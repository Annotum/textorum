fs     = require 'fs'
path   = require 'path'
{exec} = require 'child_process'

# Make sure we have our dependencies
try
  colors     = require 'colors'
  wrench     = require 'wrench'
  coffeelint = require 'coffeelint'
catch error
  console.error 'Please run `npm install` first'
  process.exit 1

# Setup directory paths
paths =
  tmpDir: '.tmp'
  srcDir:  'src' # Uncompiled coffeescript / et cetera
  testDir: 'test'
  libDir: 'lib' # Compiled .js
  distDir: 'dist' # Minified output

paths.testLibDir = paths.testDir + '/lib'

# Create directories if they do not already exist
for dir in [paths.distDir, paths.tmpDir]
  fs.mkdirSync dir, '0755' if not fs.existsSync dir

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

task 'dist', 'Compiles and minifies JavaScript file for production use', ->
  console.log "Compiling CoffeeScript".yellow
  exec "coffee --compile --output #{paths.testLibDir} #{paths.testDir}"
  exec "coffee --compile --output #{paths.libDir} #{paths.srcDir}", (e, o, se) ->
    if e
      console.error "Error encountered while compiling CoffeeScript".red
      console.error se
      process.exit 1

    console.log "CoffeeScript Compiled".green
    invoke 'size'

task 'build', 'Compiles JavaScript and CSS files', ->
  console.log "Compiling CoffeeScript".yellow
  exec "coffee --compile --output #{paths.testLibDir} #{paths.testDir}"
  exec "coffee --compile --output #{paths.libDir} #{paths.srcDir}", (e, o, se) ->
    if e
      console.error "Error encountered while compiling CoffeeScript".red
      console.error se
      process.exit 1
    console.log "CoffeeScript Compiled".green
  console.log "Compiling SCSS".yellow
  exec "sass --update #{paths.srcDir}:#{paths.libDir}", (e, o, se) ->
    if e
      console.error "Error encountered while compiling SCSS".red
      console.error se
      process.exit 1
    console.log "SCSS Compiled".green


task 'watch', 'Automatically recompile CoffeeScript files to JavaScript, SASS to CSS', ->
  console.log "Watching coffee and sass files for changes, press Control-C to quit".yellow
  srcWatcher  = exec "coffee --compile --watch --output #{paths.libDir} #{paths.srcDir}"
  srcWatcher.stderr.on 'data', (data) -> console.error stripEndline(data).red
  srcWatcher.stdout.on 'data', (data) ->
    filenameMatcher = new RegExp("^In #{paths.srcDir}/(.*)\.coffee")
    if /\s-\scompiled\s/.test data
      process.stdout.write data.green
    else
      process.stderr.write data.red
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
      else
        process.stdout.write ">>> #{err.red}"
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
    fs.watchFile path.join(process.cwd, "Cakefile"), (curr, prev) ->
      if +curr.mtime isnt +prev.mtime
        console.log "Cakefile changed, restarting watch"
        sassWatcher.kill()
        testWatcher.kill()
        srcWatcher.kill() 
        kexec "npm run-script watch"
  catch ex
    console.log "no kexec, not watching Cakefile".yellow


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

# Helper for finding all source files
getSourceFilePaths = (dirPath = paths.srcDir) ->
  files = []
  for file in fs.readdirSync dirPath
    filepath = path.join dirPath, file
    stats = fs.lstatSync filepath
    if stats.isDirectory()
      files = files.concat getSourceFilePaths filepath
    else if /\.coffee$/.test file
      files.push filepath
  files

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
