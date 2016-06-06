
backbone = require 'backbone'
_ = require 'underscore'
$ = require 'jquery'

module.exports = backbone.View.extend
  tagName: 'nav',

  initialize: (options) ->
    @paginationOptions = options.pagination
    @paginationId = options.id

  bindPagination: ->
    $pagination = $(@paginationId)
    $pagination.unbind()
    $pagination.pagination(@paginationOptions)

  render: ->
    @$el.append $('<ul class="pagination">')
    @$el.append $('</ul>')
    @$el

