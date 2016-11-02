fs = require 'fs-extra'
path = require 'path'
moment = require 'moment'

getBaseNamePath = (dir, date) ->
  [y, m, _] = date.split '-'
  path.join dir, y, m, date

getDataTemplateForWeekday = (_options) ->
  ''

# getDataTemplateForWeekend = (
#   options: { date: Moment, directory: string; }
# ): string
getDataTemplateForWeekend = ({ date: m, directory }) ->
  posts = [1..7]
  .map (i) ->
    moment(m).subtract(i, 'days').format('YYYY-MM-DD')
  .map (date) ->
    date: date
    title: getTitle directory, date
    url: "http://blog.bouzuya.net/#{date.replace(/-/g, '/')}/"
  """
    # 今週のふりかえり

    #{posts.map((i) -> "- [#{i.date} #{i.title}][#{i.date}]").join('\n')}
  """

getMetaFile = (dir, date) ->
  getBaseNamePath(dir, date) + '.json'

getMetaTemplate = ({ date }) ->
  pubdate: date.format()
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

getTitle = (dir, date) ->
  readMeta(getMetaFile(dir, date)).title

readMeta = (file) ->
  data = fs.readFileSync file, encoding: 'utf8'
  JSON.parse(data)

module.exports = (id) ->
  templates[id]
