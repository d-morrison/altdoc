# Split a block of example source into the lines a code chunk is written from.
#
# Nothing is trimmed. The blank lines an Rd example carries --- including the
# one after `\examples{` --- are part of how it reads, and R's own HTML
# rendering keeps them too, so removing them here would silently reflow every
# existing page.
#
# `strsplit()` drops the trailing empty field, which is what stops the newline
# that closes the block from becoming a blank line before the chunk fence.
.split_example_lines <- function(code) {
    strsplit(code, "\n", fixed = TRUE)[[1]]
}
