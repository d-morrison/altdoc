

# Create a "conductor" tour

## Description

blah blah blah

## Methods

<h4>
Public methods
</h4>
<ul>
<li>

<a href="#method-Conductor-new">`hello_r6$new()`</a>

</li>
<li>

<a href="#method-Conductor-init">`hello_r6$init()`</a>

</li>
<li>

<a href="#method-Conductor-step">`hello_r6$step()`</a>

</li>
<li>

<a href="#method-Conductor-clone">`hello_r6$clone()`</a>

</li>
</ul>
<hr>

<a id="method-Conductor-new"></a>

<h4>
Method `new()`
</h4>
<h5>
Usage
</h5>

<pre>hello_r6\$new()</pre>

<h5>
Details
</h5>

Initialise `Conductor`.

<hr>

<a id="method-Conductor-init"></a>

<h4>
Method `init()`
</h4>
<h5>
Usage
</h5>

<pre>hello_r6\$init(session = NULL)</pre>

<h5>
Arguments
</h5>

<dl>
<dt>
`session`
</dt>
<dd>
A valid Shiny session. If `NULL` (default), the function
attempts to get the session with
`shiny::getDefaultReactiveDomain()`.
</dd>
</dl>

<h5>
Details
</h5>

Initialise `Conductor`.

<hr>

<a id="method-Conductor-step"></a>

<h4>
Method `step()`
</h4>
<h5>
Usage
</h5>

<pre>hello_r6\$step(title = NULL)</pre>

<h5>
Arguments
</h5>

<dl>
<dt>
`title`
</dt>
<dd>
Title of the popover.
</dd>
</dl>

<h5>
Details
</h5>

Add a step in a `Conductor` tour.

<hr>

<a id="method-Conductor-clone"></a>

<h4>
Method `clone()`
</h4>

The objects of this class are cloneable with this method.

<h5>
Usage
</h5>

<pre>hello_r6\$clone(deep = FALSE)</pre>

<h5>
Arguments
</h5>

<dl>
<dt>
`deep`
</dt>
<dd>
Whether to make a deep clone.
</dd>
</dl>
