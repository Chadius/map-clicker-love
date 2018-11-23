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
  mapObject:drawSelectedTile(clicked.column, clicked.row)

  love.graphics.setColor(0.8,0.8,0.8)
  if column ~= nil and row ~= nil then
    love.graphics.print("You clicked on (" .. clicked.column .. ", " .. clicked.row .. ")", 100, 420,0,2,2)
  else
    love.graphics.print("Click on the map.", 100, 420,0,2,2)
  end
end
function love.keypressed(key)
  if key == "escape" then
     love.event.quit()
  end
end
function love.mousepressed(x, y, button, istouch, presses)
  if button == 1 then
    column, row = mapObject:getCoordinateClickedOn(x, y)

    if column ~= nil then
      clicked.column = column
      clicked.row = row
    else
      -- If the user clicked off screen, deselect.
      clicked.column = nil
      clicked.row = nil
    end
  end
end
