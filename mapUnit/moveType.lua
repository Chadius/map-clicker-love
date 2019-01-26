--[[ Move type determines:
If you pay minimum movement costs when travelling
If you can cross pits
]]

local moveTypeDefinition = {
  {
    id=1,
    description="walk",
    minimumMoveCost=false,
    canCrossPits=false,
  },
  {
    id=2,
    description="tiptoe",
    minimumMoveCost=true,
    canCrossPits=false,
  },
  {
    id=3,
    description="fly",
    minimumMoveCost=true,
    canCrossPits=true,
  },
}

local function moveTypesByField(field)
  --[[ Return move by the given field. ]]
  local sortedMoves = {}
  for i, data in ipairs(moveTypeDefinition) do
    sortedMoves[data[field]] = data
  end
  return sortedMoves
end

local MoveTypes = {
  id=moveTypesByField("id"),
  description=moveTypesByField("description"),
}

return MoveTypes
