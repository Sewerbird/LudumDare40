local Shape = require('core/components/Shape')
local Stead = require('core/components/Stead')
local Splat = require('core/components/Splat')
local State = require('core/components/State')

local TheCad = {}
TheCad.__index = TheCad
TheCad.new = function(init)
  local self = setmetatable({}, TheCad)
  self.gid = init.gid or uuid()
  self.type = 'Piece'
  self.tag = 'TheCad'
  self.stead = init.stead
  self.shape = Shape.circle(tile_size_in_pixels/2,1,tile_size_in_pixels/2,tile_size_in_pixels/2)
  self.splat = Splat.new(Assets.img.cad, {Assets.quad.cad}, 1/10, 0, -tile_size_in_pixels, tile_size_in_pixels/90, tile_size_in_pixels/90)
  self.state = State.new({
    gid = self.gid,
    initial = "UNENGAGED",
    events = {
      { name = 'engage', from = {'ESCORTING','UNENGAGED'}, to = 'ENGAGED'},
      { name = 'escort', from = 'UNENGAGED', to = 'ESCORTING'},
      { name = 'disengage', from = 'ENGAGED', to = 'UNENGAGED'},
      { name = 'bust', from = '*', to = 'BUSTED'}
    }
  })
  return self
end
TheCad.create = function(init)
  local n = TheCad.new(init)
  if n.stead and n.stead.parent then
    GS[n.stead.parent].stead.children[n.gid] = true
  end
  return GS:add(n)
end
function TheCad:draw()
  love.graphics.push()
  love.graphics.setColor(255,0,0)
  self.splat:draw()
  love.graphics.setColor(0,0,255)
  love.graphics.print(self.state.current,-tile_size_in_pixels/2,tile_size_in_pixels+6)
  love.graphics.pop()
end
function TheCad:tick()
  --Called whenever a turn passes
end
function TheCad:update(dt)
  --Called as time passes
end
function TheCad:moveToTile(tile_gid)
  local tgt = tile_gid
  if tgt and GS[tgt].passable then
    self.stead.boardspace.col = GS[tgt].stead.boardspace.col
    self.stead.worldspace.x = GS[tgt].stead.worldspace.x + 0.5
    self.stead.screenspace.s_x = GS[tgt].stead.screenspace.s_x
    self.stead.boardspace.row = GS[tgt].stead.boardspace.row
    self.stead.worldspace.y = GS[tgt].stead.worldspace.y + 0.5
    self.stead.screenspace.s_y = GS[tgt].stead.screenspace.s_y
    self.stead.parent = tgt
    GS[self.stead.parent].stead.children[self.gid] = true
    self.current_tile = tgt
  else
    self.current_tile = self.last_tile
  end
  if self.current_tile ~= self.last_tile then
    local curr_tile = GS[self.current_tile]
    if curr_tile.tag == "chair" then
      local dates = GS[GS:currentScene().board]:search('Piece','Date')
      local following_date = nil
      for i, date_gid in ipairs(dates) do
        local date = GS[date_gid]
        if date.state.current == "FOLLOWING_CAD" then
          following_date = date_gid
          break
        end
      end
      local b_row = curr_tile.stead.boardspace.row
      local b_col = curr_tile.stead.boardspace.col
      local desig = F"{b_row}_{b_col}_Companion_Chair"
      if curr_tile.designations["Companion_Chair"] and following_date then
        local companion_chair = GS[GS:currentScene().board]:searchByDesignation('Tile',desig)[1]
        GS[following_date]:moveToTile(companion_chair)
        GS[following_date].state:sit_down()
        GS[following_date].state:cad_at_table()
        self.current_date = following_date
        self.state:engage()
      elseif curr_tile.designations["Companion_Chair"] then
        local companion_chair = GS[GS:currentScene().board]:searchByDesignation('Tile',desig)[1]
        assert(companion_chair, F"Companion chair is missing? Tried to find designation {desig}")
        local companion = GS[GS:currentScene().board]:search('Piece','Date',GS[companion_chair].stead.boardspace.row, GS[companion_chair].stead.boardspace.col)[1]
        if companion then
          --Sitting down with companion
          self.current_date = companion
          self.state:engage()
          GS[self.current_date].state:cad_at_table()
        end
      end
    end
  end
end
function TheCad:keyinput(event, data)
  if event == 'keypressed' then
    if self.state.current == 'ENGAGED' then
      --Arrow keys are conversation tactics
      if data.key == 'w' or data.key == 'up' then
        GS[self.current_date]:charm()
      elseif data.key == 'a' or data.key == 'left' then
        GS[self.current_date]:neg()
      elseif data.key == 's' or data.key == 'down' then
        GS[self.current_date].state:cad_leaving()
        self.state:disengage()
      elseif data.key == 'd' or data.key == 'right' then
        GS[self.current_date]:bore()
      end
    else
      --Allow movement
      if data.key == 'w' or data.key == 'up' then
        tgt = GS[GS:currentScene().board]:search('Tile',nil,self.stead.boardspace.row - 1, self.stead.boardspace.col)
      elseif data.key == 'a' or data.key == 'left' then
        tgt = GS[GS:currentScene().board]:search('Tile',nil,self.stead.boardspace.row,self.stead.boardspace.col - 1)
      elseif data.key == 's' or data.key == 'down' then
        tgt = GS[GS:currentScene().board]:search('Tile',nil,self.stead.boardspace.row + 1,self.stead.boardspace.col)
      elseif data.key == 'd' or data.key == 'right' then
        tgt = GS[GS:currentScene().board]:search('Tile',nil,self.stead.boardspace.row, self.stead.boardspace.col + 1)
      end
      if tgt and #tgt > 0 then 
        self.last_tile= GS[GS:currentScene().board]:search('Tile',nil,self.stead.boardspace.row, self.stead.boardspace.col)[1]
        self:moveToTile(tgt[1]) 
      end
    end
    --DEBUG: Sends a date in a cab
    if data.key == 'n' then
      print("Trying to send new date...")
      GS[GS:currentScene().board]:sendNewDate(GS:currentScene().gid)
    end
    --DEBUG: reloads camera
    if data.key == 'm' then
      GS[GS:currentScene().camera]:refreshCache()
    end
  end

  --Trigger 'Tick', since turn has happened
  assert(GS:currentScene(), F"Scene doesnt seem to exist to call Tick event on. Current scene is {inspect(GS:currentScene())}")
  for gid, gob in pairs(GS) do
    if gob.DEBUG_SELECT then
      gob.DEBUG_SELECT = false
    end
  end
  --GS:currentScene().message_bus:publish('tick','tick',{})
end

return TheCad
