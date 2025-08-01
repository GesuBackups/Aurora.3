/mob/living/carbon/human
	name = "unknown"
	real_name = "unknown"
	voice_name = "unknown"
	icon = 'icons/mob/human.dmi'
	icon_state = "body_m_s"

	mob_size = 9 //Based on average weight of a human

	var/pronouns = NEUTER

	var/species_items_equipped // used so species that need special items (autoinhalers for vaurca/RMT for offworlders) don't get them twice when they shouldn't.

	var/list/hud_list[11]
	var/embedded_flag	  //To check if we've need to roll for damage on movement while an item is imbedded in us.
	var/obj/item/rig/wearing_rig // This is very not good, but it's much much better than calling get_rig() every update_canmove() call.
	/// Pref holder for the speech bubble style.
	var/speech_bubble_type

/mob/living/carbon/human/Initialize(mapload, var/new_species = null)
	if(!dna)
		dna = new /datum/dna(null)
		// Species name is handled by set_species()

	if(!species)
		if(new_species)
			set_species(new_species, 1)
		else
			set_species()

	if(species)
		real_name = species.get_random_name(gender)
		name = real_name
		if(mind)
			mind.name = real_name
		if(get_hearing_sensitivity())
			add_verb(src, /mob/living/carbon/human/proc/listening_close)
		if(!height)
			height = species.species_height

	// Randomize nutrition and hydration. Defines are in __defines/mobs.dm
	if(max_nutrition > 0)
		nutrition = rand(CREW_MINIMUM_NUTRITION*100, CREW_MAXIMUM_NUTRITION*100) * max_nutrition * 0.01
	if(max_hydration > 0)
		hydration = rand(CREW_MINIMUM_HYDRATION*100, CREW_MAXIMUM_HYDRATION*100) * max_hydration * 0.01

	hud_list[HEALTH_HUD]      = new /image/hud_overlay('icons/hud/hud_med.dmi', src, "100")
	hud_list[STATUS_HUD]      = new /image/hud_overlay('icons/hud/hud.dmi', src, "hudhealthy")
	hud_list[ID_HUD]          = new /image/hud_overlay('icons/hud/hud_security.dmi', src, "hudunknown")
	hud_list[WANTED_HUD]      = new /image/hud_overlay('icons/hud/hud_security.dmi', src, "hudblank")
	hud_list[IMPLOYAL_HUD]    = new /image/hud_overlay('icons/hud/hud.dmi', src, "hudblank")
	hud_list[IMPCHEM_HUD]     = new /image/hud_overlay('icons/hud/hud.dmi', src, "hudblank")
	hud_list[IMPTRACK_HUD]    = new /image/hud_overlay('icons/hud/hud.dmi', src, "hudblank")
	hud_list[SPECIALROLE_HUD] = new /image/hud_overlay('icons/hud/hud.dmi', src, "hudblank")
	hud_list[STATUS_HUD_OOC]  = new /image/hud_overlay('icons/hud/hud.dmi', src, "hudhealthy")
	hud_list[LIFE_HUD]	      = new /image/hud_overlay('icons/hud/hud.dmi', src, "hudhealthy")
	hud_list[TRIAGE_HUD]      = new /image/hud_overlay('icons/hud/hud_med.dmi', src, triage_tag)

	//Scaling down the ID hud
	var/image/holder = hud_list[ID_HUD]
	holder.pixel_x = -3
	holder.pixel_y = 24
	hud_list[ID_HUD] = holder

	holder = hud_list[IMPLOYAL_HUD]
	holder.pixel_y = 2
	hud_list[IMPLOYAL_HUD] = holder

	holder = hud_list[IMPCHEM_HUD]
	holder.pixel_y = 2
	hud_list[IMPCHEM_HUD] = holder

	holder = hud_list[IMPTRACK_HUD]
	holder.pixel_y = 2
	hud_list[IMPTRACK_HUD] = holder


	holder = hud_list[WANTED_HUD]
	holder.pixel_x = -3
	holder.pixel_y = 14
	hud_list[WANTED_HUD] = holder


	GLOB.human_mob_list |= src

	. = ..()

	hide_underwear.Cut()
	for(var/category in GLOB.global_underwear.categories_by_name)
		hide_underwear[category] = FALSE

	if(dna)
		dna.ready_dna(src)
		dna.real_name = real_name
		sync_organ_dna()
	make_blood()

	pixel_x = species.icon_x_offset
	pixel_y = species.icon_y_offset

	if(length(species.unarmed_attacks))
		set_default_attack(species.unarmed_attacks[1])

/mob/living/carbon/human/Destroy(force)
	ghost_spawner = null

	//Srom (Shared Dreaming)
	srom_pulled_by = null
	srom_pulling = null
	bg = null //Just to be sure.

	GLOB.human_mob_list -= src
	GLOB.intent_listener -= src
	QDEL_LIST(organs)
	internal_organs_by_name = null
	internal_organs = null
	organs_by_name = null
	bad_internal_organs = null
	bad_external_organs = null

	QDEL_NULL(vessel)

	QDEL_NULL(DS)
	// qdel and null out our equipment.
	QDEL_NULL(shoes)
	QDEL_NULL(belt)
	QDEL_NULL(gloves)
	QDEL_NULL(glasses)
	QDEL_NULL(head)
	QDEL_NULL(l_ear)
	QDEL_NULL(r_ear)
	QDEL_NULL(wear_id)
	QDEL_NULL(r_store)
	QDEL_NULL(l_store)
	QDEL_NULL(s_store)
	QDEL_NULL(wear_suit)
	QDEL_NULL(wear_mask)
	// Do this last so the mob's stuff doesn't drop on del.
	QDEL_NULL(w_uniform)

	//Yes this is shit, but since someone had the brillant mind to use images for this, we must suffer
	if(length(hud_list))
		for(var/image/hud_overlay/an_hud_overlay in hud_list)
			if(an_hud_overlay.owner)
				an_hud_overlay.owner.client?.images -= an_hud_overlay
			an_hud_overlay.owner = null
			qdel(an_hud_overlay)
		hud_list = null

	. = ..()

/mob/living/carbon/human/can_devour(atom/movable/victim, var/silent = FALSE)
	if(!should_have_organ(BP_STOMACH))
		return ..()

	var/obj/item/organ/internal/stomach/stomach = internal_organs_by_name[BP_STOMACH]
	if(!stomach || !stomach.is_usable())
		if(!silent)
			to_chat(src, SPAN_WARNING("Your stomach is not functional!"))
		return FALSE

	if(!stomach.can_eat_atom(victim))
		if(!silent)
			to_chat(src, SPAN_WARNING("You are not capable of devouring \the [victim] whole!"))
		return FALSE

	if(stomach.is_full(victim))
		if(!silent)
			to_chat(src, SPAN_WARNING("Your [stomach.name] is full!"))
		return FALSE

	if(species?.gluttonous & GLUT_MESSY)
		if(ismob(victim))
			var/mob/M = victim
			if(ishuman(victim) && !islesserform(M))
				to_chat(src, SPAN_WARNING("You can't devour humanoids!"))
				return FALSE
			for(var/obj/item/grab/G in M.grabbed_by)
				if(G && G.state < GRAB_NECK)
					if(!silent)
						to_chat(src, SPAN_WARNING("You need a tighter hold on \the [M]!"))
					return FALSE

	. = stomach.get_devour_time(victim) || ..()

/mob/living/carbon/human/get_ingested_reagents()
	if(should_have_organ(BP_STOMACH))
		var/obj/item/organ/internal/stomach/stomach = internal_organs_by_name[BP_STOMACH]
		if(stomach)
			return stomach.ingested
	return touching

/mob/living/carbon/human/proc/metabolize_ingested_reagents()
	if(should_have_organ(BP_STOMACH))
		var/obj/item/organ/internal/stomach/stomach = internal_organs_by_name[BP_STOMACH]
		if(stomach)
			stomach.metabolize()

/mob/living/carbon/human/get_fullness()
	if(!should_have_organ(BP_STOMACH))
		return ..()
	var/obj/item/organ/internal/stomach/stomach = internal_organs_by_name[BP_STOMACH]
	if(stomach)
		return nutrition + stomach.ingested.total_volume
	return 0

/mob/living/carbon/human/get_status_tab_items()
	. = ..()

	/// This needs to be updated to use signals.
	var/holding_gps = FALSE
	if(istype(src.get_active_hand(), /obj/item/device/gps) || istype(src.get_inactive_hand(), /obj/item/device/gps))
		holding_gps = TRUE

	var/area/A = get_area(src)
	var/area_name
	if(holding_gps)
		area_name = get_area_display_name(A)
		. += "[area_name]"
		. += ""
	if(A.area_blurb)
		. += "[A.area_blurb]"
		. += ""
	. += "Intent: [a_intent]"
	. += "Move Mode: [m_intent]"
	if(is_diona() && DS)
		. += "Biomass: [round(nutrition)] / [max_nutrition]"
		. += "Energy: [round(DS.stored_energy)] / [round(DS.max_energy)]"
		if(DS.regen_limb)
			. += "Regeneration Progress: [round(DS.regen_limb_progress)] / [LIMB_REGROW_REQUIREMENT]"
	if(internal)
		if(!internal.air_contents)
			qdel(internal)
		else
			. += "Internal Atmosphere Info: [internal.name]"
			. += "Tank Pressure: [internal.air_contents.return_pressure()]"
			. += "Distribution Pressure: [internal.distribute_pressure]"

	var/obj/item/organ/internal/cell/IC = internal_organs_by_name[BP_CELL]
	if(IC && IC.cell)
		. += "Battery charge: [IC.get_charge()]/[IC.cell.maxcharge]"

	if(mind)
		var/datum/vampire/vampire = mind.antag_datums[MODE_VAMPIRE]
		if(vampire)
			. += "Usable Blood [vampire.blood_usable]"
			. += "Total Blood [vampire.blood_total]"
		var/datum/changeling/changeling = mind.antag_datums[MODE_CHANGELING]
		if(changeling)
			. += "Chemical Storage: [changeling.chem_charges]"
			. += "Genetic Damage Time: [changeling.geneticdamage]"

	if(. && istype(back,/obj/item/rig))
		var/obj/item/rig/R = back
		if(R && !R.canremove && R.installed_modules.len)
			var/cell_status = R.cell ? "[R.cell.charge]/[R.cell.maxcharge]" : "ERROR"
			. += "Suit Charge: [cell_status]"

	var/obj/item/technomancer_core/core = get_technomancer_core()
	if(core)
		var/charge_status = "[core.energy]/[core.max_energy] ([round( (core.energy / core.max_energy) * 100)]%) \
		([round(core.energy_delta)]/s)"
		var/instability_delta = instability - last_instability
		var/instability_status = "[src.instability] ([round(instability_delta, 0.1)]/s)"
		. += "Core Charge: [charge_status]"
		. += "User instability: [instability_status]"

/mob/living/carbon/human/ex_act(severity)
	if(!blinded)
		flash_act()

	var/b_loss = null
	var/f_loss = null

	if (is_diona() == DIONA_WORKER)//Thi
		diona_contained_explosion_damage(severity)

	switch (severity)
		if (1.0)
			b_loss += 500
			f_loss = 100
			var/atom/target = get_edge_target_turf(src, get_dir(src, get_step_away(src, src)))
			throw_at(target, 200, 4)

		if (2.0)
			b_loss = 60
			f_loss = 60

			if (!istype(l_ear, /obj/item/clothing/ears/earmuffs) && !istype(r_ear, /obj/item/clothing/ears/earmuffs))
				adjustEarDamage(30, 120)

			if (prob(70))
				Paralyse(10)

		if(3.0)
			b_loss = 30
			if (!istype(l_ear, /obj/item/clothing/ears/earmuffs) && !istype(r_ear, /obj/item/clothing/ears/earmuffs))
				adjustEarDamage(15, 60)
			if (prob(50))
				Paralyse(10)

	// focus most of the blast on one organ
	apply_damage(0.7 * b_loss, DAMAGE_BRUTE, null, DAMAGE_FLAG_EXPLODE, used_weapon = "Explosive blast")
	apply_damage(0.7 * f_loss, DAMAGE_BURN, null, DAMAGE_FLAG_EXPLODE, used_weapon = "Explosive blast")

	// distribute the remaining 30% on all limbs equally (including the one already dealt damage)
	apply_damage(0.3 * b_loss, DAMAGE_BRUTE, null, DAMAGE_FLAG_EXPLODE | DAMAGE_FLAG_DISPERSED, used_weapon = "Explosive blast")
	apply_damage(0.3 * f_loss, DAMAGE_BURN, null, DAMAGE_FLAG_EXPLODE | DAMAGE_FLAG_DISPERSED, used_weapon = "Explosive blast")

	UpdateDamageIcon()

/mob/living/carbon/human/proc/implant_loyalty(mob/living/carbon/human/M, override = FALSE) // Won't override by default.
	if(!GLOB.config.use_loyalty_implants && !override) return // Nuh-uh.

	var/obj/item/implant/mindshield/L
	if(isipc(M))
		L = new/obj/item/implant/mindshield/ipc(M)
	else
		L = new/obj/item/implant/mindshield(M)
	L.imp_in = M
	L.implanted = 1
	var/obj/item/organ/external/affected = M.organs_by_name[BP_HEAD]
	affected.implants += L
	L.part = affected
	L.implanted(src)

/mob/living/carbon/human/proc/is_loyalty_implanted(mob/living/carbon/human/M)
	for(var/L in M.contents)
		if(istype(L, /obj/item/implant/mindshield))
			for(var/obj/item/organ/external/O in M.organs)
				if(L in O.implants)
					return 1
	return 0

/mob/living/carbon/human/restrained()
	if (handcuffed)
		return 1
	if (istype(wear_suit, /obj/item/clothing/suit/straight_jacket))
		return 1
	return 0

/mob/living/carbon/human/show_inv(mob/user as mob)
	if(user.incapacitated() || !user.Adjacent(src))
		return

	var/obj/item/clothing/under/suit = null
	if(istype(w_uniform, /obj/item/clothing/under))
		suit = w_uniform

	user.set_machine(src)
	var/dat = "<B><HR><FONT size=3>[name]</FONT></B><BR><HR>"

	if(internals)
		dat += "<B>Internals: [internal ? "On" : "Off"]</B><BR>"

	if(suit)
		var/list/modes = list("Off" = 1, "Binary Sensors" = 2, "Vitals Tracker" = 3, "Tracking Beacon" = 4)
		dat += "<B>Suit Sensors: [modes[suit.sensor_mode + 1]]</B><BR>"

	if(internals || suit)
		dat += "<HR>"

	for(var/entry in species.hud.gear)
		var/list/slot_ref = species.hud.gear[entry]
		if((slot_ref["slot"] in list(slot_l_store, slot_r_store)))
			continue
		var/obj/item/thing_in_slot = get_equipped_item(slot_ref["slot"])
		dat += "<BR><B>[slot_ref["name"]]:</b> <a href='byond://?src=[REF(src)];item=[slot_ref["slot"]]'>[istype(thing_in_slot) ? thing_in_slot : "nothing"]</a>"

	dat += "<BR><HR>"

	if(species.hud.has_hands)
		dat += "<BR><b>Left hand:</b> <A href='byond://?src=[REF(src)];item=[slot_l_hand]'>[istype(l_hand) ? l_hand : "nothing"]</A>"
		dat += "<BR><b>Right hand:</b> <A href='byond://?src=[REF(src)];item=[slot_r_hand]'>[istype(r_hand) ? r_hand : "nothing"]</A>"

	var/has_mask // 0, no mask | 1, mask but it's down | 2, mask and it's ready
	var/has_helmet
	if(istype(wear_mask, /obj/item/clothing/mask))
		var/obj/item/clothing/mask/M = wear_mask
		has_mask = 1
		if(!M.hanging)
			has_mask = 2
	if(istype(head, /obj/item/clothing/head/helmet/space))
		has_helmet = TRUE

	var/has_tank
	if(istype(back, /obj/item/tank) || istype(belt, /obj/item/tank) || istype(s_store, /obj/item/tank))
		has_tank = TRUE

	if((has_mask == 2|| has_helmet) && has_tank)
		dat += "<BR><A href='byond://?src=[REF(src)];item=internals'>Toggle internals [internal ? "off" : "on"]</A>"

	// Other incidentals.
	if(istype(suit) && suit.has_sensor == 1)
		dat += "<BR><A href='byond://?src=[REF(src)];item=sensors'>Set sensors</A>"
	if(handcuffed)
		dat += "<BR><A href='byond://?src=[REF(src)];item=[slot_handcuffed]'>Handcuffed</A>"
	if(legcuffed)
		dat += "<BR><A href='byond://?src=[REF(src)];item=[slot_legcuffed]'>Legcuffed</A>"

	if(has_mask)
		var/obj/item/clothing/mask/M = wear_mask
		if(M.adjustable)
			dat += "<BR><A href='byond://?src=[REF(src)];item=mask'>Adjust mask</A>"
	if(has_tank && internal)
		dat += "<BR><A href='byond://?src=[REF(src)];item=tank'>Check air tank</A>"
	if(suit && LAZYLEN(suit.accessories))
		dat += "<BR><A href='byond://?src=[REF(src)];item=tie'>Remove accessory</A>"
	dat += "<BR><A href='byond://?src=[REF(src)];item=splints'>Remove splints</A>"
	dat += "<BR><A href='byond://?src=[REF(src)];item=pockets'>Empty pockets</A>"
	dat += species.get_strip_info("[REF(src)]")
	dat += "<BR><A href='byond://?src=[REF(user)];refresh=1'>Refresh</A>"
	dat += "<BR><A href='byond://?src=[REF(user)];mach_close=mob[name]'>Close</A>"

	var/datum/browser/mob_win = new(user, "mob[name]", capitalize_first_letters(name), 350, 550)
	mob_win.set_content(dat)
	mob_win.open()

// called when something steps onto a human
// this handles vehicles
/mob/living/carbon/human/on_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	..()

	if(istype(arrived, /obj/vehicle))
		var/obj/vehicle/V = arrived
		V.RunOver(src)

// Get rank from ID, ID inside PDA, PDA, ID in wallet, etc.
/mob/living/carbon/human/proc/get_authentification_rank(var/if_no_id = "No id", var/if_no_job = "No job")
	var/obj/item/card/id/id = GetIdCard()
	if(!istype(id))
		return if_no_id
	else
		return id.rank ? id.rank : if_no_job

//gets assignment from ID or ID inside PDA or PDA itself
//Useful when player do something with computers
/mob/living/carbon/human/proc/get_assignment(var/if_no_id = "No ID", var/if_no_job = "No Job")
	var/obj/item/card/id/I = GetIdCard()
	if(istype(I))
		return I.assignment ? I.assignment : if_no_job
	else
		return if_no_id

//gets name from ID or ID inside PDA or PDA itself
//Useful when player do something with computers
/mob/living/carbon/human/proc/get_authentification_name(var/if_no_id = "Unknown")
	var/obj/item/card/id/I = GetIdCard()
	if(istype(I))
		return I.registered_name
	else
		return if_no_id

//repurposed proc. Now it combines get_id_name() and get_face_name() to determine a mob's name variable. Made into a seperate proc as it'll be useful elsewhere
/mob/living/carbon/human/proc/get_visible_name()
	if( wear_mask && (wear_mask.flags_inv&HIDEFACE) )	//Wearing a mask which hides our face, use id-name if possible
		return get_id_name("Unknown")
	if( head && (head.flags_inv&HIDEFACE) )
		return get_id_name("Unknown")		//Likewise for hats
	var/face_name = get_face_name()
	var/id_name = get_id_name("")
	if(id_name && (id_name != face_name))
		return "[face_name] (as [id_name])"
	return face_name

//Returns "Unknown" if facially disfigured and real_name if not. Useful for setting name when polyacided or when updating a human's name variable
/mob/living/carbon/human/proc/get_face_name()
	var/obj/item/organ/external/head = get_organ(BP_HEAD)
	if(!head || head.disfigured || head.is_stump() || !real_name || (mutations & HUSK))	//disfigured. use id-name if possible
		return "Unknown"
	return real_name

//gets name from ID or PDA itself, ID inside PDA doesn't matter
//Useful when player is being seen by other mobs
/mob/living/carbon/human/proc/get_id_name(var/if_no_id = "Unknown")
	. = if_no_id
	var/obj/item/card/id/I = GetIdCard()
	if(I)
		return I.registered_name
	return

//gets ID card object from special clothes slot or null.
/mob/living/carbon/human/proc/get_idcard()
	if(wear_id)
		return wear_id.GetID()

/mob/living/carbon/human/electrocute_act(var/shock_damage, var/obj/source, var/base_siemens_coeff = 1.0, var/def_zone = null, var/tesla_shock = 0, var/ground_zero)
	var/list/damage_areas = list()
	if(status_flags & GODMODE)	return 0	//godmode

	if (!tesla_shock)
		shock_damage *= base_siemens_coeff
	if (shock_damage<1)
		return 0

	var/obj/item/organ/internal/augment/tesla/tesla = internal_organs_by_name[BP_AUG_TESLA]
	if(tesla?.check_shock())
		tesla.actual_charges = min(tesla.actual_charges+1, tesla.max_charges)
		return FALSE

	if(!def_zone)
		//The way this works is by damaging multiple areas in an "Arc" if no def_zone is provided. should be pretty easy to add more arcs if it's needed. though I can't imangine a situation that can apply.
		switch ((h_style == "Floorlength Braid" || h_style == "Very Long Hair") ? rand(1, 7) : rand(1, 6))
			if(1)
				damage_areas = list(BP_L_HAND, BP_L_ARM, BP_CHEST, BP_R_ARM, BP_R_HAND)
			if(2)
				damage_areas = list(BP_R_HAND, BP_R_ARM, BP_CHEST, BP_L_ARM, BP_L_HAND)
			if(3)
				damage_areas = list(BP_L_HAND, BP_L_ARM, BP_CHEST, BP_GROIN, BP_L_LEG, BP_L_FOOT)
			if(4)
				damage_areas = list(BP_L_HAND, BP_L_ARM, BP_CHEST, BP_GROIN, BP_R_LEG, BP_R_FOOT)
			if(5)
				damage_areas = list(BP_R_HAND, BP_R_ARM, BP_CHEST, BP_GROIN, BP_R_LEG, BP_R_FOOT)
			if(6)
				damage_areas = list(BP_R_HAND, BP_R_ARM, BP_CHEST, BP_GROIN, BP_L_LEG, BP_L_FOOT)
			if(7)//snowflake arc - only happens when they have long hair.
				damage_areas = list(BP_R_HAND, BP_R_ARM, BP_CHEST, BP_HEAD)
				h_style = "skinhead"
				visible_message(SPAN_WARNING("[src]'s hair gets a burst of electricty through it, burning and turning to dust!"), SPAN_DANGER("your hair burns as the current flows through it, turning to dust!"), SPAN_NOTICE("You hear a crackling sound, and smell burned hair!."))
				update_hair()
	else
		damage_areas = list(def_zone)

	if(!ground_zero)
		ground_zero = pick(damage_areas)

	if(!(ground_zero in damage_areas))
		damage_areas.Add(ground_zero) //sucks to suck, get more zappy time bitch

	var/obj/item/organ/external/contact = get_organ(check_zone(ground_zero))
	shock_damage *= get_siemens_coefficient_organ(contact)

	var/obj/item/organ/external/affecting
	for (var/area in damage_areas)
		affecting = get_organ(check_zone(area))
		var/emp_damage
		switch(shock_damage)
			if(-INFINITY to 5)
				emp_damage = FALSE
			if(6 to 49)
				emp_damage = EMP_LIGHT
			else
				emp_damage = EMP_HEAVY

		if(emp_damage)
			for(var/obj/item/organ/O in affecting.internal_organs)
				O.emp_act(emp_damage)
			for(var/obj/item/I in affecting.implants)
				I.emp_act(emp_damage)
			for(var/obj/item/I in affecting)
				I.emp_act(emp_damage)

		apply_damage(shock_damage, DAMAGE_BURN, area, used_weapon="Electrocution")
		shock_damage *= 0.4
		playsound(loc, /singleton/sound_category/spark_sound, 50, 1, -1)

	if (shock_damage > 15)
		visible_message(
		SPAN_WARNING("[src] was shocked by the [source]!"),
		SPAN_DANGER("You feel a powerful shock course through your body!"),
		SPAN_WARNING("You hear a heavy electrical crack.")
		)
		Stun(10)//This should work for now, more is really silly and makes you lay there forever
		Weaken(10)

	else
		visible_message(
		SPAN_WARNING("[src] was mildly shocked by the [source]."),
		SPAN_WARNING("You feel a mild shock course through your body."),
		SPAN_WARNING("You hear a light zapping.")
		)

	spark(loc, 5, GLOB.alldirs)

	return shock_damage

/mob/living/carbon/human/Topic(href, href_list)
	if (href_list["refresh"])
		if((machine)&&(in_range(src, usr)))
			show_inv(machine)

	if (href_list["mach_close"])
		var/t1 = "window=[href_list["mach_close"]]"
		unset_machine()
		src << browse(null, t1)

	if(href_list["item"])
		handle_strip(href_list["item"],usr)

	if(href_list["species"])
		species.handle_strip(usr, src, href_list["species"])

	if(href_list["criminal"])
		if(hasHUD(usr,"security"))

			var/modified = 0
			var/perpname = "wot"
			if(wear_id)
				var/obj/item/card/id/I = wear_id.GetID()
				if(I)
					perpname = I.registered_name
				else
					perpname = name
			else
				perpname = name

			if(perpname)
				var/datum/record/general/R = SSrecords.find_record("name", perpname)
				if(istype(R) && istype(R.security))
					var/setcriminal = tgui_input_list(usr, "Specify a new criminal status for this person.", "Security HUD", list("None", "*Arrest*", "Search", "Incarcerated", "Parolled", "Released", "Cancel"))
					if(hasHUD(usr, "security"))
						if(setcriminal != "Cancel")
							R.security.criminal = setcriminal
							modified = 1
							BITSET(hud_updateflag, WANTED_HUD)
							if(istype(usr,/mob/living/carbon/human))
								var/mob/living/carbon/human/U = usr
								U.handle_regular_hud_updates()
							if(istype(usr,/mob/living/silicon/robot))
								var/mob/living/silicon/robot/U = usr
								U.handle_regular_hud_updates()

			if(!modified)
				to_chat(usr, EXAMINE_BLOCK_RED(SPAN_WARNING("Unable to locate a data core entry for this person.")))

	if (href_list["secrecord"])
		if(hasHUD(usr,"security"))
			var/perpname = "wot"
			var/read = 0

			if(GetIdCard())
				var/obj/item/card/id/id = GetIdCard()
				perpname = id.registered_name
			else
				perpname = src.name
			var/datum/record/general/R = SSrecords.find_record("name", perpname)
			if(istype(R) && istype(R.security))
				if(hasHUD(usr,"security"))
					var/message = "<b>Security Records: [R.name]</b>\n\n" \
						+ "<b>Criminal Status:</b> [R.security.criminal]\n" \
						+ "<b>Crimes:</b> [R.security.crimes]\n" \
						+ "<b>Notes:</b> [R.security.notes]\n" \
						+ "<a href='byond://?src=[REF(src)];secrecordComment=`'>\[View Comment Log\]</a>"
					to_chat(usr, EXAMINE_BLOCK_RED(message))
					read = 1

			if(!read)
				to_chat(usr, EXAMINE_BLOCK_RED(SPAN_WARNING("Unable to locate a data core entry for this person.")))

	if (href_list["secrecordComment"])
		if(hasHUD(usr,"security"))
			var/perpname = "wot"
			var/read = 0

			if(GetIdCard())
				var/obj/item/card/id/id = GetIdCard()
				perpname = id.registered_name
			else
				perpname = src.name
			var/datum/record/general/R = SSrecords.find_record("name", perpname)
			if(istype(R) && istype(R.security))
				if(hasHUD(usr, "security"))
					var/message = "<b>Security Record Comments: [name]</b>\n\n"
					read = 1
					if(R.security.comments.len > 0)
						for(var/comment in R.security.comments)
							message += comment + "\n\n"
					else
						message += "No comments found.\n"
					message += "<a href='byond://?src=[REF(src)];secrecordadd=`'>\[Add Comment\]</a>"
					to_chat(usr, EXAMINE_BLOCK_RED(message))

			if(!read)
				to_chat(usr, EXAMINE_BLOCK_RED(SPAN_WARNING("Unable to locate a data core entry for this person.")))

	if (href_list["secrecordadd"])
		if(hasHUD(usr,"security"))
			var/perpname = "wot"
			if(GetIdCard())
				var/obj/item/card/id/id = GetIdCard()
				perpname = id.registered_name
			else
				perpname = src.name
			var/datum/record/general/R = SSrecords.find_record("name", perpname)
			if(istype(R) && istype(R.security))
				var/t1 = sanitize(input("Add Comment:", "Sec. records", null, null)  as message)
				if ( !(t1) || usr.stat || usr.restrained() || !(hasHUD(usr,"security")) )
					return
				if(istype(usr,/mob/living/carbon/human))
					var/mob/living/carbon/human/U = usr
					R.security.comments += "Made by [U.get_authentification_name()] ([U.get_assignment()]) on [time2text(world.realtime, "DDD MMM DD hh:mm:ss")], [GLOB.game_year]<BR>[t1]"
				if(istype(usr,/mob/living/silicon/robot))
					var/mob/living/silicon/robot/U = usr
					R.security.comments += "Made by [U.name] ([U.mod_type] [U.braintype]) on [time2text(world.realtime, "DDD MMM DD hh:mm:ss")], [GLOB.game_year]<BR>[t1]"

	if (href_list["medical"])
		if(hasHUD(usr,"medical"))
			var/perpname = "wot"
			var/modified = 0

			if(GetIdCard())
				var/obj/item/card/id/id = GetIdCard()
				perpname = id.registered_name
			else
				perpname = src.name

			var/datum/record/general/R = SSrecords.find_record("name", perpname)
			if(istype(R))
				var/setmedical = tgui_input_list(usr, "Specify a new medical status for this person.", "Medical HUD", list("*SSD*", "*Deceased*", "*Missing*", "Physically Unfit", "Active", "Disabled", "Cancel"), R.physical_status)

				if(hasHUD(usr,"medical"))
					if(!isnull(setmedical) && setmedical != "Cancel")
						R.physical_status = setmedical
						modified = 1
						SSrecords.reset_manifest()
						if(istype(usr,/mob/living/carbon/human))
							var/mob/living/carbon/human/U = usr
							U.handle_regular_hud_updates()
						if(istype(usr,/mob/living/silicon/robot))
							var/mob/living/silicon/robot/U = usr
							U.handle_regular_hud_updates()

			if(!modified)
				to_chat(usr, EXAMINE_BLOCK_DEEP_CYAN(SPAN_WARNING("Unable to locate a data core entry for this person.")))

	if (href_list["medrecord"])
		if(hasHUD(usr,"medical"))
			var/perpname = "wot"
			var/read = 0

			if(GetIdCard())
				var/obj/item/card/id/id = GetIdCard()
				perpname = id.registered_name
			else
				perpname = src.name
			var/datum/record/general/R = SSrecords.find_record("name", perpname)
			if(istype(R) && istype(R.medical))
				if(hasHUD(usr, "medical"))
					var/message = "<b>Medical Records: [R.name]</b>\n\n" \
						+ "<b>Name:</b> [R.name] <b>Blood Type:</b> [R.medical.blood_type]\n" \
						+ "<b>DNA:</b> [R.medical.blood_dna]\n" \
						+ "<b>Disabilities:</b> [R.medical.disabilities]\n" \
						+ "<b>Notes:</b> [R.medical.notes]\n" \
						+ "<a href='byond://?src=[REF(src)];medrecordComment=`'>\[View Comment Log\]</a>"
					to_chat(usr, EXAMINE_BLOCK_DEEP_CYAN(message))
					read = 1

			if(!read)
				to_chat(usr, EXAMINE_BLOCK_DEEP_CYAN(SPAN_WARNING("Unable to locate a data core entry for this person.")))

	if (href_list["medrecordComment"])
		if(hasHUD(usr,"medical"))
			var/perpname = "wot"
			var/read = 0

			if(GetIdCard())
				var/obj/item/card/id/id = GetIdCard()
				perpname = id.registered_name
			else
				perpname = src.name
			var/datum/record/general/R = SSrecords.find_record("name", perpname)
			if(istype(R) && istype(R.medical))
				if(hasHUD(usr, "medical"))
					var/message = "<b>Medical Record Comments: [name]</b>\n\n"
					read = 1
					if(R.medical.comments.len > 0)
						for(var/comment in R.medical.comments)
							message += comment + "\n\n"
					else
						message += "No comments found.\n"
					message += "<a href='byond://?src=[REF(src)];medrecordadd=`'>\[Add Comment\]</a>"
					to_chat(usr, EXAMINE_BLOCK_DEEP_CYAN(message))

			if(!read)
				to_chat(usr, EXAMINE_BLOCK_DEEP_CYAN(SPAN_WARNING("Unable to locate a data core entry for this person.")))

	if (href_list["medrecordadd"])
		if(hasHUD(usr,"medical"))
			var/perpname = "wot"
			if(GetIdCard())
				var/obj/item/card/id/id = GetIdCard()
				perpname = id.registered_name
			else
				perpname = src.name
			var/datum/record/general/R = SSrecords.find_record("name", perpname)
			if(istype(R) && istype(R.medical))
				var/t1 = sanitize(input("Add Comment:", "Med. records", null, null)  as message)
				if ( !(t1) || use_check(usr) || !(hasHUD(usr,"medical")) )
					return
				if(ishuman(usr))
					var/mob/living/carbon/human/U = usr
					R.medical.comments += "Made by [U.get_authentification_name()] ([U.get_assignment()]) on [time2text(world.realtime, "DDD MMM DD hh:mm:ss")], [GLOB.game_year]<BR>[t1]"
				if(isrobot(usr))
					var/mob/living/silicon/robot/U = usr
					R.medical.comments += "Made by [U.name] ([U.mod_type] [U.braintype]) on [time2text(world.realtime, "DDD MMM DD hh:mm:ss")], [GLOB.game_year]<BR>[t1]"

	if(href_list["triagetag"])
		if(hasHUD(usr, "medical"))
			var/static/list/tags = list()
			if(!length(tags))
				for(var/thing in list(TRIAGE_NONE, TRIAGE_GREEN, TRIAGE_YELLOW, TRIAGE_RED, TRIAGE_BLACK))
					tags[thing] = image(icon = 'icons/mob/screen/triage_tag.dmi', icon_state = thing)
			var/chosen_tag = show_radial_menu(usr, src, tags, radius = 42, tooltips = TRUE)
			if(chosen_tag)
				triage_tag = chosen_tag
			BITSET(hud_updateflag, HEALTH_HUD)
			handle_hud_list()

	if (href_list["lookitem"])
		var/obj/item/I = locate(href_list["lookitem"])
		if(!I)
			return
		examinate(src, I)

	if (href_list["lookitem_desc_only"])
		var/obj/item/I = locate(href_list["lookitem_desc_only"])
		if(!I)
			return
		examinate(usr, I)

	if (href_list["lookmob"])
		var/mob/M = locate(href_list["lookmob"])
		if(!M)
			return
		examinate(src, M)

	if (href_list["flavor_change"])
		if(src != usr)
			log_and_message_admins("attempted to use a exploit to change the flavor text of [src]", usr)
			return
		switch(href_list["flavor_change"])
			if("done")
				src << browse(null, "window=flavor_changes")
				return
			if("general")
				var/msg = sanitize(input(usr,"Update the general description of your character. This will be shown regardless of clothing, and may include OOC notes and preferences.","Flavor Text",html_decode(flavor_texts[href_list["flavor_change"]])) as message, extra = 0)
				flavor_texts[href_list["flavor_change"]] = msg
				return
			else
				var/msg = sanitize(input(usr,"Update the flavor text for your [href_list["flavor_change"]].","Flavor Text",html_decode(flavor_texts[href_list["flavor_change"]])) as message, extra = 0)
				flavor_texts[href_list["flavor_change"]] = msg
				set_flavor()
				return

	if (href_list["metadata"])
		var/message = "<b>OOC Notes: [name]</b>" \
			+ "\n\n" \
			+ client.prefs.metadata \
			+ "\n\n" \
			+ SPAN_WARNING("Remember, this is OOC information.")
		to_chat(usr, EXAMINE_BLOCK(message))

	if(href_list["default_attk"])
		if(href_list["default_attk"] == "reset_attk")
			set_default_attack(null)
		else
			var/datum/unarmed_attack/u_attack = locate(href_list["default_attk"])
			if(u_attack && (u_attack in species.unarmed_attacks))
				set_default_attack(u_attack)
		check_attacks()
		return 1

	..()
	return

///eyecheck()
///Returns a number between -1 to 2
/mob/living/carbon/human/get_flash_protection(ignore_inherent = FALSE)

	//Ling
	var/datum/changeling/changeling = changeling_power(0, 0, 0)
	if(changeling && changeling.using_thermals)
		return FLASH_PROTECTION_REDUCED

	if(!species.vision_organ || !species.has_organ[species.vision_organ]) //No eyes, can't hurt them.
		return FLASH_PROTECTION_MAJOR

	var/obj/item/organ/I = get_eyes()	// Eyes are fucked, not a 'weak point'.
	if (I && I.status & ORGAN_CUT_AWAY)
		return FLASH_PROTECTION_MAJOR

	if (!ignore_inherent && species.inherent_eye_protection)
		. = max(species.inherent_eye_protection, flash_protection)
	else
		return flash_protection

	if(HAS_TRAIT(src, TRAIT_ORIGIN_LIGHT_SENSITIVE))
		return max(. - 1, FLASH_PROTECTION_REDUCED)

/mob/living/carbon/human/flash_act(intensity = FLASH_PROTECTION_MODERATE, override_blindness_check = FALSE, affect_silicon = FALSE, ignore_inherent = FALSE, type = /atom/movable/screen/fullscreen/flash, length = 2.5 SECONDS)
	if(..())
		var/obj/item/organ/E = get_eyes(no_synthetic = !affect_silicon)
		if(istype(E))
			return E.flash_act(intensity, override_blindness_check, affect_silicon, ignore_inherent, type, length)
	else if(intensity == get_flash_protection(ignore_inherent))
		if(prob(20))
			to_chat(src, SPAN_NOTICE("Something bright flashes in the corner of your vision!"))

//Used by various things that knock people out by applying blunt trauma to the head.
//Checks that the species has a BP_HEAD (brain containing organ) and that hit_zone refers to it.
/mob/living/carbon/human/proc/headcheck(var/target_zone, var/brain_tag = BP_BRAIN)
	if(!species.has_organ[brain_tag])
		return 0

	var/obj/item/organ/affecting = internal_organs_by_name[brain_tag]

	target_zone = check_zone(target_zone)
	if(!affecting || affecting.parent_organ != target_zone)
		return 0

	//if the parent organ is significantly larger than the brain organ, then hitting it is not guaranteed
	var/obj/item/organ/parent = get_organ(target_zone)
	if(!parent)
		return 0

	if(parent.w_class > affecting.w_class + 1)
		return prob(100 / 2**(parent.w_class - affecting.w_class - 1))

	return 1

/mob/living/carbon/human/IsAdvancedToolUser(var/silent)

	if(is_berserk())
		if(!silent)
			to_chat(src, SPAN_WARNING("You are in no state to use that!"))
		return FALSE

	if(!species.has_fine_manipulation)
		if(!silent)
			to_chat(src, SPAN_WARNING("You don't have the dexterity to use that!"))
		return FALSE

	if(lobotomized)
		if(!silent)
			to_chat(src, SPAN_WARNING("You are in no state to use that!"))
		return FALSE

	return TRUE

/mob/living/carbon/human/abiotic(var/full_body = 0)
	if(full_body && ((src.l_hand && !( src.l_hand.abstract )) || (src.r_hand && !( src.r_hand.abstract )) || (src.back || src.wear_mask || src.head || src.shoes || src.w_uniform || src.wear_suit || src.glasses || src.l_ear || src.r_ear || src.gloves)))
		return 1

	if( (src.l_hand && !src.l_hand.abstract) || (src.r_hand && !src.r_hand.abstract) )
		return 1

	return 0


/mob/living/carbon/human/proc/check_dna()
	dna.check_integrity(src)
	return

/mob/living/carbon/human/get_species(var/reference = FALSE, var/records = FALSE)
	if(!species)
		set_species()
	return species.get_species(reference, src, records)

/mob/living/carbon/human/proc/play_xylophone()
	if(!src.xylophone)
		visible_message(SPAN_WARNING("\The [src] begins playing [get_pronoun("his")] ribcage like a xylophone. It's quite spooky."), SPAN_NOTICE("You begin to play a spooky refrain on your ribcage."), SPAN_WARNING("You hear a spooky xylophone melody."))
		var/song = pick('sound/effects/xylophone1.ogg','sound/effects/xylophone2.ogg','sound/effects/xylophone3.ogg')
		playsound(loc, song, 50, 1, -1)
		xylophone = 1
		spawn(1200)
			xylophone=0
	return

/mob/living/carbon/human/proc/check_has_mouth()
	// Todo, check stomach organ when implemented.
	var/obj/item/organ/external/E = get_organ(BP_HEAD)
	if(E && !E.is_stump())
		var/obj/item/organ/external/head/H = E
		if(!H.can_intake_reagents)
			return FALSE
	return TRUE

/mob/living/proc/empty_stomach()
	return

/mob/living/carbon/human/empty_stomach()
	Stun(3)

	var/obj/item/organ/internal/stomach/stomach = internal_organs_by_name[BP_STOMACH]
	var/nothing_to_puke = FALSE
	if(should_have_organ(BP_STOMACH))
		if(!istype(stomach) || (stomach.ingested.total_volume <= 3 && !length(stomach.contents)) && nutrition <= 50)
			nothing_to_puke = TRUE
	else if(!(locate(/mob) in contents))
		nothing_to_puke = TRUE

	if(nothing_to_puke)
		custom_emote(VISIBLE_MESSAGE,"dry heaves.")
		return

	var/list/vomitCandidate = typecacheof(/obj/machinery/disposal) + typecacheof(/obj/structure/sink) + typecacheof(/obj/structure/toilet)
	var/obj/vomitReceptacle
	for(var/obj/vessel in view(1, src))
		if(!is_type_in_typecache(vessel, vomitCandidate))
			continue
		if(!vessel.Adjacent(src))
			continue
		vomitReceptacle = vessel
		break

	var/obj/effect/decal/cleanable/vomit/splat
	if(vomitReceptacle)
		src.visible_message(SPAN_WARNING("[src] vomits into \the [vomitReceptacle]!"), SPAN_WARNING("You vomit into \the [vomitReceptacle]!"))
		splat = new /obj/effect/decal/cleanable/vomit(vomitReceptacle)
	else
		src.visible_message(SPAN_WARNING("\The [src] vomits!"), SPAN_WARNING("You vomit!"))
		var/turf/location = loc
		if(istype(location, /turf/simulated))
			splat = new /obj/effect/decal/cleanable/vomit(location)

	if(should_have_organ(BP_STOMACH))
		for(var/a in stomach.contents)
			var/atom/movable/A = a
			if(vomitReceptacle)
				A.dropInto(vomitReceptacle)
			else
				A.dropInto(get_turf(src))
			if((species.gluttonous & GLUT_PROJECTILE_VOMIT) && !vomitReceptacle)
				A.throw_at(get_edge_target_turf(src,dir),7,7,src)
		nutrition -= 20
	else
		for(var/mob/M in contents)
			if(vomitReceptacle)
				M.dropInto(vomitReceptacle)
			else
				M.dropInto(get_turf(src))
			if((species.gluttonous & GLUT_PROJECTILE_VOMIT) && !vomitReceptacle)
				M.throw_at(get_edge_target_turf(src,dir),7,7,src)

	if(istype(splat))
		if(stomach.ingested.total_volume)
			stomach.ingested.trans_to_obj(splat, min(15, stomach.ingested.total_volume))
		for(var/obj/item/organ/internal/parasite/P in src.internal_organs)
			if(P)
				if(P.egg && (P.stage == P.max_stage))
					splat.reagents.add_reagent(P.egg, 2)
		handle_additional_vomit_reagents(splat)
		splat.update_icon()

		playsound(get_turf(src), 'sound/effects/splat.ogg', 50, 1)

/mob/living/carbon/human/proc/vomit(var/timevomit = 1, var/level = 3, var/deliberate = FALSE)

	set waitfor = 0

	if(!check_has_mouth() || isSynthetic() || !timevomit || !level || stat == DEAD || lastpuke)
		return

	if(chem_effects[CE_ANTIEMETIC])
		to_chat(src, SPAN_WARNING("You feel a very brief wave of nausea, but it quickly disapparates."))
		return

	if(deliberate)
		if(incapacitated())
			to_chat(src, SPAN_WARNING("You cannot do that right now."))
			return
		visible_message(SPAN_WARNING("\The [src] retches a bit..."))
		if(!do_after(src, 30))
			return
		timevomit = max(timevomit, 5)

	timevomit = clamp(timevomit, 1, 10)
	level = clamp(level, 1, 3)

	lastpuke = TRUE
	to_chat(src, SPAN_WARNING("You feel nauseous..."))
	if(level > 1)
		sleep(150 / timevomit)	//15 seconds until second warning
		to_chat(src, SPAN_WARNING("You feel like you are about to throw up!"))
		if(level > 2)
			sleep(100 / timevomit)	//and you have 10 more for mad dash to the bucket
			empty_stomach()
	sleep(350)	//wait 35 seconds before next volley
	lastpuke = FALSE

// A damaged stomach can put blood in your vomit.
/mob/living/carbon/human/handle_additional_vomit_reagents(obj/effect/decal/cleanable/vomit/vomit)
	..()
	if(should_have_organ(BP_STOMACH))
		var/obj/item/organ/internal/stomach/stomach = internal_organs_by_name[BP_STOMACH]
		if(!stomach || stomach.is_broken() || (stomach.is_bruised() && prob(stomach.damage)))
			if(should_have_organ(BP_HEART))
				vessel.trans_to_obj(vomit, 5)
			else
				reagents.trans_to_obj(vomit, 5)

/mob/living/carbon/human/get_digestion_product()
	return species.get_digestion_product(src)

/mob/living/carbon/human/proc/morph()
	set name = "Morph"
	set category = "Superpower"

	if(stat!=CONSCIOUS)
		reset_view(0)
		remoteview_target = null
		return

	if(!(mutations & mMorph))
		remove_verb(src, /mob/living/carbon/human/proc/morph)
		return

	var/new_facial = input("Please select facial hair color.", "Character Generation",rgb(r_facial,g_facial,b_facial)) as color
	if(new_facial)

		r_facial = hex2num(copytext(new_facial, 2, 4))
		g_facial = hex2num(copytext(new_facial, 4, 6))
		b_facial = hex2num(copytext(new_facial, 6, 8))

	var/new_hair = input("Please select hair color.", "Character Generation",rgb(r_hair,g_hair,b_hair)) as color
	if(new_facial)
		r_hair = hex2num(copytext(new_hair, 2, 4))
		g_hair = hex2num(copytext(new_hair, 4, 6))
		b_hair = hex2num(copytext(new_hair, 6, 8))

	var/new_eyes = input("Please select eye color.", "Character Generation",rgb(r_eyes,g_eyes,b_eyes)) as color
	if(new_eyes)
		r_eyes = hex2num(copytext(new_eyes, 2, 4))
		g_eyes = hex2num(copytext(new_eyes, 4, 6))
		b_eyes = hex2num(copytext(new_eyes, 6, 8))
		update_eyes()

	var/new_tone = input("Please select skin tone level: 1-220 (1=albino, 35=caucasian, 150=black, 220='very' black)", "Character Generation", "[35-s_tone]")  as text

	if (!new_tone)
		new_tone = 35
	s_tone = max(min(round(text2num(new_tone)), 220), 1)
	s_tone =  -s_tone + 35

	// hair
	var/list/all_hairs = typesof(/datum/sprite_accessory/hair) - /datum/sprite_accessory/hair
	var/list/hairs = list()

	// loop through potential hairs
	for(var/x in all_hairs)
		var/datum/sprite_accessory/hair/H = new x // create new hair datum based on type x
		hairs.Add(H.name) // add hair name to hairs
		qdel(H) // delete the hair after it's all done

	var/new_style = input("Please select hair style", "Character Generation",h_style)  as null|anything in hairs

	// if new style selected (not cancel)
	if (new_style)
		h_style = new_style

	// facial hair
	var/list/all_fhairs = typesof(/datum/sprite_accessory/facial_hair) - /datum/sprite_accessory/facial_hair
	var/list/fhairs = list()

	for(var/x in all_fhairs)
		var/datum/sprite_accessory/facial_hair/H = new x
		fhairs.Add(H.name)
		qdel(H)

	new_style = input("Please select facial style", "Character Generation",f_style)  as null|anything in fhairs

	if(new_style)
		f_style = new_style

	var/new_gender = alert(usr, "Please select gender.", "Character Generation", "Male", "Female")
	if (new_gender)
		if(new_gender == "Male")
			gender = MALE
		else
			gender = FEMALE
	regenerate_icons()
	check_dna()

	visible_message(SPAN_NOTICE("\The [src] morphs and changes [get_pronoun("his")] appearance!"), SPAN_NOTICE("You change your appearance!"), SPAN_WARNING("Oh, god!  What the hell was that?  It sounded like flesh getting squished and bone ground into a different shape!"))

/mob/living/carbon/human/proc/remotesay()
	set name = "Project mind"
	set category = "Superpower"

	if(stat!=CONSCIOUS)
		reset_view(0)
		remoteview_target = null
		return

	if(!(mutations & mRemotetalk))
		remove_verb(src, /mob/living/carbon/human/proc/remotesay)
		return
	var/list/creatures = list()
	for(var/hh in GLOB.human_mob_list)
		var/mob/living/carbon/human/H = hh
		if (H.client)
			creatures += hh

	var/mob/target = input("Who do you want to project your mind to ?") as null|anything in creatures
	if (isnull(target))
		return

	var/say = sanitize(input("What do you wish to say"))
	if((target.mutations & mRemotetalk))
		target.show_message(SPAN_NOTICE("You hear [src.real_name]'s voice: [say]"))
	else
		target.show_message(SPAN_NOTICE("You hear a voice that seems to echo around the room: [say]"))
	usr.show_message(SPAN_NOTICE("You project your mind into [target.real_name]: [say]"))
	log_say("[key_name(usr)] sent a telepathic message to [key_name(target)]: [say]")
	for(var/mob/abstract/ghost/observer/G in GLOB.dead_mob_list)
		G.show_message("<i>Telepathic message from <b>[src]</b> to <b>[target]</b>: [say]</i>")

/mob/living/carbon/human/proc/remoteobserve()
	set name = "Remote View"
	set category = "Superpower"

	if(stat!=CONSCIOUS)
		remoteview_target = null
		reset_view(0)
		return

	if(!(mutations & mRemote))
		remoteview_target = null
		reset_view(0)
		remove_verb(src, /mob/living/carbon/human/proc/remoteobserve)
		return

	if(client.eye != client.mob)
		remoteview_target = null
		reset_view(0)
		return

	var/list/mob/creatures = list()

	for(var/h in GLOB.human_mob_list)
		var/mob/living/carbon/human/H = h
		if (!H.client)
			continue

		var/turf/temp_turf = get_turf(H)
		if((temp_turf.z != 1 && temp_turf.z != 5) || H.stat!=CONSCIOUS) //Not on mining or the station. Or dead
			continue
		creatures += h

	var/mob/target = input ("Who do you want to project your mind to ?") as mob in creatures

	if (target)
		remoteview_target = target
		reset_view(target)
	else
		remoteview_target = null
		reset_view(0)

/mob/living/carbon/human/succumb()
	set hidden = TRUE

	if(shock_stage > 50 && (maxHealth * 0.6) > get_total_health())
		adjustBrainLoss(health + maxHealth * 2) // Deal 2x health in BrainLoss damage, as before but variable.
		to_chat(src, SPAN_NOTICE("You have given up life and succumbed to death."))
	else
		to_chat(src, SPAN_WARNING("You are not injured enough to succumb to death!"))

/mob/living/carbon/human/get_gender()
	var/skipitems = get_covered_clothes()
	var/skipbody = get_covered_body_parts(TRUE)
	if((skipbody & FACE || (skipitems & (HIDEMASK|HIDEFACE))) && ((skipbody & UPPER_TORSO && skipbody & LOWER_TORSO) || (skipitems & HIDEJUMPSUIT))) //big suits/masks/helmets make it hard to tell their gender
		return PLURAL
	return pronouns

/mob/living/carbon/human/proc/increase_germ_level(n)
	if(gloves)
		gloves.germ_level += n
	else
		germ_level += n

/mob/living/carbon/human/revive(reset_to_roundstart = TRUE)

	if(species && !(species.flags & NO_BLOOD))
		vessel.add_reagent(/singleton/reagent/blood,560-vessel.total_volume, temperature = species.body_temperature)
		fixblood()

	// Fix up all organs.
	species.create_organs(src)

	var/datum/preferences/prefs
	if (client)
		prefs = client.prefs
	else if (ckey)	// Mob might be logged out.
		prefs = GLOB.preferences_datums[ckey(ckey)]	// run the ckey through ckey() here so that aghosted mobs can be rejuv'd too. (Their ckeys are prefixed with @)

	if (prefs && real_name == prefs.real_name)
		// Re-apply the mob's markings and prosthetics if their pref is their current char.
		sync_organ_prefs_to_mob(prefs, reset_to_roundstart)	// Don't apply prosthetics if we're a ling rejuving.

	if(!client || !key) //Don't boot out anyone already in the mob.
		for (var/obj/item/organ/internal/brain/H in world)
			if(H.brainmob)
				if(H.brainmob.real_name == src.real_name)
					if(H.brainmob.mind)
						H.brainmob.mind.transfer_to(src)
						H.brainmob.client.init_verbs()
						qdel(H)

	losebreath = 0
	shock_stage = 0

	//Fix husks
	mutations &= ~HUSK
	status_flags &= ~DISFIGURED	//Fixes the unknown status
	if(src.client)
		SSjobs.EquipAugments(src, src.client.prefs)
	update_body(1)
	update_eyes()

	..()

/mob/living/carbon/human/handle_breath(datum/gas_mixture/breath)
	if(status_flags & GODMODE)
		return

	if(!species.has_organ[BP_LUNGS])
		return

	var/species_organ = species.breathing_organ
	if(!species_organ)
		return

	var/obj/item/organ/internal/lungs/L = internal_organs_by_name[species_organ]

	if(!L || nervous_system_failure())
		failed_last_breath = TRUE
	else
		failed_last_breath = L.handle_breath(breath)

	return !failed_last_breath

/mob/living/carbon/human/proc/is_lung_ruptured()
	var/species_organ = species.breathing_organ
	var/obj/item/organ/internal/lungs/L = internal_organs_by_name[species_organ]
	return L && L.is_bruised()

/mob/living/carbon/human/proc/rupture_lung()
	var/species_organ = species.breathing_organ
	var/obj/item/organ/internal/lungs/L = internal_organs_by_name[species_organ]
	if(L && !L.is_bruised())
		custom_pain("You feel a stabbing pain in your chest!", 50)
		L.bruise()

/mob/living/carbon/human/proc/is_lung_rescued()
	var/species_organ = species.breathing_organ
	var/obj/item/organ/internal/lungs/L = internal_organs_by_name[species_organ]
	return L && L.rescued

//returns 1 if made bloody, returns 0 otherwise
/mob/living/carbon/human/add_blood(mob/living/carbon/C as mob)
	if (!..())
		return FALSE
	//if this blood isn't already in the list, add it
	hand_blood_color = COLOR_HUMAN_BLOOD
	if(ishuman(C))
		var/mob/living/carbon/human/H = C
		if(!blood_DNA[H.dna.unique_enzymes])
			blood_DNA[H.dna.unique_enzymes] = H.dna.b_type
		hand_blood_color = H.get_blood_color()
	src.update_inv_gloves()	//handles bloody hands overlays and updating
	add_verb(src, /mob/living/carbon/human/proc/bloody_doodle)
	return TRUE //we applied blood to the item

/mob/living/carbon/human/proc/get_full_print()
	if(!dna ||!dna.uni_identity)
		return
	return md5(dna.uni_identity)

/mob/living/carbon/human/clean_blood(var/clean_feet)
	.=..()
	if(gloves)
		if(gloves.clean_blood())
			update_inv_gloves(1)
		gloves.germ_level = 0
	else
		if(!isnull(bloody_hands))
			bloody_hands = null
			update_inv_gloves(1)
		germ_level = 0

	LAZYCLEARLIST(gunshot_residue)
	if(clean_feet && !shoes)
		footprint_color = null
		feet_blood_DNA = null
		track_footprint = 0
		update_inv_shoes(1)

	if(blood_color)
		blood_color = null
		return 1

/mob/living/carbon/human/get_visible_implants(var/class = 0)

	var/list/visible_implants = list()
	for(var/obj/item/organ/external/organ in src.organs)
		for(var/obj/item/O in organ.implants)
			if(!istype(O,/obj/item/implant) && (O.w_class > class) && !istype(O,/obj/item/material/shard/shrapnel))
				visible_implants += O

	return(visible_implants)

/mob/living/carbon/human/embedded_needs_process()
	for(var/obj/item/organ/external/organ in src.organs)
		for(var/obj/item/O in organ.implants)
			if(!istype(O, /obj/item/implant)) //implant type items do not cause embedding effects, see handle_embedded_objects()
				return 1
	return 0

/mob/living/carbon/human/proc/handle_embedded_objects()

	for(var/obj/item/organ/external/organ in src.organs)
		if(organ.status & ORGAN_SPLINTED) //Splints prevent movement.
			continue
		for(var/obj/item/O in organ.implants)
			if(m_intent == "run" && !istype(O, /obj/item/implant) && prob(5)) //Moving quickly with things stuck in you could be bad.
				if(!can_feel_pain())
					to_chat(src, SPAN_WARNING("You feel [O] moving inside your [organ.name]."))
				else
					var/msg = pick( \
						SPAN_WARNING("A spike of pain jolts your [organ.name] as you bump [O] inside."), \
						SPAN_WARNING("Your movement jostles [O] in your [organ.name] painfully."), \
						SPAN_WARNING("Your movement jostles [O] in your [organ.name] painfully.") \
					)
					custom_pain(msg, 10, 10, organ)
				organ.take_damage(rand(1, 3), 0, DAMAGE_FLAG_EDGE)

/mob/living/carbon/human/verb/check_pulse()
	set category = "Object"
	set name = "Check pulse"
	set desc = "Approximately count somebody's pulse. Requires you to stand still at least 6 seconds."
	set src in view(1)
	var/self = 0

	if(usr.stat || usr.restrained() || !isliving(usr)) return

	if(usr == src)
		self = 1

	if ((src.species.flags & NO_BLOOD) || (status_flags & FAKEDEATH))
		to_chat(usr, SPAN_WARNING(self ? "You have no pulse." : "[src] has no pulse!"))
		return

	if(!self)
		usr.visible_message(SPAN_NOTICE("[usr] kneels down, puts [usr.get_pronoun("his")] hand on [src]'s wrist and begins counting their pulse."),\
		"You begin counting [src]'s pulse")
	else
		usr.visible_message(SPAN_NOTICE("[usr] begins counting their pulse."),\
		"You begin counting your pulse.")

	if(pulse())
		to_chat(usr, SPAN_NOTICE("[self ? "You have a" : "[src] has a"] pulse! Counting..."))
	else
		to_chat(usr, SPAN_WARNING("[src] has no pulse!"))	//it is REALLY UNLIKELY that a dead person would check his own pulse)
		return

	to_chat(usr, "You must[self ? "" : " both"] remain still until counting is finished.")
	if(do_mob(usr, src, 60))
		var/pulsae = src.get_pulse(GETPULSE_HAND)
		var/introspect = self ? "Your" : "[src]'s"
		to_chat(usr, SPAN_NOTICE("[introspect] pulse is [pulsae]."))
	else
		to_chat(usr, SPAN_WARNING("You failed to check the pulse. Try again."))

/mob/living/carbon/human/proc/set_species(var/new_species, var/default_colour, var/kpg=0, var/change_hair = TRUE)
	cached_bodytype = null
	if(!dna)
		if(!new_species)
			new_species = SPECIES_HUMAN
	else
		if(!new_species)
			new_species = dna.species
		else
			dna.species = new_species

	// No more invisible screaming wheelchairs because of set_species() typos.
	if(!GLOB.all_species[new_species])
		new_species = SPECIES_HUMAN

	if(species)

		if(species.name && species.name == new_species)
			return
		if(species.language)
			remove_language(species.language)
		if(species.default_language)
			remove_language(species.default_language)
		// Clear out their species abilities.
		species.remove_inherent_verbs(src)
		holder_type = null

	species = GLOB.all_species[new_species]

	if(species.language)
		add_language(species.language)

	if(species.default_language)
		add_language(species.default_language)

	if(species.base_color && default_colour)
		//Apply colour.
		r_skin = hex2num(copytext(species.base_color,2,4))
		g_skin = hex2num(copytext(species.base_color,4,6))
		b_skin = hex2num(copytext(species.base_color,6,8))
	else
		r_skin = 0
		g_skin = 0
		b_skin = 0

	if(species.holder_type)
		holder_type = species.holder_type

	//Clear out the manouvers of the previous specie and add the one of the current specie
	available_maneuvers = null
	if(species?.maneuvers)
		available_maneuvers = species.maneuvers.Copy()

	icon_state = lowertext(species.name)

	species.create_organs(src)

	species.handle_post_spawn(src,kpg) // should be zero by default

	maxHealth = species.total_health
	health = maxHealth

	regenerate_icons()
	if (vessel)
		restore_blood()

	// Rebuild the HUD and visual elements.
	if(client)
		LateLogin()

	if (src.is_diona())
		setup_gestalt(1)

	burn_mod = species.burn_mod
	brute_mod = species.brute_mod

	max_stamina = species.stamina
	if(HAS_TRAIT(src, TRAIT_ORIGIN_STAMINA_BONUS))
		max_stamina *= 1.1
	stamina = max_stamina
	sprint_speed_factor = species.sprint_speed_factor
	sprint_cost_factor = species.sprint_cost_factor
	stamina_recovery = species.stamina_recovery

	exhaust_threshold = species.exhaust_threshold
	max_nutrition = BASE_MAX_NUTRITION * species.max_nutrition_factor
	max_hydration = BASE_MAX_HYDRATION * species.max_hydration_factor

	nutrition_loss = HUNGER_FACTOR * species.nutrition_loss_factor
	hydration_loss = THIRST_FACTOR * species.hydration_loss_factor

	speech_bubble_type = species.possible_speech_bubble_types[1]
	if(typing_indicator)
		adjust_typing_indicator_offsets(typing_indicator)

	if(change_hair)
		h_style = random_hair_style(gender, species.type)

	if(prob(10))
		f_style = random_facial_hair_style(gender, species.type)

	if(length(species.character_color_presets) && !default_colour)
		var/preset_name = pick(species.character_color_presets)
		var/preset_colour = species.character_color_presets[preset_name]
		r_skin = GetRedPart(preset_colour)
		g_skin = GetGreenPart(preset_colour)
		b_skin = GetBluePart(preset_colour)
		change_skin_tone(35 - rand(30, 220))

	fill_random_culture_data()

	species.set_default_tail(src)

	if(species.psi_deaf || (species.flags & IS_MECHANICAL) || (species.flags & NO_SCAN))
		ADD_TRAIT(src, TRAIT_PSIONICALLY_DEAF, INNATE_TRAIT)
	else if(HAS_TRAIT(src, TRAIT_PSIONICALLY_DEAF))
		REMOVE_TRAIT(src, TRAIT_PSIONICALLY_DEAF, INNATE_TRAIT)

	if(psi && species.character_creation_psi_points && species.has_psionics)
		psi.psi_points = max(species.character_creation_psi_points - psi.spent_psi_points, 0) //to prevent species-switching for more points

	if(client)
		client.init_verbs()

	update_emotes()

	if(species)
		return TRUE
	else
		return FALSE

/mob/living/carbon/human/proc/fill_out_culture_data()
	set_culture(GET_SINGLETON(species.possible_cultures[1]))
	set_origin(GET_SINGLETON(culture.possible_origins[1]))
	accent = pick(origin.possible_accents)
	citizenship = origin.possible_citizenships[1]
	religion = origin.possible_religions[1]

/mob/living/carbon/human/proc/fill_random_culture_data()
	var/new_culture_type = pick(species.possible_cultures)
	var/culture_singleton = GET_SINGLETON(new_culture_type)
	set_culture(culture_singleton)
	var/new_origin = pick(culture.possible_origins)
	var/origin_singleton = GET_SINGLETON(new_origin)
	set_origin(origin_singleton)
	accent = pick(origin.possible_accents)
	citizenship = pick(origin.possible_citizenships)
	religion = pick(origin.possible_religions)

/mob/living/carbon/human/proc/bloody_doodle()
	set category = "IC"
	set name = "Write in blood"
	set desc = "Use blood on your hands to write a short message on the floor or a wall, murder mystery style."

	if (src.stat)
		return

	if (usr != src)
		return 0 //something is terribly wrong

	if (!bloody_hands)
		remove_verb(src, /mob/living/carbon/human/proc/bloody_doodle)

	if (src.gloves)
		to_chat(src, SPAN_WARNING("Your [src.gloves] are getting in the way."))
		return

	var/turf/simulated/T = src.loc
	if (!istype(T)) //to prevent doodling out of mechs and lockers
		to_chat(src, SPAN_WARNING("You cannot reach the floor."))
		return

	var/direction = input(src,"Which way?","Tile selection") as anything in list("Here","North","South","East","West")
	if (direction != "Here")
		T = get_step(T,text2dir(direction))
	if (!istype(T) || !Adjacent(T))
		to_chat(src, SPAN_WARNING("You cannot doodle there."))
		return

	var/num_doodles = 0
	for (var/obj/effect/decal/cleanable/blood/writing/W in T)
		num_doodles++
	if (num_doodles > 4)
		to_chat(src, SPAN_WARNING("There is no space to write on!"))
		return

	var/max_length = bloody_hands * 30 //tweeter style

	var/message = sanitize(input("Write a message. It cannot be longer than [max_length] characters.","Blood writing", ""))

	if (message)
		if(!Adjacent(T))
			to_chat(src, SPAN_WARNING("You're too far away!"))
			return
		var/used_blood_amount = round(length(message) / 30, 1)
		bloody_hands = max(0, bloody_hands - used_blood_amount) //use up some blood

		if (length(message) > max_length)
			message += "-"
			to_chat(src, SPAN_WARNING("You ran out of blood to write with!"))

		var/obj/effect/decal/cleanable/blood/writing/W = new(T)
		W.basecolor = (hand_blood_color) ? hand_blood_color : COLOR_HUMAN_BLOOD
		W.update_icon()
		W.message = message
		W.add_fingerprint(src)

/mob/living/carbon/human/can_inject(var/mob/user, var/error_msg, var/target_zone, var/handle_coverage = TRUE)
	. = BASE_INJECTION_MOD

	if(!target_zone)
		if(!user)
			target_zone = pick(BP_CHEST, BP_CHEST, BP_CHEST, BP_L_LEG, BP_R_LEG, BP_L_ARM, BP_R_ARM, BP_HEAD)
		else
			target_zone = user.zone_sel.selecting

	. *= species.get_injection_modifier()

	var/obj/item/organ/external/affecting = get_organ(target_zone)
	var/fail_msg
	if(!affecting)
		. = INJECTION_FAIL
		fail_msg = "They are missing that limb."
	else if (affecting.status & ORGAN_ROBOT)
		. = INJECTION_FAIL
		fail_msg = "That limb is robotic."
	else if (handle_coverage)
		. *= get_bp_coverage(target_zone)
		if(isvaurca(src) && . == SUIT_INJECTION_MOD)
			user.visible_message("<b>[user]</b> begins hunting for an injection port on \the [src]'s carapace.")
		else if(. >= SUIT_INJECTION_MOD)
			user.visible_message("<b>[user]</b> begins hunting for \the [src]'s injection port.")
	if(!. && error_msg && user)
		if(!fail_msg)
			fail_msg = "There is no exposed skin nor thin material on \the [affecting.loc]'s [target_zone] to inject into."
		to_chat(user, SPAN_ALERT("[fail_msg]"))

/mob/living/carbon/human/proc/get_bp_coverage(var/bp)
	. = BASE_INJECTION_MOD
	var/static/list/bp_to_coverage = list(
		BP_HEAD = HEAD,
		BP_EYES = EYES,
		BP_MOUTH = FACE,
		BP_CHEST = UPPER_TORSO,
		BP_GROIN = LOWER_TORSO,
		BP_L_ARM = (ARMS|ARM_LEFT),
		BP_R_ARM = (ARMS|ARM_RIGHT),
		BP_L_HAND = (HANDS|HAND_LEFT),
		BP_R_HAND = (HANDS|HAND_RIGHT),
		BP_L_LEG = (LEGS|LEG_LEFT),
		BP_R_LEG = (LEGS|LEG_RIGHT),
		BP_L_FOOT = (FEET|FOOT_LEFT),
		BP_R_FOOT = (FEET|FOOT_RIGHT)
	)
	for(var/obj/item/C in list(wear_suit, head, wear_mask, w_uniform, gloves, shoes))
		var/injection_modifier = BASE_INJECTION_MOD
		if(C.item_flags & ITEM_FLAG_INJECTION_PORT)
			injection_modifier = SUIT_INJECTION_MOD
		else if(C.item_flags & ITEM_FLAG_THICK_MATERIAL)
			injection_modifier = INJECTION_FAIL
		if(. == SUIT_INJECTION_MOD && injection_modifier != INJECTION_FAIL) // don't reset it back to the base, unless it completely blocks
			continue
		if(C.body_parts_covered & bp_to_coverage[bp])
			. = injection_modifier
		if(. == INJECTION_FAIL)
			return

/mob/living/carbon/human/print_flavor_text(var/shrink = 1)
	var/list/equipment = list(src.head,src.wear_mask,src.glasses,src.w_uniform,src.wear_suit,src.gloves,src.shoes)
	var/head_exposed = 1
	var/face_exposed = 1
	var/eyes_exposed = 1
	var/torso_exposed = 1
	var/arms_exposed = 1
	var/legs_exposed = 1
	var/hands_exposed = 1
	var/feet_exposed = 1

	for(var/obj/item/clothing/C in equipment)
		if(C.item_flags & ITEM_FLAG_SHOW_FLAVOR_TEXT)
			continue

		if(C.body_parts_covered & HEAD)
			head_exposed = 0
		if(C.body_parts_covered & FACE)
			face_exposed = 0
		if(C.body_parts_covered & EYES)
			eyes_exposed = 0
		if(C.body_parts_covered & UPPER_TORSO)
			torso_exposed = 0
		if(C.body_parts_covered & ARMS)
			arms_exposed = 0
		if(C.body_parts_covered & HANDS)
			hands_exposed = 0
		if(C.body_parts_covered & LEGS)
			legs_exposed = 0
		if(C.body_parts_covered & FEET)
			feet_exposed = 0

	flavor_text = ""
	for (var/T in flavor_texts)
		if(flavor_texts[T] && flavor_texts[T] != "")
			if((T == "general") || (T == BP_HEAD && head_exposed) || (T == "face" && face_exposed) || (T == BP_EYES && eyes_exposed) || (T == "torso" && torso_exposed) || (T == "arms" && arms_exposed) || (T == "hands" && hands_exposed) || (T == "legs" && legs_exposed) || (T == "feet" && feet_exposed))
				flavor_text += flavor_texts[T]
				flavor_text += "\n\n"
	if(!shrink)
		return flavor_text
	else
		return ..()

/mob/living/carbon/human/getDNA()
	if(species.flags & NO_SCAN)
		return null
	..()

/mob/living/carbon/human/setDNA()
	if(species.flags & NO_SCAN)
		return
	..()

/mob/living/carbon/human/has_brain()
	if(internal_organs_by_name[BP_BRAIN])
		var/obj/item/organ/brain = internal_organs_by_name[BP_BRAIN] // budget fix until MMIs and stuff get made internal or you think of a better way, sorry matt
		if(brain && istype(brain))
			return 1
	return 0

/mob/living/carbon/human/has_eyes()
	var/obj/item/organ/internal/eyes = get_eyes()
	if(istype(eyes) && !(eyes.status & ORGAN_CUT_AWAY))
		return 1
	return 0

/mob/living/carbon/human/slip(var/slipped_on, stun_duration=8)
	if((species.flags & NO_SLIP) || (shoes && (shoes.item_flags & ITEM_FLAG_NO_SLIP)))
		return 0
	. = ..(slipped_on,stun_duration)

/mob/living/carbon/human/proc/undislocate()
	set category = "Object"
	set name = "Undislocate Joint"
	set desc = "Pop a joint back into place. Extremely painful."
	set src in view(1)

	if(!isliving(usr) || !usr.canClick())
		return

	usr.setClickCooldown(20)

	if(usr.stat > 0)
		to_chat(usr, "You are unconcious and cannot do that!")
		return

	if(usr.restrained())
		to_chat(usr, "You are restrained and cannot do that!")
		return

	var/mob/S = src
	var/mob/U = usr
	var/self = null
	if(S == U)
		self = 1 // Removing object from yourself.

	var/list/limbs = list()
	for(var/limb in organs_by_name)
		var/obj/item/organ/external/current_limb = organs_by_name[limb]
		if(current_limb && current_limb.dislocated == 2)
			limbs |= limb
	var/choice = tgui_input_list(usr, "Which joint do you wish to relocate?", "Relocate Joint", limbs)

	if(!choice)
		return

	var/obj/item/organ/external/current_limb = organs_by_name[choice]

	if(self)
		U.visible_message(SPAN_WARNING("[U] tries to relocate their [current_limb.joint]..."), \
		SPAN_WARNING("You brace yourself to relocate your [current_limb.joint]..."))
	else
		U.visible_message(SPAN_WARNING("[U] tries to relocate [S]'s [current_limb.joint]..."), \
		SPAN_WARNING("You begin to relocate [S]'s [current_limb.joint]..."))

	if(!do_after(U, 30))
		return
	if(!choice || !current_limb || !S || !U)
		return

	if(self)
		U.visible_message(SPAN_DANGER("[U] pops their [current_limb.joint] back in!"), \
		SPAN_DANGER("You pop your [current_limb.joint] back in!"))
		playsound(src.loc, /singleton/sound_category/fracture_sound, 50, 1, -2)
	else
		U.visible_message(SPAN_DANGER("[U] pops [S]'s [current_limb.joint] back in!"), \
		SPAN_DANGER("You pop [S]'s [current_limb.joint] back in!"))
		playsound(src.loc, /singleton/sound_category/fracture_sound, 50, 1, -2)
	current_limb.undislocate()

/mob/living/carbon/human/drop_from_inventory(var/obj/item/W, var/atom/target = null)
	if(W in organs)
		return
	..()

/mob/living/carbon/human/reset_view(atom/A, update_hud = 1)
	..()
	if(update_hud)
		handle_regular_hud_updates()
	if(eyeobj)
		eyeobj.remove_visual(src)


/mob/living/carbon/human/can_stand_overridden()
	if(wearing_rig && wearing_rig.ai_can_move_suit(check_for_ai = 1))
		// Actually missing a leg will screw you up. Everything else can be compensated for.
		for(var/limbcheck in list(BP_L_LEG,BP_R_LEG))
			var/obj/item/organ/affecting = get_organ(limbcheck)
			if(!affecting)
				return 0
		return 1
	return 0

/mob/living/carbon/human/proc/can_drink(var/obj/item/I)
	if(!check_has_mouth())
		to_chat(src, SPAN_NOTICE("Where do you intend to put \the [I]? You don't have a mouth!"))
		return FALSE
	var/obj/item/blocked = check_mouth_coverage()
	if(blocked)
		to_chat(src, SPAN_WARNING("\The [blocked] is in the way!"))
		return FALSE
	return TRUE

/mob/living/carbon/human/mouse_drop_dragged(atom/over, mob/user, src_location, over_location, params)
	if(ishuman(over))
		var/mob/living/carbon/human/H = over
		if(holder_type && istype(H) && H.a_intent == I_HELP && !H.lying && !issmall(H) && Adjacent(H))
			get_scooped(H, (user == src))
			return
	return ..()

/mob/living/carbon/human/AltClickOn(var/atom/A)
	var/doClickAction = 1
	if (istype(get_active_hand(), /obj/item))
		var/obj/item/I = get_active_hand()
		doClickAction = I.alt_attack(A,src)

	if (doClickAction)
		..()

/mob/living/carbon/human/AltClick(mob/user)
	. = ..()
	if(hasHUD(user, MED_HUDTYPE))
		Topic(src, list("triagetag"=1))

/mob/living/carbon/human/verb/toggle_underwear()
	set name = "Toggle Underwear"
	set desc = "Shows/hides selected parts of your underwear."
	set category = "Object"

	if(stat)
		return
	var/datum/category_group/underwear/UWC = tgui_input_list(usr, "Choose underwear.", "Show/Hide Underwear", GLOB.global_underwear.categories)
	if(!UWC)
		return
	var/datum/category_item/underwear/UWI = all_underwear[UWC.name]
	if(!UWI || UWI.name == "None")
		to_chat(src, SPAN_NOTICE("You do not have [UWC.gender==PLURAL ? "[UWC.display_name]" : "any [UWC.display_name]"]."))
		return
	hide_underwear[UWC.name] = !hide_underwear[UWC.name]
	update_underwear(1)
	to_chat(src, SPAN_NOTICE("You [hide_underwear[UWC.name] ? "take off" : "put on"] your [UWC.display_name]."))

/mob/living/carbon/human/verb/pull_punches()
	set name = "Pull Punches"
	set desc = "Try not to hurt them."
	set category = "IC"

	if(stat) return
	pulling_punches = !pulling_punches
	to_chat(src, SPAN_NOTICE("You are now [pulling_punches ? "pulling your punches" : "not pulling your punches"]."))
	return

/mob/living/carbon/human/get_metabolism(metabolism)
	return ..() * (species ? species.metabolism_mod : 1)

/mob/living/carbon/human/is_clumsy()
	if((mutations & CLUMSY))
		return TRUE
	if(CE_CLUMSY in chem_effects)
		return TRUE

	var/bac = get_blood_alcohol()
	var/SR = species.ethanol_resistance
	if(SR>0)
		if(bac > INTOX_REACTION*SR)
			return TRUE

	return FALSE

// Similar to get_pulse, but returns only integer numbers instead of text.
/mob/living/carbon/human/proc/get_pulse_as_number()
	var/obj/item/organ/internal/heart/heart_organ = internal_organs_by_name[BP_HEART]
	if(!heart_organ)
		return 0

	switch(pulse())
		if(PULSE_NONE)
			return 0
		if(PULSE_SLOW to (PULSE_NORM - 0.1))
			return rand(species.low_pulse, species.norm_pulse)
		if(PULSE_NORM to (PULSE_FAST - 0.1))
			return rand(species.norm_pulse, species.fast_pulse)
		if(PULSE_FAST to (PULSE_2FAST - 0.1))
			return rand(species.fast_pulse, species.v_fast_pulse)
		if(PULSE_2FAST to (PULSE_THREADY - 0.1))
			return rand(species.v_fast_pulse, species.max_pulse)
		if(PULSE_THREADY to INFINITY)
			return PULSE_MAX_BPM
	return 0

/mob/living/carbon/human/proc/get_pulse(var/method)	//method 0 is for hands, 1 is for machines, more accurate
	var/obj/item/organ/internal/heart/heart_organ = internal_organs_by_name[BP_HEART]
	if(!heart_organ)
		// No heart, no pulse
		return "0"

	if(status_flags & FAKEDEATH)
		return "0"

	var/bpm = get_pulse_as_number()
	if(bpm >= PULSE_MAX_BPM)
		return method ? ">[PULSE_MAX_BPM]" : "extremely weak and fast, patient's artery feels like a thread"

	return "[method ? bpm : bpm + rand(-10, 10)]"

/mob/living/carbon/human/proc/pulse()
	var/obj/item/organ/internal/heart/heart = internal_organs_by_name[BP_HEART]
	return heart ? heart.pulse : PULSE_NONE

/mob/living/carbon/human/proc/move_to_stomach(atom/movable/victim)
	var/obj/item/organ/internal/stomach/stomach = internal_organs_by_name[BP_STOMACH]
	if(istype(stomach))
		victim.forceMove(stomach)

/mob/living/carbon/human/need_breathe()
	if(!(mutations & mNobreath) && species.breathing_organ && species.has_organ[species.breathing_organ])
		return TRUE
	return FALSE

//Get fluffy numbers
/mob/living/carbon/human/proc/blood_pressure()
	if(status_flags & FAKEDEATH)
		return list(FLOOR(species.bp_base_systolic+rand(-5,5), 1)*0.25, FLOOR(species.bp_base_disatolic+rand(-5,5), 1)*0.25)
	var/blood_result = get_blood_circulation()
	return list(FLOOR((species.bp_base_systolic+rand(-5,5))*(blood_result/100), 1), FLOOR((species.bp_base_disatolic+rand(-5,5))*(blood_result/100), 1))

//Formats blood pressure for text display
/mob/living/carbon/human/proc/get_blood_pressure()
	var/list/bp = blood_pressure()
	return "[bp[1]]/[bp[2]]"

//Works out blood pressure alert level -- not very accurate
/mob/living/carbon/human/proc/get_blood_pressure_alert()
	var/list/bp_list = blood_pressure()
	// For a blood pressure, e.g. 120/80
	var/systolic_alert // this is the top number '120' -- highest pressure when heart beats
	var/diastolic_alert // this is the bottom number '80' -- lowest pressure when heart relaxes

	var/blood_pressure_systolic = bp_list[1]
	if (blood_pressure_systolic)
		if (blood_pressure_systolic >= (species.bp_base_systolic - BP_SYS_IDEAL_MOD) && blood_pressure_systolic <= (species.bp_base_systolic + HIGH_BP_MOD))
			systolic_alert = BLOOD_PRESSURE_IDEAL
		else if (blood_pressure_systolic <= (species.bp_base_systolic - BP_SYS_IDEAL_MOD))
			systolic_alert = BLOOD_PRESSURE_LOW
		else if (blood_pressure_systolic >= (species.bp_base_systolic + PRE_HIGH_BP_MOD) && blood_pressure_systolic <= (species.bp_base_systolic + HIGH_BP_MOD))
			systolic_alert = BLOOD_PRESSURE_PRE_HIGH
		else if (blood_pressure_systolic >= (species.bp_base_systolic + HIGH_BP_MOD))
			systolic_alert = BLOOD_PRESSURE_HIGH

	var/blood_pressure_disatolic = bp_list[2]
	if (blood_pressure_disatolic)
		if(blood_pressure_disatolic >= (species.bp_base_disatolic - BP_DIS_IDEAL_MOD) && blood_pressure_disatolic <=  (species.bp_base_disatolic + HIGH_BP_MOD))
			diastolic_alert = BLOOD_PRESSURE_IDEAL
		else if (blood_pressure_disatolic >=  (species.bp_base_disatolic - BP_DIS_IDEAL_MOD))
			diastolic_alert = BLOOD_PRESSURE_LOW
		else if (blood_pressure_disatolic >= (species.bp_base_disatolic + PRE_HIGH_BP_MOD) && blood_pressure_disatolic <= (species.bp_base_disatolic + PRE_HIGH_BP_MOD))
			diastolic_alert = BLOOD_PRESSURE_PRE_HIGH
		else if (blood_pressure_disatolic >= (species.bp_base_disatolic + HIGH_BP_MOD))
			diastolic_alert = BLOOD_PRESSURE_HIGH

	if(systolic_alert == BLOOD_PRESSURE_HIGH || diastolic_alert == BLOOD_PRESSURE_HIGH)
		return BLOOD_PRESSURE_HIGH
	if(systolic_alert == BLOOD_PRESSURE_PRE_HIGH || diastolic_alert == BLOOD_PRESSURE_PRE_HIGH)
		return BLOOD_PRESSURE_PRE_HIGH
	if(systolic_alert == BLOOD_PRESSURE_LOW || diastolic_alert == BLOOD_PRESSURE_LOW)
		return BLOOD_PRESSURE_LOW
	if(systolic_alert <= BLOOD_PRESSURE_IDEAL && diastolic_alert <= BLOOD_PRESSURE_IDEAL)
		return BLOOD_PRESSURE_IDEAL

//Point at which you dun breathe no more. Separate from asystole crit, which is heart-related.
/mob/living/carbon/human/nervous_system_failure()
	return getBrainLoss() >= maxHealth * 0.75

// Check if we should die.
/mob/living/carbon/human/proc/handle_death_check()
	if(should_have_organ(BP_BRAIN) && !is_mechanical()) //robots don't die via brain damage
		var/obj/item/organ/internal/brain/brain = internal_organs_by_name[BP_BRAIN]
		if(!brain || (brain.status & ORGAN_DEAD))
			return TRUE
	return species.handle_death_check(src)

/mob/living/carbon/human/should_have_organ(var/organ_check)
	return (species?.has_organ[organ_check])

/mob/living/carbon/human/should_have_limb(var/limb_check)
	return (species?.has_limbs[limb_check])

/mob/living/proc/resuscitate()
	return FALSE

/mob/living/carbon/human/resuscitate()
	if(!is_asystole() || !should_have_organ(BP_HEART))
		return
	var/obj/item/organ/internal/heart/heart = internal_organs_by_name[BP_HEART]
	if(istype(heart) && !(heart.status & ORGAN_DEAD))
		if(!nervous_system_failure())
			visible_message("<b>[src]</b> jerks and gasps for breath!")
		else
			visible_message("<b>[src]</b> twitches a bit as [get_pronoun("his")] heart restarts!")
		shock_stage = min(shock_stage, 100) // 120 is the point at which the heart stops.
		if(getOxyLoss() >= 75)
			setOxyLoss(75)
		heart.pulse = PULSE_NORM
		heart.handle_pulse()
		return TRUE

/mob/living/carbon/human/proc/make_adrenaline(var/amount)
	if(stat == CONSCIOUS)
		reagents.add_reagent(/singleton/reagent/adrenaline, amount)

/mob/living/carbon/human/proc/gigashatter()
	for(var/obj/item/organ/external/E in organs)
		E.fracture()
	return

/mob/living/carbon/human/get_bullet_impact_effect_type(var/def_zone)
	var/obj/item/organ/external/E = get_organ(def_zone)
	if(!E || E.is_stump())
		return BULLET_IMPACT_NONE
	if(BP_IS_ROBOTIC(E))
		return BULLET_IMPACT_METAL
	return BULLET_IMPACT_MEAT

/mob/living/carbon/human/bullet_impact_visuals(obj/projectile/impacting_projectile, def_zone, damage, blocked)
	. = ..()
	if(blocked > 70)
		return
	switch(get_bullet_impact_effect_type(def_zone))
		if(BULLET_IMPACT_MEAT)
			if(impacting_projectile.damage_type == DAMAGE_BRUTE)
				var/hit_dir = get_dir(impacting_projectile.starting, src)
				var/obj/effect/decal/cleanable/blood/B = blood_splatter(get_step(src, hit_dir), src, 1, hit_dir)
				B.icon_state = pick("dir_splatter_1","dir_splatter_2")
				var/scale = min(1, round(damage / 50, 0.2))
				var/matrix/M = new()
				B.transform = M.Scale(scale)

/mob/living/carbon/human/get_accent_icon(var/datum/language/speaking, var/mob/hearer, var/force_accent)
	var/used_accent = accent //starts with the mob's default accent

	if(mind)
		var/datum/changeling/changeling = mind.antag_datums[MODE_CHANGELING]
		if(changeling?.mimiced_accent)
			used_accent = changeling.mimiced_accent

	if(istype(back,/obj/item/rig)) //checks for the rig voice changer module
		var/obj/item/rig/rig = back
		if(rig.speech && rig.speech.voice_holder && rig.speech.voice_holder.active && rig.speech.voice_holder.current_accent)
			used_accent = rig.speech.voice_holder.current_accent

	var/obj/item/organ/internal/augment/synthetic_cords/voice/aug = internal_organs_by_name[BP_AUG_ACC_CORDS] //checks for augments, thanks grey
	if(aug)
		used_accent = aug.accent

	for(var/obj/item/gear in list(wear_mask,wear_suit,head)) //checks for voice changers masks now
		if(gear)
			var/obj/item/voice_changer/changer = locate() in gear
			if(changer && changer.active && changer.current_accent)
				used_accent = changer.current_accent

	return ..(speaking, hearer, used_accent)

/mob/living/carbon/human/proc/generate_valid_languages()
	var/list/available_languages = species.secondary_langs.Copy() + LANGUAGE_TCB
	for(var/L in GLOB.all_languages)
		var/datum/language/lang = GLOB.all_languages[L]
		if(!(lang.flags & RESTRICTED) && (!GLOB.config.usealienwhitelist || is_alien_whitelisted(src, L) || !(lang.flags & WHITELISTED)))
			available_languages |= L
	return available_languages

/mob/living/carbon/human/proc/set_accent(var/new_accent)
	accent = new_accent
	if(!(accent in origin.possible_accents))
		accent = origin.possible_accents[1]
	return TRUE

/mob/living/carbon/human/proc/add_or_remove_language(var/language)
	var/datum/language/new_language = GLOB.all_languages[language]
	if(!new_language || !istype(new_language))
		to_chat(src, SPAN_WARNING("Invalid language!"))
		return TRUE
	if(new_language in languages)
		if(remove_language(language))
			to_chat(src, SPAN_NOTICE("You no longer know <b>[new_language.name]</b>."))
		return TRUE
	var/total_alternate_languages = languages.Copy()
	total_alternate_languages -= GLOB.all_languages[species.language]
	if(length(total_alternate_languages) >= species.num_alternate_languages)
		to_chat(src, SPAN_WARNING("You can't add any more languages!"))
		return TRUE
	if(add_language(language))
		to_chat(src, SPAN_NOTICE("You now know <b>[language]</b>."))
	return TRUE

/mob/living/carbon/human/verb/click_belt()
	set hidden = 1
	set name = "click_belt"
	if(belt)
		belt.Click()

/mob/living/carbon/human/verb/click_uniform()
	set hidden = 1
	set name = "click_uniform"
	if(w_uniform)
		w_uniform.Click()

/mob/living/carbon/human/verb/click_back()
	set hidden = 1
	set name = "click_back"
	if(back)
		back.Click()

/mob/living/carbon/human/verb/click_suit_storage()
	set hidden = 1
	set name = "click_suit_storage"
	if(s_store)
		s_store.Click()

/mob/living/carbon/human/proc/disable_organ_night_vision()
	var/obj/item/organ/E = internal_organs_by_name[BP_EYES]
	if (istype(E, /obj/item/organ/internal/eyes/night))
		var/obj/item/organ/internal/eyes/night/N = E
		if(N.night_vision )
			N.disable_night_vision()

/mob/living/carbon/human/adjustEarDamage(var/damage, var/deaf, var/ringing = FALSE)
	if (damage > 0)
		var/hearing_sensitivity = get_hearing_sensitivity()
		if (hearing_sensitivity)
			if (is_listening()) // if the person is listening in, the effect is way worse
				if (hearing_sensitivity == HEARING_VERY_SENSITIVE)
					damage *= 2
				else
					damage = round(damage *= 1.5, 1)
				stop_listening()
			else
				if (hearing_sensitivity == HEARING_VERY_SENSITIVE)
					damage = round(damage *= 1.4, 1)
				else
					damage = round(damage *= 1.2, 1)
	return ..()

// Intensity 1: mild, 2: hurts, 3: very painful, 4: extremely painful, 5: that's going to leave some damage
// Sensitive_only: If yes, only those with sensitive hearing are affected
// Listening_pain: Increases the intensity by the listed amount if the person is listening in
/mob/living/carbon/human/proc/earpain(var/intensity, var/sensitive_only = FALSE, var/listening_pain = 0)
	if (ear_deaf)
		return
	if (sensitive_only && !get_hearing_sensitivity())
		return
	if (listening_pain && is_listening())
		intensity += listening_pain
	else if (sensitive_only)
		return

	var/obj/item/organ/external/E = organs_by_name[BP_HEAD]
	switch (intensity)
		if (1)
			custom_pain("Your ears hurt a little.", 5, FALSE, E, TRUE)
		if (2)
			custom_pain("Your ears hurt!", 10, TRUE, E, TRUE)
		if (3)
			custom_pain("Your ears hurt badly!", 40, TRUE, E, TRUE)
		if (4)
			custom_pain("Your ears begin to ring faintly from the pain!", 70, TRUE, E, TRUE)
			adjustEarDamage(5, 0, FALSE)
			stop_listening()
		if (5)
			custom_pain("YOUR EARS ARE DEAFENED BY THE PAIN!", 110, TRUE, E, FALSE)
			adjustEarDamage(5, 5, FALSE)
			stop_listening()

/mob/living/carbon/human/verb/lookup()
	set name = "Look Up"
	set desc = "If you want to know what's above."
	set category = "IC"

	look_up_open_space(get_turf(src))

/mob/living/proc/look_up_open_space(var/turf/T)
	if(client && !is_physically_disabled())
		if(z_eye)
			reset_view(null)
			QDEL_NULL(z_eye)
			return
		var/turf/above = GET_TURF_ABOVE(T)
		if(TURF_IS_MIMICING(above))
			z_eye = new /atom/movable/z_observer/z_up(src, src, T)
			visible_message(SPAN_NOTICE("[src] looks up."), SPAN_NOTICE("You look up."))
			reset_view(z_eye)
			return
		to_chat(src, SPAN_NOTICE("You can see \the [above ? above : "ceiling"]."))
	else
		to_chat(src, SPAN_NOTICE("You can't look up right now."))

/mob/living/verb/lookdown()
	set name = "Look Down"
	set desc = "If you want to know what's below."
	set category = "IC"

	look_down_open_space(get_turf(src))

/mob/living/proc/look_down_open_space(var/turf/T)
	if(client && !is_physically_disabled())
		if(z_eye)
			reset_view(null)
			QDEL_NULL(z_eye)
			return
		if(TURF_IS_MIMICING(T) && GET_TURF_BELOW(T))
			z_eye = new /atom/movable/z_observer/z_down(T, src, T)
			visible_message(SPAN_NOTICE("[src] looks below."), SPAN_NOTICE("You look below."))
			reset_view(z_eye)
			return
		else
			T = get_step(T, dir)
			if(TURF_IS_MIMICING(T) && GET_TURF_BELOW(T))
				z_eye = new /atom/movable/z_observer/z_down(T, src, T)
				visible_message(SPAN_NOTICE("[src] leans over to look below."), SPAN_NOTICE("You lean over to look below."))
				reset_view(z_eye)
				return
		to_chat(src, SPAN_NOTICE("You can see \the [T ? T : "floor"]."))
	else
		to_chat(src, SPAN_NOTICE("You can't look below right now."))

/mob/living/carbon/human/get_speech_bubble_state_modifier()
	if(speech_bubble_type)
		return speech_bubble_type
	else
		return ..()
