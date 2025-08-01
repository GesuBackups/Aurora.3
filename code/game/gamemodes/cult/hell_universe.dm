/*

In short:
 * Random area alarms
 * All areas jammed
 * Random gateways spawning hellmonsters (and turn people into cluwnes if ran into)
 * Broken APCs/Fire Alarms
 * Scary music
 * Random tiles changing to culty tiles.

*/
/datum/universal_state/hell
	name = "Hell Rising"
	desc = "OH FUCK OH FUCK OH FUCK"

	decay_rate = 5 // 5% chance of a turf decaying on lighting update/airflow (there's no actual tick for turfs)

/datum/universal_state/hell/OnShuttleCall(var/mob/user)
	return 1

/datum/universal_state/hell/DecayTurf(var/turf/T)
	if(!T.holy)
		T.cultify()
		for(var/obj/machinery/light/L in T.contents)
			new /obj/structure/cult/pylon(L.loc)
			qdel(L)
	return


/datum/universal_state/hell/OnTurfChange(var/turf/T)
	var/turf/space/S = T
	if(istype(S))
		S.color = "#FF0000"
	else
		S.color = initial(S.color)

// Apply changes when entering state
/datum/universal_state/hell/OnEnter()
	SSgarbage.can_fire = FALSE	// Yeah, fuck it. No point hard-deleting stuff now.

	GLOB.escape_list = get_area_turfs(locate(/area/horizon/shuttle/escape_pod))

	//Separated into separate procs for profiling
	AreaSet()
	MiscSet()
	APCSet()
	KillMobs()
	OverlayAndAmbientSet()
	SSskybox.change_skybox("narsie", new_use_stars = FALSE, new_use_overmap_details = FALSE)

	SScult.rune_boost += 9001	//basically removing the rune cap

/datum/universal_state/hell/proc/AreaSet()
	for(var/area/A in get_sorted_areas())
		if(!istype(A,/area) || istype(A, /area/space))
			continue

		A.queue_icon_update()
		CHECK_TICK

/datum/universal_state/hell/OverlayAndAmbientSet()
	set waitfor = FALSE
	for(var/turf/T in world)	// Expensive, but CHECK_TICK should prevent lag.
		if(istype(T, /turf/space))
			T.AddOverlays("hell01")
		else
			var/static/image/I = image('icons/turf/space.dmi', "hell01")
			T.underlays += I

		if (istype(T, /turf/simulated/floor) && !T.holy && prob(1))
			new /obj/effect/gateway/active/cult(T)

		CHECK_TICK

	for(var/datum/lighting_corner/C in SSlighting.lighting_corners)
		if (!C.active)
			continue

		C.update_lumcount(0.5, 0, 0)
		CHECK_TICK

/datum/universal_state/hell/proc/MiscSet()
	for (var/obj/machinery/firealarm/alm in SSmachinery.processing)
		if (!(alm.stat & BROKEN))
			alm.ex_act(2)
		CHECK_TICK

/datum/universal_state/hell/proc/APCSet()
	for (var/obj/machinery/power/apc/APC in SSmachinery.processing)
		if (!(APC.stat & BROKEN) && !APC.is_critical)
			APC.chargemode = 0
			if(APC.cell)
				APC.cell.charge = 0
			APC.emagged = 1
			APC.queue_icon_update()
		CHECK_TICK

/datum/universal_state/hell/proc/KillMobs()
	for(var/mob/living/simple_animal/M in GLOB.mob_list)
		if(M && !M.client)
			M.set_stat(DEAD)
		CHECK_TICK
