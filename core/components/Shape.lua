local Rectangle = {}
local Circle = {}
local Ellipse = {}
local Polygon = {}
local Iso = {}

local Shape = {}

Shape.__index = Shape
Circle.__index = Circle
Rectangle.__index = Rectangle
Iso.__index = Rectangle
Ellipse.__index = Ellipse
Polygon.__index = Polygon

Shape.circle = function(radius,rotation,o_x, o_y)
  local self = setmetatable({}, Circle)
  self.shape = 'circle'
  self.radius = radius
  self.rotation = rotation or 0
  self.origin_x = o_x or 0
  self.origin_y = o_y or 0
  return self
end

Shape.rect = function(width,height,rotation,o_x,o_y)
  local self = setmetatable({}, Rectangle)
  self.shape = 'rect'
  self.width = width
  self.height = height
  self.rotation = rotation or 0
  self.origin_x = o_x or 0
  self.origin_y = o_y or 0
  return self
end

Shape.iso = function(width,height,rotation,o_x,o_y)
  local self = setmetatable({}, Iso)
  self.shape = 'iso'
  self.width = width
  self.height = height
  self.rotation = rotation or 0
  self.origin_x = o_x or 0
  self.origin_y = o_y or 0
  return self
end

Shape.ellipse = function(width,height,rotation, o_x, o_y)
  local self = setmetatable({}, Ellipse)
  self.shape = 'ellipse'
  self.width = width
  self.height = height
  self.rotation = rotation or 0
  self.origin_x = o_x or 0
  self.origin_y = o_y or 0
end

Shape.polygon = function(points, rotation, o_x, o_y)
  local self = setmetatable({}, Polygon)
  self.shape = 'polygon'
  self.points = points
  self.rotation = rotation or 0
  self.origin_x = o_x or 0
  self.origin_y = o_y or 0
end

--Rectangle
function Rectangle:contains(test_x, test_y)
  return math.contains(test_x, self.origin_x - self.width/2, self.width/2 + self.origin_x)
     and math.contains(test_y, self.origin_y - self.height/2, self.height/2 + self.origin_y)
end

function Rectangle:draw()
  love.graphics.push()
  love.graphics.translate(self.origin_x, self.origin_y)
  love.graphics.rectangle('line', 0, 0, self.width, self.height)
  love.graphics.pop()
end

function Rectangle:randomWithin()
  return {x = 0, y = 0, z = 0}
end

--Circle
function Circle:contains(test_x, test_y)
  return math.dist({test_x,test_y}, {self.origin_x, self.origin_y}) < self.radius
end

function Circle:draw(style)
  love.graphics.push()
  love.graphics.translate(self.origin_x, self.origin_y)
  love.graphics.circle(style and style or 'line', 0, 0, self.radius)
  love.graphics.pop()
end

function Circle:randomWithin()
  return {x = 0, y = 0, z = 0}
end

--Iso
function Iso:contains(test_x, test_y)
  return math.abs(test_y-self.origin_y) < (self.height/2)-(self.height/self.width * math.abs(test_x-self.origin_x))
end

function Iso:draw()
  love.graphics.push()
  love.graphics.translate(self.origin_x, self.origin_y)
  love.graphics.polygon('line',-self.width/2,0 , 0,self.width/2 , self.width/2,0 , 0,-self.weight/2)
  love.graphics.pop()
end

function Iso:randomWithin()
  return {x = 0, y = 0, z = 0}
end

--Ellipse
function Ellipse:contains(test_x, test_y)
  assert(false, "Sorry, ellipse isn't completely implemented yet")
end

function Ellipse:draw()
  love.graphics.push()
  love.graphics.translate(self.origin_x, self.origin_y)
  love.graphics.ellipse('line', 0,0, self.width, self.height)
  love.graphics.pop()
end

function Ellipse:randomWithin()
  return {x = 0, y = 0, z= 0}
end

--Polygon
function Ellipse:contains(test_x, test_y)
  assert(false, "Sorry, polygon isn't completely implemented yet")
end

function Polygon:draw()
  love.graphics.push()
  love.graphics.translate(self.origin_x, self.origin_y)
  love.graphics.polygon('line',self.points)
  love.graphics.pop()
end

function Polygon:randomWithin()
  return {x = 0, y = 0, z = 0}
end

return Shape
