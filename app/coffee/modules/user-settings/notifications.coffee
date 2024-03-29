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
# File: modules/user-settings/notifications.coffee
###

taiga = @.taiga
mixOf = @.taiga.mixOf
bindOnce = @.taiga.bindOnce

module = angular.module("taigaUserSettings")


#############################################################################
## User settings Controller
#############################################################################

class UserNotificationsController extends mixOf(taiga.Controller, taiga.PageMixin)
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
          @scope.sectionName = "Email Notifications" #i18n
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

      loadNotifyPolicies: ->
          return @rs.notifyPolicies.list().then (notifyPolicies) =>
              @scope.notifyPolicies = notifyPolicies
              return notifyPolicies

      loadInitialData: ->
          promise = @repo.resolve({pslug: @params.pslug}).then (data) =>
              @scope.projectId = data.project
              return data

          return promise.then(=> @.loadProject())
                        .then(=> @.loadNotifyPolicies())


module.controller("UserNotificationsController", UserNotificationsController)


#############################################################################
## User Notifications Directive
#############################################################################

UserNotificationsDirective = () ->
    link = ($scope, $el, $attrs) ->
        $scope.$on "$destroy", ->
            $el.off()

    return {link:link}

module.directive("tgUserNotifications", UserNotificationsDirective)


#############################################################################
## User Notifications List Directive
#############################################################################

UserNotificationsListDirective = ($repo, $confirm) ->
    template = _.template("""
        <% _.each(notifyPolicies, function (notifyPolicy, index) { %>
        <div class="policy-table-row" data-index="<%- index %>">
          <div class="policy-table-project"><span><%- notifyPolicy.project_name %></span></div>
          <div class="policy-table-all">
            <fieldset>
              <input type="radio"
                     name="policy-<%- notifyPolicy.id %>" id="policy-all-<%- notifyPolicy.id %>"
                     value="2" <% if (notifyPolicy.notify_level == 2) { %>checked="checked"<% } %>/>
              <label for="policy-all-<%- notifyPolicy.id %>">All</label>
            </fieldset>
          </div>
          <div class="policy-table-involved">
            <fieldset>
              <input type="radio"
                     name="policy-<%- notifyPolicy.id %>" id="policy-involved-<%- notifyPolicy.id %>"
                     value="1" <% if (notifyPolicy.notify_level == 1) { %>checked="checked"<% } %> />
              <label for="policy-involved-<%- notifyPolicy.id %>">Involved</label>
            </fieldset>
          </div>
          <div class="policy-table-none">
            <fieldset>
              <input type="radio"
                     name="policy-<%- notifyPolicy.id %>" id="policy-none-<%- notifyPolicy.id %>"
                     value="3" <% if (notifyPolicy.notify_level == 3) { %>checked="checked"<% } %> />
              <label for="policy-none-<%- notifyPolicy.id %>">None</label>
            </fieldset>
          </div>
        </div>
        <% }) %>
    """)

    link = ($scope, $el, $attrs) ->
        render = ->
            $el.off()
            $el.html(template({notifyPolicies: $scope.notifyPolicies}))

            $el.on "change", "input[type=radio]", (event) ->
                target = angular.element(event.currentTarget)
                policyIndex = target.parents(".policy-table-row").data('index')
                policy = $scope.notifyPolicies[policyIndex]

                prev_level = policy.notify_level
                policy.notify_level = parseInt(target.val(), 10)

                $repo.save(policy).then ->
                $repo.save(policy).then null, ->
                    $confirm.notify("error")
                    target.parents(".policy-table-row").find("input[value=#{prev_level}]").prop("checked", true)

        $scope.$on "$destroy", ->
            $el.off()

        bindOnce($scope, $attrs.ngModel, render)

    return {link:link}

module.directive("tgUserNotificationsList", ["$tgRepo", "$tgConfirm", UserNotificationsListDirective])
