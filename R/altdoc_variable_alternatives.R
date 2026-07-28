# Groups of variables that are alternatives to each other, not independent
# entries.
#
# The shipped templates list every member of each group on its own line, and
# rely on `.substitute_altdoc_variables()` dropping the lines that do not
# resolve --- that is the whole point of the drop-the-line behavior. So a
# package with a `LICENSE.md` and no `LICENCE.md` is correctly configured, and
# reporting the unresolved half would fire on every default project and teach
# the reader to ignore this check.
#
# Only report a group when *none* of its members resolves, which is the case
# that actually loses the reader something.
#
# `NEWS` and `CHANGELOG` are one group for the same reason: both name the
# document describing what changed, a package normally ships one of them, and
# the template offers both.
.altdoc_variable_alternatives <- function() {
    list(
        c("ALTDOC_NEWS", "ALTDOC_CHANGELOG"),
        c("ALTDOC_LICENSE", "ALTDOC_LICENCE")
    )
}
