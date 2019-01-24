--[[ Map information, stored by column and row.
--]]

local function transposeMatrix(matrix)
  --[[ Transpose the given matrix, so (i,j) maps to (j,i).

  Args:
    matrix: A nested list of lists. Each inner list should have the same length as the first one.

  Returns:
    A table with transposed values.
  ]]

  -- Get the dimensions of the source.
  local source_rows = #matrix
  local source_columns = #matrix[1]

  transposed_matrix = {}

  for i=1, source_columns do
    transposed_matrix[i] = {}
    for j=1, source_rows do
      transposed_matrix[i][j] = matrix[j][i]
    end
  end

  return transposed_matrix
end

local MapLayer = {}
MapLayer.__index = MapLayer

function MapLayer:new(options)
  --[[Constructor.

  Args:
    options(optional, default{}): Use this to set up and fill the values.

      You can specify the data, using a table.
        data(table, optional)                       : Nested list, assuming data[row][column]. We will transpose this to fit our internal structure (see transpose option.)
        transpose(boolean, optional, default=true)  : If data follows data[column][row], set this flag to false.

      You can also set the dimensions and a fill value.
        columns(number, optional)             : see setDimensions(). rows is required.
        rows(number, optional)                : see setDimensions(). columns is required.
        defaultValue(optional, default=false) : see setDimensions().

      You can set individual data points as well.
        sparse_data(optional): A list of tables. Each table needs these keys:
          column
          row
          value
  --]]
  local newLayer = {}
  setmetatable(newLayer,MapLayer)

  --[[Internal storage. A nested list of lists.
    It's designed so infoByLocation[column][row] works.
    As a result, the outer list is by column, and the inner lists have 1 value for each row.
  ]]
  newLayer.infoByLocation = {}

  if options then
    local columns = nil
    local rows = nil
    local defaultValue = false

    if options.data ~= nil then
      if options.transpose == nil or options.transpose then
        columns = #options.data[1]
        rows = #options.data
      else
        columns = #options.data
        rows = #options.data[1]
      end
    end

    if options.columns ~= nil and options.rows ~= nil then
      columns = options.columns
      rows = options.rows
      if options.defaultValue ~= nil then
        defaultValue = options.defaultValue
      end
    end

    if columns ~= nil and rows ~= nil then
      local data_source = options.data
      if options.transpose == nil or options.transpose then
        if data_source then
          data_source = transposeMatrix(options.data)
        end
      end
      newLayer:setDimensions(columns, rows, defaultValue, data_source)
    elseif options.data ~= nil then
      local transpose = true
      if options.transpose ~= nil then transpose = options.transpose end
      newLayer:copyFromMapMatrix(options.data, transpose)
    end

    -- Fill in sparse data, if it's supplied.
    if options.sparse_data then
      for i, datum in ipairs(options.sparse_data) do
        newLayer:setLayer(datum.column, datum.row, datum.value)
      end
    end
  end

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
function MapLayer:copyFromMapMatrix(source, transpose)
  --[[ Copy values from the given 2D matrix.
  Args:
    source: Nested list of lists. source[column][row] should refer to the intended value.
    transpose: If true, source is organized by source[row][column] and we'll transpose it.

  Returns:
    true if successful, false otherwise.
  --]]

  local new_source = source
  if transpose == true then
    new_source = transposeMatrix(source)
  end

  -- Copy the source into a new table.
  self.infoByLocation = copyMatrix(new_source)
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
local function fillMatrixWithValue(matrix, value, data)
  --[[ Fill all values of the 2D nested table.
  Args:
    matrix: A 2D Nested table (will be modified). The first level has the
      columns and the child is a table with the rows.
    value: The value to set each entry to.
    data(optional): See setDimensions().

  Returns:
    true if successful.
  ]]

  -- Iterate from each column
  for i, column in ipairs(matrix) do
    -- Iterate from each row
    for j, row in ipairs(matrix[i]) do

      -- If a data table was provided, copy from there.
      local fill_value = value
      if data and data[i] and data[i][j] ~= nil then fill_value = data[i][j] end
      -- Set the value.
      matrix[i][j] = fill_value
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
function MapLayer:setDimensions(columns, rows, defaultValue, data)
  --[[ Resizes the map layer.
  If more columns and rows are added, fill the defaultValue for new locations.
  If there are fewer columns or rows, the highest number columns/rows are truncated.

  Args:
    columns(number)                       : Columns in the new map.
    rows(number)                          :
    defaultValue(optional, default=false) : Sets all of the values for new columns and rows.
    data(optional, default={})            : A list of lists that stores values in data[column][row]. Copy these values where they can be found.

  Returns:
    true upon success, false otherwise.
  ]]

  if columns < 1 or rows < 1 then
    return false
  end

  -- Make new map matrix of new size
  local layerData = {}

  -- Iterate from each column
  for i=1, columns do
    layerData[i] = {}
    -- Iterate from each column
    for j=1, rows do
      layerData[i][j] = false
    end
  end

  local fillValue = false
  if defaultValue ~= nil then
    fillValue = defaultValue
  end

  -- Fill the map with defaultValue
  fillMatrixWithValue(layerData, fillValue, data)

  -- Copy the current layers into the new matrix.
  --
  copyMatrix(self.infoByLocation, layerData)

  -- Set the matrix to the new one.
  self.infoByLocation = layerData
  return true
end
function MapLayer:getDimensions()
  if self.infoByLocation == nil then return {columns=0,rows=0} end
  if self.infoByLocation == {} then return {columns=0,rows=0} end
  return {
    columns = #self.infoByLocation,
    rows = #self.infoByLocation[1]
  }
end
function MapLayer:columns()
  return self:getDimensions().columns
end
function MapLayer:rows()
  return self:getDimensions().rows
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
