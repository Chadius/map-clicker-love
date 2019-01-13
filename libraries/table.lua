function boolean_string(value)
  -- If it's a boolean print it out
  if value == true then
    return "true"
  else
    return "false"
  end
end

function printDictionary(table, indents)
  -- Print a list of all the keys and the the values in the table.
  for k, v in pairs(table) do
    local print_value = v
    if type(v) == "boolean" then
      print_value = boolean_string(v)
    end

    -- Recurse on tables.
    if type(v) == "table" then
      local table_indents = indents
      if indents == nil then
        table_indents = 1
      else
        table_indents = table_indents + 1
      end
      print(k)
      printDictionary(v, table_indents)
    else
      if indents ~= nil then
        local tabs = ""
        for i=1,indents do
          tabs = tabs .. "  "
        end

        print(tabs, k, print_value)
      else
        print(k, print_value)
      end
    end
  end
end
