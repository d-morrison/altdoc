# The source files altdoc will accept for one of the "basic" documents it
# imports verbatim (`NEWS`, `CONTRIBUTING`, ...), in priority order.
#
# Shared by `.import_basic()`, which imports the first one that exists, and
# `check_altdoc()`, which needs the same list to answer a different question:
# whether the corresponding `$ALTDOC_*` variable will resolve on the next
# render. Duplicating the list would let the check pass a settings file whose
# variable altdoc cannot actually fill, or fail one it can --- the `.Rd` and
# `inst/` entries being the easiest to miss, since #58 found even the package's
# own documentation had omitted them.
.basic_file_candidates <- function(name = "NEWS") {
    src <- c(
        "NEWS.md",
        "NEWS.txt",
        "NEWS",
        "NEWS.Rd",
        "inst/NEWS.md",
        "inst/NEWS.txt",
        "inst/NEWS",
        "inst/NEWS.Rd"
    )
    return(gsub("NEWS", name, src, fixed = TRUE))
}
