/obj/structure/grille
	name = "grille"
	desc = "A flimsy lattice of metal rods."
	icon = 'icons/obj/structures.dmi'
	icon_state = "grille"
	density = TRUE
	anchored = TRUE
	pass_flags_self = PASSGRILLE
	obj_flags = OBJ_FLAG_CONDUCTABLE | OBJ_FLAG_MOVES_UNSUPPORTED
	explosion_resistance = 1
	layer = BELOW_WINDOW_LAYER
	var/health = 10
	var/destroyed = 0

/obj/structure/grille/condition_hints(mob/user, distance, is_adjacent)
	. += ..()
	if(health < initial(health))
		var/state
		var/current_damage = health / initial(health)
		switch(current_damage)
			if(0 to 0.3)
				state = SPAN_DANGER("The grille is barely in one piece!")
			if(0.3 to 0.8)
				state = SPAN_ALERT("The grille has taken some serious damage.")
			if(0.8 to 1)
				state = SPAN_NOTICE("The grille is in less than perfect condition.")
		. += state

/obj/structure/grille/mechanics_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "A powered and knotted wire underneath this will cause the grille to shock anyone not wearing insulated gloves."

/obj/structure/grille/assembly_hints(mob/user, distance, is_adjacent)
	. += ..()

/obj/structure/grille/disassembly_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "These could be easily <b>cut</b> through."

/obj/structure/grille/feedback_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "\the [src] [anchored ? "is" : "could be"] anchored to the floor with some <b>screws<b/>."

/obj/structure/grille/over
	name = "over-frame grille"
	icon = 'icons/obj/smooth/window/grille_over.dmi'
	layer = BELOW_WINDOW_LAYER
	smoothing_flags = SMOOTH_MORE
	canSmoothWith = list(
		/turf/simulated/wall,
		/turf/simulated/wall/r_wall,
		/turf/unsimulated/wall/steel,
		/turf/unsimulated/wall/darkshuttlewall,
		/turf/unsimulated/wall/riveted,
		/obj/structure/window_frame,
		/obj/structure/window_frame/unanchored,
		/obj/structure/window_frame/empty,
		/obj/structure/window/full/reinforced,
		/obj/structure/window/full/reinforced/indestructible,
		/obj/structure/window/full/reinforced/polarized,
		/obj/structure/window/full/reinforced/polarized/indestructible,
		/obj/structure/window/full/phoron/reinforced,
		/obj/structure/window/shuttle/scc_space_ship,
		/turf/simulated/wall/shuttle/scc_space_ship,
		/obj/machinery/door
	)
	blend_overlay = "wall"
	attach_overlay = "attach"
	can_blend_with = list(
		/turf/simulated/wall,
		/obj/structure/window_frame
	)

/obj/structure/grille/over/Destroy()
	var/obj/structure/window_frame/window_frame = locate(/obj/structure/window_frame) in get_turf(src)
	if(window_frame)
		window_frame.has_grille_installed = FALSE
	return ..()

/obj/structure/grille/over/cardinal_smooth(adjacencies, var/list/dir_mods)
	dir_mods = handle_blending(adjacencies, dir_mods)
	return ..(adjacencies, dir_mods)

/obj/structure/grille/over/large //for external windows
	name = "large over-frame grille"
	icon = 'icons/obj/smooth/window/grille_over_large.dmi'
	can_blend_with = list(
		/turf/simulated/wall,
		/obj/structure/window_frame,
		/turf/simulated/wall/shuttle/scc_space_ship
	)

/obj/structure/grille/ex_act(severity)
	qdel(src)

/obj/structure/grille/update_icon()
	if(destroyed)
		icon_state = "[initial(icon_state)]-b"
	else
		icon_state = initial(icon_state)

/obj/structure/grille/CollidedWith(atom/bumped_atom)
	. = ..()

	if(ismob(bumped_atom))
		shock(bumped_atom, 70)

/obj/structure/grille/attack_hand(mob/user as mob)

	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	playsound(loc, 'sound/effects/grillehit.ogg', 80, 1)
	user.do_attack_animation(src)

	var/damage_dealt = 1
	var/attack_message = "kicks"
	if(istype(user,/mob/living/carbon/human))
		var/mob/living/carbon/human/H = user
		if(H.species.can_shred(H))
			attack_message = "mangles"
			damage_dealt = 5

	if(shock(user, 70))
		return

	if((user.mutations & HULK))
		damage_dealt += 5
	else
		damage_dealt += 1

	attack_generic(user,damage_dealt,attack_message)

/obj/structure/grille/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(air_group || (height==0))
		return TRUE
	if(mover?.movement_type & PHASING)
		return TRUE
	if(istype(mover) && mover.pass_flags & PASSGRILLE)
		return TRUE
	else
		if(istype(mover, /obj/projectile))
			return prob(30)
		else
			return !density

/obj/structure/grille/bullet_act(obj/projectile/hitting_projectile, def_zone, piercing_hit)
	. = ..()
	if(. != BULLET_ACT_HIT)
		return .

	if(!hitting_projectile)
		return BULLET_ACT_BLOCK

	//Flimsy grilles aren't so great at stopping projectiles. However they can absorb some of the impact
	var/damage = hitting_projectile.get_structure_damage()
	var/passthrough = 0

	if(!damage)
		return BULLET_ACT_BLOCK

	//20% chance that the grille provides a bit more cover than usual. Support structure for example might take up 20% of the grille's area.
	//If they click on the grille itself then we assume they are aiming at the grille itself and the extra cover behaviour is always used.
	switch(hitting_projectile.damage_type)
		if(DAMAGE_BRUTE)
			//bullets
			if(hitting_projectile.original == src || prob(20))
				hitting_projectile.damage *= between(0, hitting_projectile.damage/60, 0.5)
				if(prob(max((damage-10)/25, 0))*100)
					passthrough = 1
			else
				hitting_projectile.damage *= between(0, hitting_projectile.damage/60, 1)
				passthrough = 1
		if(DAMAGE_BURN)
			//beams and other projectiles are either blocked completely by grilles or stop half the damage.
			if(!(hitting_projectile.original == src || prob(20)))
				hitting_projectile.damage *= 0.5
				passthrough = 1

	if(passthrough)
		. = BULLET_ACT_HIT
		damage = between(0, (damage - hitting_projectile.damage)*(hitting_projectile.damage_type == DAMAGE_BRUTE? 0.4 : 1), 10) //if the bullet passes through then the grille avoids most of the damage

	src.health -= damage*0.2
	spawn(0) healthcheck() //spawn to make sure we return properly if the grille is deleted

/obj/structure/grille/attackby(obj/item/attacking_item, mob/user)
	if(attacking_item.iswirecutter())
		if(!shock(user, 100))
			playsound(loc, 'sound/items/Wirecutter.ogg', 100, 1)
			new /obj/item/stack/rods(get_turf(src), destroyed ? 1 : 2)
			qdel(src)
	else if(istype(attacking_item, /obj/item/gun/energy/plasmacutter))
		var/obj/item/gun/energy/plasmacutter/PC = attacking_item
		if(PC.check_power_and_message(user))
			return
		PC.use_resource(user, 1)
		playsound(loc, PC.fire_sound, 100, TRUE)
		new /obj/item/stack/rods(get_turf(src), destroyed ? 1 : 2)
		qdel(src)
	else if((attacking_item.isscrewdriver()) && (istype(loc, /turf/simulated) || anchored))
		if(!shock(user, 90))
			playsound(loc, 'sound/items/Screwdriver.ogg', 100, 1)
			anchored = !anchored
			user.visible_message(SPAN_NOTICE("[user] [anchored ? "fastens" : "unfastens"] the grille."), \
								SPAN_NOTICE("You have [anchored ? "fastened the grille to" : "unfastened the grill from"] the floor."))
		return
	else if(istype(attacking_item,/obj/item/stack/rods) && destroyed == 1)
		if(!shock(user, 90))
			var/obj/item/stack/rods/ROD = attacking_item
			health = 10
			density = 1
			destroyed = 0
			icon_state = "grille"
			ROD.use(1)
			user.visible_message(SPAN_NOTICE("[user] repairs the grille."), \
								SPAN_NOTICE("You have repaired the grille."))
			return

//window placing begin //TODO CONVERT PROPERLY TO MATERIAL DATUM
	else if(istype(attacking_item,/obj/item/stack/material))
		var/obj/item/stack/material/ST = attacking_item
		if(!ST.material.created_window)
			return 0

		var/dir_to_set = 1
		if(loc == user.loc)
			dir_to_set = user.dir
		else
			if( ( x == user.x ) || (y == user.y) ) //Only supposed to work for cardinal directions.
				if( x == user.x )
					if( y > user.y )
						dir_to_set = 2
					else
						dir_to_set = 1
				else if( y == user.y )
					if( x > user.x )
						dir_to_set = 8
					else
						dir_to_set = 4
			else
				to_chat(user, SPAN_NOTICE("You can't reach."))
				return //Only works for cardinal direcitons, diagonals aren't supposed to work like this.
		for(var/obj/structure/window/WINDOW in loc)
			if(WINDOW.dir == dir_to_set)
				to_chat(user, SPAN_NOTICE("There is already a window facing this way there."))
				return
		to_chat(user, SPAN_NOTICE("You start placing the window."))
		if(do_after(user,20))
			for(var/obj/structure/window/WINDOW in loc)
				if(WINDOW.dir == dir_to_set)//checking this for a 2nd time to check if a window was made while we were waiting.
					to_chat(user, SPAN_NOTICE("There is already a window facing this way there."))
					return

			var/wtype = ST.material.created_window
			if (ST.use(1))
				var/obj/structure/window/WD = new wtype(loc, dir_to_set, 1)
				to_chat(user, SPAN_NOTICE("You place the [WD] on [src]."))
				WD.update_icon()
		return
//window placing end

	else if(!(attacking_item.obj_flags & OBJ_FLAG_CONDUCTABLE) || !shock(user, 70))
		user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
		user.do_attack_animation(src)
		playsound(loc, 'sound/effects/grillehit.ogg', 80, 1)
		switch(attacking_item.damtype)
			if("fire")
				health -= attacking_item.force
			if("brute")
				health -= attacking_item.force * 0.1
	healthcheck()
	..()
	return


/obj/structure/grille/proc/healthcheck()
	if(health <= 0)
		if(!destroyed)
			density = 0
			destroyed = 1
			update_icon()
			new /obj/item/stack/rods(get_turf(src))

		else
			if(health <= -6)
				new /obj/item/stack/rods(get_turf(src))
				qdel(src)
				return
	return

// shock user with probability prb (if all connections & power are working)
// returns 1 if shocked, 0 otherwise

/obj/structure/grille/proc/shock(mob/user as mob, prb)

	if(!anchored || destroyed)		// anchored/destroyed grilles are never connected
		return 0
	if(!prob(prb))
		return 0
	if(!in_range(src, user))//To prevent TK and mech users from getting shocked
		return 0
	var/turf/T = get_turf(src)
	var/obj/structure/cable/C = T.get_cable_node()
	if(C)
		if(electrocute_mob(user, C, src))
			if(C.powernet)
				C.powernet.trigger_warning()
			spark(src, 3, GLOB.alldirs)
			if(user.stunned)
				return 1
		else
			return 0
	return 0

/obj/structure/grille/fire_act(exposed_temperature, exposed_volume)
	if(!destroyed)
		if(exposed_temperature > T0C + 1500)
			health -= 1
			healthcheck()
	..()

/obj/structure/grille/attack_generic(var/mob/user, var/damage, var/attack_verb)
	visible_message(SPAN_DANGER("[user] [attack_verb] the [src]!"))
	user.do_attack_animation(src)
	health -= damage
	spawn(1) healthcheck()
	return 1

// Used in mapping to avoid
/obj/structure/grille/broken
	destroyed = 1
	icon_state = "grille-b"
	density = 0

/obj/structure/grille/broken/New()
	..()
	health = rand(-5, -1) //In the destroyed but not utterly threshold.
	healthcheck() //Send this to healthcheck just in case we want to do something else with it.

/obj/structure/grille/diagonal
	icon_state = "grille_diagonal"

/obj/structure/grille/cult
	name = "cult grille"
	desc = "A matrice built out of an unknown material, with some sort of force field blocking air around it"
	icon_state = "grillecult"
	health = 40 //Make it strong enough to avoid people breaking in too easily
	appearance_flags = NO_CLIENT_COLOR

/obj/structure/grille/cult/CanPass(atom/movable/mover, turf/target, height = 1.5, air_group = 0)
	if(air_group)
		return 0 //Make sure air doesn't drain
	. = ..()

/obj/structure/grille/crescent/attack_hand()
	return

/obj/structure/grille/crescent/attackby()
	return

/obj/structure/grille/crescent/attack_generic()
	return

/obj/structure/grille/crescent/ex_act(var/severity = 2.0)
	return

/obj/structure/grille/crescent/hitby(atom/movable/hitting_atom, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	return
