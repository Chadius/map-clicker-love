local defaultColorsByTile = {}
local mapTile = {}
local movementTileToImageIndex = {}

local clicked = {column=0, row=0}

local mapObject = nil
function love.load()
   -- Set the resolution
   love.window.setMode( 640, 480 )

   -- Allow users to repeat keyboard presses.
   love.keyboard.setKeyRepeat(true)

   require 'mapClass'
   mapObject = MapClass:new{}
   mapObject:load()
end

function love.update(dt)
end

function love.draw()
   mapObject:draw()

   love.graphics.setColor(0.8,0.8,0.8)
   love.graphics.print("You clicked on (" .. clicked.column .. ", " .. clicked.row .. ")", 100, 420,0,2,2)
end

function love.mousepressed(x, y, button, istouch, presses)
   if button == 1 then
	  column, row = mapObject:getCoordinateClickedOn(x, y)

	  if column ~= nil then
		 clicked.column = column
		 clicked.row = row
	  end
   end
end
