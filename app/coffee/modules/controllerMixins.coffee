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
# File: modules/controllerMixins.coffee
###

taiga = @.taiga

groupBy = @.taiga.groupBy
joinStr = @.taiga.joinStr
trim = @.taiga.trim
toString = @.taiga.toString


#############################################################################
## Page Mixin
#############################################################################

class PageMixin
    loadUsersAndRoles: ->
        promise = @q.all([
            @rs.projects.usersList(@scope.projectId),
            @rs.projects.rolesList(@scope.projectId)
        ])

        return promise.then (results) =>
            [users, roles] = results

            @scope.users = _.sortBy(users, "full_name_display")
            @scope.usersById = groupBy(@scope.users, (e) -> e.id)

            @scope.roles = _.sortBy(roles, "order")
            availableRoles = _(@scope.project.memberships).map("role").uniq().value()
            @scope.computableRoles = _(roles).filter("computable")
                                             .filter((x) -> _.contains(availableRoles, x.id))
                                             .value()

            return results

taiga.PageMixin = PageMixin


#############################################################################
## Filters Mixin
#############################################################################
# This mixin requires @location ($tgLocation) and @scope

class FiltersMixin
    selectFilter: (name, value, load=false) ->
        params = @location.search()
        if params[name] != undefined and name != "page"
            existing = _.map(taiga.toString(params[name]).split(","), (x) -> trim(x))
            existing.push(taiga.toString(value))
            existing = _.compact(existing)
            value = joinStr(",", _.uniq(existing))

        location = if load then @location else @location.noreload(@scope)
        location.search(name, value)

    replaceFilter: (name, value, load=false) ->
        location = if load then @location else @location.noreload(@scope)
        location.search(name, value)

    unselectFilter: (name, value, load=false) ->
        params = @location.search()

        if params[name] is undefined
            return

        if value is undefined or value is null
            delete params[name]

        parsedValues = _.map(taiga.toString(params[name]).split(","), (x) -> trim(x))
        newValues = _.reject(parsedValues, (x) -> x == taiga.toString(value))
        newValues = _.compact(newValues)

        if _.isEmpty(newValues)
            value = null
        else
            value = joinStr(",", _.uniq(newValues))

        location = if load then @location else @location.noreload(@scope)
        location.search(name, value)

taiga.FiltersMixin = FiltersMixin


#############################################################################
## Attachments Mixin
#############################################################################
# This mixin requires @rs ($tgResources), @scope and @log ($tgLog)
# The mixin required @..attachmentsUrlName (p.e. 'issues/attachments',see resources.coffee)

class AttachmentsMixin
    loadAttachments: (objectId) ->
        if not @.attachmentsUrlName
            return @log.error "AttachmentsMixin: @.attachmentsUrlName is required"

        @scope.attachmentsCount = 0
        @scope.deprecatedAttachmentsCount = 0

        return @rs.attachments.list(@.attachmentsUrlName, objectId).then (attachments) =>
            @scope.attachments = _.sortBy(attachments, "order")
            @.updateAttachmentsCounters()
            return attachments

    updateAttachmentsCounters: ->
        @scope.attachmentsCount = @scope.attachments.length
        @scope.deprecatedAttachmentsCount = _.filter(@scope.attachments, is_deprecated: true).length

    onCreateAttachment: (attachment) ->
        @scope.attachments[@scope.attachments.length] = attachment
        @.updateAttachmentsCounters()

    onEditAttachment: (attachment) ->
        @.updateAttachmentsCounters()

    onDeleteAttachment: (attachment) ->
        index = @scope.attachments.indexOf(attachment)
        @scope.attachments.splice(index, 1)
        @.updateAttachmentsCounters()

taiga.AttachmentsMixin = AttachmentsMixin
