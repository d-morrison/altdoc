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

    if (length(fn_vignettes) > 0) {
        fn_vignettes_formatted <- lapply(fn_vignettes, function(x) {
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
    } else {
        fn_vignettes_formatted <- list()
    }

    if (length(fn_man) > 0) {
        man_labels <- .sidebar_labels(
            sub("\\.qmd$", "", basename(fn_man)),
            src_dir = path
        )
        man_contents <- .sidebar_man_contents(
            fn_man,
            man_labels,
            src_dir = path
        )
    } else {
        man_contents <- list()
    }

    .substitute_quarto_blocks <- function(node) {
        if (!is.list(node)) {
            return(node)
        }

        if (!is.null(names(node))) {
            if ("section" %in% names(node) && is.character(node$section) && length(node$section) > 0) {
                if (identical(node$section[[1]], "$ALTDOC_VIGNETTE_BLOCK")) {
                    if (length(fn_vignettes) > 0) {
                        return(list(section = "Articles", contents = fn_vignettes_formatted))
                    } else {
                        return(NULL)
                    }
                } else if (identical(node$section[[1]], "$ALTDOC_MAN_BLOCK")) {
                    if (length(fn_man) > 0) {
                        return(list(section = "Reference", contents = man_contents))
                    } else {
                        return(NULL)
                    }
                }
            }

            if ("menu" %in% names(node)) {
                if (is.character(node$menu) && length(node$menu) > 0 && identical(node$menu[[1]], "$ALTDOC_VIGNETTE_BLOCK")) {
                    if (length(fn_vignettes) > 0) {
                        node$menu <- fn_vignettes_formatted
                        return(node)
                    } else {
                        return(NULL)
                    }
                } else if (is.character(node$menu) && length(node$menu) > 0 && identical(node$menu[[1]], "$ALTDOC_MAN_BLOCK")) {
                    if (length(fn_man) > 0) {
                        node$menu <- man_contents
                        return(node)
                    } else {
                        return(NULL)
                    }
                }
            }

            if ("contents" %in% names(node)) {
                if (is.character(node$contents) && length(node$contents) > 0 && identical(node$contents[[1]], "$ALTDOC_VIGNETTE_BLOCK")) {
                    if (length(fn_vignettes) > 0) {
                        node$contents <- fn_vignettes_formatted
                        return(node)
                    } else {
                        return(NULL)
                    }
                } else if (is.character(node$contents) && length(node$contents) > 0 && identical(node$contents[[1]], "$ALTDOC_MAN_BLOCK")) {
                    if (length(fn_man) > 0) {
                        node$contents <- man_contents
                        return(node)
                    } else {
                        return(NULL)
                    }
                }
            }

            if ("text" %in% names(node) && is.character(node$text) && length(node$text) > 0) {
                if (identical(node$text[[1]], "$ALTDOC_VIGNETTE_BLOCK")) {
                    if (length(fn_vignettes) > 0) {
                        node$text <- "Articles"
                        node$contents <- fn_vignettes_formatted
                        return(node)
                    } else {
                        return(NULL)
                    }
                } else if (identical(node$text[[1]], "$ALTDOC_MAN_BLOCK")) {
                    if (length(fn_man) > 0) {
                        node$text <- "Reference"
                        node$contents <- man_contents
                        return(node)
                    } else {
                        return(NULL)
                    }
                }
            }

            for (k in names(node)) {
                res <- .substitute_quarto_blocks(node[[k]])
                node[[k]] <- res
            }
            return(node)
        } else {
            new_list <- list()
            for (i in seq_along(node)) {
                item <- node[[i]]
                if (is.character(item) && length(item) > 0 && identical(item[[1]], "$ALTDOC_VIGNETTE_BLOCK")) {
                    if (length(fn_vignettes) > 0) {
                        new_list <- c(new_list, fn_vignettes_formatted)
                    }
                } else if (is.character(item) && length(item) > 0 && identical(item[[1]], "$ALTDOC_MAN_BLOCK")) {
                    if (length(fn_man) > 0) {
                        new_list <- c(new_list, man_contents)
                    }
                } else {
                    res <- .substitute_quarto_blocks(item)
                    if (!is.null(res)) {
                        new_list <- c(new_list, list(res))
                    }
                }
            }
            return(new_list)
        }
    }

    yml <- .substitute_quarto_blocks(yml)

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
    # committed. Repoint them at the R file the topic was documented in, or at
    # the .Rd itself where the package writes its man pages by hand.
    .rewrite_man_source_links(tar, path)
}

.sidebar_man_quarto_website <- function(sidebar, path, ...) {
    .clean_empty_text <- function(node) {
        if (!is.list(node)) {
            return(node)
        }
        if (!is.null(names(node))) {
            if (
                "text" %in% names(node) &&
                    !"file" %in% names(node) &&
                    !"href" %in% names(node) &&
                    !"contents" %in% names(node) &&
                    !"menu" %in% names(node)
            ) {
                return(NULL)
            }
            for (k in names(node)) {
                node[[k]] <- .clean_empty_text(node[[k]])
            }
            return(node)
        } else {
            new_list <- list()
            for (i in seq_along(node)) {
                res <- .clean_empty_text(node[[i]])
                if (!is.null(res)) {
                    new_list <- c(new_list, list(res))
                }
            }
            return(new_list)
        }
    }
    sidebar <- .clean_empty_text(sidebar)
    return(sidebar)
}
