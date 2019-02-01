local MessageObserver = require "observer/messageObserver"
local MessageSender = require "observer/messageSender"

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

local function piggyBankOnNotify(self, sender, message, data)
  self.piggy_bank_total_change = self.piggy_bank_total_change + data.money
end

local function findPocketChange(self, cash_found)
  self.message_sender:notify("found some change", {money=cash_found})
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
    observer=MessageObserver:new({handler=piggyBankOnNotify}),
    piggy_bank_total_change = 0
  }

  local homer = {
    message_sender = MessageSender:new(),
    find_change = findPocketChange
  }
  homer.message_sender:addObserver(piggy_bank)
  homer:find_change(10)

  assert_equal(10, piggy_bank.piggy_bank_total_change)
end

function test_multiple_registration_works_once()
  --[[Piggy bank is an Observer.
  Piggy bank is registered twice.
  Homer finds some pocket change and sends a message.
  The Piggy bank should observe the message and update the piggy bank once.
  ]]

  local piggy_bank = {
    observer=MessageObserver:new({handler=piggyBankOnNotify}),
    piggy_bank_total_change = 0
  }

  local homer = {
    message_sender = MessageSender:new(),
    find_change = findPocketChange
  }
  homer.message_sender:addObserver(piggy_bank)
  homer.message_sender:addObserver(piggy_bank)
  homer:find_change(10)

  assert_equal(10, piggy_bank.piggy_bank_total_change)
end

function test_multiple_senders_affect_observer()
  --[[Piggy bank is an Observer.
  Homer and Bart both send messages.
  The Piggy bank should get money from both sources.
  ]]

  local piggy_bank = {
    observer=MessageObserver:new({handler=piggyBankOnNotify}),
    piggy_bank_total_change = 0
  }

  local homer = {
    message_sender = MessageSender:new(),
    find_change = findPocketChange
  }

  local bart = {
    message_sender = MessageSender:new(),
    find_change = findPocketChange
  }

  homer.message_sender:addObserver(piggy_bank)
  bart.message_sender:addObserver(piggy_bank)
  homer:find_change(10)
  bart:find_change(5)

  assert_equal(15, piggy_bank.piggy_bank_total_change)
end

function test_multiple_observers_get_same_message()
  --[[2 Piggy Banks (Observers) and 1 Homer (sender).
  Every time Homer finds pocket change, both Piggy Banks should record the money.
  ]]
  local piggy_bank1 = {
    observer=MessageObserver:new({handler=piggyBankOnNotify}),
    piggy_bank_total_change = 0
  }

  local piggy_bank2 = {
    observer=MessageObserver:new({handler=piggyBankOnNotify}),
    piggy_bank_total_change = 5
  }

  local homer = {
    message_sender = MessageSender:new(),
    find_change = findPocketChange
  }
  homer.message_sender:addObserver(piggy_bank1)
  homer.message_sender:addObserver(piggy_bank2)
  homer:find_change(10)

  assert_equal(10, piggy_bank1.piggy_bank_total_change)
  assert_equal(15, piggy_bank2.piggy_bank_total_change)
end

function test_sender_remove_observer()
  --[[Piggy bank is an Observer. Homer and Bart both send messages.
  Bart can remove the Piggy bank as an observer.
  The Piggy bank should record Homer's messages but not Bart's.
  ]]
  local piggy_bank = {
    observer=MessageObserver:new({handler=piggyBankOnNotify}),
    piggy_bank_total_change = 0
  }

  local homer = {
    message_sender = MessageSender:new(),
    find_change = findPocketChange
  }

  local bart = {
    message_sender = MessageSender:new(),
    find_change = findPocketChange
  }

  homer.message_sender:addObserver(piggy_bank)
  bart.message_sender:addObserver(piggy_bank)
  homer:find_change(10)
  bart:find_change(5)

  assert_equal(15, piggy_bank.piggy_bank_total_change)

  -- Bart removes the piggy bank as an observer. It should not receive his messages.
  bart.message_sender:removeObserver(piggy_bank)
  bart:find_change(5)
  assert_equal(15, piggy_bank.piggy_bank_total_change)

  -- Homer can continue to send messages.
  homer:find_change(15)
  assert_equal(30, piggy_bank.piggy_bank_total_change)
end

local function piggyBankOnNotifyAddExtraObserver(self, sender, message, data)
  -- Try to modify the observer list
  sender:addObserver(self.extra_observer)

  -- Now add the money.
  self.piggy_bank_total_change = self.piggy_bank_total_change + data.money
end

local function findPocketChange(self, cash_found)
  self.message_sender:notify("found some change", {money=cash_found})
end

function test_cannot_modify_observers_while_notifying()
  --[[Piggy bank is an Observer.
  When receiving a message it tries to add another piggy bank as an observer.
  Homer finds some pocket change and sends a message.
  The observer list is not modified until the notify ends.
  ]]

  local piggy_bank2 = {
    observer=MessageObserver:new({handler=piggyBankOnNotify}),
    piggy_bank_total_change = 0
  }

  local piggy_bank1 = {
    observer=MessageObserver:new({handler=piggyBankOnNotifyAddExtraObserver}),
    extra_observer=piggy_bank2,
    piggy_bank_total_change = 0
  }

  local homer = {
    message_sender = MessageSender:new(),
    find_change = findPocketChange
  }
  homer.message_sender:addObserver(piggy_bank1)
  homer:find_change(10)

  assert_equal(10, piggy_bank1.piggy_bank_total_change)

  -- There should be 2 observers.
  assert_equal(2, #homer.message_sender.observers)

  -- This observer was added midway through a notification. It should not have been called during it.
  assert_equal(0, piggy_bank2.piggy_bank_total_change)
end
