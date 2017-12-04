local Behaviour = {}
Behaviour.__index = Behaviour
Behaviour.new = function(onEnter, onUpdate, onExit)
  local self = setmetatable({},Behaviour)
  self.onEnter = onEnter or nil
  self.onExit = onExit or nil
  self.onUpdate = onUpdate or nil
  return self
end
return Behaviour
