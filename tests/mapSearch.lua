require "map/mapClass"
local PriorityQueue = require "map/priorityQueue"
local lunit = require "libraries/unitTesting/lunitx"

if _VERSION >= 'Lua 5.2' then
    _ENV = lunit.module('enhanced','seeall')
else
    module( "enhanced", package.seeall, lunit.testcase )
end

local test_map = nil
local test_search = nil

function setup()
  -- Test Map is a 3x3 grid
  testMap = MapClass:new{}
  testMap.mapTile = {
    {1,1,1},
    {1,1,1},
    {1,1,1}
  }

  testSearch = MapSearch:new(testMap)
end

function teardown()
  -- Clear Test Map
  testMap = nil
  testSearch = nil
end

function dont_get_raw_neighbors(payload)
  return {}
end

function add_neighbors_null(payload, coord)
  -- Add no neighbors
  return false
end

function stop_when_empty(mapSearch)
  -- Stop searching as soon as the available paths are empty
  if mapSearch.paths:empty() == 0 then
    mapSearch.stop_search = true
  end
end

function skip_test_bad_params()
  -- Make sure an origin and functions are passed.
  functions = {
    add_neighbors=add_neighbors_null,
    should_stop=stop_when_empty
  }

  testSearch:searchMap(functions, nil)

  assert_equal(testSearch.search_errors, "origin needs column and row")
  assert_equal(search_results, nil)

  origin = {
    column=1,
    row=1
  }
  -- Pass in an origin, but no functions
  testSearch:searchMap(nil, origin)
  assert_equal(testSearch.search_errors, "function parameter should be a table")

  -- Pass in the function table, but without needed functions
  testSearch:searchMap({}, origin)
  assert_equal(testSearch.search_errors, "function table is missing should_add_to_search_2")
end

function test_no_movement()
  -- Start searching in the middle of the map.
  -- Stop after 1 iteration.
  -- Results should have 1 item, the start point.

  local functions = {
    get_raw_neighbors=dont_get_raw_neighbors,
    should_add_to_search_2=add_neighbors_null,
    should_stop=stop_when_empty
  }

  local origin = {
    column=2,
    row=3
  }

  testSearch:searchMap(functions, origin)

  -- Only 1 column was visited, at the origin, column 2
  assert_not_equal(nil, testSearch.visited[2])

  -- Only 1 row in that column was visited, row 3
  assert_not_equal(nil, testSearch.visited[2][3])

  -- The search was stopped
  assert_true(testSearch.stop_search)

  -- Confirm the origin is (2,3)
  assert_equal(2, testSearch.origin["column"])
  assert_equal(3, testSearch.origin["row"])

  -- There is only 1 visited point, at (2,3)
  all_visited = testSearch:getAllVisitedLocations()
  assert_equal(1, #all_visited)
  assert_equal(2, all_visited[1]["column"])
  assert_equal(3, all_visited[1]["row"])
end

function add_neighbors_adjacent_to_origin(mapSearch, coord)
  -- Only add neighbors adjacent to the start point.

  -- Get the origin
  local origin = mapSearch.origin

  -- And it is less than 1 row and column away from the origin
  local coordColumn = coord["column"]
  local coordRow = coord["row"]
  local adjacentToOrigin = (math.abs(coordColumn - origin["column"]) < 2 and math.abs(coordRow - origin["row"]) < 2)

  return (adjacentToOrigin == true)
end

function test_check_for_neighbors()
  -- Start searching in a corner of the map.
  -- Add neighbors on the map, maximum cost is 1.
  -- Results should have 3 items.

  local functions = {
    should_add_to_search_2=add_neighbors_adjacent_to_origin,
    should_stop=stop_when_empty
  }

  local origin = {
    column=1,
    row=1
  }

  testSearch:searchMap(functions, origin)

  -- There are 4 visited locations
  local visited_locations = testSearch.visited

  -- (1,1)
  assert_not_equal(nil, visited_locations[1])
  assert_not_equal(nil, visited_locations[1][1])

  --(2,1)
  assert_not_equal(nil, visited_locations[2])
  assert_not_equal(nil, visited_locations[2][1])

  --(1,2)
  assert_not_equal(nil, visited_locations[1])
  assert_not_equal(nil, visited_locations[1][2])

  --(2,2)
  assert_not_equal(nil, visited_locations[1])
  assert_not_equal(nil, visited_locations[1][2])

  -- Should have visited 4 locations

  all_visited = testSearch:getAllVisitedLocations()
  assert_equal(4, #all_visited)

  -- Make sure the visited locations have the expected ones
  expected_visited = {
    {column=1,row=1},
    {column=1,row=2},
    {column=2,row=1},
    {column=2,row=2}
  }

  -- For each expected location
  for i, expected in ipairs(expected_visited) do
    -- Look through the actual visited locations to see if they match.
    for j, actual in ipairs(all_visited) do
      if actual["column"] == expected["column"] and actual["row"] == expected["row"] then
        -- Found this location. Mark it as true and look at the next expected one.
        expected["found"] = true
        break
      end
    end
  end

  -- Assert all of them were found.
  for i, expected in ipairs(expected_visited) do
    assert_true(expected["found"], "(" .. expected["column"] .. "," .. expected["row"] ..") not found")
  end
end
