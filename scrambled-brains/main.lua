_ = require "underscore/underscore"
require "SB"
require "across_state_lines"
   
function love.load()
   ui_manager = init_ui_graph(UI_STATES, 'main')
end

function show_text(text, height)
   love.graphics.setColor(200,200,200)
   love.graphics.printf(text, 0, height, love.graphics.getWidth(), "center")
end

function state_thunk(s)
   return function()
      ui_manager:change_ui_state(s)
      end
end

function keymap_method(map) 
   return function(s, key, unicode) 
      (map[key] or _.identity)()
	  end
end

UI_STATES = { 
   main = {
      draw = function() 
	 show_text("Scrambled Brains", 100)
	 show_text("Press n to start", 140)
	 show_text("Press i to see instructions", 180)
      end,
      keypressed = keymap_method({ n = state_thunk("game"), i = state_thunk("instructions") }),
      to = { 'game', 'instructions' }
   },
   instructions = {
      draw = function()
	 show_text("You are the blue square.", 100)
	 show_text("Get to the green square.", 120)
	 show_text("The controls are shown on your character - ", 140)
	 show_text("but they change with each step.", 160)
	 show_text("Press any key to continue.", 200)
      end,
      keypressed = state_thunk("main"),
      to = { 'main' }
   },
   game = _.extend(SB, { to = {'pause', 'win'} }),
   pause = {
      draw = function() show_text("** Press any key to unpause **", 100) end,
      keypressed = state_thunk("game"),
      to = { 'game', 'main' }
   },
   win = {
      draw = function() show_text("You've won! Press any key.", 100) end,
      keypressed = state_thunk("main"),
      to = { 'main' }
   }
}
