/obj/machinery/atmospherics/valve
	name = "manual valve"
	desc = "A pipe valve."
	icon = 'icons/atmos/valve.dmi'
	icon_state = "map_valve0"

	level = 1
	dir = SOUTH
	initialize_directions = SOUTH|NORTH

	var/open = 0
	var/openDuringInit = 0

	var/datum/pipe_network/network_node1
	var/datum/pipe_network/network_node2

/obj/machinery/atmospherics/valve/feedback_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "It is [open ? "open" : "closed"]."

/obj/machinery/atmospherics/valve/mechanics_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "Click this to turn the valve."
	. += "If red, the pipes on each end are seperated. Otherwise, they are connected."

/obj/machinery/atmospherics/valve/open
	open = 1
	icon_state = "map_valve1"

/obj/machinery/atmospherics/valve/update_icon(animation)
	if(animation)
		flick("valve[src.open][!src.open]",src)
	else
		icon_state = "valve[open]"

/obj/machinery/atmospherics/valve/update_underlays()
	if(..())
		underlays.Cut()
		var/turf/T = get_turf(src)
		if(!istype(T))
			return
		add_underlay(T, node1, get_dir(src, node1))
		add_underlay(T, node2, get_dir(src, node2))

/obj/machinery/atmospherics/valve/hide(var/i)
	update_underlays()

/obj/machinery/atmospherics/valve/Initialize()
	switch(dir)
		if(NORTH, SOUTH)
			initialize_directions = NORTH|SOUTH
		if(EAST, WEST)
			initialize_directions = EAST|WEST
	. = ..()

/obj/machinery/atmospherics/valve/network_expand(datum/pipe_network/new_network, obj/machinery/atmospherics/pipe/reference)
	if(reference == node1)
		network_node1 = new_network
		if(open)
			network_node2 = new_network
	else if(reference == node2)
		network_node2 = new_network
		if(open)
			network_node1 = new_network

	if(new_network.normal_members.Find(src))
		return 0

	new_network.normal_members += src

	if(open)
		if(reference == node1)
			if(node2)
				return node2.network_expand(new_network, src)
		else if(reference == node2)
			if(node1)
				return node1.network_expand(new_network, src)

	return null

/obj/machinery/atmospherics/valve/Destroy()
	loc = null

	if(node1)
		node1.disconnect(src)
		qdel(network_node1)
	if(node2)
		node2.disconnect(src)
		qdel(network_node2)

	node1 = null
	node2 = null

	return ..()

/obj/machinery/atmospherics/valve/proc/open()
	if(open) return 0

	open = 1
	update_icon()

	if(network_node1&&network_node2)
		network_node1.merge(network_node2)
		network_node2 = network_node1

	if(network_node1)
		network_node1.update = 1
	else if(network_node2)
		network_node2.update = 1

	return 1

/obj/machinery/atmospherics/valve/proc/close()
	if(!open)
		return 0

	open = 0
	update_icon()

	if(network_node1)
		qdel(network_node1)
	if(network_node2)
		qdel(network_node2)

	build_network()

	return 1

/obj/machinery/atmospherics/valve/proc/normalize_dir()
	if(dir==3)
		set_dir(1)
	else if(dir==12)
		set_dir(4)

/obj/machinery/atmospherics/valve/attack_ai(mob/user as mob)
	return

/obj/machinery/atmospherics/valve/attack_hand(mob/user as mob)
	src.add_fingerprint(usr)
	update_icon(1)
	sleep(10)
	if (src.open)
		src.close()
	else
		src.open()

/obj/machinery/atmospherics/valve/process()
	..()
	return PROCESS_KILL

/obj/machinery/atmospherics/valve/atmos_init()
	normalize_dir()

	var/node1_dir
	var/node2_dir

	for(var/direction in GLOB.cardinals)
		if(direction&initialize_directions)
			if (!node1_dir)
				node1_dir = direction
			else if (!node2_dir)
				node2_dir = direction

	for(var/obj/machinery/atmospherics/target in get_step(src,node1_dir))
		if(target.initialize_directions & get_dir(target,src))
			if (check_connect_types(target,src))
				node1 = target
				break
	for(var/obj/machinery/atmospherics/target in get_step(src,node2_dir))
		if(target.initialize_directions & get_dir(target,src))
			if (check_connect_types(target,src))
				node2 = target
				break

	build_network()

	queue_icon_update()
	update_underlays()

	if(openDuringInit)
		close()
		open()
		openDuringInit = 0

/obj/machinery/atmospherics/valve/build_network()
	if(!network_node1 && node1)
		network_node1 = new /datum/pipe_network()
		network_node1.normal_members += src
		network_node1.build_network(node1, src)

	if(!network_node2 && node2)
		network_node2 = new /datum/pipe_network()
		network_node2.normal_members += src
		network_node2.build_network(node2, src)

/obj/machinery/atmospherics/valve/return_network(obj/machinery/atmospherics/reference)
	build_network()

	if(reference==node1)
		return network_node1

	if(reference==node2)
		return network_node2

	return null

/obj/machinery/atmospherics/valve/reassign_network(datum/pipe_network/old_network, datum/pipe_network/new_network)
	if(network_node1 == old_network)
		network_node1 = new_network
	if(network_node2 == old_network)
		network_node2 = new_network

	return 1

/obj/machinery/atmospherics/valve/return_network_air(datum/pipe_network/reference)
	return null

/obj/machinery/atmospherics/valve/disconnect(obj/machinery/atmospherics/reference)
	if(reference==node1)
		qdel(network_node1)
		node1 = null

	else if(reference==node2)
		qdel(network_node2)
		node2 = null

	update_underlays()

	return null

/obj/machinery/atmospherics/valve/digital		// can be controlled by AI
	name = "digital valve"
	desc = "A digitally controlled valve."
	icon = 'icons/atmos/digital_valve.dmi'

	var/frequency = 0
	var/id = null
	var/datum/radio_frequency/radio_connection

/obj/machinery/atmospherics/valve/digital/attack_ai(mob/user as mob)
	if(!ai_can_interact(user))
		return
	return src.attack_hand(user)

/obj/machinery/atmospherics/valve/digital/attack_hand(mob/user as mob)
	if(!powered())
		return
	if(!src.allowed(user))
		to_chat(user, SPAN_WARNING("Access denied."))
		return
	..()

	log_and_message_admins("has [open ? SPAN_WARNING("OPENED") : "closed"] [name].", user)

/obj/machinery/atmospherics/valve/digital/AltClick(var/mob/abstract/ghost/observer/admin)
	if (istype(admin))
		if (admin.client && admin.client.holder && ((R_MOD|R_ADMIN) & admin.client.holder.rights))
			if (open)
				close()
			else
				if (alert(admin, "The valve is currently closed. Do you want to open it?", "Open the valve?", "Yes", "No") == "No")
					return
				open()

			log_and_message_admins("has [open ? "opened" : "closed"] [name].", admin)

/obj/machinery/atmospherics/valve/digital/open
	open = 1
	icon_state = "map_valve1"

/obj/machinery/atmospherics/valve/digital/power_change()
	var/old_stat = stat
	..()
	if(old_stat != stat)
		queue_icon_update()

/obj/machinery/atmospherics/valve/digital/update_icon()
	..()
	if(!powered())
		icon_state = "valve[open]nopower"

/obj/machinery/atmospherics/valve/digital/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	if(frequency)
		radio_connection = SSradio.add_object(src, frequency, RADIO_ATMOSIA)

/obj/machinery/atmospherics/valve/digital/atmos_init()
	..()
	if(frequency)
		set_frequency(frequency)

/obj/machinery/atmospherics/valve/digital/receive_signal(datum/signal/signal)
	if(!signal.data["tag"] || (signal.data["tag"] != id))
		return 0

	switch(signal.data["command"])
		if("valve_open")
			if(!open)
				open()

		if("valve_close")
			if(open)
				close()

		if("valve_toggle")
			if(open)
				close()
			else
				open()

/obj/machinery/atmospherics/valve/attackby(obj/item/attacking_item, mob/user)
	if (!attacking_item.iswrench())
		return ..()
	if (istype(src, /obj/machinery/atmospherics/valve/digital))
		to_chat(user, SPAN_WARNING("You cannot unwrench \the [src], it's too complicated."))
		return TRUE
	var/datum/gas_mixture/int_air = return_air()
	if (!loc) return FALSE
	var/datum/gas_mixture/env_air = loc.return_air()
	if ((int_air.return_pressure()-env_air.return_pressure()) > PRESSURE_EXERTED)
		to_chat(user, SPAN_WARNING("You cannot unwrench \the [src], it is too exerted due to internal pressure."))
		add_fingerprint(user)
		return TRUE
	to_chat(user, SPAN_NOTICE("You begin to unfasten \the [src]..."))
	if(attacking_item.use_tool(src, user, istype(attacking_item, /obj/item/pipewrench) ? 80 : 40, volume = 50))
		user.visible_message( \
			SPAN_NOTICE("\The [user] unfastens \the [src]."), \
			SPAN_NOTICE("You have unfastened \the [src]."), \
			"You hear a ratchet.")
		new /obj/item/pipe(loc, make_from=src)
		qdel(src)
		return TRUE
