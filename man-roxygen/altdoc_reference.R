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
#' `title` and `reference` are the only top-level keys `altdoc/reference.yml` accepts; anything else is an error. A file holding a bare list of sections with no `reference:` key is still accepted, for a block moved over from `pkgdown` unchanged, but has nowhere to put `title` and so always uses the default.
#'
