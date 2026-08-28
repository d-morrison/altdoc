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
                man_labels <- .sidebar_labels(
                    sub("\\.qmd$", "", basename(fn_man)),
                    src_dir = path
                )
                yml$website$sidebar$contents[[i]] <- list(
                    section = "Reference",
                    contents = .sidebar_man_contents(
                        fn_man,
                        man_labels,
                        src_dir = path
                    )
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

    # Stage files pulled in by `{{< include >}}` directives that live outside
    # the copied source trees (e.g. a shared `macros/macros.qmd` submodule at
    # the package root). Quarto resolves include paths relative to the
    # including file, so these must exist under `_quarto/` before rendering.
    .stage_external_includes(
        src_dir = path,
        quarto_dir = fs::path_join(c(path, "_quarto"))
    )

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

    # Same problem for llms.txt, for a different reason. `.import_llms_txt()`
    # writes into the render target, which for this generator is `_quarto/`
    # rather than the published `docs/`. Quarto only carries a file into its
    # output when a rendered page references it or it is on Quarto's fixed
    # resource allowlist (`robots.txt`, `.nojekyll`, `CNAME`, ...), and
    # `llms.txt` is neither -- nothing links to it, by design, since it exists
    # for machines fetching it directly. Without this copy the file is written,
    # reported as written, and never published.
    llms_src <- fs::path_join(c(path, "_quarto", "llms.txt"))
    if (fs::file_exists(llms_src)) {
        fs::file_copy(
            llms_src,
            fs::path_join(c(tar, "llms.txt")),
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

    # Quarto builds each page's "View source" / "Edit this page" links from the
    # file it rendered, which for a man page is a generated .qmd that is never
    # committed. Repoint them at the R file the topic was documented in.
    .rewrite_man_source_links(tar, path)
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
