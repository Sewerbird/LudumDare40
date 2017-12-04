local Shape = require('core/components/Shape')
local Stead = require('core/components/Stead')
local Splat = require('core/components/Splat')

local Tile = {}
Tile.__index = Tile
Tile.new = function(init)
  local self = setmetatable({},Tile)
  self.gid = init.gid or uuid()
  self.type = 'Tile'
  self.tag = init.tag or nil
  self.path_distance_to_exit = init.path_distance_to_exit or 99
  self.blocks_vision = (init.blocks_vision == true) or false
  self.blocks_hearing = (init.blocks_hearing == true) or false
  self.passable = (init.passable == true) or false
  self.stead = init.stead or Stead.new(self.gid, {x = 0, y = 0, z = 0, row = 0, col = 0}, nil)
  self.shape = init.shape or Shape.iso(2,1)
  self.splat = init.splat or nil --Splat.new(Assets.img.stair, {Assets.quad.stair}, 1/10, 0, 0, tile_size_in_pixels/115, tile_size_in_pixels/115)
  self.designations = {}
  for i, designation in ipairs(init.designations or {}) do
    print(F"Setting designation {designation}")
    self.designations[designation] = true
  end
  return self
end
Tile.create = function(init)
  local n = Tile.new(init)
  if n.stead and n.stead.parent then
    GS[n.stead.parent].stead.children[n.gid] = true
  end
  return GS:add(n)
end
function Tile:draw()
  love.graphics.push()
  if self.splat then self.splat:draw() end
  local k = 0
  for a, b in pairs(self.stead.children) do
    k = k + 1
  end
  --love.graphics.print(F"{self.stead.boardspace.row},{self.stead.boardspace.col}\n{self.path_distance_to_exit}",0,0)
  --if self.DEBUG_SELECT then
  --  love.graphics.setColor(0,255,255,100)
  --  love.graphics.rectangle('fill',0,0,tile_size_in_pixels,tile_size_in_pixels)
  --end
  love.graphics.pop()
end
return Tile
