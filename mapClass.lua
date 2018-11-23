local function readFile(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

MapClass={}
function MapClass:new()
  self.mapTile={}
  self.movementTileToImageIndex={}
  self.defaultColorsByTile={}
   self:load{}
   return self
end
function MapClass:load ()
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
function MapClass:draw()
   -- For each row
   for i,row in ipairs(self.mapTile) do
	  -- For each column
	  for j,column in ipairs(row) do
		 -- Get the tile index
		 self:drawTile(j,i,row[j])
	  end
   end
end
function MapClass:getCoordinateClickedOn(x, y)
   -- Based on the y coordinate, determine the row.
   row = math.floor(y / 64) + 1

   -- The row will determine the offset.
   offset = 0
   if row % 2 == 1 then
	  offset = 64 / 2
   end

   -- Remove the offset from the x coordinate. Based on the x coordinate, determine the column.
   column = math.floor((x - offset) / 64) + 1

   -- make sure the row and column are valid.
   if row < 1 or column < 1 then
	  return nil, nil
  elseif column > #(self.mapTile[1]) or row > #self.mapTile then
	  return nil, nil
   end

   return column, row
end

-- TODO import love utility or split into gfx class

function MapClass:drawTile(column, row, colorString)
   -- Get the RGB color
   local colorIndex = self.movementTileToImageIndex[colorString]
   local tileColorRGB = self.defaultColorsByTile[colorIndex]

   -- Get the Y coordinate
   local y = 64 * (row - 1)

   -- Get the X coordinate
   local x = 64 * (column - 1)

   -- Based on the row, add an offset.
   if row % 2 == 1 then
	  x = x + 32
   end

   love.graphics.setColor(tileColorRGB.r, tileColorRGB.g, tileColorRGB.b)
   love.graphics.rectangle("fill", x, y, 63, 63 )
end

return MapClass
