# Copy whatever `.find_logo()` discovers into the rendered site, so the
# generator's settings can point at it through `$ALTDOC_LOGO`. Returns the
# logo's file name within `tar_dir`, or NULL when the package has no logo.
#
# The file keeps its original name rather than being renamed to a fixed one,
# so a package shipping `logo.svg` gets `logo.svg` in the site and the
# `$ALTDOC_LOGO` substitution resolves to a path that actually exists.
.import_logo <- function(src_dir, tar_dir) {
    src <- .find_logo(src_dir)
    if (is.null(src)) {
        return(invisible(NULL))
    }

    tar <- fs::path_join(c(tar_dir, basename(src)))
    fs::file_copy(src, tar, overwrite = TRUE)
    cli::cli_alert_success("{.file {basename(src)}} imported.")
    return(invisible(basename(src)))
}
