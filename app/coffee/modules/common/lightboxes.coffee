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
# File: modules/lightboxes.coffee
###

module = angular.module("taigaCommon")

bindOnce = @.taiga.bindOnce

#############################################################################
## Block Directive
#############################################################################

BlockDirective = ->
    link = ($scope, $el, $attrs, $model) ->
        title = $attrs.title
        $el.find("h2.title").text(title)
        $scope.$on "block", ->
            $el.removeClass("hidden")

        $scope.$on "unblock", ->
            $model.$modelValue.is_blocked = false
            $model.$modelValue.blocked_note_html = ""

        $scope.$on "$destroy", ->
            $el.off()

        $el.on "click", ".close", (event) ->
            event.preventDefault()
            $el.addClass("hidden")

        $el.on "click", ".button-green", (event) ->
            event.preventDefault()
            target = angular.element(event.currentTarget)

            $scope.$apply ->
                $model.$modelValue.is_blocked = true
                $model.$modelValue.blocked_note = $el.find(".reason").val()

            $el.addClass("hidden")

    return {link:link, require:"ngModel"}

module.directive("tgLbBlock", BlockDirective)


#############################################################################
## Create/Edit Userstory Lightbox Directive
#############################################################################

CreateEditUserstoryDirective = ($repo, $model, $rs, $rootScope) ->
    link = ($scope, $el, attrs) ->
        isNew = true

        $scope.$on "usform:new", (ctx, statusId) ->
            $scope.us = {
                project: $scope.projectId
                is_archived: false
                status: statusId or $scope.project.default_us_status
            }
            isNew = true
            # Update texts for creation
            $el.find(".button-green span").html("Create") #TODO: i18n
            $el.find(".title").html("New user story  ") #TODO: i18n
            $el.removeClass("hidden")

        $scope.$on "usform:edit", (ctx, us) ->
            $scope.us = us
            isNew = false
            # Update texts for edition
            $el.find(".button-green span").html("Save") #TODO: i18n
            $el.find(".title").html("Edit user story  ") #TODO: i18n
            $el.removeClass("hidden")

            # Update requirement info (team, client or blocked)
            if us.is_blocked
                $el.find(".blocked-note").show()
                $el.find("label.blocked").addClass("selected")

            if us.team_requirement
                $el.find("label.team-requirement").addClass("selected")
            if us.client_requirement
                $el.find("label.client-requirement").addClass("selected")

        $scope.$on "$destroy", ->
            $el.off()

        # Dom Event Handlers

        $el.on "click", ".close", (event) ->
            event.preventDefault()
            $el.addClass("hidden")

        $el.on "click", ".button-green", (event) ->
            event.preventDefault()

            form = $el.find("form").checksley()
            if not form.validate()
                return

            if isNew
                promise = $repo.create("userstories", $scope.us)
                broadcastEvent = "usform:new:success"
            else
                promise = $repo.save($scope.us)
                broadcastEvent = "usform:edit:success"

            promise.then (data) ->
                $el.addClass("hidden")
                $rootScope.$broadcast(broadcastEvent, data)

        $el.on "click", "label.blocked", (event) ->
            event.preventDefault()
            target = angular.element(event.currentTarget)
            target.toggleClass("selected")
            $scope.us.is_blocked = not $scope.us.is_blocked
            $el.find(".blocked-note").toggle(400)

        $el.on "click", "label.team-requirement", (event) ->
            event.preventDefault()
            angular.element(event.currentTarget).toggleClass("selected")
            $scope.us.team_requirement = not $scope.us.team_requirement

        $el.on "click", "label.client-requirement", (event) ->
            event.preventDefault()
            angular.element(event.currentTarget).toggleClass("selected")
            $scope.us.client_requirement = not $scope.us.client_requirement

        $scope.$on "$destroy", ->
            $el.off()

    return {link: link}

module.directive("tgLbCreateEditUserstory", [
    "$tgRepo",
    "$tgModel",
    "$tgResources",
    "$rootScope",
    CreateEditUserstoryDirective
])


#############################################################################
## Creare Bulk Userstories Lightbox Directive
#############################################################################

CreateBulkUserstoriesDirective = ($repo, $rs, $rootscope) ->
    link = ($scope, $el, attrs) ->
        $scope.form = {data: ""}

        $scope.$on "usform:bulk", ->
            $el.removeClass("hidden")
            $scope.form = {data: ""}

        $el.on "click", ".close", (event) ->
            event.preventDefault()
            $el.addClass("hidden")

        $el.on "click", ".button-green", (event) ->
            event.preventDefault()

            form = $el.find("form").checksley()
            if not form.validate()
                return

            data = $scope.form.data
            projectId = $scope.projectId

            $rs.userstories.bulkCreate(projectId, data).then (result) ->
                $rootscope.$broadcast("usform:bulk:success", result)
                $el.addClass("hidden")

        $scope.$on "$destroy", ->
            $el.off()

    return {link: link}

module.directive("tgLbCreateBulkUserstories", [
    "$tgRepo",
    "$tgResources",
    "$rootScope",
    CreateBulkUserstoriesDirective
])


#############################################################################
## AssignedTo Lightbox Directive
#############################################################################

AssignedToLightboxDirective = ->
    template = _.template("""
    <% if (selected) { %>
    <div class="watcher-single active">
        <div class="watcher-avatar">
            <a href="" title="Assigned to" class="avatar">
                <img ng-src="selectedUser.photo"/>
            </a>
        </div>
        <a href="" title="<%- selected.full_name_display %>" class="watcher-name">
            <%-selected.full_name_display %>
        </a>
        <a href="" title="Remove assigned" class="icon icon-delete remove-assigned-to"></a>
    </div>
    <% } %>

    <% _.each(users, function(user) { %>
    <div class="watcher-single">
        <div class="watcher-avatar">
            <a href="#" title="Assigned to" class="avatar">
                <img src="<%= user.photo %>" />
            </a>
        </div>
        <a href="" title="<%- selected.full_name_display %>" class="watcher-name">
            <%-selected.full_name_display %>
        </a>
    </div>
    <% }) %>

    <% if (showMore) { %>
    <div ng-show="filteringUsers" class="more-watchers">
        <span>...too many users, keep filtering</span>
    </div>
    <% } %>
    """)


    link = ($scope, $el, $attrs) ->
        editingItem = null

        render = (users) ->

        bindOnce $scope, "usersBy", (v) ->


        updateScopeFilteringUsers = (searchingText) ->
            usersById = _.clone($scope.usersById, false)

            # Exclude selected user
            if $scope.selectedUser?
                delete usersById[$scope.selectedUser.id]

            # Filter text
            usersById = _.filter usersById,  (user) ->
                return _.contains(user.full_name_display.toUpperCase(), searchingText.toUpperCase())

            # Return max of 5 items
            users = _.map(usersById, (user) -> user)
            $scope.usersSearch = searchingText
            $scope.filteringUsers = users.length > 5
            $scope.filteredUsers = _.first(users, 5)

        $scope.$on "assigned-to:add", (ctx, item) ->
            editingItem = item
            assignedToId = editingItem?.assigned_to

            $scope.selectedUser = $scope.usersById[assignedToId] if assignedToId?
            updateScopeFilteringUsers("")

            $el.removeClass("hidden")
            $el.find("input").focus()

        $scope.$watch "usersSearch", (searchingText) ->
            updateScopeFilteringUsers(searchingText)

        $el.on "click", ".watcher-single", (event) ->
            event.preventDefault()
            target = angular.element(event.currentTarget)
            if editingItem?
                user = target.scope().user
                editingItem.assigned_to = user.id

            $el.addClass("hidden")
            $scope.$broadcast("assigned-to:added", editingItem)

        $el.on "click", ".remove-assigned-to", (event) ->
            event.preventDefault()
            event.stopPropagation()

            if editingItem?
                editingItem.assigned_to = null

            $el.addClass("hidden")
            $scope.$broadcast("assigned-to:added", editingItem)

        $el.on "click", ".close", (event) ->
            event.preventDefault()
            $el.addClass("hidden")

        $scope.$on "$destroy", ->
            $el.off()

    return {
        templateUrl: "/partials/views/modules/lightbox-assigned-to.html"
        link:link
    }


module.directive("tgLbAssignedto", AssignedToLightboxDirective)
