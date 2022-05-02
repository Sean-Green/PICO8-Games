pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- ella in the dark

--flags
--0: lit area
--1: unlit area
--2: wall

function init_level()
	
	_update=update_level
	_draw=draw_level
	
	debug=false
 debugtext=""
 
 init_map()
 
	init_ella()
	
	enemies={}
	events={}
	
	cam={
		x=0,
		y=-2
	}
	
	trigger={}
	init_triggers()
	
	items={}
	init_items()
	
	death_leng=30
	death_anim=death_leng
	
end

function update_level()
	
		-- check ella alive
	if ella.health<1 then
		if death_anim==death_leng then
	 
			death_anim-=1
			ella.frame=1
			ella.anim_delay=4
		 ella.spr=ella.sit
		elseif death_anim==death_leng-9 then
			
			death_anim-=1
		 ella.spr=ella.cry
		
		elseif death_anim<-30 then
			init_level()
		else
			death_anim-=1		
		end
		
	end
	
	x=flr((ella.x)/8)
	y=flr((ella.y)/8)
	
	move_and_interact()
	update_camera()
	update_enemies()
	update_events()
	-- enemy_spawner() --unused spawn logic
	
	-- check triggers
	if trigger[x..","..y] != nil then
		trigger[x..","..y]()
	end

end

function draw_level()
	cls(0)	
	if ella.health<1 then
		local death_diff=
			death_leng-death_anim
		clip((ella.x) * (death_diff/death_leng)
						,(ella.y+8) * (death_diff/death_leng)
						,128-120*(death_diff/death_leng) 
						,128-112*(death_diff/death_leng) 
						)
	end
	--draw map 
 map(flr(cam.x/8),flr(cam.y/8),
		-(cam.x%8),-(cam.y%8),
		17,17)
	
	--draw items
	local icont=0
	for _, i in pairs(items) do
		i.draw()
		icont+=1
	end
		
	--draw enemies 
	for i=1, #enemies do
		if enemies[i].a_vis then
			palt(5,true)
			palt(0,false)
			spr(enemies[i].spr[
								enemies[i].frame
							]
						,enemies[i].x-cam.x
						,enemies[i].y-cam.y
						,enemies[i].xlen
						,enemies[i].ylen
						,enemies[i].left)
			palt()
		end
	end
	

	--draw ella
	
	clip()
	
	ella.draw()
	
	for i=0, 2 do
		local cin=14
		if i+1 > ella.health then
			cin=0
		end	
			super_print("♥",4+8*i,0*8+1,cin,8)

	end
	
	if false then
		print(death_anim,0,0,8)	
	end
	
end
-->8
-- helpers

function move_and_interact()
if ella.health<1 then return end
 local ex=flr(ella.x/8) 
 local ey=flr(ella.y/8)
	local mtile = 
		mget(flr((ella.x+4)/8),
							flr((ella.y+4)/8))
	local foottile = 
		mget(flr((ella.x+4)/8),
							flr((ella.y+12)/8))
	local floortile = 
		mget(flr((ella.x+4)/8),
							flr((ella.y+20)/8))
 local interacting=
 	ella.health<1
 	or ella.climbing 
 	or ella.hiding
		
	
	-- handle input ---------------------

	-- movement
	if btn(1) and not interacting then
		if not fget(mget(ex+1,ey),2)
					and
					not fget(mget(ex+1,ey+1),2) then
			ella.x+=ella.spd
			ella.spr=ella.walk
		else
			ella.spr=ella.stand
		end
		ella.left=false
	elseif btn(0) and not interacting then
		if not fget(mget(flr(ella.x-1)/8,ey),2)
					and
					not fget(mget(ex,ey+1),2) then
			ella.x-=ella.spd
			ella.spr=ella.walk
		end
		ella.left=true
	elseif not interacting then
		ella.spr=ella.stand
	else
		ella.spr=ella.stand
	end
	
	mtile = 
		mget(flr((ella.x+4)/8),
							flr((ella.y+4)/8))
	mtileright = 
		mget(flr((ella.x+4)/8),
							flr((ella.y+4)/8))
	foottile = 
		mget(flr((ella.x+4)/8),
							flr((ella.y+12)/8))
	floortile = 
		mget(flr((ella.x+4)/8),
							flr((ella.y+20)/8))
	-- check for walls
	
	--local flag=fget(tile)
	ella.uphint=not ella.hiding 
													and (mtile==110 
													or 	mtile==111)
													
	ella.downhint=ella.hiding
	
	-- check for lid
	if ella.uphint 
	and foottile==104 then
		
		local ftx=flr((ella.x+4)/8)
		local fty=flr((ella.y+12)/8)
		while mget(ftx,fty)==104 do
			fty-=1	
		end
		debugtext=ftx.." "..fty.." "..mget(ftx,fty)
		ella.uphint=mget(ftx,fty)!=72
		
	end														
		-- interactions------------------------
			
		--cupboard
	if btnp(3) and ella.hiding and (mtile==110 or mtile==111) 
	   or
	   btnp(2) and not ella.hiding and (mtile==110 or mtile==111) 
	then
		
		ella.hiding=not ella.hiding		
	
	--ladder down
	elseif btnp(3) 
								and 
								floortile==104 
								and
								foottile!=72
	then
  
  --align
		ella.x=flr((ella.x+4)/8)*8
		--find endpoint
		endpoint=flr((ella.y)/8)+1
		ella.climbing=true
		while 104==mget(flr(ella.x/8),endpoint+2) do
			endpoint+=1
		end
		endpoint*=8
		
	--ladder up
	elseif btnp(2) 
								and 
								foottile==104 
	then
	
	
	
		 --align
		ella.x=flr((ella.x+4)/8)*8
		--find endpoint
		endpoint=flr((ella.y)/8)+1
		ella.climbing=true
		while 104==mget(flr(ella.x/8)
																	,endpoint) 
		do
		
			endpoint-=1
		
		end
		
		-- if lid closed
		if mget(flr(ella.x/8)
									,endpoint)==72 then
			ella.climbing=false
		else
			endpoint=(endpoint-1)*8
		end
	
	end
		
	-- climbing logic	 
	if ella.climbing then
		ella.spr=ella.climb
		if endpoint<ella.y then
			ella.y-=2
		elseif endpoint>ella.y then
			ella.y+=2
		else
			ella.climbing=false
		end
	end
	
	-- is ella in the dark?
	ella.inthedark=
		0 == mget(flr((ella.x+4)/8),flr((ella.y+8)/8)) 
		or not fget(mget(flr((ella.x+4)/8),flr((ella.y+8)/8)), 0) 
		
end

function update_enemies()
	-- iterate through enemies
	for i=1, #enemies do
		-- run ai
		check_collision(i)
		enemies[i].ai(i)
		
	end
	if ella.damage>0 then
		ella.damage-=1
	end

end

function check_collision(i)
-- check player collision
		if ella.damage<1
			and not ella.hiding
			and ella.inthedark
			and 
			(
				(
				 (ella.x >= enemies[i].x and
			 	 ella.x < enemies[i].x+enemies[i].xlen*8
			 	)
					or 
					(ella.x+7 >= enemies[i].x and
				  ella.x+7 < enemies[i].x+enemies[i].xlen*8
				 )
				) 
				and
				(
				 (ella.y >= enemies[i].y and
				  ella.y < enemies[i].y+enemies[i].ylen*8
				 )
				 or
				 (ella.y+15 >= enemies[i].y and
				  ella.y+15 < enemies[i].y+enemies[i].ylen*8
				 )
				)
			) then
			ella.damage=60
			ella.health-=1
		end
end



-- converts anything to string, even nested tables
function str(any)
  if type(any)=="function" then 
   		return "function" 
	 end
  if any==nil then 
    	return "nil" 
  end
  if type(any)=="string" then
	    return any
  end
  if type(any)=="boolean" then
     if any then return "true" end
     return "false"
  end
  if type(any)=="table" then
     local str = "{ "
     for k,v in pairs(any) do
         str=str..tostring(k).."->"..tostring(v).." "
     end
     return str.."}"
  end
  if type(any)=="number" then
     return ""..any
  end
  return "unknown" -- should never show
end



function update_camera()
	if true then
	
		-- screen transition camera
		local diff=4
		if flr(ella.x/128) > flr(cam.x/128) then	
			cam.x+=diff
		elseif flr(ella.x/128) < cam.x/128 then
			cam.x-=diff
		end
		
	elseif false then
	
		-- follow camera	
		if ella.x - cam.x < 32 then
			cam.x = ella.x - 32
		end
		
		if ella.x - cam.x > 64 then
			cam.x = ella.x - 64
		end
		
		if ella.y - cam.y < 48 then
			cam.y = ella.y - 48
		end
		
		if ella.y - cam.y > 96 then
			cam.y = ella.y - 96
		end
		
		if cam.x<0 then cam.x=0 end
		
	end
	
end

function update_events()

	local tempevents={}
	local ti=1
	
	for i=1, #events do
	
		if events[i].timer>0 then
		
			events[i].go(i)
			tempevents[ti]=events[i]
			ti+=1
			
		end
		
	end
	
	events=tempevents
	
end

--requires table with 
--  anim_timer
--  anim_delay
--  frame
function animate(thing)

	if thing.anim_timer>0 then
		thing.anim_timer-=1
	else
		thing.frame+=1
		thing.anim_timer=thing.anim_delay
	end

	if thing.spr[thing.frame]==nil then
		thing.frame=1
	end
	
end

function init_map()

	for x=0, 15 do
		for y=0, 15 do
			
			mset(x,y,mget(x,y+16))
			
		end
	end

end

-->8
-- triggers
function init_triggers()
	trigger={}
		
	-------level 1 triggers-------
	
	--light goes out	
	trigger["6,1"]=function()
		t1={
		timer=30,
		on=true,
		go=function(i)
			events[i].timer-=1
			local t = events[i].timer
			if t > 0 and t%2==0  then
			
				events[i].on = 
					not events[i].on
					
				light_switch(3,0,events[i].on)
			
			else
			
				light_switch(3,0,false)
		
			end
		end
	
	}
		events[#events+1]=t1
		trigger["6,1"]=nil
	end
	
	--spawns monster on first floor
	trigger["10,1"]=function()
		spawn_first_enemy(2,1,false,fadein_runright)
		trigger["10,1"]=nil
	end
	
	handlehatch2=function()
		if btn(2) then
		
			--close hatch 1
			mset(14,2,72)
			mset(13,2,0)
			
		 --open hatch
			mset(12,5,0)
			mset(11,5,73)
			
			--flip switch
			mset(7,4,124)
			spawn_and_chase()		
			trigger["7,4"]=nil
			trigger["6,4"]=nil
		else 
			ella.uphint=true
		end
	end
	--flick switch to open hatch 2
	trigger["7,4"]=handlehatch2
	trigger["6,4"]=handlehatch2
	
	handleswitch4=function()
		if btn(2) then
			mset(9,9,0)
			mset(8,9,73)
			mset(4,7,124)	
			trigger["4,7"]=nil
			trigger["3,7"]=nil
		else 
			ella.uphint=true
		end
	end
	
	--flick switch to open hatch 3
	trigger["4,7"]=handleswitch4
	trigger["3,7"]=handleswitch4
	
	
	
	--pickup green keycard
	trigger["3,13"]=function()
		items.greenkey.found=true
		trigger["3,13"]=nil
	end
	
	--insert keycard
	trigger["10,13"]=function()
		if btn(2) and items.greenkey.found then
			-- open door
			door_state(false)
			items.greenkey.used=true
			mset(10,13,80)
			trigger["3,4"]=nil
		else 
			ella.uphint= 
			items.greenkey.found
			and not items.greenkey.used
		end
	end
	
	trigger["11,13"]=function()
		fset(mget(10,13),2,true)
		trigger["11,13"]=nil
	end
	
	trigger["12,13"]=function()
		fset(mget(11,13),2,true)
		trigger["12,13"]=nil
	end
	
		trigger["13,13"]=function()
		fset(mget(12,13),2,true)
		trigger["13,13"]=nil
	end
	
end


-- lvl1 lights out


lights={}
lights.on={
	{0,68},
	{83,84,85},
	{99,84,101},
	{116,116,116}
}
lights.off={
	{0,64},
	{0,0,0},
	{0,0,0},
	{125,125,125}
}

function light_switch(mx,my,turnon)
	mx=mx-1
	my=my-1
	
	if turnon then	
		mtiles=lights.on
	else
	 mtiles=lights.off
	end
	
	for y=1 ,#mtiles do
		for x=1 ,#mtiles[y] do
			mset(mx+x,my+y,mtiles[y][x])
		end
	end
	
end


function door_state(bool)
	
	fset(91,2, bool)
	fset(107,2,bool)
	fset(76,2,boolse)
		
end
-->8
-- items
function init_items()
	items["greenkey"]={
		offset=0,
		used=false,
		draw=function()
			if not items.greenkey.found then
				if items.greenkey.offset < 39 then
					items.greenkey.offset+=1
				else
					items.greenkey.offset=0
				end
				spr(112,
					24-cam.x,
					112-cam.y+flr(items.greenkey.offset/20))
			end
		end
	}
	
	items["greenlock"]={
		timer=60,
		draw=function()
		
		if not items.greenkey.found then
			return
		end
		
		items.greenlock.timer-=1
		if items.greenlock.timer<1 then
			items.greenlock.timer=60
		end
		
			if items.greenkey.found 
						and 
						not items.greenkey.used
						and
						items.greenlock.timer > 30 
			then
				spr(115,	
						8*10-cam.x,
						8*13-cam.y)
			end
		
		end
	}
	
	items["lvl1 door"]={
	 draw=function()
			if not items.greenkey.used then
				--11,12 to 11,14
				rectfill(11*8-cam.x+2,12*8-cam.y
												,11*8-cam.x+5,15*8-cam.y-1
												,5)
				line(11*8-cam.x+5
								,12*8-cam.y+1
								,11*8-cam.x+5
								,15*8-cam.y-2
								,7)					
			end
	 end
	 
	 
	}
	
	items["deadmonster"]={
 	active=false,
 	timer=60,
 	draw=function() 
 		print()
 	 if items.deadmonster.active then
		 	palt(5,true)
		 	palt(0,false)
	 		spr(226,88-cam.x,104-cam.y,2,2)
	 		palt()
 			if items.deadmonster.timer>0 then
	 			
	 			_update=update_win
	 			_draw=draw_win
	 			
 			end
 		end
 		
 	end
 }
end

-->8
--ella

init_ella=function()
	ella={
		x=8*4,
		y=8*1,
		spd=2,
		spr={1},
		vision=1,
		left=false,
		health=3,
		damage=0,
		hiding=false,
		climbing=false,
		inthedark=false,
		uphint=false,
		frame=1,
		sit={136,137,138},
		cry={139,140,141},
		stand={1},
		climb={4,5},
		walk={2,3},
		anim_delay=3,
		draw=function()
		 if not ella.hiding 
					and	(ella.damage%2 == 0 
									or ella.health < 1) 
			then
			
				if ella.health < 2 then
					spr(36,
									ella.x-cam.x,
									ella.y-8-cam.y
								)
				end
				
				palt(8,true)
				palt(0,false)
				if ella.inthedark then
					pal(9,13)
					pal(4,13)
					pal(15,6)
					pal(0,1)
				end
				
				if ella.anim_timer>0 then
					ella.anim_timer-=1
				else
					ella.frame+=1
					ella.anim_timer=ella.anim_delay
				end

				if ella.spr[ella.frame]==nil then
					ella.frame=1
				end
				
				
				spr(ella.spr[ella.frame],
								ella.x-cam.x,
								ella.y-cam.y,
								1,2,ella.left)
				palt(8,false)
				palt(0,true) 
				pal() 
			
			end
		
		if ella.health<1 then return end
				
			if ella.uphint then
				print("⬆️",
								ella.x-cam.x,
								ella.y-8-cam.y,
								12)
			end
			 
			if ella.hiding or ella.downhint then
					print("⬇️",
									ella.x-cam.x,
									ella.y-8-cam.y,
									12)
			end
		
		end
	}
	
	ella.spr=ella.stand
	ella.anim_timer=ella.anim_delay
end
-->8
-- enemies

function spawn_and_chase()
enemies[#enemies+1]={
		x=1*8,
		y=4*8,
		xlen=2,
		ylen=2,
		spd=2,
		spr={9},
		stand={9},
		fade={14},
		run={7,9,11},
		attack={39,41,43},
		climb={13,45},
		death={192,194,224,226},
		left=left,
		a_vis=false,
  anim_delay=4,
  frame=1,
  spawn=31,
  die=40,
  stage={true,false,false,false},
  -- 1->2->3->4->1 middle loop
  -- 						3->5    chase below
		ai=function(i)
		
			animate(enemies[i])
		
		
			-- fadein
			if enemies[i].spawn==31 then
				
				enemies[i].spr=enemies[i].fade
				enemies[i].x+=4
				enemies[i].xlen=1
				enemies[i].ylen=1	
					
				enemies[i].spawn-=1

			elseif enemies[i].spawn>0 then
				enemies[i].spawn-=1
				if enemies[i].spawn%4==0 then
					enemies[i].a_vis=true
				else
				 enemies[i].a_vis=false
				end
				
			-- run right
			elseif enemies[i].spawn==0 then
				
				enemies[i].spr=enemies[i].run
				enemies[i].x-=4
				enemies[i].xlen=2
				enemies[i].ylen=2	
				enemies[i].spawn-=1
				
			elseif enemies[i].stage[1] 
			and enemies[i].x<96 then

				enemies[i].x+=enemies[i].spd
				
			elseif enemies[i].stage[1] 
			and enemies[i].x>95 then
	
				enemies[i].stage[1]=false
				enemies[i].stage[2]=true
				
				enemies[i].spr=
					enemies[i].climb
				enemies[i].xlen=1

			elseif enemies[i].stage[2] 
			and enemies[i].y<64 then

				enemies[i].y+=enemies[i].spd
			elseif enemies[i].stage[2] 
			and enemies[i].y>63 then

				
				enemies[i].stage[2]=false
				enemies[i].stage[3]=true
				
				enemies[i].spr=
					enemies[i].run
				enemies[i].xlen=2
				enemies[i].left=true
				
			elseif enemies[i].stage[3] 
			and enemies[i].x>80 then
			
				enemies[i].x-=enemies[i].spd		
			
			-- chase below
			elseif enemies[i].stage[3] 
			and enemies[i].x>66 
			and (ella.x>64 and ella.y>64 
							or ella.y == 104) then
					
				enemies[i].stage[3]=false
				enemies[i].stage[5]=true
				
			-- chase left
			elseif enemies[i].stage[3] 
			and enemies[i].x>66 then
				
				enemies[i].frame=1
				enemies[i].spr={7}
				enemies[i].x-=enemies[i].spd
				enemies[i].y-=enemies[i].spd
			elseif enemies[i].stage[3] 
			--and enemies[i].x<67 
			and enemies[i].y<56 then
				enemies[i].frame=1
				enemies[i].spr={9}
				enemies[i].x-=enemies[i].spd
				enemies[i].y+=enemies[i].spd
			elseif enemies[i].stage[3] 
			and enemies[i].y>55 then
								
				enemies[i].stage[3]=false
				enemies[i].stage[4]=true
				
				enemies[i].spr=
					enemies[i].run	
				
			elseif enemies[i].stage[4] 
			and enemies[i].x>8 then
				enemies[i].x-=enemies[i].spd
			
			elseif enemies[i].stage[4]
			and enemies[i].y>32 then
				
				if mget(1,5!=0) and enemies[i].y<49 then
					mset(1,5,0)
					mset(2,5,74)
				end
				
				enemies[i].xlen=1
				enemies[i].spr=enemies[i].climb
				enemies[i].y-=enemies[i].spd
			
			elseif enemies[i].stage[4] then 
				enemies[i].xlen=2
				enemies[i].spr=enemies[i].run
				enemies[i].left=false
				enemies[i].stage[4]=false
				enemies[i].stage[1]=true
						
			-- climb to below
			elseif enemies[i].stage[5] then
		
				--move to ladder
				if enemies[i].x > 72 then
					enemies[i].x-=enemies[i].spd

				--climb below
				elseif enemies[i].y < 104 then
					enemies[i].spr=enemies[i].climb
					enemies[i].xlen=1
					enemies[i].y+=enemies[i].spd
				
				elseif enemies[i].y > 104 then
					enemies[i].y=104
				
				else
				 enemies[i].stage[5]=false
				 enemies[i].stage[6]=true
					enemies[i].spr=enemies[i].run
					enemies[i].xlen=2
				end
				
			-- chase below
			elseif enemies[i].stage[6] then
			 				
			 -- chase back up ladder	
				if ella.y<104 
				and (enemies[i].x>71
	    and enemies[i].x<74) then					
	    
	    enemies[i].stage[6]=false
	    enemies[i].stage[7]=true
	    
	    enemies[i].spr=enemies[i].climb
	    enemies[i].xlen=1
					
			 elseif enemies[i].left 
			 and enemies[i].x>8 then
			 
			 	enemies[i].x-=enemies[i].spd/2
				
				--triggers death state
				elseif enemies[i].x>87 then
					
					enemies[i].stage[6]=false
	    enemies[i].stage[9]=true
	    
	    enemies[i].spr=enemies[i].death
					enemies[i].anim_delay=20
					enemies[i].anim_timer=
											enemies[i].anim_delay
					enemies[i].frame=1
				else 
					if not ella.hiding 
					and ella.x>enemies[i].x then
						
						enemies[i].x+=enemies[i].spd
						
					end
					enemies[i].x+=1
					enemies[i].left=
						enemies[i].x>71 
						and not items.greenkey.used 
	
				end
				
			elseif enemies[i].stage[7] then
			
				enemies[i].y-=enemies[i].spd
			
				if enemies[i].y<65 then
					
					enemies[i].stage[7]=false
					enemies[i].stage[8]=true
					
					enemies[i].xlen=2
					enemies[i].left=true
					enemies[i].spr={11}
				
				end
					
			elseif enemies[i].stage[8] then
				
				if enemies[i].x>56 then
					enemies[i].x-=enemies[i].spd
				end
				
				if enemies[i].y>56 then
					enemies[i].y-=enemies[i].spd
				end
				
				if enemies[i].y<57 
				and enemies[i].y<57 then
					enemies[i].stage[8]=false
					enemies[i].stage[4]=true
					enemies[i].spr=
												enemies[i].run
				end
			elseif enemies[i].stage[9] then
				if enemies[i].die>0 then
					enemies[i].die-=1
				else 
					items.deadmonster.active=true
					enemies[i]=nil
				end
			end 
			
		end
	}
	enemies[#enemies].anim_timer=
		enemies[#enemies].anim_delay
end

function spawn_first_enemy(x,y,left,behavior)
	enemies[#enemies+1]={
		x=x*8,
		y=y*8,
		xlen=2,
		ylen=2,
		spr={9},
		fade={14},
		run={7,9,11},
		attack={39,41,43},
		left=left,
		a_vis=false,
		spawn=31,
		stop=false,
  anim_delay=4,
  frame=1,
		ai=fadein_runright
	}
	enemies[#enemies].anim_timer=enemies[#enemies].anim_delay
end

-- run right,then despawn
fadein_runright=function(i)
	animate(enemies[i])
	if enemies[i].spawn==31 then
		enemies[i].spr=enemies[i].fade
		enemies[i].x+=4
		enemies[i].xlen=1
		enemies[i].ylen=1		
		enemies[i].spawn-=1
		
		enemies[i].fadeout=15
		enemies[i].swipe=15
	elseif enemies[i].spawn>0 then
		enemies[i].spawn-=1
		if enemies[i].spawn%4==0 then
			enemies[i].a_vis=true
		else
		 enemies[i].a_vis=false
		end
	elseif enemies[i].spawn==0 then
		
		enemies[i].spr=enemies[i].run
		enemies[i].x-=4
		enemies[i].xlen=2
		enemies[i].ylen=2	
		enemies[i].spawn-=1
		
	elseif enemies[i].x<104 then
	
		--animate(enemies[i])
		enemies[i].x+=2
	
	elseif enemies[i].swipe>0 
	 and enemies[i].x>99 then 
		
		enemies[i].swipe-=1
		enemies[i].spr=enemies[i].attack
		--animate(enemies[i])
		
	elseif enemies[i].swipe==0
		and enemies[i].fadeout>14 then
		enemies[i].x+=4
		enemies[i].fadeout-=1
	elseif enemies[i].swipe==0
		and enemies[i].fadeout>0 then
		enemies[i].swipe-=1
		
		mset(13,2,73)
		mset(14,2,0)
	elseif enemies[i].swipe<0
		and enemies[i].fadeout>0 then
		enemies[i].spr=enemies[i].fade
		enemies[i].xlen=1
		enemies[i].ylen=1
		enemies[i].fadeout-=1
		if enemies[i].fadeout%4==0 then
			enemies[i].a_vis=true
		else
		 enemies[i].a_vis=false
		end
		
	else
		
		enemies[i]=nil
	
	end
	
end	
-->8
--title screen

function _init()
	init_title()
	_update=update_title
end

function init_title()
		title={
		x=32,
		y=32,
		text="ella in the dark"
	}
	
	title.x=flr((128-(#title.text*4))/2)
 
 init_ella()
	cam={x=0,y=0}
 ella.x=60
 ella.y=48
end

title_timer=60
choice=0
function update_title()
	
	if btnp(0) and choice > 0 then
		choice-=1
	elseif btnp(1) and choice < 1 then
	 choice+=1
	end
	
	if btnp(2) and choice<1 then
		_init=init_level
		_init()
	elseif btnp(2) and choice>0 then
		init_credits()
	end

end

title_text="00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000028000000000008200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000288880000008882000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000288200000028200000000000000000000000000000000000000000000000000000000000000000000000028000000000008200000000000000000000000000000220000000020000000000000000000000000000000000000000000000000000000000000000000000000288000000008882000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002888000000888820000000000000000000000000000000000000000000000000000000000000000000005050000000505000000000000000000000000000000002888200288882000000000000000000000000000000000000000000000000000000000000000000000555050505050555000000000000000000000000000000002220000222200000000000000000000000000000000000000000000000000000000000000000000055555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006666666666666666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001555555155aaaa51555555510000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111aa11111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000100000015555551555555515555555155155550100000001100000000000000000000000000000000000000000000000000000000000000000000001010101010110001555555515515555155555551555155515000001010100000000000000000000000000000000000000000000000000000000000000000000001010110011100015555555155555551555555515555155150000100110000000000000000000000000000000000000000000000000000000000000000000000000000000000100011111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000001010000001110111111115000555155555551555555515555555155555500011111100000101010101010111010000000000000000000000000000000000000101010000101101111115110005151555555515555555155555551555555500511111000010100110101001101000000000000000000000000000000000000010101100000111011111551550055515555555155555551555555515555555005511100001111101111101011101000000000000000000000000000000000000000000000000000000011111100111111111111111111111111111111111111011100000000000000000000000000000000000000000000000000000000000101101111100001111111555555505555555155555551555555515555555155555551510001101111111011110100000000000000000000000000000000000000101011111000011111515555555155555551555555515555515155555551555555515500111011111110111010100000000000000000000000000000000000001110111111000111155155555551555551515555555155555551555555515555555150011110111111101111010000000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000001010000001111101010001155555551155555515555555166666665555555511555555155555551511111101111111011110100000000000000000000000000101010000001111011010051555555515555555155555665666566656665555155555551555555515511011011111110111010000000000000000000000000000001010000011110111100515555555155555551555666656666556566666551555555115555555155111010111111101111000000000000000000000000000000000000000000000000001111111111111111111555555555555555555555511111111111111111111000000000000000000000000000000000000000000101011001111000011111105055555155555551555566656666666566666655666655515555555155555551111111101111110000000010000000000000000000101010101011100011111155555551555555515556666566666665666666656666655155551551555555515111111011111000000101000000000000000000000101100101111000011111555155515555555155666665666666656666666566666651555551515555555151111110111100000010101000000000000000000000000000000000000000111111111111111111155555555555555555555555555555511111111111111111110000000000000000000000000000000000000111101011111011111110115555515555555155556665665566656666666566666665666655515555555155555510111111000001111011110100000000001010101001111110111111101555555155555551555666655566656566666665666666656656655155555551555555501111100000111110111010000000000000010110111111101111111055555551555555515566666566666655666666656666666565666651555555515555555111111000111111101111000000000000000000000000000000000000111111111111111115555555555555555555555555555555555555511111111111111111000000000000000000000000000000000000001111101111101011155551555511515555666566666665566666656666666566666665666655515555515155555110111111101111010000000000000000000101011011110110111555515511555155556665666666656666666566666665666666656666555155555151555551101111111011101000000000000000000010101010111111101155555155555551555666656666666566666655666666655566666566666551555515515555551011111110110100000000000000000000000000000000000000111111111111111155555555555555555555555555555555555555555555111111111111111100000000000000000000000000000000000000010111101111155155555551555555656666666566666665666666656666666566666665665555515555155155511110111000000000000010100000000000001010111011111551555555515555566566666665666666656666666566666665666666656665555155555151555111101100000000110100110000000000000001011110111115515555555155555665666666656666666566666665666666656666666566655551555555515551111011111110111010101000000000000000000000000000111111111111111155555555555555555555555555555555555555555555555511111111111111110000000000000000000000000000000000101110111111105555555155515555666666556666666566666665666666656656666566666665655555515555555111111110111101000000000000000000010101101111111155555551555515556666666566656665666666000006666566655665666666656555555155555551511111101111101000000000000000001010111011111111555555511555555566666665666656656666604444406665666665656666666565555551555555515111111011010100000000000000000000000000000000011111111111111155555555555555555555550444444405555555555555555555551111111111111110000000000000000000000000001010111011111110115555515555555155666665666666656666666044444444406666656666666566666651555555515555551011111110111010101000000001010110111111101155555155555551566666656666666566666660444444f440666665666666656666666155555551555555101101111011110100010000000010101011111110115555515555555156666665666666656666660444444fff4066666566666665666666615555555155555510101111101110100010000000000000000000000001111111111111111555555555555555555555044444ffff4055555555555555555555511111111111111110000000000000000000000000000000101110111115515555555155556665666666656666666566044f4f0ff0f065666666656666665566665551515555515551111011110100000000000000000001011110111115515555555155556665666666656666666566044f4ffffff06566666665666666656666555155115551555111101111101000000000000000000000111011115551555555515555666566666665566666656604444ffeef406566666665666666656666555155551551555511101101010000000000000000000000000000001111111111111115555555555555555555555504444fffff405555555555555555555555511111111111111100000000000000000000000000000000000000105555555155555555666656656666666566666604444ff4444066666566666665666666656555555155555551111111101110101000000000000000000000000000000551555555556665666566666665666666604444ff9044066665666666656666666565555551555555511111111011110100000000000000000000000000055555515555555566666665666666656666600ff444999f0406666566666665666666656555555155555551511111101110100000000000000000000000000111111111111111555555555555555555555000fff9449999f0055555555555555555555555111111111111111000000000000000000000000100010101101115555155155551556666656666666566666660fff099449999fff06666666566666665666666515555555155555110111101000000000000001010101011101115555151555551556666656666666566666660ff00999499990fff066666656666666566666651555555515155511011111010000000000001010001011110115555515155555155666665666666656666666000099999999900ff066666656666666566666651555555511555551011010100000000000000000000000000001111111111111111555555555555555555555555099999999905005555555555555555555555111111111111111100000000000000000000000101011011111151555555515555566556666665666666656666660999999999066666656666556566666665666555515555555155111110110101000000000010101110111111515515555155555665666666656666666566666099999999990666666566556665666666656665555155555551551111101110101000000000010101101111115151555551555556656666666566666665666666009999999990666665556656656666666566655551555555515511111011110100000000000000000000000011111111111111155555555555555555555555555500ffff000555555555555555555555555551111111111111110000000000000000000000010001011110155555555555555155666665566666656666666566660fffff06666566666665566666655666666155555551555555501111111011110100001010101011111015555555555555515666666565566655666666656660fff0ff066665666666656666666565666661555115515555555011111110111010100001010001011110155555555555555156666665666566656666665566044f00ff06666566666665666666656666665155155551555555501111111011110100000000000000000001111111111111115555555555555555555555555504440044405555555555555555555555555555111111111111111000000000000000001111011111110111155555555555555566666666666666666666666666604440444406666666666666666666666666665555555555555551111101111101101111111111110111111555555555555555666666666666666666666666666000060000666666666666666666666666666655555555555555511111111011111111000000000000000001111111111111115555555555555555555555555555555555555555555555555555555555555555111111111111111000000000000000001111111111111111155555555555555566666666666666666666666666666666666666666666666666666666666666665555555555555551111111111111111100000000000000001111111111111111555555555555555555555555555555555555555555555555555555555555555511111111111111110000000000000000111110011111100155555155555155556566665666656566656666656666566666656666566666566666566665666656555155555551555511110111111110111100011111100111555115555115555156666566665566655666666566665666666566665666666566666566665666651555115555551155111110011111110000111111100111115115555115555515566556666566666656666656666656666665666665666665666666566665666551555511555555111111111001111111000000000000000011111111111111111555555555555555555555555555555555555555555555555555555555555551111111111111111100000000000000001001000111111001155511555551555551666665666666566666656666656666666656666656666665666556566666155555155555155551110011111110011100001010111001111511555551155555155666566566665666666566666566666666566666566666656556666566655155555115555115511111011111111001010101011101111110555555155555515555656666556566666656666665666666665666666566666656666666565555155555511555510111111001111111100000000000000000001111111111111111111155555555555555555555555555555555555555555555555555551111111111111111111100000000000000000000000000111110011115515555551555555155566666566666656666666566556666566666665666666656666555155555115555551151111011111110011001000000111110011111101555555155555515555556656666666565666665666655665666666656666666566555555155555515555555011111001111111000100000010111011111110115555515555551555555551666666656666666566666665656666666656666666155555555155555515555511001111100111111100000101011001111110011115551555555155555555515556666566666665666666666656666666566665555155555555155555515551111101111110011111110000000000000000000000000111111111111111111111111115555555555555555555555555555111111111111111111111111110000000000000000000000000000000101111101111111011555551555555555155555555155555566566666666665665555551555555551555555555155555100111101110111111001010000000000111100111111101111155155555555515555555515555555551555555555515555555515555555551555555555155111110110111110011111100010000001011110011111110110001115555555555155555555155555555515555555555155555555515555555515555555555111111110110011111001111010000000001010001011111011111100115555555515555555515555555551555555555551555555555155555555515555555511011111110111011101101101010000010101010101011001111111011111155551555555555155555555515555555555551555555555155555555515555111111011111110111111111100101010000000000000000000000000000000000001111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000111111110111111111110115555555155555555551555555555555155555555551555555511011111111111011111111011010101000000000000000000000011111111011111111111011111155515555555555515555555555551555555555515555111111011111111111011111111011010000000000000000000000001111111101111111111110111111111015555555555155555555555515555555555101111111111011111110111011111111001000000000000000000000000010111110111111111111011111111101111111115515555555555555155511111111011111111110111110001111011111110000000000000000000000000000010101010111111011101111111111011111111111011111111111110111111111111011111111110111011101011011101010000000000000000000000010101010101010110101010011111111101111111111110111111111111110111111111110111111111110110111101111010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111110111111111101111111111111011111111111111011111111111101111111111101111111111111011111010000000000000000000000000001011111111111101111111111011111111111110111111111111110111111111111011111111111101111111111111010100000000000000000000000000000001111111111110111111111101111111111111101111111111111101111111111111011111111111101111111111111010000000000000000000000000000000111111111111000111111111011111111111110111111111111100011111111111110111111111111011111111111101000000000000000000000000000001010101111111110101011111100111111111111101111111111000110111111111111110111111111111011111111110100000000000000000000000000000000000101011111000101001010010111111111111011111110001111110111111111111101111111111111011110101010101000000000000000000000000010100010101010101010000101001010111111111110111110011111111101111111111111101111111111110111010101000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010111101111111111111111011111111111111110111111111111111011111010110001111111111100000000000000000000000000000000000000000000000011010011111111111111101111111111111111101111111111111110110101000000001001000000000000000000000000000000000000000000000000000001011001111111111111111011111111111111111011111111111111000110100000000000001001000000000000000000000000000000000000000000000000101000001111111111111110111101111111111110011111111111101001010010000000000100000000000000000000000000000000000000000000000000000000000101011111111111000111111011111111010111111111010101001000000000000000000000000000000000000000000000000000000000000000000000000010101010101111101010101111111110101001111110101010101000100000000000000000000000000000000000000000000000000000000000000000000000000101010101010100010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010000000001000001000000010100000000000000000000000000000000000000000000000000"
float=15
function _draw()
 cls(0)
 
 txt_to_pic(title_text)
	
	super_print(title.text,
						title.x,title.y,4,9)
	
	local startx=34
	super_print("start",startx,104,4,9)
	super_print("credits",startx+38,104,4,9)
	
	local cx,cy=startx-10,104
	if choice==1 then
		cx=startx+28
	end
	float-=1
	if float==0 then float=15 end
	super_print("⬆️", cx,cy-flr(float/8),4,9)
	
	--ella.draw()
	super_print("v1.0",112,122,0,5)
	--super_print("gg games",1,122,0,5)
end

function super_print(t,x,y,cin,cout)

	print(t,x-1,y-1,cout)
	print(t,x-1,y,cout)
	print(t,x-1,y+1,cout)

	print(t,x+1,y-1,cout)
	print(t,x+1,y,cout)
	print(t,x+1,y+1,cout)
	
	print(t,x,y-1,cout)
	print(t,x,y,cout)
	print(t,x,y+1,cout)
	
	print(t,x,y,cin)

end
-->8
-- credit screen
function init_credits()
	_update=update_win
	_draw=draw_win
end

winmsg={
 	y=16,
		text="ella in the dark"
	}
	
credits={
	"game concept by",
	"david asplin and sean green",
	"",
	"coding and design",
	"@greenlance_games",
	"",
	"art and assets",
	"@thegreasyg"
}


credit_offset=128
credit_timer=60


function update_win()
	local amt=.25
	if btn(2) then
	amt=2
	end
	if credit_offset>32 then
		credit_offset-=amt
	end

end

function draw_win()
 cls(0)
 txt_to_pic(win_pic)
	super_print(winmsg.text, 
							(127-#winmsg.text*4)/2,
							winmsg.y
							,4,9)
	for i=1, #credits do 
		super_print(credits[i], 
							(127-#credits[i]*4)/2,
							credit_offset+i*8,4,9)
	end
end


win_pic="77777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777677777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777776777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777677777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777766677777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777667777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777666777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaccccccccccc77777777666777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9cccccca9ccccccccccc77777777766777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccca9cc9caac9cc9accccc7777777776677777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9aa9a9999a9aa9ccccc7777777766777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaa9aaaa9aaacccccc777777776777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9a9aaaaaa9a9cccccc77777776666777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9a9aaaaaaaa9a9ccccc777777666666777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9aaaaaaaaaa9cccccc777776677776777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccca9a9aaaaaaaaaa9aacccc77777777777766777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaa9aaaaaaaaaa9a9accc77777777777776677777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9aaaaaaaaaa9cccccc777777777777776777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9a9aaaaaaaa9a9ccccc7777777777777767777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9a9aaaaaa9a9cccccc7777777777777776777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaa9aaaa9aaacccccc7777777777777776777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9aa9a9999a9aa9ccccc7777777777777776777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccca9cc9caac9cc9accccc7777777777777776777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9cccccc9acccccc9cccc777777777777777677777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccacccccccccccc77677777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77766777777777677777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777767777777776777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777677777777776677777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777776777767777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777777667777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777777777777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777777777777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777777777777777777777777766777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777777777777777777777777767777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777777777777777777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777777777777777777777777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777677777777777777777777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777776677777777777777777777777777777777ccccccc77777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777667777777777777777777777777777777ccccc67777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777766777777777777777776777777777777cccc6777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777767777777777777777766777777777777cc667777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777776777776777777777777777776677777777777766677777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77776677777667777777777777777776677777777777766777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77767777776676777777777777777776667777777777767777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77677777776776667777777777777777667777777777777777777777777cccccccccccccccccccccccccccccccccccccccccccccc777777ccccccccccccc77777677777777677777677777666677777776677777777777777777777777ccccccccccccccccccccccccccccccccccccccccccccc777777777cccccccccc7777777777777777777777767766666667777777777777777776777777777777cccccccccccccccccccccccccccccccccccccccccccc777777777777cccccc77777777777777777777777777666667777667777777777777777767777777777cccccccccccccccccccccccccccccccccccccccccccc7777777777777ccccc77777777776777777777777777776677777777677777777777777776777777777cccccccccccccccccccccccccccccccccc7777ccccccc77777777777777ccc77777777776777777777777777777767777777776777777777777777777777777cc777777ccccccccccccccccccccccccc77777777ccccc77777777777777ccc777777777767777777777777777777777777777776777777777777777777777777777777777cccccccccccccccccccccc7777777777ccc777777777777777cc77777777777677777777777777777777777777777777777777777777777777777777777777777ccc777777ccccccccccc777777777777cc7777777777777777c77777777777667777777777777777777777777777777777777777777777777777777777777777cc77777777ccccccccc77777777777777c7777777777777777c7777777777676677776677777777777677777777777777777777777777777777777777777777777777777777cccccccc777777777777777777777777777777777777777776777767776677777777777777777777777777777776d777777777777777777777777777777777777cccccc7777777777777777777777777777777777777777767777777776677777777777777777777777777777666ddd77777777777776666777777777777777777ccccc777777777777777777776677777777777677777767777777777667777777777777777777777777766666ddddd77777777777777776677777776677777777cccc777777777777666777667766777777776dd777767777777737766667777777777777777777776666666dddd6ddd7777777777777777667776677677777777cc77777777777777776667777777777777666ddd77677777773337666677777777777777777777666d66d66dddd6dddd77777777777777766667777777777777777777777777777777767777777777776666dddddd7777773333336666667777777777777777666666dd6666ddddd6ddd66777777777777776677777777777777777766667777777776777777777777766d6d66ddddd7773333333777776677777777777666666666d6666666ddddddd66666777777777777776777777777777776667777777777777677777777777666d66dd66ddddd733333353777777777777776666666d6666d6666666dd66dddddd66666677777777777667777777777776777777777777777777777777776666666d6dddd6dddd33333335777777777777666666ddddd6666666666dddd66ddddddd6666667777777777677777777777777777777777777777777777776666d6d666666ddd6dd33333333377777777766666666dddddddd6666666ddddddd6dd6dddd66666667777777777777777777777777777777777777777777d66666ddd6666ddddddddd33333333377777777666666ddddd6666dd66d66666ddddddddddddd666666dddd7777777777777777777777777777777777777dd6d6666ddddd6d66dddd333d333333333377777776666666666d666666dddddd666dddddddddd6d66d66666ddddd77777777777777777777777777777777766d6666666ddd66ddddddd33333333533333377776666dd666666dddd6666dddddd66666ddddd6666666dd6d66dddddddd777777777777777777777777777d666dd66d666ddd66ddd6d33d33335333353333576666dddd66dddddddd666666dddd6666666dd6666666666ddddd66dddddddd77777ddd77dd77777777777ddd6dd6dddddd66dddddddd33333335333333333536666ddddd6ddddddd666dd6666dddddddd66dd6666dd66dddddddddd6666dd66ddddd6d66666dd777777dd66ddddddddddddddddd33d33333333333333333333666dddddddddd6dddddddd66666dddddd66ddd6ddddd666ddddddddddd66666ddddddd6dddd66dddd77ddddddddddddddd6d6dd33333333533333333333333336666ddddddd66666ddddddd66666dddd66ddd6dddddd6d6dddddddddddddd666dddddddddddd6d6ddddddddddddddd6dd6dddd33333333533335333333333533d6666dddd666666666dddddd666dddd66dddddddd6dddddddd6ddddddddddddd33dddddddddddddddddddddd6ddd66dd6ddddd33333333333553353335335333ddd666dd666ddd6666dddddddd6ddd666ddddddd6ddddddd6d6dd333ddddddd3333ddd33dddddddd6ddddd66ddd6dddddddddd35333333333333333333533354dddddddd6dddddddd66ddddddddddd6666dddddddddddddddddd33333ddddd333333d3333ddddddddddd6ddddddddddddddddd33535533353355453333345554ddddddddddddddddddddd6d6ddddddddd666ddddd33d33ddddd53333333333533333333333dddddddddddddddddddddddddd3333333353533455455543345554d6ddd33ddddddddddddddd6ddddddddddd66666d3333333dd3533335333333333333533333dddd333dddddddddddddddddd35335354534355453355545545554666d3333d333ddddddddddd66dddd00000dd66633533333333333333533333333333333333333355533ddddddddddd33dd3553335545545554333333333333536663333333333ddd33ddddddd6dd0444440ddd335333333333333333333333533335333533335555555333ddddd33355335553355333333333bbb33333355533d653353335333dd3333dddddddd044444440333333333533333353333533333534335333533335555555553d333555555553333333bbbbbbbabbbbb7bb33355535333333533333333333ddddd304444444440333533333533335333353335555543334533335335555555553555333333333bbbbbbbbbbb7bbbbbbbbbbeb333533333333333333333333333d330444444f440333353533333343334335555555345554553355533333333333333ebbbbbbbbbbbbbab7bbbbbbebcebbbbbbbb3333333333333333353335333330444444fff4033333435554554555455553355333333333333333bbbbbb7bbbbbbbbbbbbbbbabbbbbbbbbccbbbbb7bbbbbbbbb33333335333533353335333333044444ffff40355554555345545333333333333333bbbebbbbbbbbbbb7bbbebbab7bbabebbbbbbebbbbbbbbbbbbbbbbbbebbbbb3333353335333433543354553044f4f1ff1f0555534553333333333bbbbbbbbbbabbbbbbb7bbbbbbbbebbbbbebbbbbbbbb7cbbbbbebbbbbbbbbbbbbbbbbbbbbb5433433545555455545554555044f4ffffff03333333333bbbbbbbbbbbbbbebbbbbbbbbbbbbe7bbabbab7b7bbabbbbbbbbbbbbbbbabbb7bbbbbbbbbbbbbbbbb3545545554335543533333333304444ffe7f40bbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbabbbbbbebbbbbbbebbbbbabebbb7bbeabbbbbbbbbebbbbbbbbbbbbb3333333333333333333333333bb04444ffff740bbbbbbcbbbbbbbbbcbbbbbbbcbebbbb7b7bbbbbcbbbbbebbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb33333333335550303333bbbbbbb044444ff22c0bbbbbbbb7bbbabbbbebbb7bbbabbbbbbbcbbbbbbb7bbebbabbabbebbbebbbbbbbbbbbbbbbbbbbbbbbbbb3b33b3355533355330e0e0bbbbbbbbbb044449ff2cff0bbbabbbbbbbb7bbbb7bbbbbbbbbb7bbbbbebbbbbbbbb7bbbbbbabbeabbe7bbcbabbbbebbbbbbbbbbbb33b333335505033330eeee0bbbbbbbbbb0044499fc2ff0bbbbbbbbbbbbbabbbbbbbbcbcbbbbbbbbbbbbbabbbbbbcbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333330e0e0530e22e2e0bbbbbbbbbb0f449992220bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcbbbbbbbcebbbbbbebbbbbbbbbbbbbbbbbbbbbb33333333330eeee0330e00e03bbbbbbbbbb0ff499999f0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbeabbbbbbbbbcbbbbbbbbbbbbbbbbbbbbb3b33333333330ee0e0330e00e033bb3bb3bbb0ff999999f0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbbbbbbbababbbbbbbbbbbbbbbbbbbbbbbbb333333333330e2002e03022e2e033333b3bbb0ff99999990bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbcbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333b3b33b0e00e0b0300e003b3333333b30ff999999990bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333b3b3b0e2ee20b030b0bb3b3b33333330ff999999990bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbabcbbebbbbbbbbbbbbbbbbbbbb3bb3333333bbbbb0e2e220b030b3bbb3bbbb33330fff999999990b3bb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbbbbcbbbbbbbbbbbbbbbbbbbbb3b3bb3b3b33333333bbb3b300e0030030bbb3bbb3bbb556600f494999990333b3b3b3b3bbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbb3bb3b3b333333333333b3bbbb3b333030300303303bbbb5555666660000fffff0333333333333b33bb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbcbbbbbbbbbbb3b3b333333333333333b33bbbbb3bbb6666663030300303b55566666666666044fff00003333333333333b3bb3bbbbbbbbbbbbbbbbbbbbbbcbbbbbbbbbbbbbbb3b33333333333333333b3bbbb3030bb55555566300330355566666666666604ff0fff440b33b333333333333b3b3bbb3bbbbbbbbbbbbbbbbbbbbbbbbbbb3b3b33333333333333333b3bbbbbbb0a0a0b555555556603305556566666666666004f0044440bbbb3b333333333333333bb3b3bb3bbbbbbbbbbbbbbbbbbbbbb333333333333b3333b33bbbbbb3bbb0aaaa055555555556335555566666666666660444000006bb3bbbb33333333333333333333b3b3bb3bb3bbb3bbbbb3bb333333333333b3b3b3bbbbbbbbbbbbb0a9449a055555555556555556566666666666660000000666b3bbbbbb3b333333333333333333333333b33bb3b3bb333333333333b3b3b3bbbbbbb3bbbbbbbbbb0a44a05555555555555555556566666666666666666666666bbb3bbbbb33333333333333333333333333333333333333b33b33bbbbbbbbbb3bbbbbbb3bbbbbb0a9a93000555555555555555556565666666666666666666656bb3bbb3bbb3b333333333333333333333333b333b333bbbb0b0bbbbbbb3bbbbbbbbbbbbbbbbbb300a00350505555555555555565656566666666666666665566bb3b3bbbbbbbb33b3333333333333b333b33b3bbbbbbbbb0a0a0bbb3bb3bbbbbbbbb3bbbbbb3b3bb0303050500553055555555565656666666666666665566666bbb3b3b3bbbbbbbbb33b3b333b33b3bbbbbbbb0b0bb3b0aaaa0bbbbbbbbbbbbbbbbbbbb3bb3bb3b33035050500505555555556555656666666666666566666666b3bb3b3bb3b3bbbbbbbbbbbbbbbbbbbbb3bb0a0a0b30a9449a0bbbbbbbbbbbbbbbbb3b3bbbbb3033050505050055555555555556565666666666666666666666b3bbbbbb3bb3bb3bbbb3bbbb3bbb3bbbb3bb0aaaa0bb0a44a0bbbbbbbbbbbb3bbbbb3bbbb33b0305550000500505555555555555556566666655666666666666633b3bbb3bb3b3bbbbbbbbbb3bbb3bb3bbb0a9449a0b039a9a0bbbbbbbbbbbb33bbbbbb33333355555000000005555555555555555565666655666666666666663333bbbbb3bb3bbb3b0b0bbbb3bbbb3bbb30a44a0b0300a00bbb33b3bbbbbbb33bbbb333335555553000000055055555555555555556565565666666666666653333b3bbb3bbbbbb307070bbb3bbbbbb3b0a9a930b030b03bbbbb3333bbbb3b33bb3b333555550505000000050505555555555555555656556566666666666565333333b3bbbbbb3b077770bb3b030bb3bb00a0030030bb3b3bbbb3333bbb3bb33b33355555505050000000505050555555555555555555565656666666565656333333b3b3bb3b3076aa670bb07070bb3bbb0b0300303b0bb3bbbb3033bbbbb0333555550505000000000050000505055555555555555555556565656565656563333333333b333307aa703b077770bb33bbbb03030300b0b3bbbbb3033bb3b0035555505050000000000000000050505555555555555555565656565655555663333333333b33307676303076aa6703333b3b0303003303333bbbbb0033b3b3005505050000000000000000000005050555555555555555555565555555555563333333333333330070030307aa70333300033030333033333333b3000333330050500000000000000000000000005050555555555555555555555555555555533333333333333333030303036767033033300030330033333330333000333000050000000000000000000000000000050505555555505055555555555555550533333333333333333303003007003333003333033333033333330333000300000000000000000000000000000000000000505005050505055555555555555055533333333333333033030030303333333303333333003333303030300000000000000000000000"


//code taken an edited from
//https://www.lexaloffle.com/bbs/?pid=69552
function txt_to_pic(txt)
 local d={
 a=10,
 b=11,
 c=12,
 d=13,
 e=14,
 f=15
 }
 d['0']=0
 d['1']=1
 d['2']=2
 d['3']=3
 d['4']=4
 d['5']=5
 d['6']=6
 d['7']=7
 d['8']=8
 d['9']=9
 local x=1
 local y=1
 for i=1,#txt do
  if x>128 then 
   x=1
   y+=1
  end
  c=d[sub(txt,i,i)]
  pset(x-1,y,c)
  x+=1
 end
end

__gfx__
00000000888888888888888888888888888888888888888888888888555555585585555555555555555555555555555555555555508055550007000700000000
00000000884448888844488888888888884448888844488888444888555555558808085555555555555555555555855558855555807055550000000000000000
00700700844444888444448888444888844444888444448884444488555585550870078555555855855555555555558555888855587855557700000000000000
000770008444f4888444f4888444448884444488844444888444f488555555580000005555555585885585558558855555000085878800050777777700000000
0007700084f1f18884f1f1888444f488844444888444448884f1f188555858558877778555558588080008555555555880000005878000050077777000000000
00700700844fff88844fff8884f1f1888444448884444488844fff88555850808787878555855800088088555558855558870075587000050000000000000000
00000000844f4888844f4888844fff8888444f888f444888844f4888558780080080800555588000870078555585880000000008878000050000000000000000
00000000884f9888884f9888444f48888f949f888f949f88884f98f8558778000000008055808087000000855888808000870705888080880000000000000000
888844488899988888999888848f94888f999f888f999f8888999f88558087800800887855580008778770088880000887777775880008580000000000000000
888444448899988888999888889998888f99988888999f8888999888580808780080087855508000877708080000000008777775580000800000000000000000
888444f488f99888889f98888f999f88889998888899988888f99888580808808000088055580800080800858000558800870708800008080000000000000000
8884f0f0889998888899988889999998889999888999988888999888558588080080880855880080000000850808580000000085588008700000000000000000
89944fff899999888999998888999988899998888899998889999988555550805880058058780885880808788088880800800855808887080000000000000000
99944f4988f8f888888ff88888f8f88888f8f88888f8f88888f8f888555800055580080808778550005587785855808088580805800078850000000000000000
99f4f99888f8f88888f8f8888f888f8888f848888848f88888f8f888558800885800858588778850888587785555550855808085580888550000000000000000
94f9f8ff884444888844448884488448884888888888488888444488858008008880008580808088000808085555555505580855558800850000000000000000
88884448000000000000000000000000000000000000000000000000555555555555555555555555555555555558555555555555555550800000000000000000
88844444000000000000000000000000000000000000000000000000555555555555555555555558555555555555558555585555555550700000000000000000
888444f4000000000000000000000000000000000000000000000000888558558555555555555555855855555555580880855555555558780000000000000000
8884f0f0000000000000000000000000000000000000000000000000080855858855855558555580008088555558000700788555550008870000000000000000
89944fff000000000000000000000000000000000000000000000000707085880800085555555008800885555555008000085555550000870000000000000000
99944f49000000000000000000000000000000000000000000000000078888000880885555580000780755855555870777085555550000780000000000000000
9f9f499f000000000000000000000000000000000000000000000000708880008700785558588000800088588558087777785555550000870000000000000000
4f9ff88f000000000000000000000000000000000000000000000000788080870000008555587807777780858580008777055555588080880000000000000000
00000000000000000000000000000000000000000000000000000000855800087787700858508800777080085880000080800555585800080000000000000000
00000000000000000000000000000000000000000000000000000000855080008777080855808788000080085588000000888855508000080000000000000000
00000000000000000000000000000000000000000000000000000000585808000808008555800877888808855587800888780005580800000000000000000000
00000000000000000000000000000000000000000000000000000000558000800000008588000870700800855808788777778888507800880000000000000000
00000000000000000000000000000000000000000000000000000000580088858808087880008587080887888000877777700000580788800000000000000000
00000000000000000000000000000000000000000000000000000000800085500055877800085880808808780000887787788855558870000000000000000000
00000000000000000000000000000000000000000000000000000000000885508885877808008580088887080000088877770005555888080000000000000000
00000000000000000000000000000000000000000000000000000000080088880008080880008888800808080080808888888855558008850000000000000000
00000000000330000003300600000000000000000000000000000000000000000000000000000005200000000000000000006666666556666555555555555556
00011000003003000030030600000000000550000000000000000000000000000000000000000052220000000000000000060666665555666555555555555556
00111100003333000033336600000000005555000000000000000000000000000000000000000222222000000000000000006666655555566555555555555556
00055000003333000033336600000000006aa6000000000000000000000000000000000000000222222000000000000000060666666aa6666555555555555556
00000000000110000001166600000000066666600000000000000000000000000000000000000222222000000000000000006666666666666555555555555556
000000000010010000100c6600000000066666600000000000000000000000000022220000000222222000000000000000060666666666666555555555555666
000000000010010000106c6600000000666666660000000000000000000000000222225000000022250000000000000000006666666666666555555555555556
00000000000110000001c66600000000666666660000000000000000000000002222222500000002500000000000000000060666666666666555555555566666
0bb0000000011000000cc66600000006666666666000000000000000000000000000000000000000000000005555557700000000000000006555555555555556
b00b000000011000000cc66600000006666666666000000000000000000000000000000000000000000000000555577605555550000000006555555556666666
000bbbb000011000006cc66600000066666666666600000000000000000600000000000000000000000000000000666605e25551000000006555555555555556
000bbbb000011000006cc66600000066666666666600000000000000000660000000000000000000000000000006066605555551000000006555555666666666
0001100000011000066cc66600000666666666666660000000000000000666000000000000000000000000000000666605555551000000006555555555555556
0010010000011000066cc66600000666666666666660000000000000000666600000000000000000000000000006066605655651000000006555566666666666
0010010000011000666cc66600006666666666666666000000000000000666600000000000000000000000000000666605666651000000006555555555555556
0001100000011000666cc66600006666666666666666000000000000000666660000000000000000000000000006066605555551000000006556666666666666
00000000000000000000000000066666666666666666600000000000000666665555555500001111111100000000666600051111000000000005555555551000
00000000000000000000000000066666666666666666600000000000000666660500001000001111111100000006066600055100000000000555555555555510
00000000000000000000000000666666666666666666660000000000000666660555551000001111111100000000666600055100000000000555555555555510
00000000000000000000000000666666666666666666660000000000000666660500001000001111111100000006066600055100000000005551111111155511
00000000000000000000000006666666666666666666666000000000000666660555551000001111111100000000666600055100000000005511055555515151
00000000000000000000000006666666666666666666666000000000000666660500001000001111111100000006066600055100000000005510555555515151
00000000000000000000000066666666666666666666666600000000000666660555511000001111111100000555577600055100000000005510555555515151
00000000000000000000000066666666666666666666666600000000000666665500001100001111111100005555557700055100000000005510555555515511
bbb000000000000000000000000bb000cccccccc0000000000000000000666660000000000001111111100001111111100000000111111115510515555515151
b0300000000000000000000000b00b00111111110000000000000000000666660000000000001111111100001111111105555550111111115510515555511510
bb300000000000000000000000bbbb00111111110000000000000000000666660000000000001111111100001111111105a35551111111115510555555515100
0b000000000000000000000000bbbb00111111110000000000000000000666660000000000001111111100001111111105555551111111115510555555511110
0bb00000000000000000000000000000000000000000000000000000111ccccc0000000000000000000000001111111105666651000000005510555555511100
0b300000000000000000000000000000000000000000000000000000111ccccc0000000000000000000000001111111105655651000000005111111111111010
00000000000000000000000000000000000000000000000000000000111ccccc0000000000000000000000001111111105555551000000005555515151110100
00000000000000000000000000000000000000000000000000000000111ccccc0000000000000000000000001111111105555551000000001115151010000000
66666655556666660005555555551000000555555555100000055555555510008888888888888888888888888888888888888888888888880000000000000000
66665566665566660555555555555510055555555555551005555555555555108888888888888888888888888888888888888888888888880000000000000000
66656655556656660555555555555510055555555555551005555555555555108844488888888888888888888888888888888888888888880000000000000000
66565555555565665551111111155511555111111115551155511111111555118444448888888888888888888888888888888888888888880000000000000000
65655555555556565511055555515151551100555551515155115555555151518444f48888888888888888888888888888888888888888880000000000000000
56555555555555655510555555515151551dd55555515151551555555551515184f0f08884448888888888888888888888888888888888880000000000000000
5655555555555665551055555551515155ddd555555151515515555555515151844fff8844444888888888888888888888888888888888880000000000000000
6555555555556656551055555551551155d6d555555155115515555555515511844f4888444f4888884448888844488888444888884448880000000000000000
5555555555565656551051555551515155161515555151515515155555515151884f98884f0f0888844444888444448884444488844444880000000000000000
55555555556556565510515555511510556665155511151055151555555115108899988844fff8888444f4888444f4888444f4888444f4880000000000000000
55555555565556565510555555515100551dd5555511510055155555555151008899988884f9888884f0f08884f0f08884f0f08884f0f0880000000000000000
555555556555655655105555555111105510d55555111110551555555551111088f9988889998888844fff88844cff88844ffc88844cff880000000000000000
5555555655555556551055555551110055166555511111005515555555511100889999888f99f8888499948884999488849c948884999c880000000000000000
5555556655555666511111111111101051111111111110105111111111111010899f9f888999988889ffff8889ffff8889ffff8889ffff880000000000000000
555556565555555655555151511101005555515151110100555551515111010088f5f88899f9f888899ff988899ff988899ff988899ff9880000000000000000
55556556555666661115151010000000111515101000000011151510100000008844448889444488999444889994448899944488999444880000000000000000
55565556555555560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55655565566666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56555555555555560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66555556666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56555555555555560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56555666666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56555555555555560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65566666666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555855555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555888555555555555555558555585000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55558000855555855555558885558855000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55580700785888555555580085508055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55580000088000855555800708800055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55800077000000085558070008000855000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55800777700008085888000070000555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
58000007708808088008000770885555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
80000000000858850000007707855555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
80088000000085550050070708555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
80008800000008585055000000555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
80008580080008855555500000858555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
80808800088000855555000850085555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
58588000085800085580008850008585000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55800000858000085800000855000855000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
58000800080008000000000080500085000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555585555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555855855555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555500788855555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555000008555885555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55585700008550855555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55855000070550855555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55880000777550055555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
58000007707000055555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000007000000055557500555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000000005555000077007555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008808000000550000777700000555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000028000000000008200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000028888000000888200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000002882000000282000000000000000000000000000000000000000000000000000000000000000000000000280000000000082000000000000
00000000000000000220000000020000000000000000000000000000000000000000000000000000000000000000000000000288000000008882000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000288800000088882000000000000
00000000000000000000000000000000000000000000000000000000050500000005050000000000000000000000000000000028882002888820000000000000
00000000000000000000000000000000000000000000000000000000555050505050555000000000000000000000000000000002220000222200000000000000
00000000000000000000000000000000000000000000000000000005555555555555555500000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000066666666666666666660000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000001555555155aaaa51555555510000100000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000001111111111111aa111111111111000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000100000100000015555551555555515555555155155550100000001100000000000000000000000000000000000000
00000000000000000000000000000000101010101011000155555551551555515555555155515551500000101010000000000000000000000000000000000000
00000000000000000000000000000000010101100111000155555551555555515555555155551551500001001100000000000000000000000000000000000000
00000000000000000000000000000000000000000000100011111111111111111111111111111111100000000000000000000000000000000000000000000000
00000000000000000000000101000000111011111111500055515555555155555551555555515555550001111110000010101010101011101000000000000000
00000000000000000000001010100001011011111151100051515555555155555551555555515555555005111110000101001101010011010000000000000000
00000000000000000000010101100000111011111551550055515555555155555551555555515555555005511100001111101111101011101000000000000000
00000000000000000000000000000000000000001111110011111111111111111111111111111111111101110000000000000000000000000000000000000000
00000000000000000001011011111000011111115555555055555551555555515555555155555551555555515100011011111110111101000000000000000000
00000000000000000000101011111000011111515555555155555551555555515555515155555551555555515500111011111110111010100000000000000000
00000000000000000000111011111109999999599959999955599999999555599999999999995559999999999999999911111110111101000000000000000000
00000000000000000000000000000009444949194919444911194449449911194449494944491119449944494449494900000000000000000000000000000000
00000000000001010000001111101019499949594959494955599499494966699499494949991559494949494949494911101111111011110100000000000000
00000000000010101000000111101109449949594959444955519499494966659499444944915559494944494499449901101111111011101000000000000000
00000000000000010100000111101119499949994999494955599499494966669499494949995559494949494949494910101111111011110000000000000000
00000000000000000000000000000009444944494449494911194449494955559499494944491119444949494949494900000000000000000000000000000000
00000000010101100111100001111119999999999999999955599999999966659999999999995559999999999999999911111110111111000000001000000000
00000000001010101010111000111111555555515555555155566665666666656666666566666551555515515555555151111110111110000001010000000000
00000000000101100101111000011111555155515555555155666665666666656666666566666651555551515555555151111110111100000010101000000000
00000000000000000000000000000011111111111111111115555555555555555555555555555551111111111111111111000000000000000000000000000000
00000001111010111110111111101155555155555551555566656655666566666665666666656666555155555551555555101111110000011110111101000000
00001010101001111110111111101555555155555551555666655566656566666665666666656656655155555551555555501111100000111110111010000000
00000001011011111110111111105555555155555551556666656666665566666665666666656566665155555551555555511111100011111110111100000000
00000000000000000000000000001111111111111111155555555555555555555555555555555555555111111111111111110000000000000000000000000000
00000000001111101111101011155551555511515555666566666665566666656666666566666665666655515555515155555110111111101111010000000000
00000000010101101111011011155551551155515555666566666665666666656666666566666665666655515555515155555110111111101110100000000000
00000000101010101111111011555551555555515556666566666665666666556666666555666665666665515555155155555510111111101101000000000000
00000000000000000000000000111111111111111155555555555555555555555555555555555555555555111111111111111100000000000000000000000000
00000000000001011110111115515555555155555565666666656666666566666665666666656666666566555551555515515551111011100000000000001010
00000000000010101110111115515555555155555665666666656666666566666665666666656666666566655551555551515551111011000000001101001100
00000000000001011110111115515555555155555665666666656666666566666665666666656666666566655551555555515551111011111110111010101000
00000000000000000000000011111111111111115555555555555555555555555555555555555555555555551111111111111111000000000000000000000000
00000000001011101111111055555551555155556666665566666665666666656666666566566665666666656555555155555551111111101111010000000000
00000000010101101111111155555551555515556666666566656665666666000006666566655665666666656555555155555551511111101111101000000000
00000000101011101111111155555551155555556666666566665665666660444440666566666565666666656555555155555551511111101101010000000000
00000000000000000000000111111111111111555555555555555555555504444444055555555555555555555511111111111111100000000000000000000000
00001010111011111110115555515555555155666665666666656666666044444444406666656666666566666651555555515555551011111110111010101000
000001010110111111101155555155555551566666656666666566666660444444f4406666656666666566666661555555515555551011011110111101000100
00000010101011111110115555515555555156666665666666656666660444444fff406666656666666566666661555555515555551010111110111010001000
0000000000000000000001111111111111111555555555555555555555044444ffff405555555555555555555551111111111111111000000000000000000000
0000000000101110111115515555555155556665666666656666666566044f4f0ff0f06566666665666666556666555151555551555111101111010000000000
0000000001011110111115515555555155556665666666656666666566044f4ffffff06566666665666666656666555155115551555111101111101000000000
000000000000111011115551555555515555666566666665566666656604444ffeef406566666665666666656666555155551551555511101101010000000000
000000000000000000001111111111111115555555555555555555555504444fffff405555555555555555555555511111111111111100000000000000000000
000000000000000000105555555155555555666656656666666566666604444ff444406666656666666566666665655555515555555111111110111010100000
0000000000000000000000000551555555556665666566666665666666604444ff90440666656666666566666665655555515555555111111110111101000000
00000000000000000000055555515555555566666665666666656666600ff444999f040666656666666566666665655555515555555151111110111010000000
0000000000000000000111111111111111555555555555555555555000fff9449999f00555555555555555555555551111111111111110000000000000000000
00000100010101101115555155155551556666656666666566666660fff099449999fff066666665666666656666665155555551555551101111010000000000
00001010101011101115555151555551556666656666666566666660ff00999499990fff06666665666666656666665155555551515551101111101000000000
0001010001011110115555515155555155666665666666656666666000099999999900ff06666665666666656666665155555551155555101101010000000000
00000000000000000011111111111111115555555555555555555555550999999999050055555555555555555555551111111111111111000000000000000000
00000101011011111151555555515555566556666665666666656666660999999999066666656666556566666665666555515555555155111110110101000000
00001010111011111151551555515555566566666665666666656666609999999999066666656655666566666665666555515555555155111110111010100000
00000101011011111151515555515555566566666665666666656666660099999999906666655566566566666665666555515555555155111110111101000000
00000000000000000011111111111111155555555555555555555555555500ffff00055555555555555555555555555111111111111111000000000000000000
0000010001011110155555555555555155666665566666656666666566660fffff06666566666665566666655666666155555551555555501111111011110100
001010101011111015555555555555515666666565566655666666656660fff0ff06666566666665666666656566666155511551555555501111111011101010
0001010001011110155555555555555156666665666566656666665566044f00ff06666566666665666666656666665155155551555555501111111011110100
00000000000000000111111111111111555555555555555555555555550444004440555555555555555555555555555511111111111111100000000000000000
11110111111101111555555555555555666666666666666666666666666044404444066666666666666666666666666655555555555555511111011111011011
11111111110111111555555555555555666666666666666666666666666000060000666666666666666666666666666655555555555555511111111011111111
00000000000000000111111111111111555555555555555555555555555555555555555555555555555555555555555511111111111111100000000000000000
11111111111111111555555555555555666666666666666666666666666666666666666666666666666666666666666655555555555555511111111111111111
00000000000000001111111111111111555555555555555555555555555555555555555555555555555555555555555511111111111111110000000000000000
11111001111110015555515555515555656666566665656665666665666656666665666656666656666656666566665655515555555155551111011111111011
11000111111001115551155551155551566665666655666556666665666656666665666656666665666665666656666515551155555511551111100111111100
00111111100111115115555115555515566556666566666656666656666656666665666665666665666666566665666551555511555555111111111001111111
00000000000000001111111111111111155555555555555555555555555555555555555555555555555555555555555111111111111111110000000000000000
10010001111110011555115555515555516666656666665666666566666566666666566666566666656665565666661555551555551555511100111111100111
00001010111001111511555551155555155666566566665666666566666566666666566666566666656556666566655155555115555115511111011111111001
01010101110111111055555515555551555565666655656666665666666566666666566666656666665666666656555515555551155551011111100111111110
00000000000000000011111111111111111111555555555555555555555555555555555555555555555555555511111111111111111111000000000000000000
00000000111110011115515555551555555155566666566666656666666566556666566666665666666656666555155555115555551151111011111110011001
00000011111001111110155555515555551555555665666666656566666566665566566666665666666656655555515555551555555501111100111111100010
00000101110111111101155555155555515555555516666666566666665666666656566666666566666661555555551555555155555110011111001111111000
00101011001111110011115551555555155555555515556666566666665666666666656666666566665555155555555155555515551111101111110011111110
00000000000000000000000011111111111111111111111111555555555555555555555555555511111111111111111111111111000000000000000000000000
00000001011111011111110115555515555555551555555551555555665666666666656655555515555555515555555551555551001111011101111110010100
00000000111100111111101111155155555555515555555515555555551555555555515555555515555555551555555555155111110110111110011111100010
00000101111001111111011000111555555555515555555515555555551555555555515555555551555555551555555555511111111011001111100111101000
00000010100010111110111111001155555555155555555155555555515555555555515555555551555555555155555555110111111101110111011011010100
00010101010101011001111111011111155551555555555155555555515555555555551555555555155555555515555111111011111110111111111100101010
00000000000000000000000000000000000111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000
00000000000000001111111101111111111101155555551555555555515555555555551555555555515555555110111111111110111111110110101010000000
00000000000000011111111011111111111011111155515555555555515555555555551555555555515555111111011111111111011111111011010000000000
00000000000000111111110111111111111011111111101555555555515555555555551555555555510111111111101111111011101111111100100000000000
00000000000000101111101111111111110111111111011111111155155555555555551555111111110111111111101111100011110111111100000000000000
00000000000000010101010111111011101111111111011111111111011111111111110111111111111011111111110111011101011011101010000000000000
00000000001010101010101011010101001111111110111111111111011111111111111011111111111011111111111011011110111101010101010000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000011111111111110111111111101111111111111011111111111111011111111111101111111111101111111111111011111010000000000
00000000000000000101111111111110111111111101111111111111011111111111111011111111111101111111111110111111111111101010000000000000
00000000000000000011111111111101111111111011111111111111011111111111111011111111111110111111111111011111111111110100000000000000
00000000000000000111111111111000111111111011111111111110111111111111100011111111111110111111111111011111111111101000000000000000
00000000000000101010111111111010101111110011111111111110111111111100011011111111111111011111111111101111111111010000000000000000
00000000000000000001010111110001010010100101111111111110111111100011111101111111111111011111111111110111101010101010000000000000
00000000000010100010101010101010000101001010111111111110111110011111111101111111111111101111111111110111010101000001000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000010101111011111111111111110111111111111111101111111111111110111110101100011111111115050550000005550
00000000000000000000000000000000011010011111111111111101111111111111111101111111111111110110101000000001001000005050050000005050
00000000000000000000000000000000101100111111111111111101111111111111111101111111111111100011010000000000000100105050050000005050
00000000000000000000000000000001010000011111111111111101111011111111111100111111111111010010100100000000001000005550050000005050
00000000000000000000000000000000000000101011111111111000111111011111111010111111111010101001000000000000000000000500555005005550
00000000000000000000000000000000000001010101010111110101010111111111010100111111010101010100010000000000000000000000000000000000
00000000000000000000000000000000000000001010101010101000101010101010101010101010100000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000001010000000001000001000000010100000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000400000001010101000000000005000404000404040101010000000404050004000000040000000004000004040400000000
0101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
6900440000000000000000000000006a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
69535455000000000000006e6f00006a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
69635465000000000000007e7f00486a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
697474747d7d7d7d7d7d7d7d7d7d686a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
690000410000005c000000000000686a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
694700510000006c000000004800686a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
69687d7d7d7d7d7d7d7d7d7d687d7b6a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
696800005c0000006d00000068007b6a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
696800006c0000000000000068007b6a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
697b687d7d687b680048000068007b6a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
697b680000687b7d7d687d7b7b7b7b6a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
697b680000687b000068007b644d646a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
697d7d7d7d7d7d000068005b6480816a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
690000006e6f00000068004c6490916a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
690000007e7f00000068006b64a0a16a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
797d7d7d7d7d7d7d7d7d7d747474747a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6900000044000000000000000000006a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
69000053545500000000006e6f00006a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
69000063546500000000007e7f00486a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
697d7d7474747d7d7d7d7d7d7d7d686a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
690000000000005c000000000000686a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
694800000000006c000000004800686a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
69687d7d7d7d7d7d7d7d7d7d687d7b6a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
696800005c0000006d00000068007b6a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
696800006c0000000000000068007b6a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
697b687d7d687b680048000068007b6a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
697b680000687b7d7d687d7b7b7b7b6a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
697b680000687b000068007b644d646a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
697d7d7d7d7d7d000068005b6480816a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
69000000006e6f000068414c6490916a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
69000000007e7f000068516b64a0a16a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
797d7d7d7d7d7d7d7d7d7d747474747a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
