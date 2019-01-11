local PriorityQueue = require "map/priorityQueue"

local function startMapSearch(self, destination, context)
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

local function nextMapSearch(self, destination, context)
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

  -- If a destination was provided, stop if the next step is there.
  if destination ~= nil and destination.column == step.column and destination.row == step.row then
    self.stop_search = true
  end
end

local function getRawNeighbors(self, centralCoordinate, destination, context)
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

local function shouldAddToSearch(self, step, destination, context)
  -- Returns true if this coord should be added to the search.
  local map = self.map

  -- If the coordinate is on the map
  local onMap = map:isOnMap(step)

  -- If the coordinate has not been visited
  local alreadyVisited = self:isAlreadyVisited(step)

  -- if it's on the map
  if onMap and alreadyVisited ~= true then
    -- Add it to the results.
    return true
  end

  return false
end

local function stop_when_empty(self, destination, context)
  -- Stop searching as soon as the available paths are empty
  if self.paths:empty() == 0 then
    self.stop_search = true
  end
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
    basic_should_add_to_search=nil,
    should_add_to_search=nil,
  }
  self.search_errors = nil

  return self
end

--[[
  Starting from the origin, this performs an A* search.

  functions is a table and must contain this key:
    - should_add_to_search: function(self, coord) returns true if the coord
      should be added to the list of paths to search.

    Optional keys for the function table let you customize behavior:
    - start: Starts the search.
    - next: Gets the next path and marks it visited.
    - get_raw_neighbors: When looking at a path, call this function to retutn a list
    - basic_should_add_to_search: Default behavior returns true if the coord is
      on the map and hasn't been visited.
    - should_stop: Return true if you should stop searching after a given iteration.

  destination: nil (if there is no destination) or a table with column and row.

  context: extra information added to any search

  Returns: None.
  Side Effects include:
    self.visited will contain all of the locations visited.
]]
function MapSearch:searchMap(functions, origin, destination, context)
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
  if functions["should_add_to_search"] == nil then
    self.search_errors = "function table is missing should_add_to_search"
    return nil
  end

  functions["start"] = functions["start"] or startMapSearch
  functions["next"] = functions["next"] or nextMapSearch
  functions["get_raw_neighbors"] = functions["get_raw_neighbors"] or getRawNeighbors
  functions["basic_should_add_to_search"] = functions["basic_should_add_to_search"] or shouldAddToSearch
  functions["should_stop"] = functions["should_stop"] or stop_when_empty

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
    basic_should_add_to_search=functions["basic_should_add_to_search"],
    should_add_to_search=functions["should_add_to_search"],
  }

  -- Start the search
  functions["start"](self, destination, context)

  -- While we should not stop the search
  while self.stop_search ~= true do
    -- Get the next path
    functions["next"](self, destination, context)

    -- See if we should stop the search
    if self.stop_search then
      break
    end

    -- Get the raw neighbors
    local topPath = self.top
    local step = topPath[ #topPath ]
    local rawNeighbors = functions["get_raw_neighbors"](self, step, destination, context)

    -- Filter the neighbors

    -- Get the origin
    local origin = self.origin

    -- Get the adjacent coordinates to the top
    local neighbors = {}

    for i, coord in ipairs(rawNeighbors) do
      local coordColumn = coord["column"]
      local coordRow = coord["row"]
      local cost = step["cost"]

      local next_step = {column=coordColumn, row=coordRow, cost=cost}

      local firstFilterPass = functions["basic_should_add_to_search"](self, next_step, destination, context)
      if firstFilterPass then
        -- Run the custom second pass
        local secondFilterPass = functions["should_add_to_search"](self, next_step, destination, context)

        if secondFilterPass then
          -- Add the coordinate to the neighbors
          table.insert(neighbors, {
            column=coordColumn,
            row=coordRow,
            cost=1 -- TODO have to extract cost to the next tile
          })
        end
      end
    end
    -- Using the new neighbors, generate new paths
    self:addNewPathsWithNeighbors(neighbors)

    -- See if we should stop the search
    functions["should_stop"](self, destination, context)
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
  local visited = {}

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
