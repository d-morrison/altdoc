.import_readme <- function(src_dir, tar_dir, tool, freeze) {
    readme_files <- list.files(src_dir, pattern = "README")

    # setup_docs() already created README.md if there is none, so if we don't find
    # any, it means the user has deleted it and we error
    if (!"README.md" %in% readme_files) {
        cli::cli_abort("README.md is mandatory.")
    }

    use_qmd <- "README.qmd" %in% readme_files && tool == "quarto_website"

    src_file <- if (use_qmd) {
        fs::path_join(c(src_dir, "README.qmd"))
    } else {
        fs::path_join(c(src_dir, "README.md"))
    }

    # Skip file when frozen
    if (isTRUE(freeze)) {
        hashes <- .get_hashes(src_dir = src_dir, freeze = freeze)
        flag <- .is_frozen(
            input = basename(src_file),
            output = fs::path_join(c(tar_dir, basename(src_file))),
            hashes = hashes
        )
        if (isTRUE(flag)) {
            cli::cli_alert(
                "Skipped {.file {basename(src_file)}} rendering because it didn't change."
            )
            return(invisible())
        }
    }

    tar_file <- fs::path_join(c(tar_dir, "README.md"))
    fs::file_copy(fs::path_join(c(src_dir, "README.md")), tar_file, overwrite = TRUE)
    .check_md_structure(tar_file)

    if (use_qmd) {
        fs::file_copy(src_file, fs::path_join(c(tar_dir, "README.qmd")), overwrite = TRUE)
    }

    # Add the index page which includes README.qmd (if present for Quarto) or README.md
    if (tool == "quarto_website") {
        inc_file <- if (use_qmd) "README.qmd" else "README.md"
        writeLines(
            enc2utf8(paste0("{{< include ", inc_file, " >}}")),
            fs::path_join(c(tar_dir, "index.qmd"))
        )
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
    if ("README.qmd" %in% readme_files) {
        if (use_qmd) {
            cli::cli_alert(
                "Altdoc uses {.file README.qmd} directly for Quarto website rendering."
            )
        } else {
            cli::cli_alert(
                "Altdoc does not render README.qmd automatically to markdown. Please ensure that your README.md file is in sync."
            )
        }
    }
}
