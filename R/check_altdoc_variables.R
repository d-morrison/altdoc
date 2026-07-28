# Findings about the `$ALTDOC_*` variables in a package's settings files.
#
# Two failures, both of which are silent at render time:
#
#   - An **unknown** variable is never substituted, so the literal
#     `$ALTDOC_TYPOED_NAME` text reaches the published page.
#   - A **known** variable whose source is missing has its whole line dropped
#     by `.substitute_altdoc_variables()`, so a sidebar entry simply vanishes
#     with nothing said about it. That behavior is deliberate --- it lets a
#     settings file carry an entry unconditionally --- which is exactly why it
#     needs a check: the intended and the accidental case look identical.
.check_altdoc_variables <- function(path = ".", tool = "docsify") {
    files <- .settings_files_with_variables(path, tool)
    if (length(files) == 0) {
        return(character(0))
    }

    known <- .altdoc_variable_names()
    out <- character(0)

    for (fn in files) {
        used <- .altdoc_variables_used(.readlines(fn))
        rel <- fs::path_rel(fn, path)

        unknown <- setdiff(used, known)
        for (v in unknown) {
            out <- c(
                out,
                sprintf(
                    "%s uses `$%s`, which altdoc does not recognize; it will appear verbatim in the rendered page.",
                    rel,
                    v
                )
            )
        }

        reported <- character(0)
        for (v in intersect(used, known)) {
            if (v %in% reported) {
                next
            }
            group <- .altdoc_variable_group(v)
            # A group is only a finding when no member of it resolves; see
            # `.altdoc_variable_alternatives()`. Marking the whole group
            # reported keeps a two-member group to one message rather than one
            # per member.
            reasons <- lapply(
                group,
                .altdoc_variable_source_missing,
                path = path
            )
            reported <- c(reported, group)
            if (any(vapply(reasons, is.null, logical(1)))) {
                next
            }

            # Report the members this file actually uses, each with *its own*
            # reason. Resolution is judged across the whole group, but the
            # advice has to name the file that would fix the variable in front
            # of the reader: a settings file using only `$ALTDOC_CHANGELOG`
            # told to add a `NEWS` file has been sent after the wrong document.
            in_use <- intersect(group, used)
            why <- unique(unlist(reasons[match(in_use, group)]))
            out <- c(
                out,
                sprintf(
                    "%s uses %s, but %s, so the line%s using %s dropped from the rendered page. That is expected if the package has none; add the file, or remove the line to make the omission deliberate.",
                    rel,
                    paste0("`$", in_use, "`", collapse = " and "),
                    paste(why, collapse = " and "),
                    if (length(in_use) > 1) "s" else "",
                    if (length(in_use) > 1) "them are" else "it is"
                )
            )
        }
    }

    return(out)
}
