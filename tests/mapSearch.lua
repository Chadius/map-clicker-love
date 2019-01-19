require "tests/utility/map"

local MapClass = require "map/mapClass"
local PriorityQueue = require "map/priorityQueue"
local MapPath = require "map/mapPath"
local MapHighlight = require "map/mapHighlight"

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

function test_map_paths_empty()
  -- [[ Initialize an empty MapPath
  -- ]]
  local path = MapPath:new()

  -- Path should be empty upon creation
  assert_true(path:empty())

  -- Add a step and confirm it's not empty
  path:addStep(1,1,0)
  assert_false(path:empty())
end

function test_add_step_to_map_path()
  -- [[ Add Step to path
  -- Add multiple steps to path
  -- ]]

  local path = MapPath:new()
  -- The Path is empty so the total cost is 0.
  assert_equal(path:totalCost(), 0)
  -- Add a step with a positive cost.
  path:addStep(2,2,1)
  -- Verify the total cost has changed.
  assert_equal(path:getNumberOfSteps(), 1)
  assert_equal(path:totalCost(), 1)
  -- Add another step.
  path:addStep(3,2,5)
  -- There are 2 steps in this path.
  assert_equal(path:getNumberOfSteps(), 2)
  -- The total cost has increased, too.
  assert_equal(path:totalCost(), 6)
end

function test_clone_map_path()
  --[[ Clone path
    Add step to cloned path, not original
  --]]

  -- Create the original path.
  local originalPath = MapPath:new()
  originalPath:addStep(2,2,1)
  originalPath:addStep(3,2,5)
  originalPath:addStep(3,3,2)
  assert_equal(originalPath:getNumberOfSteps(), 3)
  assert_equal(originalPath:totalCost(), 8)

  -- Clone this path.
  local newPath = originalPath:clone()
  assert_equal(newPath:getNumberOfSteps(), 3)
  assert_equal(newPath:totalCost(), 8)
  -- Add another step on the clone and make sure it doesn't affect the original.
  newPath:addStep(4,2,3)
  assert_equal(originalPath:getNumberOfSteps(), 3)
  assert_equal(originalPath:totalCost(), 8)

  assert_equal(newPath:getNumberOfSteps(), 4)
  assert_equal(newPath:totalCost(), 11)
end

function atest_map_highlight_from_search()
  --[[Test that you can make a highlight from a completed search.
  --]]

  -- Perform a search.
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

  -- Create a new MapHighlight and use the search's visited points as a basis.
  local highlights = MapHighlight:new()
  highlights:copyFromMapMatrix(testSearch.visited)

  -- Confirm they have the same locations.
  local actual_highlights = highlights:getHighlightedMap()
  assert_map_locations_table_found(expected_locations, actual_highlights, "test_map_highlight_from_search 253")

  -- Assert all locations were found.
  local actual_highlights_list = highlights:getHighlightedList()
  assert_map_locations_list_found(expected_locations, actual_highlights_list, "test_map_highlight_from_search 257")
end
function test_map_set_dimension_and_highlight()
  --[[ MapHighlights can change their dimensions and can have highlights.
  ]]

  -- Make a new MapHighlight and set its dimensions to 3 columns by 2 rows.
  local highlight = MapHighlight:new()
  highlight:setDimensions(3, 2)

  -- Make sure you can't get offmap information.
  assert_equal(highlight:getHighlight(0, 1), nil)
  assert_equal(highlight:getHighlight(4, 1), nil)
  assert_equal(highlight:getHighlight(1, 0), nil)
  assert_equal(highlight:getHighlight(1, 3), nil)

  -- Highlight (1,2) and confirm it succeeded.
  assert_true(highlight:setHighlight(1, 2, 1))
  assert_equal(highlight:getHighlight(1, 2), 1)

  -- Highlight (3,2) and confirm it succeeded.
  assert_true(highlight:setHighlight(3, 2, "A"))
  assert_equal(highlight:getHighlight(3, 2), "A")

  -- Change the dimensions to 2 columns by 2 rows.
  assert_true(highlight:setDimensions(2, 2))

  -- Trying to check (3, 2) should return nil to indicate a nonexistent location.
  assert_false(highlight:setHighlight(3, 2, "bogus"))
  assert_equal(highlight:getHighlight(3, 2), nil)

  -- (1, 2) is still highlighted.
  assert_true(highlight:setHighlight(1, 2, 1))
  assert_equal(highlight:getHighlight(1, 2), 1)

  -- Change the dimensions to 2 columns by 1 row.
  assert_true(highlight:setDimensions(2, 1))

  -- Trying to check (1, 2) should return nil to indicate a nonexistent location.
  assert_false(highlight:setHighlight(1, 2, 1))
  assert_equal(highlight:getHighlight(1, 2), nil)

  -- Highlight the entire Map. (1, 1) should be highlighted.
  assert_true(highlight:clear("candy"))
  assert_equal(highlight:getHighlight(1, 1), "candy")
  assert_equal(highlight:getHighlight(2, 1), "candy")
end
