# The `issue-url` a rendered quarto_website was built with, or NULL.
#
# Quarto renders a "Report an issue" action from this value and gives it the
# same `toc-action` class the source and edit actions carry, so a site is free
# to point it at a URL shaped exactly like one of them. Knowing it is what
# lets `.rewrite_man_source_links_one()` leave that one alone.
#
# Read from the settings file the render actually used, for the same reason
# `.site_repo_url()` is.
.site_issue_url <- function(src_dir) {
    settings <- fs::path_join(c(src_dir, "_quarto", "_quarto.yml"))
    if (!fs::file_exists(settings)) {
        return(NULL)
    }

    parsed <- try(yaml::read_yaml(settings), silent = TRUE)
    if (inherits(parsed, "try-error")) {
        return(NULL)
    }

    url <- parsed[["website"]][["issue-url"]]
    if (!is.character(url) || length(url) != 1 || !nzchar(url)) {
        return(NULL)
    }

    sub("/$", "", url)
}
