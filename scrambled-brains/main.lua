_ = require "underscore/underscore"
require "SB"
   
function love.load()
   init_ui_state('main')
end

function show_text(text, height)
   love.graphics.setColor(200,200,200)
   love.graphics.printf(text, 0, height, love.graphics.getWidth(), "center")
end

function state_thunk(s)
   return function()
      change_ui_state(s)
      end
end

function keymap_method(map) 
   return function(s, key, unicode) 
      if map[key] ~= nil then
	 map[key]()
      end
	  end
end

function init_ui_state(first_state)
   local new_state = UI_STATES[first_state]
   
   for n,m in pairs(new_state) do
      love[n] = function(...)
	 new_state[n](new_state,...)
      end
   end

   for n,m in pairs(UI_STATES) do
      m.change_ui_state = function(self,s)
	 change_ui_state(s)
      end
   end

   UI_STATE = first_state
end

function change_ui_state(new_state_name)
   local old_state, i, new_state, n, m

   old_state_name = UI_STATE
   old_state = UI_STATES[old_state_name]
   new_state = UI_STATES[new_state_name]

   if old_state == nil or old_state.to == nil or not _.include(old_state.to, new_state_name) then error("Invalid state change") end

   for n,m in pairs(old_state) do
      love[n] = nil
   end

   -- Note: This does incorrectly copy to, to_* and from_* into love as weird broken functions.
   for n,m in pairs(new_state) do
      love[n] = function(...)
	 new_state[n](new_state,...)
      end
   end

   (old_state['to_'..new_state_name] or _.identity)(old_state);
   (new_state['from_'..old_state_name] or _.identity)(new_state)

   UI_STATE = new_state_name
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
