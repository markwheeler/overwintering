local TriggerView = {}

function TriggerView.redraw(triggers)
  
  for _, t in ipairs(triggers) do
    if t.active then
      screen.level(15)
      screen.rect(t.screen_x - 2.5, t.screen_y - 2.5, 5, 5)
      screen.stroke()
    end
    if t.display_timer > 0 then
      screen.level(util.round(t.display_timer * 15))
      screen.rect(t.screen_x - 1, t.screen_y - 1, 2, 2)
      screen.fill()
    elseif not t.active then
      screen.level(15)
      screen.rect(t.screen_x - 1, t.screen_y - 1, 2, 2)
      screen.fill()
    end

  end

end

return TriggerView
