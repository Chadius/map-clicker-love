--[[ This module handles drawing Units on the Map.
--]]

local MapUnitDrawing={}
MapUnitDrawing.__index = MapUnitDrawing

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

  return newDrawing
end
function MapUnitDrawing:load(unitJson)
  -- Load the Unit and its images.
  return self
end
function MapUnitDrawing:update(dt)
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
  -- MapUnit wants to move to the given tile.

  -- if the column and row are nil, we're done
  if column == nil or row == nil then
    return
  end

  -- convert the column and row into the new destination
  local unitX, unitY = self.graphicsContext:getTileCoordinate(column, row)
  self.destination.x = unitX
  self.destination.y = unitY
  self.finishedMovingCallback = callback
end

return MapUnitDrawing
