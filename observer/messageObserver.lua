--[[This supports the Observer design pattern.
When you want to send messages without specifying who observes it.

Observers react to messages they receive through the onNotify handler.
]]

local MessageObserver = {}
MessageObserver.__index = MessageObserver

function MessageObserver:new(args)
  --[[ Create a new Observer.
  --]]
  local newObserver = {}
  setmetatable(newObserver,MessageObserver)
  newObserver.handler = nil
  if args then
    newObserver.handler = args.handler or nil
  end
  return newObserver
end

function MessageObserver:onNotify(sender, observerOwner, message, payload)
  --[[Sender classes will notify observers, sending a payload.
  this:handler will be called.

  Args:
    sender          : The object responsible for sending the data.
    observerOwner   : The parent object which owns this object.
    message (string): A human-readable message. Do not modify this.
    payload         : A table containing important data. Do not modify this.
  Returns:
    True upon success.
  ]]

  -- Call the handler.
  self.handler(observerOwner, sender, message, payload)
end

return MessageObserver
