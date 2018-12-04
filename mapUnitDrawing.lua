--[[ This module handles drawing Units on the Map.
--]]

MapUnitDrawing={}
function MapUnitDrawing:new(graphicsContext)
  self.graphicsContext = graphicsContext
  self.x = nil
  self.y = nil
  return self
end
function MapUnitDrawing:load(unitJson)
  -- Load the Unit and its images.
  return self
end
function MapUnitDrawing:update(dt)
end
function MapUnitDrawing:drawOnTile(column, row)
  -- Draw self on the map
  if column ~= nil then
    love.graphics.setColor(0.3,0.1,0.1)
    local unitX, unitY = self.graphicsContext:getTileCoordinate(column, row)
    love.graphics.rectangle( "fill", unitX + 8, unitY + 14, 48, 48 )
  end
end
