--[[ Map information, stored by column and row.
--]]

local MapLayer = {}
MapLayer.__index = MapLayer

function MapLayer:new()
  --[[ Create a new path.
  --]]
  local newLayer = {}
  setmetatable(newLayer,MapLayer)

  -- A 2D matrix. If [column][map] is not nil, then that location was layered.
  newLayer.infoByLocation = {}

  return newLayer
end
local function copyMatrix(source)
  --[[ Create a copy of the values from the source.

  Args:
    source  (table): Nested table. columns point to a table of rows.

  Returns:
    A nested table.
  ]]

  local dest = {}

  -- Iterate across columns
  for i, col in ipairs(source) do
    -- Add a new column.
    dest[i] = {}
    -- Iterate across rows
    for j, row in ipairs(source[i]) do
      -- Add a new row.
      dest[i][j] = {}
      -- Fill each with the newValue
      dest[i][j] = source[i][j]
    end
  end

  return dest
end
function MapLayer:copyFromMapMatrix(source)
  --[[ Copy values from the given 2D matrix.
  Args:
    source: Nested table. The first level has the columns and the child is a
      table with the rows. If child value is not nil, then the location is
      layered.

  Returns:
    true if successful, false otherwise.
  --]]

  -- Copy the source into a new table.
  self.infoByLocation = copyMatrix(source)
end
function MapLayer:getLayeredMap()
  --[[ Returns a 2D Nested Table with [column][row] locations.
  --]]
  return copyMatrix(self.infoByLocation)
end
function MapLayer:getMap()
  --[[ Alternate name for getLayeredMap.
  --]]
  return self:getLayeredMap()
end
function MapLayer:getLayeredList(options)
  --[[ Returns a list of {column, row} tables.
  -- Each item is a layered point.

    Options(optional, default {}): A table containing keys as options:
      skipValue: Do not add items with this value.
  --]]

  local skipValue = nil

  if options then
    skipValue = options["skipValue"]
  end

  local summary = {}

  -- Iterate from each column
  for i, column in ipairs(self.infoByLocation) do
    -- Iterate from each row
    for j, row in ipairs(self.infoByLocation[i]) do
      -- If it's not the skipValue, add it to the location
      if self.infoByLocation[i][j] ~= skipValue then
        table.insert(summary, {column=i, row=j, value=self.infoByLocation[i][j]})
      end
    end
  end

  return summary
end
function MapLayer:getList(options)
  --[[ Alternate name for getLayeredList.
  --]]
  return self:getLayeredList(options)
end
local function isLocationValid(self, column, row)
  --[[ Check if the map location at (column, row) is on the map.
  Args:
    column(number) : Map column.
    row(number) : Map row.

  Returns:
    true if the location is valid.
  ]]
  if column < 1 or row < 1 then
    return false
  end

  if column > #self.infoByLocation then
    return false
  end

  if row > #(self.infoByLocation[1]) then
    return false
  end

  return true
end
function MapLayer:getLayer(column, row)
  --[[ Check if the map location at (column, row) has been layered.
  Args:
    column(number) : Map column.
    row(number) : Map row.

  Returns:
    the value at that location, usually a boolean.
    nil if the location is not applicable (usually off the map.)
  ]]

  -- Make sure column and row is on the layer.
  if isLocationValid(self, column, row) == false then
    return nil
  end

  -- Get the value.
  return self.infoByLocation[column][row]
end
function MapLayer:setLayer(column, row, value)
  --[[ Change whether the location at (column, row) is layered.
  Args:
    column(number)        : Map column.
    row(number)           : Map row.
    value: Value to set this location to.

  Returns:
    true upon success, false otherwise.
  ]]

  -- Make sure column and row is on the layer.
  if isLocationValid(self, column, row) == false then
    return false
  end

  -- Set the value.
  self.infoByLocation[column][row] = value
  return true
end
local function fillMatrixWithValue(matrix, value)
  --[[ Fill all values of the 2D nested table.
  Args:
    matrix: A 2D Nested table (will be modified). The first level has the
      columns and the child is a table with the rows.
    value: The value to set each entry to.

  Returns:
    true if successful.
  ]]

  -- Iterate from each column
  for i, column in ipairs(matrix) do
    -- Iterate from each row
    for j, row in ipairs(matrix[i]) do
      -- Set the value.
      matrix[i][j] = value
    end
  end

  return true
end
function MapLayer:clear(newValue)
  --[[ Sets the layers of all the locations on the map.
  Args:
    newValue(default=false): Sets all of the values on this map.

  Returns:
    true upon success, false otherwise.
  ]]
  return fillMatrixWithValue(self.infoByLocation, newValue)
end
function MapLayer:setDimensions(columns, rows, defaultValue)
  --[[ Resizes the map layer.
  If more columns and rows are added, fill the defaultValue for new locations.
  If there are fewer columns or rows, the highest number columns/rows are truncated.

  Args:
    columns(number)           : Columns in the new map.
    rows(number)              :
    defaultValue(default=false) : Sets all of the values for new columns and rows.

  Returns:
    true upon success, false otherwise.
  ]]

  if columns < 1 or rows < 1 then
    return false
  end

  -- Make new map matrix of new size
  local layers = {}

  -- Iterate from each column
  for i=1, columns do
    layers[i] = {}
    -- Iterate from each row
    for j=1, rows do
      layers[i][j] = false
    end
  end

  local fillValue = false
  if defaultValue ~= nil then
    fillValue = defaultValue
  end

  -- Fill the map with defaultValue
  fillMatrixWithValue(layers, fillValue)

  -- Copy the current layers into the new matrix.
  copyMatrix(self.infoByLocation, layers)

  -- Set the matrix to the new one.
  self.infoByLocation = layers
  return true
end
function MapLayer:printMe()
  local columns = #self.infoByLocation
  local rows = #self.infoByLocation[1]
  print(columns .. " x " .. rows)

  -- Iterate across columns
  for i, col in ipairs(self.infoByLocation) do
    if i < 10 then
      print("Row  " .. i .. ":")
    else
      print("Row " .. i .. ":")
    end

    -- Iterate across rows
    for j, row in ipairs(self.infoByLocation[i]) do
      print (self.infoByLocation[i][j])
    end
  end
end
return MapLayer
