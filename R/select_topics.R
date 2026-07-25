# Resolve the `contents:` entries of one `altdoc/reference.yml` section to row
# indices of `topics`, in the order the user listed them.
#
# Each entry is evaluated as R code in the environment built by `.topics_env()`,
# so a bare topic name, an alias, and a selector call such as
# `starts_with("read_")` are all valid. An entry prefixed with `-` removes its
# matches instead of adding them; when the first entry is a removal, the
# selection starts from every non-internal topic.
.select_topics <- function(contents, topics, env = NULL) {
    if (length(contents) == 0 || nrow(topics) == 0) {
        return(integer(0))
    }
    if (is.null(env)) {
        env <- .topics_env(topics)
    }

    matched <- lapply(contents, .match_topic, topics = topics, env = env)

    selected <- integer(0)
    for (i in seq_along(matched)) {
        idx <- matched[[i]]
        if (length(idx) == 0) {
            next
        }
        if (all(idx < 0)) {
            if (i == 1L) {
                selected <- which(!topics$internal)
            }
            selected <- setdiff(selected, -idx)
        } else if (all(idx > 0)) {
            selected <- union(selected, idx)
        } else {
            cli::cli_abort(
                "Cannot mix selected and de-selected topics in a single {.code contents} entry: {.val {contents[[i]]}}."
            )
        }
    }

    selected
}
