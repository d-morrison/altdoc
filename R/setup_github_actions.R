#' Create a Github Actions workflow
#'
#' This function creates a Github Actions workflow in
#' ".github/workflows/altdoc.yaml". This workflow will automatically render the
#' website using the setup specified in the folder "altdoc" and will push the
#' output to the branch "gh-pages".
#'
#' @inheritParams render_docs
#' @param multiversion Logical. If `TRUE`, configure the workflow to publish
#'   versioned documentation under `gh-pages/<branch-or-tag>/` and add a second
#'   job using `insightsengineering/r-pkgdown-multiversion` to maintain a
#'   version landing page and version switcher links.
#' @param default_landing_page Character scalar. The default landing page passed
#'   to `r-pkgdown-multiversion` when `multiversion = TRUE`.
#' @param refs_order Character scalar. Space-separated ref order passed to
#'   `r-pkgdown-multiversion` when `multiversion = TRUE`.
#' @param branches_or_tags_to_list Character scalar. Regular expression used by
#'   `r-pkgdown-multiversion` to decide which refs appear in the versions list
#'   when `multiversion = TRUE`.
#'
#' @return No value returned. Creates the file ".github/workflows/altdoc.yaml"
#' @export
#'
#' @examples
#' if (interactive()) {
#'   setup_github_actions()
#' }
.default_multiversion_branches_or_tags_to_list <- function() {
    "^main$|^latest-tag$|^v([0-9]+\\.)?([0-9]+\\.)?([0-9]+)(-rc[0-9]+)?$"
}

setup_github_actions <- function(
    path = ".",
    multiversion = FALSE,
    default_landing_page = "main",
    refs_order = "main latest-tag",
    branches_or_tags_to_list = .default_multiversion_branches_or_tags_to_list()
) {
    if (
        !isTRUE(length(multiversion) == 1) ||
            !is.logical(multiversion) ||
            is.na(multiversion)
    ) {
        cli::cli_abort("{.arg multiversion} must be a single TRUE/FALSE value.")
    }
    if (multiversion) {
        args <- list(
            default_landing_page = default_landing_page,
            refs_order = refs_order,
            branches_or_tags_to_list = branches_or_tags_to_list
        )
        for (nm in names(args)) {
            val <- args[[nm]]
            if (
                !isTRUE(length(val) == 1) ||
                    !is.character(val) ||
                    is.na(val) ||
                    identical(val, "")
            ) {
                cli::cli_abort(
                    "{.arg {nm}} must be a non-empty string when {.arg multiversion = TRUE}."
                )
            }
        }
    }

    strip_workflow_block <- function(
        workflow,
        start_marker,
        end_marker,
        keep = FALSE
    ) {
        starts <- grep(start_marker, workflow, fixed = TRUE)
        ends <- grep(end_marker, workflow, fixed = TRUE)
        if (length(starts) != length(ends)) {
            cli::cli_abort(
                "Unbalanced workflow markers: {.val {start_marker}} and {.val {end_marker}}."
            )
        }

        for (i in rev(seq_along(starts))) {
            start <- starts[i]
            end <- ends[i]
            if (start > end) {
                cli::cli_abort(
                    "Invalid workflow marker order: {.val {start_marker}} appears after {.val {end_marker}}."
                )
            }
            if (keep) {
                workflow <- workflow[-c(start, end)]
            } else {
                workflow <- workflow[-(start:end)]
            }
        }

        workflow
    }

    path <- .convert_path(path)
    fs::dir_create(fs::path_join(c(path, ".github/workflows")))
    if (
        fs::file_exists(fs::path_join(c(path, ".github/workflows/altdoc.yaml")))
    ) {
        cli::cli_abort("{.file .github/workflows/altdoc.yaml} already exists.")
    }

    src <- system.file("gha/altdoc.yaml", package = "altdoc")
    tar <- fs::path_join(c(path, ".github/workflows/altdoc.yaml"))
    fs::file_copy(src, tar)

    # Deal with mkdocs installation in workflow
    tool <- .doc_type(path)
    workflow <- .readlines(tar)
    workflow <- strip_workflow_block(
        workflow = workflow,
        start_marker = "$ALTDOC_MKDOCS_START",
        end_marker = "$ALTDOC_MKDOCS_END",
        keep = tool == "mkdocs"
    )
    workflow <- strip_workflow_block(
        workflow = workflow,
        start_marker = "$ALTDOC_MULTIVERSION_START",
        end_marker = "$ALTDOC_MULTIVERSION_END",
        keep = multiversion
    )
    if (multiversion) {
        workflow <- gsub(
            "$ALTDOC_DEFAULT_LANDING_PAGE",
            default_landing_page,
            workflow,
            fixed = TRUE
        )
        workflow <- gsub(
            "$ALTDOC_REFS_ORDER",
            refs_order,
            workflow,
            fixed = TRUE
        )
        workflow <- gsub(
            "$ALTDOC_BRANCHES_OR_TAGS_TO_LIST",
            branches_or_tags_to_list,
            workflow,
            fixed = TRUE
        )
    }
    writeLines(workflow, tar)

    invisible(desc::desc_set_dep("altdoc", "Suggests"))

    cli::cli_alert_success("{.file .github/workflows/altdoc.yaml} created.")
    cli::cli_alert_success("Added {.code altdoc} in Suggests.")
}
