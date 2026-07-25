# Is this topic callable? Datasets and package-level pages are listed without
# trailing parentheses in the reference index, functions with them.
#
# A dataset is identified by \docType{data}, and otherwise a topic counts as a
# function when its \usage{} section calls one of its own aliases.
.rd_is_function <- function(rd, name) {
    doctype <- .rd_tag_values(rd, "\\docType")
    if (any(doctype %in% c("data", "package"))) {
        return(FALSE)
    }

    usage <- .rd_tag_node(rd, "\\usage")
    if (is.null(usage)) {
        return(FALSE)
    }
    usage <- .rd_flatten_text(usage)

    # \name{} is usually an alias too, so drop the duplicate it would create.
    aliases <- unique(c(name, .rd_tag_values(rd, "\\alias")))
    # A usage entry is a call when the alias is followed by an opening paren.
    # Aliases such as `[.myclass` contain regex metacharacters, so match on the
    # fixed string rather than building a pattern from them.
    calls <- paste0(aliases, "(")
    any(vapply(calls, grepl, logical(1), x = usage, fixed = TRUE))
}
