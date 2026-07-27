

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
<code>CONTRIBUTING.md</code>, <code>LICENSE.md</code>,
<code>LICENCE.md</code>.

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

<code style="white-space: pre;">$ALTDOC_LOGO</code>: File name of the
package logo, which <code>render_docs()</code> copies into the website
root. The first of <code>logo.svg</code>,
<code>man/figures/logo.svg</code>, <code>logo.png</code>, or
<code>man/figures/logo.png</code> to exist is used. If the package has
no logo, lines containing this variable are removed from the settings
file. Of the settings files created by <code>setup_docs()</code>, only
<code>quarto_website.yml</code> refers to this variable; add it yourself
to use a logo with another documentation generator, or to a settings
file created before this variable existed.

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

A file holding a bare list of sections with no
<code style="white-space: pre;">reference:</code> key is still accepted,
for a block moved over from <code>pkgdown</code> unchanged, but has
nowhere to put <code>title</code> and so always uses the default.

## Sidebar labels

Every generator labels a man page in the sidebar with its topic name,
which says what a topic is called but not what it does. Set
<code>sidebar_labels</code> to <code>name-and-title</code> to append the
topic’s <code style="white-space: pre;">
</code>, so the summary written once in the roxygen2
<code style="white-space: pre;">@title</code> reaches the sidebar as
well as the reference index:

<pre>sidebar_labels: name-and-title
</pre>

A topic then reads <code style="white-space: pre;">as_pop_data(): Load a
cross-sectional antibody survey data set</code> rather than
<code>as_pop_data</code>. The name keeps the
<code style="white-space: pre;">()</code> suffix only when the topic
documents something callable, matching how the reference index writes
it.

This is opt-in: the default, <code>name</code>, is what every generator
did before, so an existing site’s sidebar does not change until its
author asks for it.

Titles are truncated to 40 characters so a long one cannot overflow a
narrow sidebar. Only the title is shortened, never the topic name, so
entries stay scannable by the name a reader is looking for. Set
<code>sidebar_label_width</code> to change the limit:

<pre>sidebar_labels: name-and-title
sidebar_label_width: 60
</pre>

<code>title</code>, <code>reference</code>, <code>sidebar_labels</code>,
and <code>sidebar_label_width</code> are the only top-level keys
<code>altdoc/reference.yml</code> accepts; anything else is an error. So
is an unrecognized <code>sidebar_labels</code> value, and a
<code>sidebar_label_width</code> that is not a whole number of at least
4 — below 4 leaves no room for the ellipsis, and a fractional width
would be silently truncated, so <code>4.5</code> would quietly behave as
<code>4</code>.

Setting <code>sidebar_label_width</code> without <code>sidebar_labels:
name-and-title</code> warns, since the width has nothing to apply to on
its own.

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
