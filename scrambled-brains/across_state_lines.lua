require "underscore/underscore"

function change_ui_state(self, new_state_name)
   local old_state, new_state

   old_state_name = self.current_state_name
   old_state = self.state_graph[old_state_name]
   new_state = self.state_graph[new_state_name]

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

   self.current_state_name = new_state_name
end

-- "constructor"
function init_ui_graph(state_graph, first_state_name)
   local ui_state_manager = {
      state_graph = state_graph,
      change_ui_state = change_ui_state,
      current_state_name = first_state_name
      }

   local new_state = state_graph[first_state_name]
   
   -- Install state into 'love'...
   for n,m in pairs(new_state) do
      love[n] = function(...)
	 new_state[n](new_state,...)
      end
   end

   -- Install a change_ui_state method in each state for convenience...
   for n,m in pairs(state_graph) do
      function m:change_ui_state(s)
	 ui_state_manager:change_ui_state(s)
      end
   end

   return ui_state_manager
end

-- A trio of functions for building dazzlingly bad UIs right in the state graph literal.
function show_text(text, height)
   love.graphics.setColor(200,200,200)
   love.graphics.printf(text, 0, height, love.graphics.getWidth(), "center")
end

function state_thunk(s)
   return function(self)
      self:change_ui_state(s)
      end
end

function keymap_method(map) 
   return function(s, key, unicode) 
      (map[key] or _.identity)(s)
	  end
end
