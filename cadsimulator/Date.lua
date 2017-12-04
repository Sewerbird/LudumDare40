local Shape = require('core/components/Shape')
local Stead = require('core/components/Stead')
local Splat = require('core/components/Splat')
local State = require('core/components/State')
local Behaviour = require('core/components/Behaviour')

local Date = {}
Date.__index = Date
Date.new = function(init)
  local self = setmetatable({}, Date)
  self.gid = init.gid or uuid()
  self.type = 'Piece'
  self.tag = 'Date'
  self.in_taxi = init.in_taxi
  self.stead = init.stead
  self.shape = Shape.circle(tile_size_in_pixels/2,1,tile_size_in_pixels/2,tile_size_in_pixels/2)
  self.splat = Splat.new(Assets.img.date, {Assets.quad.date}, 1/10, 0, -tile_size_in_pixels, tile_size_in_pixels/90, tile_size_in_pixels/90)
  self.hearts_max = 3
  self.irritation_max = 100
  self.irritation_min = 0
  self.boredom_max = 100
  self.boredom_min = 0
  self.hearts = 0
  self.irritation = 0
  self.boredom = 0
  self.behaviours = {
    AT_WORK = Behaviour.new(function() end, function() end, function() end),
    ON_THE_WAY = Behaviour.new(function() end, function() end, function() end),
    IN_TAXI = Behaviour.new(function() end, function() end, function() end),
    STANDING_ON_CURB = Behaviour.new(function() end, 
      function(me) 
        me:increaseBoredom(1)
        me:increaseIrritation(1)
      end, function() end),
    FOLLOWING_CAD = Behaviour.new(function(me) end,function(me)
      local cad = GS[GS:currentScene().board]:search('Piece','TheCad',me.stead.boardspace.row, me.stead.boardspace.col,10)[1]
      if cad then
        cad = GS[cad]
        if self.seek_tile and cad.last_tile and cad.last_tile ~= cad.current_tile then
          me:moveToTile(cad.last_tile)
          self.seek_tile = cad.last_tile
        else
          self.seek_tile = cad.last_tile
        end
      end
  end,function(me) end),
    SEEKING_CHAIR = Behaviour.new(function() end, function() end, function() end),
    SITTING_DOWN = Behaviour.new(function() end, function() 
        self:increaseIrritation(2)
        self:increaseBoredom(5)
        if math.random() > 0.5 then
          self.state:look_at_phone()
        end
      end, function() end),
    SITTING_UP = Behaviour.new(function() end, function() end, function() end),
    LOOKING_AT_PHONE = Behaviour.new(function() end, function() 
        self:increaseIrritation(1)
        self:increaseBoredom(1)
        if math.random() > 0.9 then
          self.state:look_away_from_phone()
        end
      end, function() end),
    FRESHING_UP = Behaviour.new(function() end, function() end, function() end),
    ENGAGED = Behaviour.new(function() end, function() end, function() end),
    GOING_RESTROOM = Behaviour.new(function() end, function() end, function() end),
    LEAVING_BUILDING = Behaviour.new(function() end, function() 
        self:moveTowardsExit()
      end, function() end),
    DITCHING_DATE = Behaviour.new(function() end, function() 
        self:moveTowardsExit()
      end, function() end),
    GOING_HOME = Behaviour.new(function() end, function() 
        self.stead = nil
        GS:currentScene().message_bus:unsubscribe(self.gid)
      end, function() end),
    SUPER_HOSTILE = Behaviour.new(
      function() 
        --Righteous Fury
        self.hearts = 0;
        self.irritation = self.irritation_max;
        self.boredom = 0;
        GS[GS:currentScene().level].state:lose_game()
      end, 
      function() 
        self.hearts = 0;
        self.irritation = self.irritation_max;
        self.boredom = 0;
        GS[GS:currentScene().level].state:lose_game()
      end, function() end)
  }

  self.state = State.new({
    gid = self.gid,
    initial = "AT_WORK",
    events = {
      { name = 'leave_work', from = 'AT_WORK', to = 'ON_THE_WAY' },
      { name = 'found_cab', from = 'ON_THE_WAY', to = 'IN_TAXI' },
      { name = 'disembark', from = "IN_TAXI", to = 'STANDING_ON_CURB' },
      { name = 'cad_is_adjacent', from = 'STANDING_ON_CURB', to = 'FOLLOWING_CAD' },
      { name = 'cad_entered_view', from = 'SITTING_DOWN', to = 'SITTING_UP' },
      --{ name = 'sit_with_cad', from = 'FOLLOWING_CAD', to = 'SEEKING_CHAIR' },
      { name = 'sit_down', from = 'FOLLOWING_CAD'--[['SEEKING_CHAIR']], to = 'SITTING_DOWN' },
      { name = 'cad_at_table', from = {'LOOKING_AT_PHONE','SITTING_UP','SITTING_DOWN'}, to = 'ENGAGED' },
      { name = 'look_at_phone', from = 'SITTING_DOWN', to = 'LOOKING_AT_PHONE' },
      { name = 'look_away_from_phone', from='LOOKING_AT_PHONE', to='SITTING_DOWN'},
      { name = 'cad_leaving', from = 'ENGAGED', to = 'SITTING_DOWN' },
      { name = 'cad_left_view', from = 'SITTING_UP', to = 'SITTING_DOWN' },
      { name = 'go_to_restroom', from = {'SITTING_DOWN','LOOKING_AT_PHONE'}, to = 'GOING_RESTROOM' },
      { name = 'at_restroom_sink', from = 'GOING_RESTROOM', to = 'FRESHING_UP' },
      { name = 'finish_freshening', from = 'FRESHING_UP', to = 'RETURNING_TO_TABLE' },
      { name = 'conclude_date', from = {'ENGAGED','SITTING_UP','SITTING_DOWN','STANDING_ON_CURB'}, to = 'LEAVING_BUILDING' },
      { name = 'ditch_date', from = {'ENGAGED','SITTING_UP','SITTING_DOWN','STANDING_ON_CURB'}, to = 'DITCHING_DATE' },
      { name = 'exit_board', from = {'LEAVING_BUILDING','DITCHING_DATE'}, to = 'GOING_HOME'},
      { name = 'see_cad_with_other_date', from = {'STANDING_ON_CURB','FOLLOWING_CAD','SEEKING_CHAIR','SITTING_UP','SITTING_DOWN','GOING_RESTROOM','ENGAGED','GOING_RESTROOM','LEAVING_BUILDING','DITCHING_DATE'}, to = 'SUPER_HOSTILE' }
    },
    states = {
      AT_WORK = self.behaviours.AT_WORK,
      ON_THE_WAY = self.behaviours.ON_THE_WAY,
      IN_TAXI = self.behaviours.IN_TAXI,
      STANDING_ON_CURB = self.behaviours.STANDING_ON_CURB,
      FOLLOWING_CAD = self.behaviours.FOLLOWING_CAD,
      SEEKING_CHAIR = self.behaviours.SEEKING_CHAIR,
      SITTING_UP = self.behaviours.SITTING_UP,
      SITTING_DOWN = self.behaviours.SITTING_DOWN,
      LOOKING_AT_PHONE = self.behaviours.LOOKING_AT_PHONE,
      GOING_RESTROOM = self.behaviours.GOING_RESTROOM,
      FRESHING_UP = self.behaviours.FRESHING_UP,
      ENGAGED = self.behaviours.ENGAGED,
      GOING_RESTROOM = self.behaviours.GOING_RESTROOM,
      LEAVING_BUILDING = self.behaviours.LEAVING_BUILDING,
      GOING_HOME = self.behaviours.GOING_HOME,
      DITCHING_DATE = self.behaviours.DITCHING_DATE,
      SUPER_HOSTILE = self.behaviours.SUPER_HOSTILE
    }
  })
  return self
end
Date.create = function(init)
  local n = Date.new(init)
  if n.stead and n.stead.parent then
    GS[n.stead.parent].stead.children[n.gid] = true
  end
  return GS:add(n)
end

function Date:draw()
  love.graphics.push()
  love.graphics.translate(-tile_size_in_pixels/2,-tile_size_in_pixels/2)
  --love.graphics.setColor(255,185,230)
  love.graphics.setColor(255,255,255)
  self.splat:draw()
  for i = 0, self.hearts_max do
    if i > 0 and i <= self.hearts then
      love.graphics.setColor(255,125,200)
      love.graphics.circle('fill',2,i*6,3)
    elseif i > 0 and self.hearts < 0 and  -i >= self.hearts then
      love.graphics.setColor(100,0,255)
      love.graphics.circle('fill',2,i*6,3)
    end
  end
  love.graphics.setColor(255,0,0)
  love.graphics.rectangle('fill',0,tile_size_in_pixels,tile_size_in_pixels,4)
  love.graphics.setColor(125,255,155)
  love.graphics.rectangle('fill',0,tile_size_in_pixels,tile_size_in_pixels * (1 - self.irritation/self.irritation_max),4)
  love.graphics.setColor(125,255,155)
  if self.state.current == "SUPER_HOSTILE" then love.graphics.setColor(255,0,0) end
  if self.state.current == "DITCHING_DATE" then love.graphics.setColor(255,125,0) end
  love.graphics.print(self.state.current,-tile_size_in_pixels/2,tile_size_in_pixels+6)
  love.graphics.pop()
end

function Date:tick()
  --Called whenever a turn passes
  if self.state.current == 'AT_WORK' or self.state.current == 'IN_TAXI' then return end
  --Look around for Cad
  if self.state.current ~= 'LOOKING_AT_PHONE' then
    --Only a Phone can neutralize a person's situational awareness so utterly
    local cad = GS[GS:currentScene().board]:search('Piece','TheCad')[1]
    if cad then
      cad = GS[cad]
      local los_path =GS[GS:currentScene().board]:testLineOfSight(self,cad)
      if los_path then
        for i, tile in ipairs(los_path) do
          GS[tile].DEBUG_SELECT = true
        end
        self.state:cad_entered_view()
        local dates_near_cad = GS[GS:currentScene().board]:search('Piece','Date',cad.stead.boardspace.row, cad.stead.boardspace.col,2)
        if #dates_near_cad then
          local other_date = nil
          for i, date_gid in ipairs(dates_near_cad) do
            local other = GS[date_gid]
            if other.gid ~= self.gid then
              local date_los = GS[GS:currentScene().board]:testLineOfSight(self,other)
              if date_los then
                other_date = date_gid
              end
            end
          end
          if other_date then
            self.warpath = los_path
            self.warpathprogress = 1
            self.state:see_cad_with_other_date()
          end
        end
        cad = nil
        cad = GS[GS:currentScene().board]:search('Piece','TheCad',self.stead.boardspace.row, self.stead.boardspace.col,1)[1]
        if cad then
          self.state:cad_is_adjacent()
          if self.state.current == 'FOLLOWING_CAD' then
            GS[cad].state:escort()
          end
        end
      else
        self.state:cad_left_view()
      end
    end
    --Notice other Super Hostile dates
    local dates = GS[GS:currentScene().board]:search('Piece','Date')
    for i, gid in ipairs(dates) do
      if gid ~= self.gid then
        local los_path = GS[GS:currentScene().board]:testLineOfSight(self,GS[gid])
        if los_path then
          for i, tile in ipairs(los_path) do
            GS[tile].DEBUG_SELECT = true
          end
          if GS[gid].state.current == 'SUPER_HOSTILE' then
            self.state:see_cad_with_other_date()
          end
        end
      end
    end
  end
  if self.irritation == self.irritation_max then
    self.state:ditch_date()
  elseif self.hearts == math.abs(self.hearts_max) then
    self.state:conclude_date()
  end
  self.state:update(self.gid)
end

function Date:update(dt)
  --Called as time passes
end

function Date:bore()
  self:increaseBoredom(10)
  self:increaseIrritation(5)
end

function Date:neg()
  if math.random() > 0.7 then self:increaseHearts(-1) end
  self:increaseIrritation(20)
end

function Date:charm()
  if math.random() > 0.9 then self:increaseHearts(1) end
  self:increaseIrritation(-10)
end

function Date:increaseHearts(val)
  self.hearts = math.max(math.min(self.hearts+val,self.hearts_max),-self.hearts_max)
end

function Date:increaseBoredom(val)
  self.boredom = math.max(math.min(self.boredom+val,self.boredom_max),0)
end

function Date:increaseIrritation(val)
  self.irritation = math.max(math.min(self.irritation+val,self.irritation_max),0)
end

function Date:moveTowardsExit()
  --Walk to exit tile
  local adjacent_tiles = GS[GS:currentScene().board]:search('Tile',nil, self.stead.boardspace.row, self.stead.boardspace.col,1)
  local my_tile = GS[GS:currentScene().board]:search('Tile',nil,self.stead.boardspace.row, self.stead.boardspace.col)[1]
  local tgt_tile = nil
  local minDist = 90
  for i, adjacent in ipairs(adjacent_tiles) do
    local d = GS[adjacent].path_distance_to_exit
    if d < GS[my_tile].path_distance_to_exit and d < minDist then
      tgt_tile = adjacent
      minDist = d
    elseif d < minDist then
      minDist = d
    end
  end
  if tgt_tile then
    self:moveToTile(tgt_tile)
  end
  if minDist == 0 then
    self.state:exit_board()
    table.insert(GS[GS:currentScene().level].dates_off_board,self.gid)
  end
end

function Date:moveToTile(tile_gid)
  local tgt = tile_gid
  if tgt and GS[tgt].passable then
   --and not GS[GS:currentScene().board]:search('Piece','TheCad',GS[tgt].stead.boardspace.row,GS[tgt].stead.boardspace.col)[1] then
    self.stead.boardspace.col = GS[tgt].stead.boardspace.col
    self.stead.worldspace.x = GS[tgt].stead.worldspace.x + 0.5
    self.stead.screenspace.s_x = GS[tgt].stead.screenspace.s_x + tile_size_in_pixels/2
    self.stead.boardspace.row = GS[tgt].stead.boardspace.row
    self.stead.worldspace.y = GS[tgt].stead.worldspace.y + 0.5
    self.stead.screenspace.s_y = GS[tgt].stead.screenspace.s_y + tile_size_in_pixels/2
    self.stead.parent = tgt
    GS[self.stead.parent].stead.children[self.gid] = true
  end
end

return Date
