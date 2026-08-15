# Extract the \title{} of a parsed Rd object as a single line of Markdown.
# Returns NA when the Rd file has no title.
.rd_title <- function(rd) {
    node <- .rd_tag_node(rd, "\\title")
    if (is.null(node)) {
        return(NA_character_)
    }
    out <- .rd_flatten_text(node)
    out <- gsub("[[:space:]]+", " ", out)
    out <- gsub("\u201c", "\"", out, fixed = TRUE)
    out <- gsub("\u201d", "\"", out, fixed = TRUE)
    out <- gsub("\u2018", "'", out, fixed = TRUE)
    out <- gsub("\u2019", "'", out, fixed = TRUE)
    trimws(out)
}
