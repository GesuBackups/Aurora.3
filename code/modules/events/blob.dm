/datum/event/blob
	announceWhen	= 12

	var/obj/effect/blob/core/Blob
	ic_name = "a biohazard"

/datum/event/blob/announce()
	level_seven_announcement(affecting_z)

/datum/event/blob/start()
	..()

	var/turf/T = pick_subarea_turf(/area/horizon/maintenance, list(/proc/is_station_turf, /proc/not_turf_contains_dense_objects))
	if(!T)
		log_and_message_admins("Blob failed to find a viable turf.")
		kill(TRUE)
		return

	log_and_message_admins("Blob spawned at \the [get_area(T)]", location = T)
	Blob = new /obj/effect/blob/core(T)
	for(var/i = 1; i < rand(3, 4), i++)
		Blob.process()

/datum/event/blob/tick()
	if(!Blob || !Blob.loc)
		Blob = null
		end()
		kill()
		return
	if(IsMultiple(activeFor, 3))
		Blob.process()
