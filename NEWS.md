# News

## Unreleased

* Added: `quarto_website` now supports `README.qmd`. When `README.qmd` is present
  in the package root, `altdoc` copies it to the output directory and creates
  `index.qmd` with `{{< include README.qmd >}}` (#368).

* Fixed: a `quarto_website` man page's "View source" and "Edit this page" links
  now point at the source file the topic was documented in --- usually a file
  under `R/`, and a path elsewhere in the package where `@backref` names one
  --- rather than at the
  `man/<topic>.qmd` that `render_docs()` generates and never commits, which
  404s.
  A hand-written man page records no such file --- roxygen2 writes that
  mapping, and nothing else does --- so those pages link to their `.Rd`
  instead.
  Quarto builds these links from the file it rendered, so a site only carries
  them when it sets `repo-actions:` in `altdoc/quarto_website.yml`.
  A site is rewritten only where it also records `repo-url:`, since that is
  what distinguishes a source or edit action from the "Report an issue" link
  Quarto builds out of `issue-url:` and gives the same styling; a site
  recording neither is untouched.

* Added: `check_altdoc()` now reports a `sidebar_fold` setting that cannot take
  effect --- one set without a settings file pointing at
  `$ALTDOC_SIDEBAR_FOLD`, or set for a generator other than `quarto_website`.
  The key chooses the fold control's starting state but does not create the
  control, so on its own it does nothing at all.
  It is reported here rather than at render time because deciding it needs
  `altdoc/reference.yml` and the settings file together, and because a project
  part-way through being wired up is not broken.

* Added: `$ALTDOC_SIDEBAR_FOLD`, a `quarto_website` variable that adds a navbar
  button folding the whole sidebar away and giving the content the width it
  held.
  Quarto's own `collapse-level` folds sections *within* the sidebar and has no
  control for the sidebar itself, so a site wanting one had to carry its own
  script and stylesheet.
  Point `include-in-header` at the variable under `format: html:` to opt in.
  The reader's choice is remembered across pages; `sidebar_fold: collapsed` in
  `altdoc/reference.yml` starts the sidebar folded for a reader who has not
  chosen yet.
  The snippet ships with altdoc rather than being copied into `altdoc/`, so a
  site picks up changes to it by upgrading the package.

* Added: `sidebar_fold` is now accepted in `altdoc/reference.yml`, taking
  `expanded` (the default) or `collapsed`.
  Any other value is an error, as with the other sidebar keys.

* Added: `quarto_website`'s `$ALTDOC_MAN_BLOCK` now groups the sidebar's
  `Reference` section into the sections declared in `altdoc/reference.yml`,
  the same ones that already group the reference index page.
  Quarto renders each as a collapsible entry, so a large reference folds down
  to its section headings instead of scrolling as one unbroken list.
  Sections appear in the order they are declared, and topics in the order they
  are listed; a section with no `title:` contributes its topics without a
  wrapper; and a non-internal topic no section claims goes into a trailing
  `Other` section, mirroring what the index page does with it.
  A package with no `reference:` block keeps the flat list, so no existing
  sidebar moves (#101).

* Fixed: the `quarto_website` sidebar listed `\keyword{internal}` topics.
  It was built by globbing the rendered man pages, and `.import_man()` renders
  internal topics too, so the sidebar advertised pages about helpers a caller
  is not meant to reach for -- 150 of the 282 entries on one package's site.
  The index page and `llms.txt` have always excluded them via
  `.listed_topics()`; the sidebar now agrees, for any package that declares a
  `reference:` block (#101).

* Added: `docsify` and `mkdocs` now render and link vignettes kept in a
  subdirectory, such as the `vignettes/articles/` layout `pkgdown` users
  arrive with.
  Previously only `quarto_website` did, and under the other generators a
  nested vignette was copied to the site as its unrendered `.qmd` source,
  absent from both the sidebar and `llms.txt`.
  `docute` is unchanged: it relocates every `vignettes/` subdirectory to the
  site root, so distinguishing an asset directory from a vignette directory
  there is a separate question, tracked in #2.

* Fixed: `altdoc/pkgdown.yml` no longer gets a `urls:` block rooted at a code
  repository.
  A package whose only `DESCRIPTION` `URL:` was a non-GitHub forge repo (GitLab,
  Codeberg) had `/man` and `/vignettes` appended to that repo URL, so `downlit`
  autolinked vignette function calls to paths like
  `https://gitlab.com/foo/bar/man` that do not exist.
  The block is now omitted when no `URL:` is a documentation site, which makes
  `downlit` skip autolinking instead, and `render_docs()` says so rather than
  leaving the omission silent.
  GitHub-hosted packages were unaffected, by accident rather than design: their
  repo URL was already removed before the fallback ran (#85).

* Fixed: `.add_pkgdown()` read `DESCRIPTION` from the working directory instead
  of from its `path` argument, so rendering a package from outside its own
  directory wrote *another* package's site URL into its `altdoc/pkgdown.yml`
  (#85).

* Fixed: the reference index and `llms.txt` now link to a topic's page by its
  `.Rd` file name rather than its `\name{}`.
  roxygen2 mangles the file name of a topic whose name is not filesystem-safe,
  so `%+%` is documented in `grapes-plus-grapes.Rd` and published as
  `man/grapes-plus-grapes`, while both indexes linked to `man/%+%` and 404'd.
  Entries are still labelled `%+%`, the name a reader is looking for.
  The generated sidebar was affected by the same divergence when
  `sidebar_labels: name-and-title` is set: it looked such a topic up by the
  wrong key, found no `.Rd` row, and fell back to showing the mangled file
  name with no summary (#80).

* Fixed: the message `render_docs()` prints after writing the reference index
  counted every documented topic, including the `\keyword{internal}` ones the
  page leaves out, so a package with internal topics was told it wrote more
  entries than the page lists (#80).

* Added: `check_altdoc()` reports configuration problems without rendering.
  Five things `render_docs()` otherwise handles silently: an `$ALTDOC_*`
  variable altdoc does not recognize, which reaches the published page as
  literal text; a recognized one whose source file is missing, where the whole
  line using it is dropped; a man page or vignette the navigation never links,
  which is published but unreachable by clicking; a missing or
  repository-only `URL:`, which leaves `downlit` no base to autolink vignette
  code against; and an invalid `altdoc/reference.yml`.
  Every check reports rather than aborts and all of them run, so one call
  lists everything there is to fix, and the findings are returned invisibly as
  a character vector so a CI script can act on them.
  A settings file using `$ALTDOC_MAN_BLOCK` or `$ALTDOC_VIGNETTE_BLOCK` cannot
  omit a page, so the navigation checks only apply to a hand-authored
  navigation.
  The function is opt-in: `render_docs()` does not call it (#39).

* Internal: the render tests now assert which files each generator publishes,
  rather than only that `render_docs()` returned without an error.
  A render that succeeds while writing a page somewhere the site never reaches
  used to pass every test, which is how three bugs in the `llms.txt` work
  reached review.
  Each generator's expected file set is derived from the fixture package's own
  `man/` and `vignettes/` directories, so adding a topic or an article to a
  fixture extends the assertion with it.
  Two generators also render a second time into an already-populated `docs/`,
  a case nothing covered before, and check that opting out of `llms.txt`
  removes the previously published file rather than only stopping a new one
  from being written (#79).

* Added: `render_docs()` now writes an [`llms.txt`](https://llmstxt.org/) at
  the site root, indexing every public topic and rendered article so a
  coding agent can read the package's documentation without scraping HTML.
  Topics marked `\keyword{internal}` are left out, as they are in the
  reference index; a package with nothing else to list gets no file.
  Each reference entry carries the topic's `.Rd` `\title{}`, the same summary
  the reference index shows, so the two cannot disagree and neither can drift
  from the help page. Links are absolute when the package declares a site
  (`altdoc/pkgdown.yml`'s `urls: reference:` first, then `DESCRIPTION`'s
  `URL:`), and site-relative otherwise. They point at `.md` pages under
  `docsify`, `docute`, and `mkdocs`, all of which leave the Markdown in the
  published tree, and at `.html` under `quarto_website`, the one generator
  that compiles it away. Opt out with `llms_txt: false` in
  `altdoc/reference.yml` (#40).

* Fixed: the workflow `setup_github_actions()` writes no longer bootstraps its
  R installation with `eddelbuettel/r-ci`. That script installs `bspm` from a
  single APT host, `r2u.stat.illinois.edu`, and aborts the job when that host
  is unreachable, so a generated workflow could go red with nothing in the
  package at fault. It now uses `r-lib/actions/setup-r` and
  `setup-r-dependencies`, which resolve packages through the RStudio Package
  Manager CDN. A workflow a project has already generated is a file in that
  project, untouched by upgrading altdoc; rerun `setup_github_actions()` to
  regenerate it (#60).

* Added: `render_docs()` now discovers a package logo and copies it into the
  site, so a package following the usual convention gets one without
  hand-placing files. The search order matches `pkgdown`'s: `logo.svg`,
  `man/figures/logo.svg`, `logo.png`, then `man/figures/logo.png`. The file
  is copied under its own name and can be referenced from a settings file
  with the new `$ALTDOC_LOGO` variable; as with the other `$ALTDOC_`
  variables, a line using it is dropped when the package has no logo, so a
  settings file can carry a logo entry unconditionally. Only the
  `quarto_website` template wires it up so far, via `navbar: logo:`; the
  other three generators copy the logo but do not yet reference it. Settings
  files created before this release are never modified automatically, so add
  a `$ALTDOC_LOGO` entry to pick it up. Favicons are deliberately not
  included (#41).
  
* Fixed: `render_docs(freeze = TRUE)` now actually skips an unchanged
  `README.md`. The freeze check hashed whichever README variant had priority
  (`README.qmd`, then `README.Rmd`, then `README.md`), but the hash recorded
  after the copy was always `README.md`'s, so for any package shipping a
  `README.qmd` or `README.Rmd` the check looked up a key that was never
  written and the README was re-copied on every render. Both sides now use
  `README.md`, which is the file altdoc actually copies to `docs/README.md`:
  keying the skip on a variant altdoc never reads would let an edit made
  directly to `README.md` go undetected and leave the rendered copy stale
  (#69).

* Fixed: `render_docs()`'s documented list of source files it looks for now
  matches what it actually looks for. Three gaps: the `.Rd` and `inst/`
  candidates were listed for `NEWS` but for none of the other files, even
  though every one of them is searched for under all four extensions in both
  locations; `ChangeLog` and `LICENCE` were not mentioned at all, though both
  are searched for; and `README` was listed as a three-way choice between
  `README.md`, `README.qmd`, and `README.Rmd`, which reads as though writing
  a `README.qmd` is enough. It is not: `docs/README.md` is always a copy of
  `README.md`, and a `.qmd` or `.Rmd` has to be rendered to it separately.
  The `.Rd` omission was the other one likely to mislead, since a `.Rd`
  source is converted rather than copied, so a package shipping `inst/NEWS.Rd`
  is handled differently from what the docs implied was possible (#58).

* Fixed: `\dontrun{}` and `\donttest{}` are now honored per block. A single
  such block used to switch evaluation off for every example on the page, so a
  help page whose examples were mostly runnable but ended with one error-case
  block rendered with no output at all. Each block is now emitted as its own
  chunk, and only the non-runnable ones are left unevaluated. The decision also
  comes from the parsed `.Rd` tree rather than a search of the rendered page
  for the strings `dontrun`/`donttest`, so an example that merely mentions
  either word in a comment or a string no longer disables the page. The
  `@examplesIf` condition is read from the same tree instead of by matching the
  sentinel roxygen2 generates against the whole deparsed help page (#38).

* Added: man pages can now be labeled in the sidebar with their `.Rd`
  `\title{}` as well as their topic name, so a reader scanning the sidebar
  sees what each topic does rather than only what it is called. Set
  `sidebar_labels: name-and-title` in `altdoc/reference.yml` to opt in; an
  entry then reads `as_pop_data(): Load a cross-sectional antibody survey
  data set`, with the `()` suffix only on topics that document something
  callable, matching the reference index. Titles are truncated to 40
  characters so a long one cannot overflow a narrow sidebar; only the title
  is shortened, never the name, and `sidebar_label_width` changes the limit.
  This is opt-in, so an existing site's sidebar is unchanged until its author
  asks for it (#37).

* Fixed: `render_docs()` now imports `CONTRIBUTING.md` to `docs/`, so the
  `$ALTDOC_CONTRIBUTING` variable resolves. `.substitute_altdoc_variables()`
  already substituted that variable, but the file it points at was never
  copied, so the variable never resolved and any settings-file line using it
  was silently dropped. The settings files shipped by `setup_docs()` now
  carry a "Contributing" entry alongside "Code of Conduct" for all four
  generators; settings files created before this release are never modified
  automatically, so add a `$ALTDOC_CONTRIBUTING` entry to pick it up (#4).

* Fixed: a `docute` vignette title containing a backslash no longer produces a
  malformed sidebar entry. The title was escaped for the single quotes that
  enclose it, but not for the backslash that does the escaping (#37).

* Internal: removed unused `filename` parameter from `.substitute_altdoc_variables()` (#44).

* Added: `render_docs()` now generates a reference index at `reference.md`,
  listing every documented topic with a one-line summary taken from its `.Rd`
  `\title{}`. The summary is therefore written once, in the roxygen2 `@title`,
  instead of being retyped in a hand-authored index that can drift out of sync
  with the help pages. Link to the page from the settings file with the new
  `$ALTDOC_REFERENCE` variable. With no configuration the index lists every
  non-internal topic under a single heading; to group the topics, create
  `altdoc/reference.yml` with a `reference:` key using the same schema as
  `pkgdown`'s `_pkgdown.yml`, including the `starts_with()`, `matches()`, and
  `has_concept()` selectors. The page is headed "Package index", the name
  `pkgdown` gives the same page, so a reader arriving from a "Reference"
  navigation entry sees a heading that says what the page is rather than
  repeating how they got there; a top-level `title` key in
  `altdoc/reference.yml` overrides it. Settings files created before this
  release do not reference the new page, so add a `$ALTDOC_REFERENCE` entry to
  pick it up (#33, #46).

* Added: `setup_github_actions()` now supports multiversion docs deployment via
  `multiversion = TRUE`. In this mode, docs are published to
  `gh-pages/<branch-or-tag>/` and a second job runs
  `insightsengineering/r-pkgdown-multiversion` to maintain the landing page and
  version links.

* Fixed: for `quarto_website` sites with `code-link: true`, `downlit`'s
  rdrr.io fallback links to the documented package's own functions are now
  also rewritten to page-relative links to the locally rendered `man/`
  pages. `downlit` emits these when it cannot discover the package's site
  at render time (most commonly a private GitHub Pages deploy, whose
  `pkgdown.yml` is not fetchable without auth), and rdrr.io only indexes
  CRAN packages, so for a non-CRAN package every such link was dead (#25).

* Fixed: for `quarto_website` sites with `code-link: true`, links to the
  documented package's own functions in vignettes/articles and man pages
  are now rewritten to be relative to the linking page. Previously
  `downlit` emitted an absolute link to the production site recorded in
  `altdoc/pkgdown.yml`, which broke on any other deploy path -- most
  commonly a pull-request preview served under its own subpath (#10).

## 0.7.3

* Fix NOTE in CRAN results.

## 0.7.2

* `quarto_website` now stages files pulled in by `{{< include >}}` directives
  that resolve outside the copied source trees (e.g. a shared `macros/macros.qmd`
  submodule at the package root), so those includes resolve at render time.

* Disabled more tests on CRAN following a removal from CRAN due to a `NOTE` (#359).

## 0.7.1

### Bug fixes

* Vignettes in subfolders (e.g., `vignettes/articles/`) are now discovered 
  recursively when using `quarto_website`. (#355)

* Custom sidebars with singleton entries in `quarto_website.yml` are now 
  properly processed. (#355)

* In 0.5.0, we announced that `README.qmd` wouldn't be automatically rendered,
  but this still happened when `output = "quarto_website"`. This is now fixed,
  meaning that `altdoc` uses `README.md` over `README.qmd` (#354).

* Figures stored in `man/figures` and used in the README are now properly
  displayed (#354).

* Fix for change of default value of `getOption("help.htmltoc")` in R-devel
  4.6.0 (#356).

## 0.7.0

### New features

* When using `mkdocs` as documentation generator, the Python virtual environment
  to be used can now be set with the environment variable `ALTDOC_VENV`. It
  doesn't have to be `.venv_altdoc` located at the project root anymore (#339).

* `render_docs()` now updates the file `altdoc/pkgdown.yml`. This file was also
  adapted so that it can be used by R-universe to display a link to the package
  website (#344).

### Bug fixes

* When using `mkdocs` as documentation generator, changes in settings such as
  overrides templates or CSS files are now correctly applied to `docs/index.html`.
  Previously, it was required to manually delete the file and run `render_docs()`
  again (#337).

### Misc

* Fix errors in CRAN checks occurring when Quarto isn't available on the system.

## 0.6.0

### Changes

* The CSS for arguments table in "Reference" page has changed a bit. Argument
  names are now wrapped so that they have limited width, improving the
  readability in case of multiple arguments on the same line (#308).

* Files stored in `man/figures` (such as `lifecycle` badges) are now properly
  included by `render_docs()` (#321).

### Bug fixes

* Fix a `quarto_website` rendering failure when the package being rendered has
  its URL or BugReports set to a site other than GitHub (#319, @gardiners).

* Fix footer in `docsify` when a package doesn't have a website or GitHub URL
  (#324).

* `render_docs()` now shows an explicit error message if Quarto is not installed
  on the system (#329).

* Fix an error in `render_docs()` when the title in the Rd file is split across
  several lines (#333).

## 0.5.0

### Breaking changes

* Do not render README.qmd to markdown automatically. Users should render them manually to make sure that the README on CRAN and Github is in sync with the Altdoc home page.

### Other changes

* `README.qmd` is no longer required to create a `quarto_website`, only
  `README.md` (#295).

### Bug fixes

* Fix some failures in CRAN checks (#303).

## 0.4.0

### Breaking changes

* Simplified rendering for Quarto websites. Previously, the website was rendered
  into `_quarto/_site` and manually copied over to `docs/`. The new version removes
  this logic and instead uses the `output-dir` project option. To transition, change
  `quarto_website.yml` to:
  ``` yml
  project:
    output-dir: ../docs/
  ```

### New features

* `render_docs(freeze = TRUE)` now works correctly when output is `"quarto_website"`.
  Freezing a document needs to be set either at a project or per-file level. To do
  so, add to either `quarto_website.yml` or the frontmatter of a file:

  ``` yml
  execute:
    freeze: auto
  ```
* For Quarto websites, `render_docs()` can use the `downlit` package to automatically
  link function calls to their documentation on the web. Turn off by modifying
  the `code-link` line in `altdoc/quarto_website.yml`
* Citation is now formatted with HTML instead of verbatim (#282, Achim Zeileis).
* The `\doi{}` tags in Rd files are now linked once rendered (#282, Achim Zeileis).
* Warn if README.qmd does not exist when calling `setup_docs("quarto_website")`. Issue #280.



### Other changes

* Update `github-pages-deploy-action` to v4
* Support `@examplesIf` tag in `roxygen2`

## 0.3.0

All functions have changed so any change listed below technically is a breaking
change.


### Breaking changes

* Functions renamed:
  - `use_docute()`, `use_docsify()` and `use_mkdocs()` are combined into `setup_docs()`
  - `update_docs()` -> `render_docs()`
  - `preview()` -> `preview_docs()`

* `setup_docs()` (previously `use_*()`) no longer updates and previews the website
  by default.
* `custom_reference` argument is removed. See the `Post-processing` vignette for
  a description of the new proposed workflow.
* `theme` argument is removed. Users can change themes by editing settings files
  in `altdoc/`
* `mkdocs` documentation is no longer stored in `docs/docs/`

### New features

* Support Quarto websites as a documentation format.

* Support Quarto vignettes (.qmd) in the `vignettes/` folder.

* `render_docs(parallel = TRUE)` uses `future` to parallelize the rendering of
  vignettes and man pages.

* `render_docs(freeze = TRUE)` no longer renders vignettes or man pages when they
  have not changed and are already stored in `docs/`.

* Link to source code at the top of function reference.

* Settings files are now permanently stored in the `altdoc/` directory. These
  files can be edited manually to customize the website.

* Major internal changes to the .Rd -> .md conversion system. We now use Quarto
  to convert man pages and execute examples, and the man pages are stored in
  separate markdown files instead of combined in a single large file.

* `mkdocs` now behaves like the other documentation generators and stores its
  files in `docs/`. This means that `mkdocs` websites can be deployed to Github
  Pages.

* Improved vignettes

* Do not reformat markdown header levels automatically, but raise a warning when
  there is more than one level 1 header.

* Fewer dependencies.
* Fix parsing for issue/PR references like [org/repo#111].

* Changelog and News sections can be present simultaneously.

* Support for `NEWS.Rd`, either in the root folder or in `inst/`

* Automatically create a Github Actions workflow with `setup_github_actions()`.

* Skip .Rd files when they document internal functions.


## 0.2.2

* If necessary, two spaces are automatically added in nested lists in the `NEWS`
  (or `Changelog`) file.

* This is the last release before a large rework of this package.

## 0.2.1

* Fix test failures on CRAN due to the new version of `usethis`
  (see https://github.com/cynkra/fledge/issues/683).

## 0.2.0

#### Breaking changes

* Vignettes are no longer automatically added to the file that defines the structure
  of the website. Developers must now manually update this structure and the order
  of their articles. Note that the name of the file defining the structure of the
  website differs based on the selected site builder. This file lives at the root
  of `/docs` (`use_docsify()` = `_sidebar.md`; `use_docute()` = `index.html`;
  `use_mkdocs()` = `mkdocs.yml`).


#### Major changes

* `update_docs()` now updates the package version as well as altdoc version in
  the footer.

* The NEWS or Changelog file included in the docs now automatically links issues,
  pull requests and users (only works for projects on Github).

* Vignettes are now always rendered by `use_*()` or `update_docs()`. Therefore,
  the argument `convert_vignettes` is removed. Previously, they were only rendered
  if their content changed. This was problematic because the code in a vignette
  can have different output while the vignette in itself doesn't change (#37, #38).

* New argument `custom_reference` in `use_*()` and `update_docs()`. If it is a
  path to a custom R file then it uses this file to build the "Reference" section
  in the docs (#35).

#### Minor changes

* Fix some CRAN failures.


## 0.1.0

* First version.
