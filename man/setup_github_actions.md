

# Create a Github Actions workflow

[**Source code**](https://github.com/etiennebacher/altdoc/tree/main/R/setup_github_actions.R#L28)

## Description

This function creates a Github Actions workflow in
".github/workflows/altdoc.yaml". This workflow will automatically render
the website using the setup specified in the folder "altdoc" and will
push the output to the branch "gh-pages".

## Usage

<pre><code class='language-R'>setup_github_actions(
  path = ".",
  multiversion = FALSE,
  default_landing_page = "main",
  refs_order = "main latest-tag",
  branches_or_tags_to_list = "^main\$|^latest-tag\$|^v([0-9]+[.])?([0-9]+[.])?([0-9]+)(-rc[0-9]+)?\$"
)
</code></pre>

## Arguments

<table role="presentation">
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
<code id="multiversion">multiversion</code>
</td>
<td>
Logical. If <code>TRUE</code>, configure the workflow to publish
versioned documentation under <code>gh-pages/\<branch-or-tag\>/</code>
and add a second job using
<code>insightsengineering/r-pkgdown-multiversion</code> to maintain a
version landing page and version switcher links.
</td>
</tr>
<tr>
<td style="white-space: collapse; font-family: monospace; vertical-align: top">
<code id="default_landing_page">default_landing_page</code>
</td>
<td>
Character scalar. The default landing page passed to
<code>r-pkgdown-multiversion</code> when <code>multiversion =
TRUE</code>.
</td>
</tr>
<tr>
<td style="white-space: collapse; font-family: monospace; vertical-align: top">
<code id="refs_order">refs_order</code>
</td>
<td>
Character scalar. Space-separated ref order passed to
<code>r-pkgdown-multiversion</code> when <code>multiversion =
TRUE</code>.
</td>
</tr>
<tr>
<td style="white-space: collapse; font-family: monospace; vertical-align: top">
<code id="branches_or_tags_to_list">branches_or_tags_to_list</code>
</td>
<td>
Character scalar. Regular expression used by
<code>r-pkgdown-multiversion</code> to decide which refs appear in the
versions list when <code>multiversion = TRUE</code>.
</td>
</tr>
</table>

## Value

No value returned. Creates the file ".github/workflows/altdoc.yaml"

## Examples

``` r
library("altdoc")

if (interactive()) {
  setup_github_actions()
}
```
