# Copy files referenced by Quarto `{{< include >}}` directives, or by a
# path-valued front-matter key (`shortcodes:`, `filters:`,
# `metadata-files:`), that resolve to a location outside the `_quarto/` build
# tree into the matching spot under `_quarto/`, so Quarto can find them at
# render time.
#
# altdoc stages `vignettes/`, `man/`, and the miscellaneous root files into
# `_quarto/`, but an include such as `{{< include ../macros/macros.qmd >}}`
# (common when a package shares its LaTeX macros via a submodule at the package
# root) points outside those trees and is otherwise never copied. Because
# Quarto resolves include paths relative to the including file, the referenced
# file must live at the same relative path under `_quarto/`. This walks the
# staged files, follows their includes recursively, and copies each
# externally-referenced file from the source tree into `_quarto/`.
.stage_external_includes <- function(src_dir, quarto_dir) {
    src_dir <- fs::path_abs(src_dir)
    quarto_dir <- fs::path_abs(quarto_dir)
    include_re <- rex::rex(
        "{{<",
        rex::regex("[[:space:]]*"),
        "include",
        rex::regex("[[:space:]]+"),
        rex::regex("([^>]+)"),
        rex::regex("[[:space:]]*"),
        ">}}"
    )
    staged_doc_re <- rex::rex(rex::escape("."), rex::regex("(qmd|Rmd|md)$"))
    edge_quote_re <- rex::rex(rex::regex("(^[\"'])|([\"']$)"))
    parent_ref_re <- rex::rex(rex::escape("."), rex::escape("."))
    starts_with_parent_re <- rex::rex(
        rex::regex("^"),
        rex::escape("."),
        rex::escape(".")
    )

    queue <- list.files(
        quarto_dir,
        full.names = TRUE,
        recursive = TRUE
    )
    queue <- queue[grepl(staged_doc_re, queue, perl = TRUE)]
    seen <- character(0)

    while (length(queue) > 0) {
        fn <- queue[[1]]
        queue <- queue[-1]
        if (fn %in% seen || !fs::file_exists(fn)) {
            next
        }
        seen <- c(seen, fn)

        lines <- .readlines(fn)
        matches <- unlist(
            regmatches(lines, gregexpr(include_re, lines, perl = TRUE))
        )
        paths <- sub(include_re, "\\1", matches)

        # Front matter can reference an external file by relative path too
        # (`shortcodes:`, `filters:`, `metadata-files:`), resolved the same way
        # as an include, so both feed the same staging logic below.
        paths <- c(paths, .front_matter_paths(lines))

        for (inc in unique(trimws(paths))) {
            inc <- gsub(edge_quote_re, "", inc, perl = TRUE)
            rel <- fs::path_rel(
                fs::path_norm(fs::path_join(c(fs::path_dir(fn), inc))),
                start = quarto_dir
            )

            # guard against resolved paths that escape quarto_dir
            if (grepl(starts_with_parent_re, rel, perl = TRUE)) {
                next
            }
            tar_file <- fs::path_join(c(quarto_dir, rel))

            # queue any include already present under `_quarto/` so we also
            # discover nested escaping includes from in-tree includes
            if (fs::file_exists(tar_file)) {
                queue <- c(queue, tar_file)
                next
            }

            # only includes that escape the copied tree need staging; the rest
            # were already copied with their containing directory
            if (!grepl(parent_ref_re, inc, perl = TRUE)) {
                next
            }
            src_file <- fs::path_join(c(src_dir, rel))

            if (fs::file_exists(src_file)) {
                fs::dir_create(fs::path_dir(tar_file))
                fs::file_copy(src_file, tar_file, overwrite = TRUE)
                queue <- c(queue, tar_file)
            }
        }
    }

    invisible()
}
