# Validate the sidebar keys of `altdoc/reference.yml`.
#
# All three are optional. When present they are checked here rather than where
# they are used, so a typo is reported once, at render time, naming the file
# the reader has to edit --- instead of silently falling back to the default
# and leaving them to wonder why the setting did nothing.
.check_sidebar_settings <- function(settings) {
    labels <- settings[["sidebar_labels"]]
    known_labels <- c("name", "name-and-title")
    if (
        !is.null(labels) &&
            (!is.character(labels) ||
                length(labels) != 1 ||
                !labels %in% known_labels)
    ) {
        cli::cli_abort(c(
            "Invalid {.field sidebar_labels} in {.file altdoc/reference.yml}: {.val {labels}}.",
            "i" = "Valid values are {.val {known_labels}}."
        ))
    }

    width <- settings[["sidebar_label_width"]]
    if (!is.null(width)) {
        # A width under 4 leaves no room for the "..." the truncation appends.
        # A fractional width is rejected rather than rounded: `substr()` would
        # silently truncate it, so `4.5` would quietly behave as `4` and the
        # setting would not mean what its author wrote.
        if (
            !is.numeric(width) ||
                length(width) != 1 ||
                is.na(width) ||
                width != trunc(width) ||
                width < 4
        ) {
            cli::cli_abort(c(
                "Invalid {.field sidebar_label_width} in {.file altdoc/reference.yml}: {.val {width}}.",
                "i" = "It must be a single whole number no smaller than {.val {4}}."
            ))
        }
    }

    fold <- settings[["sidebar_fold"]]
    known_fold <- c("expanded", "collapsed")
    if (
        !is.null(fold) &&
            (!is.character(fold) ||
                length(fold) != 1 ||
                !fold %in% known_fold)
    ) {
        cli::cli_abort(c(
            "Invalid {.field sidebar_fold} in {.file altdoc/reference.yml}: {.val {fold}}.",
            "i" = "Valid values are {.val {known_fold}}."
        ))
    }

    # A width with no opt-in is inert, which is the same silent no-op the
    # checks above exist to prevent. It is not invalid, though --- an author
    # part-way through opting in would hit it --- so it warns rather than
    # aborting.
    if (!is.null(width) && !identical(labels, "name-and-title")) {
        cli::cli_warn(c(
            "{.field sidebar_label_width} in {.file altdoc/reference.yml} has no effect.",
            "i" = "It applies only when {.field sidebar_labels} is {.val name-and-title}."
        ))
    }

    invisible(TRUE)
}
