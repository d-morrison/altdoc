# Double the braces in `x` so cli renders them literally.
#
# cli formats every string it is handed through glue, so a brace in text altdoc
# is only relaying --- an error message, a URL, a file name --- is interpreted
# rather than printed. Doubling is glue's own escape for a literal brace.
.escape_braces <- function(x) {
    x <- gsub("{", "{{", x, fixed = TRUE)
    return(gsub("}", "}}", x, fixed = TRUE))
}
