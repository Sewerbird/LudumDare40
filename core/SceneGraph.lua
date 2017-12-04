local Stead = require('core/components/Stead')

local SceneGraph = {}

SceneGraph.__index = SceneGraph

SceneGraph.new = function(name, coordinate_system)
  local self = setmetatable({},SceneGraph)
  self.coordinate_space = coordinate_system --Used later for defining transformation
  self.gid = uuid()
  self.type = 'SceneGraph'
  self.name = name
  local root_gid = uuid()
  self.root = GS:add({
    gid = root_gid,
    stead = Stead.new({x = 0, y = 0, z = 0},nil)
  })
  return self
end

function SceneGraph:setParent(gid, new_parent)
  assert(GS[gid].stead and GS[new_parent].stead, F"Child and new parent must both have Steads, but child has {inspect(GS[gid].stead} and new parent has {inspect(GS[new_parent].stead)}")
  assert(not GS[gid].stead.parent or GS[GS[gid].parent].stead, F"Old parent must have a stead, but has {inspect(GS[GS[gid].parent].stead")
  GS[GS[gid].stead.parent].children[gid] = nil
  GS[gid].stead.parent = new_parent
  GS[GS[gid].stead.parent].children[gid] = true
  return gid
end

function SceneGraph:traverse(root_gid, pre_fn, in_fn, post_fn)
  local pre, post

  if pre_fn then
    pre = pre_fn(self, root_gid)
  end

  assert(GS[root_gid], F"UID not present in GS {root_gid}")
  if GS[root_gid].stead and GS[root_gid].stead.children then
    for key, _ in pairs(GS[root_gid].stead.children) do
      local in_pre, in_post = self:traverse(key, pre_fn, in_fn, post_fn)
      if in_fn then in_fn(self, root_gid, in_pre, in_post) end
    end
  end

  if post_fn then post = post_fn(self, root_gid) end

  return pre, post
end

function SceneGraph:ascend(tgt_gid, fn)
  local val = fn(tgt_gid)
  if GS[tgt_gid][self.name].parent then
    self:ascend(GS[tgt_gid][self.name].parent)
  end
  return val
end

return SceneGraph
