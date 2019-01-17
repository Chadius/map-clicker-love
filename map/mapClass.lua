local MapSearch = require "map/mapSearch"

local function readFile(file)
  local f = assert(io.open(file, "rb"))
  local content = f:read("*all")
  f:close()
  return content
end

MapClass={}
function MapClass:new()
  self.mapTile={}

  -- Store the terrain costs. This should have the same dimensions as mapTile.
  self.moveTile={}
  self.drawing=nil
  self.search=MapSearch:new(self)
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

function MapClass:searchMap(functions, origin)
  -- origin must contain a row and column
  return self.search:searchMap(functions, origin)
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

function MapClass:getTileTerrain(coordinate)
  -- Return the type of terrain at a tile.
  if self:isOnMap(coordinate) == false then
    return nil
  end
  local column = coordinate["column"]
  local row = coordinate["row"]
  return self.moveTile[row][column]
end
