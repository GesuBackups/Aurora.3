/obj/item/device/uv_light
	name = "\improper UV light"
	desc = "A small handheld black light."
	icon = 'icons/obj/item/device/uv_light.dmi'
	icon_state = "uv_off"
	item_state = "electronic"
	slot_flags = SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	matter = list(DEFAULT_WALL_MATERIAL = 150)
	origin_tech = list(TECH_MAGNET = 1, TECH_ENGINEERING = 1)
	var/list/scanned = list()
	var/list/stored_alpha = list()
	var/list/reset_objects = list()
	uv_intensity = 255
	var/range = 3
	var/on = 0
	var/step_alpha = 50

/obj/item/device/uv_light/attack_self(var/mob/user)
	on = !on
	if(on)
		set_light(range, 2, "#7700dd")
		START_PROCESSING(SSprocessing, src)
		icon_state = "uv_on"
	else
		set_light(0)
		clear_last_scan()
		STOP_PROCESSING(SSprocessing, src)
		icon_state = "uv_off"

/obj/item/device/uv_light/proc/clear_last_scan()
	if(scanned.len)
		for(var/atom/O in scanned)
			O.set_invisibility(scanned[O])
			if(O.fluorescent == 2) O.fluorescent = 1
		scanned.Cut()
	if(stored_alpha.len)
		for(var/atom/O in stored_alpha)
			O.alpha = stored_alpha[O]
			if(O.fluorescent == 2) O.fluorescent = 1
		stored_alpha.Cut()
	if(reset_objects.len)
		for(var/obj/item/I in reset_objects)
			I.CutOverlays(I.blood_overlay, ATOM_ICON_CACHE_PROTECTED)
			if(I.fluorescent == 2) I.fluorescent = 1
		reset_objects.Cut()

/obj/item/device/uv_light/process()
	clear_last_scan()
	if(on)
		step_alpha = round(255/range)
		var/turf/origin = get_turf(src)
		if(!origin)
			return
		for(var/turf/T in range(range, origin))
			var/use_alpha = 255 - (step_alpha * get_dist(origin, T))
			for(var/atom/A in T.contents)
				if(A.fluorescent == 1)
					A.fluorescent = 2 //To prevent light crosstalk.
					if(A.invisibility)
						scanned[A] = A.invisibility
						A.set_invisibility(0)
						stored_alpha[A] = A.alpha
						A.alpha = use_alpha
					if(istype(A, /obj/item))
						var/obj/item/O = A
						if(O.was_bloodied && !(O.blood_overlay in O.overlays))
							O.AddOverlays(O.blood_overlay, ATOM_ICON_CACHE_PROTECTED)
							reset_objects |= O
