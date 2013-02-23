_ = require "underscore/underscore"
require "across_state_lines"

sb = require "SB"

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
   game = _.extend(sb, { to = {'pause', 'win', 'dead' } }),
   dead = {
      draw = function() 
	 show_text("-- You have died. --", 100)
	 show_text("Press any key to restart level.", 140)
      end,
      keypressed = state_thunk("game"),
      to = { 'game' },
   },
   pause = {
      draw = function() 
	 show_text("** Press any key to unpause **", 100) 
	 show_text("Deaths: " .. tostring(SB:stats().deaths), 140)
	 show_text("Moves: " .. tostring(SB:stats().moves), 160)
      end,
      keypressed = state_thunk("game"),
      to = { 'game', 'main' }
   },
   win = {
      draw = function() show_text("You've won! Press any key.", 100) end,
      keypressed = state_thunk("main"),
      to = { 'main' }
   }
}

init_ui_graph(UI_STATES, 'main')
