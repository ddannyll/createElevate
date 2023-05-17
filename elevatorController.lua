MODEM_FACE = 'TOP'
CLUTCH_FACE = 'LEFT'
GEAR_SHIFT_FACE = 'RIGHT'
GEAR_SHIFT_ON_IS_UP = true

local state = 'idle'
local currFloor = nil
local floors = {'G', '-1', '-2'}
-- state can be idle, up, down

-- MAIN FUNCTIONS --
local function listen ()
    rednet.open(MODEM_FACE)
    local received = rednet.receive()
    print(received)
end

local function setup()
    redstone.setOutput(GEAR_SHIFT_FACE, false)
    redstone.setOutput(CLUTCH_FACE, true)
    -- validate floor level
    -- go to top floor
    
end

local function loop()
    while true do
        if state == 'idle' then
            redstone.setOutput(CLUTCH_FACE, true)
        elseif state == 'up' then
            redstone.setOutput(GEAR_SHIFT_FACE, GEAR_SHIFT_ON_IS_UP)
            redstone.setOutput(CLUTCH_FACE, false)
        else
            redstone.setOutput(GEAR_SHIFT_FACE, not GEAR_SHIFT_ON_IS_UP)
            redstone.setOutput(CLUTCH_FACE, false)
        end
        sleep(0.05)
    end
end

local function debugInput()
    print('Available Debug Commands: idle, up, down')
    while true do
        local input = read()
        if input == 'idle' then
            state = 'idle'
        elseif input == 'up' then
            state = 'up'
        elseif input == 'down' then
            state = 'down'
        else
            print('unknown debug command')
        end
    end
end

setup()
parallel.waitForAll(listen, loop, debugInput)
-- HELPERS