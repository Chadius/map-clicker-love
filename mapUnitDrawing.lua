--[[ This module handles drawing Units on the Map.
--]]

MapUnitDrawing={}
function MapUnitDrawing:new(graphicsContext)
  self.graphicsContext = graphicsContext
  -- Rename to world location
  self.x = nil
  self.y = nil

  self.destination = {x=nil, y=nil}
  return self
end
function MapUnitDrawing:load(unitJson)
  -- Load the Unit and its images.
  return self
end
function MapUnitDrawing:update(dt)
  -- If destination is nil, return

  -- If x & y are nil
  --- x & y = destination
  -- Move at 100 pixels per second to the destination
  -- new = 100 * dt + old
  -- if x is within 5 px of the x destination, set it to the destination
  -- if y is within 5 px of the y destination, set it to the destination
  -- if x & y found the destination, set the destination to nil and set the callback
end
function MapUnitDrawing:draw()
end
function MapUnitDrawing:moveToTile(column, row, callback)
  -- MapUnit wants to move to the given tile.
  -- TODO if the column and row aren't nil
  -- TODO convert the column and row into the new destination
end
function MapUnitDrawing:drawOnTile(column, row)
  -- Draw self on the map
  if column ~= nil then
    love.graphics.setColor(0.3,0.1,0.1)
    local unitX, unitY = self.graphicsContext:getTileCoordinate(column, row)
    love.graphics.rectangle( "fill", unitX + 8, unitY + 14, 48, 48 )
  end
end
