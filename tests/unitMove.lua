--[[
RAW NOTES

Situations:
- I have 3 visions. Show everything I can see on this map
- Can i reach this location with only 3 move? What if a wall blocks my way?
- I want to reach this location. Give me the shortest route.

Each tile asks 3 questions:
- Can units stop on me?
- Can units pass over me?
- How much movement does it cost to enter my square?

         | Stop? | Pass? | Cost
Wall     | N     | N     | n/a
Concrete | Y     | Y     | 1
Grass    | Y     | Y     | 2
Mud      | Y     | Y     | 3
Pit      | N     | Y     | 1

UnitMove class
needs Map
needs MapUnit
- location
- move type
- move distance

function ChartCourse(destination)
Return a single path to the destination, assuming inifinite turns.
Returns nil if the trip is impossible.

function NextWaypoint(course)
Following the course, return the next location within move distance.
Returns nil if:
- Unit is not on the path
- Unit has completed the path and is on the end.
- Unit does not have enough move to actually move.

function GetTilesWithinMovement()
Returns a MapSearch object showing all of the tiles within movement range.

MoveType class
TODO

TODO: Add MoveType to MapUnits

Unit Tests!
5x5 map
  | 1     | 2      | 3      | 4      | 5      |
-----------------------------------------------
1 |       | Mud    |        |        |        |
2 | Grass |        |        |        |        |
3 |       |        |        |        |        |
4 |       |        | Wall   |        | Pit    |
5 |       |        | Wall   |        |        |

Test 0 movement
Unit starts at (3,2)
Move distance is 0
GetTilesWithinMovement returns a table with only 1 element, (3,2)
ChartCourse to (3,1), returns a path with 2 items, (3,2) to (3,1)
NextWaypoint returns nil because you lack movement to get there

Test 1 movement
Unit starts at (1,3)
Move distance is 1
Move type is on foot
GetTilesWithinMovement returns a table with elements, (1,3) (2,3) (1, 4)
ChartCourse to (1,1), returns nil because you lack movement.
NextWaypoint returns nil because you passed it nil.
]]
