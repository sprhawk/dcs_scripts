local socket = require("socket")
print("connecting to server\n")
local client,msg = socket.connect("localhost", 4444)
print("connected(" .. tostring(msg) .. ")\n")

function send_command(client)
    print("waiting for input:\n")
    local data, errmsg
    local running = true
    repeat 
        text = io.stdin:read()
        if text == "exit" then
            running = false
        else    
            print("sending ...")
            i, errmsg = client:send(text .. "\r\n")
            if i then
                print( tostring(i) .. " sent\n" )
            else
                running = false
                print("errmsg: " .. errmsg)
            end
    
        end
    until running == false
end

function receive_data(client)
    local data, errmsg
    repeat
        data, errmsg = client:receive('*l')
        if data then
            print(tostring(data))
        else
            print("errmsg: " .. errmsg)
            break 
        end
    until not true
end

receive_data(client)

print("closing connection\n")
client:close()

