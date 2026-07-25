

# Mixed runnable and non-runnable examples

## Description

Mixed runnable and non-runnable examples

## Usage

<pre><code class='language-R'>hello_dontrun(x = 2)
</code></pre>

## Arguments

<table role="presentation">
<tr>
<td style="white-space: nowrap; font-family: monospace; vertical-align: top">
<code id="x">x</code>
</td>
<td>
A parameter
</td>
</tr>
</table>

## Value

Some value

## Examples

``` r
library("testpkg.altdoc")

hello_dontrun()
```

    [1] "Hello, world!"

``` r
stop("this must never be evaluated")
```

``` r
hello_dontrun()
```

    [1] "Hello, world!"

``` r
Sys.sleep(1000)
```
