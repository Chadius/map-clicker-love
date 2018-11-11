-- Sky RGB: 0.64, 0.73, 0.75 (HSV 190, 1.15, 0.75)
-- Wall RGB: 0.1, 0, 0.15 (HSV 280, 1, 0.15)
-- Ground RGB: 0.74, 0.75, 0.71 (HSV 75, 0.5, 0.75)
-- Rough RGB: 0.65, 0.55, 0.36 (HSV 39, 0.45, 0.65)

local colorsByTile = {
   {r = 0.64, g = 0.73, b = 0.75},
   {r = 0.1,  g = 0,    b = 0.15},
   {r = 0.74, g = 0.75, b = 0.71},
   {r = 0.65, g = 0.55, b = 0.36}
}

local mapTile = {}
local movementTileToImageIndex = {}

local json = require "json"

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

   mapFile = readFile("sampleMap.json")
   mapJson = json.decode(mapFile)

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
   local tileColorRGB = colorsByTile[colorIndex]

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
