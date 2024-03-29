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
# File: modules/admin/project-profile.coffee
###

taiga = @.taiga

mixOf = @.taiga.mixOf
trim = @.taiga.trim
toString = @.taiga.toString
joinStr = @.taiga.joinStr
groupBy = @.taiga.groupBy
bindOnce = @.taiga.bindOnce

module = angular.module("taigaAdmin")

#############################################################################
## Project Profile Controller
#############################################################################

class ProjectProfileController extends mixOf(taiga.Controller, taiga.PageMixin)
    @.$inject = [
        "$scope",
        "$rootScope",
        "$tgRepo",
        "$tgConfirm",
        "$tgResources",
        "$routeParams",
        "$q",
        "$location",
        "$appTitle"
    ]

    constructor: (@scope, @rootscope, @repo, @confirm, @rs, @params, @q, @location, @appTitle) ->
        @scope.project = {}

        promise = @.loadInitialData()

        promise.then () =>
            @appTitle.set("Project profile - " + @scope.sectionName + " - " + @scope.project.name)

        promise.then null, ->
            console.log "FAIL" #TODO

    loadProject: ->
        return @rs.projects.get(@scope.projectId).then (project) =>
            @scope.project = project
            @scope.$emit('project:loaded', project)
            @scope.pointsList = _.sortBy(project.points, "order")
            @scope.usStatusList = _.sortBy(project.us_statuses, "order")
            @scope.taskStatusList = _.sortBy(project.task_statuses, "order")
            @scope.prioritiesList = _.sortBy(project.priorities, "order")
            @scope.severitiesList = _.sortBy(project.severities, "order")
            @scope.issueTypesList = _.sortBy(project.issue_types, "order")
            @scope.issueStatusList = _.sortBy(project.issue_statuses, "order")
            return project

    loadInitialData: ->
        promise = @repo.resolve({pslug: @params.pslug}).then (data) =>
            @scope.projectId = data.project
            return data

        return promise.then(=> @.loadProject())

    openDeleteLightbox: ->
        @rootscope.$broadcast("deletelightbox:new", @scope.project)


module.controller("ProjectProfileController", ProjectProfileController)

#############################################################################
## Project Profile Directive
#############################################################################

ProjectProfileDirective = ($rootscope, $log, $repo, $confirm, $location) ->
    link = ($scope, $el, $attrs) ->
        form = $el.find("form").checksley({"onlyOneErrorElement": true})
        submit = =>
            return if not form.validate()

            promise = $repo.save($scope.project)
            promise.then ->
                $confirm.notify("success")
                $location.path("/project/#{$scope.project.slug}/admin/project-profile/details")
                $scope.$emit("project:loaded", $scope.project)

            promise.then null, (data) ->
                form.setErrors(data)
                if data._error_message
                    $confirm.notify("error", data._error_message)

        $el.on "submit", "form", (event) ->
            event.preventDefault()
            submit()

        $el.on "click", "form a.button-green", (event) ->
            event.preventDefault()
            submit()

    return {link:link}

#############################################################################
## Project Features Directive
#############################################################################

ProjectFeaturesDirective = ($rootscope, $log, $repo, $confirm) ->
    link = ($scope, $el, $attrs) ->
        form = $el.find("form").checksley()
        submit = =>
            return if not form.validate()

            promise = $repo.save($scope.project)
            promise.then ->
                $confirm.notify("success")
                $scope.$emit("project:loaded", $scope.project)

            promise.then null, (data) ->
                $confirm.notify("error", data._error_message)

        $el.on "submit", "form", (event) ->
            event.preventDefault()
            submit()

        $el.on "click", "form a.button-green", (event) ->
            event.preventDefault()
            submit()

        $scope.$watch "isVideoconferenceActivated", (isVideoconferenceActivated) ->
            if isVideoconferenceActivated
                $el.find(".videoconference-attributes").show()
            else
                $el.find(".videoconference-attributes").hide()
                $scope.project.videoconferences = null
                $scope.project.videoconferences_salt = ""

        $scope.$watch "project", (project) ->
            if project.videoconferences?
                $scope.isVideoconferenceActivated = true
            else
                $scope.isVideoconferenceActivated = false

    return {link:link}

module.directive("tgProjectProfile", ["$rootScope", "$log", "$tgRepo", "$tgConfirm", "$location", ProjectProfileDirective])
module.directive("tgProjectFeatures", ["$rootScope", "$log", "$tgRepo", "$tgConfirm", ProjectFeaturesDirective])
