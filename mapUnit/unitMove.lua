-- [[ This class handles a unit's movement. This includes:
--- Type of movement
--- Navigating on maps
--- Getting directions on maps
--- Movement distance
--- Movement cost
-- ]]
local function should_add_to_search_if_within_unit_movement(mapSearch, next_step, destination, context)
  -- Return true if the point would not exceed the cost.

  local self = context.unitMove

  local coordColumn = next_step["column"]
  local coordRow = next_step["row"]
  local current_cost = next_step["cost"]

  -- If this neighbor is in a wall, return false
  local terrainType = self.map:getTileTerrain(next_step)

  -- [[ TODO We're hard coding the terrain types for now.
  -- 1 = Concrete
  -- 2 = Grass
  -- 3 = Mud
  -- 4 = Wall
  -- 5 = Pit
  -- ]]

  -- You cannot cross walls.
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

local function should_add_to_search_if_can_be_crossed(mapSearch, next_step, destination, context)
  -- Return true if the unit could cross the tile, given its movement type.

  local self = context.unitMove

  local coordColumn = next_step["column"]
  local coordRow = next_step["row"]

  -- If this neighbor is in a wall, return false
  local terrainType = self.map:getTileTerrain(next_step)

  -- [[ TODO We're hard coding the terrain types for now.
  -- 1 = Concrete
  -- 2 = Grass
  -- 3 = Mud
  -- 4 = Wall
  -- 5 = Pit
  -- ]]

  -- You cannot cross walls.
  if terrainType == 4 then
    return false
  end

  -- On foot units cannot cross pits.
  if terrainType == 5 then
    return false
  end

  -- Get the movement cost of this tile
  local moveCost = 1 -- TODO

  -- If move cost exceeds the unit's move cost, return false.
  if moveCost > self.moveDistance then
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
function UnitMove:chartCourse(mapUnit, destination)
  -- Return a single path to the destination, assuming inifinite turns.
  -- Returns nil if the trip is impossible.

  if destination.column == nil then
    print("destination doesn't have a column key")
    return nil
  end
  if destination.row == nil then
    print("destination doesn't have a row key")
    return nil
  end

  -- Start a new MapSearch.
  local search = MapSearch:new(self.map)

  -- Begin a search. Track all of the visited locations the unit can reach with its movement.
  local functions = {
    should_add_to_search=should_add_to_search_if_within_unit_movement
  }

  search:searchMap(
    functions,
    {column=mapUnit.column,row=mapUnit.row},
    destination,
    {
      mapUnit=mapUnit,
      unitMove=self
    }
  )
  -- If no top path exists, return nil
  if search.top == nil then
    return nil
  end

  local topPath = search.top
  local step = topPath[ #topPath ]

  -- If the topPath refers to the destination, return it
  if step.column == destination.column and step.row == destination.row then
    return search.top
  end

  -- The path is not possible.
  return nil
end
function UnitMove:nextWaypoint(mapUnit, course)
  --[[ Following the course, return the next location within move distance.
  Returns nil if:
  - Unit is not on the path
  - Unit has completed the path and is on the end.
  - Unit does not have enough move to actually move.
  --]]

  if course == nil then
    return nil
  end

  -- Get the destination
  local destination = course[#course]
  -- If the unit is already at the destination, return nil
  local current_location = mapUnit:getMapCoordinates()
  if destination.column == current_location.column and destination.row == current_location.row then
    return nil
  end

  return nil
end

function UnitMove:getTilesWithinMovement(mapUnit, args)
  -- Returns a MapSearch object showing all of the tiles within movement range.

  -- Start a new MapSearch.
  local search = MapSearch:new(self.map)

  -- Begin a search. Track all of the visited locations the unit can reach with its movement.
  local functions = {should_add_to_search=should_add_to_search_if_within_unit_movement}

  search:searchMap(
    functions,
    {column=mapUnit.column,row=mapUnit.row},
    nil,
    {
      mapUnit=mapUnit,
      unitMove=self
    }
  )

  -- If the flatten argument was supplied, flatten the results before returning.
  if args and args["flatten"] ~= nil then
    return search:getAllVisitedLocations()
  end
  -- Return all of the visited locations.
  return search.visited
end
