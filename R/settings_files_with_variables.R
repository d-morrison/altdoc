# Every settings file whose `$ALTDOC_*` variables are substituted at render
# time, so a check over them covers the same text `render_docs()` would.
#
# This is `.settings_file()` plus `docsify.html`, which is easy to overlook: it
# carries `$ALTDOC_PACKAGE_URL_GITHUB` and `$ALTDOC_PACKAGE_NAME`, and it is
# substituted by `.settings_docsify()` rather than by `.import_settings()`. A
# check reading only `.settings_file()` would therefore pass a docsify site
# whose body template has an unknown variable in it.
.settings_files_with_variables <- function(path = ".", tool = "docsify") {
    out <- .settings_file(path, tool)
    if (identical(tool, "docsify")) {
        out <- c(out, fs::path_join(c(path, "altdoc", "docsify.html")))
    }
    return(out[fs::file_exists(out)])
}
