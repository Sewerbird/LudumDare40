local Shape = require('core/components/Shape')
local Stead = require('core/components/Stead')
local Splat = require('core/components/Splat')
local Tile = require('cadsimulator/Tile')
local TheCad = require('cadsimulator/TheCad')
local Date = require('cadsimulator/Date')
local Taxi = require('cadsimulator/Taxi')

local Board = {}
Board.__index = Board
Board.new = function(init)
  local self = setmetatable({},Board)
  self.gid = init.gid or uuid()
  self.type = "Board"
  self.stead = init.stead or Stead.new(self.gid)
  return self
end

Board.create = function(init)
  local n = Board.new(init)
  if n.stead and n.stead.parent then
    GS[n.stead.parent].stead.children[n.gid] = true
  end
  return GS:add(n)
end

function Board:tick()
  if self.pendingDate then
    local taxi = self:search('Piece','Taxi')
    if not taxi.passenger then
      taxi.passenger = theDate
    else
      self.pendingDate = theDate
    end
  end
end

function Board:searchByDesignation(g_type,designation)
  local result = {}
  assert(designation, F"When you search by designation, you must specify a designation, but got {inspect(designation)}")
  for gid, _ in pairs(self.stead.children) do
    if GS[gid].stead and GS[gid].type == g_type then
      if (GS[gid].designations and GS[gid].designations[designation]) then
        table.insert(result,gid)
      end
    end
  end
  return result
end

function Board:findAtWorldspace(g_type,tag,worldspace)
  local result = {}
  for gid, _ in pairs(self.stead.children) do
    if GS[gid].stead and GS[gid].type == g_type then
      if (tag and tag == GS[gid].tag) or not tag then
        if GS[gid].stead and GS[gid].shape then
          if GS[gid].shape:contains(
              worldspace.x - GS[gid].stead.worldspace.x, 
              worldspace.y - GS[gid].stead.worldspace.y) then
            table.insert(result,gid)
          end
        end
      end
    end
  end
  return result
end

function Board:search(g_type,tag,row,col,distance)
  local result = {}
  for gid, _ in pairs(self.stead.children) do
    if GS[gid].stead and GS[gid].type == g_type then
      if (tag and tag == GS[gid].tag) or not tag then
        if distance then
          assert(row and col, F"distance search requires both a row and col, but got {row} and {col}")
          local dist = math.abs(GS[gid].stead.boardspace.row - row) + math.abs(GS[gid].stead.boardspace.col - col)
          if (dist <= distance) then
            table.insert(result,gid)
          end
        elseif row and col then
          if (GS[gid].stead.boardspace.row == row)
           and (GS[gid].stead.boardspace.col == col) then
              table.insert(result,gid)
          end
        else
          table.insert(result,gid)
        end
      end
    end
  end
  return result
end

function Board:sendNewDate(scene)
  local taxi = self:search('Piece','Taxi')
  local piece = {row = -100, col = -100}
  local theDate = nil
  if self.pendingDate then 
    theDate = self.pendingDate
    self.pendingDate = nil
  else
    theDate = Date.create({
      in_taxi = true,
      stead = Stead.new({
        row = piece.row, col = piece.col,
        x = piece.row, y = piece.col, z = 1,
        s_x = (piece.row-1) * tile_size_in_pixels, s_y = (piece.col-1) * tile_size_in_pixels
      },self.gid)
    })
  end
  DEBUG_OF_INTEREST = theDate
  if not taxi.passenger then
    GS[scene].message_bus:subscribe(theDate, "tick", GS[theDate].tick)
    GS[scene].message_bus:subscribe(theDate, "time", GS[theDate].update)
    GS[theDate].state:leave_work()
    GS[theDate].state:found_cab()
    GS[taxi[1]].passenger = theDate
  else
    self.pendingDate = theDate
    return false
  end
  GS[GS[scene].camera]:refreshCache()
  return theDate
end

function Board:getSampledLine(src_boardspace, tgt_boardspace,sample_rate)
  local src = {src_boardspace.row + 0.5, src_boardspace.col + 0.5}
  local tgt = {tgt_boardspace.row + 0.5, tgt_boardspace.col + 0.5}
  local distance = math.dist(src,tgt)
  local num_samples = math.floor(distance/sample_rate) + 1
  local samples = {}
  for i = 1, num_samples do
    local lerped = math.lerp(src,tgt,i/num_samples)
    table.insert(samples, { row = lerped[1], col = lerped[2] })
  end
  return samples
end

function Board:testLineOfSight(src, tgt)
  local path = {}
  if not use_pathfinding then
    local sample_line = self:getSampledLine(src.stead.boardspace,tgt.stead.boardspace,0.5)
    --TODO: rewrite this to use actual camera math
    --local next_node = self:findAtWorldspace('Tile',nil,sample_line[1])
    local next_node = 1
    local tgt_tile = self:search('Tile',nil,math.floor(sample_line[next_node].row),math.floor(sample_line[next_node].col))[1]
    while sample_line[next_node] and tgt_tile do
      tgt_tile = self:search('Tile',nil,
      math.floor(sample_line[next_node].row),
      math.floor(sample_line[next_node].col))[1]
      GS[tgt_tile].DEBUG_SELECT = true
      if GS[tgt_tile].blocks_vision then
        return false
      end
      table.insert(path, tgt_tile)
      next_node = next_node + 1
    end
  end
  return path
end

function Board:getPath(src, tgt, use_pathfinding, respect_impassab)
  local path = {}
  if not use_pathfinding then
    local sample_line = self:getSampledLine(src.stead.worldspace,tgt.stead.worldspace,1)
    --TODO: rewrite this to use actual camera math
    --local next_node = self:findAtWorldspace('Tile',nil,sample_line[1])
    local next_node = 1
    local tgt_tile = nil
    while sample_line[next_node] and
      self:search('Tile',nil,math.floor(sample_line[next_node].x), math.floor(sample_line[next_node].y))[1] do
      sample_line[next_node].x = math.floor(sample_line[next_node].x)
      sample_line[next_node].y = math.floor(sample_line[next_node].y)
      table.insert(path,self:search('Tile',nil,sample_line[next_node].x,sample_line[next_node].y)[1])
      next_node = next_node + 1
    end
  end
  return path
end

function Board:layout(file, scene)
  local mapData = require(file)
  
  --Position all tiles/pieces on board against the grid
  local tiles = {}
  local assets = {
    X = {sprite = "wall", tag = "wall", blocks_vision = true, passable = false},
    x = {sprite = "wallUD", tag = "wall", blocks_vision = true, passable = false},
    Y = {sprite = "wallLR", tag = "wall", blocks_vision = true, passable = false},
    C = {sprite = "chair", tag = "chair", passable = true},
    P = {sprite = "potted_plant", passable = true},
    T = {sprite = "table", passable = true},
    s = {sprite = "sidewalk", passable = true},
    S = {sprite = "street", passable = true},
    o = {sprite = "floor", passable = true},
    z = {sprite = "divTop", passable = true}
  }
  for i, tileRow in ipairs(mapData.tilemap) do
    local row = i
    for j, tile in ipairs(tileRow) do
      local col = j
      local designations = mapData.tile_tags and mapData.tile_tags["r"..row] and mapData.tile_tags["r"..row]["c"..col] or {}
      table.insert(tiles,Tile.create({
        passable = assets[tile].passable,
        designations = designations,
        blocks_vision = assets[tile].blocks_vision,
        path_distance_to_exit = mapData.exit_pathfinding[row][col],
        tag = assets[tile].tag,
        stead = Stead.new({
          row = row, col = col, 
          x = row, y = col, z = 0,
          s_x = (col-1) * tile_size_in_pixels, s_y = (row-1) * tile_size_in_pixels }
        ,self.gid),
        splat = assets[tile] and assets[tile].sprite and Splat.new(
          Assets.img[assets[tile].sprite], {Assets.quad[assets[tile].sprite]}, 1/10, 
          0, 0, tile_size_in_pixels/115, tile_size_in_pixels/115) or nil,
        shape = Shape.rect(tile_size_in_pixels,tile_size_in_pixels)
      }))
    end
  end

  local pieces = {}
  for i, piece in ipairs(mapData.pieces) do
    if piece.tag == "TheCad" then
      local theCad = TheCad.create({
        stead = Stead.new({
          row = piece.row, col = piece.col, 
          x = piece.row + 0.5, y = piece.col + 0.5, z = 1,
          s_x = (piece.col-1) * tile_size_in_pixels, s_y = (piece.row-1) * tile_size_in_pixels 
        },self.gid)
      })
      GS[scene].message_bus:subscribe(theCad, "keyboard", GS[theCad].keyinput)
      GS[scene].message_bus:subscribe(theCad, "time", GS[theCad].update)
    elseif piece.tag == "Date" then
      local theDate = Date.create({
        stead = Stead.new({
          row = piece.row, col = piece.col,
          x = piece.row + 0.5, y = piece.col + 0.5, z = 1,
          s_x = (piece.col-0.5) * tile_size_in_pixels, s_y = (piece.row-0.5) * tile_size_in_pixels
        },self.gid)
      })
      GS[scene].message_bus:subscribe(theDate, "tick", GS[theDate].tick)
      GS[scene].message_bus:subscribe(theDate, "time", GS[theDate].update)
    elseif piece.tag == "Taxi" then
      local theTaxi = Taxi.create({
        stead = Stead.new({
          row = piece.row, col = piece.col,
          x = piece.row, y = piece.col, z = 1,
          s_x = (piece.col-1) * tile_size_in_pixels, s_y = (piece.row-1) * tile_size_in_pixels
        },self.gid)
      })
      GS[scene].message_bus:subscribe(theTaxi, "tick", GS[theTaxi].tick)
      GS[scene].message_bus:subscribe(theTaxi, "time", GS[theTaxi].update)
    end
  end
end
return Board
