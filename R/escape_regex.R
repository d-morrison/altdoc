# Quote a string so it matches literally inside a regular expression.
#
# Topic and vignette names are user data, and a mangled one is full of regex
# metacharacters --- roxygen2 writes `%+%` to `grapes-plus-grapes`, but `[.foo`
# to `sub-.foo`, whose `.` would otherwise match any character. Needed wherever
# a name has to be both quoted and anchored, which rules out `fixed = TRUE`.
.escape_regex <- function(x) {
    return(gsub("([][{}()*+?.\\^$|])", "\\\\\\1", x))
}
