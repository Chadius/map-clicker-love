require "map/mapClass"
local PriorityQueue = require "map/priorityQueue"
local lunit = require "libraries/unitTesting/lunitx"

if _VERSION >= 'Lua 5.2' then
    _ENV = lunit.module('enhanced','seeall')
else
    module( "enhanced", package.seeall, lunit.testcase )
end

local test_map = nil

function setup()
  -- Test Map is a 3x3 grid
  testMap = MapClass:new{}
  testMap.mapTile = {
    {1,1,1},
    {1,1,1},
    {1,1,1}
  }
end

function teardown()
  -- Clear Test Map
  testMap = nil
end

function add_neighbors_null(payload)
  -- Add no neighbors
end

function stop_when_empty(payload)
  -- Stop searching as soon as the available paths are empty
  if #(payload["paths"]) == 0 then
    payload["stop_search"] = true
  end
end

function test_bad_params()
  -- Make sure an origin and functions are passed.
  functions = {
    add_neighbors=add_neighbors_null,
    should_stop=stop_when_empty
  }

  search_results = testMap:searchMap(functions, nil)
  assert_equal(search_results, nil)

  origin = {
    column=1,
    row=1
  }

  search_results = testMap:searchMap(nil, orign)
  assert_equal(search_results, nil)
end

function test_no_movement()
  -- Start searching in the middle of the map.
  -- Stop after 1 iteration.
  -- Results should have 1 item, the start point.

  functions = {
    add_neighbors=add_neighbors_null,
    should_stop=stop_when_empty
  }

  origin = {
    column=2,
    row=3
  }

  search_results = testMap:searchMap(functions, origin)

  -- There is only 1 visited point, at (2,3)
  visited_locations = search_results["visited"]

  -- Only 1 column was visited, at the origin, column 2
  assert_not_equal(nil, visited_locations[2])

  -- Only 1 row in that column was visited, row 3
  assert_not_equal(nil, visited_locations[2][3])

  -- The search was stopped
  assert_true(search_results["stop_search"])

  -- Confirm the origin is (2,3)
  assert_equal(2, search_results["origin"]["column"])
  assert_equal(3, search_results["origin"]["row"])
end

--[[ Path objects
Has steps
Each step is a table
- column
- row
- movement_spent

start_column
start_row

And the function calls
--]]
