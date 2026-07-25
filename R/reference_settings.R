# Read `altdoc/reference.yml` and return its two top-level pieces.
#
# The file is read once here, rather than by each consumer, so
# `.reference_title()` and `.reference_sections()` cannot disagree about what
# it says.
#
# Returns a list with:
#   - `title`: the optional page heading, or NULL to use the default
#   - `sections`: the raw (not yet validated) section list, or NULL to use the
#     default grouping
#
# Both are NULL when the file does not exist, so a package with no settings
# file still gets a complete index.
#
#   title: Function reference
#   reference:
#     - title: Data
#       contents:
#         - as_pop_data
#
# A bare list of sections at the top level (no `reference:` key) is accepted
# too, for a settings file moved over unchanged from pkgdown; such a file has
# nowhere to put `title`, so it always uses the default.
.reference_settings <- function(src_dir = ".") {
    empty <- list(title = NULL, sections = NULL)
    fn <- fs::path_join(c(src_dir, "altdoc", "reference.yml"))

    if (!fs::file_exists(fn)) {
        return(empty)
    }

    .assert_dependency("yaml")
    settings <- yaml::yaml.load_file(fn)

    if (is.null(settings) || length(settings) == 0) {
        return(empty)
    }

    # An unnamed list is the bare pkgdown-style section list.
    if (is.null(names(settings))) {
        return(list(title = NULL, sections = settings))
    }

    known <- c("title", "reference")
    unknown <- setdiff(names(settings), known)
    if (length(unknown) > 0) {
        cli::cli_abort(c(
            "Unknown top-level key{?s} in {.file altdoc/reference.yml}: {.val {unknown}}.",
            "i" = "Known keys are {.val {known}}."
        ))
    }

    list(title = settings[["title"]], sections = settings[["reference"]])
}
