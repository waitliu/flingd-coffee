#
# Copyright (C) 2013-2014, The OpenFlint Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
#    limitations under the License.
#

{ RemoteServer }    = rekuire 'remote/RemoteServer'
{ DataPack }        = rekuire 'remote/DataPack'

createServer = createServer:(options) ->
    remoteServer = new RemoteServer
    remoteServer.set options
    return remoteServer

module.exports.createServer = createServer.createServer

module.exports.RemoteServer = RemoteServer
