local machine = {}
machine.__index = machine

local NONE = "none"
local ASYNC = "async"

local function call_handler(handler, params)
  if handler then
    return handler(unpack(params))
  end
end

local function create_transition(name)
  local can, to, from, params

  local function transition(self, ...)
    if self.asyncState == NONE then
      can, to = self:can(name)
      from = self.current
      params = { self, name, from, to, ...}

      if not can then return false end
      self.currentTransitioningEvent = name

      local beforeReturn = call_handler(self["onbefore" .. name], params)
      local leaveReturn = call_handler(self["onleave" .. from], params)

      if beforeReturn == false or leaveReturn == false then
        return false
      end

      self.asyncState = name .. "WaitingOnLeave"

      if leaveReturn ~= ASYNC then
        transition(self, ...)
      end
      
      return true
    elseif self.asyncState == name .. "WaitingOnLeave" then
      self.current = to

      local enterReturn = call_handler(self["onenter" .. to] or self["on" .. to], params)

      self.asyncState = name .. "WaitingOnEnter"

      if enterReturn ~= ASYNC then
        transition(self, ...)
      end
      
      return true
    elseif self.asyncState == name .. "WaitingOnEnter" then
      call_handler(self["onafter" .. name] or self["on" .. name], params)
      call_handler(self["onstatechange"], params)
      self.asyncState = NONE
      self.currentTransitioningEvent = nil
      return true
    else
    	if string.find(self.asyncState, "WaitingOnLeave") or string.find(self.asyncState, "WaitingOnEnter") then
    		self.asyncState = NONE
    		transition(self, ...)
    		return true
    	end
    end

    self.currentTransitioningEvent = nil
    return false
  end

  return transition
end

local function add_to_map(map, event)
  if type(event.from) == 'string' then
    map[event.from] = event.to
  else
    for _, from in ipairs(event.from) do
      map[from] = event.to
    end
  end
end

function machine:update()
  assert(self.gob_gid,F"No gob gid given for this machine! Updating update{self.current}, with {self.gob_gid}")
  assert(GS[self.gob_gid],F"Gob_gid {self.gob_gid} isn't present in gamestate")
  assert(self["update"..self.current],F"update function update{self.current} doesn't exist in {inspect(self)}")
  return self["update"..self.current](GS[self.gob_gid])
end

function machine.create(options)
  assert(options.events, "You must specify 'events' option when creating a FSM")

  local fsm = {}
  setmetatable(fsm, machine)

  fsm.options = options
  fsm.current = options.initial or 'none'
  fsm.gob_gid = options.gid or nil
  fsm.asyncState = NONE
  fsm.events = {}
  fsm.states = options.states or {}

  for _, event in ipairs(options.events or {}) do
    local name = event.name
    fsm[name] = fsm[name] or create_transition(name)
    fsm.events[name] = fsm.events[name] or { map = {} }
    add_to_map(fsm.events[name].map, event)
  end

  for state, behaviours in pairs(options.states or {}) do
    fsm["onenter"..state] = function(self, event, from, to, ...)
      for _, behaviour in ipairs(behaviours) do
        behaviour:onEnter(self, event, from, to, ...)
      end
    end
    fsm["onleave"..state] = function(self, event, from, to, ...)
      for _, behaviour in ipairs(behaviours) do
        behaviour:onLeave(self, event, from, to, ...)
      end
    end
    fsm["update"..state] = function(self)
      if #behaviours > 1 then
        for _, behaviour in ipairs(behaviours) do
          behaviour.onUpdate(self or nil)
        end
      else
        behaviours.onUpdate(self or nil)
      end
    end
  end

  for name, callback in pairs(options.callbacks or {}) do
    fsm[name] = callback
  end

  return fsm
end
machine.new = machine.create

function machine:is(state)
  return self.current == state
end

function machine:can(e)
  local event = self.events[e]
  local to = event and event.map[self.current] or event.map['*']
  return to ~= nil, to
end

function machine:cannot(e)
  return not self:can(e)
end

function machine:todot(filename)
  local dotfile = io.open(filename,'w')
  dotfile:write('digraph {\n')
  local transition = function(event,from,to)
    dotfile:write(string.format('%s -> %s [label=%s];\n',from,to,event))
  end
  for _, event in pairs(self.options.events) do
    if type(event.from) == 'table' then
      for _, from in ipairs(event.from) do
        transition(event.name,from,event.to)
      end
    else
      transition(event.name,event.from,event.to)
    end
  end
  dotfile:write('}\n')
  dotfile:close()
end

function machine:transition(event)
  if self.currentTransitioningEvent == event then
    return self[self.currentTransitioningEvent](self)
  end
end

function machine:cancelTransition(event)
  if self.currentTransitioningEvent == event then
    self.asyncState = NONE
    self.currentTransitioningEvent = nil
  end
end

machine.NONE = NONE
machine.ASYNC = ASYNC

return machine
