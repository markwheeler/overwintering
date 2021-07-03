local MapView = {}

function MapView.redraw(points, focus)

  local map_level = 3
  if focus then map_level = 15 end
  screen.level(map_level)

  for _, p in ipairs(points) do
    screen.rect(util.linlin(0, 1, 1, 125, p.x_norm), util.linlin(0, 1, 61, 1, p.y_norm), 1, 1)
    screen.fill()
  end

end

return MapView
