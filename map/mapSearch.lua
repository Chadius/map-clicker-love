local PriorityQueue = require "map/priorityQueue"

local function startMapSearch(self)
  -- Default map start.

  -- Add the start point as a path.
  local start_point = {}
  local new_point = {}
  new_point["column"] = self.origin["column"]
  new_point["row"] = self.origin["row"]
  new_point["cost"] = 0

  table.insert(start_point, new_point)

  self.paths:put(start_point, new_point["cost"])
end

local function nextMapSearch(self)
  -- If the paths are empty, stop the search now.
  if self.paths:empty() then
    self.stop_search = true
    return
  end

  -- Pop the top of the queue. Set the top.
  local topPath = self.paths:pop()
  self.top = topPath
  local step = topPath[ #topPath ]
  local column = step["column"]
  local row = step["row"]

  -- Mark the location as visited
  if self.visited[column] == nil then
    self.visited[column] = {}
  end
  self.visited[column][row] = 1
end

local function getRawNeighbors(self, centralCoordinate)
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

  local map = self.map

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

local function shouldAddToSearch(self, coord)
  -- Returns true if this coord should be added to the search.

  local map = self.map

  -- If the coordinate is on the map
  local onMap = map:isOnMap(coord)

  -- If the coordinate has not been visited
  local alreadyVisited = self:isAlreadyVisited(coord)

  -- if it's on the map
  if onMap and alreadyVisited ~= true then
    -- Add it to the results.
    return true
  end

  return false
end

MapSearch={}
function MapSearch:new(map)
  self.origin = nil
  self.top = nil
  self.paths = PriorityQueue()
  self.map = map
  self.stop_search = false
  self.visited = {}
  self.functions = {
    start=nil,
    next=nil,
    get_raw_neighbors=nil,
    should_add_to_search_1=nil,
    should_add_to_search_2=nil,
  }
  self.search_errors = nil

  return self
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
function MapSearch:searchMap(functions, origin)
  -- origin must contain a row and column
  if origin == nil or
    type(origin) ~= "table" or
    origin["column"] == nil or
    origin["row"] == nil then
    self.search_errors = "origin needs column and row"
    return nil
  end

  -- If any functions are missing, apply the default functions
  if functions == nil or
    type(functions) ~= "table" then
    self.search_errors = "function parameter should be a table"
    return nil
  end
  if functions["should_add_to_search_2"] == nil then
    self.search_errors = "function table is missing should_add_to_search_2"
    return nil
  end

  functions["start"] = functions["start"] or startMapSearch
  functions["next"] = functions["next"] or nextMapSearch
  functions["get_raw_neighbors"] = functions["get_raw_neighbors"] or getRawNeighbors
  functions["should_add_to_search_1"] = functions["should_add_to_search_1"] or shouldAddToSearch

  self.origin = origin
  self.top = nil
  self.paths = PriorityQueue()
  --self.map = map
  self.stop_search = false
  self.visited = {}
  self.functions = {
    start=functions["start"],
    next=functions["next"],
    get_raw_neighbors=functions["get_raw_neighbors"],
    should_add_to_search_1=functions["should_add_to_search_1"],
    should_add_to_search_2=functions["should_add_to_search_2"],
  }

  -- Start the search
  functions["start"](self)

  -- While we should not stop the search
  while self.stop_search ~= true do
    -- Get the next path
    functions["next"](self)

    -- See if we should stop the search
    if self.stop_search then
      break
    end

    -- Get the raw neighbors
    local topPath = self.top
    local step = topPath[ #topPath ]
    local rawNeighbors = functions["get_raw_neighbors"](self, step)

    -- Filter the neighbors

    -- Get the origin
    local origin = self.origin

    -- Get the adjacent coordinates to the top
    local neighbors = {}

    for i, coord in ipairs(rawNeighbors) do
      local coordColumn = coord["column"]
      local coordRow = coord["row"]

      local firstFilterPass = functions["should_add_to_search_1"](self, coord)

      if firstFilterPass then
        -- Run the custom second pass
        local secondFilterPass = functions["should_add_to_search_2"](self, coord)

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
    self:addNewPathsWithNeighbors(neighbors)

    -- See if we should stop the search
    functions["should_stop"](self)
  end

  -- Return the paths
  return self.visited
end

function MapSearch:isAlreadyVisited(coordinate)
  -- Returns true if the coordinate has already been visited
  local coordColumn = coordinate["column"]
  local coordRow = coordinate["row"]

  local alreadyVisited = (self.visited[coordColumn] ~= nil and self.visited[coordColumn][coordRow] ~= nil)

  return (alreadyVisited == true)
end

function MapSearch:getNeighboringCoordinates(centralCoordinate)
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
    local onMap = self.map:isOnMap(centralCoordinate)

    -- if it's on the map
    if onMap then
      -- Add it to the results.
      table.insert(neighbors, newCoordinate)
    end
  end
  return neighbors
end

function MapSearch:addNewPathsWithNeighbors(neighbors)
  -- Make new paths for the given neighbors.
  -- Neighbors are a table containing the column, row and movment cost to the neighbor.

  local topPath = self.top
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
    self.paths:put(newPath, newCost)
  end
end

function MapSearch:getAllVisitedLocations()
  -- Return a table containing one table for each visited entry.
  visited = {}

  -- Iterate from each column
  for column, column_table in pairs(self.visited) do
    -- Iterate from each row
    for row, row_found in pairs(column_table) do
      -- If it's not nil, add it to the visited locations
      table.insert(visited, {column=column, row=row})
    end
  end

  return visited
end
