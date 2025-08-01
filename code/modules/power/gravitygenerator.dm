#define POWER_IDLE 0
#define POWER_UP 1
#define POWER_DOWN 2

#define GRAV_NEEDS_SCREWDRIVER 0
#define GRAV_NEEDS_WELDING 1
#define GRAV_NEEDS_PLASTEEL 2
#define GRAV_NEEDS_WRENCH 3

#define AREA_ERRNONE 0
#define AREA_STATION 1
#define AREA_SPACE 2
#define AREA_SPECIAL 3
//
// Abstract Generator
//

/obj/machinery/gravity_generator
	name = "gravitational generator"
	desc = "A device which produces a gravaton field when set up."
	icon = 'icons/obj/machinery/gravity_generator.dmi'
	anchored = 1
	density = 1
	use_power = POWER_USE_OFF
	unacidable = 1
	var/sprite_number = 0
	light_color = LIGHT_COLOR_CYAN
	light_power = 1
	light_range = 8
	var/datum/looping_sound/gravgen/soundloop

/obj/machinery/gravity_generator/ex_act(severity)
	if(severity == 1) // Very sturdy.
		set_broken()

/obj/machinery/gravity_generator/update_icon()
	..()
	icon_state = "[get_status()]_[sprite_number]"

/obj/machinery/gravity_generator/proc/get_status()
	return "off"

// You aren't allowed to move.
/obj/machinery/gravity_generator/Move()
	. = ..()
	qdel(src)

/obj/machinery/gravity_generator/proc/set_broken()
	stat |= BROKEN

/obj/machinery/gravity_generator/proc/set_fix()
	stat &= ~BROKEN

/obj/machinery/gravity_generator/part/Destroy()
	set_broken()
	if(main_part)
		qdel(main_part)
	return ..()

//
// Part generator which is mostly there for looks
//

/obj/machinery/gravity_generator/part
	var/obj/machinery/gravity_generator/main/main_part = null

/obj/machinery/gravity_generator/part/attackby(obj/item/attacking_item, mob/user)
	return main_part.attackby(attacking_item, user)

/obj/machinery/gravity_generator/part/get_status()
	return main_part.get_status()

/obj/machinery/gravity_generator/part/attack_hand(mob/user as mob)
	return main_part.attack_hand(user)

/obj/machinery/gravity_generator/part/set_broken()
	..()
	if(main_part && !(main_part.stat & BROKEN))
		main_part.set_broken()

//
// Generator which spawns with the station.
//

/obj/machinery/gravity_generator/main/station/Initialize()
	. = ..()
	setup_parts()
	middle.AddOverlays("activated")
	update_list(TRUE)
	addtimer(CALLBACK(src, PROC_REF(round_startset)), 100)

/obj/machinery/gravity_generator/main/station/proc/round_startset()
	if(round_start >= 1)
		round_start--
		set_light(8,1,LIGHT_COLOR_CYAN)

//
// Generator an admin can spawn
//

/obj/machinery/gravity_generator/main/station/admin/Initialize()
	. = ..()
	round_start = 1

//
// Main Generator with the main code
//

/obj/machinery/gravity_generator/main
	icon_state = "on_8"
	idle_power_usage = 0
	active_power_usage = 3000
	power_channel = AREA_USAGE_ENVIRON
	sprite_number = 8
	interact_offline = 1
	var/on = 1
	var/breaker = 1
	var/list/parts = list()
	var/obj/middle = null
	var/charging_state = POWER_IDLE
	var/charge_count = 100
	var/current_overlay = null
	var/broken_state = 0
	var/list/localareas = list()
	var/round_start = 2 //To help stop a bug with round start
	var/backpanelopen = 0
	var/eventon = 0

/obj/machinery/gravity_generator/main/Destroy()
	LOG_DEBUG("Gravity Generator Destroyed")
	investigate_log("was destroyed!", "gravity")
	on = 0
	QDEL_NULL(soundloop)
	update_list(TRUE)
	for(var/obj/machinery/gravity_generator/part/O in parts)
		O.main_part = null
		qdel(O)
	linked?.gravity_generator = null
	return ..()

/obj/machinery/gravity_generator/main/proc/eventshutofftoggle() // Used by the gravity event. Bypasses charging and all of that stuff.
	breaker = 0
	set_state(eventon)
	sleep(20)
	charge_count = 0
	breaker = 1
	charging_state = POWER_UP
	set_power()
	eventon = !eventon
	addtimer(CALLBACK(src, PROC_REF(reset_event)), 100) // Because it takes 100 seconds for it to recharge. And we need to make sure we resen this var

/obj/machinery/gravity_generator/main/proc/reset_event()
	eventon = !eventon

/obj/machinery/gravity_generator/main/proc/setup_parts()
	var/turf/our_turf = get_turf(src)
	// 9x9 block obtained from the bottom middle of the block
	var/list/spawn_turfs = block(locate(our_turf.x - 1, our_turf.y + 2, our_turf.z), locate(our_turf.x + 1, our_turf.y, our_turf.z))
	var/count = 10
	for(var/turf/T in spawn_turfs)
		count--
		if(T == our_turf) // Skip our turf.
			continue
		var/obj/machinery/gravity_generator/part/part = new(T)
		if(count == 5) // Middle
			middle = part
		if(count <= 3) // Their sprite is the top part of the generator
			part.density = 0
			part.layer = MOB_LAYER + 0.1
		part.sprite_number = count
		part.main_part = src
		parts += part
		part.update_icon()

/obj/machinery/gravity_generator/main/proc/connected_parts()
	return parts.len == 8

/obj/machinery/gravity_generator/main/set_broken()
	..()
	for(var/obj/machinery/gravity_generator/M in parts)
		if(!(M.stat & BROKEN))
			M.set_broken()
	middle.ClearOverlays()
	charge_count = 0
	breaker = 0
	set_power()
	set_state(0)
	investigate_log("has broken down.", "gravity")

/obj/machinery/gravity_generator/main/set_fix()
	..()
	for(var/obj/machinery/gravity_generator/M in parts)
		if(M.stat & BROKEN)
			M.set_fix()
	broken_state = 0
	update_icon()
	set_power()

// Interaction

// Fixing the gravity generator.
/obj/machinery/gravity_generator/main/attackby(obj/item/attacking_item, mob/user)
	var/old_broken_state = broken_state
	switch(broken_state)
		if(GRAV_NEEDS_SCREWDRIVER)
			if(attacking_item.isscrewdriver())
				to_chat(user, SPAN_NOTICE("You secure the screws of the framework."))
				attacking_item.play_tool_sound(get_turf(src), 50)
				broken_state++
		if(GRAV_NEEDS_WELDING)
			if(attacking_item.iswelder())
				var/obj/item/weldingtool/WT = attacking_item
				if(WT.use(1, user))
					to_chat(user, SPAN_NOTICE("You mend the damaged framework."))
					playsound(src.loc, 'sound/items/welder_pry.ogg', 50, 1)
					broken_state++
		if(GRAV_NEEDS_PLASTEEL)
			if(istype(attacking_item, /obj/item/stack/material/plasteel))
				var/obj/item/stack/material/plasteel/PS = attacking_item
				if(PS.amount >= 10)
					PS.use(10)
					to_chat(user, SPAN_NOTICE("You add the plating to the framework."))
					playsound(src.loc, 'sound/machines/click.ogg', 75, 1)
					broken_state++
				else
					to_chat(user, SPAN_NOTICE("You need 10 sheets of plasteel."))
		if(GRAV_NEEDS_WRENCH)
			if(attacking_item.iswrench())
				to_chat(user, SPAN_NOTICE("You secure the plating to the framework."))
				attacking_item.play_tool_sound(get_turf(src), 75)
				set_fix()
		else
			..()
	if(attacking_item.iscrowbar())
		if(backpanelopen)
			attacking_item.play_tool_sound(get_turf(src), 50)
			to_chat(user, SPAN_NOTICE("You replace the back panel."))
			backpanelopen = 0
		else
			attacking_item.play_tool_sound(get_turf(src), 50)
			to_chat(user, SPAN_NOTICE("You open the back panel."))
			backpanelopen = 1

	if(old_broken_state != broken_state)
		update_icon()

/obj/machinery/gravity_generator/main/attack_hand(mob/user as mob)
	if(!..())
		return interact(user)

/obj/machinery/gravity_generator/main/interact(mob/user as mob)
	if(stat & BROKEN)
		return
	var/dat = "Gravity Generator Breaker: "
	if(!eventon)
		if(breaker)
			dat += "<span class='linkOn'>ON</span> <A href='byond://?src=[REF(src)];gentoggle=1'>OFF</A>"
		else
			dat += "<A href='byond://?src=[REF(src)];gentoggle=1'>ON</A> <span class='linkOn'>OFF</span> "
		if(backpanelopen)
			dat += "<br>Emergency shutoff:<br>"
			dat += "<A href='byond://?src=[REF(src)];eshutoff=1'>Red Button</A>"

		dat += "<br>Generator Status:<br><div class='statusDisplay'>"
		if(charging_state != POWER_IDLE)
			dat += "<font class='bad'>WARNING</font> Radiation Detected. <br>[charging_state == POWER_UP ? "Charging..." : "Discharging..."]"
		else if(on)
			dat += "Powered."
		else
			dat += "Unpowered."

		dat += "<br>Gravity Charge: [charge_count]%</div>"
	else
		dat += "<h3><font class='bad'>ERROR: SYSTEM MALFUNCTION. PLEASE WAIT...</font></h3>"
	var/datum/browser/popup = new(user, "gravgen", name)
	popup.set_content(dat)
	popup.open()


/obj/machinery/gravity_generator/main/Topic(href, href_list)

	if(..())
		return

	if(href_list["gentoggle"])
		breaker = !breaker
		investigate_log("was toggled [breaker ? "<font color='green'>ON</font>" : SPAN_WARNING("OFF")] by [usr.key].", "gravity")
		set_power()
		src.updateUsrDialog()
	else if(href_list["eshutoff"])
		investigate_log("was shut off by [usr.key].", "gravity")
		eshutoff()


/obj/machinery/gravity_generator/main/power_change()
	..()
	breaker = (stat & NOPOWER) ? FALSE : TRUE
	set_power()
	investigate_log("has [stat & NOPOWER ? "lost" : "regained"] power.", "gravity")

/obj/machinery/gravity_generator/main/proc/eshutoff()
	if(charge_count > 0)
		charge_count = 0
		playsound(src.loc, 'sound/effects/EMPulse.ogg', 100, 1)
		pulse_radiation(100)
		set_state(0)
		if(middle)
			middle.ClearOverlays()
		if(prob(1)) //It will spawn a small one and eat the generator. Won't cause any other issues considering it's a 1x1 and will go away on it's own.
			new /obj/singularity(src.loc)
		if(prob(33)) //Releasing all that power at once is dangerous.
			empulse(src.loc, 2, 4)
		set_light(10,1,LIGHT_COLOR_FLARE)
		sleep(5)
		set_light(5,0.5,LIGHT_COLOR_FIRE)
		sleep(5)
		set_light(0,0,"#000000")

/obj/machinery/gravity_generator/main/get_status()
	if(stat & BROKEN)
		return "fix[min(broken_state, 3)]"
	return on || charging_state != POWER_IDLE ? "on" : "off"

/obj/machinery/gravity_generator/main/update_icon()
	..()
	for(var/obj/O in parts)
		O.update_icon()

// Set the charging state based on power/breaker.
/obj/machinery/gravity_generator/main/proc/set_power()
	var/new_state = 0
	if(stat & (NOPOWER|BROKEN) || !breaker)
		new_state = 0
	else if(breaker)
		new_state = 1

	charging_state = new_state ? POWER_UP : POWER_DOWN // Startup sequence animation.
	investigate_log("is now [charging_state == POWER_UP ? "charging" : "discharging"].", "gravity")
	update_icon()

// Set the state of the gravity.
/obj/machinery/gravity_generator/main/proc/set_state(var/new_state)
	charging_state = POWER_IDLE
	var/gravity_changed = (on != new_state)
	on = new_state
	update_use_power(on ? POWER_USE_ACTIVE : POWER_USE_IDLE)
	// Sound the alert if gravity was just enabled or disabled.
	var/alert = 0
	var/area/area = get_area(src)
	var/areadisplayname = get_area_display_name(area)
	if(new_state) // If we turned on
		if(!area.has_gravity())
			alert = 1
			GLOB.gravity_is_on = 1
			soundloop.start(src)
			investigate_log("was brought online and is now producing gravity for this level.", "gravity")
			message_admins("The gravity generator was brought online. (<A href='byond://?_src_=holder;adminplayerobservecoodjump=1;X=[x];Y=[y];Z=[z]'>[areadisplayname]</a>)")
	else
		if(area.has_gravity())
			alert = 1
			GLOB.gravity_is_on = 0
			soundloop.stop(src)
			investigate_log("was brought offline and there is now no gravity for this level.", "gravity")
			message_admins("The gravity generator was brought offline with no backup generator. (<A href='byond://?_src_=holder;adminplayerobservecoodjump=1;X=[x];Y=[y];Z=[z]'>[areadisplayname]</a>)")

	update_icon()
	update_list(gravity_changed)
	src.updateUsrDialog()
	if(alert)
		shake_everyone()

// Charge/Discharge and turn on/off gravity when you reach 0/100 percent.
// Also emit radiation and handle the overlays.
/obj/machinery/gravity_generator/main/process()
	if(stat & BROKEN)
		return
	if(charging_state != POWER_IDLE)
		if(charging_state == POWER_UP && charge_count >= 100)
			set_state(1)
		else if(charging_state == POWER_DOWN && charge_count <= 0)
			set_state(0)
		else
			if(charging_state == POWER_UP)
				charge_count += rand(1,5)
			else if(charging_state == POWER_DOWN)
				charge_count -= rand(1,5)

			if(charge_count % 4 == 0 && prob(75)) // Let them know it is charging/discharging.
				playsound(src.loc, 'sound/effects/EMPulse.ogg', 100, 1)

			updateDialog()
			if(prob(30)) // To help stop "Your clothes feel warm" spam.
				pulse_radiation()

			var/overlay_state = null
			switch(charge_count)
				if(0 to 20)
					overlay_state = null
					set_light(0,0,"#000000")
				if(21 to 40)
					overlay_state = "startup"
					set_light(4,0.2,LIGHT_COLOR_BLUE)
				if(41 to 60)
					overlay_state = "idle"
					set_light(6,0.5,"#7D9BFF") //More of a washed out perywinkle than blue but shut up.
				if(61 to 80)
					overlay_state = "activating"
					set_light(6,0.8,"#7DC3FF")
				if(81 to 100)
					overlay_state = "activated"
					set_light(8,1,LIGHT_COLOR_CYAN)

			if(overlay_state != current_overlay)
				if(middle)
					middle.ClearOverlays()
					if(overlay_state)
						middle.AddOverlays(overlay_state)
					current_overlay = overlay_state

/obj/machinery/gravity_generator/main/proc/pulse_radiation(var/amount = 20)
	SSradiation.radiate(src, amount)

// Shake everyone on the z level to let them know that gravity was enagaged/disenagaged.
/obj/machinery/gravity_generator/main/proc/shake_everyone()
	var/turf/our_turf = get_turf(src)
	for(var/mob/M in GLOB.mob_list)
		var/turf/their_turf = get_turf(M)
		if(their_turf && (their_turf.z == our_turf.z))
			M.update_gravity(M.mob_has_gravity())
			if(M.client)
				if(!M)	return
				shake_camera(M, 5, 1)
				M.playsound_local(our_turf, 'sound/effects/alert.ogg', 100, vary = TRUE, falloff_distance = 0.5)

/obj/machinery/gravity_generator/main/proc/update_list(var/gravity_changed = FALSE)
	var/turf/T = get_turf(src.loc)
	if(T)
		if(!SSmachinery.gravity_generators)
			SSmachinery.gravity_generators = list()

		if(on && gravity_changed)
			for(var/area/A in localareas)
				A.gravitychange(TRUE)
			SSmachinery.gravity_generators += src
		else if (!on)
			for(var/area/A in localareas)
				A.gravitychange(FALSE)
			SSmachinery.gravity_generators -= src

/obj/machinery/gravity_generator/main/Initialize()
	. = ..()
	soundloop = new(src, start_immediately = FALSE)
	addtimer(CALLBACK(src, PROC_REF(updateareas)), 10)
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/gravity_generator/main/LateInitialize()
	if(SSatlas.current_map.use_overmap && !linked)
		var/my_sector = GLOB.map_sectors["[z]"]
		if (istype(my_sector, /obj/effect/overmap/visitable))
			attempt_hook_up(my_sector)
	if(linked)
		linked.gravity_generator = src

/obj/machinery/gravity_generator/main/proc/updateareas()
	for(var/area/A in GLOB.the_station_areas)
		if(!(get_area_type(A) == AREA_STATION))
			continue
		localareas += A

/obj/machinery/gravity_generator/main/proc/get_area_type(var/area/A = get_area(src))
	if (A.name == "Space")
		return AREA_SPACE
	else if(A.alwaysgravity == 1 || A.nevergravity == 1)
		return AREA_SPECIAL
	else
		return AREA_STATION

/obj/machinery/gravity_generator/main/proc/throw_up_and_down(var/area/Area)
	if(!Area)
		return
	to_world("<h2 class='alert'>Station Announcement:</h2>")
	to_world(SPAN_DANGER("Warning! Localized Gravity Failure in \the [Area]. Brace for dangerous gravity change!"))
	sleep(50)
	set_state(FALSE)
	sleep(30)
	set_state(TRUE)
	for(var/mob/living/M in GLOB.mob_list)
		var/turf/their_turf = get_turf(M)
		if(their_turf?.loc ==  Area)
			if(ishuman(M))
				var/mob/living/carbon/human/H = M
				var/obj/item/clothing/shoes/magboots/boots = H.get_equipped_item(slot_shoes)
				if(istype(boots))
					continue
			to_chat(M, SPAN_DANGER("Suddenly the gravity pushed you up to the ceiling and dropped you back on the floor with great force!"))
			M.fall_impact(1)


#undef POWER_IDLE
#undef POWER_UP
#undef POWER_DOWN

#undef GRAV_NEEDS_SCREWDRIVER
#undef GRAV_NEEDS_WELDING
#undef GRAV_NEEDS_PLASTEEL
#undef GRAV_NEEDS_WRENCH

#undef AREA_ERRNONE
#undef AREA_STATION
#undef AREA_SPACE
#undef AREA_SPECIAL
