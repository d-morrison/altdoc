# The settings file `$ALTDOC_*` variables are substituted into, for one tool.
#
# Each generator keeps its navigation and its variables in a single file under
# `altdoc/`, and which one it is has to be known in two places: `render_docs()`
# reads it to build the site, and `check_altdoc()` reads it to validate it
# without rendering. Keeping the mapping here means the two cannot disagree
# about which file carries a generator's settings.
#
# `docsify` is the one generator whose `$ALTDOC_*` variables live in two files:
# the sidebar in `docsify.md` (returned here) and the page body in
# `docsify.html`, which `.settings_docsify()` substitutes separately. Callers
# that need every file carrying variables should use
# `.settings_files_with_variables()` below.
.settings_file <- function(path = ".", tool = "docsify") {
    fn <- switch(
        tool,
        docsify = "docsify.md",
        docute = "docute.html",
        mkdocs = "mkdocs.yml",
        quarto_website = "quarto_website.yml"
    )
    return(fs::path_join(c(path, "altdoc", fn)))
}
