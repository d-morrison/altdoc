# Findings about pages the site publishes but never links from its navigation.
#
# A page nothing links to is still published and still fetchable, so nothing
# fails and nothing warns --- a reader simply cannot find it by navigating. That
# makes it the class of misconfiguration most likely to survive unnoticed, and
# the reason this check exists.
#
# The `$ALTDOC_MAN_BLOCK` and `$ALTDOC_VIGNETTE_BLOCK` variables are generated
# from whatever is on disk at render time, so a settings file using them cannot
# omit anything and gets no findings. This check therefore only has work to do
# on a hand-authored navigation --- which is precisely the case
# `.sidebar_labels()` and the block builders leave entirely to the user.
#
# `kind` selects which set to check, and is a parameter rather than two
# near-identical functions because only the inputs differ: the block variable
# that makes the check moot, the names expected in the nav, and the wording.
.check_altdoc_nav <- function(path = ".", tool = "docsify", kind = "man") {
    fn <- .settings_file(path, tool)
    if (!fs::file_exists(fn)) {
        return(character(0))
    }
    settings <- .readlines(fn)

    # Variables that make every page of this kind reachable, so nothing can be
    # missing from the nav and the check has no work to do.
    #
    # `$ALTDOC_REFERENCE` counts for man pages alongside `$ALTDOC_MAN_BLOCK`:
    # it expands to the generated index, which lists every non-internal topic.
    # All four shipped templates carry both lines, and deleting the per-page
    # block while keeping the index is an ordinary way to trim a long sidebar
    # --- every topic is then two clicks away rather than one, which is
    # reachable. Reporting those pages as unreachable would be false.
    #
    # There is no vignette equivalent: an articles index is not built (see
    # #36), so only the block variable exempts a vignette.
    blocks <- switch(
        kind,
        man = c("\\$ALTDOC_MAN_BLOCK", "\\$ALTDOC_REFERENCE"),
        vignettes = "\\$ALTDOC_VIGNETTE_BLOCK"
    )
    if (any(vapply(blocks, function(b) any(grepl(b, settings)), logical(1)))) {
        return(character(0))
    }

    expected <- switch(
        kind,
        man = .rd_topics(path)$file,
        vignettes = .check_altdoc_vignette_names(path)
    )
    if (length(expected) == 0) {
        return(character(0))
    }

    # A nav entry may spell the page with or without its extension, and with or
    # without a leading directory, so match the bare name anywhere in the
    # settings file rather than a full path. That is deliberately permissive:
    # this check reports a page with no plausible mention at all, it does not
    # adjudicate how a hand-written nav spells its links.
    #
    # Permissive is not the same as unanchored, though. A plain substring test
    # matches `plot` inside `man/plot_group.md`, so a package documenting both
    # would have `plot` silently counted as linked by the entry for a different
    # page --- a false negative on exactly the name-prefix families (`plot` /
    # `plot_group`, `summary` / `summary_table`) that are ordinary in R
    # packages. Requiring the name to end at a character that cannot continue
    # one keeps the tolerance for path and extension while closing that.
    #
    # `.` terminates and `_`/`-` do not, which is what separates the two cases:
    # `hello` must match `man/hello.md`, and `plot` must not match
    # `man/plot_group.md` or `man/plot-2.md`.
    #
    # This is the same prefix hazard `.altdoc_variables_used()` avoids for
    # `$ALTDOC_PACKAGE_URL` versus `$ALTDOC_PACKAGE_URL_GITHUB`, met here in a
    # second place and solved a second way, since these names are user data
    # rather than a fixed set.
    linked <- vapply(
        expected,
        function(name) {
            pattern <- paste0(.escape_regex(name), "([^A-Za-z0-9_-]|$)")
            any(grepl(pattern, settings))
        },
        logical(1),
        USE.NAMES = FALSE
    )
    missing <- expected[!linked]
    if (length(missing) == 0) {
        return(character(0))
    }

    label <- switch(kind, man = "man page", vignettes = "vignette")
    variable <- switch(
        kind,
        man = "$ALTDOC_MAN_BLOCK",
        vignettes = "$ALTDOC_VIGNETTE_BLOCK"
    )
    return(sprintf(
        "%s is not linked from %s, so the %s is published but unreachable by navigation; add it, or use `%s` to list every one automatically.",
        paste0("`", missing, "`", collapse = ", "),
        fs::path_rel(fn, path),
        label,
        variable
    ))
}
