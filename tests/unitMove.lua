local MapClass = require "map/mapClass"
local MapUnit = require "mapUnit/mapUnit"
local UnitMove = require "mapUnit/unitMove"
local TerrainType = require("map/terrainType")
local MapLayer = require "map/mapLayer"

require "tests/utility/map"
local lunit = require "libraries/unitTesting/lunitx"
require "libraries/table"

if _VERSION >= 'Lua 5.2' then
    _ENV = lunit.module('enhanced','seeall')
else
    module( "enhanced", package.seeall, lunit.testcase )
end

--[[
RAW NOTES

Situations:
- I have 3 visions. Show everything I can see on this map
- Can i reach this location with only 3 move? What if a wall blocks my way?
- I want to reach this location. Give me the shortest route.

Each tile asks 3 questions:
- Can units stop on me?
- Can units pass over me?
- How much movement does it cost to enter my square?

         | Stop? | Pass? | Cost
Wall     | N     | N     | n/a
Concrete | Y     | Y     | 1
Grass    | Y     | Y     | 2
Mud      | Y     | Y     | 3
Pit      | N     | Y     | 1

UnitMove class
needs Map
needs MapUnit
- location
- move type
- move distance

function ChartCourse(destination)
Return a single path to the destination, assuming inifinite turns.
Returns nil if the trip is impossible.

function NextWaypoint(course)
Following the course, return the next location within move distance.
Returns nil if:
- Unit is not on the path
- Unit has completed the path and is on the end.
- Unit does not have enough move to actually move.

function GetTilesWithinMovement()
Returns a MapSearch object showing all of the tiles within movement range.

MoveType class
TODO

TODO: Add MoveType to MapUnits
]]

local testMap = nil
local testUnit = nil

function setup()
  -- Test Map is a 3x3 grid
  testMap = MapClass:new{}
  testMap.mapTile = MapLayer:new({
    data={
      {1,1,1,1,1},
       {1,1,1,1,1},
      {1,1,1,1,1},

       {1,1,1,1,1},
      {1,1,1,1,1},
       {1,1,1,1,1},

      {1,1,1,1,1},
       {1,1,1,1,1},
      {1,1,1,1,1},

       {1,1,1,1,1},
      {1,1,1,1,1},
       {1,1,1,1,1},
    }
  })

  testMap.moveTile = MapLayer:new({
    data={
      {1,2,1,1,1},
       {3,1,4,1,1},
      {1,1,1,1,1},

       {1,1,4,1,5},
      {1,1,4,1,1},
       {4,4,4,4,4},

      {1,1,1,1,1},
       {1,1,1,1,1},
      {1,1,1,1,1},

       {1,1,1,1,1},
      {4,4,4,4,4},
       {1,5,1,5,1},
    }
  })

  -- Test Unit
  testUnit = MapUnit:new()
end

function teardown()
  testMap = nil
  testUnit = nil
end

function assert_map_locations_table_found(expected_locations, actual_map, assert_prepend)
  -- Asserts all of the expected and actual locations were found.
  -- actual_map is a sparse nested table.
  --- The first key is the column and the value is another table.
  --- The inner table uses rows as keys.
  -- expected_locations is a list of tables with column and row keys.
  -- assert_prepend is a string to add to the assert if it fails.

  if expected_locations ~= nil then
    assert_not_equal(nil, actual_map)
  else
    assert_equal(nil, actual_map)
  end

  for index, location in pairs(expected_locations) do
    local column = location["column"]
    local row = location["row"]

    assert_not_equal(
      nil,
      actual_map[column],
      assert_prepend .. ": cannot find column " .. column
    )
    assert_not_equal(
      nil,
      actual_map[column][row],
      assert_prepend .. ": cannot find location " .. column .. ", " .. row
    )
  end

  -- Everything matches.
end

function assert_map_locations_list_found(expected_locations, actual_map, assert_prepend)
  -- Asserts all of the expected and actual locations were found.
  -- Assumes actual and expected are a list of tables with column and row keys.

  -- Should have visited the expected number of locations
  assert_equal(#expected_locations, #actual_map, assert_prepend .. ": " .. "expected " .. #expected_locations .. " item, but found " .. #actual_map)

  -- For each expected location
  for i, expected in ipairs(expected_locations) do
    -- Look through the actual visited locations to see if they match.
    for j, actual in ipairs(actual_map) do
      if actual["column"] == expected["column"] and actual["row"] == expected["row"] then
        -- Found this location. Mark it as true and look at the next expected one.
        expected["found"] = true
        break
      end
    end
  end

  -- Assert all of them were found.
  for i, expected in ipairs(expected_locations) do
    assert_true(expected["found"], assert_prepend .. ": " ..  "(" .. expected["column"] .. "," .. expected["row"] ..") not found")
  end
end

function test_adjacent_tiles()
  --[[
  Unit can move 1 space.
  Make sure you get the correct adjacent tiles on even and odd rows.
  ]]

  -- Make unit with 1 move.
  testUnit.movement=UnitMove:new(
    testMap,
    1,
    "walk"
  )

  -- Place it on an odd numbered row.
  testUnit.mapCoordinates.column=2
  testUnit.mapCoordinates.row=9

  -- Get adjacent tiles. It can move diagonally left but not rßight.
  local nearby_tiles = testUnit:getTilesWithinMovement()

  local expected_locations = {
    {column=2,row=9},
    {column=1,row=9},
    {column=3,row=9},
    {column=1,row=10},
    {column=1,row=8},
    {column=2,row=10},
    {column=2,row=8},
  }
  assert_map_locations_table_found(expected_locations, nearby_tiles:getLayeredMap(), "test_adjacent_tiles odd")

  -- Place it on an even numbered row.
  testUnit.mapCoordinates.column=2
  testUnit.mapCoordinates.row=8

  -- Get adjacent tiles. It can move diagonally right but not left.
  local nearby_tiles = testUnit:getTilesWithinMovement()
  local expected_locations = {
    {column=2,row=8},
    {column=1,row=8},
    {column=3,row=8},
    {column=3,row=9},
    {column=3,row=7},
    {column=2,row=9},
    {column=2,row=7},
  }
  assert_map_locations_table_found(expected_locations, nearby_tiles:getLayeredMap(), "test_adjacent_tiles even")
end

function test_unit_has_no_move()
  -- Unit cannot move.
  testUnit.mapCoordinates.column=2
  testUnit.mapCoordinates.row=3

  testUnit.movement=UnitMove:new(
    testMap,
    0,
    "walk"
  )

  -- Unit can only access its spawn point.
  local nearby_tiles = testUnit:getTilesWithinMovement()
  local expected_locations = {
    {column=2,row=3},
  }
  assert_map_locations_table_found(expected_locations, nearby_tiles:getLayeredMap(), "test_unit_has_no_move map")

  assert_map_locations_list_found(expected_locations, nearby_tiles:getLayeredList({skipValue=false}), "test_unit_has_no_move list")

  -- Unit can't chart courses because it can't move there.
  local course = testUnit:chartCourse({column=2,row=2})
  assert_equal(nil, course)

  -- Unit cannot get a waypoint because you cannot move.
  local next_waypoint = testUnit:nextWaypoint(course)
  assert_equal(nil, next_waypoint)

  -- You can chart a course to the starting point.
  local course = testUnit:chartCourse({column=2,row=3})
  assert_not_equal(nil, course)

  -- You are at the course destination so there are no waypoints.
  next_waypoint = testUnit:nextWaypoint(course)
  assert_equal(nil, next_waypoint)
end

function test_unit_with_1_move_fly()
  -- Unit has 1 movement while flying
  testUnit.mapCoordinates.column=2
  testUnit.mapCoordinates.row=2

  testUnit.movement=UnitMove:new(
    testMap,
    1,
    "fly"
  )

  -- Unit can access adjacent spaces next turn (except the wall)
  local nearby_tiles = testUnit:getTilesWithinMovement()
  local expected_locations = {
    {column=2,row=1},
    {column=3,row=1},
    {column=1,row=2},
    {column=2,row=2},
    {column=2,row=3},
    {column=3,row=3},
  }

  assert_map_locations_table_found(expected_locations, nearby_tiles:getLayeredMap(), "test_unit_with_1_move_fly 232")

  local list_of_tiles = testUnit:getTilesWithinMovement()
  assert_map_locations_list_found(expected_locations, list_of_tiles:getLayeredList{skipValue=false}, "test_unit_with_1_move_fly 235")

  -- Unit can chart courses to anywhere except walls.
  local course = testUnit:chartCourse({column=1,row=1})
  assert_not_equal(nil, course)

  -- Can't chart a course to the wall, no matter how many turns
  course = testUnit:chartCourse({column=3,row=2})
  assert_equal(nil, course)

  -- Can't chart a course to the pit because you can't stop there
  course = testUnit:chartCourse({column=5,row=4})
  assert_equal(nil, course)

  -- Chart a course that will take 2 turns to reach. NextWaypoint returns an adjacent tile.
  course = testUnit:chartCourse({column=4,row=1})
  assert_not_equal(nil, course)

  local next_waypoint = testUnit:nextWaypoint(course)
  assert_equal(3, next_waypoint["column"])
  assert_equal(1, next_waypoint["row"])

  -- Chart a course to the space next to the pit. Because you can't stop on a pit, the course should not include the pit space.
  course = testUnit:chartCourse({column=4,row=2})
  assert_not_equal(nil, course)

  for i, step in iterateMapPathSteps(course) do
    assert_true(TerrainType.id[testMap.moveTile:get(step.column, step.row)].canStopOn)
  end
end

function test_fly_over_pits()
  --[[ Unit can fly 2 spaces.
  Make sure it can chart courses over 1 space pits.
  ]]
  testUnit.mapCoordinates.column=1
  testUnit.mapCoordinates.row=12

  testUnit.movement=UnitMove:new(
    testMap,
    2,
    "fly"
  )

  -- Make sure it can reach across the pit this turn.
  local nearby_tiles = testUnit:getTilesWithinMovement()
  local expected_locations = {
    {column=1,row=12},
    {column=3,row=12},
  }

  assert_map_locations_table_found(expected_locations, nearby_tiles:getLayeredMap(), "test_fly_over_pits")

  -- It can chart a course over the pits, to the other side by stopping on the middle tile.
  local course = testUnit:chartCourse({column=3,row=12})
  assert_not_equal(nil, course)
  local next_waypoint = testUnit:nextWaypoint(course)
  assert_equal(3, next_waypoint["column"])
  assert_equal(12, next_waypoint["row"])

  course = testUnit:chartCourse({column=5,row=12})
  assert_not_equal(nil, course)
end

function test_unit_with_1_move_foot()
  -- Unit has 1 movement on foot
  testUnit.mapCoordinates.column=2
  testUnit.mapCoordinates.row=2

  testUnit.movement=UnitMove:new(
    testMap,
    1,
    "walk"
  )

  -- [[ Unit can access adjacent spaces next turn.
  --  Because it cost too much movement, this unit cannot move to the grass and
  --    mud tiles. They should not appear.
  -- ]]
  local nearby_tiles = testUnit:getTilesWithinMovement()
  local expected_locations = {
    {column=3,row=1},
    {column=2,row=2},
    {column=2,row=3},
    {column=3,row=3},
  }
  assert_map_locations_table_found(expected_locations, nearby_tiles:getLayeredMap(), "test_unit_with_1_move_foot")

  -- Unit can chart courses to concrete terrain.
  local course = testUnit:chartCourse({column=1,row=3})
  assert_not_equal(nil, course)

  -- Chart course to a location that takes 2 movement to cross, expect nil.
  local course = testUnit:chartCourse({column=1,row=1})
  assert_equal(nil, course)
end
