# Escape a string for interpolation into a single-quoted JavaScript literal.
#
# `docute` builds its sidebar as a JavaScript object literal whose fields are
# single-quoted, so an apostrophe in the interpolated text ends the string
# early and breaks the whole sidebar. Backslashes have to go first, or the
# backslash this function adds in front of an apostrophe would itself be
# escaped by the later pass.
.escape_js_single_quoted <- function(x) {
    x <- gsub("\\", "\\\\", x, fixed = TRUE)
    gsub("'", "\\'", x, fixed = TRUE)
}
