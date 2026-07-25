# Validate one section of `altdoc/reference.yml` and return it normalized.
# Fails on an unusable section rather than silently dropping it, so a typo in the
# settings file surfaces at `render_docs()` time instead of producing a quietly
# incomplete index.
.reference_section_check <- function(section) {
    if (!is.list(section) || is.null(names(section))) {
        cli::cli_abort(
            "Each section of {.file altdoc/reference.yml} must be a mapping with a {.code title}, {.code subtitle}, {.code desc}, and/or {.code contents}."
        )
    }

    known <- c("title", "subtitle", "desc", "contents")
    unknown <- setdiff(names(section), known)
    if (length(unknown) > 0) {
        cli::cli_abort(c(
            "Unknown key{?s} in {.file altdoc/reference.yml}: {.val {unknown}}.",
            "i" = "Known keys are {.val {known}}."
        ))
    }

    for (key in c("title", "subtitle", "desc")) {
        value <- section[[key]]
        if (!is.null(value) && !(is.character(value) && length(value) == 1)) {
            cli::cli_abort(
                "{.code {key}} in {.file altdoc/reference.yml} must be a single string."
            )
        }
    }

    if (!is.null(section$contents) && length(section$contents) == 0) {
        cli::cli_abort(
            "{.code contents} in {.file altdoc/reference.yml} must list at least one topic."
        )
    }

    section
}
