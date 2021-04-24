local Trove = {}

Trove.bird_data = {}

local function kmeans(data, nclusters, init)
  -- K-means Clustering
  --
  assert(nclusters > 0)
  assert(#data > nclusters)
  assert(init == "kmeans++" or init == "random")
 
  local diss = function(p, q)
    -- Computes the dissimilarity between points 'p' and 'q'
    -- 
    return math.pow(p.x - q.x, 2) + math.pow(p.y - q.y, 2)
  end
 
  -- Initialization
  --  
  local centers = {} -- clusters centroids
  if init == "kmeans++" then
    local K = 1
 
    -- take one center c1, chosen uniformly at random from 'data'
    local i = math.random(1, #data)
    centers[K] = {x = data[i].x, y = data[i].y}
    local D = {}
 
    -- repeat until we have taken 'nclusters' centers
    while K < nclusters do
      -- take a new center ck, choosing a point 'i' of 'data' with probability 
      -- D(i)^2 / sum_{i=1}^n D(i)^2
 
      local sum_D = 0.0
      for i = 1,#data do
        local min_d = D[i]
        local d = diss(data[i], centers[K])
        if min_d == nil or d < min_d then
            min_d = d
        end
        D[i] = min_d
        sum_D = sum_D + min_d
      end
 
      sum_D = math.random() * sum_D
      for i = 1,#data do
        sum_D = sum_D - D[i]
 
        if sum_D <= 0 then 
          K = K + 1
          centers[K] = {x = data[i].x, y = data[i].y}
          break
        end
      end
    end
  elseif init == "random" then
    for k = 1,nclusters do
      local i = math.random(1, #data)
      centers[k] = {x = data[i].x, y = data[i].y}
    end
  end
 
  -- Lloyd K-means Clustering
  --
  local cluster = {} -- k-partition
  for i = 1,#data do cluster[i] = 0 end
 
  local J = function()
    -- Computes the loss value
    --
    local loss = 0.0
    for i = 1,#data do
      loss = loss + diss(data[i], centers[cluster[i]])
    end
    return loss
  end
 
  local updated = false
  repeat
    -- update k-partition
    --
    local card = {}
    for k = 1,nclusters do
      card[k] = 0.0
    end
 
    updated = false
    for i = 1,#data do
      local min_d, min_k = nil, nil
 
      for k = 1,nclusters do
        local d = diss(data[i], centers[k])
 
        if min_d == nil or d < min_d then
          min_d, min_k = d, k
        end
      end
 
      if min_k ~= cluster[i] then updated = true end
 
      cluster[i]  = min_k
      card[min_k] = card[min_k] + 1.0
    end
    -- print("update k-partition: ", J())
 
    -- update centers
    --
    for k = 1,nclusters do
      centers[k].x = 0.0
      centers[k].y = 0.0
    end
 
    for i = 1,#data do
      local k = cluster[i]
 
      centers[k].x = centers[k].x + (data[i].x / card[k])
      centers[k].y = centers[k].y + (data[i].y / card[k])
    end
    -- print("    update centers: ", J())
  until updated == false
 
  return centers, cluster, J()
end



local function load_csv(file_path)

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
          density = 0
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

  for _, s in ipairs(bird.slices) do

    -- Calculate density
    local w = s.max_x - s.min_x
    local h = s.max_y - s.min_y
    s.density = s.num_points / (w * h)
    if s.density < bird.min_density then bird.min_density = s.density end
    if s.density > bird.max_density then bird.max_density = s.density end

    -- Calculate clusters



    local centers, cluster, loss = kmeans(s.points, 4, "kmeans++")
    -- print("center.x: ", centers[1].x, " center.y: ", centers[1].y)
    -- print(s.num_points, #cluster)

    for i = 1, #s.points do
      s.points[i].cluster_id = cluster[i]
    end

    -- tab.print(cluster)
    -- tab.print(loss)


    -- s.clusters = {}
    -- local to_cluster = {table.unpack(s.points)}
    -- local current_cluster = {}


    -- while #to_cluster > 0 do
    --   table.insert(current_cluster, 1, to_cluster[1])
    --   table.remove(to_cluster, 1)

    --   for _, pc in ipairs(current_cluster) do
    --     if not pc.checked then
    --       for i = #to_cluster, 1, -1 do
    --         local distance = math.sqrt(math.pow(current_cluster[1].x - to_cluster[i].x, 2) + math.pow(current_cluster[1].y - to_cluster[i].y, 2))
    --         if distance < 6 then
    --           table.insert(current_cluster, 1, to_cluster[i])
    --           table.remove(to_cluster, i)
    --         end
    --       end
    --       pc.checked = true
    --     end
    --   end

    --   table.insert(s.clusters, current_cluster)
    --   current_cluster = {}
      
    -- end

    -- print(#s.clusters, "num clusters")


    -- for _, p in ipairs(s.points) do
    --   if not p.cluster_id then
    --     cluster_id = cluster_id + 1
    --     p.cluster_id = cluster_id
    --   end
    --   for _, o in ipairs(s.points) do
    --     if not o.cluster_id then
    --       local distance = math.sqrt(math.pow(p.x - o.x, 2) + math.pow(p.y - o.y, 2))
    --       if distance < 6 then
    --         o.cluster_id = p.cluster_id
    --       end
    --     end
    --   end
    -- end

  end

  -- Generate values for easy scaling/centering later

  bird.x_range = bird.max_x - bird.min_x
  bird.y_range = bird.max_y - bird.min_y

  bird.scale = math.min(360 / bird.x_range, 180 / bird.y_range)
  bird.x_offset = bird.x_range / 2 + bird.min_x
  bird.y_offset = bird.y_range / 2 + bird.min_y

  -- Done!

  if bird.num_slices > 0 then
    table.insert(Trove.bird_data, bird)
    print("Added ", bird.name)
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