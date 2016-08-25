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
    dataFile = getDataFile options.directory, date.format('YYYY-MM-DD')
    metaFile = getMetaFile options.directory, date.format('YYYY-MM-DD')

    if fs.existsSync dataFile
      console.error "the post #{dataFile} already exists"
      return 1
    else
      meta = getMetaTemplate date, options
      data = getDataTemplate date, options
      writeMeta metaFile, meta
      writeData options.directory, date.format('YYYY-MM-DD'), data
      console.log [
        'create a new post'
        dataFile
        metaFile
      ].join('\n')
      return 0
  program

getConfig = ->
  configFile = path.join process.env.HOME, '.bbn.json'
  if fs.existsSync configFile then require(configFile) else {}

getDataFile = (dir, date) ->
  getBaseNamePath(dir, date) + '.md'

getDataTemplate = (m, options) ->
  if options.weekend
    getDataTemplateForWeekend(m, options)
  else
    getDataTemplateForWeekday(m, options)

getDataTemplateForWeekday = (m, options) ->
  ''

getDataTemplateForWeekend = (m, options) ->
  posts = [1..7]
  .map (i) ->
    moment(m).subtract(i, 'days').format('YYYY-MM-DD')
  .map (date) ->
    date: date
    title: getTitle options.directory, date
    url: "http://blog.bouzuya.net/#{date.replace(/-/g, '/')}/"
  """
    # 今週のふりかえり

    #{posts.map((i) -> "- [#{i.date} #{i.title}][#{i.date}]").join('\n')}
  """

getMetaFile = (dir, date) ->
  getBaseNamePath(dir, date) + '.json'

getMetaTemplate = (m, _options) ->
  pubdate: m.format()
  title: ''
  tags: ['']
  minutes: 0

getTitle = (dir, date) ->
  readMeta(getMetaFile(dir, date)).title

readMeta = (file) ->
  data = fs.readFileSync file, encoding: 'utf8'
  JSON.parse(data)

writeData = (dir, date, data) ->
  file = getBaseNamePath(dir, date) + '.md'
  fs.outputFileSync file, data, encoding: 'utf8'

writeMeta = (file, meta) ->
  data = JSON.stringify meta, null, 2
  fs.outputFileSync file, data, encoding: 'utf8'

module.exports = ->
  command = getCommand()
  command.execute()
