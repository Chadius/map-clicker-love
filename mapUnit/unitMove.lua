-- [[ This class handles a unit's movement. This includes:
--- Type of movement
--- Navigating on maps
--- Getting directions on maps
--- Movement distance
--- Movement cost
-- ]]

UnitMove={}
function UnitMove:new(...)
  self.map, self.location, self.moveDistance, self.moveType = ...
  return self
end
function UnitMove:ChartCourse(destination)
  -- Return a single path to the destination, assuming inifinite turns.
  -- Returns nil if the trip is impossible.
  return nil
end
function UnitMove:NextWaypoint(course)
  --[[ Following the course, return the next location within move distance.
  Returns nil if:
  - Unit is not on the path
  - Unit has completed the path and is on the end.
  - Unit does not have enough move to actually move.
  --]]
  return nil
end
function UnitMove:GetTilesWithinMovement()
  -- Returns a MapSearch object showing all of the tiles within movement range.
  return nil
end
