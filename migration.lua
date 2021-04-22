-- Migration
-- 1.0.0 @markeats @giovannilami
--
-- WIP
--

local Trove = include("lib/trove")

local SCREEN_FRAMERATE = 15
local screen_dirty = true

local timeline_clock

local slice_index = 0
local bird_data = {}


-- Metro/clock callbacks

local function screen_update()
  if screen_dirty then
    screen_dirty = false
    redraw()
  end
end

local function advance()
  while true do
    slice_index = slice_index + 1
    screen_dirty = true
    print("tick", slice_index)
    clock.sync(1)
  end
end


-- Functions

local function bird_changed()
  slice_index = 0
end


-- Encoder input
function enc(n, delta)
  if n == 1 then
    params:delta("selected_bird", delta)
  elseif n == 2 then

  elseif n == 3 then
    
  end
  screen_dirty = true
end

-- Key input
function key(n, z)
  if z == 1 then
    if n == 1 then

    elseif n == 2 then

    elseif n == 3 then
      
    end
  end
end


function init()

  Trove.load_folder("data")

  -- Add params
  
  params:add_separator("Migration")

  local bird_names = {}
  for k, v in ipairs(Trove.bird_data) do
    table.insert(bird_names, v.name)
  end

  params:add {
    type = "option",
    id = "selected_bird",
    name = "Bird Species",
    options = bird_names,
    action = bird_changed
  }

  -- Start routines

  metro.init(screen_update, 1 / SCREEN_FRAMERATE):start()

  timeline_clock = clock.run(advance)

end


function redraw()
  screen.clear()
  screen.aa(1)

  screen.level(15)
  screen.move(10, 16)
  screen.text(params:string("selected_bird"))
  screen.move(10, 26)
  screen.text("Slice " .. slice_index)
  screen.fill()

  screen.update()
end
