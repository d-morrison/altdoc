

# Mixed runnable and non-runnable examples

## Description

Mixed runnable and non-runnable examples

## Usage

<pre><code class='language-R'>hello_dontrun()
</code></pre>

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
