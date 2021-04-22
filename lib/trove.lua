
local Trove = {}

Trove.bird_data = {}

function Trove.load_folder(path)

  -- TODO ref Timber Player
  
  for i = 1, 3 do
    Trove.bird_data[i] = {
      slices = {},
      name = "None " .. i
    }
  end

end

return Trove