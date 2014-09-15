--  Aircraft Instruments and panels communication script for iPanel for DCS 
--  Yang Hongbo [hongbo@yang.me]
--  2014/08/16
     
local lfs = require("lfs")

programPath = lfs.realpath(lfs.currentdir())
-- package.path = lfs.writedir().. "Scripts\\dog\\?.lua" .. ";" .. programPath .. "LuaSocket\\?.lua;" .. package.path  -- needed for debug command line mode

package.path = programPath .. "LuaSocket\\?.lua;" .. package.path  
-- package.cpath = ".\\bin\\lua-ocket.dll;" .. package.cpath

local socket = require("socket")
-- local copas = require("copas")

local LOG_LEVEL = 1
local USE_LOG = true
local logFile = nil

local DogServer = nil
local ServerTry = nil
local DogClient = nil

Coroutines = Coroutines or {}
CoroutineIndex = CoroutineIndex or 0

function initLog()
    if USE_LOG and nil == logFile then
        logFile = io.open(lfs.writedir() .. "Scripts\\dog.log", "w+")
    end
end

function uninitLog()
    if logFile then
        logFile:close()
    end
end

function log(text, level)
    if nil == level then
        level = LOG_LEVEL
    end
    if level > 0 then
        if logFile then
            logFile:write(text .. "\n")
        end
        print(text)
    end
end

function startDogServer()
    foo = socket.protect(function()
        if DogServer == nil then
            DogServer = socket.try(socket.tcp())
            ServerTry = socket.newtry(function() 
                            if DogClient then
                                DogClient:close()
                                DogClinet = nil
                            end
                            if DogServer then
                                DogServer:close()
                                DogServer = nil
                            end
                        end)
            ServerTry(DogServer:bind("*", 4444))
            ret, errmsg = ServerTry(DogServer:listen(2)) -- max 2 clients can be queued
            if not ret then
                log("Dogserver listen: " .. errmsg)
            end
            ipaddr, port = DogServer:getsockname()
            log("DogSever listen on " .. ipaddr .. ":" .. tostring(port))
            DogServer:settimeout(0)
        end
    end)
    foo()
end

function stopDogServer()
    if DogServer then
        DogServer:close()
        log("DogServer closed")
    end
end

local OldExportStart = LuaExportStart
LuaExportStart = function()
    initLog()
    if OldExportStart then
        OldExportStart()
    end
end

local OldExportStop = LuaExportStop
LuaExportStop = function()
    if DogClient then
        DogClient:close()
        DogClient = nil
    end
    stopDogServer()
    uninitLog()
    if OldExportStop then
        OldExportStop()
    end
end
  
local OldExportAfterNextFrame = LuaExportAfterNextFrame
LuaExportAfterNextFrame = function()
    if not DogServer then
        startDogServer()
    end
    if DogServer and not DogClient then
        DogClient,errmsg = DogServer:accept()
        if DogClient then
            local peername, port = DogClient:getpeername()
            log(peername .. ":" .. tostring(port) .. " connected\n")
        elseif errmsg == "timeout" then
        else
            log("accept: " .. errmsg)
        end
    end
    if DogClient then
        local value
        local results = {}
        value = LoGetModelTime()
        if value then
            table.insert(results, "mt=" .. value)
        end

        value = LoGetPilotName()
        if value then
            table.insert(results, "pn=\"" .. value .. "\"")
        end

        value = LoGetIndicatedAirSpeed()
        if value then
            table.insert(results, "ia=" .. value)
        end

        value = LoGetTrueAirSpeed()
        if value then
            table.insert(results, "ta=" .. value)
        end

        value = LoGetAltitudeAboveSeaLevel()
        if value then
            table.insert(results, "aas=" .. value)
        end

        value = LoGetAltitudeAboveGroundLevel()
        if value then
            table.insert(results, "aag=" .. value)
        end

        value = LoGetAngleOfAttack()
        if value then
            table.insert(results, "aoa=" .. value)
        end

        value = LoGetAccelerationUnits()
        -- table.insert(results, value)

        value = LoGetVerticalVelocity()
        if value then
            table.insert(results, "vv=" .. value)
        end

        value = LoGetMachNumber()
        if value then
            table.insert(results, "mn=" .. value)
        end

        value = LoGetADIPitchBankYaw()
        if value then
            table.insert(results, "ap=" .. value)
        end

        value = LoGetMagneticYaw()
        if value then
            table.insert(results, "my=" .. value)
        end

        value = LoGetGlideDeviation()
        if value then
            table.insert(results, "gd=" .. value)
        end

        value = LoGetSideDeviation()
        if value then
            table.insert(results, "sd=" .. value)
        end

        value = LoGetSlipBallPosition()
        if value then
            table.insert(results, "sb=" .. value)
        end

        value = LoGetBasicAtmospherePressure()
        if value then
            table.insert(results, "ba=" .. value)
        end

        value = LoGetControlPanel_HSI()
        if value then
            --[[
            for k,v in pairs(value) do
                if type(v) == "table" then
                    for l,w in pairs(v) do
                        table.insert(results, l .. "=" .. w)
                    end
                else
                    table.insert(results, k .. "=" .. v)
                end    
            end
            ]]
            local v
            v = value["ADF_raw"]
            if v then
                table.insert(results, "adf=" .. v)
            end
            v = value["RMI_raw"]
            if v then
                table.insert(results, "rmi=" .. v)
            end
            v = value["Heading_raw"]
            if v then
                table.insert(results, "hd=" .. v)
            end
            v = value["HeadingPointer_raw"]
            if v then
                table.insert(results, "hp=" .. v)
            end
            v = value["Course"]
            if v then
                table.insert(results, "co=" .. v)
            end
            v = value["BearingPointer"]
            if v then
                table.insert(results, "bp=" .. v)
            end
            v = value["CourseDeviation"]
            if v then
                table.insert(results, "cd=" .. v)
            end
        end

        value = LoGetEngineInfo()
        if value then
            v = value["RPM"]
            if v then
                if v["left"] then
                    table.insert(results, "rl=" .. v["left"])
                end
                if v["right"] then
                    table.insert(results, "rr=" .. v["right"])
                end
            end
            v = value["Temperature"]
            if v then
                if v["left"] then
                    table.insert(results, "tl=" .. v["left"])
                end
                if v["right"] then
                    table.insert(results, "tr=" .. v["right"])
                end
            end
            v = value["HydraulicPressure"]
            if v then
                if v["left"] then
                    table.insert(results, "hpl=" .. v["left"])
                end
                if v["right"] then
                    table.insert(results, "hpr=" .. v["right"])
                end
            end
            v = value["FuelConsumption"]
            if v then
                if v["left"] then
                    table.insert(results, "fcl=" .. v["left"])
                end
                if v["right"] then
                    table.insert(results, "fcr=" .. v["right"])
                end
            end
            v = value["fuel_internal"]
            if v then
                table.insert(results, "fi=" .. v)
            end
            v = value["fuel_external"]
            if v then
                table.insert(results, "fe=" .. v)
            end
            --[[
            for k,v in pairs(value) do
                if type(v) == "table" then
                    for l,w in pairs(v) do
                        table.insert(results, l .. "=" .. w)
                    end
                else
                    table.insert(results, k .. "=" .. v)
                end    
            end
            ]]
            --[[
            table.insert(results, "rl=" .. value[1][1])
            table.insert(results, "rr=" .. value[1][2])
            table.insert(results, "tl=" .. value[2][1])
            table.insert(results, "tr=" .. value[2][2])
            table.insert(results, "fcl=" .. value[3][1])
            table.insert(results, "fcr=" .. value[3][2])
            table.insert(results, "fi=" .. value[4])
            table.insert(results, "fe=" .. value[5])
            ]]
        end

        value = LoGetMechInfo()
        if value then
            for k,v in ipairs(value) do
                table.insert(results, k .. "=" .. v)
            end
            --[[
            table.insert(results, "g=" .. value[1][1] .. "," .. value[1][2])
            table.insert(results, "f=" .. value[1][1] .. "," .. value[1][2])
            table.insert(results, "spb=" .. value[1][1] .. "," .. value[1][2])
            table.insert(results, "wb=" .. value[1][1] .. "," .. value[1][2])
            ]]
        end

        s = table.concat(results, ";")
        index, errmsg = DogClient:send(s .. "\n")
        if errmsg == "closed" then
            local peername, port = DogClient:getpeername()
            log(peername .. ":" .. tostring(port) .. " disconnected\n")
            DogClient:close()
            DogClient = nil
        end
    end
    if OldExportAfterNextFrame then
        OldExportAfterNextFrame()
    end    
end

