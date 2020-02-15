/obj/machinery/mineral/bluespace_miner
	name = "bluespace mining machine"
	desc = "A machine that constantly scans the nearby asteroid feilds for usable material, then uses the magic of Bluespace to teleport it straight to a linked Silo."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "stacker"
	density = TRUE
	circuit = /obj/item/circuitboard/machine/bluespace_miner
	layer = BELOW_OBJ_LAYER
	var/ore_collection_chance = 40
	var/ore_collection_modifier = 0.9
	var/CanCollectRareOre = 0.36
	var/ore_collection_rarechance = 1
	var/list/ore_rates = list(/datum/material/iron = 0.6, /datum/material/glass = 0.6, /datum/material/copper = 0.4, /datum/material/plasma = 0.2,  /datum/material/silver = 0.2, /datum/material/gold = 0.1, /datum/material/titanium = 0.1, /datum/material/uranium = 0.1, /datum/material/diamond = 0.05)
	var/list/rare_ore_rates = list(/datum/material/plasma = 0.3,  /datum/material/silver = 0.3, /datum/material/gold = 0.15, /datum/material/titanium = 0.15, /datum/material/uranium = 0.15, /datum/material/diamond = 0.075, /datum/material/bluespace = 0.05)
	var/datum/component/remote_materials/materials

/obj/machinery/mineral/bluespace_miner/Initialize(mapload)
	. = ..()
	materials = AddComponent(/datum/component/remote_materials, "bsm", mapload)

/obj/machinery/mineral/bluespace_miner/Destroy()
	materials = null
	return ..()

/obj/machinery/mineral/bluespace_miner/multitool_act(mob/living/user, obj/item/multitool/M)
	if(istype(M))
		if(!M.buffer || !istype(M.buffer, /obj/machinery/ore_silo))
			to_chat(user, "<span class='warning'>You need to log the ore silo with the multitool first.</span>")
			return FALSE

/obj/machinery/mineral/bluespace_miner/RefreshParts()
	var/ore_collection_chance_TEMP = 20 // Defaults to 40%, max 90%
	var/ore_collection_modifier_TEMP = 0.4 // Defaults to 67.5%, max 150%
	var/CanCollectRareOre_TEMP = -0.25 // Defaults to .36; Anything above 1 enables rare ore collection
	var/ore_collection_rarechance_TEMP = -8 //defaults to 0, max 20
	for(var/obj/item/stock_parts/matter_bin/B in component_parts)
		ore_collection_chance_TEMP = ore_collection_chance_TEMP + (4 * B.rating)


	for(var/obj/item/stock_parts/manipulator/M in component_parts)
		ore_collection_modifier_TEMP = ore_collection_modifier_TEMP + (0.075 * M.rating)
		CanCollectRareOre_TEMP = CanCollectRareOre_TEMP + (0.12 * M.rating)
		ore_collection_rarechance_TEMP = ore_collection_rarechance_TEMP + (1 * M.rating)

	for(var/obj/item/stock_parts/micro_laser/L in component_parts)
		ore_collection_rarechance_TEMP = ore_collection_rarechance_TEMP + (4 * L.rating)

	for(var/obj/item/stock_parts/scanning_module/S in component_parts)
		ore_collection_chance_TEMP = ore_collection_chance_TEMP + (8 * S.rating)
		ore_collection_modifier_TEMP = ore_collection_modifier_TEMP + (0.05 * S.rating)
		CanCollectRareOre_TEMP = CanCollectRareOre_TEMP + (0.25 * S.rating)

	if(ore_collection_chance_TEMP > 99)
		ore_collection_chance_TEMP = 99
	ore_collection_chance = ore_collection_chance_TEMP
	ore_collection_modifier = ore_collection_modifier_TEMP
	CanCollectRareOre = CanCollectRareOre_TEMP
	ore_collection_rarechance = ore_collection_rarechance_TEMP

/obj/machinery/mineral/bluespace_miner/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += "<span class='notice'>The status display reads: <br>Scanning accuracy: <b>[ore_collection_chance]</b>%.<br>Estimated material reclamation: <b>[ore_collection_modifier*100]%</b>.<span>"
		if(CanCollectRareOre >= 1.0 && ore_collection_rarechance > 0)
			. += "<span class='notice'>The status display estimates that it can process veins more accurately, and process more fragile materials. Accuracy reading at <b>[ore_collection_rarechance]</b>%<span>"
	if(!materials?.silo)
		. += "<span class='notice'>No ore silo connected. Use a multi-tool to link an ore silo to this machine.</span>"
	else if(materials?.on_hold())
		. += "<span class='warning'>Ore silo access is on hold, please contact the quartermaster.</span>"



/obj/machinery/mineral/bluespace_miner/process()
	if(!materials?.silo || materials?.on_hold())
		return
	var/datum/component/material_container/mat_container = materials.mat_container
	if(!mat_container || panel_open || !powered())
		return
	var/datum/material/ore = pick(ore_rates)
	if (rand(0, 100) <= ore_collection_chance)
		if (CanCollectRareOre >= 1)
			if (rand(0,100) <= ore_collection_rarechance)
				ore = pick(rare_ore_rates)
				mat_container.insert_amount_mat(round((rare_ore_rates[ore] * 1000)*ore_collection_modifier, 1), ore)
			else
				mat_container.insert_amount_mat(round((ore_rates[ore] * 1000)*ore_collection_modifier, 1), ore)
		else
			mat_container.insert_amount_mat(round((ore_rates[ore] * 1000)*ore_collection_modifier, 1), ore)