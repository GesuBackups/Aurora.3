//NASA Voidsuit
/obj/item/clothing/head/helmet/space/void
	name = "void helmet"
	desc = "A high-tech dark red space suit helmet. Used for AI satellite maintenance."
	icon_state = "void"

	heat_protection = HEAD
	armor = list(
		MELEE = ARMOR_MELEE_RESISTANT,
		BULLET = ARMOR_BALLISTIC_MINOR,
		LASER = ARMOR_LASER_SMALL,
		ENERGY = ARMOR_ENERGY_MINOR,
		BOMB = ARMOR_BOMB_PADDED,
		BIO = ARMOR_BIO_SHIELDED,
		RAD = ARMOR_RAD_MINOR
	)
	max_heat_protection_temperature = SPACE_SUIT_MAX_HEAT_PROTECTION_TEMPERATURE
	max_pressure_protection = VOIDSUIT_MAX_PRESSURE
	min_pressure_protection = 0
	siemens_coefficient = 0.5
	contained_sprite = FALSE
	icon = 'icons/obj/clothing/hats.dmi'

	//Species-specific stuff.
	species_restricted = list(BODYTYPE_HUMAN)
	sprite_sheets_refit = list(
		BODYTYPE_UNATHI = 'icons/mob/species/unathi/helmet.dmi',
		BODYTYPE_TAJARA = 'icons/mob/species/tajaran/helmet.dmi',
		BODYTYPE_SKRELL = 'icons/mob/species/skrell/helmet.dmi',
		BODYTYPE_IPC = 'icons/mob/species/machine/helmet.dmi'
	)
	sprite_sheets_obj = list(
		BODYTYPE_UNATHI = 'icons/obj/clothing/species/unathi/hats.dmi',
		BODYTYPE_TAJARA = 'icons/obj/clothing/species/tajaran/hats.dmi',
		BODYTYPE_SKRELL = 'icons/obj/clothing/species/skrell/hats.dmi',
		BODYTYPE_IPC = 'icons/obj/clothing/species/machine/hats.dmi'
	)

	light_overlay = "helmet_light"

/obj/item/clothing/suit/space/void
	name = "voidsuit"
	icon_state = "void"
	item_state = "void"
	desc = "A high-tech dark red space suit. Used for AI satellite maintenance."
	slowdown = 1
	armor = list(
		MELEE = ARMOR_MELEE_RESISTANT,
		BULLET = ARMOR_BALLISTIC_MINOR,
		LASER = ARMOR_LASER_SMALL,
		ENERGY = ARMOR_ENERGY_MINOR,
		BOMB = ARMOR_BOMB_PADDED,
		BIO = ARMOR_BIO_SHIELDED,
		RAD = ARMOR_RAD_MINOR
	)
	allowed = list(/obj/item/device/flashlight,/obj/item/tank,/obj/item/device/suit_cooling_unit)
	heat_protection = UPPER_TORSO|LOWER_TORSO|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = SPACE_SUIT_MAX_HEAT_PROTECTION_TEMPERATURE
	siemens_coefficient = 0.5
	contained_sprite = FALSE
	icon = 'icons/obj/clothing/suits.dmi'

	species_restricted = list(BODYTYPE_HUMAN, BODYTYPE_SKRELL)
	sprite_sheets_refit = list(
		BODYTYPE_UNATHI = 'icons/mob/species/unathi/suit.dmi',
		BODYTYPE_TAJARA = 'icons/mob/species/tajaran/suit.dmi',
		BODYTYPE_SKRELL = 'icons/mob/species/skrell/suit.dmi',
		BODYTYPE_IPC = 'icons/mob/species/machine/suit.dmi'
	)
	sprite_sheets_obj = list(
		BODYTYPE_UNATHI = 'icons/obj/clothing/species/unathi/suits.dmi',
		BODYTYPE_TAJARA = 'icons/obj/clothing/species/tajaran/suits.dmi',
		BODYTYPE_SKRELL = 'icons/obj/clothing/species/skrell/suits.dmi',
		BODYTYPE_IPC= 'icons/obj/clothing/species/machine/suits.dmi'
	)

	action_button_name = "Toggle Helmet"
	var/helmet_deploy_sound = 'sound/items/helmet_close.ogg'
	var/helmet_retract_sound = 'sound/items/helmet_open.ogg'

	//Breach thresholds, should ideally be inherited by most (if not all) voidsuits.
	//With 0.2 resiliance, will reach 10 breach damage after 3 laser carbine blasts or 8 smg hits.
	breach_threshold = 18
	can_breach = 1

	//Inbuilt devices.
	var/obj/item/clothing/shoes/magboots/boots = null // Deployable boots, if any.
	var/obj/item/clothing/head/helmet/helmet = null   // Deployable helmet, if any.
	var/obj/item/tank/tank = null              // Deployable tank, if any.
	var/obj/item/device/suit_cooling_unit/cooler = null // Deployable suit cooler, if any

/obj/item/clothing/suit/space/void/get_examine_text(mob/user, distance, is_adjacent, infix, suffix)
	. = ..()
	var/list/part_list = new
	for(var/obj/item/I in list(helmet,boots,tank,cooler))
		part_list += "\a [I]"
	. +=  "\The [src] has [english_list(part_list)] installed."
	if(tank && distance <= 1)
		. += SPAN_NOTICE("The wrist-mounted pressure gauge reads [max(round(tank.air_contents.return_pressure()),0)] kPa remaining in \the [tank].")
	if (cooler && distance <= 1)
		. += SPAN_NOTICE("The mounted cooler's battery charge reads [round(cooler.cell.percent())]%")

/obj/item/clothing/suit/space/void/refit_for_species(var/target_species)
	..()
	if(istype(helmet))
		helmet.refit_for_species(target_species)
	if(istype(boots))
		boots.refit_for_species(target_species)

/obj/item/clothing/suit/space/void/equipped(mob/M)
	..()

	var/mob/living/carbon/human/H = M

	if(!istype(H)) return

	if(H.wear_suit != src)
		return

	if(boots)
		if (H.equip_to_slot_if_possible(boots, slot_shoes))
			boots.canremove = 0

	if(helmet)
		if(H.head)
			to_chat(M, "You are unable to deploy your suit's helmet as \the [H.head] is in the way.")
		else if (H.equip_to_slot_if_possible(helmet, slot_head))
			to_chat(M, "Your suit's helmet deploys with a hiss.")
			playsound(loc, helmet_deploy_sound, 30)
			helmet.canremove = 0

	if(tank)
		if(H.s_store) //In case someone finds a way.
			to_chat(M, "Alarmingly, the valve on your suit's installed tank fails to engage.")
		else if (H.equip_to_slot_if_possible(tank, slot_s_store))
			to_chat(M, "The valve on your suit's installed tank safely engages.")
			tank.canremove = 0

	if(cooler)
		if (H.equip_to_slot_if_possible(cooler, slot_s_store))
			cooler.canremove = 0

/obj/item/clothing/suit/space/void/proc/cleanup_from_mob()
	var/mob/living/carbon/human/H

	if(helmet)
		helmet.canremove = 1
		H = helmet.loc
		if(istype(H))
			if(helmet && H.head == helmet)
				H.drop_from_inventory(helmet,src)

	if(boots)
		boots.canremove = 1
		H = boots.loc
		if(istype(H))
			if(boots && H.shoes == boots)
				H.drop_from_inventory(boots,src)

	if(tank)
		tank.canremove = 1
		tank.forceMove(src)

	if(cooler)
		cooler.canremove = 1
		cooler.forceMove(src)

/obj/item/clothing/suit/space/void/on_slotmove()
	..()
	cleanup_from_mob()

/obj/item/clothing/suit/space/void/dropped()
	..()
	cleanup_from_mob()

/obj/item/clothing/suit/space/void/verb/toggle_helmet()

	set name = "Toggle Helmet"
	set category = "Object"
	set src in usr

	if(!istype(src.loc,/mob/living)) return

	if(!helmet)
		to_chat(usr, "There is no helmet installed.")
		return

	var/mob/living/carbon/human/H = usr

	if(!istype(H)) return
	if(H.stat) return
	if(H.wear_suit != src) return

	if(H.head == helmet)
		to_chat(H, SPAN_NOTICE("You retract your suit helmet."))
		playsound(loc, helmet_retract_sound, 30)
		helmet.canremove = 1
		H.drop_from_inventory(helmet,src)
	else
		if(H.head)
			to_chat(H, SPAN_DANGER("You cannot deploy your helmet while wearing \the [H.head]."))
			return
		if(H.equip_to_slot_if_possible(helmet, slot_head))
			helmet.pickup(H)
			helmet.canremove = 0
			to_chat(H, "<span class='info'>You deploy your suit helmet, sealing you off from the world.</span>")
	helmet.update_light(H)

/obj/item/clothing/suit/space/void/verb/eject_tank()

	set name = "Eject Voidsuit Tank"
	set category = "Object"
	set src in view(1)

	var/mob/living/user = usr

	if(use_check_and_message(user))	return

	if(!tank)
		to_chat(usr, "There is no tank inserted.")
		return

	to_chat(user, SPAN_INFO("You press the emergency release lever, ejecting \the [tank] from your suit."))
	tank.canremove = 1
	playsound(src, 'sound/effects/air_seal.ogg', 50, 1)

	if(user.get_inventory_slot(src) == slot_wear_suit)
		user.drop_from_inventory(tank)
	else
		tank.forceMove(get_turf(src))
	src.tank = null

/obj/item/clothing/suit/space/void/verb/eject_cooler()

	set name = "Eject Suit Cooler"
	set category = "Object"
	set src in view(1)

	var/mob/living/user = usr

	if(use_check_and_message(user))	return

	if(!cooler)
		to_chat(usr, "There is no suit cooler installed.")
		return

	to_chat(user, SPAN_INFO("You engage the release mechanism, ejecting \the [cooler] from your suit."))
	cooler.canremove = 1
	playsound(src, 'sound/items/Deconstruct.ogg', 30, 1)

	if(user.get_inventory_slot(src) == slot_wear_suit)
		user.drop_from_inventory(cooler)
	else
		cooler.forceMove(get_turf(src))
	src.cooler = null

/obj/item/clothing/suit/space/void/attack_self()
	toggle_helmet()

/obj/item/clothing/suit/space/void/attackby(obj/item/attacking_item, mob/user)

	if(!istype(user,/mob/living)) return

	if(istype(attacking_item, /obj/item/clothing/accessory) || istype(attacking_item, /obj/item/device/hand_labeler))
		return ..()

	if(user.get_inventory_slot(src) == slot_wear_suit)
		to_chat(user, SPAN_WARNING("You cannot modify \the [src] while it is being worn."))
		return

	if(attacking_item.isscrewdriver())
		if(helmet || boots || tank || cooler)
			var/choice = tgui_input_list(usr, "What component would you like to remove?", "Component Removal", list(helmet,boots,tank,cooler))
			if(!choice) return

			playsound(src, 'sound/items/Screwdriver.ogg', 50, 1)
			if(choice == tank)	//No, a switch doesn't work here. Sorry. ~Techhead
				to_chat(user, "You pop \the [tank] out of \the [src]'s storage compartment.")
				tank.forceMove(get_turf(src))
				src.tank = null
			else if(choice == helmet)
				to_chat(user, "You detach \the [helmet] from \the [src]'s helmet mount.")
				helmet.forceMove(get_turf(src))
				src.helmet = null
			else if(choice == boots)
				to_chat(user, "You detach \the [boots] from \the [src]'s boot mounts.")
				boots.forceMove(get_turf(src))
				src.boots = null
			else if (choice == cooler)
				to_chat(user, "You detach \the [cooler] from \the [src]'s cooler mount.")
				cooler.forceMove(get_turf(src))
				src.cooler = null
		else
			to_chat(user, "\The [src] does not have anything installed.")
		return
	else if(istype(attacking_item,/obj/item/clothing/head/helmet/space))
		if(helmet)
			to_chat(user, "\The [src] already has a helmet installed.")
		else
			playsound(src, 'sound/items/Deconstruct.ogg', 30, 1)
			to_chat(user, "You attach \the [attacking_item] to \the [src]'s helmet mount.")
			user.drop_from_inventory(attacking_item, src)
			src.helmet = attacking_item
		return
	else if(istype(attacking_item,/obj/item/clothing/shoes/magboots))
		if(boots)
			to_chat(user, "\The [src] already has magboots installed.")
		else
			playsound(src, 'sound/items/Deconstruct.ogg', 30, 1)
			to_chat(user, "You attach \the [attacking_item] to \the [src]'s boot mounts.")
			user.drop_from_inventory(attacking_item, src)
			boots = attacking_item
		return
	else if(istype(attacking_item,/obj/item/tank))
		if(tank)
			to_chat(user, "\The [src] already has an airtank installed.")
		else if(cooler)
			to_chat(user, "\The [src] already has a suit cooler installed, there is no room for an airtank.")
		else if(istype(attacking_item,/obj/item/tank/phoron))
			to_chat(user, "\The [attacking_item] cannot be inserted into \the [src]'s storage compartment.")
		else
			playsound(src, 'sound/items/Deconstruct.ogg', 30, 1)
			to_chat(user, "You insert \the [attacking_item] into \the [src]'s storage compartment.")
			user.drop_from_inventory(attacking_item, src)
			tank = attacking_item
		return
	else if (istype(attacking_item, /obj/item/device/suit_cooling_unit))
		if(cooler)
			to_chat(user, "\The [src] already has a suit cooler installed.")
		else if(tank)
			to_chat(user, "\The [src] already has an airtank installed, there is no room for a suit cooler.")
		else
			playsound(src, 'sound/items/Deconstruct.ogg', 30, 1)
			to_chat(user, "You insert \the [attacking_item] into \the [src]'s storage compartment.")
			user.drop_from_inventory(attacking_item, src)
			cooler = attacking_item
		return
	..()
