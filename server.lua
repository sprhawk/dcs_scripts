local socket = require("socket")

local LOG_LEVEL = 1
local USE_LOG = true
local logFile = nil

local DogServer = nil
local ServerTry = nil

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
                            if DogServer then
                                DogServer:close()
                                DogServer = nil
                            end
                        end)
            ServerTry(DogServer:bind("*", 4444))
            ServerTry(DogServer:listen(5))
            ipaddr, port = DogServer:getsockname()
            log("DogSever listen on " .. ipaddr .. ":" .. tostring(port))
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

initLog()
startDogServer()
DogServer:settimeout(0.1)
clientcos = {}
serverco = coroutine.create(function()
    client,err = DogServer:accept()
    if client then
        clientcos[#clientcos] = coroutine.create(function()
            data,err,part = client:receive()
        end)
end)
local running = true
while running == true do
    coroutine.resume(co)
end
stopDogServer()
uninitLog()
