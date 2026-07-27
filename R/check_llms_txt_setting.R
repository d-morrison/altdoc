# Validate `altdoc/reference.yml`'s `llms_txt` key.
#
# The key is only ever read with `isFALSE()`, which is exactly why it needs
# checking: every value that is not the logical `FALSE` is silently treated as
# "generate the file". A quoted `llms_txt: "false"` is a character scalar and a
# `llms_txt: 0` is a number, so both look like an opt-out to whoever wrote them
# and do nothing at all. Failing loudly is the difference between a typo the
# author fixes in seconds and a setting they believe is in effect for months.
#
# `sidebar_labels` and `sidebar_label_width` are validated for the same reason
# in `.check_sidebar_settings()`; leaving this one key unchecked would make it
# the only setting in the file that accepts a wrong value in silence.
.check_llms_txt_setting <- function(settings) {
    value <- settings[["llms_txt"]]
    if (is.null(value)) {
        return(invisible())
    }

    if (!is.logical(value) || length(value) != 1 || is.na(value)) {
        cli::cli_abort(c(
            "Invalid {.field llms_txt} in {.file altdoc/reference.yml}:
             {.val {value}}.",
            "i" = "It must be {.val {TRUE}} or {.val {FALSE}}, unquoted."
        ))
    }

    invisible()
}
