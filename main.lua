local defaultColorsByTile = {}
local mapTile = {}
local movementTileToImageIndex = {}

local clicked = {column=0, row=0}

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

   love.graphics.setColor(0.8,0.8,0.8)
   love.graphics.print("You clicked on (" .. clicked.column .. ", " .. clicked.row .. ")", 100, 420,0,2,2)
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

   -- Prepare the map.
   mapTile = {}

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
	  mapTile[rowIndex] = newRow

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

function love.mousepressed(x, y, button, istouch, presses)
   if button == 1 then
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
		 return
	  elseif column > #(mapTile[1]) or row > #mapTile then
		 return
	  end

   	  clicked.column = column
	  clicked.row = row
   end
end
