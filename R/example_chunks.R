# Render example blocks as Quarto code chunks, one chunk per block.
#
# `blocks` comes from `.rd_example_blocks()`: each carries its own `eval` flag,
# so a `\dontrun{}` block is shown without being run while the code around it
# still evaluates.
#
# `pkg_load` is altdoc's own scaffolding --- the `library()` call that makes the
# examples runnable --- not part of the example the author wrote. It goes at the
# top of the first block that actually evaluates, since that is the one that
# needs it. When no block evaluates it still goes at the top of the first one,
# so a page whose examples are all disabled reads the same as it always has.
.example_chunks <- function(blocks, pkg_load) {
    if (length(blocks) == 0) {
        return(character(0))
    }

    evaluated <- vapply(blocks, function(b) isTRUE(b$eval), logical(1))
    load_into <- if (any(evaluated)) which(evaluated)[1] else 1L

    out <- character(0)
    for (i in seq_along(blocks)) {
        code <- .split_example_lines(blocks[[i]]$code)
        if (i == load_into) {
            code <- c(pkg_load, code)
        }
        out <- c(
            out,
            sprintf(
                "```{r, warning=FALSE, message=FALSE, eval=%s}",
                blocks[[i]]$eval
            ),
            code,
            "```"
        )
    }

    out
}
