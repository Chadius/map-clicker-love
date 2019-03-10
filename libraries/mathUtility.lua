-- TODO Test all of this.
local function mathBound (x, min, max)
  --[[ Ensures the number x is bound between numbers min and max.
    Args:
      x(number):
      min(number, optional, default=nil): If x is less than min, return min.
        If min is nil, there is no lower bound.
      max(number, optional, default=nil): If x is more than max, return max.
        If max is nil, there is no upper bound.

    Returns:
      A number.
  ]]

  local bounded_output = x

  if min ~= nil then
    bounded_output = math.max(bounded_output, min)
  end

  if max ~= nil then
    bounded_output = math.min(bounded_output, max)
  end

  return bounded_output
end

local function lerp (t, t1, x1, t2, x2)
  --[[ Use Linear IntERPolation to figure out what f(t) is,
    given (t1, x1) and (t2, x2).
    f(t) is of the form x = mt + b

  Args:
    t (number): The input.
    t1 (number): One known input.
    x1 (number): An output so that f(t1) = x1.
    t2 (number): Another known input.
    x2 (number): An output so that f(t2) = x2.

  Returns:
    A number.
  ]]

  -- If x1 == x2, then x never changes based on t. Just return x.
  if x1 == x2 then
    return x1
  end

  -- Calculate the slope
  local slope = (x2 - x1) / (t2 - t1)

  -- Calculate the offset, using x1 = (slope * t1) + offset
  local offset = x1 - (slope * t1)

  -- With offset and slope, apply f(t)
  return (slope * t) + offset
end

MathUtility = {
  bound = mathBound,
  clamp = mathBound,
  lerp = lerp,
  linear_interpolation = lerp,
}
return MathUtility
