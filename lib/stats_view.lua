local StatsView = {}

function StatsView.redraw(area, mass, density)

  screen.level(15)

  -- Area
  screen.move(2, 21)
  screen.text("Area")
  screen.fill()
  screen.rect(40, 18, area * 76,  2)
  screen.fill()

  -- Mass
  screen.move(2, 32)
  screen.text("Mass")
  screen.fill()
  screen.rect(40, 29, mass * 76,  2)
  screen.fill()

  -- Density
  screen.move(2, 43)
  screen.text("Density")
  screen.fill()
  screen.rect(40, 40, density * 76,  2)
  screen.fill()
end

return StatsView
