# Render one bullet per topic: a link to the topic's page, followed by the
# summary taken from its .Rd \title{}.
#
# The label is the topic's `\name{}` and the link target is the .Rd file's
# basename, which are the same string for most topics and deliberately not for
# a topic whose name is not filesystem-safe -- see `.rd_topics()`. A reader
# looking for `%+%` should see `%+%`, and the page they land on is
# `man/grapes-plus-grapes`, because that is the file roxygen2 wrote and the
# generators published.
.reference_rows <- function(topics, ext = "md") {
    label <- ifelse(topics$is_fun, paste0(topics$name, "()"), topics$name)
    label <- vapply(label, .rd_code_span, character(1), USE.NAMES = FALSE)
    link <- paste0("- [", label, "](man/", topics$file, ".", ext, ")")
    # A topic with no \title{} still gets a row, just without a summary.
    has_title <- !is.na(topics$title) & nzchar(topics$title)
    ifelse(has_title, paste0(link, " --- ", topics$title), link)
}
