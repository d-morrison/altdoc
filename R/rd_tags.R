# Return the Rd_tag of every top-level node of a parsed Rd object, using "" where
# the attribute is absent so the result lines up with `rd` and never contains NA.
.rd_tags <- function(rd) {
    vapply(
        rd,
        function(x) {
            tag <- attr(x, "Rd_tag")
            if (is.null(tag)) "" else tag
        },
        character(1)
    )
}
