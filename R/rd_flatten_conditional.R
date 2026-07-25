# Render the branch of an Rd \if{}{} or \ifelse{}{}{} node that applies to
# Markdown output. The first child holds the comma-separated target formats.
.rd_flatten_conditional <- function(x) {
    formats <- strsplit(.rd_flatten_text(x[[1]]), ",[[:space:]]*")[[1]]
    yes <- if (length(x) >= 2) .rd_flatten_text(x[[2]]) else ""
    no <- if (length(x) >= 3) .rd_flatten_text(x[[3]]) else ""
    if (any(formats %in% c("html", "text", "markdown"))) yes else no
}
