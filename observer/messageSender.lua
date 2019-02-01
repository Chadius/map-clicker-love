--[[This supports the Observer design pattern.
When you want to send messages without specifying who observes it.

Senders register Observers and will notify all them with a message.
]]

local MessageSender={}
MessageSender.__index = MessageSender

function MessageSender:new(args)
  --[[ Create a new Sender.
  --]]
  local newSender = {}
  setmetatable(newSender,MessageSender)
  newSender.handler = nil
  newSender.observers = {}
  if args then
    newSender.handler = args.handler or nil
  end
  return newSender
end

function MessageSender:addObserver(observerOwner)
  --[[Register the observer so it can receive messages from this Sender.
  Args:
    observerOwner: observerOwner.observer refers to an Observer object.
  Returns:
    True upon success.
  ]]
  if observerOwner == nil then
    return false
  end

  -- Make sure the observer is not already registered.
  for i, obs in ipairs(self.observers) do
    if obs == observerOwner then
      return true
    end
  end

  -- Add the observer to the list of observers.
  table.insert(self.observers, observerOwner)
  return true
end

function MessageSender:removeObserver(observerOwner)
  --[[Unregister the observer so it no longer receives messages from this Sender.
  Args:
    observerOwner: observerOwner.observer refers to an Observer object.
  Returns:
    True upon success.
  ]]

--[[
  local index = nil
  for i, obs in ipairs(self.observers) do
    if obs == observerOwner then
      index = i
    end
  end

  table.remove(self.observers, index)
  return true
  ]]
end

function MessageSender:notify(message, payload)
  --[[ Contact all observers and send them information.
  Args:
    message (string): A human-readable message.
    payload (table) : A table containing custom information.
  Returns:
    True upon success.
  ]]

  -- For each observer owner
  for i, obs in ipairs(self.observers) do
    -- Notify the observer.
    obs.observer:onNotify(self, obs, message, payload)
  end
end
return MessageSender
