pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- tarogue: early access
function game_init()
	_update=level_update
	_draw=level_draw
 init_map(true)
 init_events_and_effects()
 turn=0
end

function level_update()
 if player.hp==0 then _init() end

	player.turn()
	if player.moved then
		player.moved=false
		turn+=1
		
		for i=1, #entities do
			local ent=entities[i]
		 	if ent.hp>0 then
				ent.turn(i)
			end
		end
		
	end

	-- run events
	for i=1, #events do
	 if not events[i].done then
			events[i].run(i)
		end
	end

	--clean up finished

	--entities
	local j=1
	local t_entities={}
	for i=1, #entities do
		local ent=entities[i]
		if ent.hp>0 then
			--ent.turn(i)
			t_entities[j]=ent
			j+=1
		end
	end
	entities=t_entities

	--events
	local j=1
	local t_events={}
	for i=1, #events do
	 if not events[i].done then
			t_events[j]=events[i]
			j+=1
		end
	end
	events=t_events
end
	
function level_draw()
 cls(0)
 
 world.draw()
	
	--draw entities
	for i=1, #entities do
		entities[i].draw(i)
	end
	
	player.draw()
	
	for i=1, #events do
		events[i].draw(i)	
	end
	--[[
	for v in all(find_shortest_path(entities[1], player)) do
		rect(v.x*8,v.y*8,v.x*8+7,v.y*8+7,8)
	end
	--]]
end
-->8

-- _init -----------------------

function init_map()
	world={}	
	entities={}
	for x=0, 15 do
	for y=0, 15 do
	 
		

		local s=mget(x,y)
		world[x..","..y]={x=x,y=y}

		if fget(s,sprflag.enemy) then 
			
			world[x..","..y].entity=init_enemy(x,y,s)
			entities[#entities+1]=world[x..","..y].entity
			s=0

		elseif fget(s,sprflag.player) then
			
			init_player(x+1,y)

		end

		if s==0 then

			s=flr(rnd(20))+77
			if s>79 then s=0 end
		end

		world[x..","..y].spr=s

		--[[
		--grass
			local sprite=flr(rnd(20))+109
			if flr(rnd(16))==1 then
			
			--rock
				sprite=99
			
			elseif sprite>111 then
				
				sprite=0
				
			end
			world[x..","..y]={
				spr=sprite
			}
		]]
	 end
	end
	world.draw=function()
		
	for y=0, 15 do
	 	for x=0, 15 do
	 		spr(world[x..","..y].spr
	 					,x*8
	 					,y*8)
	 	end
	 end
	 
	end
end

-- player
function init_player(x,y)
	player={
		x=x,
		y=y,
		ox=0,-- offsets for animations like player attack
		oy=0,
		spr=16,
		draw=function()
			--draw textbox
			local x1,x2,y1,y2=-1,128,118,128
			palt(0,true)
			rectfill(x1,y1,x2,y2,0)
			palt()
			rect(x1,y1,x2,y2,6)

			--draw health
			for i=1, player.hp do
				pal(5,14)
				pal(6,8)
				spr(19,(x1+2)+(i-1)*9,120)
				pal()
			end	

			-- draw abilities
			for i=1, 2 do
				local col,col2,sel=6,3,(i==player.a_index)
				if sel then
					col=11
					--if (wait) col=8 col2=2
					pal(5,col2)
					pal(6,col)
				end
				spr(16+i,(x1+2)+(i)*36,120)
				print(player.res[i],(x1+12)+(i)*36,121,col)
				pal()
				if (sel) spr(62,(x1+2)+(i)*36,117)
			end

			-- draw points
			local startx=104
			pal(5,4)
			pal(6,10)
			spr(20,startx,120)
			pal()
			print(player.points,startx+10,121,6)
			--[[sword
			pal(6,11)
			spr(17,x1+2,y1+1)
			print(player.res[resflag.swords], x1+12, y1+2)
			pal()
			-- wand			
			spr(18,18,y1+1)
			print(player.wands, 28, y1+2)

			local selx, colors={0,16},{13,13,13,13}
			colors[player.a_index]=11
			rect(selx[player.a_index],118,selx[player.a_index]+15,127,11)

			-- cups			
			spr(19,34,y1+1)
			print(player.cups, 44, y1+2)

			-- pentacles
			spr(20,50,y1+1)
			print(player.pentacles, 60, y1+2)
			]] 

			--draw player
			spr(player.spr,
						 player.x*8+player.ox,
						 player.y*8+player.oy)
			
		end,
		hp=3,
		points=0,
		ability={sword_charge, wand_shot},
		a_index=1,
		res={3,3},
		combo=0,
		turn=function()
			if wait then return end
			local xmod, ymod = get_xy_mods()
			
			if enemy_exists(player,xmod,ymod) then
				
				local w = world[player.x+xmod..","..player.y+ymod]
				
				player.combo+=1
				player.points+=player.combo
				regular_attack(player,xmod,ymod)
				w.entity.hp-=1
				w.entity=nil
				player.moved = true

			elseif (ymod!=0 or xmod!=0) and not wall_exists(player, xmod, ymod) then
			
				player.combo=0
				move(player,xmod,ymod)
				player.moved = true
			elseif btnp(5) and player.res[player.a_index]>0 then

				player.ability[player.a_index].target()
				
			elseif btnp(4) then
				if player.a_index==1 then player.a_index=2 else player.a_index=1 end
			end
		end
		
	}
end

-- entities
function init_entities()
	entities={}
	for i=1, 2 do
		entities[#entities+1]=init_enemy()
		local e1=entities[i]
		world[e1.x..","..e1.y].entity=e1
	end
	
end

-- events

function init_events_and_effects()
	events={}
	wait=false
	--effects={}
	add(events,{
		run=empty_fun,
		draw=empty_fun
	})
end

-- update ----------------------
function get_xy_mods()
	local xmod, ymod = 0, 0 
	
	if btnp(0) then
		xmod-=1
	elseif btnp(1) then
		xmod+=1
	elseif btnp(2) then
		ymod-=1
	elseif btnp(3) then
		ymod+=1
	end

	return xmod, ymod
end

-->8
wand_shot={
	name="wAND SHOT",
	target=function()
		wait=true
		events[#events+1]={
			name="wand shot",
			x=player.x+1,
			y=player.y,
			wait=true,
			path={},
			run=function(i)

				local e=events[i]
				--local range=8
				wait=true
				if e.wait then
					e.wait=false
					return
				elseif btnp(5) then 
					-- todo execute
					wand_shot.execute(e.path, true)
					player.res[resflag.wands]-=1
					e.done=true
					wait=false
					return
				end

				if btnp(4) then
					wait=false
					e.done=true
				end

				local xmod,ymod=get_xy_mods()
				if abs(e.x+xmod-player.x)+abs(e.y-player.y)<8 then				
					e.x+=xmod
				end
				if abs(e.y+ymod-player.y)+abs(e.x-player.x)<8 then				
					e.y+=ymod 				
				end
				if e.x==player.x and e.y==player.y then
					e.x+=xmod
					e.y+=ymod
				end
				
				local startx,				starty,			  endx,	   	endy=
							player.x*8+4,	player.y*8+4,	e.x*8+4,	e.y*8+4
				
				local truepath, basepath={}, get_tile_path(player, e)
				for i=1, #basepath do
					if fget(basepath[i].spr, sprflag.wall) or (i>1 and basepath[i-1].entity!=nil and fget(basepath[i-1].entity.spr,sprflag.enemy) ) then
						
						break
					end
					if i>1 and abs(basepath[i].x-basepath[i-1].x)==abs(basepath[i].y-basepath[i-1].y) then
						--check if we squeaked through a diagonal
						local x = basepath[i].x+(basepath[i].x-basepath[i-1].x) 
						local y = basepath[i].y+(basepath[i].y-basepath[i-1].y) 

						if fget(world[basepath[i].x..","..basepath[i-1].y].spr, sprflag.wall) and fget(world[basepath[i-1].x..","..basepath[i].y].spr,sprflag.wall) then		
							break
						end
					end
					truepath[i]=basepath[i]					
				end
				e.path=truepath	
			end,
			
			draw=function(i)

				local e=events[i]
				local startx,				starty,				endx,		endy=
							player.x*8+4,	player.y*8+4,	e.x*8+4,	e.y*8+4
				local path, fullpath=e.path, get_tile_path(player, e)
				
				for j=2, #fullpath do
					if j!=#fullpath and j!=#path then
						rect(fullpath[j].x*8,fullpath[j].y*8,fullpath[j].x*8+7,fullpath[j].y*8+7,4)
					end
				end

				pal(11,4)
				spr(18,endx-4,endy-4)
				pal()

				for j=2, #path do
					if j<#path then
						rect(path[j].x*8,path[j].y*8,path[j].x*8+7,path[j].y*8+7,11)
					else
					  if path[j].entity!=nil then
							--pal(11,8)
							spr(33,path[j].x*8,path[j].y*8)
							--spr(18,path[j].x*8,path[j].y*8,1,1,true)
							--pal()
						end
					end
				end
				-- pal(11)

				--get_tile_path(startx, starty, endx, endy)
				--[[drawing]]
				--line(startx,starty,endx,endy,11)
				--print(#path,0,0,11)

			end


		}
	end,
	execute=function(path,player_move_flag)
		events[#events+1]={
			name="wand shot execute",
			j=1,
			tile_path=path,
			done=false,
			run=function(i)

				local e=events[i]

				if not e.done 
					and e.j==#e.tile_path then
					
					e.done=true

					if player_move_flag then
						player.moved=true
					end
					
					if e.tile_path[e.j].entity!=nil then

						
						
						--[[print("Lenth of path:"..#e.tile_path..
									"\ntilex:"..e.tile_path[e.j].x..
									"\ntiley:"..e.tile_path[e.j].y..
									"\nentityhp:"..e.tile_path[e.j].entity.hp
						,0,0,11)--]]

						--lands on anything
					 	if e.tile_path[e.j].entity!=nil then
						  player.combo+=1
							player.points+=player.combo
							e.tile_path[e.j].entity.hp-=1
							e.tile_path[e.j].entity=nil
						else
							player.combo=0
						end
					
					end

				elseif e.j<#e.tile_path then
					
					e.j+=1

				end
			end,
			draw=function(i)
				
				local e=events[i]
				spr(33,e.tile_path[e.j].x*8,e.tile_path[e.j].y*8)

			end
		}

	end
}


sword_charge={
	name="sWORD CHARGE",
	target=function()
		if (player.res[resflag.swords]<1) return 
		wait=true
		events[#events+1]={
			name="chargetarget",
			x=player.x+1,
			y=player.y,
			wait=true,

			run=function(i)

				local e=events[i]
				wait=true
				if e.wait then
					e.wait=false
					return
				elseif btnp(5) and player.res[resflag.swords]>0 then 
					player.res[resflag.swords]-=1
					sword_charge.execute(e.x-player.x,e.y-player.y,3)
					--wait=false
					e.done=true
					return
				end

				if btnp(4)  then
					wait=false
					e.done=true
				end

				local xmod,ymod=get_xy_mods()

				if xmod!=0 or ymod !=0 then
					e.x=player.x+xmod
					e.y=player.y+ymod
				end

			end,
			
			draw=function(i)
				local e=events[i]
				local tx,ty=e.x*8,e.y*8
				--print(e.x-player.x.." "..e.y-player.y,0,0,8)
				--rect(tx,ty,tx+7,ty+7,8)
				pal(5,3)
				pal(6,11)
				spr(17,tx,ty)
				pal()
			end

		}
	end,
	execute=function(xmod, ymod, distance)
		
		local dist,limit=0,distance
		--[[]]
		while dist<=limit 
		and (not enemy_exists(player,xmod*dist,ymod*dist) 
				and not wall_exists(player,xmod*dist,ymod*dist)) do
			
			dist+=1
		
		end
		--]]

		events[#events+1]={
			name="chargeexecute",
			xm=xmod,
			ym=ymod,
			d=(dist-1)*8,
			dx=player.x+xmod*(dist-1),
			dy=player.y+ymod*(dist-1),
			run=function(i)
	--[[]]
				local e=events[i]
				wait=true
				if abs(player.oy)==e.d
				or abs(player.ox)==e.d then

					world[player.x..","..player.y].entity=nil

					player.x=e.dx
					player.y=e.dy
					player.ox=0
					player.oy=0
					world[player.x..","..player.y].entity=player
					if enemy_exists(player,e.xm,e.ym) then
						player.combo+=1
						regular_attack(player,e.xm,e.ym)
						world[player.x+e.xm..","..player.y+e.ym].entity.hp-=1
						world[player.x+e.xm..","..player.y+e.ym].entity=nil
					else
						player.combo=0
						wait=false
					end
					player.moved=true
					e.done=true
					return
				end
				
				player.ox+=e.xm*4
				player.oy+=e.ym*4

			
				--]]
			end,
			draw=function(i)
				
				local e=events[i]

				--print(e.d)
			end
		}

	end
}
function wall_exists(e,x,y)
	return e.x+x<0 or e.x+x>15			
		or e.y+y<0 or e.y+y>15			
		or fget(world[e.x+x..","..e.y+y].spr,sprflag.wall)
end

function enemy_exists(e,x,y)
	local w = world[e.x+x..","..e.y+y]
	return w!=nil
	 and w.entity!=nil	
	 and w.entity.type==etype.enemy
end

function anything_blocks(e,x,y)
	return (wall_exists(e,x,y) or enemy_exists(e,x,y))
end

function move(ent,xmod,ymod)

	world[ent.x..","..ent.y].entity=nil

	ent.x+=xmod
	ent.y+=ymod
	
	world[ent.x..","..ent.y].entity=ent

	 animate_move(ent, xmod, ymod)

end

function animate_move(ent, xmod, ymod)
	events[#events+1]={
		name="animatemove",
		timer=8,
		ent=ent,
		xm=xmod,
		ym=ymod,
		run=function(i)

			local me=events[i]

			if me.timer>=0 then
				ent.ox=me.xm*-me.timer
				ent.oy=me.ym*-me.timer
			end
			
			if me.timer==8 then
				wait=true
			elseif me.timer==0 then
			  wait=false
				me.done=true
			end

			me.timer-=2

		end,
		draw=empty_fun
	}
end

--[[
	
	returns a list of tiles a ray will pass through 
	in the order that it will pass through them

]]
function get_tile_path(start,_end)
  
	local startx,				starty,			  endx,	   	endy=
				start.x*8+4,	start.y*8+4,	_end.x*8+4,	_end.y*8+4
	local x,	inc=
				0,	.25
				
	if startx>endx then 
		inc*=-1 
	end

	local tiles_traveled={}

	--could probably do this calculation for both cases with proper trig
	-- case 1: straight up or down 
	if startx+x==endx then
		if endy<starty then
			inc= -1
		elseif endy>starty then
			inc= 1
		end
		local y, yend = flr(starty/8), flr(endy/8)

		while y!=yend do
			tiles_traveled[#tiles_traveled+1]=world[flr(startx/8)..","..y]
			y+=inc
		end 
		
		tiles_traveled[#tiles_traveled+1]=world[flr(startx/8)..","..y]
		
	end

	local f=flr
	-- case 2: angles
	if not ((startx<endx and starty<endy) or (startx>endx and starty>endy)) then
	 starty-=1
	 endy-=1
	 f=ceil
	end

	
	local slope=(endy-starty)/(endx-startx)

	--print(slope,0,0,4) --for debug
	while startx+x!=endx do

		local y,cx=f(x*slope+starty), x+startx
		local rectx,recty=flr(cx/8)*8,flr(y/8)*8
		--pset(cx,y,4) --for debug
		if #tiles_traveled==0 
			or not (tiles_traveled[#tiles_traveled].x==rectx/8 
			and tiles_traveled[#tiles_traveled].y==recty/8)  then
			--rect(rectx,recty,rectx+7,recty+7,11) -- for debug
			tiles_traveled[#tiles_traveled+1]=world[(rectx/8)..","..recty/8]
		
		end

		x+=inc

	end

	--print(#tiles_traveled,0,0,4) --for debug

	return tiles_traveled

end

--[[
	Basic attack events have a run and a draw call,
	run animates the character moving forward and back
	draw animates the attack swipe and damage displayed
]]
function regular_attack(entity,xmod,ymod)
	--world[entity.x+xmod..","..entity.y+ymod].entity.hp-=1
	--world[entity.x+xmod..","..entity.y+ymod].entity=nil
	wait=true
	events[#events+1]={
		name="regular_attack",
		timer=0,
		ent=entity,
		xm=xmod,
		ym=ymod,
		run=function(i)
			local this=events[i]
			if this.timer==0 then
			 this.timer+=1
			elseif this.timer<4 then
			 this.timer+=1
					entity.ox+=xmod
					entity.oy+=ymod
			elseif this.timer<7 then
			 this.timer+=1
					entity.ox-=xmod
					entity.oy-=ymod
			elseif this.timer>6 and this.timer<14 then
			 this.timer+=1
			else 
			end
			
		end,
		tx=(entity.x+xmod)*8,
		ty=(entity.y+ymod)*8,
		msg=player.combo,
		draw=function(i)
			local this=events[i]
			if this.timer<4 then
			elseif this.timer<7 then
				for j=0, 2 do
					line(this.tx+j,
										this.ty,
										this.tx+this.timer,
										this.ty+this.timer,
										10-j)
				end
				print(this.msg,
										this.tx+4,
										this.ty-this.timer,
										8)
				
			elseif this.timer>6 and this.timer<15 then
			 this.timer+=1
				print(this.msg,
										this.tx+4,
										this.ty-6,
										8)
			else
			 
				wait=false
			 this.done=true

			end
		end
	}
end

directions={
	north={0,-1},
	south={0, 1},
	west={0,-1},
	east={0,-1}
}

function init_enemy(x,y,s)
  -- Default case: Melee enemy
	local turntype,drawtype=basic_enemy_turn, basic_entity_draw

	if s==2 then --Ranged Enemy sprite 6
		turntype, drawtype=ranged_enemy_turn, ranged_enemy_draw
	end

	return {
		x=x,
		y=y,
		ox=0,
		oy=0,
		spr=s,
		type=etype.enemy,
		seen_player= false,
		draw=drawtype,
		hp=1,
		turn=turntype
	}
end

function ranged_enemy_draw(i)
			local me=entities[i]
			if me.seen_player then 
				local pp=get_tile_path(me,player)
				for j=2, #pp-1 do
					circ(pp[j].x*8+4,pp[j].y*8+4,1,8)
				end
			end
			basic_entity_draw(i)
end

function basic_entity_draw(i)
			local me=entities[i]
			spr(me.spr,
							me.x*8+me.ox,
							me.y*8+me.oy)
			print()
end

function ranged_enemy_turn(i)

	local me=entities[i]
	
	if me.x==player.x or me.y==player.y then
		
		local path_to_player=get_tile_path(me,player)
		
		if me.seen_player then
		
			wand_shot.execute(path_to_player,false)
			me.seen_player=false
		
		else

			for j=1, #path_to_player do
				if wall_exists(path_to_player[j],0,0) then
					return
				end
			end

			me.seen_player=true
		
		end

	else

		me.seen_player=false
	
	end
end

function basic_enemy_turn(i)
	--tokens before fix: 2958
	local me,seen=entities[i],true
	-- check for player in line of sight
	local ray=get_tile_path(me,player)
	foreach(ray, function(tile)
		if wall_exists(tile,0,0) then
			seen=false
		end
	end)

	if not seen then return end

	--check if attack
	if player_adjacent_to(me) then
	-- -- attack
		regular_attack(me, player.x-me.x, player.y-me.y)
		player.hp-=1
	else
		--[[]]route=find_shortest_path(me,player)
		if #route>1 then
			local next_node = route[#route-1]
			local xmod,ymod = next_node.x-me.x,next_node.y-me.y
			move(me, xmod, ymod)
		end--]]
	end
end

function find_shortest_path(start, end_node)

  local Q,xval,yval,dist_to_start,dist_to_end,prev={},{},{},{},{},{}
	
	--for k,v in pairs(world) do
	for x=0, 15 do
		for y=0,15 do
			local k=x..","..y
			local v=world[k]
			if not (anything_blocks(v,0,0)) or k==start.x..","..start.y then  
				if k==start.x..","..start.y then
					dist_to_start[k]=0
				else
					dist_to_start[k]=257
				end
				dist_to_end[k]=abs(end_node.x-start.x)+abs(end_node.y-start.y)
				prev[k]=nil
				xval[k]=v.x
				yval[k]=v.y
				add(Q,k)
			end
		end
	end
	--[[
	dist_to_start[start.x..","..start.y]=0
	prev[start.x..","..start.y]=nil
	xval[start.x..","..start.y]=start.x
	yval[start.x..","..start.y]=start.y
	--]]
	while #Q>0 do

		-- get the k with the min distance from Q and remove it from Q
		local u, neighbors=Q[1], {}
		for k in all(Q) do
			if dist_to_start[k]+dist_to_end[k]<dist_to_start[u]+dist_to_end[u] then
				u=k
			end
		end
		del(Q,u)

		-- if we have arrived at endx
		if xval[u]==end_node.x and yval[u]==end_node.y then
			--FOUND SHORTEST PATH
			local S={world[u]}
			while prev[u]!=nil or u==start.x..","..start.y do
				add(S,world[u])
				u=prev[u]
			end
			return S
		end
    
		--- get neighbors
		for xmod=-1,1 do
			for ymod=-1,1 do
				if not (abs(xmod)==1 and abs(ymod)==1) then 

					local v = xval[u]+xmod..","..yval[u]+ymod

					if count(Q,v)>0 then
						add(neighbors, v)
					end

				end
			end
		end

		-- for each neighbor v or u still in Q
		for v in all(neighbors) do 
			
			local alt=dist_to_start[u]+1
			
			if alt < dist_to_start[v] then
				dist_to_start[v]=alt
				prev[v]=u
			end
		
		end
	
	end
	return {}
end

function player_adjacent_to(me)
	return (me.x == player.x and abs(player.y-me.y) < 2) 
			or (me.y == player.y and abs(player.x-me.x) < 2)
end
--[[ for empty, turn, run and draw methods ]]
function empty_fun() 
	return
end
-->8
sprflag={
	wall=0,
	player=1,
	enemy=2
}

resflag={
	swords=1,
	wands=2,
	cups=3,
	pentacles=4
}

etype={
	player=0,
	friend=1,
	enemy=2
}

flashpal={
	0,
	7,
	7,
	7,
	7,
	7,
	7,
	7,
	7,
	7,
	7,
	7,
	7,
	7,
	7,
	7
}
--[[
	
]]
-->8
--title and credits
function _init()
	_update=start_update
	_draw=start_draw
end

function start_update()
	if (btn(5)) game_init()
end

function start_draw()
	cls(0)
	
	--title
	super_print("tar0gue",get_center_x("targgue"),16,1,7)
	
	--controls
	super_print([[⬅️➡️⬆️⬇️:
move character /
move target
									
x/❎:
target ability / 
fire ability

z/🅾️:
change abilities /
cancel targeting]], 
							get_center_x("cancel targeting")
							,32,1,7)
							
	super_print("press x/❎ to start",get_center_x("press x/❎ to start"),112,1,7)

end

function super_print(str,x,y,c1,c2)
	
	for mx=-1,1 do
		for my=-1,1 do
			print(str,x+mx,y+my,c1)
		end
	end
	
	print(str,x,y,c2)
	
end

function get_center_x(str)
 return (127-#str*4)/2
end
__gfx__
00000000000880000000bb00000033b3000bb000000880000b330bb00000dddd0000000000000000000000000000000000000000dd000000dddddddd00000000
00000000000dd800030bfb00000bb03000bfb000000dd8000000bffb000880d00000000000000000000000000000000000000000dd0d00000000000d00000000
000000000d0ff8d00300ffb030bfbb00300ff0300d0ff8d0b3ffdff3d08d88000000000000000000000000000000000000000000dd0d0d00d000000d00000000
0000000000d8fd003b3fddf030bffbb0300ddd3000d8fd0000000ddbd08ff8800000000000000000000000000000000000000000dd0d0d0dd0d0000d00000000
00000000008dde000300dd30b30ddd30b00fffbf008dde0000b33ffddd0eeef00000000000000000000000000000000000000000dd0d0d0dd0d0d00d00000000
00000000080ff000000dd3b330fff3b30000dd00080ff0000000ddd0d0ffdddf0000000000000000000000000000000000000000110d0d0dd0d0100d00000000
00000000000eee00000d0d300003dd30000d00d0000eee00000d00d0000deed0000000000000000000000000000000000000000011110d0dd010101d00000000
0000000000eeeee0000d00d0033b30d000b30b3000eeeee000d00d000ddddeee00000000000000000000000000000000000000001111110d1010101d00000000
0077704000000066000060065556565500666500000bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000
006f604400000656000000655566666506656650000ff30000000000000000000000000000000000000000000000000000000000000000000000000000000000
01ff1040000065600060065055666565665556650b0ff3f000000000000000000000000000000000000000000000000000000000000000000000000000000000
dd14014000065600000065000556565065565565003dfb0000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ff0df400565600000065006005565006655566500fddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000
044d104000560000006500000005500066565665030dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000
010d104005050000065000000005600006666650000ded0000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010d1405000000065000000055556600055550000ddedd000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b3b3000000300000000000000000000000000000000000000440700009900c0000000000000000000000000000000000000000000000000000000000000000
030b30b00003b030000000000000000000000000000000000099a070099440060000000000000000000000000000000000000000000000000000000000000000
b0333b3b030bb30000000000000000000000000000000000004ff070909440040000000000000000000000000000000000000000000000000000000000000000
3b3b3333303b3b030000000000000000000000000000000008bf8070008668460000000000000000000000000000000000000000000000000000000000000000
3333b33b00b3b33000000000000000000000000000000000468bb555004868060000000000000000000000000000000000000000000000000000000000000000
b0b33b03003b3b000000000000000000000000000000000060688080040880000000000000000000000000000000000000000000000000000000000000000000
0b0330b0030030300000000000000000000000000000000000808050088668000000000000000000000000000000000000000000000000000000000000000000
0033b300000300000000000000000000000000000000000008808800806068000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000011a99a11000111100001111000000000000000000000000000000000000000000000000000000000000000000766650007666500
0000000000000000000000001999aa90001000010017777100000000000000000000000000000000000000000000000000000000000000007686865076ccc650
000000000000000000000000199a00a0010070710177070100000000000000000000000000000000000000000000000000000000000000007668665076c6c650
00000000000000000000000009a0ff90010000010177777100000000000000000000000000000000000000000000000000000000000000007686865076ccc650
0000000000000000000000009a900009100000101777771000000000000000000000000000000000000000000000000000000000000000000766650007666500
00000000000000000000000056655665100000101777771000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000066665566010010017177177100000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000056655665001001017717717100000000000000000000000000000000000000000000000000000000000000000000000000000000
0ddddd0dd0dddd0dd0ddddd0dddddddddddddddddddddddddddddddddddddddd000000000000000000d0d0d002d0000000000000000000000000000000000000
d00000d00d0000d00d00000d0d0000d00d0000d00d0000d0dd0000dd0d0000d0000000000000000000d0d0d02d8d000000000000000000000000000000000000
d00dd000000dd000000dd00dd000000dd000000dd0d22d0dd000000d000dd0000000000000000000002020202d8d00000dddddd0000000000000000000200000
d0000000000000dd0000000dd000000dd000000dd002200d00000000000200dd0000000000000000002d2d2d2d8d0000d888888d000000000000000000020020
ddd00dd000dd00000dd00dddd000000dd008000dd002200d0000000000d82000000228f00ddddd200d20202d2d8d00000dddddd0000000000000000000002000
d0000000d000000d0000000dd0dddd0dd0d22d0dd002200d00000000d200200d0ff8222200ddd2000d20202d22d82000d0d0000d000080000000000002000000
0d0dd000000dd000000dd0d0d0dddd0dd0d2dd0dd000200d00000000020d800000222000000d2000d02020d0222d82000d0d00d0022828200000000000020220
d00000000d0000d00000000d0d0dd0d00d0dd0d00d0000d0000000002d0202d00000000000ddd200dddddd0d2222dddd00d00d00000220000222022000000000
d0dd0dd0d0dddd0d0dd0dd0d0d0000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d00000000d0000d00000000dd00dd00d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d00dd00000dd00000dd00d0d000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0000000000000dd0000000dddd0dd0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0dd0dd000dd00000dd0dd0dd000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0000000d000000d0000000dd00dd00d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d0dd000000dd000000dd0d00d0000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d00000000d0000d00000000dd000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3ddddddddd3ddddddd3ddddddd0dd0dddddddddddddddd3ddd00000d0000000ddd00000000000000000000000000000000030000000000000000000000000000
3d0d030d0d3d0d3d0d3d0d3d000000000d0d0d0d0d0d03d0d0d000dd000000ddd0d000000000000000000000000000000003e000003000000000030000000000
03d000300030033000300030ddd0dd0d0000000000d03d00dd000d0d00000d0ddd00000000000000000000000000000000e3300003e3000000003f3000000000
03d000300300ed030300e00300000000030003000ed03d00d00000dd000000ddd000000000000000000000000000000000333300003000000000000003300000
03d3030000303d3000303030d0ddd0dd3f30333003d30d30dd00000d0000000ddd00000000000000000000000000000000333e00000000000300000000000000
3d3ddd3dd3ddd3ddd3ddd3dd00000000dddddddddd3dddd3d0d000dd000000ddd0d000000000000000000000000000000dddddd0000000300033000000000333
0330d0d0d0d0d3d0d0d0d3d0dd0ddd0dd0d0d0d00d30d0d3dd000d0d00000d0ddd0000000000000000000000000000000d0dd0d0000003e30300300000330000
dddddddddddddddddddddddd00000000ddddddddddddddddd00000dd000000ddd0000000000000000000000000000000d0d00d0d000000300000000003003000
3ddddddddd3ddddddddddddddddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d0d030d0d3d03d00d0d0d3d0d0d0d0d0d0d0d0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300003000303d000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300003000030d000033300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030003000d300333f30330303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d3ddd3ddd3ddddd3ddd3ddddddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0330d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dd00000d0d0d0dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0d0d0d00000dd
d000d000d0d0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0d0d000d000d
d00d0d000d0dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0d000d0d00d
d0d0d0d0d0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0d0d0d0d0d
d00d0d000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000d0d00d
d000d000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000d000d
dd00000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d00000dd
d0d0d0d0000000000000000000000000000000000000bbbb000bbb0000000000000000000000000000000000000000000000000000000000000000000d0d0d0d
dd0d0d0000000000000000000000000000000000000bbbb00000000bbbb000000000000000000000000000000000000000000000000000000000000000d0d0dd
d0d0d000000000000000000000000000000000000b0000000bb000bbbb00000000000000000000000000000000000000000000000000000000000000000d0d0d
dd0d0000000000000000000000000000000bbb00bb0bbb00bbbb00b0000000000000000000000000000000000000000d0000000000000000000000000000d0dd
d0dd000000000000000000000000000000bbb00bb00bb000000000000000000000000000000000000000000000000dd00000000000000000000000000000dd0d
dd0d000000000000000000000000000000b000bb00bb0000000000000000000000000d00000000000000000000dddd000000000000000000000000000000d0dd
dd0d0000000000000000000000000000b000b000000000000000000000000000000000ddd000000000000000ddddd0000000000000000000000000000000d0dd
dd0d00000000000000000000000000bbb00bb00000b00000000000d0000000000000000ddddd000000000dddddddd000000000000d000000000000000000d0dd
dd0d0000000000000000000000000bbb00bbb00000b000000000000dd000000000000000ddddddddddddddddeeeddd000000000dd0000000000000000000d0dd
dd0d000000000000000000000bbb0b000bbb00000bb0000000000000dd000000000000ddddddddddddddddeeeeeeedddd000ddd000000000000000000000d0dd
dd0d00000000000000000000bbb0000b00000000bbb00000000000000ddd000000000dddddeeeeeeeddeeeeeeeeeedddddddddd000000000000000000000d0dd
dd0d00000000000000000000bb00000bbb00000bb00000000000000000dddddddddddddddeeeeeeeeeeeeeeeeeeeeeedddddd00000000000000000000000d0dd
dd0d00000000000000000bb000000000bbb0000000000000000000000000dddddddddeeeeeeeeeeeeeeeeeeeeeeeeeeedddd00000000d000000000000000d0dd
dd0d000000000000000bbb000000000000b0000bb00000000000000000000ddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedddddd000dd0000000000000000d0dd
dd0d000000000000b0bbb000b0000000b00000bb00000000000000000000ddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeddddddddd00000000000000000d0dd
dd0d000000000bbbb0b000bbb00b0000bb000bbb0000000000000000000ddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedddd0dd0000000000000000000d0dd
dd0d00000000bbbb00000bbb00bbb000bbb0bbb0000000000000d00000ddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeddd000000000000000000000000d0dd
dd0d00000000bb0000000000000bbb000bb000000000000000000ddddddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeddd0000000000000000000000000d0dd
dd0d00000000b00bbbb0b00000000b0b00000000000000000000000ddd0ddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedd0000000000000000000000000d0dd
dd0d000000b000bbbb000bb00000000b0bbb00000000000000000000000dddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedddd00000000000000000000000d0dd
dd0d00000bbb0bb0000000bb000000bb00bbbb000000000000000000000ddddeeeeeeeeeeeeeee0e0e0e0e0eeeeeeeeeeeddddd000000000000000000000d0dd
dd0d00000bb00000000000bb000000bb000bbb00000000000000000000ddddeeeeeeeeeeeeeee0d0d0d0d0d0eeeeeeeeeeeddddd00000000000000000000d0dd
dd0d0000000000000000000b00b0000b00000b00000000000000000000dddeeeeeeeeeeeeeeee0ddddddddd0eeeeeeeeeeddddddddd00000000000000000d0dd
dd0d00000000000000000b000bb000000b00000000000000000000000dddddeeeeeeeeeeeeeee0ddddddddd0eeeeeeeeeddddd00dd000000000000000000d0dd
dd0d0000000000000000bb00bb0000000bbb000000000000000000000ddddddeeeeeeeeeeeeee0dd0d0d0dd0eeeeeeeeeedd000000000000000000000000d0dd
dd0d000000000000000bbb0bb000000000bbb0000000000000000000dd0d0dddeeeeeeeeeeee0ddd00d00dd0eeeeeeeeeeedd0000000d000000000000000d0dd
dd0d00000000000000bbb00000000000000bb000000000000000000d000000ddddeeeeeeeeee0dddd0000dd0eeeeeeeeeeddd0000ddd0000000000000000d0dd
dd0d000000000000bbbb000000000000b000b00000000000000000000000000ddddeeeeeeeee0ddddddd00d00eeeeeeeedddddd0ddd00000000000000000d0dd
dd0d0000000000000000000000b00000bb000000000000000000000000000000dddddddeeeee0d00000dddddd0eeedeeddd0000ddd000000000000000000d0dd
dd0d000000000000b00b00000bb00000bbb000000000000000000000000dd000dddddddddee0dd0d0d0d0dddd0dddddddd00000dd0000000000000000000d0dd
dd0d00000000b00bb0bb0000bb0000000bb000000000000000e000000000dd00ddddddddddd0ddd0d0d0d00ddd0dd0dddd0000dd000000000e0000000000d0dd
dd0d000000bbb0bbb0b00000000000e000000000000000000000000000000dddd00dd00ddd00dd000000000ddd000000dd0000d000000000000000000000d0dd
dd0d00000bbb00bb000000b00000ee00bbb000000000000000e0000000000dd00000dd000d0d0dd00000000ddd000000dd000d0000000000000000000000d0dd
dd0d000000000bb0000e0bb0000ee00bbb0000000000000000000000000000dd00000d00000dddddd0000000dd00000ddd00000000000000e00000000000d0dd
dd0d00000bbb000000e00b0000ee00bb00bb00000000000000000000000000dd0000ddd000ddddddddd00000dd0dddddddd0000000000000000000000000d0dd
dd0d0000bbbbb0000ee0000e0ee000bb0bb00000000000000e0e00000000000d000dddddd0ddd0dd0dddd000ddddd000dddd000000000000000000000000d0dd
dd0d0000bb000000ee000000e0000bb0bb000e000000000000e000000000000000000000d0dd0d0ddd0dddd0dd00000000dd00000000000e000000000000d0dd
dd0d000000000eeeeeeee0e000bb000000000000000000000e00000000000000000000000dd0d0d000dd0ddddd0000000000000000000000000000000000d0dd
dd0d000000eeeee00eee0e000bbb0bbbb0000000000000000000000000000000000000000d0d0d0d0d00dd0dddd000000000000000000000e00000000000d0dd
dd0d00000ee0000000000000bbb0b0bb0000e0000000000000e000000000000000000d000dd0d0d0d0d000dd0ddd00000000000000000000000000000000d0dd
dd0d00000000000000bb0000000000000000000000000000000000000000000000000d000dd0000d0d0d0000dd0dddd00000000000000000e00000000000d0dd
dd0d0000000000b0000000bbb00bb00000000e000000000000000000000000000000dddddd000000000ddd0d00dddd000000000000000000000000000000d0dd
dd0d0000e000bbb00000000b00bb0000000000000000000000e000000000000000000dddddddd0000000d00d00ddd000000000000000000e0e0000000000d0dd
dd0d0000e000b0000bb0bb000bb00000000000000000000000ee00000000000000000dddddddddddd0000000dd0dd000000000000000000e0e0000000000d0dd
dd0d0000ee000000bb0b0bb00000000000000e00000000000000000000000000000000ddddd0dddddddddd000000d0000000000000000000e00000000000d0dd
dd0d0000ee000000b0bb0000000000000000e0e0000000000ee0000000000000000000dd0dd00ddddddddddddd00d0000000000000000000000000000000d0dd
dd0d0000e00e0bbb000b000000000000000000000000000000e00000000000000000000d0dd00ddd0ddddddddddddddd0000000000000000e00000000000d0dd
dd0d0000e00ee0bbb0000000000000000000e0e00000000000000000000000000000000d0d000dd00ddd00ddddddddddd00000000000000e0e0000000000d0dd
dd0d000000ee000000000e000000000000000e00000000000eee000000000000000000dd0d0d0dd00ddd00ddddddddddd000000000000000e00000000000d0dd
dd0d000000e000000000ee000e0000000000e0e00000000000000000000000000ddddddd000d0d000dd000ddd0ddddddd0ddddd000000000000000000000d0dd
dd0d0000e00000000000ee000e000000000000000000000000e000000000000000d0d0dd00d00d0d0dd000ddd00dddddd00d0d0000000000e000e0000000d0dd
dd0d0000e00000000000eee0ee00000000000e00000000000e0e00000000000000d0d0d0d00d000d0dd000dd000dddddd00d0d00000000000000e0000000d0dd
dd0d0000e0000000000eeeeeee0000000000eee00000000000e000000000000000d0d0d0d0d0d0d00d00d0dd0d00dddddd0d0d000000000eee00e0000000d0dd
dd0d0000ee000000000eeeeeee00000e00000e0000e000000000000000000000ddddddddd00d0d0d0d00d0dd0d00dd0ddd0d0d0000000000e000ee000000d0dd
dd0d0000ee0000000eeeeeeeee00000e0000000000e000e00eee0000000000000d0d0d0dddd000d0d000d0dd00d0dd0ddddd0dd000000000000eee000000d0dd
dd0d0000e0000000eeeeeeeeeee0000ee000eee000ee00e000e0000000000000d0d0d0d0ddddd0000d0d00d00d00dd0ddddd0d0d00000000e0eeee000000d0dd
dd0d0000e0000000eeeeeeeeeee0000eee0000000eeee0e00000000000000000d0d0d0d0ddddddd000d0d0d000d0d000dd0ddd0d0000000e00eeee000000d0dd
dd0d0000e000e00eeeeeeeeeeee000eeeee0e0e00eeeeee000000000000000d0d0d0d00d0d0dddddd000000d0d00d0d0ddd00dd0d0000000e0eeeee00000d0dd
dd0d0000000ee00eeeeeeeeeeeee00eeeee00e00eeeeeeee0000e000000000d0d0d000d0d0d00dddddd00000d0d0d00d0dddd00ddd00e00000eeeee00000d0dd
dd0d00000e0ee0eeeeeeeeeeeeee00eeeeee0000eeeeeeee0000e000000000d0d0d00d0d000d00d0ddddddd0000000d0d0ddddd000d00ee000eeeee00000d0dd
dd0d0000ee0eeeeeeeeeeeeeeeee0eeeeeee000eeeeeeeee0000ee000000d0ddd000d0dddd0d0d0dd0ddddddddd0000d0d0d0d0d0d0d00ee0eeeeeee0000d0dd
dd0d0000ee0eeeeeee0eeeeeeeee0eeeeeee000eeeeeeeee000eee000dd0d0d0d0dd000d00d0d0dd0d0dddddddddddd0d0d0d000d000d00e0eeee0ee0000d0dd
dd0d0000ee0eeeeeee0eeeeeeeeeeeeeeeee000eeeeeeeeee0eeeee000d0dd0d0d00dddd0d0d0d00d0d0d0d0dddddddddddddddddddd0d0eeeee00ee0000d0dd
dd0d0000ee0eeeeee000eeeeeeeeeeeeeeee00eeeee0eeeeeeeeeeee00d0d0d0d0000d0d0d00d0000d00d0d0d000ddddd0d0d0d0d0d0000eeeee00ee0000d0dd
dd0d0000e00eeeee00e00eee0eeeeeeeeeeee0eeee00eeeeeeee0e0000dd0ddd0ddddddd0d00d0000d00d0d0d000000d0d0d0d0d0d00000eeeee000e0000d0dd
dd0d0000e00eeeee0e0e0ee00eeeeeeeeeeee0eeee000eeeeeee000000d0d0dd00d0000d0d0d0d00d0d0d0d0d0d0d000000d0d0dd0000e0eeee0000e0000d0dd
dd0d0000ee00eee000e0000000eeeeeeeeeeeeeee0000eeeeee000000ddd0dddddddd00d0d00d0dd0d00d0d00dd0dd000000ddddd00eeeeeeee0000e0000d0dd
dd0d0000ee00ee000000000000eeeeee0eeeeeeee00000eeeee000000ddddd00d00d000d00d00dd0d00d00d00dd0dd0000000d0d0d00eee0eee00e000000d0dd
dd0d0000ee000e0000e00000000eeee00eeeeeeee0eee0eeee00ddddddddddddddddddd0000d000d00d000d00ddddd0dd000d0dddd00e0000e00e0e00000d0dd
dd0d0000ee0000000e0e00000000ee0000eeeeee000e000ee000d000d0d00000d000d0dd0000d0d0dd0000d0dddd0ddddd000d0ddd0000dd00000e000000d0dd
dd0d0000ee0000000000000d0000000000eeeeee00000000000d0d0d0d0ddddd0ddd0d0d0dddddddddd0d00dd0dd00dd0d0dddddddd0dd0dd00000000000d0dd
dd0d0000ee0000000eee00ddd000000000eeeee000eee000000d0dddddd00000d000d0d00000dd0dd00000dd000d00d00d0d00d000ddd000d000eee00000d0dd
dd0d0000eee0000000000dddddd00000000ee000000d000000dd0dddddddddddddddddd00d00000000000d00000d00000ddd0000000ddd00ddd000000000d0dd
dd0d0000eee0000000e0dddddddd00000000000000ddd0000dd0d0dddd000d00dddd0dd00dd000dd0000dd00000000000dd00000000dddd0dddd0e000000d0dd
dd0d0000eeee000000ddddd00dddddd0000000000dd0dd000d0d0dddd000dd00d0000dd0d0dd0dddd00dd0d0000000000d0000000000ddddd00d00e00000d0dd
dd0d00000eee0000ddddd00000ddddddd000000dddd00ddd0ddddddd00000ddd000000000dd0dd00ddd0dd000000000dd00000000000ddddd00dd0000000d0dd
dd0d00000eeeedddddd000000ddddddddddd0dddd00000ddd0ddddd0000000dd0d000000dd0dd0000ddd0dd00ddddddd0dd0000000000ddddd00d0000000d0dd
dd0d000000eeddddd00000000dddddddd00dddd000000000dddddd000000000ddddd00000ddd00dd000ddd00dd0d00d0d00d000000000dddddd0d0e00000d0dd
dd0d0000000eedd000000000ddddddd000dddd00000000000ddddd00000000000ddd0000dddddd00dddddddddd000000000000d0000d00ddddddd0000000d0dd
dd0d0000000eed0000000000000ddd000dddd000000000000dddd00000000000000dddd0ddd0d0dd0d0ddddd00000000000000000000000dddddd0000000d0dd
dd0d0000000eee0000000000000ddddddddd000000000000dddd00d0000000000000d0dddddd0d00d0ddddd000000000000000d00d0d000ddddddd000000d0dd
dd0d00000000ee000000000000ddd00dddd000000000000ddddd00d0d00000000000000dddd0d0ee0d0ddd00000000000dd0d000dd000d0dd00d00000000d0dd
dd0d0000e000ee000000000000000000dd00000000000dddddd000d0d000d00000d0000000d000ee00dd000000000d00ddddd0d0dd0d0ddd0000d0d00000d0dd
dd0d0000ee000ee00000000000000000000000000000ddddddddd0d0d0d0d000d0d00d000000d0ee0d000000d00d0dddddddddddddddddd00ddddd000000d0dd
dd0d0000ee000ee000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd00000000d0dd
dd0d00000ee000eeddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd00000bb0000d0dd
dd0d00000e0e000ed000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbb0000d0dd
dd0d00000ee0e00eeeddddddd00dd0dddd0dd0000d00d0dd0ddddddddddddddddddddddddddddddddddddddddddddddddddddddd0ddd0d0d00000bb00000d0dd
dd0d00000ee0ee00eeed000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0000d0dd
dd0d000000e00ee00eeddddddddddd0dd0d000000000000d00d0ddd0d0ddddddddddddddddddddddddddddddddddddddd0dd0dd00000000000000bb00000d0dd
dd0d000000e0000000eedd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb0000d0dd
dd0d0000000e0000000eeddddddddddddd0000000000000000000000000000700d0d00dddddddddddddddd0d0d0000000000000000000000000bb00b0000d0dd
dd0d0000000e0000000eeed000000000000000000000000000000000000077670000040000000000000000000000000000000000000000000bbb00000000d0dd
dd0d0000b000e0b0b000eeddddddd0d0000000000000000000000000000066f070004400dd0d0ddddddddddd000000000000000000000000bbbbb0000000d0dd
dd0d0000b000eebbb0b0eeed00000000000000000000000000000000000011f000004000000000000000000000000000000000000000000bb00000b00000d0dd
dd0d0000b0b00e0bbbb0b00bdbdd00000000000000000000000000000001111100004000000000d0ddddddddddddddd0dd000000000000000000bb000000d0dd
dd0d0000bbb0b0b0bbbbb0bbbb0b0b000000000000000000000000000004111100040000000000000000000000000000000000000000000b000bbbbb0000d0dd
dd0d0000bb0bbbb0b0bbbbbbbbbbbb0b0b000000000000000000000000114111110400000000000000ddddddddddddd00000000000000bb0000bb0000000d0dd
dd0d0000b00b0b0b000bbbbbbbbbbbbb0b0b00000000000000000000001d40101dd40000000000000000000000000000000000000000bbbbb0b000000000d0dd
dd0d0000b0b00bbbb0b0b0bbbbbbbbbbbbbb0b000000000000000000000d04010dff00000000000d0ddddddddddddddd0d000000000bbbbb0000000b0000d0dd
dd0d0000bbbb0b0bbbbb0b000b0b0bb0bbbb0b000000000000000000000f11410004000000000000000000000000000000000000000bbb00000b0b0b0000d0dd
dd0d0000b0b0b00b0bbbbb0b000b00b00b0bbbb00000000000000000000f110440040000000000000ddddddddddddd0000000000000bb000000bbbbb0000d0dd
dd0d0000b0b000000b0bbbbb0b000b00000b0bbb0000000000000000000310149004006060000000000000000000000000000000000b0000b0bbbbbb0000d0dd
dd0d0000000000b0000b0bbbbbb0000b0b0000bbb0b0b00000000000073110144040005660000000000dddd0000000000000000000000000bbbbbb0b0000d0dd
dd0d00000000b0b000000b0bbbb0b000bb00000b0bbbb0b0000000007a711014404000556600000000000000000000000000000000000b0bbbbb0b000000d0dd
dd0d0000000bbbbb0b00000b0b0bbb0000b0b0000b0bbbb0b00b0b00070101110040000600000000d0dddd000000000000000000000b0b0bbbbb00000000d0dd
dd0d000000bb0bbbbb000000000b0bb0b000b0b0000b0bbbb0bbbb0b000101110040605560000000000000000000000000000000b0bbbbbbbb0b00b00000d0dd
d0dd0000b00b0b0bbbbb0b00bb000b0bb0b000bb000000bbbbbbbbbbb0b101010400605660000000dddd000000000000000000b0bbbb0bbb0b0000bb0000dd0d
dd0d00000000000b0bbbbb0b000b000bbbb0b000b0b0b000b0b0b0bbbbb0b0110400656660000000000000000000000000b0b0bbbb0b00b00000bbb00000d0dd
d0d0d0000000000000bbbbbb0000000b0bbbb0b000000bb00000b00b0bbbbb0b040006566600d0dddddddd0d0000000000b0bbbb00000000000bbb00000d0d0d
dd0d0d000000000000b0b0bbb0bb00000b0b0bbb0b000000bb00000b0b0b0bbb0b0b0b5b5b000000000000000000000b0bbbb0b00000000b00bb000000d0d0dd
d0d0d0d0000000000000000b0bb0bb00000b00b0b0b00b00000bbb00000000b0b0bbbbbbbbbbb0000000000000000bbbbb00000000000b0b0b0000000d0d0d0d
dd00000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d00000dd
d000d000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000d000d
d00d0d000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000d0d00d
d0d0d0d0d0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0d0d0d0d0d
d00d0d000d0dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0d000d0d00d
d000d000d0d0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0d0d000d000d
dd00000d0d0d0dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0d0d0d00000dd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__gff__
0004040404040404000004000002000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010100010101010100000000010101010101010101010101000000000101010101010101010101010000000001010101010101010101010100000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4041414141414141414141414141414200000000000000000000004041414141414141414141414141414200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
530d00000000000200000000000000530000000000000000000000530d000000000002000000000000005300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5300000000050000000000000000005300000000000000000000005300000000050000000000000000005300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5351515151515151515151420000005300000000000000000000005351515151515151515151420000005300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5300000000000000000000530000005300000000000000000000005300000000000000000000530000005300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5300000253020000005300000000005300000000000000000000005300000253020000005300000000005300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5300000550514200005300404200405200000000000000000000005300000550514200005300404200405200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5300000000000000055300530000005300000000000000000000005300000000000000055300530000005300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5300004042020000000000530000005300000000000000000000005300004042020000000000530000005300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5300005052000051515100530000005300000000000000000000005300005052000051515100530000005300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5300000000050000000002530500055300000000000000000000005300000000050000000002530500055300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5300000500405151515151515151515300000000000000000000005300000500405151515151515151515300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5300000000000000020000000000005300000000000000000000005300000000000000020000000000005300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
53000002000000000500000000000e53000000000000000000000053000002000000000500000000000e5300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051515151515151515151515151515200000000000000000000005051515151515151515151515151515200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000006363636363636363636363636363636300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000006300000000000000000000000000006300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000006300000000000000000000000000006300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000006300000000000000000000000000006300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000006300000000000000000063636300006300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000006300000000630000000000006300006300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000006300000000630000000000000000006300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000006300000000000000000000000000006300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000630000630000000d000000000000006300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000006300000063000000000000630000006300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000006300000000630000000063630000006300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000006300000000000063000000000000006300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000006300000000000000000000000000006300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000012650116500f6500e6400d6300b6300b62009620076200462003610026100161001610006100061000610025000150001500015000150001500015000150000500005000050000500005000050000500
00010000016500365006650096500b65012650186501e6502365026650286502460026600286002a6000c6000e6000f600126001260015600186001a6001c6001f6002160026600286002c6002e6003060031600
