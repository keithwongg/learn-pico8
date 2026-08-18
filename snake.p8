pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- =================
-- Game Loop
-- =================
-- constants
snake_spr = 1
apple = 2
snake = {}
cell_size = 8

function _init()
	add(snake, { x = 7, y = 7 })
	add(snake, { x = 6, y = 7 })
	add(snake, { x = 5, y = 7 })

	game_state = true
	score = 0

	dx = -1
	dy = 0

	timer = 0
	move_delay = 10

	update_apple()
end

-->8
-- =================
-- Update
-- =================

function _update60()
	button_inputs()
	timer += 1
	if timer >= move_delay then
		timer = 0
		update_snake()
		snake_collision()
	end
end

function button_inputs()
	if btn(0) and dx != 1 then
		-- left
		dx = -1
		dy = 0
	end
	if btn(1) and dx != -1 then
		-- right
		dx = 1
		dy = 0
	end
	if btn(2) and dy != 1 then
		-- down
		dx = 0
		dy = -1
	end
	if btn(3) and dy != -1 then
		-- up
		dx = 0
		dy = 1
	end
end

function update_snake()
	local head = snake[1]
	local new_head = { x = head.x + dx, y = head.y + dy }
	add(snake, new_head, 1)
	deli(snake, #snake)
end

function snake_collision()
	local head = snake[1]
	local tail = snake[#snake]

	-- hit the wall
	if (head.x > 15 or head.x < 0) or (head.y > 15 or head.y < 0) then
		game_state_end()
	end

	-- ate the apple
	if head.x == ax and head.y == ay then
		score += 1
		ax = flr(rnd(16))
		ay = flr(rnd(15))
		sfx(0)
		add(snake, { x = tail.x + dx, y = tail.y + dy })
	end
end

function update_apple()
	ax = flr(rnd(15))
	ay = flr(rnd(15))
	-- do not spawn apple in snake body
	for i = 1, #snake, 1 do
		if snake[i].x == ax and snake[i].y == ay then
			update_apple()
		end
	end
end

function game_state_end()
	if game_state == true then
		game_state = false
		sfx(1)
	end
end

-->8
-- =================
-- Draw
-- =================

function _draw()
	if game_state == true then
		game_loop()
	else
		ending_screen()
	end
end

function game_loop()
	cls()
	print("score: " .. score, 7, 7, 7)
	draw_snake()
	draw_apple()
end

function ending_screen()
	cls()
	print("final score: " .. score, 24, 64, 7)
end

function draw_snake()
	local len = #snake
	for i = 1, len, 1 do
		local body = snake[i]
		spr(snake_spr, body["x"] * cell_size, body["y"] * cell_size)
	end
end

function draw_apple()
	spr(apple, ax * cell_size, ay * cell_size)
end

__gfx__
00000000777777770088880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777770888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700777777778888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000777777778888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000777777778888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700777777778888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777770888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777770088880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001a0501d050220502305024050240502605000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008001f0c550185502755014350324503445038450354502f4501d650256502765025650226501d6501a65030450304502135022350203501f3501d6502265026650216501e6501e650265501f5501b55010550
