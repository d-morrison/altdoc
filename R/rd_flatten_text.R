# Walk a node of a parsed Rd object and render it as Markdown. Inline markup is
# mapped to its Markdown equivalent (\code{} to backticks, \emph{} to asterisks,
# and so on) so that a short fragment such as a \title{} can be embedded in a
# generated Markdown page.
#
# This is deliberately much smaller than a full Rd-to-HTML translator: it only
# covers the inline markup that occurs in short fragments, it does not resolve
# links, and it does not evaluate \Sexpr{}.
.rd_flatten_text <- function(x) {
    tag <- attr(x, "Rd_tag")
    if (is.null(tag)) {
        tag <- ""
    }

    # parse_Rd() emits a USERMACRO token followed by its expansion, so rendering
    # the token as well would duplicate the macro's content.
    if (tag %in% c("USERMACRO", "COMMENT", "\\Sexpr")) {
        return("")
    }

    # \if{format}{yes} and \ifelse{format}{yes}{no}: the first child is the
    # target format, so only one branch applies to Markdown output.
    if (tag %in% c("\\if", "\\ifelse")) {
        return(.rd_flatten_conditional(x))
    }

    if (is.character(x)) {
        return(paste(x, collapse = ""))
    }

    if (tag %in% c("\\dots", "\\ldots")) {
        return("...")
    }

    inner <- paste(
        vapply(x, .rd_flatten_text, character(1)),
        collapse = ""
    )

    switch(
        tag,
        "\\code" = ,
        "\\command" = ,
        "\\env" = ,
        "\\file" = ,
        "\\kbd" = ,
        "\\option" = ,
        "\\samp" = ,
        "\\verb" = .rd_code_span(inner),
        "\\pkg" = paste0("{", inner, "}"),
        "\\acronym" = ,
        "\\cite" = ,
        "\\dfn" = ,
        "\\emph" = ,
        "\\var" = paste0("*", inner, "*"),
        "\\bold" = ,
        "\\strong" = paste0("**", inner, "**"),
        "\\dQuote" = paste0("\"", inner, "\""),
        "\\sQuote" = paste0("'", inner, "'"),
        "\\deqn" = ,
        "\\eqn" = paste0("$", inner, "$"),
        "\\R" = "R",
        "\\cr" = " ",
        inner
    )
}
