-- Process CSV into multiple JSON files

package.path = package.path .. ";../lib/?.lua;"
local Json = require "json"
local Clustering = require "clustering"

local MAX_NUM_CLUSTERS = 4
local ROUND_QUANT = 0.001 -- This just helps keep the output file size down

local function round(number, quant)
  if quant == 0 then
    return number
  else
    return math.floor(number/(quant or 1) + 0.5) * (quant or 1)
  end
end

local function linlin(slo, shi, dlo, dhi, f)
  if f <= slo then
    return dlo
  elseif f >= shi then
    return dhi
  else
    return (f-slo) / (shi-slo) * (dhi-dlo) + dlo
  end
end

local function table_print(t)
  for k, v in pairs(t) do
    print(k .. "\t\t" .. tostring(v))
  end
end

local function table_sort_by_values(t, ...)
  local a = {...}
  table.sort(
    t,
    function(u, v)
      for i = 1, #a do
        if u[a[i]] > v[a[i]] then
          return false
        end
        if u[a[i]] < v[a[i]] then
          return true
        end
      end
    end
  )
end

local function normalize_point(x, y, bird_x_offset, bird_y_offset, bird_scale)
  x = linlin(-180, 180, 0, 1, (x - bird_x_offset) * bird_scale)
  y = linlin(-90, 90, 0, 1, (y - bird_y_offset) * bird_scale)
  return x, y
end

local function load_csv(file_path)
  local DELIMITERS = ";\r\n"

  local data = {}
  local line_num = 0
  local attributes = {}

  for line in io.lines(file_path) do
    line_num = line_num + 1

    if line_num == 1 then
      -- Get attribute names from headers
      for val in string.gmatch(line, "([^" .. DELIMITERS .. "]+)") do
        table.insert(attributes, val)
      end
    else
      -- Split the row
      local row = {}
      local count = 1
      for v in string.gmatch(line, "([^" .. DELIMITERS .. "]+)") do
        local value = v
        if attributes[count] ~= "species_id" then
          value = tonumber(value)
        end
        row[attributes[count]] = value
        count = count + 1
      end
      table.insert(data, row)
    end
  end

  print("Read " .. line_num .. " rows from " .. file_path)
  return data
end


local function load_species_list(file_path)
  local input_json = ""
  for line in io.lines(file_path) do
    input_json = input_json .. line
  end

  local species_list = Json.decode(input_json)
  print("Loaded " .. #species_list .. " species from " .. file_path)
  return species_list
end


local function split_by_species(data, species_list)
  local split_data = {}

  local count = 0
  for _, v in ipairs(data) do
    if not split_data[v.species_id] then
      split_data[v.species_id] = {}
      count = count + 1
    end
    table.insert(split_data[v.species_id], v)
  end

  print("Found " .. count .. " species in input CSV")
  return split_data
end


local function increment_week(week, year)
  week = week + 1
  if week > 52 then
    week = 1
    year = year + 1
  end
  return week, year
end


local function create_slice(week, year)
  local slice = {
    week = week,
    year = year,
    area_norm = 0,
    density_norm = 0,
    num_points_norm = 0,
    points = {},
    clusters = {},
    min_x_norm = 0,
    max_x_norm = 0,
    min_y_norm = 0,
    max_y_norm = 0,
    -- Temp below
    area = 0,
    density = 0,
    num_points = 0,
    min_x = 180,
    max_x = -180,
    min_y = 90,
    max_y = -90,
  }
  return slice
end


local function create_bird(bird_data, species)
  -- Sort
  table_sort_by_values(bird_data, "year", "week", "y", "x")

  -- Create bird object
  local bird = {
    species_id = species.species_id,
    latin_name = species.latin,
    english_name = species.english,
    num_slices = 0,
    slices = {}
  }

  local slice

  for _, v in ipairs(bird_data) do
    -- Add a new slice if need be
    if bird.num_slices == 0 or v.week ~= bird.slices[bird.num_slices].week or v.year ~= bird.slices[bird.num_slices].year then

      -- Check if we need to fill in a gap with empty slices
      if bird.num_slices > 0 then
        local expected_week, expected_year = increment_week(bird.slices[bird.num_slices].week, bird.slices[bird.num_slices].year)

        while expected_week ~= v.week do  
          slice = create_slice(expected_week, expected_year)
          table.insert(bird.slices, slice)
          bird.num_slices = bird.num_slices + 1
          expected_week, expected_year = increment_week(expected_week, expected_year)
        end
      end

      slice = create_slice(v.week, v.year)
      table.insert(bird.slices, slice)
      bird.num_slices = bird.num_slices + 1
    end

    -- Add point
    local point = {
      x = v.x,
      y = v.y
    }
    table.insert(bird.slices[bird.num_slices].points, point)
    slice.num_points = slice.num_points + 1
  end

  print("Created " .. bird.num_slices .. " slices for " .. bird.species_id)

  return bird
end

local function process_bird(bird)

  local AREA_GRID_COLS = 20
  local AREA_GRID_ROWS = AREA_GRID_COLS / 2

  local min_x, max_x = 180, -180
  local min_y, max_y = 90, -90
  local min_points, max_points = 9999999, 0
  local min_area, max_area = 9999999, 0
  local min_density, max_density = 9999999, 0
  local min_cluster_points, max_cluster_points = 9999999, 0

  
  for _, s in ipairs(bird.slices) do
    
    -- Store slice min/max xy
    for _, p in ipairs(s.points) do
      if p.x < s.min_x then
        s.min_x = p.x
      end
      if p.x > s.max_x then
        s.max_x = p.x
      end
      if p.y < s.min_y then
        s.min_y = p.y
      end
      if p.y > s.max_y then
        s.max_y = p.y
      end
    end

    -- Store overall min/max xy
    if s.min_x < min_x then
      min_x = s.min_x
    end
    if s.max_x > max_x then
      max_x = s.max_x
    end
    if s.min_y < min_y then
      min_y = s.min_y
    end
    if s.max_y > max_y then
      max_y = s.max_y
    end
  end

  -- Generate values for easy scaling/centering later

  local x_range = max_x - min_x
  local y_range = max_y - min_y

  local scale = math.min(360 / x_range, 180 / y_range)
  local x_offset = x_range / 2 + min_x
  local y_offset = y_range / 2 + min_y

  -- Iterate slices
  for _, s in ipairs(bird.slices) do

    -- Create area grid
    local area_grid = {}
    for gx = 1, AREA_GRID_COLS do
      table.insert(area_grid, {})
      for gy = 1, AREA_GRID_ROWS do
        table.insert(area_grid[gx], false)
      end
    end

    -- Calculate normalized points
    for _, p in ipairs(s.points) do

      p.x, p.y = normalize_point(p.x, p.y, x_offset, y_offset, scale)
      p.x = round(p.x, ROUND_QUANT)
      p.y = round(p.y, ROUND_QUANT)

      -- Update area grid
      local gx = round(linlin(0, 1, 0.5, AREA_GRID_COLS + 0.499, p.x))
      local gy = round(linlin(0, 1, 0.5, AREA_GRID_ROWS + 0.499, p.y))
      area_grid[gx][gy] = true

      -- Store min/max points
      if s.num_points < min_points then min_points = s.num_points end
      if s.num_points > max_points then max_points = s.num_points end
    end

    -- Update min/max x/y if no points
    if s.num_points == 0 then
      s.min_x = min_x
      s.max_x = max_x
      s.min_y = min_y
      s.max_y = max_y
    end

    -- Calculate area
    s.area = 0
    for _, col in ipairs(area_grid) do
      for _, cell in ipairs(col) do
        if cell then
          s.area = s.area + 1
        end
      end
    end
    if s.area < min_area then min_area = s.area end
    if s.area > max_area then max_area = s.area end

    -- Calculate density
    if s.area > 0 then
      s.density = s.num_points / s.area
      if s.density < min_density then min_density = s.density end
      if s.density > max_density then max_density = s.density end
    end

    -- Calculate clusters
    -- Note: Could be smarter about estimating number of clusters but just basing on number points for now
    local num_clusters = round(linlin(min_points, max_points, 2, MAX_NUM_CLUSTERS, s.num_points))

    -- Skip clusters if not enough points to be meaningful
    if s.num_points > num_clusters then
      local centers, point_clusters, loss = Clustering.kmeans(s.points, num_clusters, "kmeans++")

      -- Store centroids and number points per cluster
      for i = 1, num_clusters do
        local cluster = {
          x = round(centers[i].x, ROUND_QUANT),
          y = round(centers[i].y, ROUND_QUANT),
          num_points = 0
        }
        
        for _, v in ipairs(point_clusters) do
          if v == i then
            cluster.num_points = cluster.num_points + 1
          end
        end
        if cluster.num_points < min_cluster_points then min_cluster_points = cluster.num_points end
        if cluster.num_points > max_cluster_points then max_cluster_points = cluster.num_points end
        table.insert(s.clusters, cluster)
      end

      -- Sort clusters by y position
      table.sort(s.clusters, function(a, b)
        return a.y > b.y
      end)
    end

  end

  -- Normalize
  for _, s in ipairs(bird.slices) do

    s.min_x_norm, s.min_y_norm = normalize_point(s.min_x, s.min_y, x_offset, y_offset, scale)
    s.max_x_norm, s.max_y_norm = normalize_point(s.max_x, s.max_y, x_offset, y_offset, scale)
    s.min_x_norm = round(s.min_x_norm, ROUND_QUANT)
    s.min_y_norm = round(s.min_y_norm, ROUND_QUANT)
    s.max_x_norm = round(s.max_x_norm, ROUND_QUANT)
    s.max_y_norm = round(s.max_y_norm, ROUND_QUANT)

    s.num_points_norm = round(linlin(min_points, max_points, 0, 1, s.num_points), ROUND_QUANT)
    s.area_norm = round(linlin(min_area, max_area, 0, 1, s.area), ROUND_QUANT)
    s.density_norm = round(linlin(min_density, max_density, 0, 1, s.density), ROUND_QUANT)

    for _, c in ipairs(s.clusters) do
      c.num_points_norm = round(linlin(min_cluster_points, max_cluster_points, 0, 1, c.num_points), ROUND_QUANT)
    end
    
  end

  print("Processed " .. bird.species_id)

  return bird
end

local function cleanup_bird(bird)
  -- Remove attributes we no longer need
  for _, s in ipairs(bird.slices) do
    s.area = nil
    s.density = nil
    s.num_points = nil
    s.min_x = nil
    s.max_x = nil
    s.min_y = nil
    s.max_y = nil

    -- NOTE: Could bring these back but currently unused by Sequencer
    s.min_x_norm = nil
    s.max_x_norm = nil
    s.max_y_norm = nil

    for _, c in ipairs(s.clusters) do
      c.num_points = nil
    end
  end

  return bird
end

local function write_bird_json(bird, output_folder)
  local json_data = Json.encode(bird)
  output_file = io.open(output_folder .. bird.species_id .. ".json", "w")
  output_file:write(json_data)
  output_file:close()
  print("Wrote " .. bird.species_id .. ".json – " .. bird.english_name)
end

local function init()
  if #arg ~= 3 then
    print("Usage: lua data_process.lua <Input CSV> <Species list JSON> <Output folder>")
    os.exit(false)
  end

  local input_file_path = arg[1]
  local species_list_file_path = arg[2]
  local output_folder = arg[3]

  -- TODO check file extensions of these

  local data = load_csv(input_file_path)
  local species_list = load_species_list(species_list_file_path)
  local split_data = split_by_species(data, species_list)
  for k, v in pairs(split_data) do
    local species
    for _, s in pairs(species_list) do
      if tostring(s.species_id) == k then
        species = s
        break
      end
    end
    if species then
      local bird = create_bird(v, species)
      bird = process_bird(bird)
      bird = cleanup_bird(bird)
      write_bird_json(bird, output_folder)
    end
  end

  print("Done!")
end

init()
