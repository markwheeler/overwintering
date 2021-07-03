local ClusterView = {}

function ClusterView.redraw(slice)

  -- Slice bounds
  screen.level(3)
  screen.rect(math.floor(util.linlin(0, 1, 1, 126, slice.min_x_norm)) - 0.5, math.floor(util.linlin(0, 1, 62, 1, slice.max_y_norm)) - 0.5, math.ceil((slice.max_x_norm - slice.min_x_norm) * 125) + 2,  math.ceil((slice.max_y_norm - slice.min_y_norm) * 61) + 2)

  screen.stroke()

  -- Cluster centroids
  screen.level(15)
  for _, c in ipairs(slice.clusters) do
    screen.rect(util.round(c.centroid.x_norm * 126) - 1.5, util.round(62 - c.centroid.y_norm * 62) - 1.5, 5, 5)
    screen.stroke()
    -- screen.move(util.round(c.centroid.x_norm * 126) + 5, util.round(62 - c.centroid.y_norm * 62) + 3)
    -- screen.text(c.num_points_norm)
    screen.fill()
  end

end

return ClusterView
