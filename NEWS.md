# News

## Unreleased

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
