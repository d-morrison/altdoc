# Join one base directory to several relative paths.
#
# `fs::path_join()` takes a single character vector and joins its elements into
# one path, so it cannot be handed a vector of candidates directly --- passing
# `c(base, candidates)` would produce a single deep path rather than one path
# per candidate.
.path_join_all <- function(base, relative) {
    return(vapply(
        relative,
        function(x) as.character(fs::path_join(c(base, x))),
        character(1),
        USE.NAMES = FALSE
    ))
}
