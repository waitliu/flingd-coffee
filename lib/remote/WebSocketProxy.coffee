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

events          = require "events"
os              = require "os"
WebSocket       = require "ws"

{ Log }         = rekuire "log/Log"

class WebSocketProxy extends events.EventEmitter

    constructor: (locale,remote)->
        events.EventEmitter.call(this)
        @remoteWs = new WebSocket remote
        
        @remoteWs.on "open", () =>
            @rstatus = true
            Log.d "websocket open: #{remote}" 
        @remoteWs.on "message", (data,flags) =>
            if @lstatus
                @localeWs.send data
            Log.d "sender data: #{data}"
        @remoteWs.on "close", () =>
            @rstatus = false
            if @lstatus
                @lstatus = false
                @localeWs.close()
            Log.d "websocket colse: #{remote}"
        
        @localeWs = new WebSocket locale
        @localeWs.on "open", () =>
            @lstatus = true
            Log.d "websocket open: #{locale}"
        @localeWs.on "message", (data,flags) =>
            if @rstatus
                @remoteWs.send data
            Log.d "recver data: #{data}"
        @localeWs.on "close", () =>
            @lstatus = false
            if @rstatus
                @rstatus = false
                @remoteWs.close()
            Log.d "websocket colse: #{locale}"

    stop: ->
        if @lstatus
            @lstatus = false
            @localeWs.close()
        if @rstatus
            @rstatus = false
            @remoteWs.close()

module.exports.WebSocketProxy = WebSocketProxy
