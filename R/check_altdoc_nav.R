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

    block <- switch(
        kind,
        man = "\\$ALTDOC_MAN_BLOCK",
        vignettes = "\\$ALTDOC_VIGNETTE_BLOCK"
    )
    # The block generates every entry, so nothing can be missing from the nav.
    if (any(grepl(block, settings))) {
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
    # without a leading directory, so match on the bare name appearing anywhere
    # in the settings file rather than on a full path. That is deliberately
    # permissive: this check should report a page with no plausible mention at
    # all, not adjudicate how a hand-written nav spells its links.
    linked <- vapply(
        expected,
        function(name) any(grepl(name, settings, fixed = TRUE)),
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
    sprintf(
        "%s is not linked from %s, so the %s is published but unreachable by navigation; add it, or use `%s` to list every one automatically.",
        paste0("`", missing, "`", collapse = ", "),
        fs::path_rel(fn, path),
        label,
        variable
    )
}
