textorum
========

Advanced, validating, text editing component. Part of the Annotum project.

## Project Layout

- `src/` - .coffee and .js
- `vendor/` - .coffee and .js, third party
- `lib/` - compiled to .js
- `test/` - qunit tests in .coffee and related support
    - `specs/` - pavlov specfiles in .coffee
	- `lib/` - compiled tests and specs

- `build/` - support files and configurations for project building
	- `textorum.build.js` - r.js file (probably gets subsumed into Cakefile
	- `fragments/` - javascript fragments / templates for building
- `dist/` - Production-compiled output
- `Cakefile` - cake (coffeescript make) automation
- `package.json` - dependencies, `npm install` to install

## Installation Instructions

brew install node

_from the textorum dir:_

npm install
bundle install

git clone --depth=1 https://github.com/ckeditor/ckeditor-dev.git

cd ckeditor-dev; dev/builder/build.sh

cd ..

npm run-script watch

