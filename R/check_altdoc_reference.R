# Findings about `altdoc/reference.yml`.
#
# The schema rules are not restated here. `.reference_settings()` already
# validates the file at render time --- unknown top-level keys, the
# `sidebar_labels` values, the `llms_txt` flag --- and calls
# `.reference_section_check()` per section, so this check runs that same code
# and reports whatever it aborts with. Duplicating the rules would let the two
# disagree about what a valid file is, which is worse than having no check.
#
# `.reference_index()` also aborts on a `contents:` entry naming a topic that
# does not exist, and that check needs the package's topics, so it is run here
# too --- but only far enough to resolve the selectors, discarding the Markdown
# it builds.
.check_altdoc_reference <- function(path = ".") {
    fn <- fs::path_join(c(path, "altdoc", "reference.yml"))
    if (!fs::file_exists(fn)) {
        return(character(0))
    }

    # A warning is a real finding too --- `.reference_settings()` warns that
    # `sidebar_label_width` alone does nothing --- but it must not stop the
    # checks below from running.
    #
    # `withCallingHandlers()` rather than `tryCatch(warning = )`: the latter
    # installs an *exiting* handler, so the warning would unwind the stack back
    # to this call and `.reference_sections()`/`.reference_index()` would never
    # run. A file that both sets `sidebar_label_width` alone and names a topic
    # that does not exist would then report only the harmless width warning and
    # hide the error that actually aborts `render_docs()` --- the opposite of
    # this function's one-call-lists-everything contract. `muffleWarning`
    # resumes execution after recording it.
    warnings <- character(0)
    settings <- withCallingHandlers(
        tryCatch(.reference_settings(path), error = function(e) e),
        warning = function(w) {
            warnings <<- c(warnings, conditionMessage(w))
            invokeRestart("muffleWarning")
        }
    )
    out <- if (length(warnings) > 0) {
        paste0("`altdoc/reference.yml`: ", warnings)
    } else {
        character(0)
    }
    if (inherits(settings, "condition")) {
        return(c(
            out,
            paste0("`altdoc/reference.yml`: ", conditionMessage(settings))
        ))
    }

    topics <- .rd_topics(path)
    if (nrow(topics) == 0) {
        return(out)
    }

    sections <- tryCatch(
        .reference_sections(settings, topics),
        error = function(e) e
    )
    if (inherits(sections, "condition")) {
        return(c(
            out,
            paste0("`altdoc/reference.yml`: ", conditionMessage(sections))
        ))
    }

    # Selector resolution is what catches a `contents:` entry naming a topic
    # that does not exist. The index's own Markdown is not wanted here, and its
    # "topics missing from reference.yml" message is a `cli` alert rather than a
    # condition, so it is suppressed --- `.check_altdoc_nav()` covers
    # reachability, and this check is about the file being valid.
    built <- tryCatch(
        suppressMessages(.reference_index(sections, topics)),
        error = function(e) e
    )
    if (inherits(built, "condition")) {
        return(c(
            out,
            paste0("`altdoc/reference.yml`: ", conditionMessage(built))
        ))
    }

    return(out)
}
