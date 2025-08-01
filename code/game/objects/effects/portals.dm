/obj/effect/portal
	name = "portal"
	desc = "A bluespace tear in space, reaching directly to another point within this region. Looks unstable. Best to test it carefully."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "portal"
	density = TRUE
	unacidable = TRUE //Can't destroy energy portals.
	mouse_opacity = MOUSE_OPACITY_ICON
	anchored = TRUE

	///Boolean, if the portal can actually teleport, or not (aka it's just visual)
	var/does_teleport = TRUE

	var/has_lifespan = TRUE // Whether we want to directly control the lifespan or not

	///Chance that the portal will fail
	var/failchance = 5

	///Boolean, if the portal has failed (aka it will teleport you somewhere else)
	var/has_failed = FALSE

	/**
	 * The target the teleport aims to, an `/obj` or `/turf`
	 *
	 * *Not* to be set directly, use `set_target()` instead
	 */
	var/atom/target

	///Who created the portal
	var/creator

	///How precise (turf range) is the teleportation
	var/precision = 1

/obj/effect/portal/Initialize(mapload, turf/set_target, set_creator, lifespan = 300, precise = 1)
	. = ..()

	if(set_target)
		set_target(set_target)

	if(set_creator)
		creator = set_creator
		if(istype(creator, /atom))
			RegisterSignal(creator, COMSIG_QDELETING, PROC_REF(handle_creator_qdel))

	if(has_lifespan && lifespan > 0)
		QDEL_IN(src, lifespan)

	if(prob(failchance))
		has_failed = TRUE

	precision = precise

	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)

	AddElement(/datum/element/connect_loc, loc_connections)

/obj/effect/portal/Destroy()
	if(istype(creator, /obj/item/hand_tele))
		var/obj/item/hand_tele/HT = creator
		HT.remove_portal(src)
	. = ..()

/obj/effect/portal/CollidedWith(atom/bumped_atom)
	. = ..()

	if(does_teleport)
		teleport(bumped_atom)

/obj/effect/portal/proc/on_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER

	if(does_teleport)
		teleport(arrived)

/obj/effect/portal/attackby(obj/item/attacking_item, mob/user)
	if(istype(attacking_item, /obj/item/bluespace_neutralizer))
		user.visible_message("<b>[user]</b> collapses \the [src] with \the [attacking_item].", SPAN_NOTICE("You collapse \the [src] with \the [attacking_item]."))
		qdel(src)
		return TRUE
	return ..()

/obj/effect/portal/attack_hand(mob/user)
	if(does_teleport)
		teleport(user)

/obj/effect/portal/proc/teleport(atom/movable/movable)
	if(!does_teleport) // just to be safe
		return
	if(istype(movable, /obj/effect)) //sparks don't teleport
		return
	if(!target)
		qdel(src)
		return
	var/has_teleported = FALSE
	var/list/things_to_teleport = list(movable)
	if(ismob(movable))
		var/mob/M = movable
		if(M.pulling)
			things_to_teleport += M.pulling
		if(ishuman(movable))
			var/mob/living/carbon/human/H = movable
			for(var/obj/item/grab/G in list(H.l_hand, H.r_hand))
				things_to_teleport += G.affecting
	for(var/atom/movable/M in things_to_teleport)
		if(has_failed) //oh dear a problem, put em in deep space
			icon_state = "portal1" // only tell people the portal failed after a teleport has been done
			desc = "A bluespace tear in space, reaching directly to another point within this region. Definitely unstable."
			if(do_teleport(M, locate(rand(5, world.maxx - 5), rand(5, world.maxy -5), pick(GetConnectedZlevels(z))), 0))
				has_teleported = TRUE
		else
			if(do_teleport(M, target, precision))
				has_teleported = TRUE
	if(!has_teleported)
		visible_message(SPAN_WARNING("\The [src] oscillates violently as \the [movable] comes into contact with it, and collapses! Seems like the rift was unstable..."))
		qdel(src)

/**
 * Sets the target of the teleporter
 */
/obj/effect/portal/proc/set_target(atom/new_target)
	if(!is_type_in_list(new_target, list(/obj, /turf, /mob)))
		stack_trace("Portal was tried to be targeted at something that it is not supposed to!")
		return

	if(target)
		UnregisterSignal(target, COMSIG_QDELETING)

	target = new_target
	RegisterSignal(target, COMSIG_QDELETING, PROC_REF(handle_target_qdel))

/**
 * Handles the teleporting target being deleted
 */
/obj/effect/portal/proc/handle_target_qdel()
	SIGNAL_HANDLER

	if(!QDELETED(src))
		qdel(src)

/**
 * Handles the creator being deleted
 */
/obj/effect/portal/proc/handle_creator_qdel()
	SIGNAL_HANDLER

	creator = null


/*##############
	SUBTYPES
##############*/

/obj/effect/portal/spawner
	name = "portal"
	desc = "A bluespace tear in space, reaching directly to another point within this region. This one looks like a one-way portal to here; don't get too close."
	does_teleport = FALSE
	has_lifespan = FALSE
	layer = OBJ_LAYER - 0.01
	var/list/spawn_things = list() // The list things to spawn
	var/num_of_spawns			   // How many times we want to spawn them before qdel
	var/next_spawn

/obj/effect/portal/spawner/mechanics_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "This portal is a spawner portal. You cannot enter it to teleport, but it will periodically spawn things."

/obj/effect/portal/spawner/Initialize()
	. = ..()
	START_PROCESSING(SSprocessing, src)
	next_spawn = world.time + 5 SECONDS

/obj/effect/portal/spawner/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/obj/effect/portal/spawner/process()
	if(next_spawn < world.time)
		visible_message(SPAN_WARNING("\The [src] spits something out!"))
		for(var/thing in spawn_things)
			var/spawn_path = thing
			var/atom/spawned_thing = new spawn_path(get_turf(src))

			if(istype(spawned_thing, /obj/item/stack))
				var/obj/item/stack/stack = spawned_thing
				stack.amount = spawn_things[thing]
				stack.throw_at(get_random_turf_in_range(get_turf(src), 1), 2)
			else
				for(var/i = 1; i < spawn_things[thing]; i++)
					var/atom/movable/A = new spawn_path(get_turf(src))
					A.throw_at(get_random_turf_in_range(get_turf(src), 1), 2)

		next_spawn = world.time + 30 SECONDS
		num_of_spawns--
	if(num_of_spawns <= 0)
		visible_message(SPAN_WARNING("\The [src] collapses in on itself!"))
		qdel(src)

/obj/effect/portal/spawner/metal
	num_of_spawns = 3
	spawn_things = list(
		/obj/item/stack/material/steel = 10,
		/obj/item/stack/material/plasteel = 5
	)

/obj/effect/portal/spawner/rare_metal
	num_of_spawns = 4
	spawn_things = list(
		/obj/item/stack/material/gold = 2,
		/obj/item/stack/material/silver = 2,
		/obj/item/stack/material/uranium = 2,
		/obj/item/stack/material/diamond = 1
	)

/obj/effect/portal/spawner/silver
	num_of_spawns = 3
	spawn_things = list(
		/obj/item/stack/material/silver = 3
	)

/obj/effect/portal/spawner/gold
	num_of_spawns = 3
	spawn_things = list(
		/obj/item/stack/material/gold = 3
	)

/obj/effect/portal/spawner/phoron
	num_of_spawns = 3
	spawn_things = list(
		/obj/item/stack/material/phoron = 3
	)

/obj/effect/portal/spawner/plasticglass
	num_of_spawns = 3
	spawn_things = list(
		/obj/item/stack/material/plastic = 5,
		/obj/item/stack/material/glass = 5
	)

/obj/effect/portal/spawner/wood
	num_of_spawns = 3
	spawn_things = list(
		/obj/item/stack/material/wood = 5,
		/obj/item/stack/material/cardboard = 5,
		/obj/item/stack/material/cloth = 5
	)

/obj/effect/portal/spawner/hide
	num_of_spawns = 3
	spawn_things = list(
		/obj/item/stack/material/animalhide = 5,
		/obj/item/stack/material/leather = 5
	)

/obj/effect/portal/spawner/monkey_cube
	num_of_spawns = 1
	spawn_things = list(
		/obj/item/reagent_containers/food/snacks/monkeycube = 4
	)

/obj/effect/portal/spawner/cow // debug but funny so im keeping it
	num_of_spawns = 1
	spawn_things = list(
		/mob/living/simple_animal/cow = 1
	)

#define COLOR_STAGE_FIVE "#163DFF"
#define COLOR_STAGE_FOUR "#0099ff"
#define COLOR_STAGE_THREE "#33eb33"
#define COLOR_STAGE_TWO "#F0FF2B"
#define COLOR_STAGE_ONE "#FF8D23"
#define COLOR_STAGE_ZERO "#FF0000"

/obj/effect/portal/revenant
	name = "bluespace rift"
	desc = "A bluespace tear in space, reaching directly to another point within this region. This one looks like a one-way portal to here, don't come too close."
	icon_state = "portal_g"

	does_teleport = FALSE
	has_lifespan = FALSE

	color = COLOR_STAGE_FIVE
	light_color = COLOR_STAGE_FIVE
	light_power = 6
	light_range = 8

	var/last_color_level = 5
	var/health_timer = 10 MINUTES // you need to reduce the health by standing near it with a neutralizer

/obj/effect/portal/revenant/mechanics_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "This is a bluespace rift. It is a node wherein revenants can seep into this locale. To destroy it, you must bring a bluespace neutralizer near it."

/obj/effect/portal/revenant/Initialize(mapload)
	. = ..()
	if(GLOB.revenants.revenant_rift)
		return INITIALIZE_HINT_QDEL
	var/turf/T = get_turf(src)
	log_and_message_admins("Revenant Bluespace Rift spawned at \the [get_area(T)]", null, T)
	GLOB.revenants.revenant_rift = src

/obj/effect/portal/revenant/Destroy()
	GLOB.revenants.destroyed_rift()
	visible_message(FONT_LARGE(SPAN_DANGER("\The [src] collapses!")))
	new /obj/random/highvalue/no_crystal(src)
	new /obj/random/highvalue/no_crystal(src)
	for(var/thing in contents)
		var/obj/O = thing
		O.forceMove(get_turf(src))
	var/area_display_name = get_area_display_name(get_area(src))
	message_all_revenants(FONT_LARGE(SPAN_WARNING("The rift keeping us here has been destroyed in [area_display_name]!")))
	return ..()

/obj/effect/portal/revenant/attackby(obj/item/attacking_item, mob/user)
	if(istype(attacking_item, /obj/item/bluespace_neutralizer))
		to_chat(user, SPAN_WARNING("You need to activate \the [attacking_item] and keep it near \the [src] to collapse it."))
		return TRUE
	return ..()

/obj/effect/portal/revenant/proc/reduce_health(var/amount = 1)
	health_timer -= amount
	if(health_timer <= 0)
		qdel(src)
		return
	update_icon()

/obj/effect/portal/revenant/update_icon()
	var/color_level = round((health_timer / 600) / 2) // this should give a value from 0 - 5
	if(color_level == last_color_level)
		return
	var/area_display_name = get_area_display_name(get_area(src))
	message_all_revenants(FONT_LARGE(SPAN_WARNING("The rift keeping us here is being attacked in [area_display_name]!")))
	last_color_level = color_level
	switch(color_level)
		if(0)
			color = COLOR_STAGE_ZERO
		if(1)
			color = COLOR_STAGE_ONE
		if(2)
			color = COLOR_STAGE_TWO
		if(3)
			color = COLOR_STAGE_THREE
		if(4)
			color = COLOR_STAGE_FOUR
		if(5)
			color = COLOR_STAGE_FIVE
	light_color = color
	update_light()

/// Mainly for admin events.
/obj/effect/portal/permanent
	has_lifespan = FALSE

#undef COLOR_STAGE_FIVE
#undef COLOR_STAGE_FOUR
#undef COLOR_STAGE_THREE
#undef COLOR_STAGE_TWO
#undef COLOR_STAGE_ONE
#undef COLOR_STAGE_ZERO
