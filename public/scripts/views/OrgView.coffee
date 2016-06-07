
backbone = require 'backbone'
_ = require 'underscore'
$ = require 'jquery'
bootbox = require 'bootbox'
OrgUserView = require './OrgUserView'
spinner = require './Spinner'
require 'select2'
require '../../../bower_components/jquery-bootstrap-pagination/vendor/assets/javascripts/jquery-bootstrap-pagination.js'

module.exports = backbone.View.extend
  initialize : (options) ->
    @host = options.host
    @orgGuid = options.orgGuid
    @orgName = options.orgName
    @userName = options.userName

    @currentPage = 1
    @limitPerPage = 50
    @allData = null

  render : ->
    @$el.empty()

    table = $("<table class=\"table table-bordered table-striped\"></table>")
    row = $("<tr></tr>")
    row.append $("<th >User Id</th>")
    row.append $("<th>Org Developer</th>")
    row.append $("<th>Org Manager</th>")
    row.append  $("<th>Org Auditor</th>")
    table.append(row)
    @$el.append(table)

    spinner.blockUI()

    if (!@allData)
      auditorRequest = $.ajax
        url: "https://#{@host}/cf-users/cf-api/organizations/#{@orgGuid}/auditors"
      managerRequest = $.ajax
        url: "https://#{@host}/cf-users/cf-api/organizations/#{@orgGuid}/managers"
      orgUserRequest = $.ajax
        url: "https://#{@host}/cf-users/cf-api/organizations/#{@orgGuid}/users"
      userRequest = $.ajax
        url:"https://#{@host}/cf-users/cf-api/users"

    success = (auditorData,managerData,orgUserData,userData) =>
        if (!@allData)
          resources = userData[0].resources.filter (u) ->
            u.entity.username
          resources.sort (a,b) ->
            a.entity.username.toLowerCase().localeCompare(b.entity.username.toLowerCase())

          arguments[3][0].resources = resources
          @allData = arguments

        userData = @sliceUserData()

        auditors = {}
        for auditor in auditorData[0].resources
          auditors[auditor.entity.username] = true
        managers = {}
        for manager in managerData[0].resources
          managers[ manager.entity.username] = true
        @isOrgManager = ((manager for manager in managerData[0].resources when manager.entity.username is @userName ).length > 0)
        orgUsers = {}
        for orgUser in orgUserData[0].resources
          orgUsers[orgUser.entity.username] = true
        userViews = (new OrgUserView({host: @host,orgGuid : @orgGuid, userName: user.entity.username, userGuid : user.metadata.guid, isManager : managers[user.entity.username], isAuditor : auditors[user.entity.username], isOrgUser : orgUsers[user.entity.username], userIsOrgManager: @isOrgManager}) for user in userData[0].resources)

        for userView in userViews
          userView.render()
          table.append(userView.$el)

        pagination = $('<div id="userPagination"></div>')
        @$el.append(pagination)
        console.log(userData)
        pagination.pagination
          total_pages: userData[0].total_pages
          current_page: @currentPage
          next: '&raquo;'
          prev: '&laquo;'
          display_max: 4
          callback: (event, page) =>
            console.log(event, page)
            @currentPage = parseInt(page)
            pagination.unbind()
            @render()

        spinner.unblockUI()

    failure = (XMLHttpRequest, textStatus, errorThrown) =>
       spinner.unblockUI()
       @handleError(XMLHttpRequest, textStatus, errorThrown)

    if (@allData)
      success.apply(@, @allData)
    else
      $.when(auditorRequest,managerRequest,orgUserRequest,userRequest).then success, failure

  sliceUserData: ->
    if (!@allData)
      console.log('nodata')
      [
        total_pages: 1
        resources: []
      ]
    else
      userData = @allData[3][0]
      offset = (@currentPage - 1) * @limitPerPage
      console.log(offset, @currentPage, @limitPerPage)
      console.log(userData)
      [
        total_pages: parseInt(userData.resources.length / @limitPerPage) + 1
        resources: userData.resources.slice(offset, offset + @limitPerPage)
      ]

  handleError : (XMLHttpRequest, textStatus, errorThrown)->
    if(XMLHttpRequest.status ==403)
       bootbox.alert(XMLHttpRequest.responseJSON.description)