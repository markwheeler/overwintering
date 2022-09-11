local Json = include("lib/json")

local Trove = {}

Trove.MAX_NUM_CLUSTERS = 4 -- Must match data_process.lua

Trove.bird_data = {}


local function load_species_list(file_path)
  local input_json = ""
  for line in io.lines(file_path) do
    input_json = input_json .. line
  end

  local species_list = Json.decode(input_json)
  print("Loaded " .. #species_list .. " species from " .. file_path)
  return species_list
end

local function load_bird(file_path)

  print("Loading " .. file_path)
  local start_time = os.time()

  if not util.file_exists(file_path) then
    print("No file " .. file_path )
    return nil
  end

  local input_json = ""
  for line in io.lines(file_path) do
    input_json = input_json .. line
  end

  local bird = Json.decode(input_json)
  
  if bird.num_slices > 0 then
    print("Loaded " .. bird.english_name .. " in " .. os.difftime(os.time(), start_time) .. " seconds")
    return bird
  else
    print("Could not load " .. file_path)
    return nil
  end

end


function Trove.get_bird(bird_index)
  return Trove.bird_data[bird_index]
end

function Trove.get_slice(bird_index, slice_index)
  slice_index = util.wrap(slice_index, 1, Trove.get_bird(bird_index).num_slices)
  return Trove.get_bird(bird_index).slices[slice_index]
end

function Trove.interp_slice_value(bird_index, start_slice_index, end_slice_index, progress, value_name)
  return util.linlin(0, 1, Trove.get_slice(bird_index, start_slice_index)[value_name], Trove.get_slice(bird_index, end_slice_index)[value_name], progress)
end

function Trove.load_birds(data_folder)

  local start_time = os.time()

  local species_list = load_species_list(data_folder .. "species_list.json")
  for _, v in ipairs(species_list) do
    local file_path = data_folder .. v.species_id .. ".json"
    local bird = load_bird(file_path)
    if bird then table.insert(Trove.bird_data, bird) end
  end

  print("Loaded all species data in " .. os.difftime(os.time(), start_time) .. " seconds")

end

return Trove
