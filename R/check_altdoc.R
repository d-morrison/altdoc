#' Check an altdoc project's settings before rendering
#'
#' @description
#' Report configuration problems that `render_docs()` would otherwise handle
#' silently: an `$ALTDOC_*` variable altdoc does not recognize, one whose
#' source file is missing, a man page or vignette the navigation never links,
#' a missing or inconsistent site URL, and an invalid `altdoc/reference.yml`.
#'
#' Every check reports rather than aborts, and all checks run even when an
#' earlier one finds something, so one call lists everything there is to fix.
#'
#' @details
#' The checks are grouped by what goes wrong when they fail.
#'
#' **Variables that never resolve.** An unrecognized variable --- a typo, or one
#' from a newer altdoc than the installed version --- is left alone, so the
#' literal `$ALTDOC_...` text reaches the published page. A *recognized*
#' variable whose source is missing behaves differently: the whole line using
#' it is dropped, which is deliberate (it lets a settings file carry an entry
#' unconditionally) and therefore indistinguishable from a mistake without a
#' check.
#'
#' **Pages nothing links to.** A man page or vignette absent from the
#' navigation is still rendered and still fetchable; it just cannot be reached
#' by clicking. Settings files using `$ALTDOC_MAN_BLOCK` or
#' `$ALTDOC_VIGNETTE_BLOCK` cannot have this problem, since those blocks are
#' generated from what is on disk, so this only applies to a hand-authored
#' navigation.
#'
#' **A missing site URL.** `altdoc/pkgdown.yml`'s `urls:` block is what
#' `downlit` reads to autolink function calls in vignettes, and it is populated
#' from `DESCRIPTION`'s `URL:`. With no site URL the autolinks simply do not
#' appear, and a repository URL is not a substitute --- appending a page path to
#' it yields a link that does not exist.
#'
#' **An invalid `altdoc/reference.yml`.** This runs the same validation
#' `render_docs()` runs, so it reports exactly what a render would refuse,
#' without waiting for one.
#'
#' The function is opt-in: `render_docs()` does not call it. A render that
#' warned about every one of these would be noisy on every build, and one that
#' errored would refuse work it can complete.
#'
#' @inheritParams setup_docs
#'
#' @return A character vector of findings, invisibly, one per problem, and
#' empty when nothing was found. The findings are also printed. Returning them
#' lets a caller act on the result --- in a CI check, say --- rather than
#' reading the console.
#'
#' @export
#'
#' @examples
#' if (interactive()) {
#'
#'   check_altdoc()
#'
#' }
check_altdoc <- function(path = ".") {
    .check_is_package(path)
    tool <- .doc_type(path)

    findings <- c(
        .check_altdoc_variables(path, tool),
        .check_altdoc_nav(path, tool, kind = "man"),
        .check_altdoc_nav(path, tool, kind = "vignettes"),
        .check_altdoc_urls(path),
        .check_altdoc_reference(path)
    )

    if (length(findings) == 0) {
        cli::cli_alert_success("No problems found in {.file altdoc/}.")
        return(invisible(findings))
    }

    cli::cli_alert_warning(
        "Found {length(findings)} problem{?s} in {.file altdoc/}:"
    )
    cli::cli_div(theme = list(ul = list(`margin-left` = 2, before = "")))
    cli::cli_ul(findings)
    cli::cli_end()

    invisible(findings)
}
