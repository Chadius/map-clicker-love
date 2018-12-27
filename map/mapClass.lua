local PriorityQueue = require "map/priorityQueue"

local function readFile(file)
  local f = assert(io.open(file, "rb"))
  local content = f:read("*all")
  f:close()
  return content
end

MapClass={}
function MapClass:new()
  self.mapTile={}
  self.drawing=nil
  return self
end
function MapClass:load()
  local json = require "reader/json"
  mapFile = readFile("sampleMap.json")
  mapJson = json.decode(mapFile)

  -- Load graphical information.
  self.drawing:load(mapJson)

  -- Get the width of the first map. All rows should be this wide.
  local width = #(mapJson.graphics.movement[1])

  -- Prepare the map.
  self.mapTile = {}

  local rowIndex,columnIndex = 1,1

  -- For each row
  for i, row in ipairs(mapJson.graphics.movement) do
    -- Make sure the row is as long as the first row
    assert(#row == width, 'Map is not aligned: width of row ' .. tostring(rowIndex) .. ' should be ' .. tostring(width) .. ', but it is ' .. tostring(#row))

    newRow = {}
    columnIndex = 1
    for character in row:gmatch(".") do
      -- Add a character to this row.
      newRow[columnIndex] = character
      columnIndex = columnIndex + 1
    end

    -- Add the row.
    self.mapTile[rowIndex] = newRow

    -- Increment the row counter
    rowIndex = rowIndex + 1
  end

  return self
end
function MapClass:drawSelectedTile(column, row)
  self.drawing:drawSelectedTile(column, row)
end
function MapClass:draw()
  self.drawing:draw(self.mapTile)
end
function MapClass:getTileClickedOn(x, y)
  return self.drawing:getTileClickedOn(x, y,
    #(self.mapTile[1]), -- width
    #self.mapTile -- height
  )
end

local function startMapSearch(payload)
  -- Default map start.

  -- Add the start point as a path.
  local start_point = {}
  local new_point = {}
  new_point["column"] = payload["origin"]["column"]
  new_point["row"] = payload["origin"]["row"]
  new_point["cost"] = 0

  table.insert(start_point, new_point)

  payload["paths"]:put(start_point, new_point["cost"])
end

local function nextMapSearch(payload)
  -- If the paths are empty, stop the search now.
  if payload["paths"]:empty() then
    payload["stop_search"] = true
    return
  end

  -- Pop the top of the queue. Set the payload's top.
  local topPath = payload["paths"]:pop()
  payload["top"] = topPath
  local step = topPath[ #topPath ]
  local column = step["column"]
  local row = step["row"]

  -- Mark the location as visited
  if payload["visited"][column] == nil then
    payload["visited"][column] = {}
  end
  payload["visited"][column][row] = 1
end

local function getRawNeighbors(payload, centralCoordinate)
  --[[ Return the coordinates surrounding the central coordinate
  --]]
  local neighbors = {}

  local direction = {}
  table.insert(direction, {column_adj= 0, row_adj=-1})
  table.insert(direction, {column_adj= 1, row_adj=-1})
  table.insert(direction, {column_adj= 1, row_adj= 0})
  table.insert(direction, {column_adj= 1, row_adj= 1})
  table.insert(direction, {column_adj= 0, row_adj= 1})
  table.insert(direction, {column_adj=-1, row_adj= 0})

  local map = payload["map"]

  -- for each direction
  for i, adjustment in ipairs(direction) do
    -- Map to the changes to column and row.
    newCoordinate = {
      column=centralCoordinate["column"] + adjustment["column_adj"],
      row=centralCoordinate["row"] + adjustment["row_adj"]
    }

    -- If the coordinate is on the map
    local onMap = map:isOnMap(newCoordinate)

    -- if it's on the map
    if onMap then
      -- Add it to the results.
      table.insert(neighbors, newCoordinate)
    end
  end
  return neighbors
end

local function shouldAddToSearch(payload, coord)
  -- Returns true if this coord should be added to the search.

  local map = payload["map"]

  -- If the coordinate is on the map
  local onMap = map:isOnMap(coord)

  -- If the coordinate has not been visited
  local alreadyVisited = map:isAlreadyVisited(payload, coord)

  -- if it's on the map
  if onMap and alreadyVisited ~= true then
    -- Add it to the results.
    return true
  end

  return false
end

--[[ Search functions
functions: A table that lets you customize the search.
  start - Has a default (see startMapSearch). Initializes search parameters.
  next - Has a default (see nextMapSearch). Gets the next path to observe and
    marks a location as visited.
  get_raw_neighbors - Has a default (see getRawNeighbors). Based on the top path
    returned by next(), return a list of neighbors, not filtered.
  should_add_to_search_1 - Has a default (see TODO). Returns a boolean to
    determine if this coordinate should be added to the search. Default has
    basic filtering options.
  should_add_to_search_2 - Returns a boolean to determine if this coordinate
    should be added to the search.
  (DEPRECATED) add_neighbors - This function will add neighbors to the search.
  should_stop - Sets payload["stop_search"] to true if the search should end.

origin: A table with the column and row where you want to begin the search.

payload is a table containing:
  origin - A table with the "column" and "row" indecies
  top - The current observed path
  paths - A priority queue containing all of the paths to points on the map,
    sorted by movement cost.
  map - This MapClass object
  stop_search - A boolean value indicating if the search should stop now.
  visited - A dict marking the columns and rows than have been visited.
--]]
function MapClass:searchMap(functions, origin)
  -- origin must contain a row and column
  if origin == nil or
    type(origin) ~= "table" or
    origin["column"] == nil or
    origin["row"] == nil then
    return nil
  end

  -- If any functions are missing, apply the default functions
  functions["start"] = functions["start"] or startMapSearch
  functions["next"] = functions["next"] or nextMapSearch
  functions["get_raw_neighbors"] = functions["get_raw_neighbors"] or getRawNeighbors
  functions["should_add_to_search_1"] = functions["should_add_to_search_1"] or shouldAddToSearch

  local payload = {}
  payload["paths"] = PriorityQueue()
  payload["map"] = self
  payload["stop_search"] = false
  payload["top"] = nil
  payload["origin"] = origin
  payload["visited"] = {}

  -- Start the search
  functions["start"](payload)

  -- While we should not stop the search
  while payload["stop_search"] ~= true do
    -- Get the next path
    functions["next"](payload)

    -- See if we should stop the search
    if payload["stop_search"] then
      break
    end

    -- Get the raw neighbors
    local topPath = payload["top"]
    local step = topPath[ #topPath ]
    local rawNeighbors = functions["get_raw_neighbors"](payload, step)

    -- Filter the neighbors

    -- Get the origin
    local origin = payload["origin"]

    -- Get the adjacent coordinates to the top
    local neighbors = {}

    for i, coord in ipairs(rawNeighbors) do
      local coordColumn = coord["column"]
      local coordRow = coord["row"]

      local firstFilterPass = functions["should_add_to_search_1"](payload, coord)

      if firstFilterPass then
        -- Run the custom second pass
        local secondFilterPass = functions["should_add_to_search_2"](payload, coord)

        if secondFilterPass then
          -- Add the coordinate to the neighbors
          table.insert(neighbors, {
            column=coordColumn,
            row=coordRow,
            cost=1
          })
        end
      end
    end
    -- Using the new neighbors, generate new paths
    self:addNewPathsWithNeighbors(payload, neighbors)

    -- See if we should stop the search
    functions["should_stop"](payload)
  end

  -- Return the paths
  return payload
end

function MapClass:isOnMap(coordinate)
  -- Returns true if the coordinate is on the map.

  local mapWidth = #(self.mapTile[1])
  local mapHeight = #self.mapTile

  if coordinate["column"] < 1 or coordinate["row"] < 1 then
    return false
  end

  if coordinate["column"] > mapWidth or coordinate["row"] > mapHeight then
    return false
  end

  return true
end

function MapClass:isAlreadyVisited(payload, coordinate)
  -- Returns true if the coordinate has already been visited
  local coordColumn = coordinate["column"]
  local coordRow = coordinate["row"]

  local alreadyVisited = (payload["visited"][coordColumn] ~= nil and payload["visited"][coordColumn][coordRow] ~= nil)

  return (alreadyVisited == true)
end

function MapClass:getNeighboringCoordinates(centralCoordinate)
  --[[ Return the coordinates surrounding the central coordinate
  --]]
  local neighbors = {}

  local direction = {}
  table.insert(direction, {column_adj= 0, row_adj=-1})
  table.insert(direction, {column_adj= 1, row_adj=-1})
  table.insert(direction, {column_adj= 1, row_adj= 0})
  table.insert(direction, {column_adj= 1, row_adj= 1})
  table.insert(direction, {column_adj= 0, row_adj= 1})
  table.insert(direction, {column_adj=-1, row_adj= 0})

  -- for each direction
  for i, adjustment in ipairs(direction) do
    -- Map to the changes to column and row.
    newCoordinate = {
      column=centralCoordinate["column"] + adjustment["column_adj"],
      row=centralCoordinate["row"] + adjustment["row_adj"]
    }

    -- If the coordinate is on the map
    local onMap = self:isOnMap(centralCoordinate)

    -- if it's on the map
    if onMap then
      -- Add it to the results.
      table.insert(neighbors, newCoordinate)
    end
  end
  return neighbors
end

function MapClass:addNewPathsWithNeighbors(payload, neighbors)
  -- Make new paths for the given neighbors.
  -- Neighbors are a table containing the column, row and movment cost to the neighbor.

  local topPath = payload["top"]
  local step = topPath[ #topPath ]

  for i, neighbor in ipairs(neighbors) do
    -- Clone the top path
    local newPath = {}

    for i, step in ipairs(topPath) do
      table.insert(newPath, step)
    end

    -- Add this new neighbor but with the neighbor's cost
    local newCost = step["cost"] + neighbor["cost"]
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
