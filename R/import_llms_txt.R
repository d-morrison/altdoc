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

    # Count the topics that will actually be listed, not every documented one.
    # `.llms_txt()` drops internal topics, so a package whose topics are all
    # internal has nothing indexable: gating on `nrow(topics)` would write a
    # file holding only the H1 and the title, with no `## Reference` section.
    listed <- .llms_txt_listed(topics)

    if (nrow(listed) == 0 && nrow(vignettes) == 0) {
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
        "{.file llms.txt} written with {nrow(listed)} topic{?s} and
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

# Vignettes actually present in the rendered site, with their titles and the
# extension each one is published under.
#
# The file set differs by generator, and matching the wrong one goes wrong in
# both directions:
#
#   - quarto_website gets `vignettes/` copied verbatim (`.import_vignettes()`
#     returns early for it), so the sources are what is there and Quarto
#     renders them. A `.Rmd` vignette is published and listed in the sidebar,
#     so a pattern that only knows `.qmd` silently drops it.
#   - Every other generator renders down to `.md` -- but
#     `.render_one_vignette()` copies the source in first and, unlike
#     `.import_man()`, never deletes it. So `customize.qmd` sits beside the
#     `customize.md` built from it, and a pattern matching both lists the same
#     vignette twice.
#
# Hence one pattern per generator, mirroring what the sidebar builders already
# match, plus a dedup by name as a backstop for a package that hand-authors a
# `.md` vignette alongside a `.qmd` of the same name.
#
# `ext` is per-vignette rather than one value for the whole section because a
# `.pdf` vignette is copied, not rendered: under quarto_website its siblings
# become `.html` while it stays `.pdf`.
.llms_txt_vignettes <- function(src_dir, tar_dir, tool) {
    dir <- fs::path_join(c(tar_dir, "vignettes"))
    empty <- data.frame(
        name = character(0),
        title = character(0),
        ext = character(0),
        stringsAsFactors = FALSE
    )
    if (!fs::dir_exists(dir)) {
        return(empty)
    }

    pattern <- if (identical(tool, "quarto_website")) {
        "\\.(qmd|Rmd|md|pdf)$"
    } else {
        "\\.(md|pdf)$"
    }

    files <- list.files(dir, pattern = pattern, full.names = TRUE)
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

    # quarto_website renders its sources to HTML; a .pdf is copied through
    # unchanged, so it keeps its own extension either way.
    src_ext <- fs::path_ext(files)
    ext <- if (identical(tool, "quarto_website")) {
        ifelse(src_ext == "pdf", "pdf", "html")
    } else {
        src_ext
    }

    out <- data.frame(
        name = fs::path_ext_remove(basename(files)),
        title = titles,
        ext = ext,
        stringsAsFactors = FALSE
    )
    out[!duplicated(out$name), , drop = FALSE]
}
