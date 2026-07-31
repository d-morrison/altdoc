# Stage the sidebar-fold partial into the render directory.
#
# The partial is altdoc's rather than the user's, so it is not copied into
# `altdoc/` by `setup_docs()` and does not become a file each site maintains
# its own drifting copy of. It is written straight into the render directory
# at `render_docs()` time, which also means a site picks up fixes to it by
# upgrading altdoc rather than by re-copying a snippet.
#
# The initial state is baked in here rather than read by the script at run
# time, because the script runs in `<head>` to beat the first paint and has
# nothing to read a setting from at that point.
#
# Returns the staged file's name, for the settings file to point at, or NULL
# when the partial could not be staged --- which the caller turns into the
# same drop-the-line behavior every other unresolvable variable gets.
.import_sidebar_fold <- function(src_dir = ".", tar_dir = NULL) {
    src <- system.file(
        "quarto_website/sidebar-fold.html",
        package = "altdoc"
    )
    if (!nzchar(src) || !fs::file_exists(src)) {
        return(NULL)
    }

    folded <- .sidebar_fold_default(src_dir)
    contents <- .readlines(src)
    contents <- gsub(
        "@ALTDOC_FOLD_DEFAULT@",
        if (isTRUE(folded)) "true" else "false",
        contents,
        fixed = TRUE
    )

    name <- "sidebar-fold.html"
    writeLines(contents, fs::path_join(c(tar_dir, name)))
    return(name)
}

# TRUE when the sidebar should start folded.
#
# Unfolded is the default because it is what a site gets without the setting,
# and a reader who has never seen the button should be shown the navigation
# rather than left to discover that it exists.
.sidebar_fold_default <- function(src_dir = ".") {
    settings <- .reference_settings(src_dir)
    identical(settings[["sidebar_fold"]], "collapsed")
}
