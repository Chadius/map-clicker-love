-- [[ This class handles a unit's movement. This includes:
--- Type of movement
--- Navigating on maps
--- Getting directions on maps
--- Movement distance
--- Movement cost
-- ]]
local function should_add_to_search_if_within_unit_movement(mapSearch, coord, current_cost, context)
  -- Return true if the point would not exceed the cost.

  local self = context

  local coordColumn = coord["column"]
  local coordRow = coord["row"]

  -- If this neighbor is in a wall, return false
  local terrainType = self.map:getTileTerrain(coord)

  -- [[ TODO We're hard coding the terrain types for now.
  -- 1 = Concrete
  -- 2 = Grass
  -- 3 = Mud
  -- 4 = Wall
  -- 5 = Pit
  -- ]]
  if terrainType == 4 then
    return false
  end

  -- Get the movement cost of this tile
  local moveCost = 1 -- TODO

  -- If the cost exceeds the moveDistance, return false
  if current_cost + moveCost > self.moveDistance then
    return false
  end

  -- Return true, you can go there.
  return true
end

UnitMove={}
function UnitMove:new(...)
  self.map, self.moveDistance, self.moveType = ...
  return self
end
function UnitMove:chartCourse(destination)
  -- Return a single path to the destination, assuming inifinite turns.
  -- Returns nil if the trip is impossible.
  return nil
end
function UnitMove:nextWaypoint(course)
  --[[ Following the course, return the next location within move distance.
  Returns nil if:
  - Unit is not on the path
  - Unit has completed the path and is on the end.
  - Unit does not have enough move to actually move.
  --]]
  return nil
end

function UnitMove:getTilesWithinMovement(unitLocation, args)
  -- Returns a MapSearch object showing all of the tiles within movement range.

  -- Start a new MapSearch.
  local search = MapSearch:new(self.map)

  -- Begin a search. Track all of the visited locations the unit can reach with its movement.
  local functions = {should_add_to_search=should_add_to_search_if_within_unit_movement}

  search:searchMap(
    functions,
    unitLocation,
    self
  )

  -- If the flatten argument was supplied, flatten the results before returning.
  if args and args["flatten"] ~= nil then
    return search:getAllVisitedLocations()
  end
  -- Return all of the visited locations.
  return search.visited
end
