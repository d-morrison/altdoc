# Build the environment in which a `contents:` entry of `altdoc/reference.yml` is
# evaluated. Selector functions live in the parent environment and every topic
# name and alias is bound to its row index in the child, so a bare topic name and
# a call such as `starts_with("read_")` both evaluate to row indices of `topics`.
#
# The selectors mirror the ones pkgdown accepts in `_pkgdown.yml`, so a
# `reference:` block can be moved from pkgdown to altdoc unchanged.
.topics_env <- function(topics) {
    n <- nrow(topics)
    index <- seq_len(n)

    # Whether each topic is eligible: internal topics are opt-in, per selector.
    eligible <- function(internal) {
        if (isTRUE(internal)) rep(TRUE, n) else !topics$internal
    }

    # TRUE for each topic with any alias (or its name) matching `predicate`.
    any_alias <- function(predicate, internal) {
        hit <- vapply(
            seq_len(n),
            function(i) any(predicate(c(topics$name[i], topics$alias[[i]]))),
            logical(1)
        )
        index[hit & eligible(internal)]
    }

    any_meta <- function(column, values, internal) {
        hit <- vapply(
            topics[[column]],
            function(x) any(trimws(x) %in% values),
            logical(1)
        )
        index[hit & eligible(internal)]
    }

    fns <- new.env(parent = baseenv())

    fns$starts_with <- function(x, internal = FALSE) {
        any_alias(function(a) startsWith(a, x), internal)
    }
    fns$ends_with <- function(x, internal = FALSE) {
        any_alias(function(a) endsWith(a, x), internal)
    }
    fns$contains <- function(x, internal = FALSE) {
        any_alias(function(a) grepl(x, a, fixed = TRUE), internal)
    }
    fns$matches <- function(x, internal = FALSE) {
        any_alias(function(a) grepl(x, a), internal)
    }
    fns$has_keyword <- function(x, internal = FALSE) {
        any_meta("keywords", x, internal)
    }
    fns$has_concept <- function(x, internal = FALSE) {
        any_meta("concepts", x, internal)
    }
    fns$lacks_concepts <- function(x, internal = FALSE) {
        setdiff(index[eligible(internal)], any_meta("concepts", x, TRUE))
    }
    fns$lacks_concept <- fns$lacks_concepts
    fns$everything <- function(internal = FALSE) {
        index[eligible(internal)]
    }

    out <- new.env(parent = fns)
    # Bind aliases first and names second, so that a name always wins over
    # another topic's competing alias.
    for (i in index) {
        for (a in topics$alias[[i]]) {
            assign(a, i, envir = out)
        }
    }
    for (i in index) {
        assign(topics$name[i], i, envir = out)
    }

    out
}
