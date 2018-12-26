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
  if payload["paths"]:empty() == 0 then
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

function atest_no_movement()
  -- Start searching in the middle of the map.
  -- Stop after 1 iteration.
  -- Results should have 1 item, the start point.

  local functions = {
    add_neighbors=add_neighbors_null,
    should_stop=stop_when_empty
  }

  local origin = {
    column=2,
    row=3
  }

  local search_results = testMap:searchMap(functions, origin)

  -- There is only 1 visited point, at (2,3)
  local visited_locations = search_results["visited"]

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

function add_neighbors_adjacent_to_origin(payload)
  -- Only add neighbors adjacent to the start point.

  -- Get the origin
  local origin = payload["origin"]

  -- Get the adjacent coordinates to the top
  local topPath = payload["top"]
  local step = topPath[ #topPath ]
  local map = payload["map"]

  local rawNeighbors = map:getNeighboringCoordinates(step)
  local neighbors = {}

  for i, coord in ipairs(rawNeighbors) do
    local coordColumn = coord["column"]
    local coordRow = coord["row"]
    -- If the coordinate has not been visited
    local alreadyVisited = (payload["visited"][coordColumn] and payload["visited"][coordColumn][coordRow])

    -- If the coordinate is on the map
    local onMap = map:isOnMap(coord)
    -- And it is less than 1 row and column away from the origin
    local adjacentToOrigin = (math.abs(coordColumn - origin["column"]) < 2 and math.abs(coordRow - origin["row"]) < 2)

    if onMap and adjacentToOrigin and alreadyVisited == nil then
      -- Add the coordinate to the neighbors
      table.insert(neighbors, coord)
    end
  end

  -- Make new paths for the neighbors
  for i, neighbor in ipairs(neighbors) do
    -- Clone the top path
    local newPath = {}

    for i, step in ipairs(topPath) do
      table.insert(newPath, step)
    end

    -- Add this new neighbor but with a cost of 1
    local cost = topPath[1]["cost"]
    local newCost = cost + 1
    table.insert(
      newPath,
      {
        column=neighbor["column"],
        row=neighbor["row"],
        cost=newCost
      }
    )

    -- Add this to the paths
    payload["paths"]:put(newPath, newCost)
  end
end

function test_check_for_neighbors()
  -- Start searching in the middle of the map.
  -- Add neighbors on the map, maximum cost is 1.
  -- Results should have 7 items.

  local functions = {
    add_neighbors=add_neighbors_adjacent_to_origin,
    should_stop=stop_when_empty
  }

  local origin = {
    column=1,
    row=1
  }

  local search_results = testMap:searchMap(functions, origin)

  -- There are 3 visited locations
  local visited_locations = search_results["visited"]

  -- (1,1)
  assert_not_equal(nil, visited_locations[1])
  assert_not_equal(nil, visited_locations[1][1])

  --(2,1)
  assert_not_equal(nil, visited_locations[2])
  assert_not_equal(nil, visited_locations[2][1])

  --(1,2)
  assert_not_equal(nil, visited_locations[1])
  assert_not_equal(nil, visited_locations[1][2])

  -- TODO: Make a list of locations
end
