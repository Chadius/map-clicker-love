--[[ State required to track a Unit on a Map.
--]]

local MapUnit={}
MapUnit.__index = MapUnit

function MapUnit:new()
  --[[ Create a new MapUnit.
  --]]
  local newUnit = {}
  setmetatable(newUnit,MapUnit)
  newUnit.drawing=nil
  newUnit.mapCoordinates={column=nil,row=nil}
  newUnit.movement=nil
  return newUnit
end
function MapUnit:load()
end
function MapUnit:update(dt)
  self.drawing:update(dt)
end
function MapUnit:moveToTile(column, row)
  -- Indicate the unit should move to the given location on the map.
  self.mapCoordinates={column=column,row=row}

  -- Tell the graphics you want to animate the tile moving over to the destination.
  self.drawing:moveToTile(
    column,
    row,
    function ()
      self:finishedMoving()
    end
  )
end
function MapUnit:finishedMoving()
  -- Function to signal the unit finished moving to the destination.
  print("Callback: Finished moving.")
end
function MapUnit:draw()
  self.drawing:draw()
end

function MapUnit:chartCourse(destination)
  return self.movement:chartCourse(self, destination)
end
function MapUnit:nextWaypoint(course)
  return self.movement:nextWaypoint(self, course)
end
function MapUnit:getTilesWithinMovement(args)
  return self.movement:getTilesWithinMovement(self, args)
end
function MapUnit:getMapCoordinates()
  return {column=self.mapCoordinates.column, row=self.mapCoordinates.row}
end

return MapUnit
