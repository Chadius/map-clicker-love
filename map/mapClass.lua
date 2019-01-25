local MapSearch = require "map/mapSearch"
local TerrainType = require("map/terrainType")
local MapLayer = require "map/mapLayer"

local function readFile(file)
  local f = assert(io.open(file, "rb"))
  local content = f:read("*all")
  f:close()
  return content
end

local MapClass={}
MapClass.__index = MapClass

function MapClass:new()
  --[[ Create a new path.
  --]]
  local newMap = {}
  setmetatable(newMap,MapClass)
  newMap.mapTile=MapLayer:new()
  -- Store the terrain costs. This should have the same dimensions as mapTile.
  newMap.moveTile=MapLayer:new()

  newMap.drawing=nil
  newMap.search=MapSearch:new(newMap)
  return newMap
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
  local rawMapTiles = {}

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
    mapTiles[rowIndex] = newRow

    -- Increment the row counter
    rowIndex = rowIndex + 1
  end

  -- Copy the loaded map into the tiles.
  self.mapTile.copyFromMapMatrix(rawMapTiles)

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
    self.mapTile:columns(),
    self.mapTile:rows()
  )
end
function MapClass:getDimensions()
  --[[ Returns the width and height of the map.
  Args:
    None.

  Returns:
    Two numbers. One is the number of columns, the other is the number of rows.
  ]]
  return self.mapTile:columns(), self.mapTile:rows()
end
function MapClass:searchMap(functions, origin)
  -- origin must contain a row and column
  return self.search:searchMap(functions, origin)
end

function MapClass:isOnMap(coordinate)
  -- Returns true if the coordinate is on the map.

  local mapWidth = self.mapTile:columns()
  local mapHeight = self.mapTile:rows()

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

  local type = TerrainType.id[self.moveTile:get(column, row)]
  return type
end

return MapClass
