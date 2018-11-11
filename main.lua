local defaultColorsByTile = {}
local mapTile = {}
local movementTileToImageIndex = {}

function love.load()
   -- Set the resolution
   love.window.setMode( 640, 480 )

   -- Allow users to repeat keyboard presses.
   love.keyboard.setKeyRepeat(true)

   loadMap()
end

function love.update(dt)
end

function love.draw()
   drawMap()
end

function readFile(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

function loadMap()
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
	  defaultColorsByTile[movementTileName] = rgb
   end

   -- Get the movement tile key. This maps the character in the movement map to a color.
   for char, index in pairs(mapJson.graphics["movement tile to image index"]) do
	  movementTileToImageIndex[char] = index
   end

   -- Get the width of the first map. All rows should be this wide.
   local width = #(mapJson.graphics.movement[1])

   -- Prepare all of the rows of the map
   for x = 1,width,1 do mapTile[x] = {} end

   local rowIndex,columnIndex = 1,1

   -- For each row
   for i, row in ipairs(mapJson.graphics.movement) do
	  -- Make sure the row is as long as the first row
	  assert(#row == width, 'Map is not aligned: width of row ' .. tostring(rowIndex) .. ' should be ' .. tostring(width) .. ', but it is ' .. tostring(#row))

	  -- For each character in the row
	  columnIndex = 1
	  for character in row:gmatch(".") do
		 -- Add a character to this row.
		 mapTile[rowIndex][columnIndex] = character
		 columnIndex = columnIndex + 1
	  end

	  -- Increment the row counter
	  rowIndex = rowIndex + 1
   end
end

function drawMap()
   -- For each row
   for i,row in ipairs(mapTile) do
	  -- For each column
	  for j,column in ipairs(row) do
		 -- Get the tile index
		 drawTile(j,i,row[j])
	  end
   end
end

function drawTile(column, row, colorString)

   -- Get the RGB color
   local colorIndex = movementTileToImageIndex[colorString]
   local tileColorRGB = defaultColorsByTile[colorIndex]

   -- Get the Y coordinate
   local y = 64 * row

   -- Get the X coordinate
   local x = 64 * column

   -- Based on the row, add an offset.
   if row % 2 == 1 then
	  x = x + 32
   end

   love.graphics.setColor(tileColorRGB.r, tileColorRGB.g, tileColorRGB.b)
   love.graphics.rectangle("fill", x, y, 63, 63 )
end
