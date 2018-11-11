-- Sky RGB: 0.64, 0.73, 0.75 (HSV 190, 1.15, 0.75)
-- Wall RGB: 0.1, 0, 0.15 (HSV 280, 1, 0.15)
-- Ground RGB: 0.74, 0.75, 0.71 (HSV 75, 0.5, 0.75)
-- Rough RGB: 0.65, 0.55, 0.36 (HSV 39, 0.45, 0.65)

-- Color conversion widget.

local colorConverter = nil
local hsv = {h=0, s=0.5, v=0.5}
local rgb = {r=0.5, b=0.5, g=0.5}

function getRGB()
   return {
      r = rgb.r,
      g = rgb.g,
      b = rgb.b,
   }
end

function getHSV()
   return {
      h = hsv.h,
      s = hsv.s,
      v = hsv.v,
   }
end

function loadColorPicker()
   colorConverter = require "HSVtoRGB"

   -- Recalculate the rgb value.
   rgb.r, rgb.g, rgb.b = colorConverter.HSVToRGB(hsv.h, hsv.s, hsv.v)
end

function drawColorPicker()
   love.graphics.setColor(rgb.r, rgb.g, rgb.b)
   love.graphics.rectangle("fill", 20, 20, 600, 400)

   love.graphics.setColor(0.8,0.8,0.8)
   love.graphics.print("rgb " .. rgb.r .. ", " .. rgb.g .. ", " .. rgb.b, 100, 420,0,2,2)
   love.graphics.print("hsv " .. hsv.h .. ", " .. hsv.s .. ", " .. hsv.v, 100, 440,0,2,2)
end

function colorPickerKeypressed(key, scancode, isrepeat)
   keySpeed = 1
   if love.keyboard.isDown( 'lshift' ) then
      keySpeed = keySpeed * 2
   end
   if love.keyboard.isDown( 'lalt' ) then
      keySpeed = keySpeed * 5
   end

   -- left will rotate the hue negatively.
   if key == "left" then
      hsv.h = (hsv.h - keySpeed) % 360
   elseif key == "right" then
      -- right will rotate the hue positively.
      hsv.h = (hsv.h + keySpeed) % 360
   elseif key == "up" then
      -- up will increase the saturation.
      hsv.s = hsv.s + (0.01 * keySpeed)
      if hsv.s > 1 then
	 hsv.s = 1
      end
   elseif key == "down" then
      -- down will decrease the saturation.
      hsv.s = hsv.s - (0.01 * keySpeed)
      if hsv.s < 0 then
	 hsv.s = 0
      end
   elseif key == "a" then
      -- up will increase the value.
      hsv.v = hsv.v + (0.01 * keySpeed)
      if hsv.v > 1 then
	 hsv.v = 1
      end
   elseif key == "z" then
      -- down will decrease the value.
      hsv.v = hsv.v - (0.01 * keySpeed)
      if hsv.v < 0 then
	 hsv.v = 0
      end
   end

   -- Recalculate the rgb value.
   rgb.r, rgb.g, rgb.b = colorConverter.HSVToRGB(hsv.h, hsv.s, hsv.v)
end
