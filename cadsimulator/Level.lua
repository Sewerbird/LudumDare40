local Stead = require('core/components/Stead')
local State = require('core/components/State')
local Behaviour = require('core/components/Behaviour')

local Level = {}
Level.__index = Level
Level.new = function(init)
  local self = setmetatable({},Level)
  self.gid = init.gid or uuid()
  self.type = 'Level'
  self.stead = init.stead or Stead.new(self.gid)
  self.font = love.graphics.newFont(39)
  self.date_interval_passed = 999
  self.date_interval = 200
  self.dates_sent = 0
  self.dates_on_board = {}
  self.dates_off_board = {}
  self.state = State.new({
    gid = self.gid,
    initial = "UNPAUSED",
    events = {
      { name = 'unpause', from = 'PAUSED', to = 'UNPAUSED'},
      { name = 'show_rules', from = 'INTRO', to = 'RULES'},
      { name = 'begin_game', from = {'INTRO','RULES'}, to = 'UNPAUSED'},
      { name = 'lose_game', from = 'UNPAUSED', to = 'GAMEOVER'},
      { name = 'win_game', from = 'UNPAUSED', to = 'LEVELDONE'}
    },
    states = {
      PAUSED = Behaviour.new(function() end, function() end, function() end),
      UNPAUSED = Behaviour.new(function() end, function(self) 
        if #self.dates_off_board > 3 then
          self.state:win_game()
        end
        if self.date_interval_passed > self.date_interval then
          table.insert(self.dates_on_board, GS[GS:currentScene().board]:sendNewDate(GS:currentScene().gid))
          self.date_interval_passed = 0
          self.dates_sent = self.dates_sent + 1
        else
          self.date_interval_passed = self.date_interval_passed + 1
        end
      end, function() end),
      INTRO = Behaviour.new(function() end, function() end, function() end),
      RULES = Behaviour.new(function() end, function() end, function() end),
      GAMEOVER = Behaviour.new(function() end, function() end, function() end),
      LEVELDONE = Behaviour.new(function() end, function() end, function() end)
    }
  })
  return self
end
Level.create = function(init)
  local n = Level.new(init)
  if n.stead and n.stead.parent then
    GS[n.stead.parent].stead.children[n.gid] = true
  end
  return GS:add(n)
end

function Level:draw()
  love.graphics.push()
  local oldfont = love.graphics.getFont()
  love.graphics.setFont(self.font)
  love.graphics.print(self.state.current, 10,10)
  love.graphics.setFont(oldfont)
  love.graphics.pop()
end

function Level:keyinput(key)
  if self.state.current == 'INTRO' then
    self.state:show_rules()
  elseif self.state.current == 'RULES' then
    self.state:begin_game()
  elseif self.state.current == 'PAUSED' then
    self.state:unpause()
  elseif self.state.current == 'UNPAUSED' and key == 'space' then
    self.state:pause()
  end
end
function Level:tick()
  self.state:update(self.gid)
end

return Level
