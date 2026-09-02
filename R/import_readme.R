.import_readme <- function(src_dir, tar_dir, tool, freeze) {
    readme_candidates <- c("README.qmd", "README.Rmd", "README.md")
    readme_files <- list.files(src_dir, pattern = "^README\\.(qmd|Rmd|md)$")

    found <- readme_candidates[readme_candidates %in% readme_files]

    if (length(found) == 0) {
        cli::cli_abort("README file is mandatory (.qmd, .Rmd, or .md).")
    }

    # Selection preference:
    # For quarto_website, README.qmd is used if present.
    # Otherwise (or for non-Quarto tools), README.md is preferred if present, falling back to README.qmd or README.Rmd.
    chosen_file <- found[1]
    src_file <- fs::path_join(c(src_dir, chosen_file))

    if (tool == "quarto_website" && chosen_file == "README.qmd") {
        tar_file <- fs::path_join(c(tar_dir, "README.qmd"))

        # Always maintain index files
        idx_qmd <- fs::path_join(c(tar_dir, "index.qmd"))
        idx_md <- fs::path_join(c(tar_dir, "index.md"))
        if (fs::file_exists(idx_md)) {
            fs::file_delete(idx_md)
        }
        writeLines(
            enc2utf8("{{< include README.qmd >}}"),
            idx_qmd
        )

        # Skip file copy when frozen
        if (isTRUE(freeze)) {
            hashes <- .get_hashes(src_dir = src_dir, freeze = freeze)
            flag <- .is_frozen(
                input = chosen_file,
                output = tar_file,
                hashes = hashes
            )
            if (isTRUE(flag)) {
                cli::cli_alert(
                    "Skipped {.file {chosen_file}} rendering because it didn't change."
                )
                return(invisible())
            }
        }

        fs::file_copy(src_file, tar_file, overwrite = TRUE)
        .check_md_structure(tar_file)
    } else {
        # Fallback to README.md for non-Quarto generators or when source is README.md/README.Rmd.
        # If README.md exists, use it; otherwise copy chosen_file to README.md.
        src_md <- fs::path_join(c(src_dir, "README.md"))
        if (fs::file_exists(src_md)) {
            src_file_to_copy <- src_md
            freeze_input <- "README.md"
        } else {
            src_file_to_copy <- src_file
            freeze_input <- chosen_file
        }

        tar_file <- fs::path_join(c(tar_dir, "README.md"))

        if (tool == "quarto_website") {
            idx_qmd <- fs::path_join(c(tar_dir, "index.qmd"))
            idx_md <- fs::path_join(c(tar_dir, "index.md"))
            if (fs::file_exists(idx_qmd)) {
                fs::file_delete(idx_qmd)
            }
            writeLines(
                enc2utf8("{{< include README.md >}}"),
                idx_md
            )
        }

        # Skip file copy when frozen
        if (isTRUE(freeze)) {
            hashes <- .get_hashes(src_dir = src_dir, freeze = freeze)
            flag <- .is_frozen(
                input = freeze_input,
                output = tar_file,
                hashes = hashes
            )
            if (isTRUE(flag)) {
                cli::cli_alert(
                    "Skipped {.file {freeze_input}} rendering because it didn't change."
                )
                return(invisible())
            }
        }

        fs::file_copy(src_file_to_copy, tar_file, overwrite = TRUE)
        .check_md_structure(tar_file)
    }

    tmp <- fs::path_join(c(src_dir, "README.markdown_strict_files"))
    if (fs::dir_exists(tmp)) {
        cli::cli_alert(
            "We recommend using a `knitr` option to set the path of your images to `man/figures/README-`. This would ensure that images are properly stored and displayed on multiple platforms like CRAN, Github, and on your `altdoc` website."
        )
    }

    freeze_record <- if (
        tool == "quarto_website" && chosen_file == "README.qmd"
    ) {
        "README.qmd"
    } else if (fs::file_exists(fs::path_join(c(src_dir, "README.md")))) {
        "README.md"
    } else {
        chosen_file
    }
    .update_freeze(
        src_dir,
        freeze_record,
        successes = 1,
        fails = NULL,
        type = "README"
    )
    cli::cli_alert_success("{.file README} imported.")

    if (
        ("README.qmd" %in% readme_files || "README.Rmd" %in% readme_files) &&
            "README.md" %in% readme_files &&
            tool != "quarto_website"
    ) {
        other <- if ("README.qmd" %in% readme_files) {
            "README.qmd"
        } else {
            "README.Rmd"
        }
        cli::cli_alert(
            "Altdoc does not render {.file {other}} automatically to markdown. Please ensure that your README.md file is in sync."
        )
    }
}
