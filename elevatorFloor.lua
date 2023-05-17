IS_TOP = false or fs.exists('isTop')
IS_BOTTOM = false or fs.exists('isBottom')
REDSTONE_CONTACT_FACE = 'BACK'
MODEM_FACE = 'TOP'
PROTOCOL_FILTER = 'ELEVATOR'
SETUP_PROTOCOL_FILTER = 'ELEVATOR_SETUP'
RESET_PROTOCOL_FILTER = 'ELEVATOR_RESET'
REDSTONE_CALL_FACE = 'RIGHT'
 
print(string.format('isTop %s, isBottom %s', IS_TOP, IS_BOTTOM))

COMPUTER_ID = os.getComputerID()
HOST_NAME = 'BRAIN'


local state = 'setup' -- or loop
local floor = nil


-- setup
local function setup()
    CONTROLLER_ID = rednet.lookup(SETUP_PROTOCOL_FILTER, HOST_NAME)
    if not CONTROLLER_ID then
        print('Controller not found. Aborting...')
        return
    end

    local function contactWatcher()
        while true do
            local isContacting = redstone.getInput(REDSTONE_CONTACT_FACE)
            if isContacting then
                print('contacting')
                local messageToSend = {
                    computerId = COMPUTER_ID,
                    isBottom = IS_BOTTOM,
                    isTop = IS_TOP
                }
                rednet.send(CONTROLLER_ID, textutils.serialiseJSON(messageToSend), SETUP_PROTOCOL_FILTER)
            end
            sleep(0.05)
        end
    end

    local function rednetListener()
        print('waiting for message')
        local senderId, message = rednet.receive(SETUP_PROTOCOL_FILTER)
        message = textutils.unserialiseJSON(message)
        floor = message.setFloor
        print('we are floor')
        print(floor)
    end

    parallel.waitForAny(rednetListener, contactWatcher)
    state = 'loop'
end

-- loop
local function loop()
    while true do
        if state == 'setup' then
            setup()
        else
            local isContacting = redstone.getInput(REDSTONE_CONTACT_FACE)
            local isRequested = redstone.getInput(REDSTONE_CALL_FACE)
            if isContacting then
                local messageToSend = {
                    floor = floor,
                    requesting = isRequested,
                    elevatorIsAtFloor = true
                }
                rednet.send(CONTROLLER_ID, textutils.serialiseJSON(messageToSend), PROTOCOL_FILTER)
            end
            if isRequested then
                local messageToSend = {
                    floor = floor,
                    requesting = true,
                    elevatorIsAtFloor = isContacting
                }
                rednet.send(CONTROLLER_ID, textutils.serialiseJSON(messageToSend), PROTOCOL_FILTER)
            end
            sleep(0.05)
        end
    end
end

local function resetListener()
    while true do
        rednet.receive(RESET_PROTOCOL_FILTER)
        state = 'setup'
    end
end

rednet.open(MODEM_FACE)
rednet.broadcast('reset', RESET_PROTOCOL_FILTER)

parallel.waitForAny(loop, resetListener)