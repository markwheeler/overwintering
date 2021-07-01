local MapView = {}

function MapView.redraw(points, focus)

  local map_level = 3
  if focus then map_level = 15 end
  screen.level(map_level)
  
  for _, p in ipairs(points) do
    screen.rect(p.x_norm * 128 - 0.5, 64 - p.y_norm * 64 - 0.5, 1, 1)
    screen.fill()
  end

end

return MapView
