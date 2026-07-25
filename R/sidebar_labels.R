# Build the label each man page gets in the generated sidebar.
#
# Every generator labels a man page with its topic name, which tells a reader
# scanning the sidebar what a topic is called but not what it does. Setting
# `sidebar_labels: name-and-title` in `altdoc/reference.yml` appends the
# topic's `.Rd` `\title{}`, so the summary written once in the roxygen2
# `@title` reaches the sidebar too.
#
# The name is rendered the way `.reference_rows()` renders it on the reference
# index --- `name()` for a callable topic, bare `name` otherwise --- so the two
# surfaces cannot disagree about how a topic is written.
#
# `topics` is a character vector of topic names, in the order they should
# appear. The return value is a character vector of the same length, so a
# caller can drop it into whatever structure its generator builds.
.sidebar_labels <- function(topics, src_dir = ".", width = 40L) {
    if (length(topics) == 0) {
        return(topics)
    }

    settings <- .reference_settings(src_dir)
    if (!identical(settings[["sidebar_labels"]], "name-and-title")) {
        return(topics)
    }

    if (!is.null(settings[["sidebar_label_width"]])) {
        width <- settings[["sidebar_label_width"]]
    }

    rd <- .rd_topics(src_dir)
    idx <- match(topics, rd$name)

    # A sidebar entry with no matching .Rd row keeps its bare name: the file is
    # on the site, so dropping or blanking its label would hide a reachable
    # page.
    is_fun <- !is.na(idx) & rd$is_fun[idx]
    name <- ifelse(is_fun, paste0(topics, "()"), topics)

    title <- rd$title[idx]
    has_title <- !is.na(title) & nzchar(title)
    ifelse(
        has_title,
        paste0(name, ": ", .truncate_label(title, width = width)),
        name
    )
}
