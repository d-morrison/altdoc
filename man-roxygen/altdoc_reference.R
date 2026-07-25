#' @section Reference index:
#'
#' `render_docs()` writes a reference index to `reference.md`: a page listing every documented topic with a one-line summary. Link to it from the settings file with the `$ALTDOC_REFERENCE` variable.
#'
#' Each summary is read from the `\title{}` of the topic's `.Rd` file, so it is written once in the roxygen2 `@title` and never retyped. The page is rebuilt on every `render_docs()` call, so a summary can never drift out of sync with the help page it describes.
#'
#' By default the index holds a single "All functions" section listing every topic that is not marked `@keywords internal`. To group the topics instead, create `altdoc/reference.yml`:
#'
#' ```yaml
#' reference:
#'   - title: Data
#'     desc: Load and reshape survey data.
#'     contents:
#'       - as_pop_data
#'       - starts_with("read_")
#'   - title: Modeling
#'     subtitle: Estimation
#'     contents:
#'       - has_concept("estimation")
#' ```
#'
#' Each section may set `title`, `subtitle`, `desc`, and `contents`. This is the same schema `pkgdown` uses for the `reference:` key of `_pkgdown.yml`, so an existing block can be moved over unchanged.
#'
#' An entry of `contents` is either a topic name (or alias), or one of these selectors:
#'
#' * `starts_with("x")`, `ends_with("x")`, `contains("x")`: match the start, end, or any part of a topic name or alias.
#' * `matches("x")`: match a regular expression.
#' * `has_keyword("x")`, `has_concept("x")`, `lacks_concepts("x")`: match the `\keyword{}` and `\concept{}` tags. roxygen2 writes `@family` to `\concept{}`.
#' * `everything()`: every topic.
#'
#' Prefix an entry with `-` to remove its matches instead of adding them; when the first entry of a section is a removal, the section starts from every non-internal topic. Selectors skip topics marked `@keywords internal` unless called with `internal = TRUE`.
#'
#' Topics missing from `altdoc/reference.yml` are reported at render time and collected in a trailing "Other" section, so they are never silently dropped from the index.
#'
#' The page's heading is "Package index", the name `pkgdown` gives the same page, so a reader arriving from a "Reference" navigation entry sees a heading that says what the page is rather than repeating how they got there. Set a top-level `title` key to change it:
#'
#' ```yaml
#' title: Function reference
#' reference:
#'   - title: Data
#'     contents:
#'       - as_pop_data
#' ```
#'
#' A file holding a bare list of sections with no `reference:` key is still accepted, for a block moved over from `pkgdown` unchanged, but has nowhere to put `title` and so always uses the default.
#'
#' @section Sidebar labels:
#'
#' Every generator labels a man page in the sidebar with its topic name, which says what a topic is called but not what it does. Set `sidebar_labels` to `name-and-title` to append the topic's `\title{}`, so the summary written once in the roxygen2 `@title` reaches the sidebar as well as the reference index:
#'
#' ```yaml
#' sidebar_labels: name-and-title
#' ```
#'
#' A topic then reads `as_pop_data(): Load a cross-sectional antibody survey data set` rather than `as_pop_data`. The name keeps the `()` suffix only when the topic documents something callable, matching how the reference index writes it.
#'
#' This is opt-in: the default, `name`, is what every generator did before, so an existing site's sidebar does not change until its author asks for it.
#'
#' Titles are truncated to 40 characters so a long one cannot overflow a narrow sidebar. Only the title is shortened, never the topic name, so entries stay scannable by the name a reader is looking for. Set `sidebar_label_width` to change the limit:
#'
#' ```yaml
#' sidebar_labels: name-and-title
#' sidebar_label_width: 60
#' ```
#'
#' `title`, `reference`, `sidebar_labels`, and `sidebar_label_width` are the only top-level keys `altdoc/reference.yml` accepts; anything else is an error. So is an unrecognized `sidebar_labels` value, and a `sidebar_label_width` that is not a whole number of at least 4 --- below 4 leaves no room for the ellipsis, and a fractional width would be silently truncated, so `4.5` would quietly behave as `4`.
#'
#' Setting `sidebar_label_width` without `sidebar_labels: name-and-title` warns, since the width has nothing to apply to on its own.
#'
