local S = technic.getter
autofarmer = {}
autofarmer.range = 3
local modpath = minetest.get_modpath("autofarmer")
dofile(modpath .. "/running.lua")

local tube_entry = "^pipeworks_tube_connection_wooden.png"

function autofarmer.allow_metadata_inventory_put(pos, listname, index, stack, player)
  if minetest.get_item_group(stack:get_name(), "seed") == 1 and listname == 'input' then
    return stack:get_count()
  end
  minetest.chat_send_player(player:get_player_name(), S("Seedbox is for seeds only"))
  return 0
end

function autofarmer.allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
  if from_list == 'output' and to_list == 'input' then
    local stack = minetest.get_meta(pos):get_inventory():get_stack(from_list, from_index)
    if minetest.get_item_group(stack:get_name(), "seed") == 1 then
      return count
    else
      minetest.chat_send_player(player:get_player_name(), S("Seedbox is for seeds only"))
      return 0
    end
  end
  return count
end


local function onConstruct(pos, tier)
  local meta = minetest.get_meta(pos)
  meta:set_string("infotext", S("%s Farmer"):format(tier))
  meta:set_string("formspec", "size[8,9]" ..
    "label[0,0;Seedbox]" ..
    "list[context;input;0,0.5;8,1]" ..
    "label[0,1.5;Harvest]" ..
    "list[context;output;0,2;8,2]" ..
    "button[0,4;2,1;btn_start;Disabled]" ..
    "list[current_player;main;0,5;8,4]" ..
    "listring[current_name;output]"..
    "listring[current_player;main]" ..
    "listring[current_name;input]"..
    "listring[current_player;main]"
  )
  meta:set_int("enabled", 0)
  meta:set_int("counter", 0)
  meta:set_string("tier", tier)
  local inv = meta:get_inventory()
  inv:set_size("input", 8)
  inv:set_size("output", 16)
  set_demand(meta)
end

local function afterPlace(pos, placer, itemstack)
  local meta = minetest.get_meta(pos)
  local node = minetest.get_node(pos)
  meta:set_string("owner", placer:get_player_name())
  pipeworks.scan_for_tube_objects(pos)
  meta:set_string('farm_area', minetest.serialize( getArea(minetest.facedir_to_dir(node.param2), pos, meta:get_string("tier"))))
end

local function canDig(pos,player)
  local meta = minetest.get_meta(pos);
  local inv = meta:get_inventory()
  return inv:is_empty("input") and inv:is_empty("output")
end

local function receiveFields(pos, formname, fields, sender)
  if fields.btn_start then        
    local meta = minetest.get_meta(pos)
    local formspec = meta:get_string("formspec")        
    if meta:get_int("enabled") == 1 then
      meta:set_int("enabled", 0)
      formspec = formspec.."button[0,4;2,1;btn_start;"..S("Disabled").."]"
    else
      meta:set_int("enabled", 1)
      formspec = formspec.."button[0,4;2,1;btn_start;"..S("Enabled").."]"
    end        
    meta:set_string("formspec", formspec)
    set_demand(meta)
  end
end

minetest.register_node("autofarmer:hv_farmer",
{
  description = "HV Farmer",
    tiles = {
      "default_stone_brick.png"..tube_entry, --top
      "default_stone_brick.png^technic_cable_connection_overlay.png", --bottom
      "default_stone_brick.png", --left
      "default_stone_brick.png", --right
      "default_stone_brick.png", --back 
      "default_stone_brick.png^farming_tool_steelhoe.png"
    },    
    groups = {cracky = 1, tubedevice = 1, technic_machine=1, technic_hv=1},
    paramtype2 = "facedir",
    connect_sides = {"bottom"},
    tube = {
      insert_object = function(pos, node, stack, direction)
        return ItemStack("")
      end,
      can_insert = function(pos, node, stack, direction)
      end,
      connect_sides = {top = 1},
      priority = 1,
    },
    on_construct = function(pos)
      onConstruct(pos, "HV")
    end,    
    after_place_node =afterPlace,
    can_dig = canDig,
    after_dig_node = pipeworks.scan_for_tube_objects,
    on_receive_fields = receiveFields,
    allow_metadata_inventory_put = autofarmer.allow_metadata_inventory_put,
    allow_metadata_inventory_move = autofarmer.allow_metadata_inventory_move,
    technic_run = farmer_run
})

minetest.register_node("autofarmer:mv_farmer",
{
  description = "MV Farmer",
    tiles = {
      "default_cobble.png"..tube_entry, --top
      "default_cobble.png^technic_cable_connection_overlay.png", --bottom
      "default_cobble.png", --left
      "default_cobble.png", --right
      "default_cobble.png", --back 
      "default_cobble.png^farming_tool_stonehoe.png"
      },
    groups = {cracky = 1, tubedevice = 1, technic_machine=1, technic_mv=1},
    paramtype2 = "facedir",
    connect_sides = {"bottom"},
    tube = {
      insert_object = function(pos, node, stack, direction)
        return ItemStack("")
      end,
      can_insert = function(pos, node, stack, direction)
      end,
      connect_sides = {top = 1},
      priority = 1,
    },
    on_construct = function(pos)
      onConstruct(pos, "MV")
    end,    
    after_place_node =afterPlace,
    can_dig = canDig,
    after_dig_node = pipeworks.scan_for_tube_objects,
    on_receive_fields = receiveFields,
    allow_metadata_inventory_put = autofarmer.allow_metadata_inventory_put,
    allow_metadata_inventory_move = autofarmer.allow_metadata_inventory_move,
    technic_run = farmer_run    
})

minetest.register_node("autofarmer:lv_farmer",
{
    description = "LV Farmer",
    tiles = {
      "default_wood.png", --top
      "default_wood.png^technic_cable_connection_overlay.png", --bottom
      "default_wood.png", --left
      "default_wood.png", --right
      "default_wood.png", --back 
      "default_wood.png^farming_tool_woodhoe.png"
      },
    groups = {cracky = 1, tubedevice = 0, technic_machine=1, technic_lv=1},
    paramtype2 = "facedir",
    connect_sides = {"bottom"},
    on_construct = function(pos)
      onConstruct(pos, "LV")
    end,
    after_place_node =afterPlace,
    can_dig = canDig,
    on_receive_fields = receiveFields,
    allow_metadata_inventory_put = autofarmer.allow_metadata_inventory_put,
    allow_metadata_inventory_move = autofarmer.allow_metadata_inventory_move,
    technic_run = farmer_run
})

minetest.register_craft(
{
    type = "shaped",
    output = "autofarmer:lv_farmer",
    recipe = 
    {
      {"group:wood",  "farming:hoe_wood",       "group:wood"},
      {"group:wood",  "technic:machine_casing", "group:wood"},
      {"group:wood",  "technic:lv_cable",       "group:wood"}
    }
})

minetest.register_craft(
{
    type = "shaped",
    output = "autofarmer:mv_farmer",
    recipe = 
    {
      {"default:cobble",  "farming:hoe_stone",      "default:cobble"},
      {"default:cobble",  "technic:machine_casing", "pipeworks:tube_1"},
      {"default:cobble",  "technic:mv_cable",       "default:cobble"}
    }
})

minetest.register_craft(
{
    type = "shaped",
    output = "autofarmer:hv_farmer",
    recipe = 
    {
      {"default:stonebrick",  "farming:hoe_steel",      "default:stonebrick"},
      {"default:stonebrick",  "technic:machine_casing", "pipeworks:tube_1"},
      {"default:stonebrick",  "technic:hv_cable",       "default:stonebrick"}
    }
})

technic.register_machine("LV", "autofarmer:lv_farmer", technic.receiver)
technic.register_machine("MV", "autofarmer:mv_farmer", technic.receiver)
technic.register_machine("HV", "autofarmer:hv_farmer", technic.receiver)
