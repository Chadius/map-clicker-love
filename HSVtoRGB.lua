-- https://gist.github.com/GigsD4X/8513963

local colorConverter = {}

colorConverter.HSVToRGB = function ( hue, saturation, value )
   -- Returns the RGB equivalent of the given HSV-defined color
   -- hue is between 0 and 360.
   -- saturation, value are between 0 and 1

   -- If it's achromatic, just return the value
   if saturation == 0 then
      return value, value, value;
   end;

   -- Get the hue sector
   local hue_sector = math.floor( hue / 60 );
   local hue_sector_offset = ( hue / 60 ) - hue_sector;

   local p = value * ( 1 - saturation );
   local q = value * ( 1 - saturation * hue_sector_offset );
   local t = value * ( 1 - saturation * ( 1 - hue_sector_offset ) );

   if hue_sector == 0 then
      return value, t, p;
   elseif hue_sector == 1 then
      return q, value, p;
   elseif hue_sector == 2 then
      return p, value, t;
   elseif hue_sector == 3 then
      return p, q, value;
   elseif hue_sector == 4 then
      return t, p, value;
   elseif hue_sector == 5 then
      return value, p, q;
   end;
end;

colorConverter.RGBToHSV = function ( red, green, blue )
   -- Returns the HSV equivalent of the given RGB-defined color
   -- (adapted from some code found around the web)

   local hue, saturation, value;

   local min_value = math.min( red, green, blue );
   local max_value = math.max( red, green, blue );

   value = max_value;

   local value_delta = max_value - min_value;

   -- If the color is not black
   if max_value ~= 0 then
      saturation = value_delta / max_value;

      -- If the color is purely black
   else
      saturation = 0;
      hue = -1;
      return hue, saturation, value;
   end;

   if red == max_value then
      hue = ( green - blue ) / value_delta;
   elseif green == max_value then
      hue = 2 + ( blue - red ) / value_delta;
   else
      hue = 4 + ( red - green ) / value_delta;
   end;

   hue = hue * 60;
   if hue < 0 then
      hue = hue + 360;
   end;

   return hue, saturation, value;
end;

return colorConverter
