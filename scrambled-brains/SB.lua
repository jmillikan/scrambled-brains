-- This file creates and returns the gameplay state (sb).

-- FYI, this set represents 2 different things (map setup - XSHUFFLER - vs drawn tiles - SHUFFLER)
local EMPTY, GOAL, BLOCK, CHARACTER, LAVA, ENEMY, SHUFFLER, XSHUFFLER, YSHUFFLER, SEEKER, XYSHUFFLER, TRAMPLER, REVXSHUFFLER = 1,2,3,4,5,6,7,8,9,10,11,12,13
local UP, DOWN, LEFT, RIGHT = 1,2,3,4

local asdf = {'a', 's', 'd', 'f'}
local homerow = {'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';'}

sb = {}

local levels = {
   { map = 'intro', keys = homerow },
   { map = 'blocks', keys = homerow },
   { map = 'lava', keys = homerow },
   { map = 'lab', keys = asdf },
   { map = 'seekers', keys = homerow },
   { map = 'more-lava', keys = homerow },
   { map = 'enemies-1', keys = asdf },
   { map = 'lab-1', keys = homerow },
   { map = 'trampler', keys = homerow },
   { map = 'shufflers', keys = homerow },
   { map = 'seeker-trap', keys = homerow },
   { map = 'shufflers-2', keys = homerow },
   { map = 'trampler-wall', keys = homerow },
   { map = 'lab-3', keys = asdf },
   { map = 'shuffler-shuffle', keys = homerow },
   { map = 'scrape', keys = asdf },
   { map = 'the-hall', keys = asdf },
   { map = 'lava-path', keys = homerow }
}

local stats 

local pause_button = 'p'

local tiles = {}

local shuffle_timeout = 0.7
local trample_timeout = 2.0
local til_shuffle, til_trample

function gen_map_tile(colors, size) -- size ignored
   local t = love.graphics.newCanvas()

   love.graphics.setCanvas(t)
   love.graphics.setStencil(function()
			       love.graphics.setColor(255,255,255,0)
			       love.graphics.rectangle("fill", 0, 0, tile_size, tile_size)
			    end)

   local r,g,b = unpack(colors)

   love.graphics.setColor(r,g,b,200)
   love.graphics.circle('fill',8,8,20)

   love.graphics.setColor(r,g,b,240)
   love.graphics.circle('fill',8,8,16)

   love.graphics.setColor(r,g,b,255)
   love.graphics.circle('fill',8,8,12)

   love.graphics.setStencil() -- is this necessary? works without...
   love.graphics.setCanvas()

   return t
end

function gen_someone(colors, size)
   local t = love.graphics.newCanvas()

   size = size or 1

   love.graphics.setCanvas(t)
   love.graphics.setStencil(function()
			       love.graphics.setColor(255,255,255,0)
			       love.graphics.rectangle("fill", 0, 0, tile_size * size, tile_size * size)
			    end)

   local r,g,b = unpack(colors)

   local grey = (r + g + b) / 3

   love.graphics.setColor((grey + r) / 2,(grey + g) / 2,(grey + b) / 2,255)
   love.graphics.circle('fill', 10 * size, 10 * size, 9 * size)

   love.graphics.setColor(r,g,b,255)
   love.graphics.circle('fill', 9 * size, 9 * size, 8 * size)
   
   love.graphics.setStencil() -- is this necessary? works without...
   love.graphics.setCanvas()

   return t
end

local tile_types = {}
tile_types[EMPTY] = { color = {150,180,200}, gen = gen_map_tile }
tile_types[GOAL] = { color = {200,255,200}, gen = gen_map_tile }
tile_types[BLOCK] = { color = {50,0,0}, gen = gen_map_tile }
tile_types[CHARACTER] = { color = {20,20,200}, gen = gen_someone }
tile_types[LAVA] = { color = {250, 50, 80}, gen = gen_map_tile }
tile_types[ENEMY] = { color = {200, 150, 50}, gen = gen_someone }
tile_types[SHUFFLER] = { color = {180, 150, 50}, gen = gen_someone }
tile_types[SEEKER] = { color = {200, 0, 0}, gen = gen_someone }
tile_types[TRAMPLER] = { color = {200, 0, 0 }, gen = gen_someone, size = 2 }

function get_tile(tile_type)
   tiles[tile_type] = tile_types[tile_type].gen(tile_types[tile_type].color, tile_types[tile_type].size)
   return tiles[tile_type]
end

function draw_tile(x,y,tile_type)
   love.graphics.setColor(255,255,255,255) -- modulate mode...
   love.graphics.draw(tiles[tile_type] or get_tile(tile_type),
		      (x - 1) * tile_size, 
		      (y - 1) * tile_size)
end

function randomize_letter_set(n)
   local ls = letter_set

   for i=1,n do
      selected = math.random(#ls - i + 1) - 1 + i
      local t = ls[i]
      ls[i] = ls[selected]
      ls[selected] = t
   end
end

function gen_controls()
   randomize_letter_set(4)

   controls = _.slice(letter_set,1,4)
end

function gen_enemy_controls()
   for i,e in ipairs(enemies) do

      randomize_letter_set(4)

      e[3] = _.slice(letter_set, 1, 4)
   end
end

function load_level(level, letters)
   local contents, length = love.filesystem.read("levels/"..level)
   
   letter_set = _.extend({}, letters)

   playfield = {}
   enemies = {}
   shufflers = {}
   seekers = {}
   tramplers = {}
   
   next_tile = contents:gmatch('[0-9a-f]')
   
   -- Use a bad hash of the level to get the same key sequences each run.
   local bshash = 0
   local n = 0
      
   for i=1,playfield_height do
      playfield[i] = {}
      for j=1,playfield_width do
	 local t = tonumber('0x'..next_tile()) + 1 -- >_<

	 if t == CHARACTER then
	    character_x, character_y = j,i
	    t = EMPTY
	 elseif t == ENEMY then
	    table.insert(enemies, {j, i, {'x', 'x', 'x', 'x'}})
	    t = EMPTY
	 elseif t == XSHUFFLER then
	    table.insert(shufflers, {j, i, {1,0}})
	    t = EMPTY
	 elseif t == REVXSHUFFLER then -- >_<
	    table.insert(shufflers, {j, i, {-1,0}})
	    t = EMPTY
	 elseif t == YSHUFFLER then
	    table.insert(shufflers, {j, i, {0,-1}})
	    t = EMPTY
	 elseif t == XYSHUFFLER then
	    table.insert(shufflers, {j, i, {1, 1}})
	    t = EMPTY
	 elseif t == SEEKER then
	    table.insert(seekers, {j, i})
	    t = EMPTY
	 elseif t == TRAMPLER then
	    table.insert(tramplers, {j, i})
	    t = EMPTY
	 end

	 n = n + 1
	 bshash = bshash + (n * t)

	 playfield[i][j] = t
      end
   end

   math.randomseed(bshash)

   til_shuffle = shuffle_timeout
   til_trample = trample_timeout

   gen_controls()
   gen_enemy_controls()
end

function load_current_level()
   load_level(levels[current_level].map, levels[current_level].keys)
end

function die()
   stats.deaths = stats.deaths + 1
   sb:change_ui_state('dead')
end

function char_at(x, y)
   return x == character_x and y == character_y
end

function check_everything()
   for i,e in ipairs(enemies) do
      if char_at(e[1], e[2]) then
	 die()
	 return
      end
   end

   for i,e in ipairs(shufflers) do
      if char_at(e[1], e[2]) then
	 die()
	 return
      end
   end

   for i,e in ipairs(seekers) do
      if char_at(e[1], e[2]) then
	 die()
	 return
      end
   end

   for i,e in ipairs(tramplers) do
      if char_at(e[1], e[2]) or char_at(e[1] + 1, e[2]) or
	 char_at(e[1], e[2] + 1) or char_at(e[1] + 1, e[2] + 1) then
	 die()
      end
   end

   if playfield[character_y][character_x] == GOAL then
      current_level = current_level + 1
      if current_level > #levels then
	 sb:change_ui_state("win")
	 return 
      end
      load_current_level()

      sb:change_ui_state('present_level')
   elseif playfield[character_y][character_x] == LAVA then
      die()
      return
   end
end

function try_move(x,y) 
   new_x, new_y = character_x + x, character_y + y
   
   if valid_move(new_x, new_y) then
      character_x = character_x + x
      character_y = character_y + y
      stats.moves = stats.moves + 1
   end
end

function valid_move(new_x, new_y)
   return (new_x > 0 and new_x <= playfield_width and
	   new_y > 0 and new_y <= playfield_height and
	   playfield[new_y][new_x] ~= BLOCK)
end

function try_enemy_move(i,x,y) 
   local e = enemies[i]
   new_x, new_y = e[1] + x, e[2] + y

   if valid_move(new_x, new_y) then
      enemies[i] = {new_x, new_y}
   end
end

function draw_enemies()
   for i,e in ipairs(enemies) do
      draw_someone(ENEMY, e[1], e[2], e[3])
   end

   for i,e in ipairs(shufflers) do
      draw_someone(SHUFFLER, e[1], e[2])
   end

   for i,e in ipairs(seekers) do
      draw_someone(SEEKER, e[1], e[2])
   end

   for i,e in ipairs(tramplers) do
      draw_someone(TRAMPLER, e[1], e[2])
   end
end

function draw_level()
   for y=1,playfield_height do
      for x=1,playfield_width do
	 draw_tile(x,y,playfield[y][x])
      end
   end
end

function draw_someone(type, x, y, controls)
   local tile_x = screen.screenx + ((x - 1) * tile_size)
   local tile_y = screen.screeny + ((y - 1) * tile_size)

   -- specific to 1x1 enemies for now
   if controls then
      love.graphics.setColor(200,200,200,160)
      love.graphics.circle('fill', tile_x + tile_size / 2, tile_y + tile_size / 2, tile_size * 2)
   
      love.graphics.setColor(0,0,0)
      love.graphics.printf(controls[LEFT], tile_x - 30, tile_y + 5, 20, "right")
      love.graphics.printf(controls[RIGHT], tile_x + 30, tile_y + 5, 20, "left")
      love.graphics.printf(controls[UP], tile_x, tile_y - 23, 20, "center")
      love.graphics.printf(controls[DOWN], tile_x, tile_y + 28, 20, "center")
   end

   draw_tile(x,y,type)
end

function change_playfield(x, y, tile_type)
   if playfield[y] and playfield[y][x] then
      playfield[y][x] = tile_type
   end
end

function advance_tramplers()
   for i,e in ipairs(tramplers) do
      local x,y = e[1], e[2]
      local center_xdiff, center_ydiff = (x + 0.5) - character_x, (y + 0.5) - character_y
      local center_xdist, center_ydist = math.abs(center_xdiff), math.abs(center_ydiff)
      
      -- Make the best 1x OR 1y movement toward the player...
      local new_x = x - center_xdiff / center_xdist
      local new_y = y - center_ydiff / center_ydist

      -- prefers y to x
      if center_ydist >= center_xdist and center_ydist > 0 then
	 e[2] = new_y
      elseif center_xdist >= center_ydist and center_xdist > 0 then
	 e[1] = new_x
      end

      change_playfield(e[1], e[2], EMPTY)
      change_playfield(e[1] + 1, e[2], EMPTY)
      change_playfield(e[1], e[2] + 1, EMPTY)
      change_playfield(e[1] + 1, e[2] + 1, EMPTY)
   end
end

function advance_shufflers()
   for i,s in ipairs(shufflers) do
      local x,y,movement = unpack(s)
      local move_x,move_y = unpack(movement)

      -- Handling x then y will cause y bounces off corners.

      if valid_move(x + move_x, y) then
	 x = x + move_x
      else
	 move_x = -move_x
	 if valid_move(x + move_x, y) then
	    x = x + move_x
	 end
      end

      if valid_move(x, y + move_y) then
	 y = y + move_y
      else
	 move_y = -move_y
	 if valid_move(x, y + move_y) then
	    y = y + move_y
	 end
      end
      
      shufflers[i] = {x, y, {move_x, move_y}}
   end
end

function advance_enemies(key)
   for i,e in ipairs(enemies) do
      local e_controls = e[3]
      if key == e_controls[UP] then
	 try_enemy_move(i,0,-1)
      elseif key == e_controls[DOWN] then
	 try_enemy_move(i,0,1)
      elseif key == e_controls[LEFT] then
	 try_enemy_move(i,-1,0)
      elseif key == e_controls[RIGHT] then
	 try_enemy_move(i,1,0)
      end
   end
end

function advance_seekers()
   for i,e in ipairs(seekers) do
      local x,y = e[1], e[2]
      local xdiff, ydiff = math.abs(x - character_x), math.abs(y - character_y)

      -- Make the best 1x OR 1y movement toward the player...
      new_x = x + (character_x - x) / xdiff
      new_y = y + (character_y - y) / ydiff
      x_valid = valid_move(new_x, y)
      y_valid = valid_move(x, new_y)

      -- prefers y to x
      if ydiff >= xdiff and y_valid then
	 e[2] = new_y
      elseif xdiff >= ydiff and x_valid then
	 e[1] = new_x
      elseif ydiff > 0 and y_valid then
	 e[2] = new_y
      elseif xdiff > 0 and x_valid then
	 e[1] = new_x
      end
   end
end


function sb:draw() 
   draw_level()
   draw_enemies()
   draw_someone(CHARACTER, character_x, character_y, controls)
end

function sb:update(delta)
   -- Delta will be wrong when returning from other states. (TODO.)

   til_shuffle = til_shuffle - delta

   if til_shuffle <= 0 then
      advance_shufflers()
      
      til_shuffle = til_shuffle + shuffle_timeout
   end

   til_trample = til_trample - delta
   
   if til_trample <= 0 then
      advance_tramplers()
      
      til_trample = til_trample + trample_timeout
   end

   check_everything()
end

function sb:from_main() 
   playfield_height = 20
   playfield_width = 20
   tile_size = 20

   character = {x = 0, y = 0, width = tile_size, height = tile_size}

   screen = {screenx = 0, screeny = 0}

   playfield = {}

   current_level = 1
   
   load_current_level()

   stats = {
      deaths = 0,
      moves = 0
   }

   self:change_ui_state('present_level')
end

function sb:from_dead() 
   load_current_level()
end

function sb:keypressed(key, unicode)
   if key == pause_button then
      self:change_ui_state('pause')
      return
   elseif not _.include(letter_set, key) then
	 return
   end

   if key == controls[UP] then
      try_move(0,-1)
   elseif key == controls[DOWN] then
      try_move(0,1)
   elseif key == controls[LEFT] then
      try_move(-1,0)
   elseif key == controls[RIGHT] then
      try_move(1,0)
   end

   advance_enemies(key)
   advance_seekers()

   gen_enemy_controls()
   gen_controls()
   
   check_everything()
   -- Note: check_everything may change the state.
end

function sb:stats()
   return stats
end

local countdown

function draw_key(l, x)
   local left = x
   local top = 50

   local rad = 5

   local width = 30
   local height = 30

   love.graphics.setColor(200,200,200,255)
   love.graphics.rectangle('fill', left, top + rad, width, height - rad * 2)
   love.graphics.rectangle('fill', left + rad, top, width - rad * 2, height)
   love.graphics.circle('fill', left + rad, top + rad, rad)
   love.graphics.circle('fill', left + width - rad, top + rad, rad)
   love.graphics.circle('fill', left + rad, top + height - rad, rad)
   love.graphics.circle('fill', left + width - rad, top + height - rad, rad)

   love.graphics.setColor(0,0,0,255)
   love.graphics.printf(l, x, top + 10, width, "center")
end

present_level = {
   from_game = function(self)
      countdown = 2.0
   end,
   update = function(self, delta)
      countdown = countdown - delta
      if countdown <= 0 then
	 self:change_ui_state('game')
      end
   end,
   draw = function(self)
      local margin = 30

      sb:draw()
      love.graphics.setColor(0,0,0,100)
      love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), 100)
      love.graphics.setColor(255,255,255,255)
      love.graphics.printf(levels[current_level].map, margin, 20, love.graphics.getWidth() - margin * 2, "center")

      local x = margin
      for i,l in ipairs({'a','s','d','f','g','h','j','k','l',';'}) do
	 if _.include(letter_set,l) then
	    draw_key(l, x)
	 end
	 x = x + 35
      end
      
   end
}

return sb, present_level