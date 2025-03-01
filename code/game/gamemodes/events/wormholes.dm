/proc/wormhole_event()
	var/list/pick_turfs = list()
	for(var/turf/T in world)
		var/turf/simulated/floor/F = T
		if(istype(F) && is_station_level(F.z))
			pick_turfs += F

	if(pick_turfs.len)
		//All ready. Announce that bad juju is afoot.
		command_announcement.Announce("Space-time anomalies detected on the [station_name(TRUE)]. There is no additional data.", "Anomaly Alert", new_sound = 'sound/AI/spanomalies.ogg')

		//prob(20) can be approximated to 1 wormhole every 5 turfs!
		//admittedly less random but totally worth it >_<
		var/event_duration = 3000	//~5 minutes in ticks
		var/number_of_selections = (pick_turfs.len/5)+1	//+1 to avoid division by zero!
		var/sleep_duration = round( event_duration / number_of_selections )
		var/end_time = world.time + event_duration	//the time by which the event should have ended

		var/increment =	max(1,round(number_of_selections/50))

		var/i = 1
		while( 1 )

			//we've run into overtime. End the event
			if( end_time < world.time )
				return
			if( !pick_turfs.len )
				return

			//loop it round
			i += increment
			i %= pick_turfs.len
			i++

			//get our enter and exit locations
			var/turf/simulated/floor/enter = pick_turfs[i]
			pick_turfs -= enter							//remove it from pickable turfs list
			if( !enter || !istype(enter) )	continue	//sanity

			var/turf/simulated/floor/exit = pick(pick_turfs)
			pick_turfs -= exit
			if( !exit || !istype(exit) )	continue	//sanity

			create_wormhole(enter,exit)

			sleep(sleep_duration)						//have a well deserved nap!


//maybe this proc can even be used as an admin tool for teleporting players without ruining immulsions?
/proc/create_wormhole(var/turf/enter as turf, var/turf/exit as turf)
	var/obj/effect/portal/P = new /obj/effect/portal( enter )
	P.set_target(exit)
	P.creator = null
	P.icon = 'icons/obj/objects.dmi'
	P.failchance = 0
	P.icon_state = "anom"
	P.name = "wormhole"
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(qdel), P), rand(30, 60) SECONDS)
