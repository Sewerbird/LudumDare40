local function LoadAssets(path,A)
  --Populates table with quads and tilesets and animations
  A.img = {}
  A.img.chair = love.graphics.newImage(F"{path}chair.png")
  A.img.chairR = love.graphics.newImage(F"{path}chairR.png")
  A.img.potted_plant = love.graphics.newImage(F"{path}potplant.png")
  A.img.wall = love.graphics.newImage(F"{path}wall.png")
  A.img.wallUD = love.graphics.newImage(F"{path}wallUPDOWN.png")
  A.img.wallLR = love.graphics.newImage(F"{path}wallLEFTRIGHT.png")
  A.img.divTop = love.graphics.newImage(F"{path}divtop.png")
  A.img.stair = love.graphics.newImage(F"{path}stair.png")
  A.img.table = love.graphics.newImage(F"{path}table.png")
  A.img.sidewalk = love.graphics.newImage(F"{path}sidewalk.png")
  A.img.street = love.graphics.newImage(F"{path}street.png")
  A.img.floor = love.graphics.newImage(F"{path}floor.png")
  A.img.date = love.graphics.newImage(F"{path}date.png")
  A.img.cad = love.graphics.newImage(F"{path}cad.png")
  A.img.taxi = love.graphics.newImage(F"{path}taxi.png")
  A.quad = {}
  A.quad.chair = love.graphics.newQuad(0,0,115,115,A.img.chair:getDimensions())
  A.quad.chairR = love.graphics.newQuad(0,0,115,115,A.img.chairR:getDimensions())
  A.quad.potted_plant = love.graphics.newQuad(0,0,115,115,A.img.potted_plant:getDimensions())
  A.quad.wall = love.graphics.newQuad(0,0,115,115,A.img.wall:getDimensions())
  A.quad.wallUD = love.graphics.newQuad(0,0,115,115,A.img.wallUD:getDimensions())
  A.quad.wallLR = love.graphics.newQuad(0,0,115,115,A.img.wallLR:getDimensions())
  A.quad.stair = love.graphics.newQuad(0,0,115,115,A.img.stair:getDimensions())
  A.quad.table = love.graphics.newQuad(0,0,115,115,A.img.table:getDimensions())
  A.quad.sidewalk = love.graphics.newQuad(0,0,115,115,A.img.sidewalk:getDimensions())
  A.quad.street = love.graphics.newQuad(0,0,115,115,A.img.street:getDimensions())
  A.quad.floor = love.graphics.newQuad(0,0,115,115,A.img.floor:getDimensions())
  A.quad.date = love.graphics.newQuad(0,0,90,180,A.img.date:getDimensions())
  A.quad.cad = love.graphics.newQuad(0,0,90,180,A.img.cad:getDimensions())
  A.quad.taxi = love.graphics.newQuad(0,0,482,186,A.img.taxi:getDimensions())
  A.quad.divTop = love.graphics.newQuad(0,0,115,115,A.img.divTop:getDimensions())
  --Loads audio assets
  A.soundtrack = {
   --F"{path}PRISM LITE - WITH YOU.mp3"
  }
  return A
end

return LoadAssets
