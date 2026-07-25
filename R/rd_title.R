# Extract the \title{} of a parsed Rd object as a single line of Markdown.
# Returns NA when the Rd file has no title.
.rd_title <- function(rd) {
    node <- .rd_tag_node(rd, "\\title")
    if (is.null(node)) {
        return(NA_character_)
    }
    out <- .rd_flatten_text(node)
    out <- gsub("[[:space:]]+", " ", out)
    trimws(out)
}
