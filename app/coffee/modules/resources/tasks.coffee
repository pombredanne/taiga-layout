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
# File: modules/resources/tasks.coffee
###


taiga = @.taiga

generateHash = taiga.generateHash

resourceProvider = ($repo, $http, $urls, $storage) ->
    service = {}
    hashSuffix = "tasks-queryparams"

    service.get = (projectId, taskId) ->
        params = service.getQueryParams(projectId)
        params.project = projectId
        return $repo.queryOne("tasks", taskId, params)

    service.list = (projectId, sprintId=null, userStoryId=null) ->
        params = {project: projectId}
        params.milestone = sprintId if sprintId
        params.user_story = userStoryId if userStoryId
        service.storeQueryParams(projectId, params)
        return $repo.queryMany("tasks", params)

    service.bulkCreate = (projectId, sprintId, usId, data) ->
        url = $urls.resolve("bulk-create-tasks")
        params = {project_id: projectId, sprint_id: sprintId, us_id: usId, bulk_tasks: data}
        return $http.post(url, params).then (result) ->
            return result.data

    service.history = (taskId) ->
        return $repo.queryOneRaw("history/task", taskId)

    service.listValues = (projectId, type) ->
        params = {"project": projectId}
        return $repo.queryMany(type, params)

    service.storeQueryParams = (projectId, params) ->
        ns = "#{projectId}:#{hashSuffix}"
        hash = generateHash([projectId, ns])
        $storage.set(hash, params)

    service.getQueryParams = (projectId) ->
        ns = "#{projectId}:#{hashSuffix}"
        hash = generateHash([projectId, ns])
        return $storage.get(hash) or {}

    return (instance) ->
        instance.tasks = service


module = angular.module("taigaResources")
module.factory("$tgTasksResourcesProvider", ["$tgRepo", "$tgHttp", "$tgUrls", "$tgStorage", resourceProvider])
