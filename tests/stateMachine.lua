local StateMachine = require "stateMachine/stateMachine"
local lunit = require "libraries/unitTesting/lunitx"

if _VERSION >= 'Lua 5.2' then
    _ENV = lunit.module('enhanced','seeall')
else
    module( "enhanced", package.seeall, lunit.testcase )
end

--[[
State Machines perform certain logic in the correct mode.
We'll build a class that manages controlling which logic is run and manages state changes.
]]

--[[ For testing, we'll create a Car. The Car has 4 states:
Ignition Off (Starting state)
Engine Idle
Driving
Parking

You can give it instructions.
Ignition Off:
  "Turn key in ignition" - Goes to Engine Idle
Engine Idle:
  "Shift to Drive" - Goes to Driving
  "Shift to Park" - Goes to Parking
Driving:
  "Drive"
  "Turn left"
  "Turn right"
  "Brake" - Goes to Engine Idle
Parking:
  "Shift to Drive" - Goes to Driving
  "Turn off engine" - Goes to Ignition Off
]]

local function ignition_off_state(self, owner, message, payload)
  --[[
  Ignition Off:
    "Turn the key" - Goes to Engine Idle
  ]]

  local new_message = ""

  if message == "turn the key" and payload.turn_key == true then
    self:changeState("engine_idle")
    new_message = "Turning the car on"
    owner.key_is_turned = true
  end

  return true, new_message
end

local function engine_idle_state(self, owner, message, payload)
  --[[
  Engine Idle:
    "Shift to Drive" - Goes to Driving
    "Shift to Park" - Goes to Parking
  ]]
end

local function driving_state(self, owner, message, payload)
  --[[
  Driving:
    "Drive"
    "Turn left"
    "Turn right"
    "Brake" - Goes to Engine Idle
  ]]
end

local function parking_state(self, owner, message, payload)
  --[[
  Parking:
    "Shift to Drive" - Goes to Driving
    "Turn off engine" - Goes to Ignition Off
  ]]
end

function test_make_machine()
  --[[Create a car with a state machine.
  The state machine starts in Ignition Off state.
  Turn the key and the car should be in Engine Idle state.
  ]]

  local car = {
    key_is_turned = false,
    state_machine = StateMachine:new({
      history=false,
      states={
        ignition_off=ignition_off_state,
        engine_idle=engine_idle_state,
        driving=driving_state,
        parking=parking_state
      },
      initial_state="ignition_off"
    })
  }

  -- Confirm the initial state is ignition off
  assert_equal("ignition_off", car.state_machine:getState())

  -- Tell the car to turn the key
  car.state_machine:step(car, "turn the key", {turn_key=true})

  -- Confirm the car is in the Engine Idle state.
  assert_equal("engine_idle", car.state_machine:getState())

  -- Assert the state machine manipulated the key.
  assert_true(car.key_is_turned)
end

function test_ignore_input_in_wrong_state()
  --[[Create a car with a state machine.
  Try to Drive the car.
  Car should be in Ignition Off state, and not moving.
  ]]

  local car = {
    key_is_turned = false,
    state_machine = StateMachine:new({
      history=false,
      states={
        ignition_off=ignition_off_state,
        engine_idle=engine_idle_state,
        driving=driving_state,
        parking=parking_state
      },
      initial_state="ignition_off"
    })
  }

  -- Tell the car to drive.
  car.state_machine:step(car, "drive", {hit_the_gas=true})

  -- Confirm the car is still in the ignition off state.
  assert_equal("ignition_off", car.state_machine:getState())
end

function test_manage_history()
  --[[Create a car with a state machine. Turn the history on.
  Turn the key and drive. Turn a few times.
  The car should have detected it moved.
  Throw in one invalid direction.
  The state machine's history should have all of the instructions, in order.
  The state machine's history should also have the invalid instruction.
  ]]
  local car = {
    key_is_turned = false,
    state_machine = StateMachine:new({
      history=true,
      states={
        ignition_off=ignition_off_state,
        engine_idle=engine_idle_state,
        driving=driving_state,
        parking=parking_state
      },
      initial_state="ignition_off"
    })
  }

  -- Tell the car to turn the key
  car.state_machine:step(car, "turn the key", {turn_key=true})

  -- Confirm the car is in the Engine Idle state.
  assert_equal("engine_idle", car.state_machine:getState())

  -- Drive.
  car.state_machine:step(car, "drive", {hit_the_gas=true})
  car.state_machine:step(car, "drive", {hit_the_gas=false})

  assert_equal(3, car.odometer)

  car.state_machine:step(car, "turn left")

  assert_equal("west", car.heading)

  car.state_machine:step(car, "turn right")

  assert_equal("north", car.heading)

  car.state_machine:step(car, "bogus", {bogus="yes, it's bogus"})

  -- Get the history.
  local car_history = car.state_machine:getHistory()

  
end

--[[Create a car with a state machine.
Modify the state machine so it counts the gear shifts when the state is changed.
Switch from Driving to Parking.
The car should have a tally of gear shifts.
]]

--[[Test against state change protection?
]]
