default = require './template-weekday'
weekend = require './template-weekend'

templates = { default, weekend }

module.exports = (id) ->
  templates[id]
