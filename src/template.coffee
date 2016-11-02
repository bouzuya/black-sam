weekday = require './template-weekday'
weekend = require './template-weekend'

templates = { default: weekday, weekday, weekend }

module.exports = (id) ->
  templates[id]
