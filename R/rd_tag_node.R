# Return the first top-level node of a parsed Rd object carrying `tag`, or NULL.
.rd_tag_node <- function(rd, tag) {
    idx <- which(.rd_tags(rd) == tag)
    if (length(idx) == 0) {
        return(NULL)
    }
    rd[[idx[1]]]
}
