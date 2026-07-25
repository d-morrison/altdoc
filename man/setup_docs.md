

# Initialize documentation website settings

[**Source code**](https://github.com/etiennebacher/altdoc/tree/main/R/setup_docs.R#L38)

## Description

Creates a subdirectory called
<code style="white-space: pre;">altdoc/</code> in the package root
directory to store the settings files used to by one of the
documentation generator utilities (<code>docsify</code>,
<code>docute</code>, <code>mkdocs</code>, or
<code>quarto_website</code>). The files in this folder are never altered
automatically by <code>altdoc</code> unless the user explicitly calls
<code>overwrite=TRUE</code>. They can thus be edited manually to
customize the sidebar and website.

## Usage

<pre><code class='language-R'>setup_docs(tool, path = ".", overwrite = FALSE)
</code></pre>

## Arguments

<table role="presentation">
<tr>
<td style="white-space: collapse; font-family: monospace; vertical-align: top">
<code id="tool">tool</code>
</td>
<td>
String. "docsify", "docute", "mkdocs", or "quarto_website".
</td>
</tr>
<tr>
<td style="white-space: collapse; font-family: monospace; vertical-align: top">
<code id="path">path</code>
</td>
<td>
Path to the package root directory.
</td>
</tr>
<tr>
<td style="white-space: collapse; font-family: monospace; vertical-align: top">
<code id="overwrite">overwrite</code>
</td>
<td>
Logical. If TRUE, overwrite existing files. Warning: This will
completely delete the settings files in the <code>altdoc</code>
directory, including any customizations you may have made.
</td>
</tr>
</table>

## Package structure

<code>altdoc</code> makes assumptions about your package structure:

<ul>
<li>

The homepage of the website is stored in <code>README.qmd</code>,
<code>README.Rmd</code>, or <code>README.md</code>.

</li>
<li>

<code style="white-space: pre;">vignettes/</code> stores the vignettes
in <code>.md</code>, <code>.Rmd</code> or <code>.qmd</code> format.

</li>
<li>

<code style="white-space: pre;">docs/</code> stores the rendered
website. This folder is overwritten every time a user calls
<code>render_docs()</code>, so you should not edit it manually.

</li>
<li>

<code style="white-space: pre;">altdoc/</code> stores the settings files
created by <code>setup_docs()</code>. These files are never modified
automatically after initialization, so you can edit them manually to
customize the settings of your documentation and website. All the files
stored in <code style="white-space: pre;">altdoc/</code> are copied to
<code style="white-space: pre;">docs/</code> and made available as
static files in the root of the website.

</li>
<li>

These files are imported automatically: <code>NEWS.md</code>,
<code>CHANGELOG.md</code>, <code>CODE_OF_CONDUCT.md</code>,
<code>LICENSE.md</code>, <code>LICENCE.md</code>.

</li>
</ul>

## Altdoc variables

The settings files in the <code style="white-space: pre;">altdoc/</code>
directory can include <code style="white-space: pre;">$ALTDOC</code>
variables which are replaced automatically by <code>altdoc</code> when
calling <code>render_docs()</code>:

<ul>
<li>

<code style="white-space: pre;">$ALTDOC_PACKAGE_NAME</code>: Name of the
package from <code>DESCRIPTION</code>.

</li>
<li>

<code style="white-space: pre;">$ALTDOC_PACKAGE_VERSION</code>: Version
number of the package from <code>DESCRIPTION</code>

</li>
<li>

<code style="white-space: pre;">$ALTDOC_PACKAGE_URL</code>: First URL
listed in the DESCRIPTION file of the package.

</li>
<li>

<code style="white-space: pre;">$ALTDOC_PACKAGE_URL_GITHUB</code>: First
URL that contains "github.com" from the URLs listed in the DESCRIPTION
file of the package. If no such URL is found, lines containing this
variable are removed from the settings file.

</li>
<li>

<code style="white-space: pre;">$ALTDOC_MAN_BLOCK</code>: Nested list of
links to the individual help pages for each exported function of the
package. The format of this block depends on the documentation
generator.

</li>
<li>

<code style="white-space: pre;">$ALTDOC_REFERENCE</code>: Link to the
generated reference index, a page listing every documented topic with a
one-line summary. See the "Reference index" section below.

</li>
<li>

<code style="white-space: pre;">$ALTDOC_VIGNETTE_BLOCK</code>: Nested
list of links to the vignettes. The format of this block depends on the
documentation generator.

</li>
<li>

<code style="white-space: pre;">$ALTDOC_VERSION</code>: Version number
of the altdoc package.

</li>
</ul>

Also note that you can store images and static files in the
<code style="white-space: pre;">altdoc/</code> directory. All the files
in this folder are copied to
<code style="white-space: pre;">docs/</code> and made available in the
root of the website, so you can link to them easily.

## Reference index

<code>render_docs()</code> writes a reference index to
<code>reference.md</code>: a page listing every documented topic with a
one-line summary. Link to it from the settings file with the
<code style="white-space: pre;">$ALTDOC_REFERENCE</code> variable.

Each summary is read from the <code style="white-space: pre;">
</code> of the topic’s <code>.Rd</code> file, so it is written once in
the roxygen2 <code style="white-space: pre;">@title</code> and never
retyped. The page is rebuilt on every <code>render_docs()</code> call,
so a summary can never drift out of sync with the help page it
describes.

By default the index holds a single "All functions" section listing
every topic that is not marked <code style="white-space: pre;">@keywords
internal</code>. To group the topics instead, create
<code>altdoc/reference.yml</code>:

<pre>reference:
  - title: Data
    desc: Load and reshape survey data.
    contents:
      - as_pop_data
      - starts_with("read_")
  - title: Modeling
    subtitle: Estimation
    contents:
      - has_concept("estimation")
</pre>

Each section may set <code>title</code>, <code>subtitle</code>,
<code>desc</code>, and <code>contents</code>. This is the same schema
<code>pkgdown</code> uses for the
<code style="white-space: pre;">reference:</code> key of
<code style="white-space: pre;">\_pkgdown.yml</code>, so an existing
block can be moved over unchanged.

An entry of <code>contents</code> is either a topic name (or alias), or
one of these selectors:

<ul>
<li>

<code>starts_with(“x”)</code>, <code>ends_with(“x”)</code>,
<code>contains(“x”)</code>: match the start, end, or any part of a topic
name or alias.

</li>
<li>

<code>matches(“x”)</code>: match a regular expression.

</li>
<li>

<code>has_keyword(“x”)</code>, <code>has_concept(“x”)</code>,
<code>lacks_concepts(“x”)</code>: match the
<code style="white-space: pre;"></code> and
<code style="white-space: pre;"></code> tags. roxygen2 writes
<code style="white-space: pre;">@family</code> to
<code style="white-space: pre;"></code>.

</li>
<li>

<code>everything()</code>: every topic.

</li>
</ul>

Prefix an entry with <code>-</code> to remove its matches instead of
adding them; when the first entry of a section is a removal, the section
starts from every non-internal topic. Selectors skip topics marked
<code style="white-space: pre;">@keywords internal</code> unless called
with <code>internal = TRUE</code>.

Topics missing from <code>altdoc/reference.yml</code> are reported at
render time and collected in a trailing "Other" section, so they are
never silently dropped from the index.

The page’s heading is "Package index", the name <code>pkgdown</code>
gives the same page, so a reader arriving from a "Reference" navigation
entry sees a heading that says what the page is rather than repeating
how they got there. Set a top-level <code>title</code> key to change it:

<pre>title: Function reference
reference:
  - title: Data
    contents:
      - as_pop_data
</pre>

<code>title</code> and <code>reference</code> are the only top-level
keys <code>altdoc/reference.yml</code> accepts; anything else is an
error. A file holding a bare list of sections with no
<code style="white-space: pre;">reference:</code> key is still accepted,
for a block moved over from <code>pkgdown</code> unchanged, but has
nowhere to put <code>title</code> and so always uses the default.

## Altdoc preambles

When you call <code>render_docs()</code>, <code>altdoc</code> will
automatically paste the content of one of these three files to the top
of a document:

<ul>
<li>

<code>altdoc/preamble_vignettes_qmd.yml</code>

</li>
<li>

<code>altdoc/preamble_vignettes_rmd.yml</code>

</li>
<li>

<code>altdoc/preamble_man_qmd.yml</code>

</li>
</ul>

The README file uses the vignette preamble.

To preempt this behavior, add your own preamble to the README file or to
a vignette.

## Examples

``` r
library("altdoc")

if (interactive()) {

  # Create docute documentation
  setup_docs(tool = "docute")

  # Create docsify documentation
  setup_docs(tool = "docsify")

  # Create mkdocs documentation
  setup_docs(tool = "mkdocs")

  # Create quarto website documentation
  setup_docs(tool = "quarto_website")
}
```
