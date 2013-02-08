
EMPTY = 0
GOAL = 1
BLOCK = 2
CHARACTER = 3

SB = {
   letter_set = {'a','s','d','f','g','h','j','k','l',';'}
}

levels = {
   { goal_tile = { 10, 12 }, start_tile = { 10, 8 }, blocks = { { 5,5 }, { 5, 15}, {15,5}, {15,15} } },
--[[   
   { goal_tile = { 10, 15 }, start_tile = { 10, 5 }, blocks = { { 10,10 } } },
   { goal_tile = { 5, 5 }, start_tile = { 15, 15 }, blocks = { { 10,10 }, { 9, 11 }, { 11, 9 }, { 12, 8 }, { 8, 12 }, { 13, 7 }, { 7, 13 } } }
   --]]
}

PAUSE_BUTTON = 'p'

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

function SB:gen_controls(level)
   local t, i
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

function SB:from_main() 
   playfield_height = 20
   playfield_width = 20
   tile_size = 20

   character = {x = 0, y = 0, width = tile_size, height = tile_size}

   screen = {screenx = 0, screeny = 0}

   playfield = {}

   self:gen_controls()

   current_level = 1
   self:load_level(levels[current_level])
end

function SB:load_level(level)
   for y=1,playfield_height do
      playfield[y] = {}

      for x=1,playfield_width do
	 playfield[y][x] = 0
      end
   end

   playfield[level.goal_tile[2]][level.goal_tile[1]] = GOAL

   for i=1,#level.blocks do
      block_x, block_y = unpack(level.blocks[i])
      playfield[block_y][block_x] = BLOCK
   end

   character_x = level.start_tile[1]
   character_y = level.start_tile[2]
end


function SB:keypressed(key, unicode)
   if key == PAUSE_BUTTON then
      self:change_ui_state('pause')
      return
   end

   -- Note: Must be elseif because try_move changes controls
   if key == self.up_button then
      self:try_move(0,-1)
   elseif key == self.down_button then
      self:try_move(0,1)
   elseif key == self.left_button then
      self:try_move(-1,0)
   elseif key == self.right_button then
      self:try_move(1,0)
   end

   if playfield[character_y][character_x] == GOAL then
      current_level = current_level + 1
      if current_level > #levels then
	 self:change_ui_state("win")
	 return 
      end
      self:load_level(levels[current_level])
   end
end

function SB:try_move(x,y) 
   new_x, new_y = character_x + x, character_y + y

   if (new_x > 0 and new_x <= playfield_width and
      new_y > 0 and new_y <= playfield_height and
       playfield[new_y][new_x] ~= 2) then
      character_x = character_x + x
      character_y = character_y + y
   end

   self:gen_controls()
end

function SB:draw() 
   self:draw_level()
   self:draw_character()
end

function SB:draw_level()
   for y=1,playfield_height do
      for x=1,playfield_width do
	 draw_tile(x,y,playfield[y][x])
      end
   end
end


tile_type_colors = {}
tile_type_colors[EMPTY] = {150,180,200}
tile_type_colors[GOAL] = {200,255,200}
tile_type_colors[BLOCK] = {50,0,0}
tile_type_colors[CHARACTER] = {20,20,200}


function SB:draw_character()
   tile_x = screen.screenx + ((character_x - 1) * tile_size)
   tile_y = screen.screeny + ((character_y - 1) * tile_size)

   love.graphics.setColor(200,200,200,80)
   love.graphics.circle('fill', tile_x + tile_size / 2, tile_y + tile_size / 2, tile_size * 2)

   love.graphics.setColor(0,0,0)

   love.graphics.printf(self.left_button, tile_x - 30, tile_y + 5, 20, "right")
   love.graphics.printf(self.right_button, tile_x + 30, tile_y + 5, 20, "left")
   love.graphics.printf(self.up_button, tile_x, tile_y - 23, 20, "center")
   love.graphics.printf(self.down_button, tile_x, tile_y + 28, 20, "center")

   love.graphics.setColor(230,230,230)
   draw_tile(character_x,character_y,CHARACTER)
end
