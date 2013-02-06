_ = require "underscore/underscore"
   
levels = {
   { goal_tile = { 10, 12 }, start_tile = { 10, 8 }, blocks = { { 5,5 }, { 5, 15}, {15,5}, {15,15} } },
   { goal_tile = { 10, 15 }, start_tile = { 10, 5 }, blocks = { { 10,10 } } },
   { goal_tile = { 5, 5 }, start_tile = { 15, 15 }, blocks = { { 10,10 }, { 9, 11 }, { 11, 9 }, { 12, 8 }, { 8, 12 }, { 13, 7 }, { 7, 13 } } }
}

function love.load()
   GAME_STATE = 'init'

   playfield_height = 20
   playfield_width = 20
   tile_size = 20

   character = {x = 0, y = 0, width = tile_size, height = tile_size}

   playfield = {}

   gen_controls()

   current_level = 1
   load_level(levels[current_level])

   screen = {screenx = 0, screeny = 0}

   change_game_state('main')
end

EMPTY = 0
GOAL = 1
BLOCK = 2
CHARACTER = 3

function load_level(level)
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

letter_set = {'a','s','d','f','g','h','j','k','l',';'}

function gen_controls(level)
   local t, i

   for i=1,4 do
      selected = math.random(#letter_set - i + 1)
      t = letter_set[i]
      letter_set[i] = letter_set[selected]
      letter_set[selected] = t
   end

   up_button = letter_set[1]
   down_button = letter_set[2]
   left_button = letter_set[3]
   right_button = letter_set[4]
end

PAUSE_BUTTON = 'p'

SB = {
   to = {
      pause = { }
   }
}

function SB:keypressed(key, unicode)
   if key == PAUSE_BUTTON then
      change_game_state('pause')
      return
   end

   -- Note: Must be elseif because try_move changes controls
   if key == up_button then
      try_move(0,-1)
   elseif key == down_button then
      try_move(0,1)
   elseif key == left_button then
      try_move(-1,0)
   elseif key == right_button then
      try_move(1,0)
   end

   if playfield[character_y][character_x] == GOAL then
      current_level = current_level + 1
      if current_level > #levels then
	 current_level = 1 -- BRILLIANT
      end
      load_level(levels[current_level])
   end
end

function try_move(x,y) 
   new_x, new_y = character_x + x, character_y + y

   if (new_x > 0 and new_x <= playfield_width and
      new_y > 0 and new_y <= playfield_height and
       playfield[new_y][new_x] ~= 2) then
      character_x = character_x + x
      character_y = character_y + y
   end

   gen_controls()
end

function SB:draw() 
   draw_level()
   draw_character()
end

function draw_level()
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

function draw_tile(x,y,tile_type)
   r,g,b = unpack(tile_type_colors[tile_type])
   love.graphics.setColor(r,g,b)
   draw_game_rect({width = tile_size, height=tile_size, x = (x - 1) * tile_size, y = (y - 1) * tile_size})
end

function draw_character()
   tile_x = screen.screenx + ((character_x - 1) * tile_size)
   tile_y = screen.screeny + ((character_y - 1) * tile_size)

   love.graphics.setColor(200,200,200,80)
   love.graphics.circle('fill', tile_x + tile_size / 2, tile_y + tile_size / 2, tile_size * 2)

   love.graphics.setColor(0,0,0)

   love.graphics.printf(left_button, tile_x - 30, tile_y + 5, 20, "right")
   love.graphics.printf(right_button, tile_x + 30, tile_y + 5, 20, "left")
   love.graphics.printf(up_button, tile_x, tile_y - 23, 20, "center")
   love.graphics.printf(down_button, tile_x, tile_y + 28, 20, "center")

   love.graphics.setColor(230,230,230)
   draw_tile(character_x,character_y,CHARACTER)
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

function show_text(text, height)
   love.graphics.setColor(200,200,200)
   love.graphics.printf(text, 0, 100 + height, love.graphics.getWidth(), "center")
end

function state_thunk(s)
   return function()
      change_game_state(s)
      end
end

function keymap_method(map) 
   return function(s, key, unicode) 
      if map[key] ~= nil then
	 map[key]()
      end
	  end
end

function change_game_state(new_state_name)
   local old_state, i, new_state, n, m
   old_state = GAME_STATES[GAME_STATE]
   if old_state == nil or old_state.to == nil or old_state.to[new_state_name] == nil then error("Invalid state change") end
   for i=1,#old_state.to[new_state_name] do
      old_state.to[new_state_name][i]()
   end

   new_state = GAME_STATES[new_state_name]

   for n,m in pairs(new_state) do
      love[n] = function(...)
	 new_state[n](new_state,...)
      end
   end

   GAME_STATE = new_state_name
end

GAME_STATES = { 
   init = {
      to = {
	 main = { }
      }
   },
   main = {
      draw = function() 
	 show_text("Welcome to scrambled brains", 0)
	 show_text("Press n to start", 40)
	 show_text("Press i to see instructions", 80)
      end,
      keypressed = keymap_method({ n = state_thunk("game"), i = state_thunk("instructions") }),
      to = {
	 game = { },
	 instructions = { }
      }
   },
   instructions = {
      draw = function()
	 show_text("You are the blue square.", 0)
	 show_text("Get to the green square.", 20)
	 show_text("The controls are shown on your character - ", 40)
	 show_text("but they change with each step.", 60)
	 show_text("Press any key to continue.", 100)
      end,
      keypressed = state_thunk("main"),
      to = {
	 main = { }
      }
   },
   game = SB,
   pause = {
      draw = function() show_text("** Press any key to unpause **", 0) end,
      keypressed = state_thunk("game"),
      to = {
	 game = { },
	 main = { }
      }
   }
}
