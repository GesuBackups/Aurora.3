/obj/item/mining_scanner
	name = "deep ore scanner"
	desc = "A complex device used to locate ore deep underground."
	icon = 'icons/obj/item/mining_scanner.dmi'
	icon_state = "manual_mining"
	item_state = "manual_mining"
	contained_sprite = TRUE
	origin_tech = list(TECH_MAGNET = 1, TECH_ENGINEERING = 1)
	matter = list(DEFAULT_WALL_MATERIAL = 150)

/obj/item/mining_scanner/attack_self(mob/user)
	to_chat(user, SPAN_NOTICE("You begin sweeping \the [src] about, scanning for metal deposits."))

	if(!do_after(user, 50))
		return

	var/list/metals = list(
		"surface minerals" = 0,
		"precious metals" = 0,
		"nuclear fuel" = 0,
		"exotic matter" = 0
		)

	for(var/turf/T in range(2, get_turf(user)))
		if(!T.has_resources)
			continue

		for(var/metal in T.resources)
			var/ore_type

			switch(metal)
				if(ORE_SAND, ORE_COAL, ORE_IRON)
					ore_type = "surface minerals"
				if(ORE_GOLD, ORE_SILVER, ORE_DIAMOND)
					ore_type = "precious metals"
				if(ORE_URANIUM)
					ore_type = "nuclear fuel"
				if(ORE_PHORON, ORE_PLATINUM, ORE_HYDROGEN)
					ore_type = "exotic matter"

			if(ore_type)
				metals[ore_type] += T.resources[metal]

	to_chat(user, "[icon2html(src, user)] [SPAN_NOTICE("The scanner beeps and displays a readout:")]")

	for(var/ore_type in metals)
		var/result = "no sign"

		switch(metals[ore_type])
			if(1 to 25)
				result = "trace amounts"
			if(26 to 75)
				result = "significant amounts"
			if(76 to INFINITY)
				result = "huge quantities"

		to_chat(user, SPAN_NOTICE("- [result] of [ore_type]."))
