.import_readme <- function(src_dir, tar_dir, tool, freeze) {
    readme_files <- list.files(src_dir, pattern = "README")

    # setup_docs() already created README.md if there is none, so if we don't find
    # any, it means the user has deleted it and we error
    if (!"README.md" %in% readme_files && !"README.qmd" %in% readme_files) {
        cli::cli_abort("README.md or README.qmd is mandatory.")
    } else if (!"README.md" %in% readme_files && tool != "quarto_website") {
        cli::cli_abort("README.md is mandatory.")
    }

    use_qmd <- tool == "quarto_website" && "README.qmd" %in% readme_files
    readme_filename <- if (use_qmd) "README.qmd" else "README.md"
    src_file <- fs::path_join(c(src_dir, readme_filename))

    # Skip file when frozen
    if (isTRUE(freeze)) {
        hashes <- .get_hashes(src_dir = src_dir, freeze = freeze)
        flag <- .is_frozen(
            input = basename(src_file),
            output = fs::path_join(c(src_dir, "docs", readme_filename)),
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
    if (!use_qmd) {
        .check_md_structure(tar_file)
    }

    # Add the index page which includes README.md or README.qmd.
    if (tool == "quarto_website") {
        if (use_qmd) {
            writeLines(
                enc2utf8("{{< include README.qmd >}}"),
                fs::path_join(c(tar_dir, "index.qmd"))
            )
            stale_idx <- fs::path_join(c(tar_dir, "index.md"))
            if (fs::file_exists(stale_idx)) {
                fs::file_delete(stale_idx)
            }
        } else {
            writeLines(
                enc2utf8("{{< include README.md >}}"),
                fs::path_join(c(tar_dir, "index.md"))
            )
            stale_idx <- fs::path_join(c(tar_dir, "index.qmd"))
            if (fs::file_exists(stale_idx)) {
                fs::file_delete(stale_idx)
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
    if ("README.qmd" %in% readme_files && !use_qmd) {
        cli::cli_alert(
            "Altdoc does not render README.qmd automatically to markdown. Please ensure that your README.md file is in sync."
        )
    }
}
