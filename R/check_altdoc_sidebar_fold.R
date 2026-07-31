# Findings about a `sidebar_fold` setting that cannot take effect.
#
# `sidebar_fold` sets the fold control's starting state; it does not create the
# control. A site that sets it without pointing a settings file at
# `$ALTDOC_SIDEBAR_FOLD` has no control for it to start, so the key does
# nothing at all --- the same silent no-op `.check_sidebar_settings()` warns
# about for `sidebar_label_width` without `sidebar_labels`.
#
# It lives here rather than beside that warning because deciding it needs both
# `altdoc/reference.yml` and the settings file, and `.check_sidebar_settings()`
# is handed the parsed settings alone. Putting it here also keeps it out of
# `render_docs()`, which is right for a finding that is about intent rather
# than validity: a file part-way through being wired up is not broken.
.check_altdoc_sidebar_fold <- function(path = ".", tool = "docsify") {
    # `.reference_settings()` warns about a `sidebar_label_width` with no
    # opt-in, and `tryCatch(error = )` does not intercept a warning --- so
    # without the muffle this reads the file for its own purposes and emits
    # someone else's warning as a side effect, raw, outside the `cli_ul`
    # findings list. Muffled rather than collected because
    # `.check_altdoc_reference()` runs on the same file and already reports it;
    # collecting it here would print it twice.
    settings <- withCallingHandlers(
        tryCatch(.reference_settings(path), error = function(e) NULL),
        warning = function(w) invokeRestart("muffleWarning")
    )
    if (is.null(settings) || is.null(settings[["sidebar_fold"]])) {
        return(character(0))
    }

    if (!identical(tool, "quarto_website")) {
        return(sprintf(
            "`altdoc/reference.yml` sets `sidebar_fold`, which only the quarto_website generator supports; this project uses %s.",
            tool
        ))
    }

    files <- .settings_files_with_variables(path, tool)
    used <- unlist(lapply(files, function(fn) {
        .altdoc_variables_used(.readlines(fn))
    }))
    if ("ALTDOC_SIDEBAR_FOLD" %in% used) {
        return(character(0))
    }

    return(
        "`altdoc/reference.yml` sets `sidebar_fold`, but no settings file uses `$ALTDOC_SIDEBAR_FOLD`, so the site has no fold control for it to apply to."
    )
}
