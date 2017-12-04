local Layer = {}
Layer.__index = Layer
Layer.new = function(init)
  local self = setmetatable({},Layer)
  self.gid = init.gid or uuid()
  self.type = 'Layer'
  self.stead = init.stead or Stead.new(self.gid)
  return self
end
Layer.create = function(init)
  local n = Layer.new(init)
  if n.stead and n.stead.parent then
    GS[n.stead.parent].stead.children[n.gid] = true
  end
  return GS:add(n)
end

return Layer
