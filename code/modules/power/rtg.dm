// Radioisotope Thermoelectric Generator (RTG)
// Simple power generator that would replace "magic SMES" on various derelicts.

/obj/machinery/power/rtg
	name = "radioisotope thermoelectric generator"
	desc = "A simple nuclear power generator, used in small outposts to reliably provide power for decades."
	icon = 'icons/obj/power.dmi'
	icon_state = "rtg"
	density = TRUE
	anchored = TRUE
	use_power = POWER_USE_OFF

	// You can buckle someone to RTG, then open its panel. Fun stuff.
	can_buckle = list(/mob/living)
	buckle_lying = FALSE
	buckle_require_restraints = TRUE

	var/power_gen = 1000 // Enough to power a single APC. 4000 output with T4 capacitor.

	var/irradiate = TRUE // RTGs irradiate surroundings, but only when panel is open.

	component_types = list(
		/obj/item/stack/cable_coil{amount = 5},
		/obj/item/stock_parts/capacitor,
		/obj/item/stack/material/uranium{amount = 10},
		/obj/item/circuitboard/rtg
	)

	parts_power_mgmt = FALSE

/obj/machinery/power/rtg/upgrade_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "Upgraded <b>capacitors</b> will increase maximum power output."

/obj/machinery/power/rtg/Initialize()
	. = ..()
	connect_to_network()

/obj/machinery/power/rtg/process()
	..()
	add_avail(power_gen)
	if(panel_open && irradiate)
		for (var/mob/living/L in range(2, src))
			L.apply_damage(10, DAMAGE_RADIATION, damage_flags = DAMAGE_FLAG_DISPERSED)	// Weak but noticeable.

/obj/machinery/power/rtg/update_icon()
	icon_state = panel_open ? "[initial(icon_state)]-open" : initial(icon_state)

/obj/machinery/power/rtg/RefreshParts()
	..()
	var/part_level = 0
	for(var/obj/item/stock_parts/SP in component_parts)
		part_level += SP.rating

	power_gen = initial(power_gen) * part_level

/obj/machinery/power/rtg/attackby(obj/item/attacking_item, mob/user, params)
	if(default_part_replacement(user, attacking_item))
		return
	else if(default_deconstruction_screwdriver(user, attacking_item))
		return
	else if(default_deconstruction_crowbar(user, attacking_item))
		return
	return ..()

/obj/machinery/power/rtg/attack_hand(mob/user)
	if(user.a_intent == I_GRAB && user_buckle(user.pulling, user))
		return
	..()

/obj/machinery/power/rtg/advanced
	desc = "An advanced RTG capable of moderating isotope decay, increasing power output but reducing lifetime. It uses phoron-fueled radiation collectors to increase output even further."
	power_gen = 1250 // 2500 on T1, 10000 on T4.

	component_types = list(
		/obj/item/stack/cable_coil{amount = 5},
		/obj/item/stock_parts/capacitor,
		/obj/item/stock_parts/micro_laser,
		/obj/item/stack/material/uranium{amount = 10},
		/obj/item/stack/material/phoron{amount = 5},
		/obj/item/circuitboard/rtg/advanced
	)

/obj/item/circuitboard/rtg
	name = T_BOARD("radioisotope thermoelectric generator")
	build_path = /obj/machinery/power/rtg
	board_type = BOARD_MACHINE
	origin_tech = list(
		TECH_ENGINEERING = 3,
		TECH_DATA = 2,
		TECH_MATERIAL = 4,
		TECH_POWER = 3
	)
	req_components = list(
		"/obj/item/stack/cable_coil" = 5,
		"/obj/item/stock_parts/capacitor" = 1,
		"/obj/item/stack/material/uranium" = 10
	)

/obj/item/circuitboard/rtg/advanced
	name = T_BOARD("advanced radioisotope thermoelectric generator")
	build_path = /obj/machinery/power/rtg/advanced
	origin_tech = list(
		TECH_DATA = 3,
		TECH_MATERIAL = 4,
		TECH_POWER = 3,
		TECH_ENGINEERING = 3,
		TECH_PHORON = 3
	)
	req_components = list(
		"/obj/item/stack/cable_coil" = 5,
		"/obj/item/stock_parts/capacitor" = 1,
		"/obj/item/stock_parts/micro_laser" = 1,
		"/obj/item/stack/material/uranium" = 10,
		"/obj/item/stack/material/phoron" = 5
	)
