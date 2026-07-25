# Render one bullet per topic: a link to the topic's page, followed by the
# summary taken from its .Rd \title{}.
.reference_rows <- function(topics, ext = "md") {
    label <- ifelse(topics$is_fun, paste0(topics$name, "()"), topics$name)
    label <- vapply(label, .rd_code_span, character(1), USE.NAMES = FALSE)
    link <- paste0("- [", label, "](man/", topics$name, ".", ext, ")")
    # A topic with no \title{} still gets a row, just without a summary.
    has_title <- !is.na(topics$title) & nzchar(topics$title)
    ifelse(has_title, paste0(link, " --- ", topics$title), link)
}
