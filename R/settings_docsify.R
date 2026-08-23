.finalize_docsify <- function(settings, path, ...) {
    tool <- .doc_type(path)

    # drop missing links
    settings <- settings[!grepl("\\]\\(\\)", settings)]
    settings <- stats::na.omit(settings)

    fn_man <- fs::path_join(c(.doc_path(path), "reference.md"))
    dn_man <- fs::path_join(c(.doc_path(path), "man"))

    fn <- fs::path_join(c(.doc_path(path), "_sidebar.md"))
    writeLines(settings, fn)

    # relative links
    dn <- fs::path_join(c(path, "docs", "vignettes"))
    if (fs::dir_exists(dn)) {
        md_files <- fs::dir_ls(dn, regexp = "\\.md$", recurse = TRUE)
        for (md in md_files) {
            rel_path_no_ext <- fs::path_ext_remove(fs::path_rel(md, dn))
            src <- sprintf(
                'src="%s.markdown_strict_files',
                gsub("\\.md$|\\.pdf$", "", basename(md))
            )
            tar <- sprintf(
                'src="vignettes/%s.markdown_strict_files',
                rel_path_no_ext
            )
            content <- gsub(src, tar, .readlines(md), fixed = TRUE)
            writeLines(content, md)
        }
    }

    # body also includes altdoc variables
    fn <- fs::path_join(c(path, "altdoc", "docsify.html"))
    body <- .readlines(fn)
    body <- .substitute_altdoc_variables(body, path = path, tool = tool)
    fn <- fs::path_join(c(.doc_path(path), "index.html"))
    writeLines(body, fn)
}

.sidebar_vignettes_docsify <- function(sidebar, path) {
    dn <- fs::path_join(c(.doc_path(path), "vignettes"))
    # Recursive, to match `.import_vignettes()`, which renders a nested
    # `vignettes/articles/` for this generator. Listing non-recursively would
    # publish those pages without linking them from anywhere.
    fn_vignettes <- list.files(
        dn,
        pattern = "\\.md$|\\.pdf$",
        full.names = TRUE,
        recursive = TRUE
    )
    # before gsub on files
    titles <- sapply(fn_vignettes, .get_vignettes_titles)
    # `path_rel()` rather than `basename()`, so a nested page keeps the
    # subdirectory it was published into and the link resolves.
    fn_vignettes <- sapply(fn_vignettes, function(x) {
        fs::path_join(c("vignettes", fs::path_rel(x, dn)))
    })
    if (length(fn_vignettes) > 0) {
        idx <- grep("\\$ALTDOC_VIGNETTE_BLOCK", sidebar)
        if (length(idx) == 1) {
            sidebar <- gsub("\\$ALTDOC_VIGNETTE_BLOCK", "", sidebar)
            indent <- gsub("^(\\w*).*", "\\1", sidebar[idx])
            tmp <- ifelse(
                tools::file_ext(fn_vignettes) == "pdf",
                sprintf(
                    "%s  - [%s](%s ':ignore')",
                    indent,
                    titles,
                    fn_vignettes
                ),
                sprintf("%s  - [%s](%s)", indent, titles, fn_vignettes)
            )
            sidebar <- c(
                sidebar[1:idx],
                tmp,
                sidebar[(idx + 1):length(sidebar)]
            )
        }
    } else {
        sidebar <- sidebar[!grepl("\\$ALTDOC_VIGNETTE_BLOCK", sidebar)]
    }
    return(sidebar)
}

.sidebar_man_docsify <- function(sidebar, path) {
    dn <- fs::path_join(c(.doc_path(path), "man"))
    if (fs::dir_exists(dn)) {
        fn <- list.files(dn, pattern = "\\.md$", full.names = TRUE)
        fn <- sapply(fn, function(x) fs::path_join(c("man", basename(x))))
        fn <- sapply(fn, fs::path_ext_remove)

        if (length(fn) > 0) {
            titles <- .escape_md_link_text(.sidebar_labels(
                basename(fn),
                src_dir = path
            ))
            idx <- grep("\\$ALTDOC_MAN_BLOCK", sidebar)
            if (length(idx) == 1) {
                sidebar <- gsub("\\$ALTDOC_MAN_BLOCK", "", sidebar)
                indent <- gsub("^(\\w*).*", "\\1", sidebar[idx])
                tmp <- sprintf("%s  - [%s](%s)", indent, titles, fn)
                sidebar <- c(
                    sidebar[1:idx],
                    tmp,
                    sidebar[(idx + 1):length(sidebar)]
                )
            } else {
                sidebar <- sidebar[!grepl("\\$ALTDOC_MAN_BLOCK", sidebar)]
            }
        } else {
            sidebar <- sidebar[!grepl("\\$ALTDOC_MAN_BLOCK", sidebar)]
        }
    } else {
        sidebar <- sidebar[!grepl("\\$ALTDOC_MAN_BLOCK", sidebar)]
    }
    return(sidebar)
}
