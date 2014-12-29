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

events              = require "events"
os                  = require "os"

{ Log }             = rekuire "log/Log"
{ DataPack }        = rekuire "remote/DataPack"
{ WebSocketProxy }  = rekuire "remote/WebSocketProxy"

class RemoteServer extends events.EventEmitter
    @CMD_LOGIN = 1
    @CMD_PING = 2
    @CMD_REPORT = 1001
    @CMD_PROXY = 1002
    @CMD_WS_PROXY = 1003
    @CMD_PING = 2

    constructor: ->
        events.EventEmitter.call(this)
        @wsproxy = {}
        @on "ready", =>
            Log.d "remote server is ready !"

    getAddress: ->
        address = {} 
        ifaces = os.networkInterfaces()
        for k,v of ifaces
            if (k.toLowerCase().indexOf "lo") < 0
                ipadd = {}
                for i in v
                    if i.family == "IPv4"
                        ipadd.ipv4 = i.address
                    if i.family == "IPv6"
                        ipadd.ipv6 = i.address
                # castd node ipv6 not found
                if ipadd.ipv4 #&& ipadd.ipv6
                    address = ipadd
                    break
        return address

    set: (options) ->
        @deviceId = options.deviceId
        @deviceName = options.deviceName
        @skey = options.skey
        @serverPort = options.serverPort
        @serverName = options.serverName
        @dialPort = options.dialPort
        @randomCode = options.randomCode

    _start: ->
        if !@status 
            @address = @getAddress()
            if @address.ipv4
                Log.d "Starting connect remote #{@serverName}:#{@serverPort} ..."
                net = require "net"
                try
                    @socket = net.createConnection @serverPort,@serverName
                catch error
                    Log.e error

                @socket.on "error", (error) =>
                    Log.e error

                @socket.on "data", (data) =>
                    @onReceive data

                @socket.on "connect", =>
                    Log.d "remote server is connect"
                    @login()
                    @report()
                    @emit "ready"

                @socket.on "close", =>
                    Log.d "remote server is closed"
                    @running = false
                    @status = false

                @status = true
                @running = true

            else
                Log.d "connect remote server fail"
                if not @address.ipv4
                    Log.d "no ipv4, please check network"

    start: ->
        @_start()
        @startLoop = setInterval (=>
            @_start() ), 60000

        @pingLoop = setInterval (=>
            @ping() ), 5000

    stop: ->
        @socket.close()
        @status = false
        clearInterval @startLoop
        clearInterval @pingLoop
        Log.d "disconnect remote server"

    sendData: (command, messageId, data) ->
        try
            dataBuf = DataPack.encode command, messageId, data
            @socket.write dataBuf, "utf8", =>
                Log.i "send command: #{command} messageId:#{messageId} data: #{data}"
        catch error
            Log.d "error: #{error}"
            Log.d "command: #{command} messageId:#{messageId} data: #{data}"

    login: ->
        message = 
            "id":@deviceId
            "skey":@skey
        @sendData RemoteServer.CMD_LOGIN, -1, message

    ping: ->
        message = 
            "id":@deviceId
        @sendData RemoteServer.CMD_PING, -3, message

    report: ->
        message = 
            "code" : @randomCode            
            "id" : @deviceId
            "name" : @deviceName
        @sendData RemoteServer.CMD_REPORT, -2, message

    onReceive: (data) ->
        try
            message = DataPack.decode data
        catch error
            Log.d "error: #{error}"
            Log.d "data: #{data}"
        if message and message.command and message.command > 1
            Log.i "remote receive message: #{JSON.stringify(message)}".red
            switch message.command
                when RemoteServer.CMD_PROXY
                    @proxy_send message.messageId, message.data
                when RemoteServer.CMD_WS_PROXY
                    @proxy_ws message.messageId, message.data

    proxy_send: (messageId, req) ->
        request = require "request"
        if req.path and req.method
            url = "http://127.0.0.1:"+ @dialPort + req.path
            req.method = req.method.toUpperCase()
            headers = req.headers
            if !headers
                headers = {}
            body_data = req.body
            if !body_data
                body_data = ""
            option = 
                url: url
                method: req.method 
                headers:headers
                json: body_data
                
            request option, (error, response, body) => 
                if error 
                    Log.e "error!!! #{error}" 
                else
                    resp = {}
                    resp.body = body
                    resp.mimeType = response.headers['content-type'] ? "text/html"
                    if resp.mimeType == "application/json"
                        resp.body = JSON.stringify body
                    @sendData RemoteServer.CMD_PROXY, messageId, resp
                    Log.d "response:#{response}, mimeType:#{resp.mimeType},body:#{JSON.stringify(body)}"

    proxy_ws: (messageId, wsdata) ->
        Log.d "wsdata #{JSON.stringify(wsdata)}"
        switch wsdata.cmd
            when "start"
                local_host = "ws://"+@getAddress().ipv4+":9439"
                @wsproxy[wsdata.remote] = new WebSocketProxy local_host+wsdata.local, wsdata.remote
                @sendData RemoteServer.CMD_WS_PROXY, messageId, "start"
                Log.d "start proxy #{wsdata.local}"
            when "stop"
                if @wsproxy[wsdata.remote]
                    @wsproxy[wsdata.remote].stop()
                    delete @wsproxy[wsdata.remote]
                @sendData RemoteServer.CMD_WS_PROXY, messageId, "stop"
                Log.d "stop proxy #{wsdata.local}"

module.exports.RemoteServer = RemoteServer
