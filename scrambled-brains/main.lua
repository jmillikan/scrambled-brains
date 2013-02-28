_ = require "underscore/underscore"
require "across_state_lines"

require "SB"

UI_STATES = { 
   main = {
      draw = function() 
	 show_text("Scrambled Brains", 100)
	 show_text("Press n to start", 140)
	 show_text("Press i to see instructions", 180)
	 show_text("Press k to change keys", 220)
	 show_text("(default is U.S. homerow)", 240)
      end,
      keypressed = keymap_method({ n = state_thunk("game"), i = state_thunk("instructions"), k = state_thunk("rebind_keys") }),
      to = { 'game', 'instructions', 'rebind_keys' }
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
   present_level = _.extend(present_level, { to = {'game'} }),
   game = _.extend(game, { to = {'present_level', 'pause', 'win', 'dead' } }),
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
	 show_text("Deaths: " .. tostring(game:stats().deaths), 140)
	 show_text("Moves: " .. tostring(game:stats().moves), 160)
      end,
      keypressed = state_thunk("game"),
      to = { 'game', 'main' }
   },
   win = {
      draw = function() show_text("You've won! Press any key.", 100) end,
      keypressed = state_thunk("main"),
      to = { 'main' }
   },
   rebind_keys = _.extend(rebind_keys, { to = {'rebind_keys_2'} }),
   rebind_keys_2 = _.extend(rebind_keys_2, { to = {'main'} })
}

init_ui_graph(UI_STATES, 'main')
