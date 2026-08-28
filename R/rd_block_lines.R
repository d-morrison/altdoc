# How many of a provenance block's candidate continuation lines belong to it.
#
# roxygen2 wraps the backref comment with `strwrap()`, which breaks at any
# space: after a comma usually, and part-way through a filename that contains
# one -- possibly more than once, and for more than one filename. An unrelated
# Rd comment following the block is indented identically, and Rd allows one
# there.
#
# Nothing in the text separates those, so the block is scored against the
# filesystem instead. A comma-terminated block is still growing whatever the
# filesystem says, so that case short-circuits before this is asked.
#
# A stale entry must not cost the rest, so the run is scored by how many
# entries resolve rather than by whether all of them do, and the shortest run
# achieving the best score wins -- consuming a foreign comment is the harm to
# avoid, so a tie does not buy another line.
#
# Four shapes stay ambiguous, and scoring does not resolve them because the
# text genuinely does not say which reading is meant:
#
#   * a filename containing a comma, which roxygen2's comma-joined format
#     cannot express;
#   * a trailing comment whose text happens to complete an existing filename;
#   * a filename holding two consecutive spaces, which `strwrap()` normalizes
#     to one before the comment is ever written;
#   * a wrap whose first fragment is itself an existing file, so both readings
#     score alike and the tie keeps the shorter one.
#
# The first three lose the source file and fall back to the .Rd, which is a
# link that works. The last links to a real file that is the wrong one. All
# four need a package to hold a filename shaped to collide with the format, so
# they are recorded rather than guarded.
#
# A comment beginning with a comma used to be listed here as a fifth. It is
# not ambiguous at all: roxygen2 cannot emit a continuation starting with a
# comma, so `.rd_source_files()` rejects that line before scoring sees it.
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
