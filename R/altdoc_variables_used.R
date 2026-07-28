# The `$ALTDOC_*` variables a file actually uses.
#
# Matched as whole names in one pass rather than by searching for each known
# name in turn. That ordering-free approach is what makes the prefix hazard go
# away: `ALTDOC_PACKAGE_URL` is a prefix of `ALTDOC_PACKAGE_URL_GITHUB`, so
# searching name by name would report a use of the shorter one on every line
# that uses the longer. `.substitute_altdoc_variables()` has to solve the same
# problem, and does it by ordering its substitutions instead, since it is
# replacing rather than reporting.
#
# It also means an unknown variable is *found* rather than missed, which is the
# entire point of the unknown-variable check --- a loop over known names could
# only ever confirm the names it already had.
.altdoc_variables_used <- function(lines) {
    found <- regmatches(lines, gregexpr("\\$ALTDOC_[A-Z_]+", lines))
    sub("^\\$", "", unique(unlist(found)))
}
