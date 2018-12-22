--[[
Hold all of the graphics information not built into the system.
--]]

GraphicsContext={}
function GraphicsContext:new()
  self.tileSize = 64
  return self
end
function GraphicsContext:getTileSize()
  return self.tileSize
end
function GraphicsContext:getTileCoordinate(column, row)
  -- [[ Return a pair of index coordinates noting the pixel location of
  -- the tile. Returns nil, nil if either argument is nil.
  -- ]]
  if column == nil or row == nil then
    return nil, nil
  end

  -- Get the Y coordinate
  local y = self.tileSize * (row - 1)

  -- Get the X coordinate
  local x = self.tileSize * (column - 1)

  -- Based on the row, add an offset.
  if row % 2 == 1 then
    x = x + self.tileSize / 2
  end

  return x, y
end
