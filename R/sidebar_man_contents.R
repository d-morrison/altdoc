# Build the `contents:` of the sidebar's Reference section.
#
# Without a `reference:` block in `altdoc/reference.yml` this is the flat list
# of every published man page, which is what the sidebar has always been. With
# one, the same sections that group the reference index page group the sidebar
# too, so the structure is declared once and both surfaces read it.
#
# Grouping is not only cosmetic: Quarto renders a `section:` as a collapsible
# entry, so it is also what lets a reader fold a large reference down to its
# headings instead of scrolling one unbroken list.
#
# `fn_man` is the published page path of every rendered man page, relative to
# the site root (`man/<file>.qmd`), in the order the caller found them.
# `labels` is the sidebar label for each, already resolved by
# `.sidebar_labels()` so the `sidebar_labels: name-and-title` setting applies
# inside a group exactly as it did to the flat list.
.sidebar_man_contents <- function(fn_man, labels, src_dir = ".") {
    flat <- .sidebar_man_entries(fn_man, labels, seq_along(fn_man))

    settings <- .reference_settings(src_dir)
    if (is.null(settings$sections) || length(settings$sections) == 0) {
        return(flat)
    }

    topics <- .rd_topics(src_dir)
    if (nrow(topics) == 0) {
        return(flat)
    }
    sections <- .reference_sections(settings, topics)
    if (length(sections) == 0) {
        return(flat)
    }

    # A section names topics; the sidebar lists published pages. The join key
    # is the .Rd file's basename rather than the topic's `\name{}`, the same
    # divergence `.sidebar_labels()` documents: roxygen2 mangles the file name
    # of a topic whose name is not filesystem-safe, so `%+%` is published as
    # `man/grapes-plus-grapes`. Matching on `\name{}` would leave exactly those
    # topics unfound.
    published <- sub("\\.qmd$", "", basename(fn_man))

    env <- .topics_env(topics)
    listed <- integer(0)
    out <- list()

    for (section in sections) {
        selected <- .select_topics(section$contents, topics, env = env)
        listed <- union(listed, selected)

        entries <- .sidebar_man_entries(
            fn_man,
            labels,
            match(topics$file[selected], published)
        )
        if (length(entries) == 0) {
            next
        }

        # A section with no `title:` exists to inject topics without a heading
        # -- it groups nothing, so it gets no wrapper and its entries sit at
        # the top level of the Reference section.
        if (is.null(section$title)) {
            out <- c(out, entries)
        } else {
            out <- c(
                out,
                list(list(section = section$title, contents = entries))
            )
        }
    }

    # Same rule as `.reference_index()`: a non-internal topic no section
    # claimed still has a published page, so dropping it from the sidebar would
    # hide a reachable page. Internal topics are left out, which is where the
    # sidebar starts agreeing with the index page -- the flat list published
    # every one of them.
    missing <- setdiff(which(!topics$internal), listed)
    entries <- .sidebar_man_entries(
        fn_man,
        labels,
        match(topics$file[missing], published)
    )
    if (length(entries) > 0) {
        out <- c(out, list(list(section = "Other", contents = entries)))
    }

    # Every section could have selected only topics that failed to render, in
    # which case falling back to the flat list beats publishing an empty
    # Reference section.
    if (length(out) == 0) {
        return(flat)
    }

    out
}

# One sidebar entry per index in `idx`, skipping the indices that name no
# published page.
#
# `match()` returns NA for a topic with no rendered page -- one whose man page
# failed to render, or, under a generator that skips them, an internal topic a
# section named anyway. Those are dropped rather than emitted as an entry
# pointing at a file that is not on the site.
.sidebar_man_entries <- function(fn_man, labels, idx) {
    idx <- idx[!is.na(idx)]
    if (length(idx) == 0) {
        return(list())
    }
    entries <- Map(
        function(label, file) list(text = label, file = file),
        labels[idx],
        fn_man[idx]
    )
    names(entries) <- NULL
    entries
}
