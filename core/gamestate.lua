local Gamestate = {}

Gamestate.__index = Gamestate 

Gamestate.new = function (init)
  local self = setmetatable({}, Gamestate)

  self.scenes = {}

  return self
end

--Scene Stack
function Gamestate:currentScene()
  return self[self.scenes[#self.scenes]]
end

function Gamestate:pushScene(scene)
  return table.insert(self.scenes,scene)
end

function Gamestate:popScene()
  return table.remove(self.scenes,#self.scenes)
end

--Game element constructors
function Gamestate:addBlank(init)
  local gid = uuid()
  init = init or {}
  init.gid = gid
  self[gid] = init
  return gid
end

function Gamestate:addBlanks(num)
  local results = {}
  for i = 1, num do
    table.insert(results,self:addBlank())
  end
  return results
end

function Gamestate:add(gob)
  assert(gob.gid, 'Game object must have a `gid` field with a uuid, but received ' .. inspect(gob))
  self[gob.gid] = gob
  return gob.gid
end

function Gamestate:addAll(gobset)
  local gids= {}
  for i, gob in ipairs(gobset) do
    self:add(gob)
    table.insert(gids, gob.gid)
  end
  return gids
end

function Gamestate:remove(gid)
  assert(self[gid], "Gid " .. inspect(gid) .. " does not exist, so cannot be removed.")
  self[gid] = nil
end

return Gamestate
