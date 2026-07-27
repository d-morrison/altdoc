# Write `llms.txt` at the site root.
#
# Must run after `.import_man()` and `.import_vignettes()`, since the vignette
# list is read from what those actually produced rather than from the source
# tree -- a vignette that failed to render should not be advertised.
#
# Opt out with `llms_txt: false` in `altdoc/reference.yml`.
.import_llms_txt <- function(src_dir, tar_dir, tool = "docsify") {
    settings <- .reference_settings(src_dir)
    if (isFALSE(settings$llms_txt)) {
        return(invisible())
    }

    topics <- .rd_topics(src_dir)
    vignettes <- .llms_txt_vignettes(src_dir, tar_dir, tool)

    if (nrow(topics) == 0 && nrow(vignettes) == 0) {
        return(invisible())
    }

    base <- .site_url(src_dir)
    if (is.null(base)) {
        cli::cli_alert_info(
            "No site {.field URL} found, so {.file llms.txt} links are
             site-relative."
        )
    }

    content <- .llms_txt(
        pkg_name = .pkg_name(src_dir),
        pkg_title = desc::desc_get_field(
            "Title",
            default = NULL,
            file = src_dir
        ),
        topics = topics,
        vignettes = vignettes,
        base = base,
        ext = .llms_txt_ext(tool)
    )
    writeLines(content, fs::path_join(c(tar_dir, "llms.txt")))

    cli::cli_alert_success(
        "{.file llms.txt} written with {nrow(topics)} topic{?s} and
         {nrow(vignettes)} article{?s}."
    )

    invisible()
}

# The extension of the page a consumer can actually fetch.
#
# This deliberately mirrors `.import_reference()`'s split -- quarto_website on
# one side, every other generator on the other -- because the underlying fact
# is the same: quarto_website is the only generator that does not leave the
# Markdown in the published tree. docsify and docute fetch it at runtime, and
# mkdocs builds HTML alongside the `.md` sources rather than replacing them.
# Markdown is also the better target when it is available: an LLM gets the
# source instead of a page it has to strip tags from.
#
# Do not give mkdocs `.html` on the reasoning that it "builds HTML": its
# config does not set `use_directory_urls`, so mkdocs' default of `TRUE`
# applies and pages are served at `/man/foo/`, never `/man/foo.html`. An
# extension-based HTML link is wrong for it in two ways at once.
.llms_txt_ext <- function(tool) {
    if (identical(tool, "quarto_website")) "html" else "md"
}

# Vignettes actually present in the rendered site, with their titles.
#
# `.import_vignettes()` keeps `.qmd` for quarto_website and renders everything
# else down to `.md`, so both are looked for.
.llms_txt_vignettes <- function(src_dir, tar_dir, tool) {
    dir <- fs::path_join(c(tar_dir, "vignettes"))
    empty <- data.frame(
        name = character(0),
        title = character(0),
        stringsAsFactors = FALSE
    )
    if (!fs::dir_exists(dir)) {
        return(empty)
    }

    files <- list.files(dir, pattern = "\\.(md|qmd)$", full.names = TRUE)
    if (length(files) == 0) {
        return(empty)
    }
    # Radix sort so the listing order does not depend on the collation locale,
    # matching `.rd_topics()`.
    files <- sort(files, method = "radix")

    titles <- vapply(
        files,
        function(fn) {
            title <- .get_vignettes_titles(fn, path = src_dir)
            if (length(title) == 0 || is.na(title[[1]])) {
                return(fs::path_ext_remove(basename(fn)))
            }
            as.character(title[[1]])
        },
        character(1),
        USE.NAMES = FALSE
    )

    data.frame(
        name = fs::path_ext_remove(basename(files)),
        title = titles,
        stringsAsFactors = FALSE
    )
}
