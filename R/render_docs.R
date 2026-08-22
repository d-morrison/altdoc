#' Update documentation
#'
#' Render and update the function reference manual, vignettes, README, NEWS, CHANGELOG, LICENSE,
#' CODE_OF_CONDUCT, and CONTRIBUTING sections, if they exist. This function overwrites the
#' content of the 'docs/' folder. See details below.
#'
#' @param verbose Logical. Print Rmarkdown or Quarto rendering output.
#' @param parallel Logical. Render man pages and vignettes in parallel using the `future` framework. In addition to setting this argument to TRUE, users must define the parallelism plan in `future`. See the examples section below.
#' @param freeze Logical. If TRUE and a man page or vignette has not changed since the last call to `render_docs()`, that file is skipped. File hashes are stored in `altdoc/freeze.rds`. If that file is deleted, all man pages and vignettes will be rendered anew.
#' @param ... Additional arguments are ignored.
#' @inheritParams setup_docs
#' @export
#'
#' @details
#'
#' This function searches for specific filenames, then renders, converts, or copies them to the `docs/` directory.
#'
#' `README` is searched for in the root directory only. Every other file below is searched for in the root directory first and then in `inst/`, and in each of those under four extensions, in this order of priority: `.md`, `.txt`, no extension, `.Rd`. So `NEWS` is looked for as `NEWS.md`, `NEWS.txt`, `NEWS`, `NEWS.Rd`, `inst/NEWS.md`, `inst/NEWS.txt`, `inst/NEWS`, and `inst/NEWS.Rd`, and the first of those that exists is the one used. A `.Rd` source is converted to Markdown; every other format is copied unchanged.
#'
#' The base names searched for, and the file each produces:
#'
#' * `docs/README.md`
#'   - README.md
#'   - Note: `README.md` is required, and is always the file copied. `README.qmd` and `README.Rmd` are not rendered for you, so keep `README.md` in step with whichever of them you write in. When more than one is present, the first of `README.qmd`, `README.Rmd`, `README.md` is the one the `freeze` check watches for changes.
#' * `docs/NEWS.md`
#'   - NEWS (searched with `.md`, `.txt`, no extension, `.Rd` in root and `inst/`)
#'   - Note: Where possible, Github contributors and issues are linked automatically.
#' * `docs/CHANGELOG.md`
#'   - CHANGELOG, ChangeLog (searched with `.md`, `.txt`, no extension, `.Rd` in root and `inst/`)
#'   - Note: These are two separate searches writing to the same file, so on a case-sensitive file system holding both, `ChangeLog` is the one used.
#' * `docs/CODE_OF_CONDUCT.md`
#'   - CODE_OF_CONDUCT (searched with `.md`, `.txt`, no extension, `.Rd` in root and `inst/`)
#' * `docs/CONTRIBUTING.md`
#'   - CONTRIBUTING (searched with `.md`, `.txt`, no extension, `.Rd` in root and `inst/`)
#' * `docs/LICENSE.md`
#'   - LICENSE (searched with `.md`, `.txt`, no extension, `.Rd` in root and `inst/`)
#' * `docs/LICENCE.md`
#'   - LICENCE (searched with `.md`, `.txt`, no extension, `.Rd` in root and `inst/`)
#'
#' @return NULL
#' @template altdoc_variables
#' @template altdoc_reference
#' @template altdoc_preambles
#' @template altdoc_freeze
#' @template altdoc_autolink
#'
#' @examples
#' if (interactive()) {
#'
#'   render_docs()
#'
#'   # parallel rendering
#'   library(future)
#'   plan(multicore)
#'   render_docs(parallel = TRUE)
#'
#' }
render_docs <- function(
    path = ".",
    verbose = FALSE,
    parallel = FALSE,
    freeze = FALSE,
    ...
) {
    .check_quarto_installed()
    .add_pkgdown(path)

    # Quarto sometimes raises errors encouraging users to set `quiet=FALSE` to get more information.
    # This is a convenience check to match Quarto's `quiet` and `altdoc`'s `verbose` arguments.
    dots <- list(...)
    if (
        "quiet" %in%
            names(dots) &&
            is.logical(dots[["quiet"]]) &&
            isTRUE(length(dots[["quiet"]]) == 1)
    ) {
        verbose <- !dots[["quiet"]]
    }

    path <- .convert_path(path)
    tool <- .doc_type(path)
    dir_altdoc <- fs::path_join(c(path, "altdoc"))

    if (!fs::dir_exists(dir_altdoc) || length(fs::dir_ls(dir_altdoc)) == 0) {
        cli::cli_abort(
            "No settings file found in {dir_altdoc}. Consider running {.code setup_docs()}."
        )
    }

    # build quarto in a separate folder to use the built-in freeze functionality
    # and to allow moving the _site folder to docs/
    if (tool == "quarto_website") {
        docs_dir <- fs::path_join(c(path, "_quarto"))

        # Delete everything in `_quarto/` besides `_freeze/`
        if (fs::dir_exists(docs_dir)) {
            docs_files <- fs::dir_ls(docs_dir)
            if (isTRUE(freeze)) {
                docs_files <- Filter(
                    function(f) basename(f) != "_freeze",
                    docs_files
                )
            }
            fs::file_delete(docs_files)
        }
    } else {
        docs_dir <- fs::path_join(c(path, "docs"))
    }

    # create `docs_dir/`
    fs::dir_create(docs_dir)

    cli::cli_h1("Basic files")
    basics <- .basic_file_names()
    for (b in basics) {
        .import_basic(src_dir = path, tar_dir = docs_dir, name = b)
    }
    .import_readme(
        src_dir = path,
        tar_dir = docs_dir,
        tool = tool,
        freeze = freeze
    )
    .import_citation(src_dir = path, tar_dir = docs_dir)
    .import_logo(src_dir = path, tar_dir = docs_dir)

    # Update functions reference
    cli::cli_h1("Man pages")
    fail_man <- .import_man(
        src_dir = path,
        tar_dir = docs_dir,
        tool = tool,
        verbose = verbose,
        parallel = parallel,
        freeze = freeze
    )

    .import_reference(src_dir = path, tar_dir = docs_dir, tool = tool)

    # Update vignettes
    cli::cli_h1("Vignettes")
    fail_vignettes <- .import_vignettes(
        src_dir = path,
        tar_dir = docs_dir,
        tool = tool,
        verbose = verbose,
        parallel = parallel,
        freeze = freeze
    )

    # After the man pages and vignettes, so the index lists what was actually
    # rendered rather than what the source tree promised.
    .import_llms_txt(src_dir = path, tar_dir = docs_dir, tool = tool)

    # Error so that CI fails
    if (length(fail_vignettes) > 0 && length(fail_man) > 0) {
        cli::cli_abort(
            "There were some failures when rendering vignettes and man pages."
        )
    } else if (length(fail_vignettes) > 0 && length(fail_man) == 0) {
        cli::cli_abort("There were some failures when rendering vignettes.")
    } else if (length(fail_vignettes) == 0 && length(fail_man) > 0) {
        cli::cli_abort("There were some failures when rendering man pages.")
    }

    cli::cli_h1("Update HTML")
    .import_settings(
        path = path,
        tool = tool,
        verbose = verbose,
        freeze = freeze
    )

    cli::cli_h1("Complete")
    cli::cli_alert_success("Documentation updated.")
}
