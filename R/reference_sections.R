# Read the reference-index grouping from `altdoc/reference.yml`, or fall back to
# a single section listing every non-internal topic.
#
# The file holds a `reference:` key whose value is a list of sections, using the
# same schema as pkgdown's `_pkgdown.yml`, so an existing `reference:` block can
# be moved over unchanged:
#
#   reference:
#     - title: Data
#       desc: Load and reshape survey data
#       contents:
#         - as_pop_data
#         - starts_with("read_")
#
# A bare list of sections at the top level (no `reference:` key) is accepted too.
.reference_sections <- function(src_dir = ".", topics) {
    fn <- fs::path_join(c(src_dir, "altdoc", "reference.yml"))

    if (!fs::file_exists(fn)) {
        return(.reference_sections_default(topics))
    }

    .assert_dependency("yaml")
    settings <- yaml::yaml.load_file(fn)

    sections <- if (is.list(settings) && "reference" %in% names(settings)) {
        settings[["reference"]]
    } else {
        settings
    }

    if (is.null(sections) || length(sections) == 0) {
        return(.reference_sections_default(topics))
    }
    if (!is.null(names(sections))) {
        cli::cli_abort(
            "{.file altdoc/reference.yml} must contain a list of sections, each with a {.code title} and/or {.code contents}."
        )
    }

    lapply(sections, .reference_section_check)
}
