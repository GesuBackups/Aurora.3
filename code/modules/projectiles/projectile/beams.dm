/obj/projectile/beam
	name = "laser"
	icon_state = "laser"
	ping_effect = "ping_s"
	pass_flags = PASSTABLE | PASSGLASS | PASSGRILLE | PASSRAILING
	damage = 30
	armor_penetration = 10
	damage_type = DAMAGE_BURN
	impact_sounds = list(BULLET_IMPACT_MEAT = SOUNDS_LASER_MEAT, BULLET_IMPACT_METAL = SOUNDS_LASER_METAL)
	check_armor = LASER
	eyeblur = 4
	damage_flags = DAMAGE_FLAG_LASER
	var/frequency = 1
	hitscan = 1
	invisibility = 101	//beam projectiles are invisible as they are rendered by the effect engine

	muzzle_type = /obj/effect/projectile/muzzle/laser
	tracer_type = /obj/effect/projectile/tracer/laser
	impact_type = /obj/effect/projectile/impact/laser

/obj/projectile/beam/practice
	name = "laser"
	damage = 5
	armor_penetration = 0
	damage_type = DAMAGE_PAIN
	eyeblur = 0

/obj/projectile/beam/pistol
	damage = 25
	armor_penetration = 5

/obj/projectile/beam/pistol/scc
	armor_penetration = 15

	muzzle_type = /obj/effect/projectile/muzzle/laser/scc
	tracer_type = /obj/effect/projectile/tracer/laser/scc
	impact_type = /obj/effect/projectile/impact/laser/scc

/obj/projectile/beam/pistol/scc/weak
	damage = 20
	armor_penetration = 10

	muzzle_type = /obj/effect/projectile/muzzle/laser/scc
	tracer_type = /obj/effect/projectile/tracer/laser/scc
	impact_type = /obj/effect/projectile/impact/laser/scc

/obj/projectile/beam/pistol/hegemony
	icon = 'icons/obj/guns/hegemony_pistol.dmi'
	icon_state = "hegemony_pistol"
	damage = 30

	muzzle_type = /obj/effect/projectile/muzzle/hegemony
	tracer_type = /obj/effect/projectile/tracer/hegemony
	impact_type = /obj/effect/projectile/impact/hegemony

/obj/projectile/beam/midlaser
	damage = 30
	armor_penetration = 20

/obj/projectile/beam/midlaser/skrell
	armor_penetration = 0

/obj/projectile/beam/midlaser/skrell/heavy
	damage = 40
	armor_penetration = 20

/obj/projectile/beam/midlaser/hegemony
	armor_penetration = 30
	muzzle_type = /obj/effect/projectile/muzzle/hegemony
	tracer_type = /obj/effect/projectile/tracer/hegemony
	impact_type = /obj/effect/projectile/impact/hegemony


/obj/projectile/beam/noctiluca
	damage = 20
	armor_penetration = 40

/obj/projectile/beam/noctiluca/armor_piercing
	name = "concentrated laser"
	damage = 20
	armor_penetration = 50

	muzzle_type = /obj/effect/projectile/muzzle/laser/scc
	tracer_type = /obj/effect/projectile/tracer/laser/scc
	impact_type = /obj/effect/projectile/impact/laser/scc

/obj/projectile/beam/midlaser/ice
	damage = 25
	armor_penetration = 10

/obj/projectile/beam/heavylaser
	name = "heavy laser"
	icon_state = "heavylaser"
	damage = 45
	armor_penetration = 25

	muzzle_type = /obj/effect/projectile/muzzle/heavy_laser
	tracer_type = /obj/effect/projectile/tracer/heavy_laser
	impact_type = /obj/effect/projectile/impact/heavy_laser

/obj/projectile/beam/heavylaser/mech
	damage = 35
	armor_penetration = 35

/obj/projectile/beam/xray
	name = "xray beam"
	icon_state = "xray"
	damage = 15
	armor_penetration = 50

	muzzle_type = /obj/effect/projectile/muzzle/xray
	tracer_type = /obj/effect/projectile/tracer/xray
	impact_type = /obj/effect/projectile/impact/xray

/obj/projectile/beam/xray/mech
	damage = 40
	armor_penetration = 75

/obj/projectile/beam/pulse
	name = "pulse"
	icon_state = "u_laser"
	damage = 50
	armor_penetration = 50

	muzzle_type = /obj/effect/projectile/muzzle/pulse
	tracer_type = /obj/effect/projectile/tracer/pulse
	impact_type = /obj/effect/projectile/impact/pulse

/obj/projectile/beam/pulse/mech
	damage = 45
	armor_penetration = 40

/obj/projectile/beam/pulse/on_hit(atom/target, blocked, def_zone)
	if(isturf(target))
		target.ex_act(2)
	. = ..()

/obj/projectile/beam/pulse/heavy
	name = "heavy pulse laser"
	icon_state = "pulse1_bl"
	var/life = 20

/obj/projectile/beam/pulse/heavy/Collide(atom/A)
	A.bullet_act(src, def_zone)
	src.life -= 10
	if(life <= 0)
		qdel(src)

/obj/projectile/beam/emitter
	name = "emitter beam"
	icon_state = "emitter"
	damage = 0 // The actual damage is computed in /code/modules/power/singularity/emitter.dm

	muzzle_type = /obj/effect/projectile/muzzle/emitter
	tracer_type = /obj/effect/projectile/tracer/emitter
	impact_type = /obj/effect/projectile/impact/emitter

/obj/projectile/beam/laser_tag
	name = "lasertag beam"
	icon_state = "laser"
	pass_flags = PASSTABLE | PASSGLASS | PASSGRILLE | PASSRAILING
	damage = 0
	damage_type = DAMAGE_BURN
	check_armor = LASER
	var/laser_tag_color = "red"

	muzzle_type = /obj/effect/projectile/muzzle/laser
	tracer_type = /obj/effect/projectile/tracer/laser
	impact_type = /obj/effect/projectile/impact/laser

/obj/projectile/beam/laser_tag/on_hit(atom/target, blocked, def_zone)
	. = ..()
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		var/obj/item/clothing/suit/armor/riot/laser_tag/LT = H.wear_suit
		if(istype(LT) && laser_tag_color != LT.laser_tag_color)
			LT.laser_hit()
	return TRUE

/obj/projectile/beam/laser_tag/blue
	name = "lasertag beam"
	icon_state = "bluelaser"
	laser_tag_color = "blue"

	muzzle_type = /obj/effect/projectile/muzzle/laser/blue
	tracer_type = /obj/effect/projectile/tracer/laser/blue
	impact_type = /obj/effect/projectile/impact/laser/blue

/obj/projectile/beam/laser_tag/omni//A laser tag bolt that stuns EVERYONE
	name = "lasertag beam"
	icon_state = "omnilaser"
	laser_tag_color = "omni"

	muzzle_type = /obj/effect/projectile/muzzle/disabler
	tracer_type = /obj/effect/projectile/tracer/disabler
	impact_type = /obj/effect/projectile/impact/disabler


/obj/projectile/beam/sniper
	name = "sniper beam"
	icon_state = "xray"
	damage = 50
	armor_penetration = 20
	stun = 3
	weaken = 3
	stutter = 3

	muzzle_type = /obj/effect/projectile/muzzle/xray
	tracer_type = /obj/effect/projectile/tracer/xray
	impact_type = /obj/effect/projectile/impact/xray

/obj/projectile/beam/stun
	name = "stun beam"
	icon_state = "stun"
	damage = 1
	sharp = FALSE
	eyeblur = 1
	agony = 45
	damage_type = DAMAGE_BURN

	muzzle_type = /obj/effect/projectile/muzzle/stun
	tracer_type = /obj/effect/projectile/tracer/stun
	impact_type = /obj/effect/projectile/impact/stun

/obj/projectile/beam/disorient
	name = "disorienting pulse"
	icon_state = "stun"
	damage = 1
	sharp = FALSE
	eyeblur = 1
	agony = 30
	damage_type = DAMAGE_BURN

	muzzle_type = /obj/effect/projectile/muzzle/disabler
	tracer_type = /obj/effect/projectile/tracer/disabler
	impact_type = /obj/effect/projectile/impact/disabler

/obj/projectile/beam/disorient/on_hit(atom/target, blocked, def_zone)
	if(ishuman(target) && blocked < 100 && !issilicon(target) && !isipc(target)) //Make them trip
		var/mob/living/carbon/human/H = target
		H.druggy = min(H.druggy + 15, 75)

		//do some maths to determine amount of dizzy to add
		var/makeDizzy = 250 - H.dizziness
		makeDizzy = min(makeDizzy, 50) //This should make it go back to 50
		H.make_dizzy(makeDizzy)

		H.confused = 5
		H.slurring = min(H.slurring + 15, 75)
	. = ..()

/obj/projectile/beam/gatlinglaser
	name = "diffused laser"
	icon_state = "heavylaser"
	damage = 20
	armor_penetration = 35

	muzzle_type = /obj/effect/projectile/muzzle/disabler
	tracer_type = /obj/effect/projectile/tracer/disabler
	impact_type = /obj/effect/projectile/impact/disabler

/obj/projectile/beam/mousegun
	name = "electrical arc"
	icon_state = "stun"
	damage = 1
	damage_type = DAMAGE_BURN

	muzzle_type = /obj/effect/projectile/muzzle/stun
	tracer_type = /obj/effect/projectile/tracer/stun
	impact_type = /obj/effect/projectile/impact/stun

/obj/projectile/beam/mousegun/on_hit(atom/target, blocked, def_zone)
	mousepulse(target, 1)
	. = ..()

/obj/projectile/beam/mousegun/proc/mousepulse(turf/epicenter, range, log=0)
	if(!epicenter)
		return

	if(!istype(epicenter, /turf))
		epicenter = get_turf(epicenter.loc)

	for(var/mob/living/M in range(range, epicenter))
		var/distance = get_dist(epicenter, M)
		if(distance < 0)
			distance = 0
		if(distance <= range)
			if (M.mob_size <= 3 && (M.find_type() & TYPE_ORGANIC))
				M.visible_message(SPAN_DANGER("\The [M] gets fried!"))
				M.color = "#4d4d4d" //get fried
				M.death()
				spark(M, 3, GLOB.alldirs)
			else if(iscarbon(M) && M.contents.len)
				for(var/obj/item/holder/H in M.contents)
					if(!H.contained)
						continue

					var/mob/living/A = H.contained
					if(!istype(A))
						continue

					if(A.mob_size <= 3 && (A.find_type() & TYPE_ORGANIC))
						H.release_mob()
						A.visible_message(SPAN_DANGER("\The [A] gets fried!"))
						A.color = "#4d4d4d" //get fried
						A.death()

			to_chat(M, 'sound/effects/basscannon.ogg')
	return TRUE

/obj/projectile/beam/mousegun/emag
	name = "diffuse electrical arc"
	damage_type = DAMAGE_BURN
	damage = 15
	agony = 30

/obj/projectile/beam/mousegun/emag/mousepulse(turf/epicenter, range, log=0)
	if(!epicenter)
		return

	if(!istype(epicenter, /turf))
		epicenter = get_turf(epicenter.loc)

	for(var/mob/living/M in range(range, epicenter))
		var/distance = get_dist(epicenter, M)
		if(distance < 0)
			distance = 0
		if(distance <= range)
			if(M.mob_size <= 4 && (M.find_type() & TYPE_ORGANIC))
				M.visible_message(SPAN_DANGER("[M] bursts like a balloon!"))
				M.gib()
				spark(M, 3, GLOB.alldirs)
			else if(iscarbon(M) && M.contents.len)
				for(var/obj/item/holder/H in M.contents)
					if(!H.contained)
						continue

					var/mob/living/A = H.contained
					if(!istype(A))
						continue

					if(A.mob_size <= 4 && (A.find_type() & TYPE_ORGANIC))
						H.release_mob()
						A.visible_message(SPAN_DANGER("[A] bursts like a balloon!"))
						A.gib()

			to_chat(M, 'sound/effects/basscannon.ogg')
	return TRUE

/obj/projectile/beam/mousegun/xenofauna
	damage = 10

/obj/projectile/beam/mousegun/xenofauna/mousepulse(atom/target, range, log)
	if(is_type_in_list(target, list(/mob/living/simple_animal/hostile/retaliate/cavern_dweller, /mob/living/simple_animal/hostile/carp, /mob/living/simple_animal/carp, /mob/living/simple_animal/hostile/giant_spider)))
		var/mob/living/simple_animal/SA = target
		SA.take_organ_damage(0, 20)
	return TRUE

/obj/projectile/beam/shotgun
	name = "diffuse laser"
	icon_state = "laser"
	pass_flags = PASSTABLE | PASSGLASS | PASSGRILLE | PASSRAILING
	damage = 20
	eyeblur = 4

/obj/projectile/beam/megaglaive
	name = "thermal lance"
	icon_state = "gauss"
	damage = 10
	incinerate = 5
	armor_penetration = 10

	muzzle_type = /obj/effect/projectile/muzzle/solar
	tracer_type = /obj/effect/projectile/tracer/solar
	impact_type = /obj/effect/projectile/impact/solar

/obj/projectile/beam/megaglaive/on_hit(atom/target, blocked, def_zone)
	if(isturf(target))
		if(istype(target, /turf/simulated/mineral))
			if(prob(75)) //likely because its a mining tool
				var/turf/simulated/mineral/M = target
				if(prob(10))
					M.GetDrilled(1)
				else if(!M.emitter_blasts_taken)
					M.emitter_blasts_taken += 1
				else if(prob(33))
					M.emitter_blasts_taken += 1
	if(ismob(target))
		var/mob/living/M = target
		M.apply_effect(1, INCINERATE, 0)
	explosion(target, -1, 0, 2)
	. = ..()

/obj/projectile/beam/thermaldrill
	name = "thermal drill"
	icon_state = "gauss"
	damage = 15

	muzzle_type = /obj/effect/projectile/muzzle/solar
	tracer_type = /obj/effect/projectile/tracer/solar
	impact_type = /obj/effect/projectile/impact/solar

/obj/projectile/beam/thermaldrill/on_hit(atom/target, blocked, def_zone)
	if(istype(target, /turf/simulated/mineral))
		var/turf/simulated/mineral/mineral = target
		mineral.GetDrilled(TRUE)
	return ..()



//Beams of magical veil energy fired by empowered pylons. Some inbuilt armor penetration cuz magic.
//Ablative armor is still overwhelmingly useful
//These beams are very weak but rapid firing, ~twice per second.
/obj/projectile/beam/cult
	name = "energy bolt"
	//For projectiles name is only shown in onhit messages, so its more of a layman's description
	//of what the projectile looks like
	damage = 3.5 //Very weak
	accuracy = 4 //Guided by magic, unlikely to miss
	eyeblur = 0 //Not bright or blinding
	var/mob/living/ignore

	muzzle_type = /obj/effect/projectile/muzzle/cult
	tracer_type = /obj/effect/projectile/tracer/cult
	impact_type = /obj/effect/projectile/impact/cult

/obj/projectile/beam/cult/on_hit(atom/target, blocked, def_zone)
	//Harmlessly passes through cultists and constructs
	if (target == ignore)
		return 0
	if (iscultist(target))
		return 0

	return ..()

/obj/projectile/beam/cult/heavy
	name = "glowing energy bolt"
	damage = 10 //Stronger and better armor penetration, though still much weaker than a typical laser
	armor_penetration = 10

	muzzle_type = /obj/effect/projectile/muzzle/cult/heavy
	tracer_type = /obj/effect/projectile/tracer/cult/heavy
	impact_type = /obj/effect/projectile/impact/cult/heavy

/obj/projectile/beam/energy_net
	name = "energy net projection"
	icon_state = "xray"
	damage = 0
	damage_type = DAMAGE_PAIN

	muzzle_type = /obj/effect/projectile/muzzle/xray
	tracer_type = /obj/effect/projectile/tracer/xray
	impact_type = /obj/effect/projectile/impact/xray

/obj/projectile/beam/energy_net/on_hit(atom/target, blocked, def_zone)
	do_net(target)
	. = ..()

/obj/projectile/beam/energy_net/proc/do_net(var/mob/M)
	var/obj/item/energy_net/net = new (get_turf(M))
	net.throw_impact(M)

/obj/projectile/beam/tachyon
	name = "particle beam"
	icon_state = "xray"
	damage = 25
	armor_penetration = 65
	penetrating = 1
	maim_rate = 5

	muzzle_type = /obj/effect/projectile/muzzle/tachyon
	tracer_type = /obj/effect/projectile/tracer/tachyon
	impact_type = /obj/effect/projectile/impact/tachyon

/obj/projectile/beam/tesla
	name = "tesla bolt"
	icon_state = "lightning"
	damage = 10
	damage_type = DAMAGE_BURN
	pass_flags = PASSTABLE | PASSGRILLE | PASSRAILING
	range = 40
	eyeblur = 0

	muzzle_type = /obj/effect/projectile/muzzle/tesla
	tracer_type = /obj/effect/projectile/tracer/tesla
	impact_type = /obj/effect/projectile/impact/tesla

/obj/projectile/beam/tesla/on_hit(atom/target, blocked, def_zone)
	. = ..()
	if(isliving(target))
		tesla_zap(target, 5, 5000)

/obj/projectile/beam/freezer
	name = "freezing ray"
	icon_state = "bluelaser"
	pass_flags = PASSTABLE | PASSRAILING
	damage = 15
	damage_type = DAMAGE_BURN
	check_armor = ENERGY

	muzzle_type = /obj/effect/projectile/muzzle/laser/blue
	tracer_type = /obj/effect/projectile/tracer/laser/blue
	impact_type = /obj/effect/projectile/impact/laser/blue

/obj/projectile/beam/freezer/on_hit(atom/target, blocked, def_zone)
	. = ..()
	if(isliving(target))
		var/mob/living/L = target
		L.bodytemperature -= 40

		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			if(H.bodytemperature <= H.species.cold_level_2)
				new /obj/structure/closet/statue/ice(H.loc, H)
				H.visible_message(SPAN_WARNING("\The [H] freezes!"))

/obj/projectile/beam/stun/skrell
	name = "particle stun beam"
	icon_state = "beam_omni"
	agony = 50

	muzzle_type = /obj/effect/projectile/muzzle/disabler
	tracer_type = /obj/effect/projectile/tracer/disabler
	impact_type = /obj/effect/projectile/impact/disabler

/obj/projectile/beam/pulse/skrell
	name = "particle lethal beam"
