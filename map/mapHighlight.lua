--[[ Map information, stored by column and row.
--]]

local MapHighlight = {}
MapHighlight.__index = MapHighlight

function MapHighlight:new()
  --[[ Create a new path.
  --]]
  local newHighlight = {}
  setmetatable(newHighlight,MapHighlight)

  -- A 2D matrix. If [column][map] is not nil, then that location was highlighted.
  newHighlight.highlights = {}

  return newHighlight
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
function MapHighlight:copyFromMapMatrix(source)
  --[[ Copy values from the given 2D matrix.
  Args:
    source: Nested table. The first level has the columns and the child is a
      table with the rows. If child value is not nil, then the location is
      highlighted.

  Returns:
    true if successful, false otherwise.
  --]]

  -- Copy the source into a new table.
  self.highlights = copyMatrix(source)
end
function MapHighlight:getHighlightedMap()
  --[[ Returns a 2D Nested Table with [column][row] locations.
  --]]
  return copyMatrix(self.highlights)
end
function MapHighlight:getHighlightedList()
  --[[ Returns a list of {column, row} tables.
  -- Each item is a highlighted point.
  --]]

  local summary = {}

  -- Iterate from each column
  for i, column in ipairs(self.highlights) do
    -- Iterate from each row
    for j, row in ipairs(self.highlights[i]) do
      -- If it's not nil, add it to the visited locations
      table.insert(summary, {column=i, row=j, highlight=self.highlights[i][j]})
    end
  end

  return summary
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

  if column > #self.highlights then
    return false
  end

  if row > #(self.highlights[1]) then
    return false
  end

  return true
end
function MapHighlight:getHighlight(column, row)
  --[[ Check if the map location at (column, row) has been highlighted.
  Args:
    column(number) : Map column.
    row(number) : Map row.

  Returns:
    the value at that location, usually a boolean.
    nil if the location is not applicable (usually off the map.)
  ]]

  -- Make sure column and row is on the highlight.
  if isLocationValid(self, column, row) == false then
    return nil
  end

  -- Get the value.
  return self.highlights[column][row]
end
function MapHighlight:setHighlight(column, row, value)
  --[[ Change whether the location at (column, row) is highlighted.
  Args:
    column(number)        : Map column.
    row(number)           : Map row.
    value: Value to set this location to.

  Returns:
    true upon success, false otherwise.
  ]]

  -- Make sure column and row is on the highlight.
  if isLocationValid(self, column, row) == false then
    return false
  end

  -- Set the value.
  self.highlights[column][row] = value
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
function MapHighlight:clear(newValue)
  --[[ Sets the highlights of all the locations on the map.
  Args:
    newValue(default=false): Sets all of the values on this map.

  Returns:
    true upon success, false otherwise.
  ]]
  return fillMatrixWithValue(self.highlights, newValue)
end
function MapHighlight:setDimensions(columns, rows, defaultValue)
  --[[ Resizes the map highlight.
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
  local highlights = {}

  -- Iterate from each column
  for i=1, columns do
    highlights[i] = {}
    -- Iterate from each row
    for j=1, rows do
      highlights[i][j] = false
    end
  end

  local fillValue = false
  if defaultValue ~= nil then
    fillValue = defaultValue
  end

  -- Fill the map with defaultValue
  fillMatrixWithValue(highlights, fillValue)

  -- Copy the current highlights into the new matrix.
  copyMatrix(self.highlights, highlights)

  -- Set the matrix to the new one.
  self.highlights = highlights
  return true
end
return MapHighlight
