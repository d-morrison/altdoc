# The shape `.rd_topics()` returns for a package with no documented topics,
# so that callers can rely on the column set regardless.
.rd_topics_empty <- function() {
    out <- data.frame(
        name = character(0),
        file = character(0),
        title = character(0),
        internal = logical(0),
        is_fun = logical(0),
        stringsAsFactors = FALSE
    )
    out$alias <- list()
    out$keywords <- list()
    out$concepts <- list()
    out
}
