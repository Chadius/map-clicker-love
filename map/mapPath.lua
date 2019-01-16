--[[ A map path tracks a list of locations and costs.
--]]

local PriorityQueue = require "map/priorityQueue"

MapPath = {}
function MapPath:new()
  --[[ Create a new path.
  --]]
  self.steps = []
  return self
end
function MapPath:addStep(column, row, moveCost)
  --[[ Adds the next step to this path.
  --]]

  -- Get the total movement cost of this path.
  local totalCost = self.totalCost()

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
function MapPath:clone()
  --[[ Returns a new MapPath with the same steps.
  --]]
  local newMapPath = MapPath:new()

  for i, step in self.steps do
    newMapPath:addStep(step)
  end

  return newMapPath
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
  return self.steps["numSteps"].totalCost
end
function MapPath:__string()
  --[[ Print a string representation.
  --]]
  for i, step in self.steps do
    print(i .. ": (" .. step.column .. "," .. step.row .. ") Cost " .. step.cost .. ", Total " .. step.totalCost)
  end
end
