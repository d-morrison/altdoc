# The reference index page's top-level heading.
#
# Defaults to "Package index", the name pkgdown gives the same page, so a
# reader arriving from a "Reference" navigation entry sees a heading that says
# what the page is rather than repeating how they got there.
#
# `settings` is the parsed `altdoc/reference.yml` from `.reference_settings()`.
.reference_title <- function(settings) {
    title <- settings$title

    if (is.null(title)) {
        return("Package index")
    }

    if (!is.character(title) || length(title) != 1 || is.na(title)) {
        cli::cli_abort(
            "{.code title} in {.file altdoc/reference.yml} must be a single string."
        )
    }

    if (!nzchar(trimws(title))) {
        cli::cli_abort(
            "{.code title} in {.file altdoc/reference.yml} must not be empty."
        )
    }

    title
}
