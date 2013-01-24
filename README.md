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

Clone this repository to a web-accessible directory.  The instructions below assume textorum is being installed in a webroot; `testload.php` may need to be edited to reflect the location of ckeditor-dev otherwise.

### Using OS X:

	brew install node

### Otherwise:

- Install node.js and npm (using a package manager or from the [download page](http://nodejs.org/download/))
- Install Ruby (1.9.3-p194 is known to work; later patchlevels may have problems) and RubyGems (using a package manager or from [ruby](http://www.ruby-lang.org/en/downloads/), [rubygems](https://rubygems.org/pages/download))

### In the textorum dir:

	npm install
	bundle install

	git clone --depth=1 https://github.com/ckeditor/ckeditor-dev.git

	cd ckeditor-dev
	./dev/builder/build.sh
	cd ..

### To watch and compile the SASS and CoffeeScript to CSS and JavaScript:

	npm run-script watch

## Example instructions

- Open <http://textorum.example.com/testload.php> (adjusted for where you installed Textorum)
- Enter an absolute or relative path to a Textorum-compatible XML document in the input box and click Load
- Toggling source view or pressing "Save" will submit the re-assembled XML to a test script that echos it back

Tested to work in Chrome.  Probably works in Firefox; known not to work in IE.

## Caveats

Many.  This is currently a very incomplete 

(this space intentionally left blank)