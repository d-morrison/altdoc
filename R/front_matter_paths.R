# Front-matter keys whose values Quarto resolves as paths, relative to the
# file declaring them -- the same resolution `{{< include >}}` uses, which is
# why `.stage_external_includes()` can stage both through one code path.
#
# `filters:` and `shortcodes:` also accept bare extension names (`quarto`,
# `authors-block`) rather than paths. Those are left in the returned vector:
# the caller only stages an entry that escapes the staged tree via `..` AND
# exists in the source tree, and a bare name satisfies neither.
.front_matter_path_keys <- c("shortcodes", "filters", "metadata-files")

# Return the path-valued front-matter entries of a document.
#
# Quarto lets a document pull in a Lua filter or shortcode by relative path
# (`shortcodes: [../_extensions/foo/foo.lua]`). Such a path can point outside
# the staged `_quarto/` tree exactly as an `{{< include >}}` can, and needs
# staging for the same reason -- see `.stage_external_includes()`.
.front_matter_paths <- function(lines) {
    front_matter <- .front_matter_lines(lines)
    if (length(front_matter) == 0) {
        return(character(0))
    }

    # Assert rather than fold a missing yaml into the tryCatch below: every
    # other step of the quarto_website flow calls `yaml::` unguarded, so an
    # absent yaml is a broken install, not a document to skip quietly. Doing
    # otherwise would stage nothing and leave Quarto to fail later with an
    # error naming a missing Lua filter instead of the real cause.
    .assert_dependency("yaml")

    # A document whose front matter does not parse is Quarto's error to
    # report, with far better diagnostics than this staging pass could give;
    # stage nothing and let the render surface it.
    parsed <- tryCatch(
        yaml::yaml.load(paste(front_matter, collapse = "\n")),
        error = function(e) NULL
    )
    if (!is.list(parsed)) {
        return(character(0))
    }

    values <- unlist(
        parsed[intersect(names(parsed), .front_matter_path_keys)],
        use.names = FALSE
    )
    # `unlist()` coerces to a single type, so this is all-or-nothing by
    # design: a key holding only numbers yields a numeric vector and is
    # dropped whole. A number mixed among strings survives as its coerced
    # text, which the caller's own guards then reject -- it neither escapes
    # the staged tree via `..` nor names a file that exists.
    if (!is.character(values)) {
        return(character(0))
    }
    unique(trimws(values))
}
