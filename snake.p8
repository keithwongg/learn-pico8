pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- =============================================
-- classic snake in pico-8
-- =============================================

function _init()
    cartdata("kw_snake_game_pico8_v1")
    high_score = dget(0) or 0

    state = "title" -- "title", "play", "gameover"
    grid_w = 30
    grid_h = 26
    cell_sz = 4
    ox = 4
    oy = 14

    particles = {}
    title_snake = {}
    init_title_snake()
    t = 0
    shake = 0
end

function start_new_game()
    snake = {
        {x = 15, y = 13},
        {x = 14, y = 13},
        {x = 13, y = 13}
    }
    dx = 1
    dy = 0
    input_q = {}

    score = 0
    apples_eaten = 0
    base_delay = 7
    move_delay = base_delay
    move_timer = 0

    spawn_apple()
    golden_apple = nil
    golden_timer = 0

    particles = {}
    shake = 0
    gameover_timer = 0
    is_new_high = false
    state = "play"
end

function init_title_snake()
    title_snake = {}
    for i = 1, 10 do
        add(title_snake, {x = 32 - i * 2, y = 92})
    end
end

-- =============================================
-- update loop (60 fps)
-- =============================================
function _update60()
    t += 1

    -- screen shake decay
    if shake > 0 then
        shake *= 0.85
        if (shake < 0.2) shake = 0
    end

    update_particles()

    if state == "title" then
        update_title()
    elseif state == "play" then
        update_play()
    elseif state == "gameover" then
        update_gameover()
    end
end

function update_title()
    -- animate title snake
    for i = 1, #title_snake do
        local s = title_snake[i]
        s.x = (s.x + 0.6)
        s.y = 90 + sin((t + i * 8) / 40) * 3
        if (s.x > 132) s.x = -4
    end

    if btnp(4) or btnp(5) then
        sfx(4)
        start_new_game()
    end
end

function update_play()
    -- capture directional inputs (queue up to 2 commands for responsive cornering)
    if btnp(0) then queue_dir(-1, 0) end -- left
    if btnp(1) then queue_dir(1, 0)  end -- right
    if btnp(2) then queue_dir(0, -1) end -- up
    if btnp(3) then queue_dir(0, 1)  end -- down

    -- boost speed while holding ❎
    local current_delay = move_delay
    if btn(5) then
        current_delay = max(2, flr(move_delay / 2))
    end

    move_timer += 1
    if move_timer >= current_delay then
        move_timer = 0
        step_snake()
    end

    -- update golden apple
    if golden_apple then
        golden_timer -= 1
        -- golden sparkles
        if t % 4 == 0 then
            local gx, gy = grid_to_px(golden_apple.x, golden_apple.y)
            add_particle(gx + rnd(4), gy + rnd(4), 10, rnd(0.6)-0.3, -rnd(0.5), 15)
        end

        if golden_timer <= 0 then
            -- puff of smoke when golden apple expires
            local gx, gy = grid_to_px(golden_apple.x, golden_apple.y)
            for i = 1, 6 do
                add_particle(gx + 2, gy + 2, 6, rnd(1)-0.5, rnd(1)-0.5, 12)
            end
            golden_apple = nil
        end
    end
end

function queue_dir(ndx, ndy)
    local last_d = {dx = dx, dy = dy}
    if #input_q > 0 then
        last_d = input_q[#input_q]
    end

    -- prevent 180-degree immediate reversal
    if ndx != -last_d.dx or ndy != -last_d.dy then
        if ndx != last_d.dx or ndy != last_d.dy then
            if #input_q < 2 then
                add(input_q, {dx = ndx, dy = ndy})
            end
        end
    end
end

function step_snake()
    -- apply next queued turn
    if #input_q > 0 then
        local next_d = deli(input_q, 1)
        dx = next_d.dx
        dy = next_d.dy
    end

    local head = snake[1]
    local nx = head.x + dx
    local ny = head.y + dy

    -- check wall collision
    if nx < 1 or nx > grid_w or ny < 1 or ny > grid_h then
        die()
        return
    end

    -- check self collision (exclude tail tip because it moves forward unless growing)
    for i = 1, #snake - 1 do
        if nx == snake[i].x and ny == snake[i].y then
            die()
            return
        end
    end

    -- move head forward
    add(snake, {x = nx, y = ny}, 1)

    local ate = false

    -- check regular apple
    if nx == apple.x and ny == apple.y then
        score += 10
        apples_eaten += 1
        ate = true
        sfx(0)

        local px, py = grid_to_px(apple.x, apple.y)
        for i = 1, 10 do
            add_particle(px + 2, py + 2, 8, rnd(2)-1, rnd(2)-1, 16)
            add_particle(px + 2, py + 2, 14, rnd(1.5)-0.75, rnd(1.5)-0.75, 12)
        end

        -- speed scaling
        move_delay = max(3, base_delay - flr(apples_eaten / 4))

        -- spawn golden apple every 5 regular apples
        if apples_eaten % 5 == 0 and not golden_apple then
            spawn_golden_apple()
        end

        spawn_apple()
    end

    -- check golden apple
    if golden_apple and nx == golden_apple.x and ny == golden_apple.y then
        local bonus = 50 + flr(golden_timer / 10)
        score += bonus
        ate = true
        sfx(1)

        local px, py = grid_to_px(golden_apple.x, golden_apple.y)
        for i = 1, 16 do
            add_particle(px + 2, py + 2, 10, rnd(2.5)-1.25, rnd(2.5)-1.25, 20)
            add_particle(px + 2, py + 2, 9, rnd(2)-1, rnd(2)-1, 16)
            add_particle(px + 2, py + 2, 7, rnd(1.5)-0.75, rnd(1.5)-0.75, 12)
        end

        golden_apple = nil
    end

    -- remove tail if didn't eat
    if not ate then
        deli(snake)
    end
end

function die()
    sfx(2)
    shake = 8
    state = "gameover"
    gameover_timer = 0

    -- segment explosion particles
    for i = 1, #snake do
        local s = snake[i]
        local sx, sy = grid_to_px(s.x, s.y)
        add_particle(sx + 2, sy + 2, 11, rnd(2)-1, rnd(2)-1, 25)
        if (i % 2 == 0) add_particle(sx + 2, sy + 2, 3, rnd(2)-1, rnd(2)-1, 20)
    end

    -- update high score
    if score > high_score then
        high_score = score
        dset(0, high_score)
        is_new_high = true
    end
end

function update_gameover()
    gameover_timer += 1
    if gameover_timer > 20 and (btnp(4) or btnp(5)) then
        sfx(4)
        start_new_game()
    end
end

-- =============================================
-- food spawning
-- =============================================
function is_cell_occupied(gx, gy)
    for s in all(snake) do
        if (s.x == gx and s.y == gy) return true
    end
    if golden_apple and golden_apple.x == gx and golden_apple.y == gy then
        return true
    end
    if apple and apple.x == gx and apple.y == gy then
        return true
    end
    return false
end

function spawn_apple()
    local attempts = 0
    repeat
        apple = {
            x = flr(rnd(grid_w)) + 1,
            y = flr(rnd(grid_h)) + 1
        }
        attempts += 1
    until (not is_cell_occupied(apple.x, apple.y)) or attempts > 100
end

function spawn_golden_apple()
    local attempts = 0
    local gx, gy
    repeat
        gx = flr(rnd(grid_w)) + 1
        gy = flr(rnd(grid_h)) + 1
        attempts += 1
    until (not is_cell_occupied(gx, gy)) or attempts > 100

    golden_apple = {x = gx, y = gy}
    golden_timer = 300 -- 5 seconds at 60fps
    sfx(3)
end

-- =============================================
-- particle system
-- =============================================
function add_particle(x, y, col, vx, vy, max_life)
    add(particles, {
        x = x,
        y = y,
        col = col,
        vx = vx,
        vy = vy,
        life = max_life,
        max_life = max_life
    })
end

function update_particles()
    for p in all(particles) do
        p.x += p.vx
        p.y += p.vy
        p.life -= 1
        if p.life <= 0 then
            del(particles, p)
        end
    end
end

function draw_particles()
    for p in all(particles) do
        local c = p.col
        if p.life < p.max_life * 0.3 then
            c = 5 -- fade to dark gray
        end
        pset(p.x, p.y, c)
    end
end

-- =============================================
-- drawing & rendering
-- =============================================
function grid_to_px(gx, gy)
    return ox + (gx - 1) * cell_sz, oy + (gy - 1) * cell_sz
end

function _draw()
    -- apply screen shake
    if shake > 0 then
        local cam_x = rnd(shake * 2) - shake
        local cam_y = rnd(shake * 2) - shake
        camera(cam_x, cam_y)
    else
        camera(0, 0)
    end

    cls(0)

    if state == "title" then
        draw_title()
    else
        draw_playfield()
        draw_apples()
        draw_snake()
        draw_particles()
        draw_hud()

        if state == "gameover" then
            draw_gameover()
        end
    end
end

function draw_playfield()
    -- outer board boundary (colors 5 and 6)
    local bx1 = ox - 2
    local by1 = oy - 2
    local bx2 = ox + grid_w * cell_sz + 1
    local by2 = oy + grid_h * cell_sz + 1

    rect(bx1, by1, bx2, by2, 5)
    rect(bx1 - 1, by1 - 1, bx2 + 1, by2 + 1, 1)

    -- subtle background grid dots
    for gx = 1, grid_w, 2 do
        for gy = 1, grid_h, 2 do
            local px, py = grid_to_px(gx, gy)
            pset(px + 1, py + 1, 1)
        end
    end
end

function draw_hud()
    -- top HUD bar
    rectfill(0, 0, 127, 11, 1)
    line(0, 11, 127, 11, 5)

    -- score & high score
    print("SCORE:", 3, 3, 6)
    print(score, 28, 3, 7)

    print("BEST:", 82, 3, 6)
    print(high_score, 103, 3, (score >= high_score and score > 0) and 10 or 7)

    -- golden apple timer bar if active
    if golden_apple and state == "play" then
        local bar_w = flr((golden_timer / 300) * 24)
        local col = (golden_timer < 60 and (t % 6 < 3)) and 8 or 10
        rectfill(52, 4, 52 + bar_w, 7, col)
        rect(51, 3, 77, 8, 9)
    end
end

function draw_snake()
    if state == "gameover" and gameover_timer > 10 then
        -- don't draw snake after death explosion
        return
    end

    local len = #snake
    for i = len, 1, -1 do
        local s = snake[i]
        local sx, sy = grid_to_px(s.x, s.y)

        if i == 1 then
            -- snake head
            rectfill(sx, sy, sx + 3, sy + 3, 11)
            pset(sx, sy, 3)
            pset(sx + 3, sy, 3)
            pset(sx, sy + 3, 3)
            pset(sx + 3, sy + 3, 3)

            -- directional eyes
            local e1x, e1y, e2x, e2y, p1x, p1y, p2x, p2y
            if dx == 1 then
                e1x, e1y = sx + 2, sy
                e2x, e2y = sx + 2, sy + 2
                p1x, p1y = sx + 3, sy
                p2x, p2y = sx + 3, sy + 2
            elseif dx == -1 then
                e1x, e1y = sx + 1, sy
                e2x, e2y = sx + 1, sy + 2
                p1x, p1y = sx, sy
                p2x, p2y = sx, sy + 2
            elseif dy == -1 then
                e1x, e1y = sx, sy + 1
                e2x, e2y = sx + 2, sy + 1
                p1x, p1y = sx, sy
                p2x, p2y = sx + 2, sy
            else
                e1x, e1y = sx, sy + 2
                e2x, e2y = sx + 2, sy + 2
                p1x, p1y = sx, sy + 3
                p2x, p2y = sx + 2, sy + 3
            end

            -- eyes white & pupil
            pset(e1x, e1y, 7)
            pset(e2x, e2y, 7)
            pset(p1x, p1y, 0)
            pset(p2x, p2y, 0)

            -- tongue flick animation (every ~2 seconds)
            if (t % 120 > 100) and (t % 10 < 6) then
                local tx = sx + dx * 4 + (dy != 0 and 1 or 0)
                local ty = sy + dy * 4 + (dx != 0 and 1 or 0)
                pset(tx, ty, 8)
            end
        else
            -- snake body (alternating shade pattern)
            local col = (i % 2 == 0) and 11 or 3
            rectfill(sx, sy, sx + 3, sy + 3, col)
            pset(sx + 1, sy + 1, (i % 2 == 0) and 10 or 11)
        end
    end
end

function draw_apples()
    -- regular apple
    if apple then
        local ax, ay = grid_to_px(apple.x, apple.y)
        rectfill(ax, ay + 1, ax + 3, ay + 3, 8)
        pset(ax, ay + 1, 0)
        pset(ax + 3, ay + 1, 0)
        pset(ax + 1, ay, 11)   -- leaf
        pset(ax + 1, ay + 1, 14) -- highlight
    end

    -- golden apple
    if golden_apple then
        local gax, gay = grid_to_px(golden_apple.x, golden_apple.y)
        local flash_col = (t % 8 < 4) and 10 or 9
        if (golden_timer < 60 and (t % 4 < 2)) flash_col = 7

        rectfill(gax, gay + 1, gax + 3, gay + 3, flash_col)
        pset(gax, gay + 1, 0)
        pset(gax + 3, gay + 1, 0)
        pset(gax + 1, gay, 7) -- stem / star point
        pset(gax + 1, gay + 1, 7) -- bright center
    end
end

function draw_title()
    -- decorative background frame
    rect(6, 6, 121, 121, 5)
    rect(8, 8, 119, 119, 1)

    -- retro drop shadow title
    print("S N A K E", 39, 27, 3)
    print("S N A K E", 38, 26, 11)

    print("P I C O - 8", 43, 38, 5)

    -- animated title snake
    for i = 1, #title_snake do
        local s = title_snake[i]
        local c = (i == 1) and 10 or ((i % 2 == 0) and 11 or 3)
        rectfill(s.x, s.y, s.x + 3, s.y + 3, c)
        if i == 1 then
            pset(s.x + 2, s.y + 1, 7)
            pset(s.x + 3, s.y + 1, 0)
        end
    end

    -- apple preview on title screen
    rectfill(110, 91, 113, 93, 8)
    pset(111, 90, 11)

    -- start prompt (blinking)
    if t % 40 < 25 then
        print("PRESS ❎ TO PLAY", 32, 60, 7)
    end

    -- instructions
    print("⬅️➡️⬆️⬇️ : MOVE", 36, 75, 6)
    print("❎ (HOLD) : SPEED BOOST", 20, 106, 5)

    -- best score
    if high_score > 0 then
        print("BEST SCORE: "..high_score, 36, 114, 10)
    end
end

function draw_gameover()
    -- semi-transparent box
    fillp(0x5a5a)
    rectfill(16, 32, 111, 96, 0)
    fillp()

    rect(16, 32, 111, 96, 8)
    rect(18, 34, 109, 94, 0)

    print("G A M E   O V E R", 26, 40, 8)

    print("FINAL SCORE: "..score, 32, 54, 7)
    print("BEST SCORE:  "..high_score, 32, 64, is_new_high and 10 or 6)

    if is_new_high then
        if t % 20 < 12 then
            print("★ NEW BEST RECORD! ★", 21, 74, 10)
        end
    end

    if gameover_timer > 20 and (t % 30 < 20) then
        print("PRESS ❎ TO RETRY", 28, 85, 7)
    end
end

__sfx__
00040000240602807030055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400002006024060280602c0603007034070380750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008000018670146701067300c663008655004645000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000300603807500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000280500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
