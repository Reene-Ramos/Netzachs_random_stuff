/* Spreading Structures Code
	Stolen and edited from alien weed code. I wanted a spreading
	structure that doesnt have the atmospheric element attached to its root. */
/obj/structure/spreading
	name = "spreading structure"
	desc = "This thing seems to spread when supplied with a outside signal."
	max_integrity = 15
	anchored = TRUE
	density = FALSE
	layer = TURF_LAYER
	plane = FLOOR_PLANE
	var/conflict_damage = 10
	var/last_expand = 0 //last world.time this weed expanded
	var/expand_cooldown = 1.5 SECONDS
	var/can_expand = TRUE
	var/static/list/blacklisted_turfs

/obj/structure/spreading/Initialize()
	. = ..()

	if(!blacklisted_turfs)
		blacklisted_turfs = typecacheof(list(
			/turf/open/space,
			/turf/open/chasm,
			/turf/open/lava,
			/turf/open/openspace))

/obj/structure/spreading/proc/expand(bypasscooldown = FALSE)
	if(!can_expand)
		return

	if(!bypasscooldown)
		last_expand = world.time + expand_cooldown

	var/turf/U = get_turf(src)
	if(is_type_in_typecache(U, blacklisted_turfs))
		qdel(src)
		return FALSE

	var/list/spread_turfs = U.GetAtmosAdjacentTurfs()
	shuffle_inplace(spread_turfs)
	for(var/turf/T in spread_turfs)
		if(locate(/obj/structure/spreading) in T)
			var/obj/structure/spreading/S = locate(/obj/structure/spreading) in T
			if(S.type != type) //if it is not another of the same spreading structure.
				S.take_damage(conflict_damage, BRUTE, "melee", 1)
				break
			last_expand += (0.6 SECONDS) //if you encounter another of the same then the delay increases
			continue

		if(is_type_in_typecache(T, blacklisted_turfs))
			continue

		new type(T)
		break
	return TRUE

//Cosmetic Structures
/obj/structure/cavein_floor
	name = "blocked off floor entrance"
	desc = "An entrance to some underground facility that has been caved in."
	icon = 'ModularTegustation/Teguicons/lc13_structures.dmi'
	icon_state = "cavein_floor"
	anchored = TRUE

/obj/structure/cavein_door
	name = "blocked off facility entrance"
	desc = "A entrance to somewhere that has been blocked off with rubble."
	icon = 'ModularTegustation/Teguicons/32x48.dmi'
	icon_state = "cavein_door"
	pixel_y = -8
	base_pixel_y = -8
	anchored = TRUE

/**
 * List of button counters
 * Required as persistence subsystem loads after the ones present at mapload, and to reset to 0 upon explosion.
 */
GLOBAL_LIST_EMPTY(map_button_counters)
/obj/structure/sign/button_counter
	name = "button counter"
	sign_change_name = "Flip Sign- Days since buttoned"
	desc = "A pair of flip signs describe how long it's been since the last button incident."
	icon_state = "days_since_button"
	icon = 'ModularTegustation/Teguicons/button_counter.dmi'
	is_editable = TRUE
	var/since_last = 0

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/button_counter, 32)

/obj/structure/sign/button_counter/Initialize(mapload)
	. = ..()
	GLOB.map_button_counters += src
	if(!mapload)
		update_count(SSpersistence.rounds_since_button_pressed)

/obj/structure/sign/button_counter/Destroy()
	GLOB.map_button_counters -= src
	return ..()

/obj/structure/sign/button_counter/proc/update_count(new_count)
	since_last = min(new_count, 99)
	update_overlays()

/obj/structure/sign/button_counter/update_overlays()
	. = ..()

	var/ones = since_last % 10
	var/mutable_appearance/ones_overlay = mutable_appearance('ModularTegustation/Teguicons/button_counter.dmi', "days_[ones]")
	ones_overlay.pixel_x = 4
	. += ones_overlay

	var/tens = (since_last / 10) % 10
	var/mutable_appearance/tens_overlay = mutable_appearance('ModularTegustation/Teguicons/button_counter.dmi', "days_[tens]")
	tens_overlay.pixel_x = -5
	. += tens_overlay

/obj/structure/sign/button_counter/examine(mob/user)
	. = ..()
	. += span_info("It has been [since_last] day\s since the last button event at a Lobotomy facility.")
	switch(since_last)
		if(0)
			. += span_info("In case you didn't notice.")
		if(1)
			. += span_info("Let's do better today.")
		if(2 to 5)
			. += span_info("There's room for improvement.")
		if(6 to 10)
			. += span_info("Good work!")
		if(11 to INFINITY)
			. += span_info("Incredible!")
