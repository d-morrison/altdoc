.sidebar_vignettes_quarto_website <- function(sidebar, path) {
    fn_vignettes <- list.files(
        fs::path_join(c(path, "_quarto/vignettes")),
        pattern = "\\.qmd$|\\.Rmd|\\.pdf$",
        full.names = TRUE,
        recursive = TRUE
    )
    fn_man <- list.files(
        fs::path_join(c(path, "_quarto/man")),
        pattern = "\\.qmd$",
        full.names = TRUE
    )

    # issue #266: add word boundary check
    fn_man <- gsub(".*\\b_quarto.", "", fn_man)
    fn_vignettes <- gsub(".*_quarto.", "", fn_vignettes)

    yml <- paste(sidebar, collapse = "\n")
    yml <- yaml::yaml.load(yml, handlers = list(seq = function(x) as.list(x)))

    # reverse order because we delete elements
    for (i in rev(seq_along(yml$website$sidebar$contents))) {
        if (!"section" %in% names(yml$website$sidebar$contents[[i]])) {
            next
        }
        if (
            isTRUE(
                yml$website$sidebar$contents[[i]]$section[[1]] ==
                    "$ALTDOC_VIGNETTE_BLOCK"
            )
        ) {
            if (length(fn_vignettes) > 0) {
                fn_vignettes <- lapply(fn_vignettes, function(x) {
                    # Quarto cannot retrieve titles from .pdf, so we use the file name
                    if (tools::file_ext(x) == "pdf") {
                        list(
                            text = sub("\\.pdf$", "", basename(x)),
                            file = x
                        )
                        # Quarto retrieves the title from .qmd files automatically, so we only supply the file path
                    } else {
                        x
                    }
                })
                yml$website$sidebar$contents[[i]] <- list(
                    section = "Articles",
                    contents = fn_vignettes
                )
            } else {
                yml$website$sidebar$contents[[i]] <- NULL
            }
        } else if (
            isTRUE(
                yml$website$sidebar$contents[[i]]$section[[1]] ==
                    "$ALTDOC_MAN_BLOCK"
            )
        ) {
            if (length(fn_man) > 0) {
                man_list <- lapply(
                    fn_man,
                    function(x) {
                        list(
                            text = sub("\\.qmd$", "", basename(x)),
                            file = x
                        )
                    }
                )
                yml$website$sidebar$contents[[i]] <- list(
                    section = "Reference",
                    contents = man_list
                )
            } else {
                yml$website$sidebar$contents[[i]] <- NULL
            }
        }
    }

    return(yml)
}

.finalize_quarto_website <- function(
    settings,
    path,
    verbose = FALSE,
    freeze = FALSE,
    ...
) {
    # WARNING: Note the different _quarto folder. This is an imortant design
    # choice because we want to use the built-in freeze functionality of quarto
    # and need to move _quarto/_site to docs/ after rendering.

    # drop empty lines
    settings <- settings[!grepl("^\\w*$", settings)]
    settings <- yaml::as.yaml(
        settings,
        indent.mapping.sequence = TRUE,
        handler = list(logical = yaml::verbatim_logical)
    )
    settings <- strsplit(settings, "\\n")[[1]]
    writeLines(settings, fs::path_join(c(path, "_quarto", "_quarto.yml")))

    # NEWS.qmd breaks rendering, so we delete it if NEWS.md is available.
    # This happens when converting from NEWS.Rd
    a <- fs::path_join(c(path, "_quarto", "NEWS.md"))
    b <- fs::path_join(c(path, "_quarto", "NEWS.qmd"))
    if (fs::file_exists(a) && fs::file_exists(b)) {
        fs::file_delete(b)
    }

    tar <- .doc_path(path)
    fs::dir_create(tar)

    # CNAME is used by Github and other providers to redirect to a custom domain
    files <- Filter(function(f) basename(f) != "CNAME", fs::dir_ls(tar))
    # Clear out `tar`
    fs::file_delete(files)

    # render to `output-dir: ../docs/`
    quarto::quarto_render(
        input = fs::path_join(c(path, "_quarto")),
        quiet = !verbose,
        as_job = FALSE,
        use_freezer = freeze
    )

    # copy the content of altdoc/ to docs/. This is important because the
    # process above rendered the site in a completely different directory, so
    # did not have the static files, and we want the static files in altdoc/ to
    # be served on the website. This a core feature of altdoc: users can store
    # files in altdoc/ and those will be copied to the root of the website

    # this can be done automatically with `project:` > `resources: ../altdoc/`
    fs::dir_copy(fs::path_join(c(path, "altdoc")), tar, overwrite = TRUE)

    # Also copy pkgdown.yml to the root of docs/ so that downlit can find it at
    # <url>/pkgdown.yml when auto-linking function calls in vignettes and articles.
    # fs::dir_copy() copies altdoc/ as a subdirectory of docs/ (creating
    # docs/altdoc/pkgdown.yml), but downlit looks for it at the website root.
    pkgdown_src <- fs::path_join(c(path, "altdoc", "pkgdown.yml"))
    if (fs::file_exists(pkgdown_src)) {
        fs::file_copy(
            pkgdown_src,
            fs::path_join(c(tar, "pkgdown.yml")),
            overwrite = TRUE
        )
    }

    # `code-link: true` makes downlit treat the package being documented the
    # same as any external package, so its own functions get linked with an
    # absolute URL pointing at the production site recorded in pkgdown.yml.
    # That breaks whenever the site isn't served from exactly that URL -- most
    # notably a PR preview deploy under its own subpath (altdoc#10). Rewrite
    # those self-links to be relative to each rendered page instead.
    .rewrite_self_links(tar, path)
}

# `code-link` resolves the documented package's own functions to an absolute
# URL (`<site-url>/man/<topic>.html` or `<site-url>/vignettes/<path>`, read
# from `altdoc/pkgdown.yml`) rather than a path relative to the linking page.
# That absolute URL only resolves on the exact deploy it was recorded for, so
# it 404s under any other deploy path (most commonly a PR preview served under
# its own subpath). Rewrite each such href into a path relative to the HTML
# file that contains it, which resolves correctly regardless of deploy path.
.rewrite_self_links <- function(docs_dir, path) {
    pkgdown_src <- fs::path_join(c(path, "altdoc", "pkgdown.yml"))
    if (!fs::file_exists(pkgdown_src)) {
        return(invisible())
    }

    urls <- yaml::read_yaml(pkgdown_src)$urls
    if (is.null(urls)) {
        return(invisible())
    }

    # `.add_pkgdown()` always registers these as `<site-url>/man` and
    # `<site-url>/vignettes`, matching this same render's `man/`/`vignettes/`
    # directories under `docs_dir` -- so the correct relative replacement for
    # each is always `<rel-root>/man` / `<rel-root>/vignettes`, regardless of
    # what the registered site URL happens to be.
    subdirs <- c(reference = "man", article = "vignettes")
    prefixes <- Filter(Negate(is.null), lapply(names(subdirs), function(key) {
        url <- urls[[key]]
        if (is.null(url) || !nzchar(url)) {
            return(NULL)
        }
        list(url = url, subdir = subdirs[[key]])
    }))
    if (length(prefixes) == 0) {
        return(invisible())
    }

    html_files <- fs::dir_ls(docs_dir, recurse = TRUE, glob = "*.html")
    for (html_file in html_files) {
        .rewrite_self_links_one(html_file, docs_dir, prefixes)
    }

    invisible()
}

.rewrite_self_links_one <- function(html_file, docs_dir, prefixes) {
    lines <- .readlines(html_file)
    rel_root <- as.character(
        fs::path_rel(docs_dir, start = fs::path_dir(html_file))
    )

    changed <- FALSE
    for (p in prefixes) {
        pattern <- paste0('href="', p$url)
        hit <- grepl(pattern, lines, fixed = TRUE)
        if (any(hit)) {
            replacement <- paste0('href="', rel_root, "/", p$subdir)
            lines[hit] <- gsub(pattern, replacement, lines[hit], fixed = TRUE)
            changed <- TRUE
        }
    }

    if (changed) {
        writeLines(lines, html_file)
    }
}

.sidebar_man_quarto_website <- function(sidebar, path, ...) {
    # the sidebar should not include text entries with no associated link
    # delete backwards to preserve order
    for (i in rev(seq_along(sidebar$website$sidebar$contents))) {
        tmp <- sidebar$website$sidebar$contents[[i]]
        if ("text" %in% names(tmp) && !"file" %in% names(tmp)) {
            sidebar$website$sidebar$contents[[i]] <- NULL
        }
    }
    return(sidebar)
}
