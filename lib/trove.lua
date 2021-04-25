local Trove = {}

Trove.bird_data = {}

local Clustering = include("lib/clustering")


local function process_bird(bird)

  print("Processing bird...")

  for _, s in ipairs(bird.slices) do

    -- Calculate area
    s.area = (s.max_x - s.min_x) * (s.max_y - s.min_y)
    if s.area < bird.min_area then bird.min_area = s.area end
    if s.area > bird.max_area then bird.max_area = s.area end

    -- Calculate density
    s.density = s.num_points / s.area
    if s.density < bird.min_density then bird.min_density = s.density end
    if s.density > bird.max_density then bird.max_density = s.density end

    -- Calculate clusters
    -- Note: Could be smarter about estimating number of clusters but just basing on number points for now
    local num_clusters = util.round(util.linlin(bird.min_points, bird.max_points, 2, 4, s.num_points))
    local centers, point_clusters, loss = Clustering.kmeans(s.points, num_clusters, "kmeans++")

    -- Store centroids and number points per cluster
    for i = 1, num_clusters do
      local cluster = {
        centroid = centers[i],
        num_points = 0
      }
      for _, v in ipairs(point_clusters) do
        if v == i then
          cluster.num_points = cluster.num_points + 1
        end
      end
      table.insert(s.clusters, cluster)
    end

    -- No current need to assign points to clusters
    -- for i = 1, #s.points do
    --   s.points[i].cluster_id = cluster[i]
    -- end

  end

  -- Generate values for easy scaling/centering later

  bird.x_range = bird.max_x - bird.min_x
  bird.y_range = bird.max_y - bird.min_y

  bird.scale = math.min(360 / bird.x_range, 180 / bird.y_range)
  bird.x_offset = bird.x_range / 2 + bird.min_x
  bird.y_offset = bird.y_range / 2 + bird.min_y

  return bird
end

local function load_csv(file_path)

  print("Adding bird...")

  local bird = {
    name = "Name",
    latin_name = "Latin name",
    slices = {},
    num_slices = 0,
    min_x = 180,
    max_x = -180,
    min_y = 90,
    max_y = -90,
    min_points = 9999999,
    max_points = 0,
    min_area = 9999999,
    max_area = 0,
    min_density = 9999999,
    max_density = 0
  }

  local first = true
  local slice

  for line in io.lines(file_path) do

    -- Split the line
    local split = {}
    for val in string.gmatch(line, '([^,]+)') do
      table.insert(split, val)
    end

    -- Get meta
    if first then
      bird.name = split[1]
      bird.latin_name = split[2]
      first = false

    else

      local week, year = tonumber(split[3]), tonumber(split[4])

      -- Add a new slice if need be
      if bird.num_slices == 0 or week ~= bird.slices[bird.num_slices].week or year ~= bird.slices[bird.num_slices].year then
        slice = {
          week = week,
          year = year,
          points = {},
          num_points = 0,
          min_x = 180,
          max_x = -180,
          min_y = 90,
          max_y = -90,
          area = 0,
          density = 0,
          clusters = {}
        }
        table.insert(bird.slices, slice)
        bird.num_slices = bird.num_slices + 1
      end
      
      -- Add point
      local point = {
        x = tonumber(split[1]),
        y = tonumber(split[2]),
        norm_x = 0,
        norm_y = 0
      }
      table.insert(bird.slices[bird.num_slices].points, point)
      slice.num_points = slice.num_points + 1

      -- Store overall min/max xy
      if point.x < bird.min_x then bird.min_x = point.x end
      if point.x > bird.max_x then bird.max_x = point.x end
      if point.y < bird.min_y then bird.min_y = point.y end
      if point.y > bird.max_y then bird.max_y = point.y end

      -- Store slice min/max xy
      if point.x < slice.min_x then slice.min_x = point.x end
      if point.x > slice.max_x then slice.max_x = point.x end
      if point.y < slice.min_y then slice.min_y = point.y end
      if point.y > slice.max_y then slice.max_y = point.y end

      -- Store min/max points
      if slice.num_points < bird.min_points then bird.min_points = slice.num_points end
      if slice.num_points > bird.max_points then bird.max_points = slice.num_points end
      
    end
  end

  if bird.num_slices > 0 then
    bird = process_bird(bird)
    table.insert(Trove.bird_data, bird)
    print("Added " .. bird.name)
  else
    print("Could not add ", file_path)
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
