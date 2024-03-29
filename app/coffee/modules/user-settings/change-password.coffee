###
# Copyright (C) 2014 Andrey Antukh <niwi@niwi.be>
# Copyright (C) 2014 Jesús Espino Garcia <jespinog@gmail.com>
# Copyright (C) 2014 David Barragán Merino <bameda@dbarragan.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# File: modules/user-settings/main.coffee
###

taiga = @.taiga

mixOf = @.taiga.mixOf

module = angular.module("taigaUserSettings")


#############################################################################
## User ChangePassword Controller
#############################################################################

class UserChangePasswordController extends mixOf(taiga.Controller, taiga.PageMixin)
      @.$inject = [
          "$scope",
          "$rootScope",
          "$tgRepo",
          "$tgConfirm",
          "$tgResources",
          "$routeParams",
          "$q",
          "$location",
          "$tgAuth"
      ]

      constructor: (@scope, @rootscope, @repo, @confirm, @rs, @params, @q, @location, @auth) ->
          @scope.sectionName = "Change Password" #i18n
          @scope.project = {}
          @scope.user = @auth.getUser()

          promise = @.loadInitialData()
          promise.then null, ->
              console.log "FAIL" #TODO

      loadProject: ->
          return @rs.projects.get(@scope.projectId).then (project) =>
              @scope.project = project
              @scope.$emit('project:loaded', project)
              return project

      loadInitialData: ->
          promise = @repo.resolve({pslug: @params.pslug}).then (data) =>
              @scope.projectId = data.project
              return data

          return promise.then(=> @.loadProject())

      save: ->
          if @scope.newPassword1 != @scope.newPassword2
              @confirm.notify('error', "The passwords dosn't match")
              return

          promise = @rs.userSettings.changePassword(@scope.currentPassword, @scope.newPassword1)
          promise.then =>
              @confirm.notify('success')
          promise.then null, (response) =>
              @confirm.notify('error', response.data._error_message)


module.controller("UserChangePasswordController", UserChangePasswordController)


#############################################################################
## User ChangePassword Directive
#############################################################################

UserChangePasswordDirective = () ->
    link = ($scope, $el, $attrs) ->
        $scope.$on "$destroy", ->
            $el.off()

    return {link:link}

module.directive("tgUserChangePassword", UserChangePasswordDirective)
