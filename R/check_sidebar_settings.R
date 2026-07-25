# Validate the sidebar-label keys of `altdoc/reference.yml`.
#
# Both keys are optional. When present they are checked here rather than where
# they are used, so a typo is reported once, at render time, naming the file
# the reader has to edit --- instead of silently falling back to the default
# and leaving them to wonder why the setting did nothing.
.check_sidebar_settings <- function(settings) {
    labels <- settings[["sidebar_labels"]]
    known <- c("name", "name-and-title")
    if (!is.null(labels) && !isTRUE(labels %in% known)) {
        cli::cli_abort(c(
            "Invalid {.field sidebar_labels} in {.file altdoc/reference.yml}: {.val {labels}}.",
            "i" = "Valid values are {.val {known}}."
        ))
    }

    width <- settings[["sidebar_label_width"]]
    if (!is.null(width)) {
        # A width under 4 leaves no room for the "..." the truncation appends.
        if (
            !is.numeric(width) ||
                length(width) != 1 ||
                is.na(width) ||
                width < 4
        ) {
            cli::cli_abort(c(
                "Invalid {.field sidebar_label_width} in {.file altdoc/reference.yml}: {.val {width}}.",
                "i" = "It must be a single number no smaller than {.val {4}}."
            ))
        }
    }

    invisible(TRUE)
}
