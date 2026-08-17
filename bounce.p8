-- bouncy ball demo
-- by zep

size  = 10
ballx = 64
bally = size
floor_y = 100

-- starting velocity
velx = rnd(6)-3
vely = rnd(6)-3

function _draw()
	cls(1)
	
	print("press ❎ to bump",
	      32,10, 6)
	
	fillp(░)
	rectfill(0,floor_y,127,127,12)
	fillp() -- reset
	
	circfill(ballx,bally,size,14)
	
	spr(1,ballx-4-velx, 
	      bally-4-vely)
end

function _update60()
	
	-- move ball left/right
	
	if ballx+velx < 0+size or
	   ballx+velx > 128-size
	then
		-- bounce on side!
		velx *= -1 
		sfx(1)
	else
		-- move by x velocity
		ballx += velx
	end
	
	-- move ball up/down
	
	if bally+vely < 0+size or
	   bally+vely > floor_y-size
	then
		-- bounce on floor/ceiling
		vely = vely * -0.9
		sfx(0)
		
		-- if bounce was too small,
		-- bump into air
		if vely < 0 and
		   vely > -0.5 then
			velx = rnd(6)-3
			vely = -rnd(5)-4
			sfx(3)
		end
		
	else
		bally += vely
	end
	
	-- gravity!
	vely += 0.2
	
	-- press ❎ to ranomly
	-- choose a new velocity
	if (btnp(5)) then
		velx = rnd(6)-3
		vely = rnd(6)-8
		sfx(2)
	end
	
end
