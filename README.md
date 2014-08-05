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

Clone this repository to a web-accessible directory.  The instructions below assume textorum is being installed in a webroot; `tinymce.html` may need to be edited to reflect the location of tinymce and similar otherwise.

### Using OS X:

	brew install node

### Otherwise:

- Install node.js (v0.8.16 or later is known to work) and npm (v1.1.70 or later is known to work), using a package manager or from the [download page](http://nodejs.org/download/)
- Use the commands from [this page](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager) to install Node via a package manager (Ubuntu, etc.)
- Install node.js and npm (using a package manager or from the [download page](http://nodejs.org/download/))
- Use the commands from [this page](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager) to install Node via a package manager (Ubuntu, etc.)
- Install Ruby (1.9.3-p194 is known to work; later patchlevels may have problems) and RubyGems (using a package manager or from [ruby](http://www.ruby-lang.org/en/downloads/), [rubygems](https://rubygems.org/pages/download))

### In the textorum dir:

	npm install -g grunt-cli
	npm install
	bundle install

### In the webroot (if tinymce.html is unmodified):

#### Install jstree v.pre1.0

From an archive:

	curl -LO https://github.com/vakata/jstree/archive/v.pre1.0.zip
	unzip v.pre1.0.zip
	mv jstree-v.pre1.0 jstree

Or from git:

Known good revision: `9c41e435d5aee9647e26500200e30b359bb96ae0`; tracking v.pre1.0 release branch in development

	git clone -b v.pre1.0 https://github.com/vakata/jstree.git
	cd jstree
	git checkout 9c41e435d5aee9647e26500200e30b359bb96ae0

#### Install tinymce

From an archive:

    curl -LO http://github.com/downloads/tinymce/tinymce/tinymce_3.5.8.zip
    unzip tinymce_3.5.8.zip

Or from git (tracking master branch until Textorum release):

	git clone https://github.com/tinymce/tinymce.git
	cd tinymce
	ant
	cd ..

### To compile the SASS and CoffeeScript to CSS and JavaScript:

	grunt

### To watch (continually compile) the SASS and CoffeeScript:

	grunt watch

### To build the distribution (for use with Annotum):

	grunt dist

### Ubuntu Cheat Sheet for Dev

```
cd ~/Web/wordpress/wp-content
sudo rm -rf themes
git clone git@github.com:Annotum/Annotum.git themes
cd themes
git checkout textorum-integration
git submodule update --init
cd annotum-base/js/textorum/
git checkout develop
sudo npm install -g grunt-cli
sudo npm install
sudo gem install bundler #if not already installed
sudo bundle install
grunt dist

```

## Example instructions

- Open <http://textorum.example.com/tinymce.html> (adjusted for where you installed Textorum)
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

