fs = require 'fs-extra'
path = require 'path'
commander = require 'commander-b'
moment = require 'moment'

getBaseNamePath = (dir, date) ->
  [y, m, _] = date.split '-'
  path.join dir, y, m, date

getCommand = ->
  program = commander 'black-sam'
  program.version require('../package.json').version
  program
  .command 'new', 'create a new post'
  .option '-d, --date <date>'
  .option '-y, --yesterday'
  .option '-w, --weekend'
  .action (options = {}) ->
    config = getConfig()
    options.directory = config.directory
    # ts = 'yyyy-mm-ddThh:mm:ssZ' | null
    ts = if options.yesterday
      moment().subtract(1, 'd').format('YYYY-MM-DD') + 'T23:59:59+09:00'
    else if options.date
      options.date + 'T23:59:59+09:00'
    else
      null
    # date = moment
    date = moment.apply null, if ts? then [ts, 'YYYY-MM-DDThh:mm:ssZ'] else []
    dataFile = getDataFile options.directory, date.format('YYYY-MM-DD')
    metaFile = getMetaFile options.directory, date.format('YYYY-MM-DD')

    if fs.existsSync dataFile
      console.error "the post #{dataFile} already exists"
      return 1
    else
      { meta, data } = getTemplate date, options
      writeMeta metaFile, meta
      writeData dataFile, data
      console.log [
        'create a new post'
        dataFile
        metaFile
      ].join('\n')
      return 0
  program

getConfig = ->
  configFile = path.join process.env.HOME, '.bbn.json'
  config = if fs.existsSync(configFile)
    console.warn('DEPRECATED: Use `package.json` instead of `~/.bbn.json`.')
    require(configFile)
  else
    cwd = process.cwd()
    packageJson = path.join(cwd, 'package.json')
    if fs.existsSync(packageJson)
      pkg = JSON.parse(fs.readFileSync(packageJson))
      pkg['black-sam'] ? {}
    else
      {}
  config.directory = config.directory ? '/home/bouzuya/blog.bouzuya.net'
  config

getDataFile = (dir, date) ->
  getBaseNamePath(dir, date) + '.md'

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

templates =
  default:
    data: getDataTemplateForWeekday
    meta: getMetaTemplate
  weekend:
    data: getDataTemplateForWeekend
    meta: getMetaTemplate

getTemplate = (date, options) ->
  id = if options.weekend then 'weekend' else 'default'
  { data, meta } = templates[id]
  { data: data(date, options), meta: meta(date, options) }

getTitle = (dir, date) ->
  readMeta(getMetaFile(dir, date)).title

readMeta = (file) ->
  data = fs.readFileSync file, encoding: 'utf8'
  JSON.parse(data)

writeData = (file, data) ->
  fs.outputFileSync file, data, encoding: 'utf8'

writeMeta = (file, meta) ->
  data = JSON.stringify meta, null, 2
  fs.outputFileSync file, data, encoding: 'utf8'

module.exports = ->
  command = getCommand()
  command.execute()
