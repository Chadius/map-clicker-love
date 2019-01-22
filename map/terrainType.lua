--[[ Terrain type determines:
If you can walk on it
If you can fly over it
The movement cost to enter a map tile with this terrain
]]

local terrainTypeDefinition = {
  {
    id=1,
    description="concrete",
    movementCost=1,
    canStopOn=true,
    canFlyOver=true,
  },
  {
    id=2,
    description="grass",
    movementCost=2,
    canStopOn=true,
    canFlyOver=true,
  },
  {
    id=3,
    description="mud",
    movementCost=3,
    canStopOn=true,
    canFlyOver=true,
  },
  {
    id=4,
    description="wall",
    movementCost=nil,
    canStopOn=false,
    canFlyOver=false,
  },
  {
    id=5,
    description="pit",
    movementCost=1,
    canStopOn=false,
    canFlyOver=true,
  }
}

local function terrainTypesByField(field)
  --[[ Return terrain by the given field. ]]
  local sortedTerrain = {}
  for i, data in ipairs(terrainTypeDefinition) do
    sortedTerrain[data[field]] = data
  end
  return sortedTerrain
end

local TerrainTypes = {
  id=terrainTypesByField("id"),
  description=terrainTypesByField("description"),
}

return TerrainTypes
