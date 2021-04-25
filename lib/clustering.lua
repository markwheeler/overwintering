local Clustering = {}

-- K-means Clustering
-- From https://rosettacode.org/wiki/K-means%2B%2B_clustering#Lua

function Clustering.kmeans(data, nclusters, init)

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

return Clustering
