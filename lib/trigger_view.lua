local TriggerView = {}

function TriggerView.redraw(triggers)

  screen.level(15)
  for _, t in ipairs(triggers) do
    if t.active then
      screen.rect(t.screen_x - 2.5, t.screen_y - 2.5, 5, 5)
      screen.stroke()
    end
    if t.played or not t.active then
      screen.rect(t.screen_x - 1, t.screen_y - 1, 2, 2)
      screen.fill()
    end

  end

end

return TriggerView
