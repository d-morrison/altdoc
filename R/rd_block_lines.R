# How many of a provenance block's candidate continuation lines belong to it.
#
# roxygen2 wraps the backref comment with `strwrap()`, which breaks at any
# space: after a comma usually, and part-way through a filename that contains
# one -- possibly more than once, and for more than one filename. An unrelated
# Rd comment following the block is indented identically, and Rd allows one
# there.
#
# Nothing in the text separates those, so the block is taken as the longest run
# of candidate lines that leaves every entry naming a file the package has. A
# comma-terminated block is still growing whatever the filesystem says, so that
# case short-circuits.
#
# A stale entry must not cost the rest, so the run is scored by how many
# entries resolve rather than by whether all of them do, and the shortest run
# achieving the best score wins -- consuming a foreign comment is the harm to
# avoid, so a tie does not buy another line.
#
# Two shapes stay ambiguous and no parser resolves them: a filename containing
# a comma, which roxygen2's own comma-joined format cannot express, and a
# trailing comment whose text happens to complete an existing filename. Both
# lose the R source and fall back to the .Rd, which is a link that works.
.rd_block_lines <- function(block, candidates, src_dir) {
    resolved <- function(n) {
        joined <- paste(c(block, candidates[seq_len(n)]), collapse = " ")
        entries <- trimws(strsplit(joined, ",", fixed = TRUE)[[1]])
        entries <- entries[nzchar(entries)]
        if (length(entries) == 0) {
            return(0L)
        }
        # `fs::path()` rather than `fs::path_join()`: the latter joins a whole
        # vector into one path, which would ask about a single nonexistent
        # directory chain instead of about each entry
        sum(fs::file_exists(fs::path(src_dir, entries)))
    }

    kept <- 0L
    best <- resolved(0L)

    for (n in seq_along(candidates)) {
        score <- resolved(n)
        if (score > best) {
            best <- score
            kept <- n
        }
    }

    kept
}
