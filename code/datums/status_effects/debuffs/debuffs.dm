//Largely negative status effects go here, even if they have small benificial effects
//STUN EFFECTS
/datum/status_effect/incapacitating
	id = STATUS_EFFECT_ID_ABSTRACT
	tick_interval = STATUS_EFFECT_NO_TICK // monkestation edit
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	remove_on_fullheal = TRUE
	heal_flag_necessary = HEAL_CC_STATUS
	processing_speed = STATUS_EFFECT_PRIORITY // monkestation edit: high-priority status effect processing
	var/needs_update_stat = FALSE

/datum/status_effect/incapacitating/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration))
		duration = set_duration
	. = ..()
	if(. && (needs_update_stat || issilicon(owner)))
		owner.update_stat()


/datum/status_effect/incapacitating/on_remove()
	if(needs_update_stat || issilicon(owner)) //silicons need stat updates in addition to normal canmove updates
		owner.update_stat()
	return ..()


//STUN
/datum/status_effect/incapacitating/stun
	id = "stun"

/datum/status_effect/incapacitating/stun/on_apply()
	. = ..()
	if(!.)
		return
	owner.add_traits(list(TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/stun/on_remove()
	owner.remove_traits(list(TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), TRAIT_STATUS_EFFECT(id))
	owner.stun_diminish = 1
	return ..()

//KNOCKDOWN
/datum/status_effect/incapacitating/knockdown
	id = "knockdown"

/datum/status_effect/incapacitating/knockdown/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_FLOORED, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/knockdown/on_remove()
	REMOVE_TRAIT(owner, TRAIT_FLOORED, TRAIT_STATUS_EFFECT(id))
	owner.knockdown_diminish = 1
	return ..()

// stupid subtype of knockdown for the sole purpose of not being considered a knockdown (to prevent shovestuns) but still having the same effects
/datum/status_effect/incapacitating/knockdown/tripped
	id = "tripped"

/datum/status_effect/incapacitating/knockdown/tripped/on_apply()
	// this is a horrible hack to make it so tripping doesn't drop items.
	// we just apply nodrop to their held items right before tripping them,
	// and then immediately remove it after the status effect is applied.
	// i'm sorry ~Lucy
	var/list/stupid_horrible_list = list()
	for(var/obj/item/item in owner.held_items)
		ADD_TRAIT(item, TRAIT_NODROP, TRAIT_STATUS_EFFECT(id))
		stupid_horrible_list += item
	. = ..()
	for(var/obj/item/item in stupid_horrible_list)
		REMOVE_TRAIT(item, TRAIT_NODROP, TRAIT_STATUS_EFFECT(id))

//IMMOBILIZED
/datum/status_effect/incapacitating/immobilized
	id = "immobilized"

/datum/status_effect/incapacitating/immobilized/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/immobilized/on_remove()
	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	return ..()


//PARALYZED
/datum/status_effect/incapacitating/paralyzed
	id = "paralyzed"

/datum/status_effect/incapacitating/paralyzed/on_apply()
	. = ..()
	if(!.)
		return
	owner.add_traits(list(TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_FLOORED, TRAIT_HANDS_BLOCKED), TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/paralyzed/on_remove()
	owner.remove_traits(list(TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_FLOORED, TRAIT_HANDS_BLOCKED), TRAIT_STATUS_EFFECT(id))
	owner.paralyze_diminish = 1
	return ..()

//INCAPACITATED
/// This status effect represents anything that leaves a character unable to perform basic tasks (interrupting do-afters, for example), but doesn't incapacitate them further than that (no stuns etc..)
/datum/status_effect/incapacitating/incapacitated
	id = "incapacitated"

// What happens when you get the incapacitated status. You get TRAIT_INCAPACITATED added to you for the duration of the status effect.
/datum/status_effect/incapacitating/incapacitated/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))

// When the status effect runs out, your TRAIT_INCAPACITATED is removed.
/datum/status_effect/incapacitating/incapacitated/on_remove()
	REMOVE_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))
	return ..()


//UNCONSCIOUS
/datum/status_effect/incapacitating/unconscious
	id = "unconscious"
	needs_update_stat = TRUE

/datum/status_effect/incapacitating/unconscious/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/unconscious/on_remove()
	REMOVE_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
	return ..()

/datum/status_effect/incapacitating/unconscious/tick()
	if(owner.stamina.loss)
		owner.stamina.adjust(0.3) //reduce stamina loss by 0.3 per tick, 6 per 2 seconds


//SLEEPING
/datum/status_effect/incapacitating/sleeping
	id = "sleeping"
	alert_type = /atom/movable/screen/alert/status_effect/asleep
	needs_update_stat = TRUE
	tick_interval = 2 SECONDS

/datum/status_effect/incapacitating/sleeping/on_apply()
	. = ..()
	if(!.)
		return
	if(HAS_TRAIT(owner, TRAIT_SLEEPIMMUNE))
		tick_interval = STATUS_EFFECT_NO_TICK
	else
		ADD_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
	RegisterSignal(owner, SIGNAL_ADDTRAIT(TRAIT_SLEEPIMMUNE), PROC_REF(on_owner_insomniac))
	RegisterSignal(owner, SIGNAL_REMOVETRAIT(TRAIT_SLEEPIMMUNE), PROC_REF(on_owner_sleepy))
	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(on_owner_death))

/datum/status_effect/incapacitating/sleeping/on_remove()
	UnregisterSignal(owner, list(SIGNAL_ADDTRAIT(TRAIT_SLEEPIMMUNE), SIGNAL_REMOVETRAIT(TRAIT_SLEEPIMMUNE), COMSIG_LIVING_DEATH))
	if(!HAS_TRAIT(owner, TRAIT_SLEEPIMMUNE))
		REMOVE_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
		tick_interval = initial(tick_interval)
	return ..()

/datum/status_effect/incapacitating/sleeping/proc/on_owner_death(mob/living/source)
	SIGNAL_HANDLER
	qdel(src)

///If the mob is sleeping and gain the TRAIT_SLEEPIMMUNE we remove the TRAIT_KNOCKEDOUT and stop the tick() from happening
/datum/status_effect/incapacitating/sleeping/proc/on_owner_insomniac(mob/living/source)
	SIGNAL_HANDLER
	REMOVE_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
	tick_interval = STATUS_EFFECT_NO_TICK

///If the mob has the TRAIT_SLEEPIMMUNE but somehow looses it we make him sleep and restart the tick()
/datum/status_effect/incapacitating/sleeping/proc/on_owner_sleepy(mob/living/source)
	SIGNAL_HANDLER
	ADD_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
	tick_interval = initial(tick_interval)

#define HEALING_SLEEP_DEFAULT 0.2

/datum/status_effect/incapacitating/sleeping/tick()
	if(owner.maxHealth)
		var/health_ratio = owner.health / owner.maxHealth
		var/healing = HEALING_SLEEP_DEFAULT

		// having high spirits helps us recover
		if(owner.mob_mood)
			switch(owner.mob_mood.sanity_level)
				if(SANITY_LEVEL_GREAT)
					healing = 0.2
				if(SANITY_LEVEL_NEUTRAL)
					healing = 0.1
				if(SANITY_LEVEL_DISTURBED)
					healing = 0
				if(SANITY_LEVEL_UNSTABLE)
					healing = 0
				if(SANITY_LEVEL_CRAZY)
					healing = -0.1
				if(SANITY_LEVEL_INSANE)
					healing = -0.2

		var/turf/rest_turf = get_turf(owner)
		var/is_sleeping_in_darkness = rest_turf.get_lumcount() <= LIGHTING_TILE_IS_DARK

		// sleeping with a blindfold or in the dark helps us rest
		if(owner.is_blind_from(EYES_COVERED) || is_sleeping_in_darkness)
			healing += 0.1

		// sleeping in silence is always better
		if(HAS_TRAIT(owner, TRAIT_DEAF))
			healing += 0.1

		// check for beds
		if((locate(/obj/structure/bed) in owner.loc))
			healing += 0.2
		else if((locate(/obj/structure/table) in owner.loc))
			healing += 0.1

		// don't forget the bedsheet
		if(locate(/obj/item/bedsheet) in owner.loc)
			healing += 0.1

		// you forgot the pillow
		if(locate(/obj/item/pillow) in owner.loc)
			healing += 0.1

		if(healing > 0 && health_ratio > 0.8)
			owner.adjustBruteLoss(-1 * healing, required_bodytype = BODYTYPE_ORGANIC)
			owner.adjustFireLoss(-1 * healing, required_bodytype = BODYTYPE_ORGANIC)
			owner.adjustToxLoss(-1 * healing * 0.5, TRUE, TRUE, required_biotype = MOB_ORGANIC)
		owner.stamina.adjust(-min(-1 * healing, -1 * HEALING_SLEEP_DEFAULT))
	// Drunkenness gets reduced by 0.3% per tick (6% per 2 seconds)
	owner.set_drunk_effect(owner.get_drunk_amount() * 0.997)

	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.handle_dreams()

	if(prob(2) && owner.health > owner.crit_threshold)
		owner.emote("snore")

#undef HEALING_SLEEP_DEFAULT

/atom/movable/screen/alert/status_effect/asleep
	name = "Asleep"
	desc = "You've fallen asleep. Wait a bit and you should wake up. Unless you don't, considering how helpless you are."
	icon_state = "asleep"

//STASIS
/datum/status_effect/grouped/stasis
	id = "stasis"
	duration = STATUS_EFFECT_PERMANENT
	alert_type = /atom/movable/screen/alert/status_effect/stasis
	var/last_dead_time

/datum/status_effect/grouped/stasis/proc/update_time_of_death()
	if(last_dead_time)
		var/delta = world.time - last_dead_time
		var/new_timeofdeath = owner.timeofdeath + delta
		owner.timeofdeath = new_timeofdeath
		owner.tod = station_time_timestamp(wtime=new_timeofdeath)
		last_dead_time = null
	if(owner.stat == DEAD)
		last_dead_time = world.time

/datum/status_effect/grouped/stasis/on_creation(mob/living/new_owner, set_duration)
	. = ..()
	if(.)
		update_time_of_death()
		owner.reagents?.end_metabolization(owner, FALSE)

/datum/status_effect/grouped/stasis/on_apply()
	. = ..()
	if(!.)
		return
	owner.add_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED, TRAIT_STASIS), TRAIT_STATUS_EFFECT(id))
	owner.add_filter("stasis_status_ripple", 2, list("type" = "ripple", "flags" = WAVE_BOUNDED, "radius" = 0, "size" = 2))
	var/filter = owner.get_filter("stasis_status_ripple")
	animate(filter, radius = 0, time = 0.2 SECONDS, size = 2, easing = JUMP_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(radius = 32, time = 1.5 SECONDS, size = 0)
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.update_bodypart_bleed_overlays()

/datum/status_effect/grouped/stasis/tick()
	update_time_of_death()

/datum/status_effect/grouped/stasis/on_remove()
	owner.remove_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED, TRAIT_STASIS), TRAIT_STATUS_EFFECT(id))
	owner.remove_filter("stasis_status_ripple")
	update_time_of_death()
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.update_bodypart_bleed_overlays()
	return ..()

/atom/movable/screen/alert/status_effect/stasis
	name = "Stasis"
	desc = "Your biological functions have halted. You could live forever this way, but it's pretty boring."
	icon_state = "stasis"

/datum/status_effect/his_wrath //does minor damage over time unless holding His Grace
	id = "his_wrath"
	duration = STATUS_EFFECT_PERMANENT
	tick_interval = 4
	alert_type = /atom/movable/screen/alert/status_effect/his_wrath

/atom/movable/screen/alert/status_effect/his_wrath
	name = "His Wrath"
	desc = "You fled from His Grace instead of feeding Him, and now you suffer."
	icon_state = "his_grace"
	alerttooltipstyle = "hisgrace"

/datum/status_effect/his_wrath/tick()
	for(var/obj/item/his_grace/HG in owner.held_items)
		qdel(src)
		return
	owner.adjustBruteLoss(0.1)
	owner.adjustFireLoss(0.1)
	owner.adjustToxLoss(0.2, TRUE, TRUE)

/datum/status_effect/cultghost //is a cult ghost and can't use manifest runes
	id = "cult_ghost"
	duration = STATUS_EFFECT_PERMANENT
	alert_type = null

/datum/status_effect/cultghost/on_apply()
	owner.set_invis_see(SEE_INVISIBLE_OBSERVER)
	return TRUE

/datum/status_effect/cultghost/tick()
	if(owner.reagents)
		owner.reagents.del_reagent(/datum/reagent/water/holywater) //can't be deconverted

/datum/status_effect/crusher_mark
	id = "crusher_mark"
	duration = 300 //if you leave for 30 seconds you lose the mark, deal with it
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	var/mutable_appearance/marked_underlay
	var/obj/item/kinetic_crusher/hammer_synced


/datum/status_effect/crusher_mark/on_creation(mob/living/new_owner, obj/item/kinetic_crusher/new_hammer_synced)
	. = ..()
	if(.)
		hammer_synced = new_hammer_synced

/datum/status_effect/crusher_mark/on_apply()
	var/list/factions = list(FACTION_MINING, FACTION_BOSS) // MONKESTATION ADDITION
	if(faction_check(owner.faction, factions)) //MONKESTATION EDIT, only marks mining mobs no longer large mobs
		marked_underlay = mutable_appearance('icons/effects/effects.dmi', "shield2")
		marked_underlay.pixel_x = -owner.pixel_x
		marked_underlay.pixel_y = -owner.pixel_y
		owner.underlays += marked_underlay
		return TRUE
	return FALSE

/datum/status_effect/crusher_mark/Destroy()
	hammer_synced = null
	if(owner)
		owner.underlays -= marked_underlay
	marked_underlay = null
	return ..()

/datum/status_effect/crusher_mark/be_replaced()
	owner.underlays -= marked_underlay //if this is being called, we should have an owner at this point.
	..()

/datum/status_effect/stacking/saw_bleed
	id = "saw_bleed"
	tick_interval = 6
	delay_before_decay = 5
	stack_threshold = 10
	max_stacks = 10
	overlay_file = 'icons/effects/bleed.dmi'
	underlay_file = 'icons/effects/bleed.dmi'
	overlay_state = "bleed"
	underlay_state = "bleed"
	var/bleed_damage = 200

/datum/status_effect/stacking/saw_bleed/fadeout_effect()
	new /obj/effect/temp_visual/bleed(get_turf(owner))

/datum/status_effect/stacking/saw_bleed/threshold_cross_effect()
	owner.adjustBruteLoss(bleed_damage)
	new /obj/effect/temp_visual/bleed/explode(owner.loc)
	for(var/d in GLOB.alldirs)
		owner.do_splatter_effect(d)
	playsound(owner, SFX_DESECRATION, 100, TRUE, -1)

/datum/status_effect/stacking/saw_bleed/bloodletting
	id = "bloodletting"
	stack_threshold = 7
	max_stacks = 7
	bleed_damage = 20

/datum/status_effect/neck_slice
	id = "neck_slice"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null
	duration = STATUS_EFFECT_PERMANENT

/datum/status_effect/neck_slice/on_apply()
	if(!ishuman(owner))
		return FALSE
	if(!owner.get_bodypart(BODY_ZONE_HEAD))
		return FALSE
	return TRUE

/datum/status_effect/neck_slice/tick()
	var/obj/item/bodypart/throat = owner.get_bodypart(BODY_ZONE_HEAD)
	if(owner.stat == DEAD || !throat) // they can lose their head while it's going.
		qdel(src)
		return

	var/still_bleeding = FALSE
	for(var/datum/wound/bleeding_thing as anything in throat.wounds)
		var/datum/wound_pregen_data/pregen_data = GLOB.all_wound_pregen_data[bleeding_thing.type]

		if(pregen_data.wounding_types_valid(list(WOUND_SLASH)) && bleeding_thing.severity > WOUND_SEVERITY_MODERATE && bleeding_thing.blood_flow > 0)
			still_bleeding = TRUE
			break
	if(!still_bleeding)
		qdel(src)
		return

	if(prob(10))
		owner.emote(pick("gasp", "gag", "choke"))

/datum/status_effect/neck_slice/get_examine_text()
	return span_warning("[owner.p_their(TRUE)] neck is cut and is bleeding profusely!")

/mob/living/proc/apply_necropolis_curse(set_curse)
	var/datum/status_effect/necropolis_curse/C = has_status_effect(/datum/status_effect/necropolis_curse)
	if(!set_curse)
		set_curse = pick(CURSE_BLINDING, CURSE_SPAWNING, CURSE_WASTING, CURSE_GRASPING)
	if(QDELETED(C))
		apply_status_effect(/datum/status_effect/necropolis_curse, set_curse)
	else
		C.apply_curse(set_curse)
		C.duration += 3000 //time added by additional curses
	return C

/datum/status_effect/necropolis_curse
	id = "necrocurse"
	duration = 6000 //you're cursed for 10 minutes have fun
	tick_interval = 50
	alert_type = null
	var/curse_flags = NONE
	var/effect_last_activation = 0
	var/effect_cooldown = 100
	var/obj/effect/temp_visual/curse/wasting_effect = new

/datum/status_effect/necropolis_curse/on_creation(mob/living/new_owner, set_curse)
	. = ..()
	if(.)
		apply_curse(set_curse)

/datum/status_effect/necropolis_curse/Destroy()
	if(!QDELETED(wasting_effect))
		qdel(wasting_effect)
		wasting_effect = null
	return ..()

/datum/status_effect/necropolis_curse/on_remove()
	remove_curse(curse_flags)

/datum/status_effect/necropolis_curse/proc/apply_curse(set_curse)
	curse_flags |= set_curse
	if(curse_flags & CURSE_BLINDING)
		owner.overlay_fullscreen("curse", /atom/movable/screen/fullscreen/curse, 1)

/datum/status_effect/necropolis_curse/proc/remove_curse(remove_curse)
	if(remove_curse & CURSE_BLINDING)
		owner.clear_fullscreen("curse", 50)
	curse_flags &= ~remove_curse

/datum/status_effect/necropolis_curse/tick()
	if(owner.stat == DEAD)
		return
	if(curse_flags & CURSE_WASTING)
		wasting_effect.forceMove(owner.loc)
		wasting_effect.setDir(owner.dir)
		wasting_effect.transform = owner.transform //if the owner has been stunned the overlay should inherit that position
		wasting_effect.alpha = 255
		animate(wasting_effect, alpha = 0, time = 32)
		playsound(owner, 'sound/effects/curse5.ogg', 20, TRUE, -1)
		owner.adjustFireLoss(0.75)
	if(effect_last_activation <= world.time)
		effect_last_activation = world.time + effect_cooldown
		if(curse_flags & CURSE_SPAWNING)
			var/turf/spawn_turf
			var/sanity = 10
			while(!spawn_turf && sanity)
				spawn_turf = locate(owner.x + pick(rand(10, 15), rand(-10, -15)), owner.y + pick(rand(10, 15), rand(-10, -15)), owner.z)
				sanity--
			if(spawn_turf)
				var/mob/living/simple_animal/hostile/asteroid/curseblob/C = new (spawn_turf)
				C.set_target = owner
				C.GiveTarget()
		if(curse_flags & CURSE_GRASPING)
			var/grab_dir = turn(owner.dir, pick(-90, 90, 180, 180)) //grab them from a random direction other than the one faced, favoring grabbing from behind
			var/turf/spawn_turf = get_ranged_target_turf(owner, grab_dir, 5)
			if(spawn_turf)
				grasp(spawn_turf)

/datum/status_effect/necropolis_curse/proc/grasp(turf/spawn_turf)
	set waitfor = FALSE
	new/obj/effect/temp_visual/dir_setting/curse/grasp_portal(spawn_turf, owner.dir)
	playsound(spawn_turf, 'sound/effects/curse2.ogg', 80, TRUE, -1)
	var/obj/projectile/curse_hand/C = new (spawn_turf)
	C.preparePixelProjectile(owner, spawn_turf)
	C.fire()

/obj/effect/temp_visual/curse
	icon_state = "curse"

/obj/effect/temp_visual/curse/Initialize(mapload)
	. = ..()
	deltimer(timerid)


/datum/status_effect/gonbola_pacify
	id = "gonbolaPacify"
	status_type = STATUS_EFFECT_MULTIPLE
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = null

/datum/status_effect/gonbola_pacify/on_apply()
	. = ..()
	owner.add_traits(list(TRAIT_PACIFISM, TRAIT_MUTE), REF(src))
	owner.add_mood_event(type, /datum/mood_event/gondola)
	to_chat(owner, span_notice("You suddenly feel at peace and feel no need to make any sudden or rash actions..."))

/datum/status_effect/gonbola_pacify/on_remove()
	owner.remove_traits(list(TRAIT_PACIFISM, TRAIT_MUTE), REF(src))
	owner.clear_mood_event(type)
	return ..()

/datum/status_effect/trance
	id = "trance"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 300
	tick_interval = 10
	var/stun = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/trance

/atom/movable/screen/alert/status_effect/trance
	name = "Trance"
	desc = "Everything feels so distant, and you can feel your thoughts forming loops inside your head..."
	icon_state = "high"

/datum/status_effect/trance/tick()
	if(stun)
		owner.Stun(6 SECONDS, TRUE)
	owner.set_dizzy(40 SECONDS)

/datum/status_effect/trance/on_apply()
	if(!iscarbon(owner))
		return FALSE
	RegisterSignal(owner, COMSIG_MOVABLE_HEAR, PROC_REF(hypnotize))
	ADD_TRAIT(owner, TRAIT_MUTE, TRAIT_STATUS_EFFECT(id))
	owner.add_client_colour(/datum/client_colour/monochrome/trance)
	owner.visible_message("[stun ? span_warning("[owner] stands still as [owner.p_their()] eyes seem to focus on a distant point.") : ""]", \
	span_warning(pick("You feel your thoughts slow down...", "You suddenly feel extremely dizzy...", "You feel like you're in the middle of a dream...","You feel incredibly relaxed...")))
	return TRUE

/datum/status_effect/trance/on_creation(mob/living/new_owner, _duration, _stun = TRUE)
	duration = _duration
	stun = _stun
	return ..()

/datum/status_effect/trance/on_remove()
	UnregisterSignal(owner, COMSIG_MOVABLE_HEAR)
	REMOVE_TRAIT(owner, TRAIT_MUTE, TRAIT_STATUS_EFFECT(id))
	owner.remove_status_effect(/datum/status_effect/dizziness)
	owner.remove_client_colour(/datum/client_colour/monochrome/trance)
	to_chat(owner, span_warning("You snap out of your trance!"))

/datum/status_effect/trance/get_examine_text()
	return span_warning("[owner.p_they(TRUE)] seem[owner.p_s()] slow and unfocused.")

/datum/status_effect/trance/proc/hypnotize(datum/source, list/hearing_args)
	SIGNAL_HANDLER

	if(!owner.can_hear() || owner == hearing_args[HEARING_SPEAKER])
		return

	var/mob/hearing_speaker = hearing_args[HEARING_SPEAKER]
	var/mob/living/carbon/C = owner
	C.cure_trauma_type(/datum/brain_trauma/hypnosis, TRAUMA_RESILIENCE_SURGERY) //clear previous hypnosis
	// The brain trauma itself does its own set of logging, but this is the only place the source of the hypnosis phrase can be found.
	hearing_speaker.log_message("hypnotised [key_name(C)] with the phrase '[hearing_args[HEARING_RAW_MESSAGE]]'", LOG_ATTACK, color="red")
	C.log_message("has been hypnotised by the phrase '[hearing_args[HEARING_RAW_MESSAGE]]' spoken by [key_name(hearing_speaker)]", LOG_VICTIM, color="orange", log_globally = FALSE)
	addtimer(CALLBACK(C, TYPE_PROC_REF(/mob/living/carbon, gain_trauma), /datum/brain_trauma/hypnosis, TRAUMA_RESILIENCE_SURGERY, hearing_args[HEARING_RAW_MESSAGE]), 10)
	addtimer(CALLBACK(C, TYPE_PROC_REF(/mob/living, Stun), 60, TRUE, TRUE), 15) //Take some time to think about it
	qdel(src)

/datum/status_effect/spasms
	id = "spasms"
	status_type = STATUS_EFFECT_MULTIPLE
	alert_type = null
// MONKESTATION ADDITION START
	var/mutation_synchronizer = 1
	var/mutation_power = 1
	var/mutation_energy = 1
// MONKESTATION ADDITION END

/datum/status_effect/spasms/tick()
	if(owner.stat >= UNCONSCIOUS)
		return
//	if(!prob(15)) // MONKESTATION EDIT OLD
	if(!prob(15 * mutation_synchronizer / mutation_energy)) // MONKESTATION EDIT NEW
		return
	switch(rand(1,5))
		if(1)
			if((owner.mobility_flags & MOBILITY_MOVE) && isturf(owner.loc))
				to_chat(owner, span_warning("Your leg spasms!"))
				step(owner, pick(GLOB.cardinals))
				// MONKESTATION ADDITION START
				if(mutation_power > 1)
					var/obj/item/bodypart/leg = owner.get_bodypart("[prob(50) ? "l" : "r"]_leg")
					leg.receive_damage(2 * mutation_power)
				// MONKESTATION ADDITION END
		if(2)
			if(owner.incapacitated())
				return
			// MONKESTATION ADDITION START
			if(mutation_power > 1)
				var/active_arm_dir = owner.held_index_to_dir(owner.active_hand_index)
				var/obj/item/bodypart/arm = owner.get_bodypart("[active_arm_dir]_arm")
				arm.receive_damage(1 * mutation_power)
			// MONKESTATION ADDITION END
			var/obj/item/held_item = owner.get_active_held_item()
			if(!held_item)
				return
			to_chat(owner, span_warning("Your fingers spasm!"))
			owner.log_message("used [held_item] due to a Muscle Spasm", LOG_ATTACK)
			held_item.attack_self(owner)
		if(3)
			owner.set_combat_mode(TRUE)

			var/range = 1
			if(istype(owner.get_active_held_item(), /obj/item/gun)) //get targets to shoot at
				range = 7

			var/list/mob/living/targets = list()
			for(var/mob/living/nearby_mobs in oview(owner, range))
				targets += nearby_mobs
			if(LAZYLEN(targets))
				to_chat(owner, span_warning("Your arm spasms!"))
				owner.log_message(" attacked someone due to a Muscle Spasm", LOG_ATTACK) //the following attack will log itself
				owner.ClickOn(pick(targets))
				// MONKESTATION ADDITION START
				if(mutation_power > 1)
					var/active_arm_dir = owner.held_index_to_dir(owner.active_hand_index)
					var/obj/item/bodypart/arm = owner.get_bodypart("[active_arm_dir]_arm")
					arm.receive_damage(2 * mutation_power)
				// MONKESTATION ADDITION END
			owner.set_combat_mode(FALSE)
		if(4)
			owner.set_combat_mode(TRUE)
			to_chat(owner, span_warning("Your arm spasms!"))
			owner.log_message("attacked [owner.p_them()]self to a Muscle Spasm", LOG_ATTACK)
			owner.ClickOn(owner)
			owner.set_combat_mode(FALSE)
			// MONKESTATION ADDITION START
			if(mutation_power > 1)
				var/active_arm_dir = owner.held_index_to_dir(owner.active_hand_index)
				var/obj/item/bodypart/arm = owner.get_bodypart("[active_arm_dir]_arm")
				arm.receive_damage(2 * mutation_power)
			// MONKESTATION ADDITION END
		if(5)
			if(owner.incapacitated())
				return
			var/obj/item/held_item = owner.get_active_held_item()
			var/list/turf/targets = list()
			for(var/turf/nearby_turfs in oview(owner, 3))
				targets += nearby_turfs
			if(LAZYLEN(targets) && held_item)
				to_chat(owner, span_warning("Your arm spasms!"))
				owner.log_message("threw [held_item] due to a Muscle Spasm", LOG_ATTACK)
				owner.throw_item(pick(targets))
			// MONKESTATION ADDITION START
			if(mutation_power > 1)
				var/active_arm_dir = owner.held_index_to_dir(owner.active_hand_index)
				var/obj/item/bodypart/arm = owner.get_bodypart("[active_arm_dir]_arm")
				arm.receive_damage(2 * mutation_power)
			// MONKESTATION ADDITION END

/datum/status_effect/convulsing
	id = "convulsing"
	duration = 150
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/convulsing
	show_duration = TRUE

/datum/status_effect/convulsing/on_creation(mob/living/zappy_boy)
	. = ..()
	to_chat(zappy_boy, span_boldwarning("You feel a shock moving through your body! Your hands start shaking!"))

/datum/status_effect/convulsing/tick()
	var/mob/living/carbon/H = owner
	if(prob(40))
		var/obj/item/I = H.get_active_held_item()
		if(I && H.dropItemToGround(I))
			H.visible_message(
				span_notice("[H]'s hand convulses, and they drop their [I.name]!"),
				span_userdanger("Your hand convulses violently, and you drop what you were holding!"),
			)
			H.adjust_jitter(10 SECONDS)

/atom/movable/screen/alert/status_effect/convulsing
	name = "Shaky Hands"
	desc = "You've been zapped with something and your hands can't stop shaking! You can't seem to hold on to anything."
	icon_state = "convulsing"

/datum/status_effect/dna_melt
	id = "dna_melt"
	duration = 600
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/dna_melt
	var/kill_either_way = FALSE //no amount of removing mutations is gonna save you now

/datum/status_effect/dna_melt/on_creation(mob/living/new_owner, set_duration)
	. = ..()
	to_chat(new_owner, span_boldwarning("My body can't handle the mutations! I need to get my mutations removed fast!"))

/datum/status_effect/dna_melt/on_remove()
	if(!ishuman(owner))
		owner.gib() //fuck you in particular
		return
	var/mob/living/carbon/human/H = owner
	H.something_horrible(kill_either_way)

/atom/movable/screen/alert/status_effect/dna_melt
	name = "Genetic Breakdown"
	desc = "I don't feel so good. Your body can't handle the mutations! You have one minute to remove your mutations, or you will be met with a horrible fate."
	icon_state = "dna_melt"

/datum/status_effect/go_away
	id = "go_away"
	duration = 10 SECONDS
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 0.2 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/go_away
	var/direction

/datum/status_effect/go_away/on_creation(mob/living/new_owner, set_duration)
	. = ..()
	direction = pick(NORTH, SOUTH, EAST, WEST)
	new_owner.setDir(direction)

/datum/status_effect/go_away/tick()
	owner.AdjustStun(1, ignore_canstun = TRUE)
	var/turf/T = get_step(owner, direction)
	owner.forceMove(T)

/atom/movable/screen/alert/status_effect/go_away
	name = "TO THE STARS AND BEYOND!"
	desc = "I must go, my people need me!"
	icon_state = "high"

/datum/status_effect/fake_virus
	id = "fake_virus"
	duration = 3 MINUTES //3 minutes
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 0.2 SECONDS
	alert_type = null
	var/msg_stage = 0//so you don't get the most intense messages immediately

/datum/status_effect/fake_virus/on_apply()
	if(HAS_TRAIT(owner, TRAIT_VIRUSIMMUNE))
		return FALSE
	if(owner.stat != CONSCIOUS)
		return FALSE
	return TRUE

/datum/status_effect/fake_virus/tick()
	var/fake_msg = ""
	var/fake_emote = ""
	switch(msg_stage)
		if(0 to 300)
			if(prob(1))
				fake_msg = pick(
				span_warning(pick("Your head hurts.", "Your head pounds.")),
				span_warning(pick("You're having difficulty breathing.", "Your breathing becomes heavy.")),
				span_warning(pick("You feel dizzy.", "Your head spins.")),
				span_warning(pick("You swallow excess mucus.", "You lightly cough.")),
				span_warning(pick("Your head hurts.", "Your mind blanks for a moment.")),
				span_warning(pick("Your throat hurts.", "You clear your throat.")))
		if(301 to 600)
			if(prob(2))
				fake_msg = pick(
				span_warning(pick("Your head hurts a lot.", "Your head pounds incessantly.")),
				span_warning(pick("Your windpipe feels like a straw.", "Your breathing becomes tremendously difficult.")),
				span_warning("You feel very [pick("dizzy","woozy","faint")]."),
				span_warning(pick("You hear a ringing in your ear.", "Your ears pop.")),
				span_warning("You nod off for a moment."))
		else
			if(prob(3))
				if(prob(50))// coin flip to throw a message or an emote
					fake_msg = pick(
					span_userdanger(pick("Your head hurts!", "You feel a burning knife inside your brain!", "A wave of pain fills your head!")),
					span_userdanger(pick("Your lungs hurt!", "It hurts to breathe!")),
					span_warning(pick("You feel nauseated.", "You feel like you're going to throw up!")))
				else
					fake_emote = pick("cough", "sniff", "sneeze")

	if(fake_emote)
		owner.emote(fake_emote)
	else if(fake_msg)
		to_chat(owner, fake_msg)

	msg_stage++

//Deals with ants covering someone.
/datum/status_effect/ants
	id = "ants"
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/ants
	duration = 2 MINUTES //Keeping the normal timer makes sure people can't somehow dump 300+ ants on someone at once so they stay there for like 30 minutes. Max w/ 1 dump is 57.6 brute.
	processing_speed = STATUS_EFFECT_NORMAL_PROCESS
	/// Will act as the main timer as well as changing how much damage the ants do.
	var/ants_remaining = 0
	/// Common phrases people covered in ants scream
	var/static/list/ant_debuff_speech = list(
		"GET THEM OFF ME!!",
		"OH GOD THE ANTS!!",
		"MAKE IT END!!",
		"THEY'RE EVERYWHERE!!",
		"GET THEM OFF!!",
		"SOMEBODY HELP ME!!"
	)

/datum/status_effect/ants/on_creation(mob/living/new_owner, amount_left)
	if(isnum(amount_left) && new_owner.stat < HARD_CRIT)
		if(new_owner.stat < UNCONSCIOUS) // Unconscious people won't get messages
			to_chat(new_owner, span_userdanger("You're covered in ants!"))
		ants_remaining += amount_left
		RegisterSignal(new_owner, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(ants_washed))
	. = ..()

/datum/status_effect/ants/refresh(effect, amount_left)
	var/mob/living/carbon/human/victim = owner
	if(isnum(amount_left) && ants_remaining >= 1 && victim.stat < HARD_CRIT)
		if(victim.stat < UNCONSCIOUS) // Unconscious people won't get messages
			if(!prob(1)) // 99%
				to_chat(victim, span_userdanger("You're covered in MORE ants!"))
			else // 1%
				victim.say("AAHH! THIS SITUATION HAS ONLY BEEN MADE WORSE WITH THE ADDITION OF YET MORE ANTS!!", forced = /datum/status_effect/ants)
		ants_remaining += amount_left
	. = ..()

/datum/status_effect/ants/on_remove()
	ants_remaining = 0
	to_chat(owner, span_notice("All of the ants are off of your body!"))
	UnregisterSignal(owner, COMSIG_COMPONENT_CLEAN_ACT)
	. = ..()

/datum/status_effect/ants/proc/ants_washed()
	SIGNAL_HANDLER
	owner.remove_status_effect(/datum/status_effect/ants)
	return COMPONENT_CLEANED

/datum/status_effect/ants/get_examine_text()
	return span_warning("[owner.p_they(TRUE)] [owner.p_are()] covered in ants!")

/datum/status_effect/ants/tick()
	var/mob/living/carbon/human/victim = owner
	victim.adjustBruteLoss(max(0.1, round((ants_remaining * 0.004),0.1))) //Scales with # of ants (lowers with time). Roughly 10 brute over 50 seconds.
	if(victim.stat <= SOFT_CRIT) //Makes sure people don't scratch at themselves while they're in a critical condition
		if(prob(15))
			switch(rand(1,2))
				if(1)
					victim.say(pick(ant_debuff_speech), forced = /datum/status_effect/ants)
				if(2)
					victim.emote("scream")
		if(prob(50)) // Most of the damage is done through random chance. When tested yielded an average 100 brute with 200u ants.
			switch(rand(1,50))
				if (1 to 8) //16% Chance
					var/obj/item/bodypart/head/hed = victim.get_bodypart(BODY_ZONE_HEAD)
					to_chat(victim, span_danger("You scratch at the ants on your scalp!."))
					hed.receive_damage(1,0)
				if (9 to 29) //40% chance
					var/obj/item/bodypart/arm = victim.get_bodypart(pick(BODY_ZONE_L_ARM,BODY_ZONE_R_ARM))
					to_chat(victim, span_danger("You scratch at the ants on your arms!"))
					arm.receive_damage(3,0)
				if (30 to 49) //38% chance
					var/obj/item/bodypart/leg = victim.get_bodypart(pick(BODY_ZONE_L_LEG,BODY_ZONE_R_LEG))
					to_chat(victim, span_danger("You scratch at the ants on your leg!"))
					leg.receive_damage(3,0)
				if(50) // 2% chance
					to_chat(victim, span_danger("You rub some ants away from your eyes!"))
					victim.set_eye_blur_if_lower(6 SECONDS)
					ants_remaining -= 5 // To balance out the blindness, it'll be a little shorter.
	ants_remaining--
	if(ants_remaining <= 0 || victim.stat >= HARD_CRIT)
		victim.remove_status_effect(/datum/status_effect/ants) //If this person has no more ants on them or are dead, they are no longer affected.

/atom/movable/screen/alert/status_effect/ants
	name = "Ants!"
	desc = span_warning("JESUS FUCKING CHRIST! CLICK TO GET THOSE THINGS OFF!")
	icon_state = "antalert"
	clickable_glow = TRUE

/atom/movable/screen/alert/status_effect/ants/Click()
	. = ..()
	if(!.)
		return
	var/mob/living/living = owner
	if(!istype(living) || !living.can_resist() || living != owner)
		return
	to_chat(living, span_notice("You start to shake the ants off!"))
	if(!do_after(living, 2 SECONDS, target = living))
		return
	for (var/datum/status_effect/ants/ant_covered in living.status_effects)
		to_chat(living, span_notice("You manage to get some of the ants off!"))
		ant_covered.ants_remaining -= 10 // 5 Times more ants removed per second than just waiting in place

/datum/status_effect/stagger
	id = "stagger"
	status_type = STATUS_EFFECT_REFRESH
	duration = 30 SECONDS
	tick_interval = 1 SECONDS
	alert_type = null

/datum/status_effect/stagger/on_apply()
	owner.next_move_modifier *= 1.5
	if(ishostile(owner))
		var/mob/living/simple_animal/hostile/simple_owner = owner
		simple_owner.ranged_cooldown_time *= 2.5
	return TRUE

/datum/status_effect/stagger/on_remove()
	. = ..()
	if(QDELETED(owner))
		return
	owner.next_move_modifier /= 1.5
	if(ishostile(owner))
		var/mob/living/simple_animal/hostile/simple_owner = owner
		simple_owner.ranged_cooldown_time /= 2.5

/datum/status_effect/freezing_blast
	id = "freezing_blast"
	alert_type = /atom/movable/screen/alert/status_effect/freezing_blast
	duration = 5 SECONDS
	status_type = STATUS_EFFECT_REPLACE

/atom/movable/screen/alert/status_effect/freezing_blast
	name = "Freezing Blast"
	desc = "You've been struck by a freezing blast! Your body moves more slowly!"
	icon_state = "frozen"

/datum/status_effect/freezing_blast/on_apply()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/freezing_blast, update = TRUE)
	return ..()

/datum/status_effect/freezing_blast/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/freezing_blast, update = TRUE)

/datum/movespeed_modifier/freezing_blast
	multiplicative_slowdown = 1

/datum/status_effect/discoordinated
	id = "discoordinated"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/discoordinated

/atom/movable/screen/alert/status_effect/discoordinated
	name = "Discoordinated"
	desc = "You can't seem to properly use anything..."
	icon_state = "convulsing"

/datum/status_effect/discoordinated/on_apply()
	ADD_TRAIT(owner, TRAIT_DISCOORDINATED_TOOL_USER, TRAIT_STATUS_EFFECT(id))
	return ..()

/datum/status_effect/discoordinated/on_remove()
	REMOVE_TRAIT(owner, TRAIT_DISCOORDINATED_TOOL_USER, TRAIT_STATUS_EFFECT(id))
	return ..()

///Maddly teleports the victim around all of space for 10 seconds
/datum/status_effect/teleport_madness
	id = "teleport_madness"
	duration = 10 SECONDS
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 0.2 SECONDS
	alert_type = null

/datum/status_effect/teleport_madness/tick()
	dump_in_space(owner)

/datum/status_effect/careful_driving
	id = "careful_driving"
	alert_type = /atom/movable/screen/alert/status_effect/careful_driving
	duration = 5 SECONDS
	status_type = STATUS_EFFECT_REPLACE

/datum/status_effect/careful_driving/on_apply()
	. = ..()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/careful_driving, update = TRUE)

/datum/status_effect/careful_driving/on_remove()
	. = ..()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/careful_driving, update = TRUE)

/atom/movable/screen/alert/status_effect/careful_driving
	name = "Careful Driving"
	desc = "That was close! You almost ran that one over!"
	icon_state = "paralysis"

/datum/movespeed_modifier/careful_driving
	multiplicative_slowdown = 3
