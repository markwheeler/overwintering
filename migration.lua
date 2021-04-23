-- Migration
-- 1.0.0 @markeats @giovannilami
--
-- WIP
--

local Trove = include("lib/trove")

local SCREEN_FRAMERATE = 15
local screen_dirty = true

local timeline_clock

local slice_index = 1
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
    if slice_index > Trove.bird_data[params:get("selected_bird")].num_slices then
      slice_index = 1
    end
    -- slice_index = 53

    screen_dirty = true
    -- print("tick", slice_index)
    clock.sync(0.1)
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

  Trove.load_folder(norns.state.path .. "data/")

  local bird_names = {}

  if #Trove.bird_data == 0 then
    table.insert(bird_names, "No bird data")
  end

  -- Add params
  
  params:add_separator("Migration")

  for _, v in ipairs(Trove.bird_data) do
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


local function draw_map()

  local bird = Trove.bird_data[params:get("selected_bird")]

  -- Scale and center on screen
  
  local bird_x_range = bird.max_x - bird.min_x
  local bird_y_range = bird.max_y - bird.min_y

  local scale = math.min(360 / bird_x_range, 180 / bird_y_range)
  local x_offset = bird_x_range / 2 + bird.min_x
  local y_offset = bird_y_range / 2 + bird.min_y

  screen.level(15)
  for _, p in ipairs(bird.slices[slice_index].points) do
    screen.rect(util.linlin(-180, 180, 0, 127, (p.x - x_offset) * scale), util.linlin(-90, 90, 63, 0, (p.y - y_offset) * scale), 1, 1)
    screen.fill()
  end

end

function redraw()
  
  screen.clear()
  screen.aa(1)

  draw_map()

  screen.level(15)
  screen.move(0, 11)
  local slice = Trove.bird_data[params:get("selected_bird")].slices[slice_index]
  screen.text(slice.year .. " " .. slice.week)
  -- screen.text(params:string("selected_bird"))
  -- screen.move(10, 26)
  screen.fill()

  screen.update()
end
