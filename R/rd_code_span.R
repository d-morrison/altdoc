# Wrap `x` in the shortest run of backticks that does not occur inside it, so
# that a code span containing backticks is still valid Markdown. A leading or
# trailing backtick additionally needs a space of padding.
.rd_code_span <- function(x) {
    fence <- "`"
    while (grepl(fence, x, fixed = TRUE)) {
        fence <- paste0(fence, "`")
    }
    pad <- if (grepl("^`|`$", x)) " " else ""
    paste0(fence, pad, x, pad, fence)
}
