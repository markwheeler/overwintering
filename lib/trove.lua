local Trove = {}

Trove.MAX_NUM_CLUSTERS = 4
Trove.AREA_GRID_COLS = 20
Trove.AREA_GRID_ROWS = Trove.AREA_GRID_COLS / 2

Trove.bird_data = {}

local Clustering = include("lib/clustering")

function Trove.normalize_point(x, y, bird_x_offset, bird_y_offset, bird_scale)
  x = util.linlin(-180, 180, 0, 1, (x - bird_x_offset) * bird_scale)
  y = util.linlin(-90, 90, 0, 1, (y - bird_y_offset) * bird_scale)
  return x, y
end

local function process_bird(bird)

  print("Processing bird...")

  -- Generate values for easy scaling/centering later

  bird.x_range = bird.max_x - bird.min_x
  bird.y_range = bird.max_y - bird.min_y

  bird.scale = math.min(360 / bird.x_range, 180 / bird.y_range)
  bird.x_offset = bird.x_range / 2 + bird.min_x
  bird.y_offset = bird.y_range / 2 + bird.min_y

  local min_cluster_points, max_cluster_points = 9999999, 0

  for _, s in ipairs(bird.slices) do

    s.area_grid = {}
    for gx = 1, Trove.AREA_GRID_COLS do
      table.insert(s.area_grid, {})
      for gy = 1, Trove.AREA_GRID_ROWS do
        table.insert(s.area_grid[gx], false)
      end
    end

    -- Calculate normalized points
    for _, p in ipairs(s.points) do
      p.x_norm, p.y_norm = Trove.normalize_point(p.x, p.y, bird.x_offset, bird.y_offset, bird.scale)

      -- Update area grid
      local gx = util.round(util.linlin(0, 1, 0.5, Trove.AREA_GRID_COLS + 0.499, p.x_norm))
      local gy = util.round(util.linlin(0, 1, 0.5, Trove.AREA_GRID_ROWS + 0.499, p.y_norm))
      s.area_grid[gx][gy] = true
    end

    s.min_x_norm, s.min_y_norm = Trove.normalize_point(s.min_x, s.min_y, bird.x_offset, bird.y_offset, bird.scale)
    s.max_x_norm, s.max_y_norm = Trove.normalize_point(s.max_x, s.max_y, bird.x_offset, bird.y_offset, bird.scale)

    -- Calculate normalized num_points
    s.num_points_norm = util.linlin(bird.min_points, bird.max_points, 0, 1, s.num_points)

    -- Calculate area
    s.area = 0
    for _, col in ipairs(s.area_grid) do
      for _, cell in ipairs(col) do
        if cell then
          s.area = s.area + 1
        end
      end
    end
    if s.area < bird.min_area then bird.min_area = s.area end
    if s.area > bird.max_area then bird.max_area = s.area end

    -- Calculate density
    s.density = s.num_points / s.area
    if s.density < bird.min_density then bird.min_density = s.density end
    if s.density > bird.max_density then bird.max_density = s.density end

    -- Calculate clusters
    -- Note: Could be smarter about estimating number of clusters but just basing on number points for now
    local num_clusters = util.round(util.linlin(bird.min_points, bird.max_points, 2, Trove.MAX_NUM_CLUSTERS, s.num_points))
    local centers, point_clusters, loss = Clustering.kmeans(s.points, num_clusters, "kmeans++")

    -- Store centroids and number points per cluster
    for i = 1, num_clusters do
      local cluster = {
        centroid = centers[i],
        num_points = 0
      }
      cluster.centroid.x_norm, cluster.centroid.y_norm = Trove.normalize_point(centers[i].x, centers[i].y, bird.x_offset, bird.y_offset, bird.scale)
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
      return a.centroid.y_norm > b.centroid.y_norm
    end)

    -- No current need to assign points to clusters
    -- for i = 1, #s.points do
    --   s.points[i].cluster_id = cluster[i]
    -- end

  end

  -- Store normalized values
  for _, s in ipairs(bird.slices) do

    s.area_norm = util.linlin(bird.min_area, bird.max_area, 0, 1, s.area)
    s.density_norm = util.linlin(bird.min_density, bird.max_density, 0, 1, s.density)

    for _, c in ipairs(s.clusters) do
      c.num_points_norm = util.linlin(min_cluster_points, max_cluster_points, 0, 1, c.num_points)
    end
  end

  return bird
end

local function load_csv(file_path)

  print("Adding bird...")

  local bird = {
    id = file_path:match("^.+/(.+)%..+"),
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
