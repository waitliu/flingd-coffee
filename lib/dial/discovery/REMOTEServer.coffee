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

util                = require "util"
os                  = require "os"
child_process       = require "child_process"

{ Log }             = rekuire "log/Log"
{ Platform }        = rekuire "platform/Platform"
RemoteDiscover      = rekuire "remote/RemoteDiscover"


class REMOTEServer

    constructor: (@networkChecker, @port) ->

    startServer: (name) ->
        Log.d "RemoteDiscover : #{name}"
        options =
            serverPort : 5001
            serverName : "gateway.remote.infthink.com"
            dialPort : @port
            deviceId : name
            deviceName : name
            skey : "skey"
            randomCode : "1234"
        
        if @advertisement && @advertisement.status
            Log.d "reset RemoteDiscover ..."
            @advertisement.set options
        else
            Log.d "create RemoteDiscover ..."
            @advertisement = RemoteDiscover.createServer options
            @advertisement.start()

    resetServer: (name) ->
        @startServer name

    stopServer: ->
        Log.d "stop RemoteDiscover ..."
        if @advertisement
            Log.d "real stop RemoteDiscover ..."
            @advertisement.stop()

    start: ->
        Log.d "Starting RemoteDiscover ..."

        Platform.getInstance().on "device_name_changed", (name) =>
            Log.i "RemoteDiscover: deviceNameChanged: #{name}"
            @resetServer name

        Platform.getInstance().on "network_changed", (changed) =>
            Log.i "RemoteDiscover: network_changed: #{changed}"
            if "ap" == changed or "station" == changed
                deviceName = Platform.getInstance().getDeviceName()
                if deviceName
                    @stopServer()
                    @resetServer deviceName
            else
                Log.i "RemoteDiscover: unknow network_changed"

module.exports.REMOTEServer = REMOTEServer
