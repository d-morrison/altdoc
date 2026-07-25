# Split a parsed Rd object's `\examples{}` into consecutive blocks, each with
# its own evaluation flag.
#
# `\dontrun{}` and `\donttest{}` mark code that must not run. Deciding that per
# block is the whole point: a single `\dontrun{}` used to switch evaluation off
# for the entire help page, so a page whose examples were mostly runnable but
# ended with one error-case block rendered with no output at all.
#
# The walk reads the parsed Rd tree rather than the rendered HTML. Every child
# of the `\examples` node carries its own `Rd_tag`, so a block is identified by
# what it IS, not by whether the string "dontrun" happens to appear in the
# rendered page --- which also tripped on an example that merely mentioned the
# word in a comment or a string.
#
# Returns a list of `list(code = <character>, eval = <logical>)`, in source
# order, with adjacent blocks of the same flag merged so that a run of ordinary
# code stays a single chunk.
.rd_example_blocks <- function(rd) {
    node <- .rd_tag_node(rd, "\\examples")
    if (is.null(node)) {
        return(list())
    }

    blocks <- list()
    for (child in node) {
        tag <- attr(child, "Rd_tag")
        if (is.null(tag)) {
            tag <- ""
        }

        # `\dontshow{}` and `\testonly{}` hold code meant for R's own checks,
        # not for the reader; `Rd2HTML()` omits both from the rendered page, so
        # they are dropped here too. The `@examplesIf` condition roxygen2 hides
        # in a `\dontshow{}` is read separately, by
        # `.rd_examples_if_condition()`.
        if (tag %in% c("\\dontshow", "\\testonly")) {
            next
        }

        eval <- !tag %in% c("\\dontrun", "\\donttest")
        code <- .rd_example_code(child)

        n <- length(blocks)
        if (n > 0 && identical(blocks[[n]]$eval, eval)) {
            blocks[[n]]$code <- paste0(blocks[[n]]$code, code)
        } else {
            blocks[[n + 1]] <- list(code = code, eval = eval)
        }
    }

    # Splitting on `\dontrun{}` leaves the whitespace between blocks stranded in
    # blocks of its own --- the newline after a closing brace, for instance.
    # Each block becomes a chunk, so keeping those would render empty code
    # boxes. Blocks that hold real code keep their own blank lines.
    Filter(function(b) nzchar(trimws(b$code)), blocks)
}
