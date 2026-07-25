# Return the flattened text of every top-level node carrying `tag`. Used for the
# repeatable metadata tags (\alias, \keyword, \concept), which may occur any
# number of times in one Rd file.
.rd_tag_values <- function(rd, tag) {
    idx <- which(.rd_tags(rd) == tag)
    out <- vapply(idx, function(i) .rd_flatten_text(rd[[i]]), character(1))
    trimws(out)
}
