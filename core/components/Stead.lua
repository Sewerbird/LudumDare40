local Stead = {}
Stead.__index = Stead
Stead.spaces = {
  screenspace = {
    fields = {"s_x","s_y"},
    defaults = {0,0}
  },
  worldspace  = {
    fields = {"x","y","z"},
    defaults = {0,0,0}
  },
  boardspace = {
    fields = {"row","col","z"},
    defaults = {0,0,0}
  }
}
Stead.setCamera = function(camera)
  Stead.camera = camera
end

Stead.setBoard = function(board)
  Stead.board = board
end

Stead.new = function(pos_table, parent)
  local self = setmetatable({},Stead)
  self.parent = parent
  self.children = {}
  for space, params in pairs(Stead.spaces) do
    self[space] = {}
    for i, field in ipairs(params.fields) do
      self[space][field] = pos_table[field] or Stead.spaces[space].defaults[i]
    end
  end
  return self
end

function Stead:translate(dx,dy,dz)
  self.worldspace.x = self.worldspace.x + dx
  self.worldspace.y = self.worldspace.y + dy
  self.worldspace.z = self.worldspace.z + dz
  for i, child in ipairs(self.children) do
    GS[child].stead:translate(dx,dy,dz)
  end
end

function Stead:set(x,y,z)
  local dx = self.worldspace.x - x
  local dy = self.worldspace.y - y
  local dz = self.worldspace.z - z
  self.worldspace.x = x or self.worldspace.x
  self.worldspace.y = y or self.worldspace.y
  self.worldspace.z = z or self.worldspace.z
  for i, child in ipairs(self.children) do
    GS[child].stead:translate(dx,dy,dz)
  end
end

function Stead:place(...)
  local args = {...}
  local delta = {}
  for i = 1, #args do
    table.insert(delta, args[i] - self.boardspace[Stead.spaces.boardspace.fields[i]])
    self.boardspace[Stead.spaces.boardspace.fields[i]] = args[i]
  end
  for i, child in ipairs(self.children) do
    GS[child].stead:moveBy(table.unpack(delta))
  end
end

function Stead:moveBy(...)
  assert(Stead.board.moveBy, 'You must specify a board with method moveBy on the Stead class to use the MoveBy command')
  Stead.board:moveBy(self,...)
end

return Stead
