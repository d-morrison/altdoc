# The vignette page names a rendered site would carry, from the source tree.
#
# Read from `vignettes/` rather than from a rendered `docs/`, because
# `check_altdoc()` is meant to run *before* a render --- checking the output
# would report every page as missing on a package that has not been rendered
# yet, which is the state a first-time user is in.
.check_altdoc_vignette_names <- function(path = ".") {
    dir <- fs::path_join(c(path, "vignettes"))
    if (!fs::dir_exists(dir)) {
        return(character(0))
    }
    files <- list.files(dir, pattern = "\\.Rmd$|\\.qmd$|\\.md$|\\.pdf$")
    as.character(fs::path_ext_remove(files))
}
