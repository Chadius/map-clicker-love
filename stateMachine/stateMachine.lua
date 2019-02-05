--[[
State Machines perform certain logic in the correct mode.
We'll build a class that manages controlling which logic is run and manages state changes.
]]


local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine:new(args)
  --[[ Create a new state machine.
  Args: Pass in a table with these keys.
    states(table): keys have to be strings.
      values are functions. They should accept (statemachine, caller, message,
        payload) and return two strings.
    intiial_state(string): Must match one of the keys in states
    history (boolean, default false): You can optionally turn on a history of state change calls.
  --]]
  local newObj = {}
  setmetatable(newObj,StateMachine)
  -- Make sure states were passed
  if args.states == nil then
    error("StateMachine:new called without states")
  end

  -- Copy the states
  newObj.state_to_function = {}
  for key, func in args.states do
    newObj.state_to_function[key] = func
  end

  -- Set the initial state
  if args.initial_state == nil then
    error("StateMachine:new called without initial_state")
  end
  if states[args.initial_state] == nil then
    error("StateMachine:new initial_state " .. args.initial_state .. " is not in states")
  end

  newObj.initial_state = args.initial_state
  newObj.current_state = nil
  newObj:reset_state()

  -- TODO See if you should turn on the history.
  return newObj
end

--[[ Clear the history.
]]

function StateMachine:reset_state()
  --[[ Reset to initial state.
  Returns:
    True if successful
  ]]
  self.current_state = self.initial_state
end

function StateMachine:step(caller, message, payload)
  --[[Based on the given state, call one of the defined functions.
  Args:
    caller          : Object the state machine function will affect. Usually the object containing this object.
    message(string) : A description to send to the caller. Will be recorded in the history.
    payload(table, optional, default={})  : Data to send to the caller.
  Returns:
    An optional string.
  ]]

  -- Get the function to call, based on the given state.
  local func = self.state_to_function[self.current_state]

  -- TODO Protect against state changes.

  -- Call the function.
  func(self, caller, message, payload)

  -- TODO Stop protecting state changes.

  -- TODO If there were any pending states, apply them now.
end

function stateMachine:changeState(new_state)
  --[[Change to the given state.
  ]]
  
end

--[[ Toggle recording history.
]]

return StateMachine
