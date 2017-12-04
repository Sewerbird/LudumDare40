local Shape = require('core/components/Shape')
local Stead = require('core/components/Stead')
local Splat = require('core/components/Splat')

local Taxi = {}
Taxi.__index = Taxi
Taxi.new = function(init)
  local self = setmetatable({}, Taxi)
  self.gid = init.gid or uuid()
  self.type = 'Piece'
  self.tag = 'Taxi'
  self.stead = init.stead
  self.shape = Shape.circle(tile_size_in_pixels/2,1,tile_size_in_pixels/2,tile_size_in_pixels/2)
  self.splat = Splat.new(Assets.img.taxi, {Assets.quad.taxi}, 1/10, 0, 2*tile_size_in_pixels, 2*tile_size_in_pixels/186, 5*tile_size_in_pixels/482,-math.pi/2)
  self.passenger = false
  return self
end
Taxi.create = function(init)
  local n = Taxi.new(init)
  if n.stead and n.stead.parent then
    GS[n.stead.parent].stead.children[n.gid] = true
  end
  return GS:add(n)
end
function Taxi:draw()
  love.graphics.push()
  love.graphics.setColor(255,255,200)
  self.splat:draw('fill')
  if self.passenger then
    love.graphics.setColor(255,125,200)
    love.graphics.circle('fill',0,0,3)
  end
  love.graphics.pop()
end
function Taxi:tick()
  --Called whenever a turn passes
  local current = GS[GS:currentScene().board]:search('Tile',nil,self.stead.boardspace.row, self.stead.boardspace.col)
  local tgt = nil
  if self.passenger and GS[current[1]] and GS[current[1]].designations and GS[current[1]].designations["Taxi_Drop_Off"] then
    local alightment = GS[GS:currentScene().board]:searchByDesignation('Tile',"Taxi_Passenger_Alight")[1]
    GS[self.passenger].state:disembark()
    GS[self.passenger]:moveToTile(alightment)
    self.passenger = nil
    self.pause_at_curb_timer = 5
  elseif not self.passenger and GS[current[1]] and GS[current[1]].designations and GS[current[1]].designations["Taxi_Drop_Off"] then
    --TODO: do passenger alighting
    self.pause_at_curb_timer = self.pause_at_curb_timer - 1
  end
  if self.pause_at_curb_timer and self.pause_at_curb_timer > 0 then
    tgt = nil
  elseif GS[current[1]] then
    if self.passenger and GS[current[1]].designations["Taxi_Begin_Pull_Over"] then
      tgt = GS[GS:currentScene().board]:search('Tile',nil,self.stead.boardspace.row+1, self.stead.boardspace.col-1)
    elseif GS[current[1]].designations["Taxi_End_Pull_Over"] then
      tgt = GS[GS:currentScene().board]:search('Tile',nil,self.stead.boardspace.row+1, self.stead.boardspace.col)
    elseif GS[current[1]].designations["Taxi_Begin_Pull_Away"] then
      tgt = GS[GS:currentScene().board]:search('Tile',nil,self.stead.boardspace.row+1, self.stead.boardspace.col+1)
    elseif GS[current[1]].designations["Taxi_End_Pull_Away"] then
      tgt = GS[GS:currentScene().board]:search('Tile',nil,self.stead.boardspace.row+1, self.stead.boardspace.col)
    else
      tgt = GS[GS:currentScene().board]:search('Tile',nil,self.stead.boardspace.row+1, self.stead.boardspace.col)
    end
  else
    tgt = GS[GS:currentScene().board]:search('Tile',nil,self.stead.boardspace.row+1, self.stead.boardspace.col)
  end
  if tgt and #tgt > 0 then 
    self:moveToTile(tgt[1])
  elseif self.stead.boardspace.row == 30 then
    tgt = GS[GS:currentScene().board]:search('Tile',nil,1, self.stead.boardspace.col)
    if tgt and #tgt > 0 then self:moveToTile(tgt[1]) end
  end
end
function Taxi:update(dt)
  --Called as time passes
end
function Taxi:moveToTile(tile_gid)
  local tgt = tile_gid
  if tgt and GS[tgt].passable then
    self.stead.boardspace.col = GS[tgt].stead.boardspace.col
    self.stead.worldspace.x = GS[tgt].stead.worldspace.x
    self.stead.screenspace.s_x = GS[tgt].stead.screenspace.s_x
    self.stead.boardspace.row = GS[tgt].stead.boardspace.row
    self.stead.worldspace.y = GS[tgt].stead.worldspace.y
    self.stead.screenspace.s_y = GS[tgt].stead.screenspace.s_y
    self.stead.parent = tgt
  end
end

return Taxi
