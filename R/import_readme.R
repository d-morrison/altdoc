.import_readme <- function(src_dir, tar_dir, tool, freeze) {
    readme_files <- list.files(src_dir, pattern = "^README")

    # For quarto_website, README.qmd can be used if present. Otherwise README.md is mandatory.
    use_qmd <- identical(tool, "quarto_website") &&
        "README.qmd" %in% readme_files

    if (!use_qmd && !"README.md" %in% readme_files) {
        cli::cli_abort("README.md is mandatory.")
    }

    readme_filename <- if (use_qmd) "README.qmd" else "README.md"
    src_file <- fs::path_join(c(src_dir, readme_filename))

    # Skip file when frozen
    if (isTRUE(freeze)) {
        hashes <- .get_hashes(src_dir = src_dir, freeze = freeze)
        out_path <- if (tool == "quarto_website") {
            fs::path_join(c(src_dir, "_quarto", readme_filename))
        } else {
            fs::path_join(c(src_dir, "docs", readme_filename))
        }
        flag <- .is_frozen(
            input = basename(src_file),
            output = out_path,
            hashes = hashes
        )
        if (isTRUE(flag)) {
            cli::cli_alert(
                "Skipped {.file {basename(src_file)}} rendering because it didn't change."
            )
            return(invisible())
        }
    }

    tar_file <- fs::path_join(c(tar_dir, readme_filename))
    fs::file_copy(src_file, tar_file, overwrite = TRUE)

    # Also copy README.md if use_qmd is TRUE and README.md is present
    if (use_qmd && "README.md" %in% readme_files) {
        fs::file_copy(
            fs::path_join(c(src_dir, "README.md")),
            fs::path_join(c(tar_dir, "README.md")),
            overwrite = TRUE
        )
    }

    if (!use_qmd) {
        .check_md_structure(tar_file)
    }

    # Add the index page which includes README.
    if (tool == "quarto_website") {
        if (use_qmd) {
            writeLines(
                enc2utf8("{{< include README.qmd >}}"),
                fs::path_join(c(tar_dir, "index.qmd"))
            )
            idx_md <- fs::path_join(c(tar_dir, "index.md"))
            if (fs::file_exists(idx_md)) {
                fs::file_delete(idx_md)
            }
        } else {
            writeLines(
                enc2utf8("{{< include README.md >}}"),
                fs::path_join(c(tar_dir, "index.md"))
            )
            idx_qmd <- fs::path_join(c(tar_dir, "index.qmd"))
            if (fs::file_exists(idx_qmd)) {
                fs::file_delete(idx_qmd)
            }
        }
    }

    tmp <- fs::path_join(c(src_dir, "README.markdown_strict_files"))
    if (fs::dir_exists(tmp)) {
        cli::cli_alert(
            "We recommend using a `knitr` option to set the path of your images to `man/figures/README-`. This would ensure that images are properly stored and displayed on multiple platforms like CRAN, Github, and on your `altdoc` website."
        )
    }
    .update_freeze(
        src_dir,
        basename(src_file),
        successes = 1,
        fails = NULL,
        type = "README"
    )
    cli::cli_alert_success("{.file README} imported.")
    if (!use_qmd && "README.qmd" %in% readme_files) {
        cli::cli_alert(
            "Altdoc does not render README.qmd automatically to markdown. Please ensure that your README.md file is in sync."
        )
    }
}
