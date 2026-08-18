-- 1. initialization
function _init()
  px = 64      -- player x position
  py = 64      -- player y position
  sx = 30      -- star x position
  sy = 30      -- star y position
  score = 0    -- player score
  state=true
end

-- 2. game logic & input
function _update()
  -- arrow key controls (0=left, 1=right, 2=up, 3=down)
  if (btn(0)) px -= 2
  if (btn(1)) px += 2
  if (btn(2)) py -= 2
  if (btn(3)) py += 2
  
  if px>128 or px<0 or py>128 or py<0 then
  	state=false
  end
  
  -- collision detection (distance check)
  if abs(px - sx) < 6 and abs(py - sy) < 6 then
    score += 1
    sx = flr(rnd(120))  -- random star x position
    sy = flr(rnd(120))  -- random star y position
    sfx(0)               -- play sound effect 0
  end
  
end

-- 3. rendering / drawing
function _draw()
	if state==true then
  cls(1)                              -- clear screen with dark navy
  spr(2,px, py, 4, 10)            -- draw player circle (yellow)
  spr(1, sx, sy)                     -- draw star sprite at (sx, sy)
  print("score: "..score, 4, 4, 7)   -- display score text
	else
		cls(1)
		print("gg", 56, 56, 7)
		print("final score: "..score, 64, 64, 7)
	end
end