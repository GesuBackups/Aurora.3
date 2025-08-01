/* Glass stack types
 * Contains:
 *		Glass sheets
 *		Reinforced glass sheets
 *		Wired glass sheets
 *		Phoron Glass Sheets
 *		Reinforced Phoron Glass Sheets (AKA Holy fuck strong windows)
 *		Glass shards - TODO: Move this into code/game/object/item/weapons
 */

/*
 * Glass sheets
 */
/obj/item/stack/material/glass
	name = "glass"
	singular_name = "glass sheet"
	icon_state = "sheet-glass"
	var/created_window = /obj/structure/window/basic
	var/is_reinforced = 0
	var/list/construction_options = list("One Direction", "Full Window")
	default_type = "glass"
	icon_has_variants = TRUE
	drop_sound = 'sound/items/drop/glass.ogg'
	pickup_sound = 'sound/items/pickup/glass.ogg'

/obj/item/stack/material/glass/mechanics_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "Left-click this item in-hand to view its crafting menu."

/obj/item/stack/material/glass/assembly_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "Combining this item with metal rods will create reinforced glass."

/obj/item/stack/material/glass/attack_self(mob/user as mob)
	construct_window(user)

/obj/item/stack/material/glass/proc/construct_window(mob/user as mob)
	if(!user || !src)	return 0
	if(!istype(user.loc,/turf)) return 0
	if(!user.IsAdvancedToolUser())
		return 0
	var/title = "Sheet-[name]"
	title += " ([src.get_amount()] sheet\s left)"
	switch(input(title, "What would you like to construct?") as null|anything in construction_options)
		if("One Direction")
			if(!src)	return 1
			if(src.loc != user)	return 1

			var/list/directions = new/list(GLOB.cardinals)
			var/i = 0
			for (var/obj/structure/window/win in user.loc)
				i++
				if(i >= 4)
					to_chat(user, SPAN_WARNING("There are too many windows in this location."))
					return 1
				directions-=win.dir
				if(!(win.dir in GLOB.cardinals))
					to_chat(user, SPAN_WARNING("Can't let you do that."))
					return 1

			//Determine the direction. It will first check in the direction the person making the window is facing, if it finds an already made window it will try looking at the next cardinal direction, etc.
			var/dir_to_set = 2
			for(var/direction in list( user.dir, turn(user.dir,90), turn(user.dir,180), turn(user.dir,270) ))
				var/found = 0
				for(var/obj/structure/window/WT in user.loc)
					if(WT.dir == direction)
						found = 1
				if(!found)
					dir_to_set = direction
					break
			new created_window( user.loc, dir_to_set, 1 )
			src.use(1)
		if("Full Window")
			if(!src)	return 1
			if(src.loc != user)	return 1
			if(src.get_amount() < 4)
				to_chat(user, SPAN_WARNING("You need more glass to do that."))
				return 1
			if(locate(/obj/structure/window) in user.loc)
				to_chat(user, SPAN_WARNING("There is a window in the way."))
				return 1
			new created_window( user.loc, SOUTHWEST, 1 )
			src.use(4)
		if("Windoor")
			if(!is_reinforced) return 1


			if(!src || src.loc != user) return 1

			if(isturf(user.loc) && locate(/obj/structure/windoor_assembly/, user.loc))
				to_chat(user, SPAN_WARNING("There is already a windoor assembly in that location."))
				return 1

			if(isturf(user.loc) && locate(/obj/machinery/door/window/, user.loc))
				to_chat(user, SPAN_WARNING("There is already a windoor in that location."))
				return 1

			if(src.get_amount() < 5)
				to_chat(user, SPAN_WARNING("You need more glass to do that."))
				return 1

			new /obj/structure/windoor_assembly(user.loc, user.dir, 1)
			src.use(5)

	return 0


/*
 * Reinforced glass sheets
 */
/obj/item/stack/material/glass/reinforced
	name = "reinforced glass"
	singular_name = "reinforced glass sheet"
	icon_state = "sheet-rglass"
	default_type = "reinforced glass"
	created_window = /obj/structure/window/reinforced
	is_reinforced = 1
	construction_options = list("One Direction", "Full Window", "Windoor")

/*
 * Wired glass sheets
 */
/obj/item/stack/material/glass/wired
	name = "wired glass tile"
	singular_name = "wired glass floor tile"
	desc = "A glass tile, which is wired, somehow."
	icon = 'icons/obj/item/stacks/tiles.dmi'
	icon_state = "glass_wire"
	created_window = null
	default_type = "wired glass"
	construction_options = list()
	icon_has_variants = FALSE

/obj/item/stack/material/glass/wired/attackby(obj/item/attacking_item, mob/user)
	if(istype(attacking_item, /obj/item/stack/material/steel))
		var/obj/item/stack/material/steel/M = attacking_item
		if (M.use(1))
			var/obj/item/L = new /obj/item/stack/tile/light
			user.drop_from_inventory(L, get_turf(src))
			to_chat(user, SPAN_NOTICE("You make a light tile."))
			use(1)
		else
			to_chat(user, SPAN_WARNING("You need one metal sheet to finish the light tile!"))

	else if(attacking_item.iswirecutter())
		user.drop_from_inventory(attacking_item, get_turf(src))
		to_chat(user, SPAN_NOTICE("You detach the wire from the [name]."))
		playsound(src.loc, 'sound/items/Wirecutter.ogg', 100, 1)
		new /obj/item/stack/cable_coil(user.loc, 5)
		new /obj/item/stack/material/glass(user.loc)
		use(1)
	else
		return ..()

/*
 * Phoron Glass sheets
 */
/obj/item/stack/material/glass/phoronglass
	name = "phoron glass"
	singular_name = "phoron glass sheet"
	icon_state = "sheet-phoronglass"
	created_window = /obj/structure/window/borosilicate
	default_type = "phoron glass"
	icon_has_variants = FALSE

/*
 * Reinforced phoron glass sheets
 */
/obj/item/stack/material/glass/phoronrglass
	name = "reinforced phoron glass"
	singular_name = "reinforced phoron glass sheet"
	icon_state = "sheet-phoronrglass"
	default_type = "reinforced phoron glass"
	created_window = /obj/structure/window/borosilicate/reinforced
	is_reinforced = 1
	icon_has_variants = FALSE
