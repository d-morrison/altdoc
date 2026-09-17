# Every `$ALTDOC_*` variable a settings file may use.
#
# `check_altdoc()` needs this to tell apart two cases a settings file cannot
# distinguish on its own: a variable altdoc does not know at all (a typo, or one
# from a newer altdoc than the installed one), which never resolves and leaves
# the literal `$ALTDOC_...` text in the published page; and a known variable
# whose source is missing, which `.substitute_altdoc_variables()` handles by
# silently dropping the line that used it.
#
# Kept as data here rather than derived by grepping the templates: once
# `setup_docs()` has copied them, the templates under `altdoc/` are user-owned,
# so scanning them would describe whatever a user happens to have written
# rather than what altdoc actually supports --- which is the opposite of what
# the check needs.
#
# `$ALTDOC_MULTIVERSION_*`, `$ALTDOC_MKDOCS_*`, `$ALTDOC_REFS_ORDER`,
# `$ALTDOC_BRANCHES_OR_TAGS_TO_LIST` and `$ALTDOC_DEFAULT_LANDING_PAGE` are
# deliberately absent: they are placeholders in the GitHub Actions workflow
# template that `setup_github_actions()` fills in, not settings-file variables
# that `.substitute_altdoc_variables()` ever sees.
.altdoc_variable_names <- function() {
    return(c(
        # One per basic document, from the file name. `.import_basic()` decides
        # whether each resolves; see `.check_altdoc_variables()`.
        # `unique()` after `toupper()`, not before: `CHANGELOG` and `ChangeLog`
        # are two accepted file names for one variable.
        paste0("ALTDOC_", unique(toupper(.basic_file_names()))),
        # Generated rather than imported, so these resolve without a source
        # file the user has to supply.
        "ALTDOC_CITATION",
        "ALTDOC_REFERENCE",
        "ALTDOC_MAN_BLOCK",
        "ALTDOC_VIGNETTE_BLOCK",
        # Shipped by altdoc rather than by the package, so this one resolves
        # for the `quarto_website` generator and is dropped for the rest.
        "ALTDOC_SIDEBAR_FOLD",
        # Resolved from the package itself.
        "ALTDOC_LOGO",
        "ALTDOC_PACKAGE_NAME",
        "ALTDOC_PACKAGE_VERSION",
        "ALTDOC_PACKAGE_URL",
        "ALTDOC_PACKAGE_URL_GITHUB",
        "ALTDOC_VERSION"
    ))
}
