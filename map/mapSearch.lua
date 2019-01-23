local PriorityQueue = require "map/priorityQueue"
local MapPath = require "map/mapPath"
local MapLayer = require "map/mapLayer"

local function startMapSearch(self, destination, context)
  -- Default map start.

  -- Add the start point as a path.
  local start_point = {}
  local new_path = MapPath:new()
  new_path:addStep(self.origin["column"], self.origin["row"], 0)
  self.paths:put(new_path, 0)
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

  local step = topPath:topStep()
  local column = step["column"]
  local row = step["row"]

  -- Mark the location as visited.
  self.visited:setLayer(column, row, 1)

  -- If a destination was provided, stop if the next step is there.
  if destination ~= nil and destination.column == step.column and destination.row == step.row then
    self.stop_search = true
  end
end

local function getRawNeighbors(self, centralCoordinate, destination, context)
  --[[ Return the coordinates surrounding the central coordinate
  --]]
  local neighbors = {}

  -- No matter your location, you have 4 raw neighbors: left, right, up, down
  local direction = {}
  table.insert(direction, {column_adj= 0, row_adj=-1})
  table.insert(direction, {column_adj= 1, row_adj= 0})
  table.insert(direction, {column_adj= 0, row_adj= 1})
  table.insert(direction, {column_adj=-1, row_adj= 0})

  -- If the row is even, you can move diagonally to the right.
  if centralCoordinate.row % 2 == 0 then
    table.insert(direction, {column_adj= 1, row_adj=-1})
    table.insert(direction, {column_adj= 1, row_adj= 1})
  else
    -- If the row is odd, you can move diagonally to the left.
    table.insert(direction, {column_adj= -1, row_adj=-1})
    table.insert(direction, {column_adj= -1, row_adj= 1})
  end

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
MapSearch.__index = MapSearch
function MapSearch:new(map)
  --[[ Create a new path.
  --]]
  local newSearch = {}
  setmetatable(newSearch,MapSearch)

  newSearch.origin = nil
  newSearch.top = nil
  newSearch.paths = PriorityQueue()
  newSearch.map = map
  newSearch.stop_search = false
  newSearch.visited = MapLayer:new()
  newSearch.functions = {
    start=nil,
    next=nil,
    get_raw_neighbors=nil,
    basic_should_add_to_search=nil,
    should_add_to_search=nil,
  }
  newSearch.search_errors = nil

  return newSearch
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
    self.visited will by a MapLayer containing all of the locations visited during the search.
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
  self.stop_search = false

  -- Visited is a MapLayer. Set it to the dimensions of the map. By default, set visited to false.
  self.visited = MapLayer:new()
  local columns, rows = self.map:getDimensions()
  self.visited:setDimensions(columns, rows, false)

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
    local step = topPath:topStep()
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

  if self.visited:getLayer(coordColumn, coordRow) ~= false then
    return true
  end

  return false
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
  local step = MapPath.topStep(topPath)

  for i, neighbor in ipairs(neighbors) do
    -- Clone the top path
    local newPath = topPath:clone()

    -- Add this new neighbor but with the neighbor's cost
    newPath:addStep(
      neighbor["column"],
      neighbor["row"],
      neighbor["cost"]
    )

    -- Add this to the paths
    self.paths:put(newPath, newPath:totalCost())
  end
end

function MapSearch:getAllVisitedLocations()
  -- Return a table containing one table for each visited entry.

  return self.visited:getLayeredMap()
end

return MapSearch
