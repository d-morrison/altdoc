

# Check an altdoc project’s settings before rendering

## Description

Report configuration problems that <code>render_docs()</code> would
otherwise handle silently: an
<code style="white-space: pre;">$ALTDOC\_\*</code> variable altdoc does
not recognize, one whose source file is missing, a man page or vignette
the navigation never links, a missing or inconsistent site URL, and an
invalid <code>altdoc/reference.yml</code>.

Every check reports rather than aborts, and all checks run even when an
earlier one finds something, so one call lists everything there is to
fix.

## Usage

<pre><code class='language-R'>check_altdoc(path = ".")
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
</table>

## Details

The checks are grouped by what goes wrong when they fail.

<strong>Variables that never resolve.</strong> An unrecognized variable
— a typo, or one from a newer altdoc than the installed version — is
left alone, so the literal
<code style="white-space: pre;">$ALTDOC\_…</code> text reaches the
published page. A <em>recognized</em> variable whose source is missing
behaves differently: the whole line using it is dropped, which is
deliberate (it lets a settings file carry an entry unconditionally) and
therefore indistinguishable from a mistake without a check.

<strong>Pages nothing links to.</strong> A man page or vignette absent
from the navigation is still rendered and still fetchable; it just
cannot be reached by clicking. Settings files using
<code style="white-space: pre;">$ALTDOC_MAN_BLOCK</code> or
<code style="white-space: pre;">$ALTDOC_VIGNETTE_BLOCK</code> cannot
have this problem, since those blocks are generated from what is on
disk, so this only applies to a hand-authored navigation.

<strong>A missing site URL.</strong> <code>altdoc/pkgdown.yml</code>’s
<code style="white-space: pre;">urls:</code> block is what
<code>downlit</code> reads to autolink function calls in vignettes, and
it is populated from <code>DESCRIPTION</code>’s
<code style="white-space: pre;">URL:</code>. With no site URL the
autolinks simply do not appear, and a repository URL is not a substitute
— appending a page path to it yields a link that does not exist.

<strong>An invalid <code>altdoc/reference.yml</code>.</strong> This runs
the same validation <code>render_docs()</code> runs, so it reports
exactly what a render would refuse, without waiting for one.

The function is opt-in: <code>render_docs()</code> does not call it. A
render that warned about every one of these would be noisy on every
build, and one that errored would refuse work it can complete.

## Value

A character vector of findings, invisibly, one per problem, and empty
when nothing was found. The findings are also printed. Returning them
lets a caller act on the result — in a CI check, say — rather than
reading the console.

## Examples

``` r
library("altdoc")

if (interactive()) {

  check_altdoc()

}
```
