# System Modules
fs            = require 'fs'
{print}       = require 'util'
{spawn}       = require 'child_process'
path          = require 'path'

# Third Party Modules
watch         = require 'node-watch'
minimatch     = require 'minimatch'
connect       = require 'connect'
serveStatic   = require 'serve-static'

#### Configuration
app = connect()
# Port on localhost
_port = 3335

# Origin for development
_origin = "http://localhost:#{_port}"

# Scripts that must always be included
common_scripts = [
]

# Stylesheets that must always be included
common_style = [
]

# Static files to be copied over
static_files = [
  'img/glyphicons-halflings.png'
  'img/glyphicons-halflings-white.png'
]

# Scripts to build, even if not included anyway
worker_scripts = [
]

# For each template define scripts and stylesheets to include, these will be
# included or concatenated and potentially inlined in the order they are listed.
_templates =
  # File with dependencies
  'index.jade':
    # Scripts to be included
    scripts: [
      'lib/realtime-client-utils.js'
      'lib/jquery.min.js'
      'lib/bootstrap.min.js'
      'lib/codemirror.min.js'
      'script.coffee'
    ]
    # Stylesheets to be included
    style: [
      'lib/bootstrap.min.css'
      'lib/CodeMirror.styl'
      'style.styl'
    ]
    # Additional template arguments
    args: {
    }

swapSlash = (s) -> s.replace "\\", "/"

# Template arguments for template
template_arguments = (template) ->
  template = swapSlash template
  if not _templates[template]?
    print "Template #{template} isn't configured in `_templates`"
    return null
  rel = path.relative(path.dirname(template), __dirname)
  {scripts, style, args} = _templates[template]
  return {
    origin:   _origin
    args:     args
    scripts: [
      (swapSlash path.join rel, file.replace /\.(coffee|pegjs)$/, ".js" for file in common_scripts)...
      (swapSlash path.join rel, file.replace /\.(coffee|pegjs)$/, ".js" for file in scripts)...
    ]
    style: [
      (swapSlash path.join rel, file.replace /\.styl$/, ".css" for file in common_style)...
      (swapSlash path.join rel, file.replace /\.styl$/, ".css" for file in style)...
    ]
  }

# All files to be compiled
_all_files =
  templates:  []
  scripts:    [
    (path.normalize file for file in common_scripts)...
    (path.normalize file for file in worker_scripts)...
  ]
  style:      (path.normalize file for file in common_style)
  static:     (path.normalize file for file in static_files)
for template, {scripts, style} of _templates
  _all_files.templates.push  path.normalize template
  _all_files.scripts.push    (path.normalize file for file in scripts)...
  _all_files.style.push      (path.normalize file for file in style)...


# Command line tools
_cmds =
  coffee: 'coffee'
  stylus: 'stylus'
  jade:   'jade'
  docco:  'docco'
  pegjs:  'pegjs'
  cake:   'cake'
  git:    'git'

# Postfix commandline tools with .cmd if one windows
if process.platform is "win32"
  _cmds[id] = "#{cmd}.cmd"     for id, cmd of _cmds


#### Cake Tasks

task 'deploy', "Rebuild everything, push to gh-pages from bin/", ->
  # Delete everything from bin/, except dot-files (ie. .git/)
  binfolder = path.join __dirname, 'bin'
  for name in fs.readdirSync(binfolder)
    if name[0] is '.'
      continue
    file = path.join binfolder, name
    if fs.statSync(file).isDirectory()
      rmdir file
    else
      fs.unlinkSync file
  # Run cake release as subtask
  proc = spawn _cmds.cake, ['release']
  proc.stdout.on 'data', (data) -> print data
  proc.stderr.on 'data', (data) -> print data
  proc.on 'exit', (status) ->
    print_msg("cake release", status is 0, "")
    if status is 0
      # git add
      log = ""
      proc = spawn _cmds.git, ['add', '.'], cwd: binfolder
      proc.stdout.on 'data', (data) -> log += data
      proc.stderr.on 'data', (data) -> log += data
      proc.on 'exit', (status) ->
        print_msg("git add .", status is 0, log)
        if status is 0
          # git commit
          log = ""
          proc = spawn _cmds.git, ['commit', '-am', 'Deployment from master branch'], cwd: binfolder
          proc.stdout.on 'data', (data) -> log += data
          proc.stderr.on 'data', (data) -> log += data
          proc.on 'exit', (status) ->
            print_msg("git commit", status is 0, log)
            if status is 0
              # git push
              log = ""
              proc = spawn _cmds.git, ['push', 'origin', 'gh-pages'], cwd: binfolder
              proc.stdout.on 'data', (data) -> log += data
              proc.stderr.on 'data', (data) -> log += data
              proc.on 'exit', (status) ->
                print_msg("git push origin gh-pages", status is 0, log)

task 'release', "Rebuild everything for jonasfj.github.com", ->
  # Set origin for desired origin
  _origin = "http://jonasfj.github.com"
  invoke 'build'

task 'build', "Compile all source files", ->
  for file in _all_files.scripts
    if /\.coffee$/.test file
      compile file
    else if /\.pegjs$/.test file
      generate file
    else
      copy file
  for file in _all_files.style
    if /\.styl$/.test file
      translate file
    else
      copy file
  for file in _all_files.static
    copy file
  for file in _all_files.templates
    render file

task 'watch', "Restart cake watch-files on changes to cake file", ->
  cake = null
  restart = ->
    if cake?
      cake.kill()
    cake = spawn _cmds.cake, ['build', 'watch-files'],
            stdio: ['ignore', process.stdout, process.stderr]
  restart()
  watch __dirname, (file) ->
    file = path.relative __dirname, file
    if file is 'Cakefile'
      restart()

task 'watch-files', "Rebuild files on changes", ->
  watch __dirname, (file) ->
    file = path.relative __dirname, file
    if file in _all_files.scripts
      if /\.coffee$/.test file
        compile file
      else if /\.pegjs$/.test file
        generate file
      else
        copy file
    if file in _all_files.style
      if /\.styl$/.test file
        translate file
      else
        copy file
    if file in _all_files.templates
      render file
    if file in _all_files.static
      copy file

task 'server', "Launch development server", ->
  app.use(serveStatic(path.join(__dirname, 'bin'))).listen _port

task 'develop', "Build, watch and launch development server", ->
  invoke 'watch'
  invoke 'server'

task 'docs',  "Generate source code documentation", ->
  exec "Generating Documentation",
       _cmds.docco, '-c', 'docco.css', _all_files.scripts...

task 'clean', "Clean-up generated files", ->
  failed = false
  log = ""
  try
    # Delete everything from bin/, except dot-files (ie. .git/)
    binfolder = path.join __dirname, 'bin'
    for name in fs.readdirSync(binfolder)
      if name[0] is '.'
        continue
      file = path.join binfolder, name
      if fs.statSync(file).isDirectory()
        rmdir file
      else
        fs.unlinkSync file
  catch e
    failed = true
    log = e.toString() + "\n"
  print_msg "Removed generated files", not failed, log




#### Compilation of files

compile = (file) ->
  dst = path.dirname path.join __dirname, 'bin', file
  mkdirp dst
  exec "Compiling   #{file}",
        _cmds.coffee, '-c', '-o', dst, file

generate = (file) ->
  dst = path.dirname path.join __dirname, 'bin', file
  mkdirp dst
  target = path.join dst, path.basename(file).replace /\.pegjs$/, '.js'
  variable = "(typeof module === 'undefined' ? this : module.exports)"
  variable += "['#{path.basename file, '.pegjs'}']"
  exec "Generating  #{file}",
        _cmds.pegjs, '--track-line-and-column', '--cache', '-e', variable, file, target

translate = (file) ->
  dst = path.dirname path.join __dirname, 'bin', file
  mkdirp dst
  exec "Translating #{file}",
       _cmds.stylus, '-o', dst, file

render = (file) ->
  dst = path.dirname path.join __dirname, 'bin', file
  mkdirp dst
  obj = JSON.stringify(template_arguments(file))
  exec "Rendering   #{file}",
       _cmds.jade, '--out', dst, '--pretty', '--path', file, '--obj', obj, file

copy = (file) ->
  dst = path.dirname path.join __dirname, 'bin', file
  mkdirp dst
  target = path.join dst, path.basename(file)
  failed = false
  log = ""
  try
    data = fs.readFileSync file
    fs.writeFileSync target, data
  catch e
    failed = true
    log = e.toString() + "\n"
  print_msg "Copying     #{file}", not failed, log

#### Auxiliary Functions

# Terminal colors
reset     = "\u001b[0m"
red       = (s) -> "\u001b[31m" + s + reset
bold      = (s) -> "\u001b[1m" + s + reset
underline = (s) -> "\u001b[4m" + s + reset
highlight = (s) -> "\u001b[47m" + s + reset

# Execute cmd with args, writing msg as title in terminal
exec = (msg, cmd, args...) ->
  log = ""
  proc = spawn cmd, args
  proc.stdout.on 'data', (data) -> log += data
  proc.stderr.on 'data', (data) -> log += data
  proc.on 'exit', (status) ->
    print_msg(msg, status is 0, log)

# Print a nice message of what happend, success/failure and log
print_msg = (msg, success, log) ->
  result = ""
  result_length = msg.length
  if success
    result = "[Success]"
    result_length += result.length
  else
    result = "[Failed]"
    result_length += result.length
    result = red result
  length = Math.max(Math.abs(80 - result_length), 0)
  padding = (" " for i in [0...length]).join("")
  print msg + padding + result + '\n'
  if log != ""
    print log

# Recursively delete a folder
rmdir = (folder) ->
  for name in fs.readdirSync(folder)
    file = path.join folder, name
    if fs.statSync(file).isDirectory()
      rmdir file
    else
      fs.unlinkSync file
  fs.rmdirSync folder

# Recursively create folder
mkdirp = (folder, mode) ->
  folder = path.resolve folder
  try
    fs.mkdirSync folder, mode
  catch e
    if e.code is 'ENOENT'
      mkdirp path.dirname(folder), mode
      fs.mkdirSync folder, mode
