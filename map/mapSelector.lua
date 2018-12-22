MapSelector={}
function MapSelector:new()
  self.column=nil
  self.row=nil
  return self
end
function MapSelector:selectTile(column, row)
  if column ~= nil then
    self.column = column
    self.row = row
  else
    -- If the user clicked off screen, deselect.
    self.column = nil
    self.row = nil
  end
end
