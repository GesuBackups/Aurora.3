/*
 *	Everything derived from the common cardboard box.
 *	Basically everything except the original is a kit (starts full).
 *
 *	Contains:
 *		Empty box, starter boxes (survival/engineer),
 *		Latex glove and sterile mask boxes,
 *		Syringe, beaker, dna injector boxes,
 *		Blanks, flashbangs, and EMP grenade boxes,
 *		Tracking and chemical implant boxes,
 *		Prescription glasses and drinking glass boxes,
 *		Condiment bottle and silly cup boxes,
 *		Donkpocket and monkeycube boxes,
 *		ID boxes,
 *		Handcuff, mousetrap, and pillbottle boxes,
 *		Snap-pops,
 *		Replacement light boxes.
 *		Kitchen utensil box
 * 		Random preserved snack box
 *		For syndicate call-ins see uplink_kits.dm
 *		Firing pin boxes - Testing and Normal. one for sec, one for science.
 */

/obj/item/storage/box
	name = "box"
	desc = "It's just an ordinary box."
	icon = 'icons/obj/storage/boxes.dmi'
	icon_state = "box"
	item_state = "box"
	contained_sprite = TRUE
	var/illustration = "writing"

	// BubbleWrap - if set, can be folded (when empty) into a sheet of cardboard
	var/foldable = /obj/item/stack/material/cardboard

	///Boolean, if set, can be crushed into a trash item when empty
	var/trash = null

	var/maxHealth = 20	//health is already defined
	use_sound = 'sound/items/storage/box.ogg'
	drop_sound = 'sound/items/drop/cardboardbox.ogg'
	pickup_sound = 'sound/items/pickup/cardboardbox.ogg'
	var/chewable = TRUE

/obj/item/storage/box/condition_hints(mob/user, distance, is_adjacent)
	. += ..()
	if (health < maxHealth)
		if (health >= (maxHealth * 0.5))
			. += SPAN_WARNING("It is slightly torn.")
		else
			. += SPAN_DANGER("It is full of tears and holes.")

/obj/item/storage/box/mechanics_hints(mob/user, distance, is_adjacent)
	. += ..()
	if(foldable)
		. += "Left-click on this when empty to fold it into a sheet."
	if(ispath(src.trash))
		. += "This can be crumpled up into a trash item when empty, or forcibly crumpled on harm intent. "

/obj/item/storage/box/Initialize()
	. = ..()
	health = maxHealth
	if(illustration)
		AddOverlays(illustration)

/obj/item/storage/box/proc/damage(var/severity)
	health -= severity
	check_health()

/obj/item/storage/box/proc/check_health()
	if (health <= 0)
		qdel(src)

/obj/item/storage/box/attack_generic(var/mob/user)
	if(!chewable)
		return
	if(istype(user, /mob/living))
		var/mob/living/L = user

		if (istype(L, /mob/living/carbon/alien/diona) || istype(L, /mob/living/simple_animal) || istype(L, /mob/living/carbon/human))//Monkey-like things do attack_generic, not crew
			if(contents.len && !locate(/obj/item/reagent_containers/food) in src) // you can tear open empty boxes for nesting material, or for food
				to_chat(user, SPAN_WARNING("There's no food in that box!"))
				return
			var/damage
			if (!L.mob_size)
				damage = 3//A safety incase i forgot to set a mob_size on something
			else
				damage = L.mob_size//he bigger you are, the faster it tears

			if (!damage || damage <= 0)
				return

			user.do_attack_animation(src)
			if ((health-damage) <= 0)
				L.visible_message(SPAN_DANGER("[L] tears open the [src], spilling its contents everywhere!"),
									SPAN_DANGER("You tear open the [src], spilling its contents everywhere!"))

				spill()
			else
				shake_animation()
				var/toplay = pick(list('sound/effects/creatures/nibble1.ogg','sound/effects/creatures/nibble2.ogg'))
				playsound(loc, toplay, 30, 1)
			damage(damage)
	..()

// BubbleWrap - A box can be folded up to make card
/obj/item/storage/box/attack_self(mob/user as mob)
	if(..())
		return

	if(ispath(src.foldable) || ispath(src.trash))
		var/found = 0
		for(var/mob/M in range(1))
			if(M.s_active == src)
				src.close(M) // Close any open UI windows first
			if(M == user)
				found = 1
		if(!found)	// User is too far away
			return
		if(ispath(src.foldable))
			if(contents.len)
				return
			to_chat(user, SPAN_NOTICE("You fold \the [src] flat.")) //make cardboard
			playsound(src.loc, 'sound/items/storage/boxfold.ogg', 30, 1)
			var/obj/item/foldable = new src.foldable()
			qdel(src)
			user.put_in_hands(foldable) //try to put it inhands if possible
		if(ispath(src.trash) && user.a_intent == I_HURT)
			if(!contents.len)
				to_chat(user, SPAN_NOTICE("You crumple up \the [src]."))
			else
				user.visible_message(SPAN_DANGER("You crush \the [src], spilling its contents everywhere!"), SPAN_DANGER("[user] crushes \the [src], spilling its contents everywhere!"))
				spill()
			playsound(src.loc, 'sound/items/pickup/wrapper.ogg', 30, 1)
			var/obj/item/trash = new src.trash()
			qdel(src)
			user.put_in_hands(trash)

/obj/item/storage/box/attackby(obj/item/attacking_item, mob/user)
	if(istype(attacking_item, /obj/item/stack/packageWrap))
		var/total_storage_space = attacking_item.get_storage_cost()
		for(var/obj/item/I in contents)
			total_storage_space += I.get_storage_cost()
		if(total_storage_space <= max_storage_space)
			var/question = tgui_input_list(user, "Will you want to wrap \the [src] or store the item inside?", "Wrap or Store", list("Wrap", "Store"))
			if(question == "Wrap")
				return
			else if(question == "Store")
				return ..()
	else
		..()

/obj/item/storage/box/survival
	name = "emergency survival box"
	desc = "A faithful box that will remain with you, no matter where you go, and probably save you."
	icon_state = "redbox"
	illustration = "survival"
	max_storage_space = DEFAULT_BOX_STORAGE
	can_hold = list(
				/obj/item/clothing/mask,
				/obj/item/tank/emergency_oxygen,
				/obj/item/device/flashlight/flare,
				/obj/item/stack/medical,
				/obj/item/reagent_containers/hypospray/autoinjector,
				/obj/item/reagent_containers/inhaler,
				/obj/item/device/oxycandle,
				/obj/item/extinguisher/mini,
				/obj/item/device/radio,
				/obj/item/device/flashlight,
				/obj/item/reagent_containers/food/drinks/flask,
				/obj/item/storage/box/fancy/cigarettes,
				/obj/item/flame/lighter,
				/obj/item/disk/nuclear,
				/obj/item/crowbar,
				/obj/item/airbubble
				)
	starts_with = list(
				/obj/item/clothing/mask/breath = 1,
				/obj/item/tank/emergency_oxygen = 1,
				/obj/item/device/oxycandle = 1,
				/obj/item/device/flashlight/flare/glowstick/red = 1,
				/obj/item/stack/medical/bruise_pack = 1,
				/obj/item/reagent_containers/hypospray/autoinjector/inaprovaline = 1
				)

/obj/item/storage/box/survival/engineer
	illustration = "survivaleng"
	starts_with = list(
				/obj/item/clothing/mask/breath = 1,
				/obj/item/tank/emergency_oxygen/engi = 1,
				/obj/item/device/oxycandle = 1,
				/obj/item/device/flashlight/flare = 1,
				/obj/item/stack/medical/bruise_pack = 1,
				/obj/item/reagent_containers/hypospray/autoinjector/inaprovaline = 1
				)

/obj/item/storage/box/vaurca
	icon_state = "redbox"
	illustration = "survivalvox"
	starts_with = list(/obj/item/clothing/mask/breath = 1, /obj/item/reagent_containers/inhaler/phoron_special = 1)

/obj/item/storage/box/gloves
	name = "box of sterile gloves"
	desc = "Contains sterile gloves."
	illustration = "latex"
	max_storage_space = DEFAULT_BOX_STORAGE
	starts_with = list(/obj/item/clothing/gloves/latex = 2,
						/obj/item/clothing/gloves/latex/nitrile = 2,
						/obj/item/clothing/gloves/latex/nitrile/unathi = 1,
						/obj/item/clothing/gloves/latex/nitrile/tajara = 1,
						/obj/item/clothing/gloves/latex/nitrile/vaurca = 1)
/obj/item/storage/box/masks
	name = "box of surgical masks"
	desc = "This box contains masks of surgicality."
	illustration = "sterile"
	starts_with = list(/obj/item/clothing/mask/surgical = 4, /obj/item/clothing/mask/surgical/w = 3)

/obj/item/storage/box/syringes
	name = "box of syringes"
	desc = "A box full of syringes."
	icon_state = "secbox"
	item_state = "secbox"
	illustration = "syringe"
	starts_with = list(/obj/item/reagent_containers/syringe = 20)

/obj/item/storage/box/syringegun
	name = "box of syringe gun cartridges"
	desc = "A box full of compressed gas cartridges."
	icon_state = "secbox"
	item_state = "secbox"
	illustration = "syringe"
	starts_with = list(/obj/item/syringe_cartridge = 7)

/obj/item/storage/box/beakers
	name = "box of beakers"
	illustration = "beaker"
	starts_with = list(/obj/item/reagent_containers/glass/beaker = 7)

/obj/item/storage/box/injectors
	name = "box of DNA injectors"
	desc = "This box contains injectors it seems."
	icon_state = "secbox"
	item_state = "secbox"
	illustration = "dna"
	starts_with = list(/obj/item/dnainjector/h2m = 3, /obj/item/dnainjector/m2h = 3)

/obj/item/storage/box/tungstenslugs
	name = "box of compact tungsten slugs"
	desc = "A box with several compact tungsten slugs, aimed for use in gauss carbines."
	icon_state = "ammobox"
	item_state = "ammobox"
	illustration = null
	drop_sound = 'sound/items/drop/ammobox.ogg'
	pickup_sound = 'sound/items/pickup/ammobox.ogg'
	starts_with = list(/obj/item/ammo_casing/gauss/carbine = 4)

/obj/item/storage/box/blanks
	name = "box of blank shells"
	desc = "It has a picture of a shotgun shell and several warning symbols on the front."
	icon_state = "shellbox"
	item_state = "shellbox"
	illustration = "blankshot"
	drop_sound = 'sound/items/drop/ammobox.ogg'
	pickup_sound = 'sound/items/pickup/ammobox.ogg'
	starts_with = list(/obj/item/ammo_casing/shotgun/blank = 8)

/obj/item/storage/box/beanbags
	name = "box of beanbag shells"
	desc = "It has a picture of a shotgun shell and several warning symbols on the front.<br>WARNING: Live ammunition. Misuse may result in serious injury or death."
	icon_state = "shellbox"
	item_state = "shellbox"
	illustration = "beanshot"
	drop_sound = 'sound/items/drop/ammobox.ogg'
	pickup_sound = 'sound/items/pickup/ammobox.ogg'
	starts_with = list(/obj/item/ammo_casing/shotgun/beanbag = 8)

/obj/item/storage/box/shotgunammo
	name = "box of shotgun slugs"
	desc = "It has a picture of a shotgun shell and several warning symbols on the front.<br>WARNING: Live ammunition. Misuse may result in serious injury or death."
	icon_state = "shellbox"
	item_state = "shellbox"
	illustration = "lethalslug"
	drop_sound = 'sound/items/drop/ammobox.ogg'
	pickup_sound = 'sound/items/pickup/ammobox.ogg'
	starts_with = list(/obj/item/ammo_casing/shotgun = 8)

/obj/item/storage/box/shotgunshells
	name = "box of shotgun shells"
	desc = "It has a picture of a shotgun shell and several warning symbols on the front.<br>WARNING: Live ammunition. Misuse may result in serious injury or death."
	icon_state = "shellbox"
	item_state = "shellbox"
	illustration = "lethalshell"
	drop_sound = 'sound/items/drop/ammobox.ogg'
	pickup_sound = 'sound/items/pickup/ammobox.ogg'
	starts_with = list(/obj/item/ammo_casing/shotgun/pellet = 8)

/obj/item/storage/box/flashshells
	name = "box of illumination shells"
	desc = "It has a picture of a shotgun shell and several warning symbols on the front.<br>WARNING: Live ammunition. Misuse may result in serious injury or death."
	icon_state = "shellbox"
	item_state = "shellbox"
	illustration = "illumshot"
	drop_sound = 'sound/items/drop/ammobox.ogg'
	pickup_sound = 'sound/items/pickup/ammobox.ogg'
	starts_with = list(/obj/item/ammo_casing/shotgun/flash = 8)

/obj/item/storage/box/stunshells
	name = "box of stun shells"
	desc = "It has a picture of a shotgun shell and several warning symbols on the front.<br>WARNING: Live ammunition. Misuse may result in serious injury or death."
	icon_state = "shellbox"
	item_state = "shellbox"
	illustration = "stunshot"
	drop_sound = 'sound/items/drop/ammobox.ogg'
	pickup_sound = 'sound/items/pickup/ammobox.ogg'
	starts_with = list(/obj/item/ammo_casing/shotgun/stunshell = 8)

/obj/item/storage/box/practiceshells
	name = "box of practice shells"
	desc = "It has a picture of a shotgun shell and several warning symbols on the front.<br>WARNING: Live ammunition. Misuse may result in serious injury or death."
	icon_state = "shellbox"
	item_state = "shellbox"
	illustration = "blankshot"
	drop_sound = 'sound/items/drop/ammobox.ogg'
	pickup_sound = 'sound/items/pickup/ammobox.ogg'
	starts_with = list(/obj/item/ammo_casing/shotgun/practice = 8)

/obj/item/storage/box/haywireshells
	name = "box of haywire shells"
	desc = "It has a picture of a shotgun shell and several warning symbols on the front.<br>WARNING: Live ammunition. Misuse may result in serious injury or death."
	icon_state = "shellbox"
	item_state = "shellbox"
	illustration = "empshot"
	drop_sound = 'sound/items/drop/ammobox.ogg'
	pickup_sound = 'sound/items/pickup/ammobox.ogg'
	starts_with = list(/obj/item/ammo_casing/shotgun/emp = 8)

/obj/item/storage/box/incendiaryshells
	name = "box of incendiary shells"
	desc = "It has a picture of a shotgun shell and several warning symbols on the front.<br>WARNING: Live ammunition. Misuse may result in serious injury or death."
	icon_state = "shellbox"
	item_state = "shellbox"
	illustration = "incendiaryshot"
	drop_sound = 'sound/items/drop/ammobox.ogg'
	pickup_sound = 'sound/items/pickup/ammobox.ogg'
	starts_with = list(/obj/item/ammo_casing/shotgun/incendiary = 8)

/obj/item/storage/box/trackingslugs
	name = "box of tracking slugs"
	desc = "It has a picture of a shotgun shell and several warning symbols on the front.<br>WARNING: Live ammunition. Misuse may result in serious injury or death."
	icon_state = "shellbox"
	item_state = "shellbox"
	illustration = "trackingshot"
	drop_sound = 'sound/items/drop/ammobox.ogg'
	pickup_sound = 'sound/items/pickup/ammobox.ogg'
	starts_with = list(/obj/item/ammo_casing/shotgun/tracking = 4)

/obj/item/storage/box/wallgunammo
	name = "box of wall gun slugs"
	desc = "It has a picture of a shotgun shell and several warning symbols on the front.<br>WARNING: Live ammunition. Misuse may result in serious injury or death."
	icon_state = "shellbox"
	item_state = "shellbox"
	illustration = "lethalslug"
	drop_sound = 'sound/items/drop/ammobox.ogg'
	pickup_sound = 'sound/items/pickup/ammobox.ogg'
	starts_with = list(/obj/item/ammo_casing/shotgun/moghes = 8)

/obj/item/storage/box/sniperammo
	name = "box of 14.5mm shells"
	desc = "It has a picture of a gun and several warning symbols on the front.<br>WARNING: Live ammunition. Misuse may result in serious injury or death."
	icon_state = "ammobox"
	item_state = "ammobox"
	illustration = null
	drop_sound = 'sound/items/drop/ammobox.ogg'
	pickup_sound = 'sound/items/pickup/ammobox.ogg'
	starts_with = list(/obj/item/ammo_casing/a145 = 7)

/obj/item/storage/box/ammo10mm
	name = "box of 10mm shells"
	desc = "It has a picture of a gun and several warning symbols on the front.<br>WARNING: Live ammunition. Misuse may result in serious injury or death."
	icon_state = "ammobox"
	item_state = "ammobox"
	illustration = null
	drop_sound = 'sound/items/drop/ammobox.ogg'
	pickup_sound = 'sound/items/pickup/ammobox.ogg'
	starts_with = list(/obj/item/ammo_casing/c10mm = 10)

/obj/item/storage/box/governmentammo
	name = "box of .45-70 Govt. rounds"
	desc = "It has a picture of a rifle shell and several warning symbols on the front.<br>WARNING: Live ammunition. Misuse may result in serious injury or death."
	icon_state = "ammobox"
	item_state = "ammobox"
	illustration = null
	drop_sound = 'sound/items/drop/ammobox.ogg'
	pickup_sound = 'sound/items/pickup/ammobox.ogg'
	starts_with = list(/obj/item/ammo_casing/govt = 8)

/obj/item/storage/box/flashbangs
	name = "box of flashbangs"
	desc = "A box containing 7 antipersonnel flashbang grenades.<br> WARNING: These devices are extremely dangerous and can cause blindness or deafness in repeated use."
	icon_state = "secbox"
	item_state = "secbox"
	illustration = "flashbang"
	starts_with = list(/obj/item/grenade/flashbang = 7)

/obj/item/storage/box/stingers
	name = "box of stinger grenades"
	desc = "A box containing 7 antipersonnel stinger grenades. <br> WARNING: These devices are extremely dangerous and can cause injury."
	icon_state = "secbox"
	item_state = "secbox"
	illustration = "stinger"
	starts_with = list(/obj/item/grenade/stinger = 7)

/obj/item/storage/box/firingpins
	name = "box of firing pins"
	desc = "A box of NT brand Firearm authentication pins; Needed to operate most weapons."
	illustration = "firingpin"
	starts_with = list(/obj/item/device/firing_pin = 7)

/obj/item/storage/box/securitypins
	name = "box of wireless-control firing pins"
	desc = "A box of NT brand Firearm authentication pins; Needed to operate most weapons.  These firing pins are wireless-control enabled."
	illustration = "firingpin"
	starts_with = list(/obj/item/device/firing_pin/wireless = 7)

/obj/item/storage/box/testpins
	name = "box of firing pins"
	desc = "A box of NT brand Testing Authentication pins; allows guns to fire in designated firing ranges."
	illustration = "firingpin"
	starts_with = list(/obj/item/device/firing_pin/test_range = 7)

/obj/item/storage/box/loyaltypins
	name = "box of firing pins"
	desc = "A box of specialised \"loyalty\" authentication pins produced by NanoTrasen; these check to see if the user of the gun it's installed in has been implanted with a mind shield implant. Often used in ERTs."
	illustration = "firingpin"
	starts_with = list(/obj/item/device/firing_pin/implant/loyalty = 7)

/obj/item/storage/box/loyaltypins/fill()
	..()
	new /obj/item/device/firing_pin/implant/loyalty(src)
	new /obj/item/device/firing_pin/implant/loyalty(src)
	new /obj/item/device/firing_pin/implant/loyalty(src)
	new /obj/item/device/firing_pin/implant/loyalty(src)

/obj/item/storage/box/firingpinsRD
	name = "box of assorted firing pins"
	desc = "A box of varied assortment of firing pins. Appears to have R&D stickers on all sides of the box. Also seems to have a smiley face sticker on the top of it."
	illustration = "firingpin"
	starts_with = list(/obj/item/device/firing_pin = 2, /obj/item/device/firing_pin/access = 2, /obj/item/device/firing_pin/implant/loyalty = 2, /obj/item/device/firing_pin/psionic = 1, /obj/item/device/firing_pin/dna = 1)

/obj/item/storage/box/psireceiver
	name = "box of psionic receivers"
	desc = "A box of psionic receivers, which can be surgically implanted to act as a replacement for an underdeveloped or non-existent zona bovinae. This one has a large sticker on the side reading FOR RESEARCH USE ONLY."
	illustration = "implant"
	starts_with = list(/obj/item/organ/internal/augment/psi = 4)

/obj/item/storage/box/tethers
	name = "box of tethering devices"
	desc = "A box containing eight electro-tethers, used primarily to keep track of partners during expeditions."
	starts_with = list(/obj/item/tethering_device = 8)
	make_exact_fit = TRUE

/obj/item/storage/box/teargas
	name = "box of pepperspray grenades"
	desc = "A box containing 7 tear gas grenades. A gas mask is printed on the label.<br> WARNING: Exposure carries risk of serious injury or death. Keep away from persons with lung conditions."
	icon_state = "secbox"
	item_state = "secbox"
	illustration = "grenade"
	starts_with = list(/obj/item/grenade/chem_grenade/teargas = 6)

/obj/item/storage/box/smokebombs
	name = "box of smoke grenades"
	desc = "A box full of smoke grenades, used by special law enforcement teams and military organisations. Provides cover, confusion, and distraction."
	icon_state = "secbox"
	item_state = "secbox"
	illustration = "grenade"
	starts_with = list(/obj/item/grenade/smokebomb = 7)

/obj/item/storage/box/emps
	name = "box of emp grenades"
	desc = "A box containing 5 military grade EMP grenades.<br> WARNING: Do not use near unshielded electronics or biomechanical augmentations, death or permanent paralysis may occur."
	icon_state = "secbox"
	item_state = "secbox"
	illustration = "emp"
	starts_with = list(/obj/item/grenade/empgrenade = 5)

/obj/item/storage/box/smokes
	name = "box of smoke bombs"
	desc = "A box containing 5 smoke bombs."
	icon_state = "secbox"
	item_state = "secbox"
	illustration = "grenade"
	starts_with = list(/obj/item/grenade/smokebomb = 5)

/obj/item/storage/box/anti_photons
	name = "box of anti-photon grenades"
	desc = "A box containing 5 experimental photon disruption grenades."
	icon_state = "secbox"
	item_state = "secbox"
	illustration = "grenade"
	starts_with = list(/obj/item/grenade/anti_photon = 5)

/obj/item/storage/box/frags
	name = "box of frag grenades"
	desc = "A box containing 5 military grade fragmentation grenades.<br> WARNING: Live explosives. Misuse may result in serious injury or death."
	icon_state = "secbox"
	item_state = "secbox"
	illustration = "grenade"
	starts_with = list(/obj/item/grenade/frag = 5)

/obj/item/storage/box/grenades/napalm
	name = "box of napalm grenades"
	desc = "A box containing 3 napalm grenades."
	icon_state = "secbox"
	item_state = "secbox"
	illustration = "grenade"
	starts_with = list(/obj/item/grenade/napalm = 3)

/obj/item/storage/box/cardox
	name = "box of cardox grenades"
	desc = "A box containing 5 experimental cardox grenades."
	icon_state = "secbox"
	item_state = "secbox"
	illustration = "grenade"
	starts_with = list(/obj/item/grenade/chem_grenade/large/phoroncleaner = 5)

/obj/item/storage/box/trackimp
	name = "boxed tracking implant kit"
	desc = "Box full of scum-bag tracking utensils."
	icon_state = "secbox"
	item_state = "secbox"
	illustration = "implant"
	starts_with = list(/obj/item/implantcase/tracking = 4, /obj/item/implanter = 1, /obj/item/implantpad = 1, /obj/item/locator = 1)


/obj/item/storage/box/chemimp
	name = "boxed chemical implant kit"
	desc = "Box of stuff used to implant chemicals."
	illustration = "implant"
	starts_with = list(/obj/item/implantcase/chem = 4, /obj/item/implanter = 1, /obj/item/implantpad = 1)

/obj/item/storage/box/chemimp/fill()
	..()
	new /obj/item/implantcase/chem(src)
	new /obj/item/implantcase/chem(src)
	new /obj/item/implantcase/chem(src)
	new /obj/item/implantcase/chem(src)
	new /obj/item/implantcase/chem(src)
	new /obj/item/implanter(src)
	new /obj/item/implantpad(src)

/obj/item/storage/box/rxglasses
	name = "box of prescription glasses"
	desc = "This box contains nerd glasses."
	illustration = "glasses"
	starts_with = list(/obj/item/clothing/glasses/regular = 7)

/obj/item/storage/box/drinkingglasses
	name = "box of drinking glasses"
	desc = "It has a picture of drinking glasses on it."
	illustration = "drinkglass"
	starts_with = list(/obj/item/reagent_containers/food/drinks/drinkingglass = 6)

/obj/item/storage/box/cdeathalarm_kit
	name = "death alarm kit"
	desc = "Box of stuff used to implant death alarms."
	illustration = "implant"
	starts_with = list(/obj/item/implanter = 1, /obj/item/implantcase/death_alarm = 6, /obj/item/implantpad = 1)

/obj/item/storage/box/condimentbottles
	name = "box of condiment bottles"
	desc = "It has a large ketchup smear on it."
	illustration = "condiment"
	starts_with = list(/obj/item/reagent_containers/food/condiment = 6)

/obj/item/storage/box/cups
	name = "box of paper cups"
	illustration = "cup"
	desc = "It has pictures of paper cups on the front."
	starts_with = list(/obj/item/reagent_containers/food/drinks/sillycup = 7)

/obj/item/storage/box/donkpockets
	name = "box of donk-pockets"
	desc = "<B>Instructions:</B> <I>Heat in microwave. Product will cool if not eaten within seven minutes.</I>"
	icon_state = "donkpocketbox"
	item_state = "redbox"
	illustration = null
	starts_with = list(/obj/item/reagent_containers/food/snacks/donkpocket = 6)

/obj/item/storage/box/sinpockets
	name = "box of donk-pockets"
	desc = "<B>Instructions:</B> <I>Heat in microwave. Product will cool if not eaten within seven minutes.</I>"
	icon_state = "donkpocketbox"
	item_state = "redbox"
	illustration = null
	starts_with = list(/obj/item/reagent_containers/food/snacks/donkpocket/sinpocket = 6)

/obj/item/storage/box/sinpockets/antagonist_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "Crush bottom of each package to initiate chemical heating. Wait for 20 seconds before consumption."
	. += "Product will cool if not eaten within seven minutes."

/obj/item/storage/box/donkpockets/gwok
	name = "box of teriyaki Gwok-pockets"
	icon_state = "donkpocketboxteriyaki"
	item_state = "redbox"
	illustration = null
	starts_with = list(/obj/item/reagent_containers/food/snacks/donkpocket/teriyaki = 6)

/obj/item/storage/box/donkpockets/gwok/takoyaki
	name = "box of takoyaki Gwok-pockets"
	starts_with = list(/obj/item/reagent_containers/food/snacks/donkpocket/takoyaki = 6)

/obj/item/storage/box/janitorgloves
	name = "janitorial gloves box"
	desc = "A box full of janitorial gloves of all shapes and sizes."
	make_exact_fit = TRUE
	can_hold = list(
		/obj/item/clothing/gloves/janitor
	)
	starts_with = list(
		/obj/item/clothing/gloves/janitor = 1,
		/obj/item/clothing/gloves/janitor/tajara = 1,
		/obj/item/clothing/gloves/janitor/unathi = 1,
		/obj/item/clothing/gloves/janitor/vaurca = 1
	)

/obj/item/storage/box/monkeycubes
	name = "monkey cube box"
	desc = "Drymate brand monkey cubes. Just add water!"
	desc_extended = "The manufacture of a cubed animal produces subjects that are similar but have marked differences compared to their ordinary cousins. Higher brain functions are all but destroyed \
	and the life expectancy of the cubed animal is greatly reduced, with most expiring only a few days after introduction with water."
	icon_state = "monkeycubebox"
	illustration = null
	can_hold = list(/obj/item/reagent_containers/food/snacks/monkeycube)
	starts_with = list(/obj/item/reagent_containers/food/snacks/monkeycube/wrapped = 5)

/obj/item/storage/box/monkeycubes/farwacubes
	name = "farwa cube box"
	desc = "Drymate brand farwa cubes, shipped from Adhomai. Just add water!"
	starts_with = list(/obj/item/reagent_containers/food/snacks/monkeycube/wrapped/farwacube = 5)

/obj/item/storage/box/monkeycubes/stokcubes
	name = "stok cube box"
	desc = "Drymate brand stok cubes, shipped from Moghes. Just add water!"
	starts_with = list(/obj/item/reagent_containers/food/snacks/monkeycube/wrapped/stokcube = 5)

/obj/item/storage/box/monkeycubes/neaeracubes
	name = "neaera cube box"
	desc = "Drymate brand neaera cubes, shipped from Nralakk IV. Just add water!"
	starts_with = list(/obj/item/reagent_containers/food/snacks/monkeycube/wrapped/neaeracube = 5)

/obj/item/storage/box/monkeycubes/vkrexicubes
	name = "vkrexi cube box"
	desc = "Drymate brand vkrexi cubes. Just add water!"
	starts_with = list(/obj/item/reagent_containers/food/snacks/monkeycube/wrapped/vkrexicube = 5)

/obj/item/storage/box/ids
	name = "box of spare IDs"
	desc = "Has so many empty IDs."
	illustration = "id"
	starts_with = list(/obj/item/card/id = 7)

/obj/item/storage/box/handcuffs
	name = "box of spare handcuffs"
	desc = "A box full of handcuffs."
	icon_state = "secbox"
	item_state = "secbox"
	illustration = "handcuff"
	starts_with = list(/obj/item/handcuffs = 7)

/obj/item/storage/box/zipties
	name = "box of zipties"
	desc = "A box full of zipties."
	illustration = "handcuff"
	starts_with = list(/obj/item/handcuffs/ziptie = 7)

/obj/item/storage/box/mousetraps
	name = "box of Pest-B-Gon mousetraps"
	desc = "<B><span class='warning'>WARNING:</span></B> <I>Keep out of reach of children</I>."
	illustration = "mousetraps"
	starts_with = list(/obj/item/device/assembly/mousetrap = 6)

/obj/item/storage/box/pillbottles
	name = "box of pill bottles"
	desc = "It has pictures of pill bottles on its front."
	illustration = "pillbox"
	starts_with = list(/obj/item/storage/pill_bottle = 7)

/obj/item/storage/box/spraybottles
	name = "box of spray bottles"
	desc = "It has pictures of spray bottles on its front."
	illustration = "spray"
	starts_with = list(/obj/item/reagent_containers/spray = 7)

/obj/item/storage/box/snappops
	name = "snap pop box"
	desc = "Eight wrappers of fun! Ages 8 and up. Not suitable for children."
	icon = 'icons/obj/toy.dmi'
	icon_state = "spbox"
	can_hold = list(/obj/item/toy/snappop)
	starts_with = list(/obj/item/toy/snappop = 8)

/obj/item/storage/box/snappops/syndi
	starts_with = list(/obj/item/toy/snappop/syndi = 8)

/obj/item/storage/box/snappops/syndi/antagonist_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "These snap pops have an extra compound added that will deploy a tiny smokescreen when snapped."

/obj/item/storage/box/partypopper
	name = "party popper box"
	desc = "Six cones of confetti conflagarating fun!"
	illustration = "partypopper"
	starts_with = list(/obj/item/toy/partypopper = 6)

/obj/item/storage/box/autoinjectors
	name = "box of empty injectors"
	desc = "Contains empty autoinjectors."
	illustration = "epipen"
	starts_with = list(/obj/item/reagent_containers/hypospray/autoinjector = 7)

/obj/item/storage/box/lights
	name = "box of replacement bulbs"
	illustration = "light"
	desc = "This box is shaped on the inside so that only light tubes and bulbs fit."
	use_to_pickup = TRUE // for picking up broken bulbs, not that most people will try
	make_exact_fit = TRUE

/obj/item/storage/box/lights/bulbs
	starts_with = list(/obj/item/light/bulb = 21)

/obj/item/storage/box/lights/tubes
	name = "box of replacement tubes"
	illustration = "lighttube"
	starts_with = list(/obj/item/light/tube = 21)

/obj/item/storage/box/lights/mixed
	name = "box of replacement lights"
	illustration = "lightmixed"
	starts_with = list(/obj/item/light/tube = 14, /obj/item/light/bulb = 7)

/obj/item/storage/box/lights/coloredmixed
	name = "box of colored lights"
	illustration = "lightmixed"

/obj/item/storage/box/lights/coloredmixed/fill() // too lazy for this one
	..()
	var/static/list/tube_colors = list(
		/obj/item/light/tube/colored/red,
		/obj/item/light/tube/colored/green,
		/obj/item/light/tube/colored/blue,
		/obj/item/light/tube/colored/magenta,
		/obj/item/light/tube/colored/yellow,
		/obj/item/light/tube/colored/cyan
	)
	var/static/list/bulbs_colors = list(
		/obj/item/light/bulb/colored/red,
		/obj/item/light/bulb/colored/green,
		/obj/item/light/bulb/colored/blue,
		/obj/item/light/bulb/colored/magenta,
		/obj/item/light/bulb/colored/yellow,
		/obj/item/light/bulb/colored/cyan
	)
	for(var/i = 0, i < 14, i++)
		var/type = pick(tube_colors)
		new type(src)
	for(var/i = 0, i < 7, i++)
		var/type = pick(bulbs_colors)
		new type(src)

/obj/item/storage/box/lights/colored/red
	name = "box of red lights"
	illustration = "lightmixed"
	starts_with = list(/obj/item/light/tube/colored/red = 14, /obj/item/light/bulb/colored/red = 7)

/obj/item/storage/box/lights/colored/green
	name = "box of green lights"
	illustration = "lightmixed"
	starts_with = list(/obj/item/light/tube/colored/green = 14, /obj/item/light/bulb/colored/green = 7)

/obj/item/storage/box/lights/colored/blue
	name = "box of blue lights"
	illustration = "lightmixed"
	starts_with = list(/obj/item/light/tube/colored/blue = 14, /obj/item/light/bulb/colored/blue = 7)

/obj/item/storage/box/lights/colored/cyan
	name = "box of cyan lights"
	illustration = "lightmixed"
	starts_with = list(/obj/item/light/tube/colored/cyan = 14, /obj/item/light/bulb/colored/cyan = 7)

/obj/item/storage/box/lights/colored/yellow
	name = "box of yellow lights"
	illustration = "lightmixed"
	starts_with = list(/obj/item/light/tube/colored/yellow = 14, /obj/item/light/bulb/colored/yellow = 7)

/obj/item/storage/box/lights/colored/magenta
	name = "box of magenta lights"
	illustration = "lightmixed"
	starts_with = list(/obj/item/light/tube/colored/magenta = 14, /obj/item/light/bulb/colored/magenta = 7)

/obj/item/storage/box/freezer
	name = "portable freezer"
	desc = "This nifty shock-resistant device will keep your 'groceries' nice and non-spoiled."
	icon_state = "portafreezer"
	item_state = "medicalpack"
	max_w_class = WEIGHT_CLASS_NORMAL
	max_storage_space = DEFAULT_LARGEBOX_STORAGE
	use_to_pickup = FALSE // for picking up broken bulbs, not that most people will try
	chewable = FALSE

/obj/item/storage/box/freezer/organcooler
	name = "organ cooler"
	desc = "A sealed, cooled container to keep organs from decaying."
	icon_state = "organcooler"
	item_state = "redbox"
	max_w_class = WEIGHT_CLASS_NORMAL
	foldable = FALSE
	w_class = WEIGHT_CLASS_BULKY
	can_hold = list(
		/obj/item/organ,
		/obj/item/reagent_containers/food,
		/obj/item/reagent_containers/glass,
		/obj/item/gun
	)
	storage_slots = 2

/obj/item/storage/box/kitchen
	name = "kitchen supplies"
	illustration = "knife"
	desc = "Contains an assortment of utensils and containers useful in the preparation of food and drinks."

/obj/item/storage/box/kitchen/fill()
	new /obj/item/material/knife(src)//Should always have a knife

	var/list/utensils = list(
		/obj/item/material/kitchen/rollingpin,
		/obj/item/reagent_containers/glass/beaker,
		/obj/item/material/kitchen/utensil/fork,
		/obj/item/reagent_containers/food/condiment/enzyme,
		/obj/item/material/kitchen/utensil/spoon,
		/obj/item/material/kitchen/utensil/knife,
		/obj/item/reagent_containers/food/drinks/shaker
	)
	for (var/i = 0,i<6,i++)
		var/type = pick(utensils)
		new type(src)

/obj/item/storage/box/snack
	name = "rations box"
	illustration = "snack"
	desc = "Contains a random assortment of preserved foods. Guaranteed to remain edible* in room-temperature longterm storage for centuries!"

/obj/item/storage/box/snack/fill()
	var/list/snacks = list(
			/obj/item/reagent_containers/food/snacks/koisbar_clean,
			/obj/item/reagent_containers/food/snacks/candy,
			/obj/item/reagent_containers/food/snacks/candy/koko,
			/obj/item/reagent_containers/food/snacks/candy_corn,
			/obj/item/reagent_containers/food/snacks/chips,
			/obj/item/reagent_containers/food/snacks/chocolatebar,
			/obj/item/reagent_containers/food/snacks/chocolateegg,
			/obj/item/reagent_containers/food/snacks/popcorn,
			/obj/item/reagent_containers/food/snacks/sosjerky,
			/obj/item/reagent_containers/food/snacks/no_raisin,
			/obj/item/reagent_containers/food/snacks/spacetwinkie,
			/obj/item/reagent_containers/food/snacks/cheesiehonkers,
			/obj/item/reagent_containers/food/snacks/syndicake,
			/obj/item/reagent_containers/food/snacks/fortunecookie,
			/obj/item/reagent_containers/food/snacks/poppypretzel,
			/obj/item/reagent_containers/food/snacks/cracker,
			/obj/item/reagent_containers/food/snacks/liquidfood,
			/obj/item/reagent_containers/food/snacks/skrellsnacks,
			/obj/item/reagent_containers/food/snacks/tastybread,
			/obj/item/reagent_containers/food/snacks/meatsnack,
			/obj/item/reagent_containers/food/snacks/maps,
			/obj/item/reagent_containers/food/snacks/nathisnack,
			/obj/item/reagent_containers/food/snacks/adhomian_can,
			/obj/item/reagent_containers/food/snacks/tuna,
			/obj/item/storage/box/fancy/gum,
			/obj/item/storage/box/fancy/cookiesnack,
			/obj/item/storage/box/fancy/admints,
			/obj/item/storage/box/fancy/vkrexitaffy
	)
	for (var/i = 0,i<7,i++)
		var/type = pick(snacks)
		new type(src)

/obj/item/storage/box/stims
	name = "stimpack value kit"
	desc = "A box with several stimpack medipens for the economical miner."
	icon_state = "syringe"
	starts_with = list(/obj/item/reagent_containers/hypospray/autoinjector/stimpack = 4)

/obj/item/storage/box/inhalers
	name = "inhaler kit"
	desc = "A box filled with several inhalers and empty inhaler cartridges."
	illustration = "inhalers"
	starts_with = list(/obj/item/personal_inhaler = 2, /obj/item/reagent_containers/personal_inhaler_cartridge = 6)

/obj/item/storage/box/inhalers_large
	name = "combat inhaler kit"
	desc = "A box filled with a combat inhaler and several large empty inhaler cartridges."
	illustration = "inhalers"
	starts_with = list(/obj/item/personal_inhaler/combat = 1, /obj/item/reagent_containers/personal_inhaler_cartridge/large = 6)

/obj/item/storage/box/inhalers_auto
	name = "autoinhaler kit"
	desc = "A box filled with a combat inhaler and several large empty inhaler cartridges."
	icon_state = "secbox"
	item_state = "secbox"
	illustration = "inhalers"
	starts_with = list(/obj/item/reagent_containers/inhaler = 8)

/obj/item/storage/box/clams
	name = "box of Ras'val clam"
	desc = "A box filled with clams from the Ras'val sea, imported by Njadra'Akhar Enterprises."
	starts_with = list(/obj/item/reagent_containers/food/snacks/clam = 5)

/obj/item/storage/box/produce
	name = "produce box"
	desc = "A large box of random, leftover produce."
	icon_state = "largebox"
	illustration = "fruit"
	starts_with = list(/obj/random_produce/box = 15)
	make_exact_fit = TRUE


/obj/item/storage/box/candy
	name = "candy box"
	desc = "A large box of assorted small candy."
	icon_state = "largebox"
	illustration = "writing_large"
	make_exact_fit = TRUE

/obj/item/storage/box/candy/fill()
	var/list/assorted_list = list(
		/obj/item/reagent_containers/food/snacks/cb01 = 1,
		/obj/item/reagent_containers/food/snacks/cb02 = 1,
		/obj/item/reagent_containers/food/snacks/cb03 = 1,
		/obj/item/reagent_containers/food/snacks/cb04 = 1,
		/obj/item/reagent_containers/food/snacks/cb05 = 1,
		/obj/item/reagent_containers/food/snacks/cb06 = 1,
		/obj/item/reagent_containers/food/snacks/cb07 = 1,
		/obj/item/reagent_containers/food/snacks/cb08 = 1,
		/obj/item/reagent_containers/food/snacks/cb09 = 1,
		/obj/item/reagent_containers/food/snacks/cb10 = 1
	)

	for(var/i in 1 to 24)
		var/chosen_candy = pickweight(assorted_list)
		new chosen_candy(src)


/obj/item/storage/box/crabmeat
	name = "box of crab legs"
	desc = "A box filled with high-quality crab legs. Shipped on-board by popular demand!"
	starts_with = list(/obj/item/reagent_containers/food/snacks/crabmeat = 5)

/obj/item/storage/box/tranquilizer
	name = "box of tranquilizer darts"
	desc = "It has a picture of a tranquilizer dart and several warning symbols on the front.<br>WARNING: Live ammunition. Misuse may result in serious injury or death."
	icon_state = "shellbox"
	item_state = "shellbox"
	illustration = "incendiaryshot"
	drop_sound = 'sound/items/drop/ammobox.ogg'
	pickup_sound = 'sound/items/pickup/ammobox.ogg'
	starts_with = list(/obj/item/ammo_casing/tranq = 8)

/obj/item/storage/box/toothpaste
	can_hold = list(/obj/item/reagent_containers/toothpaste,
					/obj/item/reagent_containers/toothbrush,
					/obj/item/reagent_containers/food/drinks/flask/vacuumflask/mouthwash,
					)

	starts_with = list(/obj/item/reagent_containers/toothpaste = 1,
					/obj/item/reagent_containers/toothbrush = 1,
					/obj/item/reagent_containers/food/drinks/flask/vacuumflask/mouthwash = 1,
					)

/obj/item/storage/box/toothpaste/green
	starts_with = list(/obj/item/reagent_containers/toothpaste = 1,
					/obj/item/reagent_containers/toothbrush/green = 1,
					/obj/item/reagent_containers/food/drinks/flask/vacuumflask/mouthwash = 1,
					)

/obj/item/storage/box/toothpaste/red
	starts_with = list(/obj/item/reagent_containers/toothpaste = 1,
				/obj/item/reagent_containers/toothbrush/red = 1,
					/obj/item/reagent_containers/food/drinks/flask/vacuumflask/mouthwash = 1,
					)

/obj/item/storage/box/holobadge
	name = "holobadge box"
	desc = "A box claiming to contain holobadges."
	starts_with = list(/obj/item/clothing/accessory/badge/holo = 4,
				/obj/item/clothing/accessory/badge/holo/cord = 2)

/obj/item/storage/box/sol_visa
	name = "Sol Alliance visa recommendations box"
	desc = "A box full of Sol Aliance visa recommendation slips."
	illustration = "paper"
	starts_with = list(/obj/item/clothing/accessory/badge/sol_visa = 6)

/obj/item/storage/box/ceti_visa
	name = "TCAF recruitment papers box"
	desc = "A box full of papers that signify one as a recruit of the Tau Ceti Armed Forces."
	illustration = "paper"
	starts_with = list(/obj/item/clothing/accessory/badge/tcaf_papers = 6)

/obj/item/storage/box/hadii_card
	name = "honorary party member card box"
	desc = "A box full of Hadiist party member cards."
	illustration = "paper"
	starts_with = list(/obj/item/clothing/accessory/badge/hadii_card = 6)

/obj/item/storage/box/hadii_manifesto
	name = "hadiist manifesto box"
	desc = "A box filled with copies of the Hadiist Manifesto"
	illustration = "paper"
	starts_with = list(/obj/item/device/versebook/pra = 6)

/obj/item/storage/box/dpra_manifesto
	name = "al'mariist manifesto box"
	desc = "A box filled with copies of 'In Defense of Al'mari's Legacy'."
	illustration = "paper"
	starts_with = list(/obj/item/device/versebook/dpra = 6)

/obj/item/storage/box/nka_manifesto
	name = "royalist manifesto card box"
	desc = "A box filled with copies of 'The New Kingdom'."
	illustration = "paper"
	starts_with = list(/obj/item/device/versebook/nka = 6)

/obj/item/storage/box/suns_flags
	name = "s'rand'marr Worship flag box"
	desc = "A box filled with flags of the S'rend'marr faith."
	illustration = "flags"
	starts_with = list(
		/obj/item/flag/srendarr = 1,
		/obj/item/flag/messa = 1
	)

/obj/item/storage/box/matake_flags
	name = "ma'ta'ke pantheon flag box"
	desc = "A box filled to the brim with the various flags of the Ma'ta'ke Pantheon."
	illustration = "flags"
	starts_with = list(
		/obj/item/flag/matake = 1,
		/obj/item/flag/marryam = 1,
		/obj/item/flag/rredouane = 1,
		/obj/item/flag/shumaila = 1,
		/obj/item/flag/kraszar = 1,
		/obj/item/flag/dhrarmela = 1,
		/obj/item/flag/azubarre = 1
	)

/// Parent object of various national flag boxes. Original intention for random cargo spawn.
/obj/item/storage/box/flags
	name = "national flag box - PARENT ITEM DO NOT USE"
	desc = "A box filled to the brim with various flags."
	icon_state = "largebox"
	illustration = "flags"
	make_exact_fit = TRUE
	can_hold = list(
		/obj/item/flag
	)

/obj/item/storage/box/flags/sol
	name = "Solarian Alliance flag box"
	desc = "A box filled to the brim with various national flags."
	starts_with = list(
		/obj/item/flag/sol = 6,
		/obj/item/flag/sol/l = 4,
		/obj/item/flag/venus = 2,
		/obj/item/flag/venus/l = 1,
		/obj/item/flag/luna = 2,
		/obj/item/flag/luna/l = 1,
		/obj/item/flag/callisto = 2,
		/obj/item/flag/callisto/l = 1,
		/obj/item/flag/mars = 2,
		/obj/item/flag/mars/l = 1,
		/obj/item/flag/pluto = 2,
		/obj/item/flag/pluto/l = 1,
		/obj/item/flag/visegrad = 2,
		/obj/item/flag/visegrad/l = 1,
		/obj/item/flag/nhp = 2,
		/obj/item/flag/nhp/l = 1,
		/obj/item/flag/silversun = 2,
		/obj/item/flag/silversun/l = 1,
		/obj/item/flag/sancolette = 2,
		/obj/item/flag/sancolette/l = 1,
		/obj/item/flag/nsrm = 2,
		/obj/item/flag/nsrm/l = 1,
		/obj/item/flag/ssrm = 2,
		/obj/item/flag/ssrm/l = 1
	)

/obj/item/storage/box/flags/biesel
	name = "Republic of Biesel flag box"
	desc = "A box filled to the brim with various national flags."
	starts_with = list(
		/obj/item/flag/biesel = 6,
		/obj/item/flag/biesel/l = 4,
		/obj/item/flag/valkyrie = 2,
		/obj/item/flag/valkyrie/l = 1,
		/obj/item/flag/portantillia = 2,
		/obj/item/flag/portantillia/l = 1,
		/obj/item/flag/mictlan = 2,
		/obj/item/flag/mictlan/l = 1,
		/obj/item/flag/newgibson = 2,
		/obj/item/flag/newgibson/l = 1
	)

/obj/item/storage/box/flags/coc
	name = "Coalition of Colonies flag box"
	desc = "A box filled to the brim with various national flags."
	starts_with = list(
		/obj/item/flag/coalition = 6,
		/obj/item/flag/coalition/l = 4,
		/obj/item/flag/xanu = 2,
		/obj/item/flag/xanu/l = 1,
		/obj/item/flag/gadpathur = 2,
		/obj/item/flag/gadpathur/l = 1,
		/obj/item/flag/vysoka = 2,
		/obj/item/flag/vysoka/l = 1,
		/obj/item/flag/himeo = 2,
		/obj/item/flag/himeo/l = 1,
		/obj/item/flag/konyang = 2,
		/obj/item/flag/konyang/l = 1,
		/obj/item/flag/assunzione = 2,
		/obj/item/flag/assunzione/l = 1,
		/obj/item/flag/burzsia = 2,
		/obj/item/flag/burzsia/l = 1,
		/obj/item/flag/scarab = 3,
		/obj/item/flag/scarab/l = 2
	)

/obj/item/storage/box/flags/galataea
	name = "Technocracy of Galatea flag box"
	desc = "A box filled to the brim with various national flags."
	starts_with = list(
		/obj/item/flag/galatea_government = 4,
		/obj/item/flag/galatea_government/l = 3,
		/obj/item/flag/galatea = 2,
		/obj/item/flag/galatea/l = 1,
		/obj/item/flag/tsukuyomi = 2,
		/obj/item/flag/tsukuyomi/l = 1,
		/obj/item/flag/svarog = 2,
		/obj/item/flag/svarog/l = 1,
		/obj/item/flag/empyrean = 2,
		/obj/item/flag/empyrean/l = 1
	)

/obj/item/storage/box/flags/dominia
	name = "Empire of Dominia flag box"
	desc = "A box filled to the brim with various national flags."
	starts_with = list(
		/obj/item/flag/dominia = 8,
		/obj/item/flag/dominia/l = 6,
		/obj/item/flag/strelitz = 4,
		/obj/item/flag/volvalaad = 4,
		/obj/item/flag/kazhkz = 4,
		/obj/item/flag/caladius = 2,
		/obj/item/flag/zhao = 4,
		/obj/item/flag/diona = 2,
		/obj/item/flag/hansan = 2,
		/obj/item/flag/imperial_frontier = 3,
		/obj/item/flag/imperial_frontier/l = 2
	)

/obj/item/storage/box/flags/elyra
	name = "Serene Republic of Elyra flag box"
	desc = "A box filled to the brim with various national flags."
	starts_with = list(
		/obj/item/flag/elyra = 6,
		/obj/item/flag/elyra/l = 4,
		/obj/item/flag/persepolis = 2,
		/obj/item/flag/persepolis/l = 1,
		/obj/item/flag/damascus = 2,
		/obj/item/flag/damascus/l = 1,
		/obj/item/flag/medina = 2,
		/obj/item/flag/medina/l = 1,
		/obj/item/flag/newsuez = 2,
		/obj/item/flag/newsuez/l = 1,
		/obj/item/flag/aemaq = 2,
		/obj/item/flag/aemaq/l = 1
	)

/obj/item/storage/box/flags/diona
	name = "Diona flag box"
	desc = "A box filled to the brim with various national flags."
	starts_with = list(
		/obj/item/flag/consortium = 6,
		/obj/item/flag/consortium/l = 4,
		/obj/item/flag/ekane = 2,
		/obj/item/flag/ekane/l = 1,
		/obj/item/flag/narrows = 2,
		/obj/item/flag/narrows/l = 1
	)

/obj/item/storage/box/flags/unathi
	name = "Unathi flag box"
	desc = "A box filled to the brim with various national flags."
	starts_with = list(
		/obj/item/flag/hegemony = 6,
		/obj/item/flag/hegemony/l = 4,
		/obj/item/flag/ouerea/old = 4,
		/obj/item/flag/ouerea/old/l = 3,
		/obj/item/flag/fishingleague = 2
	)

/obj/item/storage/box/flags/skrell
	name = "Skrell flag box"
	desc = "A box filled to the brim with various waterproof national flags."
	starts_with = list(
		/obj/item/flag/nralakk = 8,
		/obj/item/flag/nralakk/l = 6,
		/obj/item/flag/traverse = 2,
		/obj/item/flag/traverse/l = 1
	)

/obj/item/storage/box/flags/tajara
	name = "Tajaran collected flag box"
	desc = "A box filled to the brim with various national flags. Whoever chose the selection for this one was either brave or stupid or both."
	starts_with = list(
		/obj/item/flag/dpra = 4,
		/obj/item/flag/dpra/l = 3,
		/obj/item/flag/pra = 4,
		/obj/item/flag/pra/l = 3,
		/obj/item/flag/nka = 4,
		/obj/item/flag/nka/l = 3,
		/obj/item/flag/ftc = 4,
		/obj/item/flag/ftc/l = 3
	)

/obj/item/storage/box/flags/vaurca
	name = "Vaurca flag box"
	desc = "A box filled to the brim with various hive flags."
	starts_with = list(
		/obj/item/flag/sedantis = 4,
		/obj/item/flag/sedantis/l = 3,
		/obj/item/flag/zora = 4,
		/obj/item/flag/zora/l = 3,
		/obj/item/flag/klax = 4,
		/obj/item/flag/klax/l = 3,
		/obj/item/flag/cthur = 4,
		/obj/item/flag/cthur/l = 3
	)

/obj/item/storage/box/flags/goldendeep
	name = "Golden Deep flag box"
	desc = "A box filled to the brim with various national flags. It's made from a bit sturdier board than most boxes."
	starts_with = list(
		/obj/item/flag/goldendeep = 8,
		/obj/item/flag/goldendeep/l = 6,
		// GD might not have a lot of flags but a single gold ingot included to broadcast their flagrant absurd wealth is kind of funny.
		/obj/item/stack/material/gold
	)

/obj/item/storage/box/flags/corporate
	name = "Corporate flag box"
	desc = "A box filled to the brim with various corporate flags, flying in service to the almighty credit."
	starts_with = list(
		/obj/item/flag/scc = 4,
		/obj/item/flag/scc/l = 3,
		/obj/item/flag/heph = 4,
		/obj/item/flag/heph/l = 3,
		/obj/item/flag/idris = 4,
		/obj/item/flag/idris/l = 3,
		/obj/item/flag/heph = 4,
		/obj/item/flag/heph/l = 3,
		/obj/item/flag/nanotrasen = 4,
		/obj/item/flag/nanotrasen/l = 3,
		/obj/item/flag/orion_express = 4,
		/obj/item/flag/orion_express/l = 3,
		/obj/item/flag/pmcg = 4,
		/obj/item/flag/pmcg/l = 3,
		/obj/item/flag/zavodskoi = 4,
		/obj/item/flag/zavodskoi/l = 3,
		/obj/item/flag/zenghu = 4,
		/obj/item/flag/zenghu/l = 3,
		/obj/item/flag/eridani = 4,
		/obj/item/flag/eridani/l = 3
	)

/// Random misc flags- either non-national or no longer in use or controversial or straight-up contraband. Randomized contents from Initialize().
/obj/item/storage/box/flags/misc
	name = "miscellaneous flag box"
	desc = "A box filled to the brim with various disorganized flags that might provoke a variety of reactions."

/**
 * We don't want this box to always have every possible misc flag every time it spawns. Mix it up each time.
 */

/obj/item/storage/box/flags/misc/fill()
	..()
	var/list/flag_options = list(
		/obj/item/flag/red_coalition = 1,
		/obj/item/flag/trinaryperfection = 2,
		/obj/item/flag/trinaryperfection/l = 1,
		/obj/item/flag/traditionalist = rand(1,2),
		/obj/item/flag/traditionalist/l = 1,
		/obj/item/flag/exclusionist = 1,
		/obj/item/flag/glaorr = 1,
		/obj/item/flag/glaorr/l = 1,
		/obj/item/flag/ouerea = rand(1,2),
		/obj/item/flag/ouerea/l = 1,
		/obj/item/flag/sol/old = rand(1,2),
		/obj/item/flag/sol/old/l = 1,
		/obj/item/flag/old_visegrad = rand(1,2),
		/obj/item/flag/old_visegrad/l = 1,
		/obj/item/flag/fisanduh = rand(1,2),
		/obj/item/flag/fisanduh/l = 1,
		/obj/item/flag/hiskyn = rand(1,2),
		/obj/item/flag/tarwa = rand(1,2),
		/obj/item/flag/izharshan = rand(1,2)
		)
	for(var/i in 1 to rand(5,8))
		var/flag = pickweight(flag_options)
		new flag(src)

/obj/item/storage/box/dominia_honor
	name = "dominian honor codex box"
	desc = "A box full of dominian honor codices."
	illustration = "paper"
	starts_with = list(/obj/item/book/manual/dominia_honor = 6)

/obj/item/storage/box/tcaf_pamphlet
	name = "tau ceti armed forces pamphlets box"
	desc = "A box full of tau ceti armed forces pamphlets."
	illustration = "paper"
	starts_with = list(/obj/item/book/manual/tcaf_pamphlet = 6)

/obj/item/storage/box/sharps
	name = "sharps disposal box"
	desc = "A plastic box for disposal of used needles and other sharp, potentially-contaminated tools. There is a large biohazard sign on the front."
	illustration = null
	icon_state = "sharpsbox"
	use_sound = 'sound/items/storage/briefcase.ogg'
	max_storage_space = DEFAULT_LARGEBOX_STORAGE
	chewable = FALSE
	foldable = null

/obj/item/storage/box/fountainpens
	name = "box of fountain pens"
	illustration = "fpen"
	starts_with = list(/obj/item/pen/fountain = 7)

/obj/item/storage/box/aggression
	illustration = "implant"
	max_storage_space = DEFAULT_BOX_STORAGE
	starts_with = list(/obj/item/implantcase/aggression = 6, /obj/item/implanter = 1, /obj/item/implantpad = 1)

/obj/item/storage/box/aggression/antagonist_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "This box contains various implants that will make their owners increasingly aggressive."

/obj/item/storage/box/encryption_key
	name = "box"
	illustration = "circuit"
	starts_with = list(/obj/item/device/encryptionkey/rev = 8)

/obj/item/storage/box/encryption_key/antagonist_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "This box contains encryption keys that gives the user a safe channel to chatter in. Access the safe comms with :x."

/obj/item/storage/box/dynamite
	name = "wooden crate"
	desc = "An ordinary wooden crate."
	icon_state = "dynamite"
	foldable = null
	illustration = null
	use_sound = 'sound/effects/doorcreaky.ogg'
	drop_sound = 'sound/items/drop/wooden.ogg'
	pickup_sound = 'sound/items/pickup/wooden.ogg'
	chewable = FALSE
	w_class = WEIGHT_CLASS_BULKY
	starts_with = list(/obj/item/grenade/dynamite = 6)

/obj/item/storage/box/dynamite/throw_impact(atom/hit_atom)
	..()
	spill()

/obj/item/storage/box/closet_teleporter
	illustration = "scicircuit"
	starts_with = list(/obj/item/closet_teleporter = 2)

/obj/item/storage/box/closet_teleporter/fill()
	var/obj/item/closet_teleporter/CT_1 = new /obj/item/closet_teleporter(src)
	var/obj/item/closet_teleporter/CT_2 = new /obj/item/closet_teleporter(src)
	CT_1.linked_teleporter = CT_2
	CT_2.linked_teleporter = CT_1

/obj/item/storage/box/folders
	name = "box of folders"
	desc = "A box full of folders."
	illustration = "paper"
	starts_with = list(/obj/item/folder = 5)

/obj/item/storage/box/folders/blue
	starts_with = list(/obj/item/folder/sec = 5)

/obj/item/storage/box/papersack
	name = "paper sack"
	desc = "A sack neatly crafted out of paper."
	icon = 'icons/obj/storage/paperbag.dmi'
	item_icons = list(
		slot_l_hand_str = 'icons/mob/items/lefthand.dmi',
		slot_r_hand_str = 'icons/mob/items/righthand.dmi',
		)
	item_state = "papersack"
	icon_state = "paperbag_None"
	use_sound = 'sound/bureaucracy/papercrumple.ogg'
	drop_sound = 'sound/items/drop/paper.ogg'
	pickup_sound = 'sound/items/storage/wrapper.ogg'
	foldable = null
	max_w_class = WEIGHT_CLASS_NORMAL
	max_storage_space = 8
	use_to_pickup = TRUE
	chewable = TRUE
	var/opened = TRUE
	var/static/list/papersack_designs
	var/choice = "None"

/obj/item/storage/box/papersack/update_icon()
	. = ..()
	if(length(contents) == 0)
		icon_state = "paperbag_[choice]"
	else if(length(contents) < 8)
		icon_state = "paperbag_[choice]-food"

/obj/item/storage/box/papersack/attackby(obj/item/attacking_item, mob/user)
	if(attacking_item.ispen())
		if(!papersack_designs)
			papersack_designs = sortList(list(
			"None" = image(icon = src.icon, icon_state = "paperbag_None"),
			"NanoTrasenStandard" = image(icon = src.icon, icon_state = "paperbag_NanoTrasenStandard"),
			"Idris" = image(icon = src.icon, icon_state = "paperbag_Idris"),
			"Heart" = image(icon = src.icon, icon_state = "paperbag_Heart"),
			"SmileyFace" = image(icon = src.icon, icon_state = "paperbag_SmileyFace")
			))

		var/selected = show_radial_menu(user, src, papersack_designs, radius = 42, tooltips = TRUE)
		if(!selected)
			return
		choice = selected
		switch(choice)
			if("None")
				desc = "A sack neatly crafted out of paper."
			if("NanoTrasenStandard")
				desc = "A standard NanoTrasen paper lunch sack for loyal employees on the go."
			if("Idris")
				desc = "A premium paper bag produced by Idris Incorporated."
			if("Heart")
				desc = "A paper sack with a heart etched onto the side."
			if("SmileyFace")
				desc = "A paper sack with a crude smile etched onto the side."
			else
				return
		to_chat(user, SPAN_NOTICE("You make some modifications to [src] using your pen."))
		update_icon()
		return

	else if(attacking_item.isscrewdriver())
		if(length(contents) == 0)
			to_chat(user, SPAN_NOTICE("You begin poking holes in \the [src]."))
			if(attacking_item.use_tool(src, user, 30))
				if(choice == "SmileyFace")
					var/obj/item/clothing/head/papersack/smiley/S = new()
					user.put_in_hands(S)
				else
					var/obj/item/clothing/head/papersack/PS = new()
					user.put_in_hands(PS)
				qdel(src)
		else
			to_chat(user, SPAN_WARNING("\The [src] needs to be empty before you can do that!"))
	else
		..()

// Flares
/obj/item/storage/box/flares
	name = "flares box"
	desc = "A box full of flares."
	icon_state = "largebox"
	illustration = "flare"
	foldable = FALSE
	max_storage_space = DEFAULT_BOX_STORAGE
	can_hold = list(
		/obj/item/device/flashlight/flare
	)
	starts_with = list(
		/obj/item/device/flashlight/flare = 12
	)

// Magnetic Locks
/obj/item/storage/box/magnetic_locks
	name = "magnetic lock box"
	desc = "A box full of magnetic locks."
	w_class = WEIGHT_CLASS_BULKY
	max_w_class = WEIGHT_CLASS_NORMAL
	foldable = FALSE
	max_storage_space = DEFAULT_BOX_STORAGE
	can_hold = list(
		/obj/item/device/magnetic_lock
	)
	starts_with = list(
		/obj/item/device/magnetic_lock = 4
	)

// Power Cells
/obj/item/storage/box/cell
	name = "power cell box"
	desc = "A box full of power cells."
	foldable = FALSE
	make_exact_fit = TRUE
	can_hold = list(
		/obj/item/cell
	)
	starts_with = list(
		/obj/item/cell = 3
	)

// High-capacity Power Cells
/obj/item/storage/box/cell/high
	name = "high-capacity power cell box"
	desc = "A box full of high-capacity power cells."
	starts_with = list(
		/obj/item/cell/high = 3
	)

/obj/item/storage/box/condiment
	name = "condiment box"
	desc = "A large box of condiments, syrups, flavorings."
	icon_state = "largebox"
	illustration = "condiment"
	starts_with = list(
		/obj/item/reagent_containers/food/condiment/enzyme = 1,
		/obj/item/reagent_containers/food/condiment/shaker/peppermill = 2,
		/obj/item/reagent_containers/food/condiment/shaker/salt = 2,
		/obj/item/reagent_containers/food/condiment/shaker/spacespice = 2,
		/obj/item/reagent_containers/food/condiment/shaker/sprinkles = 1,
		/obj/item/reagent_containers/food/condiment/sugar = 1,
		/obj/item/reagent_containers/food/condiment/shaker/pumpkinspice = 1,
		/obj/item/reagent_containers/glass/bottle/syrup/chocolate = 1,
		/obj/item/reagent_containers/glass/bottle/syrup/pumpkin = 1,
		/obj/item/reagent_containers/glass/bottle/syrup/vanilla = 1,
		/obj/item/reagent_containers/glass/bottle/syrup/caramel = 1,
	)

/obj/item/storage/box/cleaner_tablets
	name = "\improper Idris cleaner tablets box"
	desc = "A box of advanced formula chemical tablets designed by Idris Incorporated."
	desc_extended = "A new generation of cleaning chemicals, according to Idris at least. The instructions on the box reads: \"Dissolve tablet fully in container of water\". A warning label mentions that you should not consume the tablets nor drink the mixture after dissolving them."
	illustration = "soapbucket"
	starts_with = list(
		/obj/item/reagent_containers/pill/cleaner_tablet = 16
	)
	make_exact_fit = TRUE

/obj/item/storage/box/led_collars
	name = "box of LED collars"
	desc = "A box containing eight LED collars, usually worn around the neck of the voidsuit."
	starts_with = list(/obj/item/clothing/accessory/led_collar = 8)
	make_exact_fit = TRUE

/obj/item/storage/box/traps/punji
	name = "box of punji traps"
	desc = "A box containing 5 punji traps."
	starts_with = list(/obj/item/trap/punji = 5)

/obj/item/storage/box/landmines/standstill
	name = "box of standstill landmines"
	desc = "A box containing 5 standstill landmines."
	starts_with = list(/obj/item/landmine/standstill = 5)

/obj/item/storage/box/landmines/door_rigging
	name = "box of door rigging landmines"
	desc = "A box containing 5 door rigging landmines."
	starts_with = list(/obj/item/landmine/frag/door_rigging = 5)

/obj/item/storage/box/landmines/claymore
	name = "box of claymore landmines"
	desc = "A box containing 5 claymore landmines, relative detonators, and a spare one to trigger them all."
	starts_with = list(
		/obj/item/landmine/claymore = 5,
		/obj/item/device/assembly/signaler = 6
		)

/obj/item/storage/box/tea
	name = "sencha cha-tin"
	desc = "A tin bearing the logo of the Konyang-cha tea company. This one contains a bag of sencha, a type of green tea."
	desc_extended = "A subsidiary of Gwok Group, the Konyang-cha tea company is the spur's foremost vendor of artisanal loose leaf tea, \
				selling blends sourced from independent Konyanger farmers. Popular both on Konyang and off-world, it is considered a symbol of Konyang's culture."
	icon = 'icons/obj/item/reagent_containers/teaware.dmi'
	icon_state = "can"
	item_state = "can"
	drop_sound = 'sound/items/drop/metal_pot.ogg'
	pickup_sound = 'sound/items/drop/metal_pot.ogg'
	contained_sprite = TRUE
	make_exact_fit = TRUE
	can_hold = list(
		/obj/item/reagent_containers/food/snacks/grown/konyang_tea
	)
	starts_with = list(
		/obj/item/reagent_containers/food/snacks/grown/konyang_tea = 7
	)
	foldable = null

/obj/item/storage/box/tea/tieguanyin
	name = "tieguanyin cha-tin"
	desc = "A tin bearing the logo of the Konyang-cha tea company. This one contains a bag of tieguanyin, a type of oolong tea."
	icon_state = "can_tie"
	starts_with = list(
		/obj/item/reagent_containers/food/snacks/grown/konyang_tea/tieguanyin = 7
	)

/obj/item/storage/box/tea/jaekseol
	name = "jaekseol cha-tin"
	desc = "A tin bearing the logo of the Konyang-cha tea company. This one contains a bag of jaekseol, a type of black tea."
	icon_state = "can_jaek"
	starts_with = list(
		/obj/item/reagent_containers/food/snacks/grown/konyang_tea/jaekseol = 7
	)

/obj/item/storage/box/telefreedom_kit
	name = "telefreedom kit"
	desc = "A box containing a telefreedom full kit."
	starts_with = list(/obj/item/implant/telefreedom = 4,
					/obj/item/implanter = 1,
					//Telepad construction items
					/obj/item/circuitboard/telesci_pad = 1,
					/obj/item/bluespace_crystal/artificial = 2,
					/obj/item/stock_parts/capacitor = 1,
					/obj/item/stock_parts/console_screen = 1,
					)

/obj/item/storage/box/telefreedom_kit/fill()
	. = ..()
	new /obj/item/stack/cable_coil(src, 6)
	new /obj/item/stack/material/steel(src, 2)

/obj/item/storage/box/sawn_doublebarrel_shotgun
	name = "sawn-off Double-barrel shotgun kit"
	desc = "A box containing a sawn-off double-barrel shotgun, an holster and some ammo."
	starts_with = list(/obj/item/gun/projectile/shotgun/doublebarrel/sawn = 1,
						/obj/item/ammo_casing/shotgun/pellet = 6,
						/obj/item/clothing/accessory/holster/thigh = 1)

/obj/item/storage/box/stressball
	name = "box of stress balls"
	desc = "A box containing a number of randomly-coloured stress balls."
	starts_with = list(
		/obj/item/toy/stressball = 6
	)

/obj/item/storage/box/mms_inhaler
	name = "mms inhaler kit"
	desc = "A box filled with an inhaler and cartridges containing Mercury Monolithium Sucrose."
	illustration = "inhalers"
	starts_with = list(
		/obj/item/personal_inhaler = 1, /obj/item/reagent_containers/personal_inhaler_cartridge/mms = 3
	)

/obj/item/storage/box/ambrosia
	name = "ambrosia box"
	starts_with = list(
		/obj/item/reagent_containers/food/snacks/grown/ambrosiavulgaris/dried = 4
	)

/obj/item/storage/box/reishi
	name = "reishi box"
	starts_with = list(
		/obj/item/reagent_containers/food/snacks/grown/mushroom/reishi/dried = 4
	)

/obj/item/storage/box/wulumunusha
	name = "wulumunusha box"
	starts_with = list(
		/obj/item/reagent_containers/food/snacks/grown/wulumunusha/dried = 4
	)

/obj/item/storage/box/ale
	name = "pack of ale"
	desc = "A box containing a six pack of ale."
	illustration = "soda"
	starts_with = list(
		/obj/item/reagent_containers/food/drinks/bottle/small/ale = 6
	)

/obj/item/storage/box/beer
	name = "pack of beer"
	desc = "A box containing a six pack of beer."
	illustration = "soda"
	starts_with = list(
		/obj/item/reagent_containers/food/drinks/bottle/small/beer = 6
	)

/obj/item/storage/box/skrellbeerdyn
	name = "pack of dyn beer"
	desc = "A box containing a six pack of dyn beer."
	illustration = "soda"
	starts_with = list(
		/obj/item/reagent_containers/food/drinks/bottle/small/skrellbeerdyn = 6
	)

/obj/item/storage/box/xuizijuice
	name = "pack of xuizi juice"
	desc = "A box containing a six pack of xuizi juice."
	illustration = "soda"
	starts_with = list(
		/obj/item/reagent_containers/food/drinks/bottle/small/xuizijuice = 6
	)

/obj/item/storage/box/khlibnyz
	name = "pack of khlibnyz"
	desc = "A box containing a six pack of khlibnyz."
	illustration = "soda"
	starts_with = list(
		/obj/item/reagent_containers/food/drinks/bottle/small/khlibnyz = 6
	)

/obj/item/storage/box/cola
	name = "pack of cola"
	desc = "A box containing a six pack of cola."
	illustration = "soda"
	starts_with = list(
		/obj/item/reagent_containers/food/drinks/bottle/cola = 6
	)

/obj/item/storage/box/space_mountain_wind
	name = "pack of space mountain wind"
	desc = "A box containing a six pack of space mountain wind."
	illustration = "soda"
	starts_with = list(
		/obj/item/reagent_containers/food/drinks/bottle/space_mountain_wind = 6
	)

/obj/item/storage/box/space_up
	name = "pack of space-up"
	desc = "A box containing a six pack of space-up."
	illustration = "soda"
	starts_with = list(
		/obj/item/reagent_containers/food/drinks/bottle/space_up = 6
	)

/obj/item/storage/box/hrozamal_soda
	name = "pack of hrozamal soda"
	desc = "A box containing a six pack of hrozamal soda."
	illustration = "soda"
	starts_with = list(
		/obj/item/reagent_containers/food/drinks/bottle/hrozamal_soda = 6
	)

/obj/item/storage/box/midynhr_water
	name = "pack of midynhr water"
	desc = "A box containing a six pack of midynhr water."
	illustration = "soda"
	starts_with = list(
		/obj/item/reagent_containers/food/drinks/bottle/small/midynhr_water = 6
	)

/obj/item/storage/box/burukutu
	name = "pack of burukutu"
	desc = "A box containing a six pack of burukutu."
	illustration = "soda"
	starts_with = list(
		/obj/item/reagent_containers/food/drinks/bottle/small/burukutu = 6
	)

/obj/item/storage/box/crutch_pair
	starts_with = list(
		/obj/item/cane/crutch = 2
	)

/obj/item/storage/box/forearm_crutch_pair
	starts_with = list(
		/obj/item/cane/crutch/forearm = 2
	)
