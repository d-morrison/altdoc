# Why a known variable will not resolve, or NULL when it will.
#
# Only the variables with a source a user is expected to supply can fail this
# way. The rest --- the generated blocks, the `DESCRIPTION`-derived names, the
# altdoc version --- either always resolve or are covered by their own check
# (`.check_altdoc_urls()` for the two URL variables), so they return NULL here
# rather than being re-checked in two places.
.altdoc_variable_source_missing <- function(variable, path = ".") {
    basics <- unique(toupper(.basic_file_names()))
    name <- sub("^ALTDOC_", "", variable)

    if (name %in% basics) {
        # Match the file name back to whichever accepted spelling altdoc
        # searches for, so `ALTDOC_CHANGELOG` covers `ChangeLog` too.
        spellings <- .basic_file_names()[toupper(.basic_file_names()) == name]
        candidates <- unlist(lapply(spellings, .basic_file_candidates))
        if (any(fs::file_exists(.path_join_all(path, candidates)))) {
            return(NULL)
        }
        return(sprintf(
            "no %s file was found (altdoc looks for %s, also under `inst/`)",
            name,
            paste0("`", unique(basename(candidates)), "`", collapse = ", ")
        ))
    }

    if (identical(name, "LOGO") && is.null(.find_logo(path))) {
        return(
            "the package ships no logo (altdoc looks for `logo.svg`, `man/figures/logo.svg`, `logo.png`, or `man/figures/logo.png`)"
        )
    }

    if (identical(name, "REFERENCE") && nrow(.rd_topics(path)) == 0) {
        return(
            "the package documents no topics, so no reference index is built"
        )
    }

    return(NULL)
}
