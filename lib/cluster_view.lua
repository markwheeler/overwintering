local ClusterView = {}

function ClusterView.redraw(slice)

  -- Cluster centroids
  screen.level(15)
  for _, c in ipairs(slice.clusters) do
    screen.rect(util.round(c.x * 126) - 1.5, util.round(62 - c.y * 62) - 1.5, 5, 5)
    screen.stroke()
    screen.fill()
  end

end

return ClusterView
