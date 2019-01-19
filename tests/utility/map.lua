local lunit = require "libraries/unitTesting/lunitx"

if _VERSION >= 'Lua 5.2' then
    _ENV = lunit.module('enhanced','seeall')
else
    module( "enhanced", package.seeall, lunit.testcase )
end

function assert_map_locations_table_found(expected_locations, actual_map, assert_prepend)
  -- Asserts all of the expected and actual locations were found.
  -- actual_map is a sparse nested table.
  --- The first key is the column and the value is another table.
  --- The inner table uses rows as keys.
  -- expected_locations is a list of tables with column and row keys.
  -- assert_prepend is a string to add to the assert if it fails.

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
  assert_equal(#expected_locations, #actual_map, assert_prepend .. ": Number of locations mismatch: expected " .. #expected_locations .. ", found " .. #actual_map .." instead")

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
    assert_true(expected["found"], assert_prepend .. ": (" .. expected["column"] .. "," .. expected["row"] ..") not found")
  end
end
