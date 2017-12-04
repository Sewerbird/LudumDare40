local Splat = {}

Splat.__index = Splat

Splat.new = function(sheet, frames, frame_duration, origin_x, origin_y, scale_x, scale_y, rotation)
  local self = setmetatable({},Splat)
  self.frames = frames
  self.sheet = sheet
  self.curr_frame = 1
  self.timer = 0
  self.frame_duration = frame_duration or 1/60
  self.origin_x = origin_x or 0
  self.origin_y = origin_y or 0
  self.scale_x = scale_x or 1.0
  self.scale_y = scale_y or 1.0
  self.rotation = rotation or 0
  self.red = red or 255
  self.green = green or 255
  self.blue = blue or 255
  return self
end

function Splat:update(dt)
  self.timer = self.timer + dt
  if self.timer > self.frame_duration then
    self.timer = self.timer - self.frame_duration
    self.curr_frame = math.mod(self.curr_frame,#self.frames)+1
  end
end

function Splat:draw()
  love.graphics.push()
  love.graphics.translate(self.origin_x,self.origin_y)
  love.graphics.setColor(self.red,self.green,self.blue)
  love.graphics.draw(self.sheet, self.frames[self.curr_frame],0,0,self.rotation,self.scale_x,self.scale_y)
  love.graphics.setColor(255,255,255)
  love.graphics.pop()
end

return Splat
