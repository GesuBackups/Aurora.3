/*
This is /obj/machinery level code to properly manage power usage from the area.
*/

// Note that we update the area even if the area is unpowered.
#define REPORT_POWER_CONSUMPTION_CHANGE(old_power, new_power)\
	if(old_power != new_power){\
		var/area/A = get_area(src);\
		if(A) A.power_use_change(old_power, new_power, power_channel)}

// returns true if the area has power on given channel (or doesn't require power), defaults to power_channel.
// May also optionally specify an area, otherwise defaults to src.loc.loc
/obj/machinery/proc/powered(var/chan = -1, var/area/check_area = null)

	if(!src.loc)
		return 0

	//Don't do this. It allows machines that set use_power to 0 when off (many machines) to
	//be turned on again and used after a power failure because they never gain the NOPOWER flag.
	//if(!use_power)
	//	return 1

	if(!check_area)
		check_area = src.loc.loc		// make sure it's in an area
	if(!check_area || !isarea(check_area))
		return 0					// if not, then not powered
	if(chan == -1)
		chan = power_channel
	return check_area.powered(chan)			// return power status of the area

/// called whenever the power settings of the containing area change
/// by default, check equipment channel & set flag can override if needed
/// This is NOT for when the machine's own status changes; update_use_power for that.
/obj/machinery/proc/power_change()
	SHOULD_NOT_SLEEP(TRUE)
	SHOULD_CALL_PARENT(TRUE)

	var/oldstat = stat

	if(powered(power_channel))
		stat &= ~NOPOWER
	else
		stat |= NOPOWER

	. = (stat != oldstat)
	if(.)
		queue_icon_update()

/obj/machinery/proc/get_power_usage()
	if(internal)
		return 0

	switch(use_power)
		if(POWER_USE_IDLE)
			return idle_power_usage
		if(POWER_USE_ACTIVE)
			return active_power_usage
		else
			return 0

/**
 * This will have this machine have its area eat this much power next tick, and not afterwards
 *
 * Do not use for continued power draw.
 *
 * * amount - The amount of power to consume
 * * chan - The channel to consume it from, see `code\__DEFINES\machinery.dm`
 */
/obj/machinery/proc/use_power_oneoff(var/amount, var/chan = POWER_CHAN)
	var/area/A = get_area(src)		// make sure it's in an area
	if(!A)
		return
	if(chan == POWER_CHAN)
		chan = power_channel
	A.use_power_oneoff(amount, chan)

// Do not do power stuff in New/Initialize until after ..()
/obj/machinery/Initialize(mapload, d = 0, populate_components = TRUE, is_internal = FALSE)
	internal = is_internal
	REPORT_POWER_CONSUMPTION_CHANGE(0, get_power_usage())
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(update_power_on_move))
	power_init_complete = TRUE
	. = ..()

// Or in Destroy at all, but especially after the ..().
/obj/machinery/Destroy()
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
	REPORT_POWER_CONSUMPTION_CHANGE(get_power_usage(), 0)
	. = ..()

/obj/machinery/proc/update_power_on_move(atom/movable/mover, atom/old_loc, dir, forced, list/old_locs)
	area_changed(get_area(old_loc), get_area(src))

/obj/machinery/proc/area_changed(area/old_area, area/new_area)
	if(old_area == new_area)
		return
	var/power = get_power_usage()
	if(!power)
		return // This is the most likely case anyway.
	if(old_area)
		old_area.power_use_change(power, 0, power_channel)
	if(new_area)
		new_area.power_use_change(0, power, power_channel)
	power_change()

// The three procs below are the only allowed ways of modifying the corresponding variables.
/// Use this to modify the use_power variable of machines, do not modify them directly!
/obj/machinery/proc/update_use_power(new_use_power)
	if(!power_init_complete)
		use_power = new_use_power
		return
	if(use_power == new_use_power)
		return
	var/old_power = get_power_usage()
	use_power = new_use_power
	var/new_power = get_power_usage()
	REPORT_POWER_CONSUMPTION_CHANGE(old_power, new_power)

/// Use this to modify the power channel variable of machines, do not modify them directly!
/obj/machinery/proc/update_power_channel(new_channel)
	if(power_channel == new_channel)
		return
	if(!power_init_complete)
		power_channel = new_channel
		return
	var/power = get_power_usage()
	REPORT_POWER_CONSUMPTION_CHANGE(power, 0)
	power_channel = new_channel
	REPORT_POWER_CONSUMPTION_CHANGE(0, power)

/// Use this to modify either of the power usage variables of machines, do not modify them directly!
/obj/machinery/proc/change_power_consumption(new_power_consumption, use_power_mode = POWER_USE_IDLE)
	var/old_power
	switch(use_power_mode)
		if(POWER_USE_IDLE)
			old_power = idle_power_usage
			idle_power_usage = new_power_consumption
		if(POWER_USE_ACTIVE)
			old_power = active_power_usage
			active_power_usage = new_power_consumption
		else
			return
	if(power_init_complete && (use_power_mode == use_power))
		REPORT_POWER_CONSUMPTION_CHANGE(old_power, new_power_consumption)

#undef REPORT_POWER_CONSUMPTION_CHANGE
