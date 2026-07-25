# Escape a string for use as the text of a Markdown inline link.
#
# `docsify` builds its sidebar as a Markdown list of `[text](target)` links, so
# a square bracket in the interpolated text closes the label early and leaves
# the rest of it rendered as literal text next to a broken link. Backslashes go
# first, for the same reason as in `.escape_js_single_quoted()`.
.escape_md_link_text <- function(x) {
    x <- gsub("\\", "\\\\", x, fixed = TRUE)
    x <- gsub("[", "\\[", x, fixed = TRUE)
    gsub("]", "\\]", x, fixed = TRUE)
}
