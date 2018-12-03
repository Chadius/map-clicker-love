local defaultColorsByTile = {}
local mapTile = {}
local movementTileToImageIndex = {}

local mapObject = nil
local mapSelector = nil
local graphicsContext = nil

function love.load()
  -- Set the resolution
  love.window.setMode( 640, 480 )

  -- Allow users to repeat keyboard presses.
  love.keyboard.setKeyRepeat(true)

  require 'graphicsContext'
  graphicsContext = GraphicsContext:new{}

  require 'mapClass'
  require 'mapDrawing'
  mapObject = MapClass:new{}
  mapObject.drawing = MapDrawing:new(graphicsContext)
  mapObject:load()

  require 'mapSelector'
  mapSelector = MapSelector:new{}

  require 'mapUnit'
  require 'mapUnitDrawing'
  mapUnit = MapUnit.new()
end

function love.update(dt)
end

function love.draw()
  -- Draw the map
  mapObject:draw()
  mapObject:drawSelectedTile(mapSelector.column, mapSelector.row)

  -- Draw the Units
  if mapSelector.column ~= nil then
    love.graphics.setColor(0.3,0.1,0.1)
    local unitX, unitY = graphicsContext:getTileCoordinate(mapSelector.column, mapSelector.row)
    love.graphics.rectangle( "fill", unitX + 8, unitY + 14, 48, 48 )
  end

  -- Draw where you clicked
  love.graphics.setColor(0.8,0.8,0.8)
  if mapSelector.column ~= nil and mapSelector.row ~= nil then
    love.graphics.print("You clicked on (" .. mapSelector.column .. ", " .. mapSelector.row .. ")", 100, 420,0,2,2)
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
  -- If the left mouse button is clicked, update the map selector.
  if button == 1 then
    local column, row = mapObject:getTileClickedOn(x, y)
    mapSelector:selectTile(column, row)
  end
end
