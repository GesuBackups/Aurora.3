/datum/event/electrical_storm
	announceWhen = 0		// Warn them shortly before it begins.
	startWhen = 30
	endWhen = 60			// Set in start()
	ic_name = "an electrical storm"
	has_skybox_image = TRUE
	var/list/valid_apcs
	var/global/lightning_color

/datum/event/electrical_storm/Destroy(force)
	valid_apcs = null
	. = ..()

/datum/event/electrical_storm/get_skybox_image()
	if(!lightning_color)
		lightning_color = pick("#ffd98c", "#ebc7ff", "#bdfcff", "#bdd2ff", "#b0ffca", "#ff8178", "#ad74cc")
	var/image/res = overlay_image('icons/skybox/electrobox.dmi', "lightning", lightning_color, RESET_COLOR)
	res.blend_mode = BLEND_ADD
	return res

/datum/event/electrical_storm/announce()
	switch(severity)
		if(EVENT_LEVEL_MUNDANE)
			command_announcement.Announce("A minor electrical storm has been detected near the [location_name()]. Please watch out for possible electrical discharges.", "[location_name()] Sensor Array", new_sound = 'sound/AI/electrical_storm.ogg', zlevels = affecting_z)
		if(EVENT_LEVEL_MODERATE)
			command_announcement.Announce("The [location_name()] is about to pass through an electrical storm. Please secure sensitive electrical equipment until the storm passes.", "[location_name()] Sensor Array", new_sound = 'sound/AI/electrical_storm.ogg', zlevels = affecting_z)
		if(EVENT_LEVEL_MAJOR)
			command_announcement.Announce("Alert. A strong electrical storm has been detected in proximity of the [location_name()]. It is recommended to immediately secure sensitive electrical equipment until the storm passes.", "[location_name()] Sensor Array", new_sound = 'sound/AI/electrical_storm.ogg', zlevels = affecting_z)

/datum/event/electrical_storm/setup()
	valid_apcs = list()
	for(var/obj/machinery/power/apc/valid_apc in SSmachinery.apc_units)
		if((valid_apc.z in affecting_z) && !valid_apc.is_critical)
			valid_apcs += valid_apc
	endWhen = (severity * 60) + startWhen

/datum/event/electrical_storm/end(faked)
	..()

	valid_apcs = null

/datum/event/electrical_storm/tick()
	..()

	if(!length(valid_apcs))
		return

	var/list/picked_apcs = list()
	for(var/i=0, i< severity*2, i++) // up to 2/4/6 APCs per tick depending on severity
		picked_apcs |= pick(valid_apcs)

	for(var/obj/machinery/power/apc/T in picked_apcs)
		// Main breaker is turned off. Consider this APC protected.
		if(!T.operating)
			continue

		// Decent chance to overload lighting circuit.
		if(prob(3 * severity))
			T.overload_lighting()

		// Relatively small chance to emag the apc as apc_damage event does.
		if(prob(0.2 * severity))
			T.emagged = 1
			T.update_icon()

		T.energy_fail(10 * severity * rand(severity * 2, severity * 4))

		// Very tiny chance to completely break the APC. Has a check to ensure we don't break critical APCs such as the Engine room, or AI core. Does not occur on Mundane severity.
		if(prob((0.2 * severity) - 0.2))
			T.set_broken()

/datum/event/electrical_storm/announce_end()
	. = ..()
	if(.)
		command_announcement.Announce("The [location_name()] has cleared the electrical storm. Please repair any electrical overloads.", "Electrical Storm Alert", zlevels = affecting_z)
