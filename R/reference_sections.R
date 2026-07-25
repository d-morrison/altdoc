# Normalize the reference-index grouping, or fall back to a single section
# listing every non-internal topic.
#
# `settings` is the parsed `altdoc/reference.yml` from `.reference_settings()`.
# Its `sections` element uses the same schema as pkgdown's `_pkgdown.yml`, so an
# existing `reference:` block can be moved over unchanged:
#
#   reference:
#     - title: Data
#       desc: Load and reshape survey data
#       contents:
#         - as_pop_data
#         - starts_with("read_")
.reference_sections <- function(settings, topics) {
    sections <- settings$sections

    if (is.null(sections) || length(sections) == 0) {
        return(.reference_sections_default(topics))
    }
    if (!is.null(names(sections))) {
        cli::cli_abort(
            "{.code reference} in {.file altdoc/reference.yml} must be a list of sections, each with a {.code title} and/or {.code contents}."
        )
    }

    lapply(sections, .reference_section_check)
}
