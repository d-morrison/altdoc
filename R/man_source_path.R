# The path, relative to the package root, that a man page's "View source" and
# "Edit this page" links should point at.
#
# The R file the topic was documented in when roxygen2 wrote the .Rd, and the
# .Rd itself when it was written by hand. A topic documented across several R
# files gets the first one roxygen2 recorded, since these links carry a single
# target each.
#
# Returns NULL when the .Rd file is gone, which leaves the rendered links
# alone rather than pointing them somewhere invented.
.man_source_path <- function(topic, src_dir) {
    rd_file <- fs::path_join(c(src_dir, "man", paste0(topic, ".Rd")))
    if (!fs::file_exists(rd_file)) {
        return(NULL)
    }

    sources <- .rd_source_files(rd_file, src_dir = src_dir)
    if (length(sources) > 0) {
        return(sources[1])
    }

    paste0("man/", topic, ".Rd")
}
