local lv_demand = 500
local mv_demand = 1500
local hv_demand = 5000

local S = technic.getter

local inject_vector = 
{
  {x=-1, y=0, z=0},
  {x=1, y=0, z=0},
  {x=0, y=1, z=0}
}

local function min_lookup(tier,facedir)  
  local range = 0
  if tier == "LV" then
    range = 3
  elseif tier == "MV" then
    range = 5
  elseif tier == "HV" then
    range = 7
  end
  local range_tmp = math.floor(range/2)
  if facedir.x == -1 and facedir.z == 0 then
    return vector.new(1, 0, -range_tmp)
  elseif facedir.x == 0 then
    local x_val = math.floor(range/2)
    if facedir.z == 1 then
      return vector.new(-range_tmp, 0, -1)
    else
      return vector.new(range_tmp, 0, 1)
    end    
  elseif facedir.x == 1 and facedir.z == 0 then
    return vector.new(-1, 0, range_tmp)    
  end
end

local function max_lookup(tier, facedir)
  local range = 0
  if tier == "LV" then
    range = 3
  elseif tier == "MV" then
    range = 5
  elseif tier == "HV" then
    range = 7
  end
  local range_tmp = math.floor(range/2)
  if facedir.x == -1 and facedir.z == 0 then
    return vector.new(range, 0, range_tmp)
  elseif facedir.x == 0 then
    if facedir.z == -1 then
      return vector.new(-range_tmp, 0, range)
    elseif facedir.z == 1 then
      return vector.new(range_tmp, 0, -range)
    end
  elseif facedir.x == 1 and facedir.z == 0 then
    return vector.new(-range, 0, -range_tmp)
  end
end

function set_demand(meta)
  local tier = meta:get_string("tier")
  local machine_name = S("%s Farmer"):format(tier)
  if meta:get_int("enabled") == 0 then
    meta:set_string("infotext", S("%s Disabled"):format(machine_name))
    meta:set_int(tier .. "_EU_demand", 0)
  else
    if tier == "LV" then
      meta:set_string("infotext", S(meta:get_int("LV_EU_input") >= lv_demand and "%s Active" or "%s Unpowered"):format(machine_name))
      meta:set_int("LV_EU_demand", lv_demand)
    elseif tier == "MV" then
      meta:set_string("infotext", S(meta:get_int("MV_EU_input") >= mv_demand and "%s Active" or "%s Unpowered"):format(machine_name))
      meta:set_int("MV_EU_demand", mv_demand)
    elseif tier == "HV" then
      meta:set_string("infotext", S(meta:get_int("HV_EU_input") >= hv_demand and "%s Active" or "%s Unpowered"):format(machine_name))
      meta:set_int("HV_EU_demand", hv_demand)
    end
  end  
end

function getArea(facepos, pos, tier)
  local min_tmp = vector.add(pos, min_lookup(tier, facepos))
  local max_tmp = vector.add(pos, max_lookup(tier, facepos))
  local minx = math.min(min_tmp.x, max_tmp.x)
  local minz = math.min(min_tmp.z, max_tmp.z)
  local maxx = math.max(min_tmp.x, max_tmp.x)
  local maxz = math.max(min_tmp.z, max_tmp.z)
  local farm_area = {}
  
  for x=minx, maxx do
    for z=minz, maxz do
      table.insert(farm_area, vector.new(x, min_tmp.y, z))
    end
  end
  return farm_area
end

local function getTube(pos_farmer)
  -- Probably not the correct way to test if a tube is connected, but it seems that it is working
  for i=1, #inject_vector do
    local inject_pos_tmp = vector.add(pos_farmer, inject_vector[i])
    local tube_node = minetest.get_node(inject_pos_tmp).name    
    if minetest.get_item_group(tube_node, "tube") == 1 then
      return inject_vector[i]
    end    
  end
  return nil
end

local function farmer_pickup(meta, pos, pos_farmer)
  for _, object in pairs(minetest.get_objects_inside_radius(pos, 1)) do    
    local lua_entity = object:get_luaentity()    
    if not object:is_player() and lua_entity and lua_entity.name == "__builtin:item" then
      if lua_entity.itemstring ~= "" then
        local t = {}
        for str in string.gmatch(lua_entity.itemstring, "([^%s]+)") do
          table.insert(t, str)
        end
        if #t > 0 then
          local inv = meta:get_inventory()
          -- Check if the pickup is a seed
          if minetest.get_item_group(t[1], "seed") == 1 then
            local leftover = inv:add_item('input',lua_entity.itemstring)
            -- Check if we have leftover, if yes then try to push the item through a pipe
            if leftover ~= nil and leftover:get_count() > 0 then
              local inject_pos = getTube(pos_farmer)
              -- If we have a tube, push the seed through the pipe
              if inject_pos ~= nil then
                pipeworks.tube_inject_item(pos_farmer, pos_farmer,inject_pos, lua_entity.itemstring, meta:get_string("owner"))
              end
            end
            -- Either way, destroy the dropped seed
            object:remove()
          else
            -- We picked up something else. Try to push it through a pipe
            local inject_pos = getTube(pos_farmer)
            if inject_pos ~= nil  then
              -- We found a tube
              pipeworks.tube_inject_item(pos_farmer, pos_farmer,inject_pos, lua_entity.itemstring, meta:get_string("owner"))
              object:remove()
            else
              -- We don't have a tube connected. Try to put it into the inventory
              -- It doesn't matter if there is space in the inventory. Dropped object will be removed
              inv:add_item('output',lua_entity.itemstring)
              object:remove()
            end
          end         
        end
      end      
    end
  end  
end

local function farmer_plant(meta, pos)
  local inv = meta:get_inventory()
  -- If the inventory is empty, do nothing
  if inv:is_empty('input') then
    return
  end
  for i=1, inv:get_size('input') do
    local instack = inv:get_stack('input',i)
    local grp = minetest.get_item_group(instack:get_name(), "seed")        
    -- Check if item belongs to group seed
    if grp == 1 then
      local taken = instack:take_item(1)
      inv:set_stack('input', i, instack)
      local seed_name = taken:get_name()
      seed_name = seed_name:gsub('seed_', '') .. '_1'
      minetest.add_node(pos, {name=seed_name, param2=3})
      minetest.get_node_timer(pos):start(math.random(166, 286))
      break
    end
  end
end

function farmer_run(pos, node)
  local meta = minetest.get_meta(pos)
  local tier = meta:get_string("tier")
  
  if meta:get_int("enabled") == 1 then
    
    if (tier == "LV" and meta:get_int("LV_EU_input") >= lv_demand) or
       (tier == "MV" and meta:get_int("MV_EU_input") >= mv_demand) or
       (tier == "HV" and meta:get_int("HV_EU_input") >= hv_demand) then
      local node = minetest.get_node(pos)
      local frontdir = minetest.facedir_to_dir(node.param2)
      
      local farm_area = {}
      if meta:get_string('farm_area') == "" then
        farm_area = getArea(frontdir, pos, tier)    
        meta:set_string('farm_area', minetest.serialize(farm_area))
      else
        farm_area = minetest.deserialize(meta:get_string('farm_area'))
      end
      local cnt = meta:get_int("counter")
      if cnt >= #farm_area then
        cnt = 0
      end  
      cnt = cnt + 1
      local farm_area_below = {x=farm_area[cnt].x, y=farm_area[cnt].y - 1, z=farm_area[cnt].z}
      local node_below = minetest.get_node(farm_area_below)
      local item_grp_soil = minetest.get_item_group(node_below.name, "soil")
      local node_top = minetest.get_node(farm_area[cnt]) 
      farmer_pickup(meta, farm_area[cnt],pos)  
      -- Check if we need to shape the soil or plant new seed? 
      if node_top.name == "air" then
        if item_grp_soil == 1 then
          minetest.set_node(farm_area_below, {name="farming:dry_soil"})
          farmer_plant(meta, farm_area[cnt])
        elseif item_grp_soil > 1 then
			-- The node belongs to farming:soil or farming:soil_wet
			farmer_plant(meta, farm_area[cnt])
        end
      else
        -- If there is a plant which can we harvest, dig, pick up and plant new
        if minetest.get_item_group(node_top.name, 'plant') == 1 then
			if 	(farming.mod == 'redo' and #farming.plant_stages[node_top.name]['stages_left'] == 0) or 
				(farming.mod ~= 'redo' and minetest.registered_nodes[node_top.name].next_plant == nil) then
           		minetest.dig_node(farm_area[cnt])
            	farmer_pickup(meta, farm_area[cnt],pos)
            	farmer_plant(meta, farm_area[cnt])
			end
        end
      end
      meta:set_int("counter", cnt)
    end
  end
  set_demand(meta)
end