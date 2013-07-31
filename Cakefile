###
# Cakefile - Task automation for Textorum development
#
# Copyright (C) 2013 Crowd Favorite, Ltd. All rights reserved.
#
# This file is part of Textorum.
#
# Licensed under the MIT license:
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
###

Q = require 'q'
fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'
{minify} = require 'uglify-js'
temp = require 'temp'
requirejs = require 'requirejs'
util = require 'util'

execPromise = (file, options) ->
  qExec = Q.defer()
  exec file, options, (e, stdout, stderr) ->
    if e
      qExec.reject
        e: e
        stdout: stdout
        stderr: stderr
    else
      qExec.resolve
        e: e
        stdout: stdout
        stderr: stderr
  return qExec.promise
  Q.nfbind(exec)

licensePreamble = """/*
Copyright (C) 2013 Crowd Favorite, Ltd. All rights reserved.

This file is part of Textorum.

Licensed under the MIT license:

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
"""

# Make sure we have our dependencies
try
  colors     = require 'colors'
  wrench     = require 'wrench'
  coffeelint = require 'coffeelint'
catch error
  console.error 'Please run `npm install` first'
  process.exit 1

try
  growl = require 'growl'
catch error
  growl = ->

mkdirSync_p = (dirpath, mode, position) ->
  parts = require("path").normalize(dirpath).split(path.sep)
  mode = mode or process.umask()
  position = position or 0
  return true  if position >= parts.length
  directory = parts.slice(0, position + 1).join(path.sep) or path.sep
  try
    fs.statSync directory
    mkdirSync_p dirpath, mode, position + 1
  catch e
    try
      fs.mkdirSync directory, mode
      mkdirSync_p dirpath, mode, position + 1
    catch e
      throw e unless e.code is "EEXIST"
      mkdirSync_p dirpath, mode, position + 1


# Setup directory paths
paths =
  tmpDir: '.tmp'
  srcDir:  'src' # Uncompiled coffeescript / et cetera
  testDir: 'test'
  libDir: 'lib' # Compiled .js
  distDir: 'dist/textorum' # Minified output

paths.testLibDir = paths.testDir + '/lib'

# Create directories if they do not already exist
for dir in [paths.distDir, paths.tmpDir]
  mkdirSync_p dir, '0755' if not fs.existsSync dir

rjsBuilt = temp.openSync()

appJS = [
  'vendor/require.js',
  path.join(paths.libDir, 'require-config.js'),
  'vendor/jquery.scrollintoview.js',
  'vendor/jstree/jquery.jstree.js',
  rjsBuilt.path
]

noUglifyJS = [
  rjsBuilt.path,
]

option '-d', '--debug', 'Do not minify when compiling'

uglifyOptions = {}

# Read in package.json
packageInfo = JSON.parse fs.readFileSync path.join __dirname, 'package.json'

coffeeLintConfig =
  no_tabs:
    level: 'error'
  no_trailing_whitespace:
    level: 'error'
  max_line_length:
    level: 'warn'
    value: 120
  camel_case_classes:
    level: 'error'
  indentation:
    value: 2
    level: 'error'
  no_implicit_braces:
    level: 'ignore'
  no_trailing_semicolons:
    level: 'error'
  no_plusplus:
    level: 'ignore'
  no_throwing_strings:
    level: 'error'
  line_endings:
    value: 'unix'
    level: 'error'

task 'build', 'Compiles JavaScript and CSS files', ->
  compileAll()

task 'watch', 'Automatically recompile CoffeeScript files to JavaScript, SASS to CSS', ->
  console.log "Watching coffee and sass files for changes, press Control-C to quit".yellow
  srcWatcher  = exec "coffee --compile --watch --output #{paths.libDir} #{paths.srcDir}"
  srcWatcher.stderr.on 'data', (data) ->
    console.error stripEndline(data).red
    growl stripEndline(data), { title: 'coffee compile error' }
  srcWatcher.stdout.on 'data', (data) ->
    filenameMatcher = new RegExp("^In #{paths.srcDir}/(.*)\.coffee")
    if /\s-\scompiled\s/.test data
      process.stdout.write data.green
    else
      process.stderr.write data.red
      growl data, { title: 'coffeescript error' }
      #filenameMatch = data.match /^In (.*)\.coffee/
      filenameMatch = data.match filenameMatcher
      if filenameMatch and filenameMatch[1]
        # Add warning into code since watch window is in bg
        insertJsError filenameMatch[1], "CoffeeScript compilation error: #{data}"

  testWatcher = exec "coffee --compile --watch --output #{paths.testLibDir} #{paths.testDir}"
  testWatcher.stderr.on 'data', stdErrorStreamer()
  testWatcher.stdout.on 'data', (data) ->
    if /\s-\scompiled\s/.test data
      process.stdout.write data.green
    else
      process.stderr.write data.red
      growl data, { title: 'coffeescript test compile error' }
  sassWriter = (data) ->
    if !data
      return false
    if /^>>>/.test data
      return false
    data = data.replace /^\s*/, ' - '
    if /^\s*-\serror\s/.test data
      err = data.match /(.*)\s+\((Line \d+: .*)\)/
      if err
        process.stdout.write "#{err[1].red}\n     #{err[2].red}\n"
        growl "#{err[1]} | #{err[2]}", { title: 'sass line error' }

      else
        process.stdout.write ">>> #{data.red}"
        growl data, { title: 'sass error' }
    else
      process.stdout.write data.green
  sassWriterCallback = (error, stdout, stderr) ->
    if stdout
      sassWriter stdout
    if stderr
      sassWriter stderr
  exec "sass --update #{paths.srcDir}:#{paths.libDir}", sassWriterCallback
  sassWatcher = exec "sass --watch #{paths.srcDir}:#{paths.libDir}"
  sassWatcher.stderr.on 'data', stdErrorStreamer()
  sassWatcher.stdout.on 'data', sassWriter
  try
    kexec = require('kexec')
    console.log "Watching Cakefile for changes".yellow
    fs.watchFile path.join(process.cwd(), "Cakefile"), (curr, prev) ->
      if +curr.mtime isnt +prev.mtime
        console.log "Cakefile changed, restarting watch"
        sassWatcher.kill()
        testWatcher.kill()
        srcWatcher.kill()
        kexec "npm run-script watch"
  catch ex
    console.log "problem loading kexec, not watching Cakefile: ".yellow + ex


task 'lint', 'Check CoffeeScript for lint', ->
  console.log "Checking *.coffee for lint".yellow
  pass = "✔".green
  warn = "⚠".yellow
  fail = "✖".red
  getSourceFilePaths().forEach (filepath) ->
    fs.readFile filepath, (err, data) ->
      shortPath = filepath.substr paths.srcDir.length + 1
      result = coffeelint.lint data.toString(), coffeeLintConfig
      if result.length
        hasError = result.some (res) -> res.level is 'error'
        level = if hasError then fail else warn
        console.error "#{level}  #{shortPath}".red
        for res in result
          level = if res.level is 'error' then fail else warn
          console.error "   #{level}  Line #{res.lineNumber}: #{res.message}"
      else
        console.log "#{pass}  #{shortPath}".green


task 'server', 'Start a web server in the root directory', ->
  console.log "Starting web server at http://localhost:8000"
  proc = exec "python -m SimpleHTTPServer"
  proc.stderr.on 'data', stdOutStreamer (data) -> data.grey
  proc.stdout.on 'data', stdOutStreamer (data) -> data.grey

task 'test:phantom', 'Run tests via phantomJS', ->
  exec "which phantomjs", (e, o, se) ->
    if e
      console.error "Must install PhantomJS http://phantomjs.org/".red
      process.exit -1

  # Disable web security so we don't have to run a server on localhost for AJAX
  # calls
  console.log "Running unit tests via PhantomJS".yellow
  p = exec "phantomjs --web-security=no #{paths.testDir}/phantom-driver.coffee"
  p.stderr.on 'data', stdErrorStreamer (data) -> data.red
  # The phantom driver outputs JSON
  bufferedOutput = ''
  p.stdout.on 'data', (data) ->
    bufferedOutput += data
    return unless bufferedOutput[bufferedOutput.length - 1] is "\n"

    unless /^PHANTOM/.test bufferedOutput
      process.stdout.write data.grey
      return

    pass = "✔".green
    fail = "✖".red

    # Split lines
    for line in (bufferedOutput.split '\n')
      continue unless line
      try
        obj = JSON.parse(line.substr 9)
        switch obj.name
          when 'error'
            console.error "#{fail}  JS Error: #{obj.result.msg}"
            console.dir obj.result.trace if obj.result.trace

          when 'log'
            continue if obj.result.result
            if 'expected' of obj.result
                console.error "#{fail} Failure: #{obj.result.message}; Expected: #{obj.result.expected}, Actual: #{obj.result.actual}"
            else
              console.error "#{fail} Failure: #{obj.result.module}: #{obj.result.name} - #{obj.result.message}"

          when 'moduleDone'
            if obj.result.failed
              console.error "#{fail}  #{obj.result.name} module: #{obj.result.passed} tests passed, " + "#{obj.result.failed} tests failed".red
            else
              console.log "#{pass}  #{obj.result.name} module: #{obj.result.total} tests passed"

          # Output statistics on completion
          when 'done'
            console.log "\nFinished in #{obj.result.runtime/1000}s".grey
            if obj.result.failed
              console.error "#{fail}  #{obj.result.passed} tests passed, #{obj.result.failed} tests failed (#{Math.round(obj.result.passed / obj.result.total * 100)}%)"
              process.exit -1
            else
              console.log "#{pass}  #{obj.result.total} tests passed"
      catch ex
        console.error "JSON parsing fail: #{line}".red

    bufferedOutput = ''

  p.on 'exit', (code) ->
    process.exit code


task 'clean', 'Remove temporary and generated files', ->
  for file in fs.readdirSync paths.libDir
    filepath = path.join paths.libDir, file
    stats = fs.lstatSync filepath
    if stats.isDirectory()
      wrench.rmdirSyncRecursive filepath
      console.log "Removed #{filepath}".magenta
    else if /\.js$/.test filepath
      fs.unlinkSync filepath
      console.log "Removed #{filepath}".magenta

  # Remove generated test jS
  for file in fs.readdirSync paths.testLibDir
    continue unless /\.js$/.test file
    filepath = path.join paths.testLibDir, file
    fs.unlinkSync filepath
    console.log "Removed #{filepath}".magenta

  # Remove dist/ and .tmp/
  for dir in [paths.tmpDir, paths.distDir]
    continue if not fs.existsSync dir
    wrench.rmdirSyncRecursive dir
    console.log "Removed #{dir}".magenta

task 'size', 'Report file size', ->
  return if not fs.existsSync paths.distDir
  for file in fs.readdirSync paths.distDir
    # Skip non-JS files
    if /\.js$/.test file
      stats = fs.statSync path.join paths.distDir, file
      console.log "#{file}: #{stats.size} bytes"


task 'dist', 'Compiles and minifies JavaScript file for production use', (options) ->
  invoke('build')
  .then (result) ->
    buildAppJS(options)
  .then (result) ->
    console.log "moving css into place"
    recursivePathCopy paths.libDir, path.join(paths.distDir, 'css'), /\.css$/
  .then (result) ->
    console.log "moving fonts into place"
    recursivePathCopy 'fonts', path.join(paths.distDir, 'fonts'), /./
  .then (result) ->
    console.log "moving images into place"
    recursivePathCopy 'img', path.join(paths.distDir, 'img'), /\.(png|jpe?g|gif|bmp|ico)$/i
  .then (result) ->
    console.log "moving schema into place"
    recursivePathCopy 'schema', path.join(paths.distDir, 'schema'), /\.s?rng$/
  .then (result) ->
    console.log "moving xsl into place"
    recursivePathCopy 'xsl', path.join(paths.distDir, 'xsl'), /\.xsl$/
  .then (result) ->
    Q.when(invoke 'size')
  .done ->
    console.log "finished with dist task"

compileAll = ->
  console.log "Compiling CoffeeScript".yellow
  compileAllPromises = []
  compileAllPromises.push execPromise("coffee --compile --output #{paths.testLibDir} #{paths.testDir}").catch((r) ->
    console.error "Error encountered while compiling tests".red
    console.error "" + r.stdout + r.stderr
    process.exit 1
  )
  compileAllPromises.push execPromise("coffee --compile --output #{paths.libDir} #{paths.srcDir}").catch((r) ->
    console.error "Error encountered while compiling CoffeeScript".red
    console.error "" + r.stdout + r.stderr
    process.exit 1
  ).then((r) ->
    console.log "CoffeeScript Compiled".green
    r
  )
  console.log "Compiling SCSS".yellow
  compileAllPromises.push execPromise("sass --update #{paths.srcDir}:#{paths.libDir}").catch((r) ->
    console.error "Error encountered while compiling SCSS".red
    console.error "" + r.stdout + r.stderr
    process.exit 1
  ).then((r) ->
    console.log "SCSS Compiled".green
    r
  )
  return Q.all(compileAllPromises)

buildAppJS = (options, output_dir) ->
  output_dir ||= paths.distDir
  console.log "running r.js optimizer"
  requireConfig =
    name: 'vendor/almond'
    nodeRequire: require
    baseUrl: 'lib'
    paths:
      "vendor/almond": "../vendor/almond"
      text: "../vendor/text"
      sax: "../vendor/sax"
      "jqueryui-popups": "../vendor/tinymce.jqueryui.popups"
      "tinymce-jquery": "../vendor/tinymce_jquery/jquery.tinymce"
      "tinymce-jquery-adapter": "../vendor/tinymce_jquery/adapter"
      jquery: 'fake/jquery'
      stream: 'fake/stream'
    optimize: (if options.debug then 'none' else 'uglify2')
    out: rjsBuilt.path
    inlineText: true
    include: ['jquery',
                'textorum/tinymce/plugin',
                'jqueryui-popups',
                'tinymce-jquery',
                'tinymce-jquery-adapter'
              ]
    insertRequire: ['textorum/tinymce/plugin']
    wrap:
      startFile: 'vendor/start.frag'
      endFile: 'vendor/end.frag'
  qOptimize = Q.defer()
  requirejs.optimize(requireConfig, qOptimize.resolve, qOptimize.reject)
  qOptimize.promise.then((buildResponse) ->
    console.log buildResponse
    console.log "done"
    concatAppJS(options, path.join(output_dir, "editor_plugin.js"))
  ).catch (error) ->
    console.log "buildAppJS error: #{error}"
    throw error

concatAppJS = (options = {}, outfile) ->
  outfile ||= path.join(paths.distDir, "editor_plugin.js")
  console.log "building to #{outfile}"
  fs.writeFileSync(outfile, licensePreamble + '\n')
  for jsfile in appJS
    stats = fs.statSync(jsfile)
    if jsfile is rjsBuilt.path
      fs.appendFileSync(outfile, "\n/***r.js built ***/\n")
    else
      fs.appendFileSync(outfile, "\n/*** #{jsfile} ***/\n")

    if options.debug or jsfile in noUglifyJS
      if jsfile is rjsBuilt.path
        console.log "concatenating r.js built file - #{stats.size} bytes"
      else
        console.log "concatenating #{jsfile} - #{stats.size} bytes"
      fs.appendFileSync(outfile, fs.readFileSync(jsfile))
    else
      min = minify(jsfile, uglifyOptions).code
      console.log "minifying #{jsfile} - #{stats.size} bytes became #{min.length} bytes"
      fs.appendFileSync(outfile, min)
      min = null
  console.log "done building to #{outfile}"
  return Q("done building to #{outfile}")

finishAppCSS = (options = {}, output_dir) ->
  output_dir ||= path.join(paths.distDir, 'css')
  console.log "moving css into place"
  return recursivePathCopy paths.libDir, output_dir, /\.css$/

findCommonDirPrefix = (leftpath, rightpath) ->
  relative = path.relative(leftpath, rightpath)
  leftdirs = leftpath.split(path.sep)
  rightdirs = rightpath.split(path.sep)
  commonpath = []
  for pathdir in leftdirs
    if rightdirs.shift() is pathdir
      commonpath.push pathdir
    else
      break
  if commonpath.length
    commonpath.push ""
  return commonpath.join(path.sep)

recursivePathCopy = (sourcedir, destdir, pattern = /./) ->
  sourcedir = path.relative(process.cwd(), path.resolve(path.normalize(sourcedir)))
  destdir = path.relative(process.cwd(), path.resolve(path.normalize(destdir)))
  mkdirSync_p destdir, '0755'
  commonprefix = findCommonDirPrefix(sourcedir, destdir)
  commonprefixlength = commonprefix.length
  for filepath in getSourceFilePaths(sourcedir, pattern)
    targetpath = path.dirname(filepath).substr(sourcedir.length)
    if targetpath
      mkdirSync_p path.join(destdir, targetpath), '0755'
    newfilepath = path.join(destdir, targetpath, path.basename(filepath))
    console.log "* #{filepath.substr(commonprefixlength)} -> #{newfilepath.substr(commonprefixlength)}"
    oldfile = fs.createReadStream(filepath)
    newfile = fs.createWriteStream(newfilepath)
    oldfile.pipe newfile
  return Q("done copying #{pattern} from #{sourcedir.substr(commonprefixlength)} to #{destdir.substr(commonprefixlength)}")

# Helper for finding all source files
getSourceFilePaths = (dirPath = paths.srcDir, pattern = /\.coffee$/) ->
  files = []
  for file in fs.readdirSync dirPath
    filepath = path.join dirPath, file
    stats = fs.lstatSync filepath
    if stats.isDirectory()
      files = files.concat getSourceFilePaths filepath, pattern
    else if pattern.test file
      files.push filepath
  files

# Helper for stripping trailing endline when outputting
stripEndline = (str) ->
  return str.slice(0, str.length - 1) if str[str.length - 1] is "\n"
  return str

# Helper for inserting error text into a given file
insertJsError = (filename, js) ->
  jsFile = fs.openSync((path.join paths.libDir, "#{filename}.js"), 'w')
  fs.writeSync jsFile, """console.error(unescape("#{escape js}"))""" + "\n"
  fs.closeSync jsFile

stdOutStreamer = (filter) ->
  (str) ->
    str = filter str if filter
    process.stderr.write str

stdErrorStreamer = (filter) ->
  (str) ->
    str = filter str if filter
    process.stderr.write str.red

