
/proc/power_failure(var/announce = 1, var/severity = 2)
	if(announce)
		command_announcement.Announce("Abnormal activity detected in [station_name()]'s powernet. As a precautionary measure, the ship's power will be shut off for an indeterminate duration.", "Critical Power Failure", new_sound = 'sound/AI/poweroff.ogg')

	for(var/obj/machinery/power/smes/buildable/S in SSmachinery.smes_units)
		if(!S.is_critical)
			S.energy_fail(rand(15 * severity,30 * severity))


	for(var/obj/machinery/power/apc/C in SSmachinery.processing)
		if(!C.is_critical)
			C.energy_fail(rand(40 * severity,150 * severity))

/proc/power_restore(var/announce = 1)
	var/list/skipped_areas = list(/area/horizon/ai)

	if(announce)
		command_announcement.Announce("The ship's power subroutines have been stabilized and restored.", "Power Systems Nominal", new_sound = 'sound/AI/poweron.ogg')
	for(var/obj/machinery/power/apc/C in SSmachinery.processing)
		if(C.cell && is_station_level(C.z))
			C.cell.charge = C.cell.maxcharge
	for(var/obj/machinery/power/smes/S in SSmachinery.smes_units)
		var/area/current_area = get_area(S)
		if((current_area.type in skipped_areas) || !is_station_level(S.z))
			continue
		S.charge = S.capacity
		S.update_icon()
		S.power_change()

/proc/power_restore_quick(var/announce = 1)

	if(announce)
		command_announcement.Announce("The ship's power subroutines have been stabilized and restored.", "Power Systems Nominal", new_sound = 'sound/AI/poweron.ogg')
	for(var/obj/machinery/power/smes/S in SSmachinery.smes_units)
		if(!is_station_level(S.z))
			continue
		S.charge = S.capacity
		S.output_level = S.output_level_max
		S.output_attempt = 1
		S.input_attempt = 1
		S.update_icon()
		S.power_change()
