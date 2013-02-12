
-- FYI, this set represents 2 different things (map setup - XSHUFFLER - vs drawn tiles - SHUFFLER)
local EMPTY, GOAL, BLOCK, CHARACTER, LAVA, ENEMY, SHUFFLER, XSHUFFLER, YSHUFFLER, SEEKER, XYSHUFFLER = 0,1,2,3,4,5,6,7,8,9,10
local UP, DOWN, LEFT, RIGHT = 1,2,3,4

local letter_sets = {
   asdf = {'a', 's', 'd', 'f'},
   homerow = {'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';'}
}

SB = {}

local levels = { 'intro', 'blocks', 'lava', 'lab', 'seekers', 'more-lava', 'enemies-1', 'lab-1', 'seeker-trap', 'shufflers', 'scrape', 'lab-2', 'the-hall', 'shufflers-2', 'lab-3', 'lava-path' }
local level_letters = { 'homerow', 'homerow', 'homerow', 'asdf', 'homerow', 'homerow', 'asdf', 'homerow', 'homerow', 'homerow', 'asdf', 'homerow', 'asdf', 'homerow', 'asdf', 'asdf' }

local pause_button = 'p'

local tile_type_colors = {}
tile_type_colors[EMPTY] = {150,180,200}
tile_type_colors[GOAL] = {200,255,200}
tile_type_colors[BLOCK] = {50,0,0}
tile_type_colors[CHARACTER] = {20,20,200}
tile_type_colors[LAVA] = {250, 50, 80}
tile_type_colors[ENEMY] = {200, 150, 50}
tile_type_colors[SHUFFLER] = {180, 150, 50}
tile_type_colors[SEEKER] = {200, 0, 0}

local tiles = {}

local shuffle_timeout = 0.7

-- "Procedural tile generation"
function gen_tile(tile_type, colors)
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

   -- started these at zero, then built levels...
   tiles[tile_type + 1] = t

   return t
end

function gen_someone(tile_type, colors)
   local t = love.graphics.newCanvas()

   love.graphics.setCanvas(t)
   love.graphics.setStencil(function()
			       love.graphics.setColor(255,255,255,0)
			       love.graphics.rectangle("fill", 0, 0, tile_size, tile_size)
			    end)

   local r,g,b = unpack(colors)

   local grey = (r + g + b) / 3

   love.graphics.setColor((grey + r) / 2,(grey + g) / 2,(grey + b) / 2,255)
   love.graphics.circle('fill',10,10,9)

   love.graphics.setColor(r,g,b,255)
   love.graphics.circle('fill',9,9,8)
   
   love.graphics.setStencil() -- is this necessary? works without...
   love.graphics.setCanvas()

   -- started these at zero, then built levels...
   tiles[tile_type + 1] = t

   return t
end

local tile_type_gen = {}
tile_type_gen[EMPTY] = gen_tile
tile_type_gen[GOAL] = gen_tile
tile_type_gen[BLOCK] = gen_tile
tile_type_gen[CHARACTER] = gen_someone
tile_type_gen[LAVA] = gen_tile
tile_type_gen[ENEMY] = gen_someone
tile_type_gen[SHUFFLER] = gen_someone
tile_type_gen[SEEKER] = gen_someone

function draw_tile(x,y,tile_type)
   love.graphics.setColor(255,255,255,255) -- modulate mode...
   love.graphics.draw(tiles[tile_type + 1] or (tile_type_gen[tile_type])(tile_type, tile_type_colors[tile_type]),
		      (x - 1) * tile_size, (y - 1) * tile_size)
end

function SB:randomize_letter_set(n)
   local ls = letter_set

   for i=1,n do
      selected = math.random(#ls - i + 1) - 1 + i
      local t = ls[i]
      ls[i] = ls[selected]
      ls[selected] = t
   end
end

function SB:gen_controls()
   self:randomize_letter_set(4)

   controls = _.slice(letter_set,1,4)
end

function SB:gen_enemy_controls()
   for i,e in ipairs(enemies) do

      self:randomize_letter_set(4)

      e[3] = _.slice(letter_set, 1, 4)
   end
end

function SB:from_main() 
   playfield_height = 20
   playfield_width = 20
   tile_size = 20

   character = {x = 0, y = 0, width = tile_size, height = tile_size}

   screen = {screenx = 0, screeny = 0}

   playfield = {}

   current_level = 1
   
   self:load_current_level()
end

function SB:load_level(level, letters)
   local contents, length = love.filesystem.read("levels/"..level)
   
   letter_set = _.extend({}, letters)

   playfield = {}
   enemies = {}
   shufflers = {}
   seekers = {}
   
   next_tile = contents:gmatch('[0-9]')
   
   -- Use a bad hash of the level to get the same key sequences each run.
   local bshash = 0
   local n = 0
      
   for i=1,playfield_height do
      playfield[i] = {}
      for j=1,playfield_width do
	 local t = tonumber(next_tile())

	 if t == CHARACTER then
	    character_x, character_y = j,i
	    t = EMPTY
	 elseif t == ENEMY then
	    table.insert(enemies, {j, i, {'x', 'x', 'x', 'x'}})
	    t = EMPTY
	 elseif t == XSHUFFLER then
	    table.insert(shufflers, {j, i, {1,0}})
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
	 end

	 n = n + 1
	 bshash = bshash + (n * t)

	 playfield[i][j] = t
      end
   end

   math.randomseed(bshash)

   til_shuffle = shuffle_timeout

   self:gen_controls()
   self:gen_enemy_controls()
end

function SB:from_dead() 
   self:load_current_level()
end

function SB:load_current_level()
   self:load_level(levels[current_level], letter_sets[level_letters[current_level]])
end

function SB:keypressed(key, unicode)
   if key == pause_button then
      self:change_ui_state('pause')
      return
   elseif not _.include(letter_set, key) then
	 return
   end

   if key == controls[UP] then
      self:try_move(0,-1)
   elseif key == controls[DOWN] then
      self:try_move(0,1)
   elseif key == controls[LEFT] then
      self:try_move(-1,0)
   elseif key == controls[RIGHT] then
      self:try_move(1,0)
   end

   for i,e in ipairs(enemies) do
      local e_controls = e[3]
      if key == e_controls[UP] then
	 self:try_enemy_move(i,0,-1)
      elseif key == e_controls[DOWN] then
	 self:try_enemy_move(i,0,1)
      elseif key == e_controls[LEFT] then
	 self:try_enemy_move(i,-1,0)
      elseif key == e_controls[RIGHT] then
	 self:try_enemy_move(i,1,0)
      end
   end

   for i,e in ipairs(seekers) do
      local x,y = e[1], e[2]
      local xdiff, ydiff = math.abs(x - character_x), math.abs(y - character_y)

      -- Make the "best possible" 1x OR 1y movement toward the player...

      new_x = x + (character_x - x) / xdiff
      new_y = y + (character_y - y) / ydiff
      x_valid = SB:valid_move(new_x, y)
      y_valid = SB:valid_move(x, new_y)

      -- Attempt 1x movement

      if xdiff >= ydiff and x_valid then
	 e[1] = new_x
      elseif ydiff >= xdiff and y_valid then
	 e[2] = new_y
      elseif xdiff > 0 and x_valid then
	 e[1] = new_x
      elseif ydiff > 0 and y_valid then
	 e[2] = new_y
      end
	 
	 

      --[[
      if xdiff > 0 then
	 new_x = x + (character_x - x) / xdiff
      end
	 
      if ydiff > 0 then
	 new_y = y + (character_y - y) / ydiff
      end

      if SB:valid_move(new_x, new_y) then
	 e[1], e[2] = new_x, new_y
      elseif xdiff > ydiff and SB:valid_move(new_x, y) then
	 e[1] = new_x
      elseif ydiff > 0 and SB:valid_move(x, new_y) then
	 e[2] = new_y
      end
      --]]
   end

   self:gen_enemy_controls()
   self:gen_controls()
   
   self:check_everything()
   -- Note: check_everything may change the state.
end

function SB:check_everything()
   for i,e in ipairs(enemies) do
      if e[1] == character_x and e[2] == character_y then
	 self:change_ui_state('dead')
	 return
      end
   end

   for i,e in ipairs(shufflers) do
      if e[1] == character_x and e[2] == character_y then
	 self:change_ui_state('dead')
	 return
      end
   end

   for i,e in ipairs(seekers) do
      if e[1] == character_x and e[2] == character_y then
	 self:change_ui_state('dead')
	 return
      end
   end

   if playfield[character_y][character_x] == GOAL then
      current_level = current_level + 1
      if current_level > #levels then
	 self:change_ui_state("win")
	 return 
      end
      self:load_current_level()
   elseif playfield[character_y][character_x] == LAVA then
      self:change_ui_state('dead')
      return
   end
end

function SB:update(delta)
   til_shuffle = til_shuffle - delta

   if til_shuffle <= 0 then
      for i,s in ipairs(shufflers) do
	 local x,y,movement = unpack(s)
	 local move_x,move_y = unpack(movement)

	 -- Handling x then y will cause y bounces off corners.

	 if self:valid_move(x + move_x, y) then
	    x = x + move_x
	 else
	    move_x = -move_x
	    if self:valid_move(x + move_x, y) then
	       x = x + move_x
	    end
	 end

	 if self:valid_move(x, y + move_y) then
	    y = y + move_y
	 else
	    move_y = -move_y
	    if self:valid_move(x, y + move_y) then
	       y = y + move_y
	    end
	 end
	    
	 shufflers[i] = {x, y, {move_x, move_y}}
      end
      
      til_shuffle = til_shuffle + shuffle_timeout
   end

   SB:check_everything()
end

function SB:try_move(x,y) 
   new_x, new_y = character_x + x, character_y + y
   
   if self:valid_move(new_x, new_y) then
      character_x = character_x + x
      character_y = character_y + y
   end
end

function SB:valid_move(new_x, new_y)
   return (new_x > 0 and new_x <= playfield_width and
	   new_y > 0 and new_y <= playfield_height and
	   playfield[new_y][new_x] ~= BLOCK)
end

function SB:try_enemy_move(i,x,y) 
   local e = enemies[i]
   new_x, new_y = e[1] + x, e[2] + y

   if self:valid_move(new_x, new_y) then
      e[1], e[2] = new_x, new_y
   end
end

function SB:draw() 
   self:draw_level()
   self:draw_enemies()
   self:draw_someone(CHARACTER, character_x, character_y, controls)
end

function SB:draw_enemies()
   for i,e in ipairs(enemies) do
      self:draw_someone(ENEMY, e[1], e[2], e[3])
   end

   for i,e in ipairs(shufflers) do
      self:draw_someone(SHUFFLER, e[1], e[2])
   end

   for i,e in ipairs(seekers) do
      self:draw_someone(SEEKER, e[1], e[2])
   end
end

function SB:draw_level()
   for y=1,playfield_height do
      for x=1,playfield_width do
	 draw_tile(x,y,playfield[y][x])
      end
   end
end

function SB:draw_someone(type, x, y, controls)
   tile_x = screen.screenx + ((x - 1) * tile_size)
   tile_y = screen.screeny + ((y - 1) * tile_size)

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

return SB