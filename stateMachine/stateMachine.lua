--[[
State Machines perform certain logic in the correct mode.
We'll build a class that manages controlling which logic is run and manages state changes.
]]


local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine:new(args)
  --[[ Create a new state machine.
  --]]
  local newObj = {}
  setmetatable(newObj,StateMachine)

  return newObj
end

--[[ Clear the history.
]]

--[[ Reset to initial state.
]]

--[[Based on the given state, call one of the defined functions.
]]

--[[Change to the given state.
]]

return StateMachine
