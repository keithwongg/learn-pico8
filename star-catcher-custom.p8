pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- 1. initialization
function _init()
  px = 64      -- player x position
  py = 64      -- player y position
  sx = 30      -- star x position
  sy = 30      -- star y position
  score = 0    -- player score
  state=true

  bullets = {}
  bullet_timer = 0
end

-- 2. game logic & input
function _update()
  -- arrow key controls (0=left, 1=right, 2=up, 3=down)
  if (btn(0)) px -= 2
  if (btn(1)) px += 2
  if (btn(2)) py -= 2
  if (btn(3)) py += 2
  
  wall_collision_detection()
  star_collision_detection()
  update_bullets()
end

function wall_collision_detection()
  if px>128 or px<0 or py>128 or py<0 then
  	if state==true then
      set_game_end()
  	end
  end
end

function star_collision_detection()
  -- collision detection (distance check)
  if abs(px - sx) < 6 and abs(py - sy) < 6 then
    score += 1
    sx = flr(rnd(120))  -- random star x position
    sy = flr(rnd(120))  -- random star y position
    sfx(0)               -- play sound effect 0
  end
end

function update_bullets()
  bullet_timer += 1

  if bullet_timer > 30 then
    bullet_timer = 0
    add(bullets, {x = flr(rnd(128)), y = 0, vy = 2})
  end

  for b in all(bullets) do
    b.y += b.vy
    if abs(px - b.x) < 6 and abs(py-b.y) < 6 then
      set_game_end()
    end
    if b.y > 128 then
      del(bullets, b)
    end
  end
end

function set_game_end()
  if state == true then
    state = false
    sfx(1)
  end
end

-- 3. rendering / drawing
function _draw()
	if state==true then
    draw_normal_game_loop()
	else
    draw_ending_screen()
	end
end

function draw_normal_game_loop()
  cls(1) -- clear screen with dark navy
  spr(2,px, py) -- draw player
  spr(1, sx, sy) -- draw star sprite at (sx, sy)
  print("score: "..score, 4, 4, 7) -- display score text
  for b in all(bullets) do
    circfill(b.x, b.y)
  end
end

function draw_ending_screen()
  cls(1)
  print("gg", 56, 56, 7)
  print("final score: "..score, 64, 64, 7)
end


__gfx__
00000000000990000707707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000009999000777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700099999900777877000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000999999990007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000099999900077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700099999900007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000009999000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000999009990070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000b0500f05013050230502e05034050390503b05015000250002f0002e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001900003a5503755033550305502c5502a5502305022050200501e0501c0501b0501905018050157501475012750117500f7500e7500e0500d0500c7500a7500975009750087500775006750067500675005750
