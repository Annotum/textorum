textorum
========

Advanced, validating, structured text (XML) editing component. Part of the Annotum project.

## Project Layout

- `src/` - .coffee and .js
- `vendor/` - .coffee and .js, third party
- `lib/` - compiled to .js
- `test/` - qunit tests in .coffee and related support
    - `specs/` - pavlov specfiles in .coffee
	- `lib/` - compiled tests and specs

- `build/` - support files and configurations for project building
	- `textorum.build.js` - r.js file (probably gets subsumed into Cakefile)
	- `fragments/` - javascript fragments / templates for building
- `dist/` - Production-compiled output
- `Cakefile` - cake (coffeescript make) automation
- `package.json` - dependencies, `npm install` to install

## Installation Instructions

Clone this repository to a web-accessible directory.  The instructions below assume textorum is being installed in a webroot; `tinymce.php` may need to be edited to reflect the location of tinymce and similar otherwise.

### Using OS X:

	brew install node

### Otherwise:

- Install node.js and npm (using a package manager or from the [download page](http://nodejs.org/download/))
- Install Ruby (1.9.3-p194 is known to work; later patchlevels may have problems) and RubyGems (using a package manager or from [ruby](http://www.ruby-lang.org/en/downloads/), [rubygems](https://rubygems.org/pages/download))

### In the textorum dir:

	npm install
	bundle install
	
	git clone -b v.pre1.0 https://github.com/vakata/jstree.git

	git clone --depth=1 https://github.com/tinymce/tinymce.git	
	cd tinymce
	ant
	cd ..

### To compile the SASS and CoffeeScript to CSS and JavaScript:

	npm run-script build

### To watch (continually compile) the SASS and CoffeeScript:

	npm run-script watch

## Example instructions

- Open <http://textorum.example.com/tinymce.php> (adjusted for where you installed Textorum)
- Enter an absolute or relative path to a Textorum-compatible XML document in the input box and click Load
- Toggling source view or pressing "Save" will submit the re-assembled XML to a test script that echos it back

Tested to work in Chrome.  Probably works in Firefox; known not to work in IE.

## Dependencies

Textorum depends on several external javascript libraries, including:

- TinyMCE
- jQuery
- jQuery UI
- JSTree

With the goal of tracking compatibility with (and potentially dependence on) the same versions as WordPress uses.  For development purposes, they will track WordPress trunk; releases will target versions available with the then-current WordPress release.

## Caveats

Many.  This is currently a very incomplete 

(this space intentionally left blank)

### XML implementation

The XML namespace handling is relatively naive: all namespaces are assumed to be global, and no scoping rules are used.  Therefore, a document which depends on complex or overlapping namespaces or namespace resets may be mishandled.  A simple example:

    <foo xmlns:a="http://example.com/a">
      <bar xmlns:a="http://example.com/b">
      	<a:baz/>
      </bar>
    </foo>

may be treated as though a:baz is either in the `/a` or the `/b` namespace (depending on the browser's XSLT behavior), rather than certainly being in the `/b` namespace by correct XML parsing.

As a workaround, documents can be passed through a namespace normalizer (such as <http://lenzconsulting.com/namespace-normalizer/> or <https://github.com/wendellpiez/XMLNamespaceFixup/blob/master/XSLT/namespace-cleanup.xsl>) before loading.  Unfortunately, neither one is effectively compatible with running in current browsers; the first produces inconsistent and sometimes empty results, and the second is XSLT 2.0, which is not commonly supported.

