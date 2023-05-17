SCREEN_PROTOCOL_FILTER = 'ELEVATOR_SCREEN'
MODEM_FACE = 'FRONT'

rednet.open(MODEM_FACE)
local floors = {}
while true do
    print(string.format('Please enter a floor: %s', floors))
    local selected = tonumber(read())
    if floors[selected] then
        local messageToSend = {
            floor = selected,
            requesting = true
        }
        rednet.broadcast(textutils.serialiseJSON(messageToSend), SCREEN_PROTOCOL_FILTER)
    end
    sleep(0.05)
    rednet.send()
end