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

class LightboxService extends taiga.Service
    open: (lightbox) ->
        lightbox.css('display', 'flex')

        setTimeout ( ->
            lightbox.addClass('open')
        ), 70

        $(document)
            .on 'keydown.lightbox', (e) =>
                code = if e.keyCode then e.keyCode else e.which

                if code == 27
                    @close(lightbox)


    close: (lightbox) ->
        $(document).off('.lightbox')
        lightbox
            .one "transitionend", () ->
                lightbox.css('display', 'none')
            .removeClass('open')

module.service("lightboxService", LightboxService)

LightboxDirective = (lightboxService) ->
    link = ($scope, $el, $attrs) ->
        $el.on "click", ".close", (event) ->
            event.preventDefault()

            lightboxService.close($el)

    return {
        restrict: "C",
        link: link
    }

module.directive("lightbox", ["lightboxService", LightboxDirective])

#############################################################################
## Block Lightbox Directive
#############################################################################

BlockLightboxDirective = (lightboxService) ->
    link = ($scope, $el, $attrs, $model) ->
        title = $attrs.title
        $el.find("h2.title").text(title)
        $scope.$on "block", ->
            lightboxService.open($el)

        $scope.$on "unblock", ->
            $model.$modelValue.is_blocked = false
            $model.$modelValue.blocked_note_html = ""

        $scope.$on "$destroy", ->
            $el.off()

        $el.on "click", ".button-green", (event) ->
            event.preventDefault()
            target = angular.element(event.currentTarget)

            $scope.$apply ->
                $model.$modelValue.is_blocked = true
                $model.$modelValue.blocked_note = $el.find(".reason").val()

            lightboxService.close($el)

    return {
        templateUrl: "/partials/views/modules/lightbox_block.html"
        link:link,
        require:"ngModel"
    }

module.directive("tgLbBlock", ["lightboxService", BlockLightboxDirective])


#############################################################################
## Create/Edit Userstory Lightbox Directive
#############################################################################

CreateEditUserstoryDirective = ($repo, $model, $rs, $rootScope, lightboxService) ->
    link = ($scope, $el, attrs) ->
        isNew = true

        $scope.$on "usform:new", (ctx, projectId, status, statusList) ->
            $scope.usStatusList = statusList

            $scope.us = {
                project: projectId
                status: status
                is_archived: false
            }

            isNew = true
            # Update texts for creation
            $el.find(".button-green span").html("Create") #TODO: i18n
            $el.find(".title").html("New user story  ") #TODO: i18n

            $el.find(".blocked-note").hide()
            $el.find("label.blocked").removeClass("selected")
            $el.find("label.team-requirement").removeClass("selected")
            $el.find("label.client-requirement").removeClass("selected")

            lightboxService.open($el)

        $scope.$on "usform:edit", (ctx, us) ->
            $scope.us = us
            isNew = false
            # Update texts for edition
            $el.find(".button-green span").html("Save") #TODO: i18n
            $el.find(".title").html("Edit user story  ") #TODO: i18n

            # Update requirement info (team, client or blocked)
            if us.is_blocked
                $el.find(".blocked-note").show()
                $el.find("label.blocked").addClass("selected")
            else
                $el.find(".blocked-note").hide()
                $el.find("label.blocked").removeClass("selected")

            if us.team_requirement
                $el.find("label.team-requirement").addClass("selected")
            else
                $el.find("label.team-requirement").removeClass("selected")
            if us.client_requirement
                $el.find("label.client-requirement").addClass("selected")
            else
                $el.find("label.client-requirement").removeClass("selected")

            lightboxService.open($el)

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
                lightboxService.close($el)
                $rootScope.$broadcast(broadcastEvent, data)

            promise.then null, (data) ->
                form.setErrors(data)
                if data._error_message
                    $confirm.notify("error", data._error_message)

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
    "lightboxService",
    CreateEditUserstoryDirective
])


#############################################################################
## Creare Bulk Userstories Lightbox Directive
#############################################################################

CreateBulkUserstoriesDirective = ($repo, $rs, $rootscope, lightboxService) ->
    link = ($scope, $el, attrs) ->
        $scope.$on "usform:bulk", (ctx, projectId, status) ->
            $scope.new = {
                projectId: projectId
                statusId: status
                bulk: ""
            }
            lightboxService.open($el)

        $el.on "click", ".button-green", (event) ->
            event.preventDefault()

            form = $el.find("form").checksley({
                onlyOneErrorElement: true
            })
            if not form.validate()
                return

            promise = $rs.userstories.bulkCreate($scope.new.projectId, $scope.new.statusId, $scope.new.bulk)
            promise.then (result) ->
                $rootscope.$broadcast("usform:bulk:success", result)
                lightboxService.close($el)

            promise.then null, (data) ->
                form.setErrors(data)
                if data._error_message
                    $confirm.notify("error", data._error_message)

        $scope.$on "$destroy", ->
            $el.off()

    return {link: link}

module.directive("tgLbCreateBulkUserstories", [
    "$tgRepo",
    "$tgResources",
    "$rootScope",
    "lightboxService",
    CreateBulkUserstoriesDirective
])


#############################################################################
## AssignedTo Lightbox Directive
#############################################################################

usersTemplate = _.template("""
<% if (selected) { %>
<div class="watcher-single active">
    <div class="watcher-avatar">
        <a href="" title="Assigned to" class="avatar">
            <img src="<%= selected.photo %>"/>
        </a>
    </div>
    <a href="" title="<%- selected.full_name_display %>" class="watcher-name">
        <%-selected.full_name_display %>
    </a>
    <a href="" title="Remove assigned" class="icon icon-delete remove-assigned-to"></a>
</div>
<% } %>

<% _.each(users, function(user) { %>
<div class="watcher-single" data-user-id="<%- user.id %>">
    <div class="watcher-avatar">
        <a href="#" title="Assigned to" class="avatar">
            <img src="<%= user.photo %>" />
        </a>
    </div>
    <a href="" title="<%- user.full_name_display %>" class="watcher-name">
        <%- user.full_name_display %>
    </a>
</div>
<% }) %>

<% if (showMore) { %>
<div ng-show="filteringUsers" class="more-watchers">
    <span>...too many users, keep filtering</span>
</div>
<% } %>
""")

AssignedToLightboxDirective = (lightboxService) ->
    link = ($scope, $el, $attrs) ->
        selectedUser = null
        selectedItem = null

        filterUsers = (text, user) ->
            username = user.full_name_display.toUpperCase()
            text = text.toUpperCase()
            return _.contains(username, text)

        render = (selected, text) ->
            $el.find("input").focus()

            users = _.clone($scope.users, true)
            users = _.reject(users, {"id": selected.id}) if selected?
            users = _.filter(users, _.partial(filterUsers, text)) if text?

            ctx = {
                selected: selected
                users: _.first(users, 5)
                showMore: users.length > 5
            }

            html = usersTemplate(ctx)
            $el.find("div.watchers").html(html)

        $scope.$on "assigned-to:add", (ctx, item) ->
            selectedItem = item
            assignedToId = item.assigned_to
            selectedUser = $scope.usersById[assignedToId]

            render(selectedUser)
            lightboxService.open($el)

        $scope.$watch "usersSearch", (searchingText) ->
            render(selectedUser, searchingText) if searchingText?

        $el.on "click", ".watcher-single", (event) ->
            event.preventDefault()
            target = angular.element(event.currentTarget)

            lightboxService.close($el)

            $scope.$apply ->
                $scope.$broadcast("assigned-to:added", target.data("user-id"), selectedItem)
                $scope.usersSearch = null

        $el.on "click", ".remove-assigned-to", (event) ->
            event.preventDefault()
            event.stopPropagation()

            lightboxService.close($el)

            $scope.$apply ->
                $scope.usersSearch = null
                $scope.$broadcast("assigned-to:added", null, selectedItem)

        $el.on "click", ".close", (event) ->
            event.preventDefault()
            lightboxService.close($el)
            $scope.$apply ->
                $scope.usersSearch = null

        $scope.$on "$destroy", ->
            $el.off()

    return {
        templateUrl: "/partials/views/modules/lightbox-assigned-to.html"
        link:link
    }


module.directive("tgLbAssignedto", ["lightboxService", AssignedToLightboxDirective])


#############################################################################
## Watchers Lightbox directive
#############################################################################

WatchersLightboxDirective = ($repo, lightboxService) ->
    link = ($scope, $el, $attrs) ->
        selectedItem = null

        # Get prefiltered users by text
        # and without now watched users.
        getFilteredUsers = (text="") ->
            _filterUsers = (text, user) ->
                if _.find(selectedItem.watchers, (x) -> x == user.id)
                    return false

                username = user.full_name_display.toUpperCase()
                text = text.toUpperCase()
                return _.contains(username, text)

            users = _.clone($scope.users, true)
            users = _.filter(users, _.partial(_filterUsers, text))
            return users

        # Render the specific list of users.
        render = (users) ->
            $el.find("input").focus()
            ctx = {
                selected: false
                users: _.first(users, 5)
                showMore: users.length > 5
            }

            html = usersTemplate(ctx)
            $el.find("div.watchers").html(html)

        $scope.$on "watcher:add", (ctx, item) ->
            selectedItem = item

            users = getFilteredUsers()
            render(users)

            lightboxService.open($el)

        $scope.$watch "usersSearch", (searchingText) ->
            if not searchingText?
                return

            users = getFilteredUsers(searchingText)
            render(users)

        $el.on "click", ".watcher-single", (event) ->
            lightboxService.close($el)

            event.preventDefault()
            target = angular.element(event.currentTarget)

            $scope.$apply ->
                $scope.usersSearch = null
                $scope.$broadcast("watcher:added", target.data("user-id"))

        $el.on "click", ".close", (event) ->
            event.preventDefault()
            lightboxService.close($el)
            $scope.$apply ->
                $scope.usersSearch = null

        $scope.$on "$destroy", ->
            $el.off()

    return {
        templateUrl: "/partials/views/modules/lightbox_users.html"
        link:link
    }

module.directive("tgLbWatchers", ["$tgRepo", "lightboxService", WatchersLightboxDirective])
