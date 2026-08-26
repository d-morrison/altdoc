.is_safe_expr <- function(expr) {
    if (is.atomic(expr) || is.name(expr)) {
        return(TRUE)
    }
    if (is.call(expr)) {
        fun <- expr[[1]]
        if (!is.name(fun)) return(FALSE)

        fun_name <- as.character(fun)
        allowed_funcs <- c(
            "-", "c",
            "starts_with", "ends_with", "contains", "matches",
            "has_keyword", "has_concept", "lacks_concepts", "lacks_concept",
            "everything"
        )

        if (!(fun_name %in% allowed_funcs)) {
            return(FALSE)
        }

        for (i in seq_along(expr)[-1]) {
            if (!.is_safe_expr(expr[[i]])) return(FALSE)
        }
        return(TRUE)
    }
    return(FALSE)
}

# Evaluate a single `contents:` entry and return the row indices of `topics` it
# selects. Indices are negative when the entry was prefixed with `-`.
.match_topic <- function(entry, topics, env) {
    if (!is.character(entry) || length(entry) != 1) {
        cli::cli_abort(
            "Every {.code contents} entry of {.file altdoc/reference.yml} must be a single string."
        )
    }

    # Exact match first: topic names such as `[.myclass` or `%+%` are bound in
    # `env` but are not parseable as the R code that names them.
    if (exists(entry, envir = env, inherits = FALSE)) {
        return(get(entry, envir = env, inherits = FALSE))
    }

    expr <- tryCatch(
        str2lang(entry),
        error = function(e) NULL
    )
    if (is.null(expr)) {
        cli::cli_abort(c(
            "{.val {entry}} in {.file altdoc/reference.yml} is not a known topic and is not valid R code.",
            "i" = "Quote special YAML values, for example {.code '-'} or {.code 'N'}."
        ))
    }

    if (!.is_safe_expr(expr)) {
        cli::cli_abort(c(
            "{.val {entry}} in {.file altdoc/reference.yml} is not a supported selection call.",
            "i" = "Supported selectors are {.code starts_with()}, {.code ends_with()}, {.code contains()}, {.code matches()}, {.code has_keyword()}, {.code has_concept()}, {.code lacks_concepts()}, {.code lacks_concept()}, and {.code everything()}."
        ))
    }

    # A bare name that reached this point was not bound, so it names no topic.
    if (is.name(expr) || is.character(expr)) {
        cli::cli_abort(c(
            "{.val {entry}} in {.file altdoc/reference.yml} is not a known topic name or alias.",
            "i" = "Topic names come from the {.code \\name{}} tag of each file in {.file man/}."
        ))
    }

    out <- tryCatch(
        eval(expr, envir = env),
        error = function(e) e
    )
    if (inherits(out, "error")) {
        cli::cli_abort(c(
            "Could not evaluate {.val {entry}} in {.file altdoc/reference.yml}.",
            "x" = conditionMessage(out)
        ))
    }
    if (!is.numeric(out)) {
        cli::cli_abort(
            "{.val {entry}} in {.file altdoc/reference.yml} must select topics, not return {.cls {class(out)[1]}}."
        )
    }

    as.integer(out)
}
