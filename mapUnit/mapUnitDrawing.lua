--[[ This module handles drawing Units on the Map.
--]]
local StateMachine = require "stateMachine/stateMachine"

local MapUnitDrawing={}
MapUnitDrawing.__index = MapUnitDrawing

local function ready_to_move_state(self, owner, message, payload)
  --In "ready_to_move" handler

  if message == "destination" and payload.world_x ~= nil and payload.world_y ~= nil then
    --[[ If it gets a destination
        Set destination to payload
        Change status to "moving"
    ]]
    owner.destination.x = payload.world_x
    owner.destination.y = payload.world_y
    owner.finishedMovingCallback = payload.callback
    self:changeState("moving")
    return true, "Moving towards destination"
  end

  return false, "message is unknown or payload is unknown. TODO more error messaging"
end

local function moving_state(self, owner, message, payload)
  --[[In "moving" handler
  ]]

  if payload.dt == nil then
    return false, "missing dt"
  end

  -- Find out how close you are to the destination.
  local xWithinRange = false
  local yWithinRange = false
  if owner.x == nil or owner.y == nil then
    -- If you don't have a location set, warp there instantly.
    xWithinRange = true
    yWithinRange = true
  else
    -- if x is within 5 px of the x destination, set it to the destination
    if math.abs (owner.x - owner.destination.x) <= 5.0 then
      xWithinRange = true
    end
    -- if y is within 5 px of the y destination, set it to the destination
    if math.abs (owner.y - owner.destination.y) <= 5.0 then
      yWithinRange = true
    end
  end

  -- If you're at the destination
  if xWithinRange and yWithinRange then
    -- Move directly to the destination
    owner.x = owner.destination.x
    owner.y = owner.destination.y

    -- Change status to "ready_to_move"
    self:changeState("ready_to_move")
    if owner.finishedMovingCallback then
      owner.finishedMovingCallback()
    end
    return true, "Moved to destination"
  else
    -- Move at 100 pixels per second to the destination
    -- new = 100 * dt + old
    local dt = payload.dt
    if owner.x < owner.destination.x then
      owner.x = (100 * dt) + owner.x
    elseif owner.x > owner.destination.x then
      owner.x = (-100 * dt) + owner.x
    end

    if owner.y < owner.destination.y then
      owner.y = (100 * dt) + owner.y
    elseif owner.y > owner.destination.y then
      owner.y = (-100 * dt) + owner.y
    end
  end
end

function MapUnitDrawing:new(graphicsContext)
  --[[ Create a new object.
  --]]
  local newDrawing = {}
  setmetatable(newDrawing,MapUnitDrawing)

  newDrawing.graphicsContext = graphicsContext
  -- Rename to world location
  newDrawing.x = nil
  newDrawing.y = nil

  newDrawing.destination = {x=nil, y=nil}
  newDrawing.finishedMovingCallback = nil
  newDrawing.state_machine = StateMachine:new({
    history=false,
    states={
      ready_to_move=ready_to_move_state,
      moving=moving_state,
    },
    initial_state="ready_to_move"
  })

  return newDrawing
end
function MapUnitDrawing:load(unitJson)
  -- Load the Unit and its images.
  return self
end
function MapUnitDrawing:update(dt)
  -- If state is "moving", call state machine with moving handler (with dt as payload)
  self.state_machine:step(self, "time elapsed", {dt=dt})
end
function MapUnitDrawing:draw()
  if self.x == nil or self.y == nil then
    return
  end

  love.graphics.setColor(0.3,0.1,0.1)
  love.graphics.rectangle( "fill", self.x + 8, self.y + 14, 48, 48 )
end
function MapUnitDrawing:moveToTile(column, row, callback)
  -- MapUnit wants to move to the given tile.

  -- if the column and row are nil, we're done
  if column == nil or row == nil then
    return
  end

  -- convert the column and row into world coordinates
  local worldX, worldY = self.graphicsContext:getTileCoordinate(column, row)

  -- Tell the state machine there's a new destination
  return self.state_machine:step(
    self,
    "destination",
    {
      world_x=worldX,
      world_y=worldY,
      callback=callback,
    }
  )
end

return MapUnitDrawing
