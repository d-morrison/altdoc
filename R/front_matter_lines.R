# Return the YAML front matter of a document, without its `---` fences.
#
# Quarto front matter is the block delimited by a `---` on the very first line
# and the next `---` or `...` on its own line. Returns an empty vector when the
# document has no front matter, so callers can treat "no front matter" and "no
# keys of interest" the same way.
.front_matter_lines <- function(lines) {
    # `---` opens the block; YAML allows either `---` or `...` to close it.
    fence_re <- "^(---|\\.\\.\\.)[[:space:]]*$"

    if (length(lines) == 0 || !grepl(fence_re, lines[[1]], perl = TRUE)) {
        return(character(0))
    }

    rest <- lines[-1]
    closing <- which(grepl(fence_re, rest, perl = TRUE))
    if (length(closing) == 0 || closing[[1]] < 2) {
        # Unterminated, or an empty block: nothing to read either way.
        return(character(0))
    }

    lines[2:closing[[1]]]
}
