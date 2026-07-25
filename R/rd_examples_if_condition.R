# Return the condition text of a roxygen2 `@examplesIf` block, or NULL.
#
# roxygen2 has no Rd tag for a conditional example, so it emits the condition as
# a `\dontshow{}` wrapper around the example:
#
#   \dontshow{if (cond) (if (getRversion() >= "3.4") withAutoprint else force)({ # examplesIf}
#   example_code()
#   \dontshow{}) # examplesIf}
#
# Reading it back means recognizing that generated shape. This looks for it in
# the parsed Rd tree, where the wrapper is a single `\dontshow` node whose text
# ends in the `# examplesIf` marker roxygen2 appends --- rather than searching
# the whole deparsed Rd object for the sentinel, which could match the same
# string occurring anywhere else on the page.
#
# See roxygen2's `rd-examples.R` for the generating side.
.rd_examples_if_condition <- function(rd) {
    node <- .rd_tag_node(rd, "\\examples")
    if (is.null(node)) {
        return(NULL)
    }

    open_call <- '(if (getRversion() >= "3.4") withAutoprint else force)({'

    for (child in node) {
        tag <- attr(child, "Rd_tag")
        if (!identical(tag, "\\dontshow")) {
            next
        }

        text <- .rd_example_code(child)
        if (!grepl("# examplesIf", text, fixed = TRUE)) {
            next
        }
        # The closing half of the wrapper carries the same marker but no
        # condition, so it must not be mistaken for the opening half.
        if (!grepl(open_call, text, fixed = TRUE)) {
            next
        }

        condition <- sub("^\\s*if\\s*\\(", "", text)
        condition <- sub(
            paste0("\\)\\s*\\Q", open_call, "\\E.*$"),
            "",
            condition,
            perl = TRUE
        )
        return(condition)
    }

    NULL
}
