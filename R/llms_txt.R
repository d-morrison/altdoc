# Build the contents of `llms.txt`: an index of the site's pages in Markdown,
# for a coding agent or LLM to read instead of scraping rendered HTML.
#
# Format per https://llmstxt.org/: an H1 with the package name, an optional
# blockquote summary, then H2 sections of `- [name](url): description` links.
#
# The description beside each topic is its `.Rd` `\title{}`, the same string
# `.reference_index()` shows, so the two pages cannot disagree about what a
# topic does -- and neither can drift from the `.Rd` file, since both read it
# on every render.
#
# `base` is the site root for absolute links, or NULL to emit site-relative
# ones. `ext` is the extension of the pages a reader would actually open,
# which differs by generator (see `.import_llms_txt()`).
#
# A topic's link is built from its .Rd file's basename rather than its
# `\name{}`, which matters more here than on the human-facing index: the whole
# audience is machines fetching the links directly, with no one to notice a
# 404 and navigate around it. See `.rd_topics()` for when the two diverge.
.llms_txt <- function(
    pkg_name,
    pkg_title = NULL,
    topics = NULL,
    vignettes = NULL,
    base = NULL,
    ext = "md"
) {
    out <- c(paste("#", pkg_name), "")

    if (!is.null(pkg_title) && nzchar(pkg_title)) {
        out <- c(out, paste(">", pkg_title), "")
    }

    if (!is.null(topics) && nrow(topics) > 0) {
        listed <- .listed_topics(topics)
        if (nrow(listed) > 0) {
            out <- c(out, "## Reference", "")
            out <- c(
                out,
                .llms_txt_rows(
                    labels = .llms_txt_topic_labels(listed),
                    urls = .llms_txt_url(base, "man", listed$file, ext),
                    descriptions = listed$title
                ),
                ""
            )
        }
    }

    if (!is.null(vignettes) && nrow(vignettes) > 0) {
        # Articles carry their own extension: a `.pdf` vignette is copied
        # rather than rendered, so it does not share its siblings'. Fall back
        # to the section-wide `ext` for a caller that supplies no column.
        vig_ext <- if (is.null(vignettes$ext)) ext else vignettes$ext
        out <- c(out, "## Articles", "")
        out <- c(
            out,
            .llms_txt_rows(
                labels = vignettes$title,
                urls = .llms_txt_url(
                    base,
                    "vignettes",
                    vignettes$name,
                    vig_ext
                ),
                descriptions = NULL
            ),
            ""
        )
    }

    out
}

# `fn()` for a topic that documents something callable, matching how the
# reference index and the sidebar label the same topic.
.llms_txt_topic_labels <- function(topics) {
    ifelse(topics$is_fun, paste0(topics$name, "()"), topics$name)
}

.llms_txt_url <- function(base, subdir, names, ext) {
    rel <- paste0(subdir, "/", names, ".", ext)
    if (is.null(base)) {
        return(rel)
    }
    paste0(base, "/", rel)
}

# One `- [label](url): description` line per entry. A description equal to the
# label adds nothing, so it is dropped rather than repeated.
#
# Labels are escaped for the same reason the docsify sidebar escapes its own:
# a `[` or `]` in the text closes the label early, so the rest renders as
# literal text beside a broken link. A vignette H1 like `Do not use R6 [beta]`
# is enough to trigger it, and topic names can carry brackets too (`[.foo`).
# Descriptions sit outside the link, so they need no escaping.
.llms_txt_rows <- function(labels, urls, descriptions = NULL) {
    rows <- paste0("- [", .escape_md_link_text(labels), "](", urls, ")")
    if (is.null(descriptions)) {
        return(rows)
    }
    has_desc <- !is.na(descriptions) &
        nzchar(descriptions) &
        descriptions != labels
    ifelse(has_desc, paste0(rows, ": ", descriptions), rows)
}
