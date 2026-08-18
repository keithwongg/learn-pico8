pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- =============================================
-- snake - pico-8 (single file edition)
-- =============================================

-- sprite constants
SPR_HEAD_RIGHT = 1
SPR_HEAD_UP    = 2
SPR_HEAD_DOWN  = 3
SPR_HEAD_LEFT  = 4
SPR_BODY       = 5
SPR_TAIL       = 6
SPR_APPLE      = 7
SPR_GOLDEN     = 8
SPR_DEAD_HEAD  = 9
SPR_TROPHY     = 10
SPR_WALL       = 11

-- =============================================
-- 1. initialization & state management
-- =============================================

function _init()
    cartdata("kw_snake_p8_edu_v1")
    high_score = dget(0) or 0

    -- grid dimensions (8x8 pixel cells)
    cell_sz = 8
    grid_w = 14
    grid_h = 13
    ox = 8
    oy = 16

    state = "title" -- "title", "play", "gameover"
    t = 0
    shake = 0
    particles = {}

    init_title_anim()
end

function start_new_game()
    init_snake()

    score = 0
    apples_eaten = 0
    base_delay = 10 -- 10 frames per grid step at 60fps
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

function init_title_anim()
    title_snake = {}
    for i = 1, 8 do
        add(title_snake, {x = 30 - i * 6, y = 88})
    end
end

-- =============================================
-- 2. main game loop (_update60 & _draw)
-- =============================================

function _update60()
    t += 1

    -- update particles & screen shake
    update_particles()
    if shake > 0 then
        shake *= 0.85
        if (shake < 0.2) shake = 0
    end

    if state == "title" then
        update_title()
    elseif state == "play" then
        update_play()
    elseif state == "gameover" then
        update_gameover()
    end
end

function update_title()
    for i = 1, #title_snake do
        local s = title_snake[i]
        s.x += 0.8
        s.y = 86 + sin((t + i * 10) / 45) * 4
        if (s.x > 136) s.x = -8
    end

    if btnp(4) or btnp(5) then
        sfx(4)
        start_new_game()
    end
end

function update_play()
    -- input polling (queue up to 2 commands for responsive cornering)
    if btnp(0) then queue_dir(-1, 0) end -- left
    if btnp(1) then queue_dir(1, 0)  end -- right
    if btnp(2) then queue_dir(0, -1) end -- up
    if btnp(3) then queue_dir(0, 1)  end -- down

    -- speed boost dash while holding ❎
    local current_delay = move_delay
    if btn(5) then
        current_delay = max(2, flr(move_delay / 2))
    end

    move_timer += 1
    if move_timer >= current_delay then
        move_timer = 0
        step_snake()
    end

    update_food()
end

function update_gameover()
    gameover_timer += 1
    if gameover_timer > 20 and (btnp(4) or btnp(5)) then
        sfx(4)
        start_new_game()
    end
end

function _draw()
    apply_camera_shake()
    cls(0)

    if state == "title" then
        draw_title()
    else
        draw_playfield()
        draw_food()
        draw_snake()
        draw_particles()
        draw_hud()

        if state == "gameover" then
            draw_gameover()
        end
    end
end

-- =============================================
-- 3. snake mechanics & collisions
-- =============================================

function init_snake()
    snake = {
        {x = 7, y = 7},
        {x = 6, y = 7},
        {x = 5, y = 7}
    }
    dx = 1
    dy = 0
    input_q = {}
end

function queue_dir(ndx, ndy)
    local last_d = {dx = dx, dy = dy}
    if #input_q > 0 then
        last_d = input_q[#input_q]
    end

    -- prevent 180-degree self reversal
    if ndx != -last_d.dx or ndy != -last_d.dy then
        if ndx != last_d.dx or ndy != last_d.dy then
            if #input_q < 2 then
                add(input_q, {dx = ndx, dy = ndy})
            end
        end
    end
end

function step_snake()
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

    -- check self collision
    for i = 1, #snake - 1 do
        if nx == snake[i].x and ny == snake[i].y then
            die()
            return
        end
    end

    -- add new head segment
    add(snake, {x = nx, y = ny}, 1)

    local ate = false

    -- regular apple collision
    if apple and nx == apple.x and ny == apple.y then
        score += 10
        apples_eaten += 1
        ate = true
        sfx(0)

        local px, py = grid_to_px(apple.x, apple.y)
        emit_burst(px + 4, py + 4, 8, 14, 12)

        -- speed scaling
        move_delay = max(4, base_delay - flr(apples_eaten / 3))

        -- spawn golden apple every 5 apples
        if apples_eaten % 5 == 0 and not golden_apple then
            spawn_golden_apple()
        end

        spawn_apple()
    end

    -- golden apple collision
    if golden_apple and nx == golden_apple.x and ny == golden_apple.y then
        local bonus = 50 + flr(golden_timer / 6)
        score += bonus
        ate = true
        sfx(1)

        local px, py = grid_to_px(golden_apple.x, golden_apple.y)
        emit_burst(px + 4, py + 4, 10, 9, 16)

        golden_apple = nil
    end

    -- remove tail if no food eaten
    if not ate then
        deli(snake)
    end
end

function die()
    sfx(2)
    shake = 10
    state = "gameover"
    gameover_timer = 0

    -- explode snake segments into debris
    for i = 1, #snake do
        local s = snake[i]
        local sx, sy = grid_to_px(s.x, s.y)
        emit_burst(sx + 4, sy + 4, 11, 3, 4)
    end

    -- record high score
    if score > high_score then
        high_score = score
        dset(0, high_score)
        is_new_high = true
    end
end

function get_head_sprite(cdx, cdy)
    if cdx == 1  then return SPR_HEAD_RIGHT end
    if cdx == -1 then return SPR_HEAD_LEFT  end
    if cdy == -1 then return SPR_HEAD_UP    end
    if cdy == 1  then return SPR_HEAD_DOWN  end
    return SPR_HEAD_RIGHT
end

-- =============================================
-- 4. food & golden apple management
-- =============================================

function is_cell_occupied(gx, gy)
    if snake then
        for s in all(snake) do
            if (s.x == gx and s.y == gy) return true
        end
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
    golden_timer = 360 -- 6 seconds at 60fps
    sfx(3)
end

function update_food()
    if golden_apple then
        golden_timer -= 1

        -- sparkles around golden apple
        if t % 5 == 0 then
            local gx, gy = grid_to_px(golden_apple.x, golden_apple.y)
            add_particle(gx + 2 + rnd(4), gy + 2 + rnd(4), 10, rnd(0.6)-0.3, -rnd(0.6), 18)
        end

        -- timeout
        if golden_timer <= 0 then
            local gx, gy = grid_to_px(golden_apple.x, golden_apple.y)
            emit_burst(gx + 4, gy + 4, 6, 5, 8)
            golden_apple = nil
        end
    end
end

-- =============================================
-- 5. particles & screen juice
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

function emit_burst(x, y, c1, c2, count)
    for i = 1, count do
        local col = (i % 2 == 0) and c1 or c2
        local angle = rnd(1)
        local speed = 0.5 + rnd(1.5)
        local vx = cos(angle) * speed
        local vy = sin(angle) * speed
        add_particle(x, y, col, vx, vy, 12 + flr(rnd(10)))
    end
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
        if p.life < p.max_life * 0.25 then
            c = 5 -- fade to dark gray
        end
        pset(p.x, p.y, c)
    end
end

function apply_camera_shake()
    if shake > 0 then
        local cam_x = rnd(shake * 2) - shake
        local cam_y = rnd(shake * 2) - shake
        camera(cam_x, cam_y)
    else
        camera(0, 0)
    end
end

-- =============================================
-- 6. sprite rendering & UI
-- =============================================

function grid_to_px(gx, gy)
    return ox + (gx - 1) * cell_sz, oy + (gy - 1) * cell_sz
end

function draw_playfield()
    local bx1 = ox - 2
    local by1 = oy - 2
    local bx2 = ox + grid_w * cell_sz + 1
    local by2 = oy + grid_h * cell_sz + 1

    rect(bx1, by1, bx2, by2, 5)
    rect(bx1 - 1, by1 - 1, bx2 + 1, by2 + 1, 1)

    -- subtle background grid dots
    for gx = 1, grid_w do
        for gy = 1, grid_h do
            local px, py = grid_to_px(gx, gy)
            pset(px + 3, py + 3, 1)
        end
    end
end

function draw_hud()
    -- top HUD bar
    rectfill(0, 0, 127, 13, 1)
    line(0, 13, 127, 13, 5)

    -- score with apple icon sprite
    spr(SPR_APPLE, 2, 2)
    print(score, 12, 4, 7)

    -- length
    print("L:"..#snake, 48, 4, 6)

    -- high score with trophy sprite
    spr(SPR_TROPHY, 82, 2)
    print(high_score, 92, 4, (score >= high_score and score > 0) and 10 or 7)

    -- golden apple timer bar if active
    if golden_apple and state == "play" then
        local bar_w = flr((golden_timer / 360) * 18)
        local col = (golden_timer < 60 and (t % 6 < 3)) and 8 or 10
        rectfill(62, 4, 62 + bar_w, 8, col)
        rect(61, 3, 81, 9, 9)
    end
end

function draw_snake()
    if state == "gameover" and gameover_timer > 15 then
        return
    end

    local len = #snake
    for i = len, 1, -1 do
        local s = snake[i]
        local sx, sy = grid_to_px(s.x, s.y)

        if i == 1 then
            -- snake head sprite
            local spr_id = get_head_sprite(dx, dy)
            if state == "gameover" then
                spr_id = SPR_DEAD_HEAD
            end
            spr(spr_id, sx, sy)
        elseif i == len and len > 2 then
            -- snake tail sprite
            spr(SPR_TAIL, sx, sy)
        else
            -- snake body segment sprite
            spr(SPR_BODY, sx, sy)
        end
    end
end

function draw_food()
    -- regular apple sprite (with gentle bob)
    if apple then
        local ax, ay = grid_to_px(apple.x, apple.y)
        local bob = flr(sin(t / 25) * 1)
        spr(SPR_APPLE, ax, ay + bob)
    end

    -- golden apple sprite
    if golden_apple then
        local gax, gay = grid_to_px(golden_apple.x, golden_apple.y)
        spr(SPR_GOLDEN, gax, gay)
    end
end

function draw_title()
    -- decorative frame
    rect(6, 6, 121, 121, 5)
    rect(8, 8, 119, 119, 1)

    -- stylized title banner
    print("S N A K E", 47, 25, 3)
    print("S N A K E", 46, 24, 11)
    print("P I C O - 8", 43, 36, 5)

    -- animated title snake using sprites
    for i = 1, #title_snake do
        local s = title_snake[i]
        if i == 1 then
            spr(SPR_HEAD_RIGHT, s.x, s.y)
        elseif i == #title_snake then
            spr(SPR_TAIL, s.x, s.y)
        else
            spr(SPR_BODY, s.x, s.y)
        end
    end

    -- apple preview sprite
    spr(SPR_APPLE, 108, 86)

    -- blinking start text
    if t % 40 < 25 then
        print("PRESS ❎ TO PLAY", 32, 56, 7)
    end

    -- controls
    print("⬅️➡️⬆️⬇️ : MOVE", 36, 70, 6)
    print("❎ (HOLD) : SPEED DASH", 18, 104, 5)

    -- best score
    if high_score > 0 then
        spr(SPR_TROPHY, 34, 112)
        print("BEST: "..high_score, 45, 113, 10)
    end
end

function draw_gameover()
    -- semi-transparent backdrop
    fillp(0x5a5a)
    rectfill(16, 32, 111, 96, 0)
    fillp()

    rect(16, 32, 111, 96, 8)
    rect(18, 34, 109, 94, 0)

    -- dead head icon
    spr(SPR_DEAD_HEAD, 24, 38)
    print("GAME OVER", 44, 40, 8)

    print("SCORE: "..score, 36, 54, 7)
    print("BEST:  "..high_score, 36, 64, is_new_high and 10 or 6)

    if is_new_high then
        if t % 20 < 12 then
            print("★ NEW BEST! ★", 38, 74, 10)
        end
    end

    if gameover_timer > 20 and (t % 30 < 20) then
        print("PRESS ❎ TO RETRY", 28, 85, 7)
    end
end

__gfx__
000000000033330000880000003333000033330000333300000000000004bb000007bb000033330000aaaa005555555500000000000000000000000000000000
0000000003b70bb303bbbb3003bbbb303bb07b3003bbba30003330000044b000007a900003707b300a7aa7a05666666500000000000000000000000000000000
000000003bb00bbb3b7007b33bbbbbb3bbb00bb33babbbb303bbb300088888800aaaaaa03b070bb30aaaaaa05611116500000000000000000000000000000000
000000003bbbbbb83b0000b33bbbbbb38bbbbbb33bbbbab33bbbb33088ee8888aa77aaaa3b707bb300aaaa005611116500000000000000000000000000000000
000000003bbbbbb83bbbbbb33b0000b38bbbbbb33bbbbbb33bbbb33088ee8888aa7799aa3b707bb3000aa0005611116500000000000000000000000000000000
000000003bb00bbb3bbbbbb33b7007b3bbb00bb33babbbb303bbb30088888888a999999a3b070bb3000aa0005611116500000000000000000000000000000000
0000000003b70bb303bbbb3003bbbb303bb07b3003bbba3000333000088888800999999003707b3000aaaa005666666500000000000000000000000000000000
000000000033330000333300008800000033330000333300000000000088880000999900003333000aaaaaa05555555500000000000000000000000000000000

__sfx__
00040000240602807030055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400002006024060280602c0603007034070380750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008000018670146701067300c663008655004645000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000300603807500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000280500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
