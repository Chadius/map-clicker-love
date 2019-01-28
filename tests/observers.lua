local lunit = require "libraries/unitTesting/lunitx"
if _VERSION >= 'Lua 5.2' then
    _ENV = lunit.module('enhanced','seeall')
else
    module( "enhanced", package.seeall, lunit.testcase )
end

--[[
Implementing an Observer/Subject pattern.

Subjects push messages and requests using notify().
Subjects have Observers they manage using addObserver() and removeObserver().

Observers react in onNotify()

MapSelector clicks
notifies MapUnit
notifies MapUnitDrawing
notifies MapUnit to say it arrived
]]

local piggyBankHandler = funcion piggyBankOnNotify(self, data)
  self.piggy_bank_total_change = self.piggy_bank_total_change + data.money
end

local findPocketChangeFunction = funcion findPocketChange(self, cash_found)
  self.message_sender.notify(self, "found some change", {money=cash_found})
end

function setup()
  --[[SetUp: Reset piggy bank to 0]]
  piggy_bank_total_change = 0
end

function test_observer_and_sender()
  --[[Piggy bank is an Observer.
  Homer finds some pocket change and sends a message.
  The Piggy bank should observe the message and update the piggy bank.
  ]]

  local piggy_bank = {
    observer=Observer:new({handler=piggyBankHandler})
    piggy_bank_total_change = 0,
  }

  local homer = {
    message_sender = MessageSender:new()
    find_change = findPocketChangeFunction
  }
  homer.message_sender:addObserver(piggy_bank)

  homer.message_sender:find_change(10)

  assert_equal(10, piggy_bank.piggy_bank_total_change)
end

--[[Piggy bank is an Observer.
Homer and Bart both send messages.
The Piggy bank should get money from both sources.
]]

--[[2 Piggy Banks (Observers) and 1 Homer (sender).
Every time Homer finds pocket change, both Piggy Banks should record the money.
]]

--[[Piggy bank is an Observer. Homer and Bart both send messages.
Bart can remove the Piggy bank as an observer.
The Piggy bank should record Homer's messages but not Bart's.
]]
