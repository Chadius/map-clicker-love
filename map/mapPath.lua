--[[ A map path tracks a list of locations and costs.
--]]

local MapPath = {}
MapPath.__index = MapPath

function MapPath:new()
  --[[ Create a new path.
  --]]
  local newPath = {}
  setmetatable(newPath,MapPath)
  newPath.steps = {}
  return newPath
end
function MapPath:addStep(column, row, moveCost)
  --[[ Adds the next step to this path.
  --]]

  -- Get the total movement cost of this path.
  local totalCost = self:totalCost()

  -- Create a new Step, using the column, row, individual move cost and the new cost.
  local newStep = {
    column=column,
    row=row,
    cost=moveCost,
    totalCost=totalCost+moveCost
  }

  -- Add to the steps.
  table.insert(self.steps, newStep)
end
function MapPath:topStep()
  --[[ Returns the last step taken.
  --]]
  local numSteps = #self.steps
  if numSteps < 1 then
    return nil
  end
  return self.steps[numSteps]
end
function MapPath:addStepsToPath(destinationMapPath)
  --[[ Add all of the steps from self to the other path.
  --]]
  for i, step in ipairs(self.steps) do
    destinationMapPath:addStep(step.column, step.row, step.cost)
  end
end
function MapPath:clone()
  --[[ Returns a new path with the same steps as self.
  --]]
  local newPath = MapPath:new()
  self.addStepsToPath(newPath)
  return newPath
end
function MapPath:totalCost()
  --[[ Returns the total costs of the steps.
  --]]
  local numSteps = #self.steps

  -- If there are no steps the cost is 0.
  if numSteps < 1 then
    return 0
  end

  -- Otherwise look at the last step.
  return self.steps[numSteps].totalCost
end
function MapPath:printMe()
  --[[ Print a string representation.
  --]]
  for i, step in ipairs(self.steps) do
    print(i .. ": (" .. step.column .. "," .. step.row .. ") Cost " .. step.cost .. ", Total " .. step.totalCost)
  end
end

return MapPath
