local defaultColorsByTile = {}
local mapTile = {}
local movementTileToImageIndex = {}

local mapObject = nil
local mapSelector = nil
local graphicsContext = nil

--[[ Raw notes to dump

New variables
Course
Destination (X&Y coordinates. Map or World coordinates?)
Wait timer

Update reads
State & Draws at postion
Sends "Current Pos" message

Drawn Unit state machine
NOT DRAWN
"Cicked on"
Payload has X&Y
- Determine if on board
- If so, change to waiting
Move Unit to position

WAITING
"Clicked on"
Payload has X&Y
- Determine if on board
- Determine if in range
- Chart Course to destination (Save it!)
- Change to Moving
- Clear >>>current point<<< to 0
- Set next >>>X&Y destination<<

MOVING
"Current Pos"
Payload has X&Y
- If X&Y is at waypoint,
- Set next >>>X&Y destination<<
- Count >>>Timer<<<
- If timer expires, clear timer
-- If at end of course, state = TURN COMPLETE
-- Else, Increment next destination

TURN complete
Count timerWhen timer expires, clear timer
State = WAITING
]]

function love.load()
  -- Set the resolution
  love.window.setMode( 640, 480 )

  -- Allow users to repeat keyboard presses.
  love.keyboard.setKeyRepeat(true)

  local GraphicsContext = require 'audiovisual/graphicsContext'
  graphicsContext = GraphicsContext:new{}

  local MapClass = require 'map/mapClass'
  local MapDrawing = require 'map/mapDrawing'

  mapObject = MapClass:new{}
  mapObject.drawing = MapDrawing:new(graphicsContext)
  mapObject:load()

  local MapSelector = require 'map/mapSelector'
  mapSelector = MapSelector:new{}

  local MapUnit = require 'mapUnit/mapUnit'
  local MapUnitDrawing = require 'mapUnit/mapUnitDrawing'
  mapUnit = MapUnit:new()
  mapUnit.drawing = MapUnitDrawing:new(graphicsContext)
end

function love.update(dt)
  mapUnit:update(dt)
end

function love.draw()
  -- Draw the map
  mapObject:draw()
  mapObject:drawSelectedTile(mapSelector.column, mapSelector.row)

  -- Draw the Units
  mapUnit:draw()

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
    -- Move the unit to the selected location
    mapUnit:moveToTile(column, row)
  end
end
