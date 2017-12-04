local EventQueue = {}

EventQueue.__index = EventQueue

EventQueue.new = function(self)
	local self = setmetatable({},EventQueue)
  self.queue = {}
	return self
end

function EventQueue:update(dt)
  while #self.queue > 0 and dt > 0 do
    if not self.queue[1].processed then
      self.queue[1].processed = true
      if self.queue[1].event.begin then self.queue[1].event:begin() end
      if self.queue[1].duration <= 0 then
        table.remove(self.queue,1)
      end
    else
      --Handle events with durations
      if self.queue[1].duration > dt then
        if self.queue[1].event.update then self.queue[1].event:update(dt) end
        self.queue[1].duration = self.queue[1].duration - dt
        dt = 0 
      else
        if self.queue[1].event.finish then self.queue[1].event:finish(self.queue[1].duration) end
        dt = dt - self.queue[1].duration
        self.queue[1].duration = 0
        table.remove(self.queue,1)
      end
    end
  end
end

function EventQueue:add(tag, event, duration)
  duration = duration or 0
  table.insert(self.queue,{
    tag = tag, 
    event = event, 
    duration = duration, 
    original_duration = duration, 
    processed = false
  })
end

function EventQueue:status_string()
  local s = self.queue[1] and ("("..(math.floor(10 * self.queue[1].duration)/10)..") ") or "(0.0) "
  for i = 1, #self.queue do
    s = s .. self.queue[i].tag .. "\n <- "
  end
  return s
end

return EventQueue
