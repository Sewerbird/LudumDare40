local Scene = require('core/Scene')
local Shape = require('core/components/Shape')
local Stead = require('core/components/Stead')

local Layer = require('ludumdare40/Layer')
local Board = require('ludumdare40/Board')
local Level = require('ludumdare40/Level')

local CadSimulator = {}

tile_size_in_pixels = 30
map_size_in_tiles = 30


function CadSimulator:load()
  if Assets.soundtrack[1] then
    Assets.music = {}
    Assets.music.bgm = love.audio.newSource(Assets.soundtrack[1])
    Assets.music.bgm:setVolume(0.2)
    Assets.music.bgm:setLooping(true)
    love.audio.play(Assets.music.bgm)
  end

  local mainScene = GS:add(Scene.new())
  --Level is defacto UI layer
  local level = Level.create({
    stead = Stead.new({s_x = 0, s_y = 0, z = 10},GS[GS[mainScene].scenegraph].root),
  })
  --Game layer with board
  local gameLayer = Layer.create({
    stead = Stead.new({s_x = 0, s_y = 0, z = 0},GS[GS[mainScene].scenegraph].root),
    shape = Shape.rect(love.graphics.getWidth(), love.graphics.getHeight())
  })
  local board = Board.create({
    stead = Stead.new({x = 0, y = 0, z = 0},gameLayer)
  })
  GS[mainScene].level = level
  GS[mainScene].board = board --TODO: have a better mechanism to make Board accessible for Pieces/Tiles
  GS[mainScene].message_bus:subscribe(level, "keyboard", GS[level].keyinput)
  GS[mainScene].message_bus:subscribe(level, "tick", GS[level].tick)
  GS[mainScene].message_bus:subscribe(board, "tick", GS[board].tick)
  GS[board]:layout("ludumdare40/assets/map",mainScene)

  GS:pushScene(mainScene)
end

return CadSimulator

