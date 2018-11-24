-- This module handles drawing maps.
local function readFile(file)
  local f = assert(io.open(file, "rb"))
  local content = f:read("*all")
  f:close()
  return content
end

mapDrawing={}
function mapDrawing:new()
  self.movementTileToImageIndex={}
  self.defaultColorsByTile={}
  self.tileSize = 64
  return self
end
function mapDrawing:load()
  local json = require "json"
  mapFile = readFile("sampleMap.json")
  mapJson = json.decode(mapFile)

  -- Load the default tile colors, if we can't find an image.
  local colorConverter = require "HSVtoRGB"
  -- For each default tile color
  for movementTileName, colorDict in pairs(mapJson.graphics["default tile color"]) do
    local rgb = {}
    local hsv = {}
    -- See if hue, value and saturation are there
    hsv.h = colorDict.hue
    hsv.s = colorDict.saturation / 100.0
    hsv.v = colorDict.value / 100.0
    --- Convert to RGB values
    rgb.r, rgb.g, rgb.b = colorConverter.HSVToRGB(hsv.h, hsv.s, hsv.v)

    --- Set the default tile color, using the given key.
    self.defaultColorsByTile[movementTileName] = rgb
  end

  -- Get the movement tile key. This maps the character in the movement map to a color.
  for char, index in pairs(mapJson.graphics["movement tile to image index"]) do
    self.movementTileToImageIndex[char] = index
  end

  return self
end
local function getTileCoordinate(column, row, tileSize)
  if column == nil or row == nil then
    return nil, nil
  end

  -- Get the Y coordinate
  local y = tileSize * (row - 1)

  -- Get the X coordinate
  local x = tileSize * (column - 1)

  -- Based on the row, add an offset.
  if row % 2 == 1 then
    x = x + tileSize / 2
  end

  return x, y
end
local function drawTile(self, column, row, colorString)
  -- Get the RGB color
  local colorIndex = self.movementTileToImageIndex[colorString]
  local tileColorRGB = self.defaultColorsByTile[colorIndex]

  local x, y = getTileCoordinate(column, row, self.tileSize)

  -- Draw the tile
  love.graphics.setColor(tileColorRGB.r, tileColorRGB.g, tileColorRGB.b)
  love.graphics.rectangle("fill", x, y, self.tileSize, self.tileSize)

  -- Draw the outline around the tile
  love.graphics.setColor(0, 0, 0, 0.2)
  love.graphics.rectangle("line", x, y, self.tileSize, self.tileSize)
end
function mapDrawing:drawSelectedTile(column, row)
  -- Draw the selected square located at the given column and row.
  local x, y = getTileCoordinate(column, row, self.tileSize)
  if x == nil or y == nil then return end

  -- Choose the color based on the time elapsed.
  timestamp = love.timer.getTime()
  -- We'll use the sine function to get how White or Black it should glow.
  -- Change the period to about every 2 seconds.
  intensity = math.sin (timestamp * math.pi)
  -- Shift the results from (-1, 1) to (0, 1)
  intensity = (intensity / 2) + 0.5

  -- Draw the outlined tile.
  love.graphics.setColor(intensity, intensity, intensity)
  love.graphics.rectangle("fill", x - 1, y - 1, self.tileSize, 3, 0.7)
  love.graphics.rectangle("fill", x - 1, y - 1 + 3, 3, self.tileSize, 0.7)
  love.graphics.rectangle("fill", x + self.tileSize - 1, y - 1, 3, self.tileSize, 0.7)
  love.graphics.rectangle("fill", x + 1, y + self.tileSize - 1, self.tileSize + 1, 3, 0.7)
end
function mapDrawing:draw(mapTile)
  -- For each row
  for i,row in ipairs(mapTile) do
    -- For each column
    for j,column in ipairs(row) do
      -- Get the tile index
      drawTile(self, j,i,row[j])
    end
  end
end
function mapDrawing:getCoordinateClickedOn(x, y, width, height)
  -- Based on the y coordinate, determine the row.
  row = math.floor(y / self.tileSize) + 1

  -- The row will determine the offset.
  offset = 0
  if row % 2 == 1 then
    offset = self.tileSize / 2
  end

  -- Remove the offset from the x coordinate. Based on the x coordinate, determine the column.
  column = math.floor((x - offset) / self.tileSize) + 1

  -- make sure the row and column are valid.
  if row < 1 or column < 1 then
    return nil, nil
  elseif column > width or row > height then
    return nil, nil
  end

  return column, row
end
