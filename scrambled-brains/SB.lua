
-- FYI, this set represents 2 different things (map setup - XSHUFFLER - vs drawn tiles - SHUFFLER)
local EMPTY, GOAL, BLOCK, CHARACTER, LAVA, ENEMY, SHUFFLER, XSHUFFLER, YSHUFFLER, XYSHUFFLER = 0,1,2,3,4,5,6,7,8,9
local UP, DOWN, LEFT, RIGHT = 1,2,3,4

SB = {
   letter_set = {'a','s','d','f','g','h','j','k','l',';'}
}

local levels = { 'intro', 'blocks', 'lava', 'lab', 'more-lava', 'enemies-1', 'lab-1', 'shufflers', 'lab-2', 'shufflers-2', 'lab-3' }

local pause_button = 'p'

local tile_type_colors = {}
tile_type_colors[EMPTY] = {150,180,200}
tile_type_colors[GOAL] = {200,255,200}
tile_type_colors[BLOCK] = {50,0,0}
tile_type_colors[CHARACTER] = {20,20,200}
tile_type_colors[LAVA] = {250, 50, 80}
tile_type_colors[ENEMY] = {200, 150, 50}
tile_type_colors[SHUFFLER] = {180, 150, 50}

local tiles = {}

local shuffle_timeout = 0.7

-- "Procedural tile generation"
function gen_tile(tile_type)
   local t = love.graphics.newCanvas()

   love.graphics.setCanvas(t)
   love.graphics.setStencil(function()
			       love.graphics.setColor(255,255,255,0)
			       love.graphics.rectangle("fill", 0, 0, tile_size, tile_size)
			    end)

   local r,g,b = unpack(tile_type_colors[tile_type])

   love.graphics.setColor(r,g,b,200)
   love.graphics.circle('fill',8,8,20)

   love.graphics.setColor(r,g,b,240)
   love.graphics.circle('fill',8,8,16)

   love.graphics.setColor(r,g,b,255)
   love.graphics.circle('fill',8,8,12)

   -- Another option...
   --[[
   love.graphics.setColor(r / 1.3, g / 1.3, b / 1.3, 255)
   love.graphics.rectangle('fill',0,0,20,20)

   love.graphics.setColor(r / 1.1, g / 1.1, b / 1.1, 255)
   love.graphics.rectangle('fill',0,0,19,19)
   
   love.graphics.setColor(r,g,b,255)
   love.graphics.rectangle('fill',0,0,18,18)
   --]]
   
   love.graphics.setStencil() -- is this necessary? works without...
   love.graphics.setCanvas()

   -- started these at zero, then built levels...
   tiles[tile_type + 1] = t

   return t
end

function draw_tile(x,y,tile_type)
   love.graphics.setColor(255,255,255,255) -- modulate mode...
   love.graphics.draw(tiles[tile_type + 1] or gen_tile(tile_type),
		      (x - 1) * tile_size, (y - 1) * tile_size)
end

function SB:randomize_letter_set(n)
   local ls = self.letter_set

   for i=1,n do
      selected = math.random(#ls - i + 1)
      local t = ls[i]
      ls[i] = ls[selected]
      ls[selected] = t
   end
end

function SB:gen_controls()
   self:randomize_letter_set(4)

   self.controls = _.slice(self.letter_set,1,4)
end

function SB:gen_enemy_controls()
   for i,e in ipairs(self.enemies) do

      self:randomize_letter_set(4)

      e[3] = _.slice(self.letter_set, 1, 4)
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

   self:load_level(levels[current_level])
end

function SB:load_level(level)
   local contents, length = love.filesystem.read("levels/"..level)

   playfield = {}
   self.enemies = {}
   self.shufflers = {}
   
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
	    table.insert(self.enemies, {j, i, {'x', 'x', 'x', 'x'}})
	    t = EMPTY
	 elseif t == XSHUFFLER then
	    table.insert(self.shufflers, {j, i, {1,0}})
	    t = EMPTY
	 elseif t == YSHUFFLER then
	    table.insert(self.shufflers, {j, i, {0,-1}})
	    t = EMPTY
	 elseif t == XYSHUFFLER then
	    table.insert(self.shufflers, {j, i, {1, 1}})
	    t = EMPTY
	 end

	 n = n + 1
	 bshash = bshash + (n * t)

	 playfield[i][j] = t
      end
   end

   math.randomseed(bshash)

   self.til_shuffle = shuffle_timeout

   self:gen_controls()
   self:gen_enemy_controls()
end

function SB:from_dead() 
   self:load_level(levels[current_level])
end

function SB:keypressed(key, unicode)
   if key == pause_button then
      self:change_ui_state('pause')
      return
   elseif not _.include(self.letter_set, key) then
	 return
   end

   if key == self.controls[UP] then
      self:try_move(0,-1)
   elseif key == self.controls[DOWN] then
      self:try_move(0,1)
   elseif key == self.controls[LEFT] then
      self:try_move(-1,0)
   elseif key == self.controls[RIGHT] then
      self:try_move(1,0)
   end

   for i,e in ipairs(self.enemies) do
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

   self:gen_enemy_controls()
   self:gen_controls()
   
   self:check_everything()
   -- Note: check_everything may change the state.
end

function SB:check_everything()
   for i,e in ipairs(self.enemies) do
      if e[1] == character_x and e[2] == character_y then
	 self:change_ui_state('dead')
	 return
      end
   end

   for i,e in ipairs(self.shufflers) do
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
      self:load_level(levels[current_level])
   elseif playfield[character_y][character_x] == LAVA then
      self:change_ui_state('dead')
      return
   end
end

function SB:update(delta)
   self.til_shuffle = self.til_shuffle - delta

   if self.til_shuffle <= 0 then
      for i,s in ipairs(self.shufflers) do
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
	    
	 self.shufflers[i] = {x, y, {move_x, move_y}}
      end
      
      self.til_shuffle = self.til_shuffle + shuffle_timeout
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
   local e = self.enemies[i]
   new_x, new_y = e[1] + x, e[2] + y

   if self:valid_move(new_x, new_y) then
      e[1], e[2] = new_x, new_y
   end
end

function SB:draw() 
   self:draw_level()
   self:draw_enemies()
   self:draw_someone(CHARACTER, character_x, character_y, self.controls)
end

function SB:draw_enemies()
   for i,e in ipairs(self.enemies) do
      self:draw_someone(ENEMY, e[1], e[2], e[3])
   end

   for i,e in ipairs(self.shufflers) do
      self:draw_someone(SHUFFLER, e[1], e[2])
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
      love.graphics.setColor(200,200,200,200)
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