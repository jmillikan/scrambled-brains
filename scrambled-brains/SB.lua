
EMPTY = 0
GOAL = 1
BLOCK = 2
CHARACTER = 3
LAVA = 4
ENEMY = 5

SB = {
   letter_set = {'a','s','d','f','g','h','j','k','l',';'}
}

levels = { 'intro', 'blocks', 'lava', 'lab', 'more-lava', 'enemies-1', 'lab-1', 'lab-2', 'lab-3' }

PAUSE_BUTTON = 'p'

local tile_type_colors = {}
tile_type_colors[EMPTY] = {150,180,200}
tile_type_colors[GOAL] = {200,255,200}
tile_type_colors[BLOCK] = {50,0,0}
tile_type_colors[CHARACTER] = {20,20,200}
tile_type_colors[LAVA] = {250, 50, 80}
tile_type_colors[ENEMY] = {200, 150, 50}

function draw_tile(x,y,tile_type)
   r,g,b = unpack(tile_type_colors[tile_type])
   love.graphics.setColor(r,g,b)
   draw_game_rect({width = tile_size, height=tile_size, x = (x - 1) * tile_size, y = (y - 1) * tile_size})
end

function draw_game_rect(r)
   love.graphics.push()
   love.graphics.translate(screen.screenx + r.x + r.width / 2, screen.screeny + r.y + r.height / 2)

   if r.angle then
      love.graphics.rotate(r.angle)
   end

   love.graphics.rectangle("fill", - r.width / 2,  - r.height / 2, r.width, r.height)
   love.graphics.pop()
end

function SB:gen_controls()
   local t
   local ls = self.letter_set

   for i=1,4 do
      selected = math.random(#ls - i + 1)
      t = ls[i]
      ls[i] = ls[selected]
      ls[selected] = t
   end

   self.up_button = ls[1]
   self.down_button = ls[2]
   self.left_button = ls[3]
   self.right_button = ls[4]
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

function SB:gen_enemy_controls()
   for i,e in ipairs(self.enemies) do

      self:randomize_letter_set(4)
      local ls = self.letter_set

      e[3] = { ls[1], ls[2], ls[3], ls[4] }
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
   
   next_tile = contents:gmatch('[0-9]')
   
   -- Use a bad hash of the level to get the same key sequences each run.
   local bshash = 0
   local n = 0
      
   for i=1,20 do
      playfield[i] = {}
      for j=1,20 do
	 local t = tonumber(next_tile())

	 if t == CHARACTER then
	    character_x, character_y = j,i
	    t = EMPTY
	 elseif t == ENEMY then
	    table.insert(self.enemies, {j, i, {'x', 'x', 'x', 'x'}})
	    t = EMPTY
	 end
	 
	 n = n + 1
	 bshash = bshash + (n * t)

	 playfield[i][j] = t
      end
   end

   print('bshash for ' .. level .. ': ' .. tostring(bshash))
   math.randomseed(bshash);

   self:gen_controls()
   self:gen_enemy_controls()
end

function SB:keypressed(key, unicode)
   if key == PAUSE_BUTTON then
      self:change_ui_state('pause')
      return
   elseif not _.include(self.letter_set, key) then
	 return
   end

   if key == self.up_button then
      self:try_move(0,-1)
   elseif key == self.down_button then
      self:try_move(0,1)
   elseif key == self.left_button then
      self:try_move(-1,0)
   elseif key == self.right_button then
      self:try_move(1,0)
   end

   for i,e in ipairs(self.enemies) do
      local e_controls = e[3]
      if key == e_controls[1] then
	 self:try_enemy_move(i,0,-1)
      elseif key == e_controls[3] then
	 self:try_enemy_move(i,0,1)
      elseif key == e_controls[4] then
	 self:try_enemy_move(i,-1,0)
      elseif key == e_controls[2] then
	 self:try_enemy_move(i,1,0)
      end
   end

   self:gen_enemy_controls()
   self:gen_controls()

   for i,e in ipairs(self.enemies) do
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

function SB:from_dead() 
   self:load_level(levels[current_level])
end

function SB:try_move(x,y) 
   new_x, new_y = character_x + x, character_y + y
   
   if self:valid_move(new_x, new_y) then
      character_x = character_x + x
      character_y = character_y + y
   end
end

function SB:valid_move(x,y)
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
   self:draw_someone(CHARACTER, character_x, character_y, 
		     { self.up_button, self.right_button, self.down_button, self.left_button })
end

function SB:draw_enemies()
   for i,e in ipairs(self.enemies) do
      self:draw_someone(ENEMY, e[1], e[2], e[3])
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

   love.graphics.setColor(200,200,200,80)
   love.graphics.circle('fill', tile_x + tile_size / 2, tile_y + tile_size / 2, tile_size * 2)

   love.graphics.setColor(0,0,0)

   love.graphics.printf(controls[4], tile_x - 30, tile_y + 5, 20, "right")
   love.graphics.printf(controls[2], tile_x + 30, tile_y + 5, 20, "left")
   love.graphics.printf(controls[1], tile_x, tile_y - 23, 20, "center")
   love.graphics.printf(controls[3], tile_x, tile_y + 28, 20, "center")

   draw_tile(x,y,type)
end
