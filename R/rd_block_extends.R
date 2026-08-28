# Does appending this continuation line to a provenance block leave a filename
# the package actually has?
#
# roxygen2 wraps the backref comment with `strwrap()`, which breaks at any
# space -- so a continuation follows a comma most of the time, and follows part
# of a filename when the filename itself contains a space. Neither shape can be
# told from an unrelated indented Rd comment by looking at it, and guessing
# wrong costs a real source link either way.
#
# So ask the filesystem instead of the text: the block extends if its last
# comma-separated entry, once joined, names a file that exists.
.rd_block_extends <- function(block, src_dir) {
    entries <- strsplit(block, ",", fixed = TRUE)[[1]]
    if (length(entries) == 0) {
        return(FALSE)
    }

    last <- trimws(entries[length(entries)])
    nzchar(last) && fs::file_exists(fs::path_join(c(src_dir, last)))
}
