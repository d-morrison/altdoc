# Write `llms.txt` at the site root.
#
# Must run after `.import_man()` and `.import_vignettes()`, since the vignette
# list is read from what those actually produced rather than from the source
# tree -- a vignette that failed to render should not be advertised.
#
# Opt out with `llms_txt: false` in `altdoc/reference.yml`.
.import_llms_txt <- function(src_dir, tar_dir, tool = "docsify") {
    settings <- .reference_settings(src_dir)
    if (isFALSE(settings$llms_txt)) {
        .remove_llms_txt(tar_dir)
        return(invisible())
    }

    topics <- .rd_topics(src_dir)
    vignettes <- .llms_txt_vignettes(src_dir, tar_dir, tool)

    # Count the topics that will actually be listed, not every documented one.
    # `.llms_txt()` drops internal topics, so a package whose topics are all
    # internal has nothing indexable: gating on `nrow(topics)` would write a
    # file holding only the H1 and the title, with no `## Reference` section.
    listed <- .llms_txt_listed(topics)

    if (nrow(listed) == 0 && nrow(vignettes) == 0) {
        .remove_llms_txt(tar_dir)
        return(invisible())
    }

    base <- .site_url(src_dir)
    if (is.null(base)) {
        cli::cli_alert_info(
            "No site {.field URL} found, so {.file llms.txt} links are
             site-relative."
        )
    }

    content <- .llms_txt(
        pkg_name = .pkg_name(src_dir),
        pkg_title = desc::desc_get_field(
            "Title",
            default = NULL,
            file = src_dir
        ),
        topics = topics,
        vignettes = vignettes,
        base = base,
        ext = .llms_txt_ext(tool)
    )
    writeLines(content, fs::path_join(c(tar_dir, "llms.txt")))

    cli::cli_alert_success(
        "{.file llms.txt} written with {nrow(listed)} topic{?s} and
         {nrow(vignettes)} article{?s}."
    )

    invisible()
}

# Drop a previously published `llms.txt`.
#
# Both early returns above need this, because a render does not start from an
# empty target for most generators: `render_docs()` clears its whole render
# directory only for `quarto_website`, where it is the throwaway `_quarto/`.
# For docsify, docute, and mkdocs the target is `docs/`, which is never
# cleared, so a file written by an earlier render simply stays.
#
# Without this, `llms_txt: false` does not do what it says: the site keeps
# serving the index from before the opt-out, and it goes stale as topics and
# vignettes change. The same holds when a package's topics all become
# internal. `.import_man()` deletes its own leftover `.Rd` copies after every
# render for the same reason.
.remove_llms_txt <- function(tar_dir) {
    fn <- fs::path_join(c(tar_dir, "llms.txt"))
    if (fs::file_exists(fn)) {
        fs::file_delete(fn)
    }
    invisible()
}

# One vignette's display title, falling back to its bare file name.
#
# `.get_vignettes_titles()` strips only a `.md` suffix when it gives up, so it
# hands back the file name with its extension intact for anything else --
# `manual.pdf`, or `guide.qmd` when no source vignette of that name is found to
# read a title from. Publishing that verbatim puts the extension in the link
# text, and disagrees with the quarto_website sidebar, which strips `.pdf`.
#
# The bare file name is the right fallback; the tell that we got one is that
# the returned title still equals the file's own basename. A real title never
# does, and a `.md` vignette's own fallback already has its extension removed,
# so this only fires where it should.
.llms_txt_title <- function(fn, src_dir) {
    name <- fs::path_ext_remove(basename(fn))
    title <- .get_vignettes_titles(fn, path = src_dir)

    if (length(title) == 0 || is.na(title[[1]])) {
        return(.llms_txt_doc_title(fn, name))
    }
    title <- as.character(title[[1]])

    if (identical(title, basename(fn))) {
        return(.llms_txt_doc_title(fn, name))
    }
    title
}

# The title a document declares about itself, or `name` when it declares none.
#
# `.get_vignettes_titles()` reaches its own fallbacks only when its same-name
# source lookup leaves `out` empty, and that lookup is non-recursive -- so for
# a nested `vignettes/articles/deep-dive.qmd` it finds nothing, leaves `out`
# seeded to the bare file name, and never consults the content it already read.
# A top-level vignette of the same shape gets a real title. Reading the
# document here restores that symmetry.
#
# Done in this function rather than by making that lookup recursive: it is a
# shared helper on `main` with other callers, so widening its search would
# change titles elsewhere in the package to fix a gap that is ours.
#
# Front matter comes first because that is where a Quarto or R Markdown
# vignette actually declares its title -- this repo's own
# `vignettes/get-started.Rmd` has `title: "Get started"` and no body heading at
# all, and Quarto builds its sidebar label from the same field. A body `# `
# heading is the fallback for a document with no front matter.
#
# A `.pdf` is binary: there is nothing to read, so it keeps its file name.
.llms_txt_doc_title <- function(fn, name) {
    if (identical(tolower(fs::path_ext(fn)), "pdf")) {
        return(name)
    }

    lines <- .readlines(fn)

    title <- .llms_txt_yaml_title(.front_matter_lines(lines))
    if (!is.null(title)) {
        return(title)
    }

    heading <- .llms_txt_body_heading(lines)
    if (!is.null(heading)) {
        return(heading)
    }
    name
}

# The `title:` value from a document's front matter, or NULL.
#
# Anchored at column 0 so an indented `title:` nested under another key (a
# `format:` block, say) is not mistaken for the document's own.
.llms_txt_yaml_title <- function(front_matter) {
    idx <- grep("^title:", front_matter)
    if (length(idx) == 0) {
        return(NULL)
    }

    value <- trimws(sub("^title:[[:space:]]*", "", front_matter[idx[1]]))
    # YAML quoting is optional, so accept either form and strip a matched pair.
    value <- sub('^"(.*)"$', "\\1", value)
    value <- sub("^'(.*)'$", "\\1", value)

    if (!nzchar(value)) {
        return(NULL)
    }
    value
}

# The document's first body heading, ignoring fenced code blocks.
#
# `#` opens a comment in R, Python, and shell alike, so a chunk containing
# `# read the static settings` at column 0 looks exactly like a heading to a
# plain grep. This repo's `vignettes/customize.qmd` has several, and is saved
# only by its real heading happening to come first. Publishing a code comment
# as an article's title is worse than falling back to the file name, since it
# looks deliberate.
#
# `.get_vignettes_titles()`'s own H1 grep has the same blind spot; it is not
# corrected here because it is `main`'s, and its callers are not ours.
.llms_txt_body_heading <- function(lines) {
    fence_re <- "^[[:space:]]*(```|~~~)"
    in_fence <- cumsum(grepl(fence_re, lines)) %% 2 == 1
    # The closing fence itself is still part of the block.
    in_fence <- in_fence | grepl(fence_re, lines)

    idx <- grep("^# \\w+", lines)
    idx <- idx[!in_fence[idx]]
    if (length(idx) == 0) {
        return(NULL)
    }
    sub("^# ", "", lines[idx[1]])
}

# The extension of the page a consumer can actually fetch.
#
# This deliberately mirrors `.import_reference()`'s split -- quarto_website on
# one side, every other generator on the other -- because the underlying fact
# is the same: quarto_website is the only generator that does not leave the
# Markdown in the published tree. docsify and docute fetch it at runtime, and
# mkdocs builds HTML alongside the `.md` sources rather than replacing them.
# Markdown is also the better target when it is available: an LLM gets the
# source instead of a page it has to strip tags from.
#
# Do not give mkdocs `.html` on the reasoning that it "builds HTML": its
# config does not set `use_directory_urls`, so mkdocs' default of `TRUE`
# applies and pages are served at `/man/foo/`, never `/man/foo.html`. An
# extension-based HTML link is wrong for it in two ways at once.
.llms_txt_ext <- function(tool) {
    if (identical(tool, "quarto_website")) "html" else "md"
}

# Vignettes actually present in the rendered site, with their titles and the
# extension each one is published under.
#
# The file set differs by generator, and matching the wrong one goes wrong in
# both directions:
#
#   - quarto_website gets `vignettes/` copied verbatim (`.import_vignettes()`
#     returns early for it), so the sources are what is there and Quarto
#     renders them. A `.Rmd` vignette is published and listed in the sidebar,
#     so a pattern that only knows `.qmd` silently drops it.
#   - Every other generator renders down to `.md` -- but
#     `.render_one_vignette()` copies the source in first and, unlike
#     `.import_man()`, never deletes it. So `customize.qmd` sits beside the
#     `customize.md` built from it, and a pattern matching both lists the same
#     vignette twice.
#
# Hence one pattern per generator, taking the sidebar builders as the evidence
# of what each one leaves behind, plus a dedup by name as a backstop for a
# package that hand-authors a `.md` vignette alongside a `.qmd` of the same
# name.
#
# The sidebars are evidence, not the specification: this file indexes what is
# *fetchable*, which is a wider set than what is *linked from the nav*. Three
# places where the two deliberately differ, all checked against the builders
# rather than assumed:
#
#   - `.sidebar_vignettes_docute()` matches only `\\.md$`, so its sidebar omits
#     a `.pdf` vignette -- but `.render_one_vignette()` copies the source in
#     regardless, so the file is published and fetchable. It is listed here.
#   - `.sidebar_vignettes_quarto_website()` matches `\\.qmd$|\\.Rmd|\\.pdf$`,
#     omitting a hand-authored `.md` vignette that Quarto still renders.
#     Listed here.
#   - `.sidebar_vignettes_docsify()` and `.sidebar_vignettes_mkdocs()` both
#     match `\\.md$|\\.pdf$`, so they agree with this function.
#
# Do not "fix" any of these to match a sidebar: a page a consumer can fetch
# belongs in the index whether or not the human-facing nav happens to link it.
#
# `ext` is per-vignette rather than one value for the whole section because a
# `.pdf` vignette is copied, not rendered: under quarto_website its siblings
# become `.html` while it stays `.pdf`.
.llms_txt_vignettes <- function(src_dir, tar_dir, tool) {
    dir <- fs::path_join(c(tar_dir, "vignettes"))
    empty <- data.frame(
        name = character(0),
        title = character(0),
        ext = character(0),
        stringsAsFactors = FALSE
    )
    if (!fs::dir_exists(dir)) {
        return(empty)
    }

    pattern <- if (identical(tool, "quarto_website")) {
        "\\.(qmd|Rmd|md|pdf)$"
    } else {
        "\\.(md|pdf)$"
    }

    # Recursion follows the same generator split, for the same reason the
    # pattern does: quarto_website gets `vignettes/` copied whole by
    # `fs::dir_copy()`, subdirectories included, and Quarto renders a nested
    # `vignettes/articles/deep-dive.qmd` -- the usual pkgdown layout -- which
    # `.sidebar_vignettes_quarto_website()` then lists, since it globs
    # recursively too. Missing it here would publish and link an article the
    # index never mentions. The other generators render vignettes
    # non-recursively, and their sidebars glob non-recursively to match, so
    # nothing of theirs lives in a subdirectory to find.
    recursive <- identical(tool, "quarto_website")

    files <- list.files(
        dir,
        pattern = pattern,
        full.names = TRUE,
        recursive = recursive
    )
    if (length(files) == 0) {
        return(empty)
    }
    # Radix sort so the listing order does not depend on the collation locale,
    # matching `.rd_topics()`.
    files <- sort(files, method = "radix")

    titles <- vapply(
        files,
        .llms_txt_title,
        character(1),
        src_dir = src_dir,
        USE.NAMES = FALSE
    )

    # quarto_website renders its sources to HTML; a .pdf is copied through
    # unchanged, so it keeps its own extension either way.
    src_ext <- fs::path_ext(files)
    ext <- if (identical(tool, "quarto_website")) {
        ifelse(src_ext == "pdf", "pdf", "html")
    } else {
        src_ext
    }

    # The name carries any subdirectory, since it becomes the link's path:
    # a nested article is served at `vignettes/articles/deep-dive.html`, so
    # `basename()` here would emit `vignettes/deep-dive.html` and 404. It also
    # keeps the dedup below honest, since two articles of the same name in
    # different directories are different pages. Titles stay on the basename;
    # a reader wants "deep-dive", not the path to it.
    out <- data.frame(
        name = as.character(fs::path_ext_remove(fs::path_rel(files, dir))),
        title = titles,
        ext = ext,
        stringsAsFactors = FALSE
    )
    out[!duplicated(out$name), , drop = FALSE]
}
