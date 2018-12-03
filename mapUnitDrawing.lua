--[[ This module handles drawing Units on the Map.
--]]

MapUnitDrawing={}
function MapUnitDrawing:new(graphicsContext)
  self.graphicsContext = graphicsContext
  return self
end
function MapUnitDrawing:load(unitJson)
  -- Load the Unit and its images.
  return self
end
function MapUnitDrawing:drawOnTile(column, row)
  -- TODO Draw self on the map
end
