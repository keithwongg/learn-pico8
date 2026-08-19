-- 1. INITIALIZATION
function _init()
  px = 64      -- player x position
  py = 64      -- player y position
  sx = 30      -- star x position
  sy = 30      -- star y position
  score = 0    -- player score
end

-- 2. GAME LOGIC & INPUT
function _update()
  -- Arrow key controls (0=Left, 1=Right, 2=Up, 3=Down)
  if (btn(0)) px -= 2
  if (btn(1)) px += 2
  if (btn(2)) py -= 2
  if (btn(3)) py += 2
  
  -- Collision detection (distance check)
  if abs(px - sx) < 6 and abs(py - sy) < 6 then
    score += 1
    sx = flr(rnd(120))  -- random star x position
    sy = flr(rnd(120))  -- random star y position
    sfx(0)               -- play sound effect 0
  end
end

-- 3. RENDERING / DRAWING
function _draw()
  cls(1)                              -- clear screen with dark navy
  circfill(px, py, 4, 10)            -- draw player circle (yellow) x,y,radius,color
  spr(1, sx, sy)                     -- draw star sprite at (sx, sy)
  print("score: "..score, 4, 4, 7)   -- display score text | text, [x,] [y,] [color]
end