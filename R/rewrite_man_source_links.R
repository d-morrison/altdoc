# Point each man page's repo-action links at a file the repository actually
# holds.
#
# A `quarto_website` man page is rendered from `_quarto/man/<topic>.qmd`, which
# `render_docs()` generates from `man/<topic>.Rd` and never commits. Quarto
# builds the "View source" and "Edit this page" links (`repo-actions:`) from
# that input path, so both land on a file that is not in the repository and
# both 404. The topic's real source is the R file it was documented in, or the
# .Rd file when the package writes its man pages by hand.
#
# A site that does not set `repo-actions:` renders no such links, and one that
# records no `repo-url` is left alone deliberately, so this is a no-op for
# both.
#
# The `repo-url` read is the project-level one. Quarto lets a page override it,
# and such a page keeps its generated .qmd link rather than being rewritten
# against the wrong repository -- a gap in coverage, never a wrong link.
#
# `.find_github_source()` answers a related question for the other generators,
# which have no repo actions to repoint: it builds a whole URL, down to the line
# the function is defined on, and inserts it into the page body. Here Quarto has
# already written the repository, the branch, and any `repo-subdir:` into the
# href, so only the path within the repository is wanted.
.rewrite_man_source_links <- function(docs_dir, src_dir) {
    man_dir <- fs::path_join(c(docs_dir, "man"))
    if (!fs::dir_exists(man_dir)) {
        return(invisible())
    }

    # Without a recorded `repo-url` there is nothing that separates a repo
    # action from a "Report an issue" link built out of an arbitrary
    # `issue-url`, which carries the same class -- so a site that records none
    # is left alone rather than rewritten on a guess.
    repo_url <- .site_repo_url(src_dir)
    if (is.null(repo_url)) {
        return(invisible())
    }
    issue_url <- .site_issue_url(src_dir)

    html_files <- fs::dir_ls(man_dir, type = "file", glob = "*.html")
    for (html_file in html_files) {
        topic <- fs::path_ext_remove(basename(html_file))
        source_path <- .man_source_path(topic, src_dir = src_dir)
        if (is.null(source_path)) {
            next
        }
        .rewrite_man_source_links_one(
            html_file,
            topic,
            source_path,
            repo_url = repo_url,
            issue_url = issue_url
        )
    }

    invisible()
}
