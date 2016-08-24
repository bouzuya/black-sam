fs = require 'fs-extra'
path = require 'path'
commander = require 'commander-b'
moment = require 'moment'

getBaseNamePath = (dir, date) ->
  [y, m, _] = date.split '-'
  path.join dir, y, m, date

getCommand = ->
  program = commander 'bbn'
  program.version require('../package.json').version
  program
  .command 'new', 'create a new post'
  .option '-d, --date <date>'
  .option '-w, --weekend'
  .action (options = {}) ->
    config = getConfig()
    options.directory = config.directory || '/home/bouzuya/blog.bouzuya.net'

    ts = if options.date then options.date + 'T23:59:59+09:00' else null
    date = moment.apply null, if ts? then [ts, 'YYYY-MM-DDThh:mm:ssZ'] else []
    baseNamePath = getBaseNamePath options.directory, date.format('YYYY-MM-DD')
    file = baseNamePath + '-diary.md'

    if fs.existsSync file
      console.error "the post #{file} already exists"
      return 1
    else
      data = getMarkdownTemplate date, options
      fs.outputFileSync file, data, encoding: 'utf8'
      console.log "create a new post #{file}"
      return 0
  program

getConfig = ->
  configFile = path.join process.env.HOME, '.bbn.json'
  if fs.existsSync configFile then require(configFile) else {}

getJsonTemplate = (m, _options) ->
  JSON.stringify
    pubdate: m.format()
    title: ''
    tags: ['']
    minutes: 0

getMarkdownTemplate = (m, options) ->
  if options.weekend
    getMarkdownTemplateForWeekend(m, options)
  else
    getMarkdownTemplateForWeekday(m, options)

getMarkdownTemplateForWeekday = (m, options) ->
  """
    ---
    layout: post
    pubdate: "#{m.format()}"
    title: ''
    tags: ['']
    minutes:
    pagetype: posts
    ---


  """

getMarkdownTemplateForWeekend = (m, options) ->
  posts = [1..7]
  .map (i) ->
    moment(m).subtract(i, 'days').format('YYYY-MM-DD')
  .map (date) ->
    date: date
    title: getTitle options.directory, date
    url: "http://blog.bouzuya.net/#{date.replace(/-/g, '/')}/"
  """
    ---
    layout: post
    pubdate: "#{m.format()}"
    title: ''
    tags: ['']
    minutes:
    pagetype: posts
    ---

    # 今週のふりかえり

    #{posts.map((i) -> "- [#{i.date} #{i.title}][#{i.date}]").join('\n')}
  """

getTitle = (dir, date) ->
  data = fs.readFileSync getPath(dir, date), encoding: 'utf8'
  title = data.match(/^title: '?(.*)$/m)[1]
  if title[title.length - 1] is '\'' then title.slice(0, -1) else title

module.exports = ->
  command = getCommand()
  command.execute()
