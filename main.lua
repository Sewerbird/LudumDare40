--Global Utility Libraries
inspect = require('lib/inspect')
uuid = require('lib/uuid')
F = require('lib/F')
require('lib/math_extensions')

--Requires
local Gamestate = require('core/gamestate')

--Global Gamestate
Assets = {} --Assets
GS = Gamestate.new() --Gamestate


function love.load(args)
  Assets = require(F"cadsimulator/assets/import")(F"cadsimulator/assets/",Assets)
  require(F"cadsimulator/main"):load()
end

function love.touchpressed(id,x,y)
  love.mousepressed(x,y,id)
end

function love.touchmoved(id,x,y,dx,dy)
  love.mousemoved(x,y,dx,dy,id)
end

function love.touchreleased(id,x,y)
  love.mousereleased(x,y,id)
end

function love.mousepressed(x,y,is_touch)
  GS:currentScene():input('mouse',{ name = 'mousepressed', x = x, y = y, touch = is_touch})
end

function love.mousemoved(x,y,dx,dy,is_touch)
  GS:currentScene():input('mouse',{ name = 'mousemoved', x = x, y = y, dx = dx, dy = dy, touch = is_touch})
end

function love.mousereleased(x,y,is_touch)
  GS:currentScene():input('mouse',{ name = 'mousereleased', x = x, y = y, touch = is_touch})
end

function love.keypressed(key)
  GS:currentScene():input('keyboard',{ name = 'keypressed', key = key})
end

function love.update(dt)
  GS:currentScene():update(dt)
end

function love.draw()
  GS:currentScene():draw()
end

