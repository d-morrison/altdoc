# Find a package's logo, searching the conventional locations in the same
# priority order `pkgdown`'s `find_logo()` uses. Returns the path to the first
# candidate that exists, or NULL when the package has no logo.
#
# `.svg` beats `.png` at each location because it scales without loss, and the
# package root beats `man/figures/` because a logo placed there is the more
# deliberate of the two.
.find_logo <- function(path = ".") {
    candidates <- c(
        "logo.svg",
        "man/figures/logo.svg",
        "logo.png",
        "man/figures/logo.png"
    )
    # `fs::path()` is vectorized, so the candidates keep their `fs_path` class
    # rather than being flattened to plain character by a per-element call.
    candidates <- fs::path(path, candidates)
    candidates <- candidates[fs::file_exists(candidates)]

    if (length(candidates) == 0) {
        return(NULL)
    }
    # Priority is hard-coded by the order of the vector above.
    return(candidates[1])
}
