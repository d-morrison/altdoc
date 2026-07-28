# The basic documents `render_docs()` imports, so a caller enumerating them
# does not have to keep its own copy of the list.
#
# `ChangeLog` is a case variant of `CHANGELOG` rather than a separate document:
# both feed the one `$ALTDOC_CHANGELOG` variable, since
# `.substitute_altdoc_variables()` upper-cases the file name to build the
# variable it looks for.
.basic_file_names <- function() {
    c(
        "NEWS",
        "CHANGELOG",
        "ChangeLog",
        "CODE_OF_CONDUCT",
        "CONTRIBUTING",
        "LICENSE",
        "LICENCE"
    )
}
