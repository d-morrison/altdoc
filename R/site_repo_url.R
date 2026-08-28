# The `repo-url` a rendered quarto_website was built with, or NULL.
#
# Quarto builds every repo action's URL from this value, so it is the one thing
# that separates a "View source" or "Edit this page" link from a "Report an
# issue" link built from an arbitrary `issue-url` -- the class and the
# `/blob/` or `/edit/` segment are shapes an `issue-url` is free to imitate.
#
# Read from the settings file the render actually used rather than from
# `altdoc/`, so a site whose workflow rewrites the value before rendering is
# matched on what it rendered with. A site that leaves `repo-url` out has
# nothing here to match against, and none of this narrows anything.
.site_repo_url <- function(src_dir) {
    settings <- fs::path_join(c(src_dir, "_quarto", "_quarto.yml"))
    if (!fs::file_exists(settings)) {
        return(NULL)
    }

    parsed <- try(yaml::read_yaml(settings), silent = TRUE)
    if (inherits(parsed, "try-error")) {
        return(NULL)
    }

    url <- parsed[["website"]][["repo-url"]]
    if (!is.character(url) || length(url) != 1 || !nzchar(url)) {
        return(NULL)
    }

    sub("/$", "", url)
}
