local Trove = {}

Trove.bird_data = {}

local function load_csv(file_path)

  local bird = {
    name = file_path,
    slices = {},
    num_slices = 0,
    min_x = 180,
    max_x = -180,
    min_y = 90,
    max_y = -90
  }

  local first = true

  for line in io.lines(file_path) do

    -- Skip headers
    if first then
      first = false

    else

      -- Split the line
      local split = {}
      for val in string.gmatch(line, '([^,]+)') do
        table.insert(split, val)
      end

      local week, year = tonumber(split[3]), tonumber(split[4])

      -- Add a new slice if need be
      if bird.num_slices == 0 or week ~= bird.slices[bird.num_slices].week or year ~= bird.slices[bird.num_slices].year then
        local slice = {
          week = week,
          year = year,
          points = {}
        }
        table.insert(bird.slices, slice)
        bird.num_slices = bird.num_slices + 1
      end
      
      -- Add point
      local point = {
        x = tonumber(split[1]),
        y = tonumber(split[2])
      }
      table.insert(bird.slices[bird.num_slices].points, point)

      -- Store min/max
      if point.x < bird.min_x then bird.min_x = point.x end
      if point.x > bird.max_x then bird.max_x = point.x end
      if point.y < bird.min_y then bird.min_y = point.y end
      if point.y > bird.max_y then bird.max_y = point.y end
      
    end
  end

  if bird.num_slices > 0 then
    table.insert(Trove.bird_data, bird)
    print("Added bird", bird.name)
  else
    print("Could not add bird", bird.name)
  end

end

function Trove.load_folder(folder_path)

  local files = util.scandir(folder_path)
  for _, v in ipairs(files) do

    if string.sub(v:lower(), -4, -1) == ".csv" then
      load_csv(folder_path .. v)
    else
      print("Skipped", v)
    end

  end

end

return Trove