# Shorten a string to at most `width` characters, marking the cut with an
# ellipsis so a reader can tell the text was clipped rather than authored short.
#
# `width` is the total length of the result, ellipsis included, so a caller can
# reason about the space a label occupies without accounting for the marker
# separately.
#
# Vectorized over `x`, and `NA` passes through untouched: a missing title is
# absent rather than long, so there is nothing to shorten.
.truncate_label <- function(x, width = 40L) {
    if (length(x) == 0) {
        return(x)
    }

    too_long <- !is.na(x) & nchar(x) > width
    x[too_long] <- paste0(substr(x[too_long], 1, width - 3L), "...")
    x
}
