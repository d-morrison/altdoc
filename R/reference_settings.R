# Read `altdoc/reference.yml` and return its top-level pieces.
#
# The file is read once here, rather than by each consumer, so
# `.reference_title()` and `.reference_sections()` cannot disagree about what
# it says.
#
# Returns a list with:
#   - `title`: the optional page heading, or NULL to use the default
#   - `sections`: the raw (not yet validated) section list, or NULL to use the
#     default grouping
#   - `sidebar_labels`: how generators label a man page in the sidebar, or NULL
#     to use the default (`"name"`)
#   - `sidebar_label_width`: the width titles are truncated to in the sidebar,
#     or NULL to use the default
#   - `llms_txt`: FALSE to skip generating `llms.txt`, or NULL to generate it
#
# Every field is NULL when the file does not exist, so a package with no
# settings file still gets a complete index. Each return path names all five,
# so a caller never has to ask which shape it got back.
#
#   title: Function reference
#   sidebar_labels: name-and-title
#   reference:
#     - title: Data
#       contents:
#         - as_pop_data
#
# A bare list of sections at the top level (no `reference:` key) is accepted
# too, for a settings file moved over unchanged from pkgdown; such a file has
# nowhere to put the mapping keys, so `title`, both sidebar keys, and
# `llms_txt` always take their defaults.
.reference_settings <- function(src_dir = ".") {
    empty <- list(
        title = NULL,
        sections = NULL,
        sidebar_labels = NULL,
        sidebar_label_width = NULL,
        llms_txt = NULL
    )
    fn <- fs::path_join(c(src_dir, "altdoc", "reference.yml"))

    if (!fs::file_exists(fn)) {
        return(empty)
    }

    .assert_dependency("yaml")
    settings <- yaml::yaml.load_file(fn)

    if (is.null(settings) || length(settings) == 0) {
        return(empty)
    }

    # `yaml.load_file()` represents a YAML sequence as an unnamed list and a
    # YAML mapping as a named one, so `names()` is what tells the two apart:
    # an unnamed top-level list is the bare pkgdown-style section list.
    if (is.null(names(settings))) {
        empty$sections <- settings
        return(empty)
    }

    known <- c(
        "title",
        "reference",
        "sidebar_labels",
        "sidebar_label_width",
        "llms_txt"
    )
    unknown <- setdiff(names(settings), known)
    if (length(unknown) > 0) {
        cli::cli_abort(c(
            "Unknown top-level key{?s} in {.file altdoc/reference.yml}: {.val {unknown}}.",
            "i" = "Known keys are {.val {known}}."
        ))
    }

    .check_sidebar_settings(settings)
    .check_llms_txt_setting(settings)

    list(
        title = settings[["title"]],
        sections = settings[["reference"]],
        sidebar_labels = settings[["sidebar_labels"]],
        sidebar_label_width = settings[["sidebar_label_width"]],
        llms_txt = settings[["llms_txt"]]
    )
}
