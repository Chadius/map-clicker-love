-- This module handles drawing maps.
local function readFile(file)
  local f = assert(io.open(file, "rb"))
  local content = f:read("*all")
  f:close()
  return content
end

MapDrawing={}
function MapDrawing:new(graphicsContext)
  self.movementTileToImageIndex={}
  self.graphicsContext = graphicsContext
  self.mapTileSpriteSheet = nil
  self.mapTileImageByTerrain = {}
  return self
end
function MapDrawing:load(mapJson)
  -- Get the terrain sprite sheet.
  self.mapTileSpriteSheet = love.graphics.newImage(mapJson["graphics"]["terrain image"]["filename"])
  local imageWidth = self.mapTileSpriteSheet:getWidth()
  local imageHeight = self.mapTileSpriteSheet:getHeight()
  local quadSize = mapJson["graphics"]["terrain image"]["quad size"]

  for terrainName, coords in pairs(mapJson["graphics"]["terrain image"]["terrain quads"]) do
    xPixel = coords["x"] * quadSize
    yPixel = coords["y"] * quadSize
    self.mapTileImageByTerrain[terrainName] = love.graphics.newQuad(
      xPixel,
      yPixel,
      quadSize,
      quadSize,
      imageWidth,
      imageHeight
    )
  end

  -- Get the movement tile key. This maps the character in the movement map to a color.
  for char, index in pairs(mapJson.graphics["movement tile to image index"]) do
    self.movementTileToImageIndex[char] = index
  end

  return self
end
local function drawTile(self, column, row, colorString)
  local quadIndex = self.movementTileToImageIndex[colorString]
  local tileImage = self.mapTileImageByTerrain[quadIndex]
  local x, y = self.graphicsContext:getTileCoordinate(column, row)
  local tileSize = self.graphicsContext:getTileSize()

  if tileImage ~= nil then
    -- Draw the tile
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.mapTileSpriteSheet, tileImage, x, y)
  else
    -- If the tile doesn't exist, we'll use a neon purple color if we can't find a backup color.
    love.graphics.setColor(0.84, 0.48, 0.72, 1)
    love.graphics.rectangle("fill", x, y, tileSize, tileSize)
  end

  -- Draw the outline around the tile
  love.graphics.setColor(0, 0, 0, 0.2)
  love.graphics.rectangle("line", x, y, tileSize, tileSize)
end
function MapDrawing:drawSelectedTile(column, row)
  -- Draw the selected square located at the given column and row.
  local x, y = self.graphicsContext:getTileCoordinate(column, row)
  local tileSize = self.graphicsContext:getTileSize()
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
  love.graphics.rectangle("fill", x - 1, y - 1, tileSize, 3, 0.7)
  love.graphics.rectangle("fill", x - 1, y - 1 + 3, 3, tileSize, 0.7)
  love.graphics.rectangle("fill", x + tileSize - 1, y - 1, 3, tileSize, 0.7)
  love.graphics.rectangle("fill", x + 1, y + tileSize - 1, tileSize + 1, 3, 0.7)
end
function MapDrawing:draw(mapTile)
  -- For each row
  for i,row in ipairs(mapTile) do
    -- For each column
    for j,column in ipairs(row) do
      -- Get the tile index
      drawTile(self, j,i,row[j])
    end
  end
end
function MapDrawing:getTileClickedOn(x, y, width, height)
  --[[ Returns the column and row of the tile clicked.
      Returns nil, nil if there is no such tile.
  --]]
  local tileSize = self.graphicsContext:getTileSize()

  -- Based on the y coordinate, determine the row.
  row = math.floor(y / tileSize) + 1

  -- The row will determine the offset.
  offset = 0
  if row % 2 == 1 then
    offset = tileSize / 2
  end

  -- Remove the offset from the x coordinate. Based on the x coordinate, determine the column.
  column = math.floor((x - offset) / tileSize) + 1

  -- make sure the row and column are valid.
  if row < 1 or column < 1 then
    return nil, nil
  elseif column > width or row > height then
    return nil, nil
  end

  return column, row
end
