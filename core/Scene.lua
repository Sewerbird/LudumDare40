local EventQueue = require('core/EventQueue')
local MessageBus = require('core/MessageBus')
local SceneGraph = require('core/SceneGraph')

local OrthographicCamera = {}
OrthographicCamera.__index = OrthographicCamera
OrthographicCamera.new = function(graph, target)
  local self = setmetatable({},OrthographicCamera)
  self.gid = uuid()
  self.graph = graph
  self.target = target
  self.cache = nil
  self.debugFont = love.graphics.newFont(8)
  return self
end
function OrthographicCamera:refreshCache()
  local scene_ids = {}
  --GS[self.graph]:traverse(self.target,function(self, gid)
  --  table.insert(scene_ids, gid)
  --end)
  for k, v in pairs(GS) do
    if v.stead then
      table.insert(scene_ids, k)
    end
  end
  table.sort(scene_ids, function(a,b)
    assert(GS[a].stead.worldspace.z, F"{inspect(GS[a].stead.worldspace)}")
    assert(GS[b].stead.worldspace.z, F"{inspect(GS[b].stead.worldspace)}")
    return GS[a].stead.worldspace.z < GS[b].stead.worldspace.z 
  end)
  self.cache = scene_ids
end
function OrthographicCamera:update()
  --Sort scenegraph by Z
  if self.cache == nil then self:refreshCache() end
end

function OrthographicCamera:draw()
  love.graphics.setBackgroundColor(200,200,200,255)
  love.graphics.setFont(self.debugFont)
  --love.graphics.translate(200,150)
  if self.cache == nil then self:refreshCache() end
  local scene_ids = self.cache
  assert(#scene_ids > 0, "Scene id cache is empty.")
  --Draw all
  for i, gid in ipairs(scene_ids) do
    love.graphics.push()
    if GS[gid].stead then
      love.graphics.translate(GS[gid].stead.screenspace.s_x, GS[gid].stead.screenspace.s_y)
    end
    if GS[gid].draw then
      GS[gid]:draw()
    elseif GS[gid].splat then
      GS[gid].splat:draw()
    end
    love.graphics.pop()
  end
end

local Scene = {}

Scene.__index = Scene

Scene.new = function (init)
  local self = setmetatable({},Scene)
  self.gid = uuid()
  self.input_queue = EventQueue.new() --For when the players want a say
  self.message_bus = MessageBus.new() --For notifying the game objects
  self.scenegraph = GS:add(SceneGraph.new()) --Define a scenegraph with a default origin root
  self.camera = GS:add(OrthographicCamera.new(self.scenegraph, GS[self.scenegraph].root)) --Specify a camera for the scene
  
  --Subscribe to standard events
  self.message_bus:subscribe(self.gid, "mouse", function() end)
  self.message_bus:subscribe(self.gid, "keyboard", function() end)
  self.message_bus:subscribe(self.gid, "time", function() end)
  self.message_bus:subscribe(self.gid, self.gid, function() end)

  return self
end

function Scene:draw()
  GS[self.camera]:draw()
end

function Scene:update(dt)
  if GS[self.level].state == 'GAMEOVER' then return end
  if GS[self.level].state == 'LEVELDONE' then return end
  self.input_queue:update(dt)
  GS[self.camera]:update(dt)

  self.time_accumulator = self.time_accumulator and self.time_accumulator + dt or dt
  if self.time_accumulator > 0.5 then
    self.message_bus:publish('tick','tick',{})
    self.time_accumulator = self.time_accumulator - 0.5
  end
end

function Scene:input(channel, event)
  local scene = self
  event.begin = function(self)
    GS[scene.gid].message_bus:publish(channel, event.name, event)
  end
  self.input_queue:add(channel, event)
end

function Scene:addToScene(gids, parent, x, y, z)
  x = x or 0
  y = y or 0
  z = z or 0
  if type(gids) ~= "table" then
    gids = { gids }
  end
  for i, gid in ipairs(gids) do
    GS[self.scenegraph]:place(gid, parent, x, y, z)
  end
end

return Scene
