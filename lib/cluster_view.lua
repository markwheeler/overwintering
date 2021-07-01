local ClusterView = {}

function ClusterView.redraw(slice)

  -- Slice bounds
  screen.level(3)
  screen.rect(math.floor(slice.min_x_norm * 128) - 0.5, 64 - math.floor(slice.max_y_norm * 64) - 0.5, math.ceil((slice.max_x_norm - slice.min_x_norm) * 128) + 1,  math.ceil((slice.max_y_norm - slice.min_y_norm) * 64) + 1)
  screen.stroke()

  -- Cluster centroids
  screen.level(15)
  for _, c in ipairs(slice.clusters) do
    screen.rect(util.round(c.centroid.x_norm * 128) - 2.5, util.round(64 - c.centroid.y_norm * 64) - 2.5, 5, 5)
    screen.stroke()
    -- screen.move(util.round(c.centroid.x_norm * 128) + 4, util.round(64 - c.centroid.y_norm * 64) + 2)
    -- screen.text(c.num_points_norm)
    screen.fill()
  end

end

return ClusterView
