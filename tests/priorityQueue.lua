PriorityQueue = require "map/priorityQueue"
lunit = require "libraries/unitTesting/lunitx"

if _VERSION >= 'Lua 5.2' then
    _ENV = lunit.module('enhanced','seeall')
else
    module( "enhanced", package.seeall, lunit.testcase )
end

local foobar = nil

function setup()
  foobar = "Hello World"
end

function teardown()
  foobar = nil
end

function test_empty_priority_queue()
  -- A new Priority Queue is empty.
  pq = PriorityQueue()
  assert_true(pq:empty())
end

function test_add_one_entry()
  --[[ Add 3c
  Top should be 3c
  Pop to confirm
  PQ is now empty
  --]]

  pq = PriorityQueue()
  pq:put("c", 3)
  top = pq:pop()
  assert_equal(top, "c")
  assert_true(pq:empty())
end

function test_priority_matters()
  -- When you add items, the lowest priority should be at the front of the queue.
  pq = PriorityQueue()

  -- Add 2a, 1b.
  pq:put("a", 2)
  pq:put("b", 1)

  -- Top should be 1b.
  top = pq:pop()
  assert_equal(top, "b")
end

function test_tied_priority_order_matters()
  -- Adding items with the same priority means the first added item is popped first.
  pq = PriorityQueue()

  -- Add 4d, 5e, 4q
  pq:put("d", 4)
  pq:put("e", 5)
  pq:put("q", 4)

  -- Top is 4d (lowest value and added first)
  top = pq:pop()
  assert_equal(top, "d")

  -- Top is now 4q (lowest value)
  top = pq:pop()
  assert_equal(top, "q")

  -- Top is now 5e (remaining item)
  top = pq:pop()
  assert_equal(top, "e")

  assert_true(pq:empty())
end
