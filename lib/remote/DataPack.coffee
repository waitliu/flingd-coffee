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

class DataPack
    @encode: (command, messageId, msg) ->
        data = [] 
        msg = JSON.stringify msg
        dataLengthBuf = new Buffer 4
        dataLengthBuf.writeUInt32BE msg.length + 12, 0 
        commandBuf = new Buffer 4
        commandBuf.writeUInt32BE command, 0
        messageIdBuf = new Buffer 4
        messageIdBuf.writeInt32BE messageId, 0
        msgBuf = new Buffer msg
        dataBuf = Buffer.concat [dataLengthBuf, commandBuf, messageIdBuf, msgBuf]
        return dataBuf

    @check: (rawData) ->
        if rawData.length < 12
            return false
        dataLen = rawData.readUInt32BE 0
        if dataLen <= rawData.length
            return true
        else
            return false

    @decode: (rawData) ->
        result = {}
        dataLen = rawData.readUInt32BE 0
        command = rawData.readUInt32BE 4
        messageId = rawData.readUInt32BE 8
        data = rawData.toString "utf-8", 12, dataLen
        rawData = rawData.slice dataLen
        try
            data = JSON.parse data
        catch error
            result.error = error
            data = {}
        result.command = command
        result.messageId = messageId
        result.data = data
        result.rawData = rawData
        return result

module.exports.DataPack = DataPack
