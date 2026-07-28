# The variables that are alternatives to `variable`, itself included.
.altdoc_variable_group <- function(variable) {
    groups <- .altdoc_variable_alternatives()
    for (g in groups) {
        if (variable %in% g) {
            return(g)
        }
    }
    return(variable)
}
