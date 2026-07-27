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
        # Internal topics are excluded for the same reason the reference index
        # omits them: they document things a caller is not meant to reach for,
        # so listing them invites an agent to suggest one.
        listed <- topics[!topics$internal, , drop = FALSE]
        if (nrow(listed) > 0) {
            out <- c(out, "## Reference", "")
            out <- c(
                out,
                .llms_txt_rows(
                    labels = .llms_txt_topic_labels(listed),
                    urls = .llms_txt_url(base, "man", listed$name, ext),
                    descriptions = listed$title
                ),
                ""
            )
        }
    }

    if (!is.null(vignettes) && nrow(vignettes) > 0) {
        out <- c(out, "## Articles", "")
        out <- c(
            out,
            .llms_txt_rows(
                labels = vignettes$title,
                urls = .llms_txt_url(base, "vignettes", vignettes$name, ext),
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
.llms_txt_rows <- function(labels, urls, descriptions = NULL) {
    rows <- paste0("- [", labels, "](", urls, ")")
    if (is.null(descriptions)) {
        return(rows)
    }
    has_desc <- !is.na(descriptions) &
        nzchar(descriptions) &
        descriptions != labels
    ifelse(has_desc, paste0(rows, ": ", descriptions), rows)
}
