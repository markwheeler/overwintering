local ClusterView = {}

function ClusterView.redraw(slice)

  -- Cluster centroids
  screen.level(15)
  for _, c in ipairs(slice.clusters) do
    screen.rect(util.round(c.centroid.x_norm * 126) - 1.5, util.round(62 - c.centroid.y_norm * 62) - 1.5, 5, 5)
    screen.stroke()
    screen.fill()
  end

end

return ClusterView
