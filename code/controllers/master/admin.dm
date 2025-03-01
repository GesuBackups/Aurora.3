// Clickable stat() button.
/obj/effect/statclick
	name = "Initializing..."
	var/target

/obj/effect/statclick/New(loc, text, target)
	..()
	name = text
	src.target = target

/obj/effect/statclick/proc/update(text)
	name = text
	return src

/obj/effect/statclick/debug
	var/class

/obj/effect/statclick/debug/Click(location, control, params)
	if(!usr.client.holder || !target)
		return

	var/permit_mark = TRUE

	if(!class)
		if(istype(target, /datum/controller/subsystem))
			class = "subsystem"
		else if(istype(target, /datum/controller))
			class = "controller"
		else if(istype(target, /datum))
			class = "datum"
			permit_mark = FALSE
		else
			class = "unknown"
			permit_mark = FALSE

	var/list/paramlist = params2list(params)
	if (paramlist["shift"] && permit_mark && target)
		if (target in usr.client.holder.watched_processes)
			to_chat(usr, SPAN_NOTICE("[target] removed from watchlist."))
			LAZYREMOVE(usr.client.holder.watched_processes, target)
		else
			to_chat(usr, SPAN_NOTICE("[target] added to watchlist."))
			LAZYADD(usr.client.holder.watched_processes, target)
	else
		usr.client.debug_variables(target)
		message_admins("Admin [key_name_admin(usr)] is debugging the [target] [class].")

// Debug verbs.
/client/proc/restart_controller(controller in list("Master", "Failsafe"))
	set category = "Debug"
	set name = "Restart Controller"
	set desc = "Restart one of the various periodic loop controllers for the game (be careful!)"

	if(!check_rights(R_DEBUG|R_SERVER))
		return

	switch(controller)
		if("Master")
			new/datum/controller/master()
			feedback_add_details("admin_verb","RMC")
		if("Failsafe")
			new /datum/controller/failsafe()
			feedback_add_details("admin_verb","RFailsafe")

	message_admins("Admin [key_name_admin(usr)] has restarted the [controller] controller.")

// Subsystems that cmd_ss_panic can hard-restart.
// *MUST* have New() use NEW_SS_GLOBAL.
GLOBAL_LIST_INIT(panic_targets, list(
	"Garbage" = /datum/controller/subsystem/garbage,
	"Air" = /datum/controller/subsystem/air,
	"Explosives" = /datum/controller/subsystem/explosives,
	"Game Ticker" = /datum/controller/subsystem/ticker,
	"Timer" = /datum/controller/subsystem/timer,
	"Effects Master" = /datum/controller/subsystem/effects
))

// Subsystems that might do funny things or lose data if hard-restarted.
// Makes subsystem require an additional confirmation to restart.
GLOBAL_LIST_INIT(panic_targets_data_loss, list(
	"Game Ticker" = TRUE
))

/client/proc/cmd_ss_panic(controller in GLOB.panic_targets)
	set category = "Server"
	set name = "Force-Restart Subsystem"
	set desc = "Hard-restarts a subsystem. May break things, use with caution."

	if (!check_rights(R_DEBUG | R_SERVER))
		return

	if (alert("Hard-Restart [controller]? Use with caution, this may break things.", "Subsystem Restart", "No", "No", "Yes") != "Yes")
		to_chat(usr, "Aborted.")
		return

	// If it's marked as potentially causing data-loss (like SStimer), require another confirmation.
	if (GLOB.panic_targets_data_loss[controller])
		if (alert("This subsystem ([controller]) may cause data loss or strange behavior if restarted! Continue?", "AAAAAA", "No", "No", "Yes") != "Yes")
			to_chat(usr, "Aborted.")
			return

	log_and_message_admins(SPAN_DANGER("hard-restarted the [controller] subsystem."))
	LOG_DEBUG("SS PANIC: [controller] hard-restart by [usr]!")

	// NEW_SS_GLOBAL will handle destruction of old controller & data transfer, just create a new one and add it to the MC.
	var/ctype = GLOB.panic_targets[controller]
	Master.subsystems += new ctype

	sortTim(Master.subsystems, GLOBAL_PROC_REF(cmp_subsystem_display))
