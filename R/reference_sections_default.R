# The reference index used when the package has no `altdoc/reference.yml`: a
# single section listing every non-internal topic, so that the index is useful
# with no configuration at all.
.reference_sections_default <- function(topics) {
    exported <- topics$name[!topics$internal]
    if (length(exported) == 0) {
        return(list())
    }
    list(list(title = "All functions", contents = as.list(exported)))
}
