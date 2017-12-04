local LinearCoordinate = {}

LinearCoordinate.__index = LinearCoordinate

LinearCoordinate.new = function (system, ...)
  local self = setmetatable({}, LinearCoordinate)
  local args = {...}
  for i, field in ipairs(system.fields) do
    if not args[i] then args[i] = system.defaults[field] end
    self[field] = args[i]
  end
  self.system = system.gid
  return self
end

function LinearCoordinate:translate(...)
  local args = {...}
  if #args == 1 and  type(args[1]) == 'table' then
    args = args[1]
    for field, value in pairs(args) do
      if not value then value = 0 end
      self[field] = self[field] + value
    end
  else
    for i, field in ipairs(self.system.fields) do
      self[field] = self[field] + args[i]
    end
  end
  return self
end

local Position = {}
Position.__index = Position
Position.spaces = {
  screenspace = {
    fields = {"x","y"},
    defaults = {0,0}
  },
  worldspace  = {
    fields = {"x","y","z"},
    defaults = {0,0}
  },
  boardspace = {
    fields = {"row","col","z"},
    defaults = {0,0,0}
  }
}
Position.new = function(...)
  local self = setmetatable({},Position)
  for space, params in pairs(Position.spaces) do
    self[space] = {}
    for i, field in ipairs(params.fields) do
      self[space][field] = Position.spaces[space].defaults[i]
    end
  end
  return self
end
return Position

local CoordinateSystem = {}

CoordinateSystem.__index = CoordinateSystem

CoordinateSystem.new = function (name, type, fields, defaults)
  local self = setmetatable({},CoordinateSystem)
  self.gid = uuid()
  self.type = 'Cartesian' or type
  self.name = name
  self.definesTo = {}
  self.definesFrom = {}
  self.fields = { 'x', 'y', 'z' } or fields
  self.defaults = { x = 0, y = 0, z = 0 } or defaults
  return self
end

function CoordinateSystem:create(x, y, z)
  return LinearCoordinate.new(self, x, y, z)
end

function CoordinateSystem:place(gid, x, y, z)
  GS[gid][self.name] = self:create(x, y, z)
  return gid
end

function CoordinateSystem:translate(gid, x, y, z)
  local args = {x, y, z}
  for i, field in ipairs(self.fields) do
    GS[gid][self.name][field] = GS[gid][self.name][field] + args[i]
  end
end

function CoordinateSystem:untranslate(gid, x, y, z)
  local args = {x, y, z}
  for i, field in ipairs(self.fields) do
    GS[gid][self.name][field] = GS[gid][self.name][field] - args[i]
  end
end

function CoordinateSystem:convertToSystem(them_system, me_coord)
  assert(self.definesTo[them_system], F"No conversion from me to {them_system} defined yet")
  return self.definesTo[them_system](me_coord)
end

function CoordinateSystem:convertFromSystem(them_system, them_coord)
  assert(self.definesFrom[them_system], F"No conversion from {them_system} to me defined yet")
  return self.definesFrom[them_system](them_coord)
end

function CoordinateSystem:defineTo(tgt_system_name, fn)
  self.definesTo[tgt_system_name] = fn
end

function CoordinateSystem:defineFrom(tgt_system_name, fn)
  self.definesFrom[tgt_system_name] = fn
end

return CoordinateSystem

