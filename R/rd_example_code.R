# Render one child of an `\examples{}` node back to its example source.
#
# Example content is plain R code, so unlike `.rd_flatten_text()` there is no
# inline markup to translate --- the text of the node and its descendants IS the
# code, and concatenating it verbatim is what preserves it exactly as written.
.rd_example_code <- function(x) {
    paste(unlist(x), collapse = "")
}
