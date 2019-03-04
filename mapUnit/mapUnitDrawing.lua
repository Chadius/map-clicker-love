--[[ This module handles drawing and moving Units on the Map.
--]]
local StateMachine = require "stateMachine/stateMachine"

local MapUnitDrawing={}
MapUnitDrawing.__index = MapUnitDrawing

local function unit_not_drawn(self, owner, message, payload)
  --[[ Unit has been created but not drawn yet.
  ]]

  if message != "clicked on" then
    return false, "unknown message: " .. message
  end

  --[[message = "clicked on"
  payload is a table:
    destination_x: world x coordinates
    destination_y: world y coordinates
    finished_callback: optional callback function
  ]]

  -- Confirm payload is correct
  local destination_x = payload.destination_x
  local destination_y = payload.destination_y

  if clicked_x == nil or clicked_y == nil then
    return false, "payload does not have destination coordinates: " .. destination_x .. ", " .. destination_y
  end

  -- Move the unit to the given position instantly
  owner.x = destination_x
  owner.y = destination_y

  -- Fire the callback since we finished moving immediately.
  if payload.callback then
    payload.callback()
  end

  -- Change state to "waiting"
  self:changeState("waiting")

  return true, "Moved to destination"
end

local function unit_waiting(self, owner, message, payload)
  --[[
  WAITING
  "Clicked on"

  Payload has the course

  - Change to Moving
  - Clear >>>current point<<< to 0
  - Set next >>>X&Y destination<<
  ]]

  -- Stop if the message isn't recognized
  if message != "clicked on" then
    return false, "unknown message: " .. message
  end

  -- Payload should have a course
  local course = payload.course

  -- If there is no course, stop
  if course == nil
    return true, "No course found, not moving"
  end
  owner.movementCourse = course

  -- Payload has a next way point (the tile location)
  owner.movementCourseIndex = 1
  local column = course[owner.movementCourseIndex]["column"]
  local row = course[owner.movementCourseIndex]["row"]

  if column == nil or row == nil then
    -- If Payload doesn't have a next way point
    return true, "No course found"
  end

  --- Set the timer to now
  owner.waitTimer = os.clock()

  --- Get the coordinates of the next tile
  local worldX, worldY = self.graphicsContext:getTileCoordinate(column, row)
  owner.mapDestination.x = worldX
  owner.mapDestination.y = worldY
  self:changeState("moving")
  return true, "Course set, now moving"
end

local function unit_moving(self, owner, message, payload)
  --[[MOVING
  "Current Pos"
  Payload has X&Y&dt
  - If X&Y is at waypoint,
  - Set next >>>X&Y destination<<
  - Count >>>Timer<<<
  - If timer expires, clear timer
  -- If at end of course, state = TURN COMPLETE
  -- Else, Increment next destination
  ]]

  if message != "current position" then
    return false, "unknown message: " .. message
  end

  -- Payload has the unit's world position
  local unitX = payload.position.x
  local unitY = payload.position.y

  if unitX == nil or unitY == nil then
    return false, "position should not be nil"
  end

  if owner.waitTimer ~= nil and os.timer() - owner.waitTimer < 1 then
    return true, "paused and waiting"
  end

  -- move towards the next destination
  local dt = payload.dt
  -- Move at 100 pixels per second to the destination
  -- new = 100 * dt + old
  if owner.x < owner.mapDestination.x then
    owner.x = (100 * dt) + owner.x
  elseif owner.x > owner.mapDestination.x then
    owner.x = (-100 * dt) + owner.x
  end

  if owner.y < owner.mapDestination.y then
    owner.y = (100 * dt) + owner.y
  elseif owner.y > owner.mapDestination.y then
    owner.y = (-100 * dt) + owner.y
  end

  -- Decide if unit is close enough to the waypoint.
  -- if x is within 5 px of the x destination, set it to the destination
  xWithinRange = false
  if math.abs (owner.x - owner.mapDestination.x) <= 5.0 then
    owner.x = owner.mapDestination.x
    xWithinRange = true
  end

  -- if y is within 5 px of the y destination, set it to the destination
  yWithinRange = false
  if math.abs (owner.y - owner.mapDestination.y) <= 5.0 then
    owner.y = owner.mapDestination.y
    yWithinRange = true
  end

  -- If X&Y is at waypoint,
  if xWithinRange and yWithinRange then
    -- Set next >>>X&Y destination<<
    owner.movementCourseIndex = owner.movementCourseIndex + 1
    local column = course[owner.movementCourseIndex]["column"]
    local row = course[owner.movementCourseIndex]["row"]

    if column == nil or row == nil then
      --- Set the timer to now
      owner.waitTimer = os.clock()

      --- If at end of course, state = TURN COMPLETE
      if owner.finishedMovingCallback then
        owner.finishedMovingCallback()
      end

      self:changeState("turn complete")
      return true, "finished moving"
    end

    --- Get the coordinates of the next tile
    local worldX, worldY = self.graphicsContext:getTileCoordinate(column, row)
    owner.mapDestination.x = worldX
    owner.mapDestination.y = worldY
    return true, "setting next way point"
  end

  return true, "moving toward next point"
end

local function unit_turn_complete(self, owner, message, payload)
  --[[ Handles the "turn complete" state
  TURN COMPLETE
  Count timerWhen timer expires, clear timer
  State = WAITING
  ]]

  local new_message = ""

  return true, new_message
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

  newDrawing.movementCourse = nil
  newDrawing.movementCourseIndex = 0
  newDrawing.mapDestination = {x=nil, y=nil}
  newDrawing.waitTimer = nil

  newDrawing.destination = {x=nil, y=nil}
  newDrawing.finishedMovingCallback = nil

  -- TODO: Make the state machine
  --newDrawing.stateMachine

  return newDrawing
end
function MapUnitDrawing:load(unitJson)
  -- Load the Unit and its images.
  return self
end
function MapUnitDrawing:update(dt)
  --[[
  TODO
  Update reads
  State & Draws at postion
  Sends "Current Pos" message
  ]]


  -- If destination is nil, return
  if self.destination.x == nil or self.destination.y == nil then
    return
  end

  -- If x & y are nil
  if self.x == nil or self.y == nil then
    --- x & y = destination
    self.x = self.destination.x
    self.y = self.destination.y
  else
    -- Move at 100 pixels per second to the destination
    -- new = 100 * dt + old
    if self.x < self.destination.x then
      self.x = (100 * dt) + self.x
    elseif self.x > self.destination.x then
      self.x = (-100 * dt) + self.x
    end

    if self.y < self.destination.y then
      self.y = (100 * dt) + self.y
    elseif self.y > self.destination.y then
      self.y = (-100 * dt) + self.y
    end
  end

  -- if x is within 5 px of the x destination, set it to the destination
  xWithinRange = false
  if math.abs (self.x - self.destination.x) <= 5.0 then
    self.x = self.destination.x
    xWithinRange = true
  end
  -- if y is within 5 px of the y destination, set it to the destination
  yWithinRange = false
  if math.abs (self.y - self.destination.y) <= 5.0 then
    self.y = self.destination.y
    yWithinRange = true
  end
  -- if x & y found the destination, set the destination to nil and set the callback
  if xWithinRange and yWithinRange then
    self.destination.x = nil
    self.destination.y = nil
    if self.finishedMovingCallback then
      self.finishedMovingCallback()
    end
  end
end
function MapUnitDrawing:draw()
  if self.x == nil or self.y == nil then
    return
  end

  love.graphics.setColor(0.3,0.1,0.1)
  love.graphics.rectangle( "fill", self.x + 8, self.y + 14, 48, 48 )
end
function MapUnitDrawing:moveToTile(column, row, callback)
  -- TODO Trigger the statemachine instead

  -- MapUnit wants to move to the given tile.

  -- if the column and row are nil, we're done
  if column == nil or row == nil then
    return
  end

  -- convert the column and row into the new destination
  local unitX, unitY = self.graphicsContext:getTileCoordinate(column, row)
  self.finishedMovingCallback = callback

  -- Tell the state machine to click on the location
  self.state_machine:step(self, "clicked on", {destination_x = unitX, destination_y = unitY})
end

return MapUnitDrawing
