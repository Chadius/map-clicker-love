require "tests/utility/map"

local MapClass = require "map/mapClass"
local PriorityQueue = require "map/priorityQueue"
local MapPath = require "map/mapPath"

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
  local functions = {
    add_neighbors=add_neighbors_null,
    should_stop=stop_when_empty
  }

  testSearch:searchMap(functions, nil)

  assert_equal(testSearch.search_errors, "origin needs column and row")
  assert_equal(search_results, nil)

  local origin = {
    column=1,
    row=1
  }
  -- Pass in an origin, but no functions
  testSearch:searchMap(nil, origin)
  assert_equal(testSearch.search_errors, "function parameter should be a table")

  -- Pass in the function table, but without needed functions
  testSearch:searchMap({}, origin)
  assert_equal(testSearch.search_errors, "function table is missing should_add_to_search")
end

function atest_no_movement()
  -- Start searching in the middle of the map.
  -- Stop after 1 iteration.
  -- Results should have 1 item, the start point.

  local functions = {
    get_raw_neighbors=dont_get_raw_neighbors,
    should_add_to_search=add_neighbors_null,
    should_stop=stop_when_empty
  }

  local origin = {
    column=2,
    row=3
  }

  testSearch:searchMap(functions, origin)

  -- The search was stopped
  assert_true(testSearch.stop_search)

  -- Confirm the origin is (2,3)
  assert_equal(2, testSearch.origin["column"])
  assert_equal(3, testSearch.origin["row"])

  -- Only 1 column was visited, at the origin
  local expected_locations = {
    {column=2,row=3},
  }

  assert_map_locations_table_found(expected_locations, testSearch.visited, "test_no_movement")

  -- There is only 1 visited point, at (2,3)
  local all_visited = testSearch:getAllVisitedLocations()
  assert_map_locations_list_found(expected_locations, all_visited, "test_no_movement")
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
    should_add_to_search=add_neighbors_adjacent_to_origin,
    should_stop=stop_when_empty
  }

  local origin = {
    column=1,
    row=1
  }

  testSearch:searchMap(functions, origin)

  -- Assert all locations were found.
  local expected_locations = {
    {column=1,row=1},
    {column=1,row=2},
    {column=2,row=1},
    {column=2,row=2}
  }

  local visited_locations = testSearch.visited
  assert_map_locations_table_found(expected_locations, testSearch.visited, "test_no_movement")

  -- Assert all locations were found.
  local all_visited = testSearch:getAllVisitedLocations()
  assert_map_locations_list_found(expected_locations, all_visited, "test_no_movement")
end

function test_map_paths()
  -- [[ Test the MapPath object.
  -- ]]
end
