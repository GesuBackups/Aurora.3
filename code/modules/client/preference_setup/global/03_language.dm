/datum/category_item/player_setup_item/player_global/language
	name = "Language"
	sort_order = 3

/datum/category_item/player_setup_item/player_global/language/load_preferences(var/savefile/S)
	S["language_prefixes"]	>> pref.language_prefixes

/datum/category_item/player_setup_item/player_global/language/save_preferences(var/savefile/S)
	S["language_prefixes"]	<< pref.language_prefixes

/datum/category_item/player_setup_item/player_global/language/gather_load_query()
	return list("ss13_player_preferences" = list("vars" = list("language_prefixes"), "args" = list("ckey")))

/datum/category_item/player_setup_item/player_global/language/gather_load_parameters()
	return list("ckey" = PREF_CLIENT_CKEY)

/datum/category_item/player_setup_item/player_global/language/gather_save_query()
	return list("ss13_player_preferences" = list("language_prefixes", "ckey" = 1))

/datum/category_item/player_setup_item/player_global/language/gather_save_parameters()
	return list("ckey" = PREF_CLIENT_CKEY, "language_prefixes" = list2params(pref.language_prefixes))

/datum/category_item/player_setup_item/player_global/language/sanitize_preferences(var/sql_load = 0)
	if (sql_load && pref.language_prefixes)
		pref.language_prefixes = params2list(pref.language_prefixes)

	if (isnull(pref.language_prefixes) || !pref.language_prefixes.len)
		pref.language_prefixes = GLOB.config.language_prefixes.Copy()

/datum/category_item/player_setup_item/player_global/language/content(var/mob/user)
	. += "<b>Language Keys</b><br>"
	. += " [jointext(pref.language_prefixes, " ")] <a href='byond://?src=[REF(src)];change_prefix=1'>Change</a> <a href='byond://?src=[REF(src)];reset_prefix=1'>Reset</a><br>"

/datum/category_item/player_setup_item/player_global/language/OnTopic(var/href, var/list/href_list, var/mob/user)
	if(href_list["change_prefix"])
		var/char
		var/keys[0]
		do
			char = input("Enter a single special character.\nYou may re-select the same characters.\nThe following characters are already in use by radio: ; : .\nThe following characters are already in use by special say commands: ! * ^", "Enter Character - [3 - keys.len] remaining") as null|text
			if(char)
				if(length(char) > 1)
					alert(user, "Only single characters allowed.", "Error", "Ok")
				else if(char in list(";", ":", "."))
					alert(user, "Radio character. Rejected.", "Error", "Ok")
				else if(char in list("!","*", "^"))
					alert(user, "Say character. Rejected.", "Error", "Ok")
				else if(contains_az09(char))
					alert(user, "Non-special character. Rejected.", "Error", "Ok")
				else
					keys.Add(char)
		while(char && keys.len < 3)

		if(keys.len == 3)
			pref.language_prefixes = keys
			return TOPIC_REFRESH

	else if(href_list["reset_prefix"])
		pref.language_prefixes = GLOB.config.language_prefixes.Copy()
		return TOPIC_REFRESH

	return ..()


/datum/category_item/player_setup_item/player_global/language/update_setup(var/savefile/preferences, var/savefile/character)
	if(preferences["version"] == 11)
		var/list/prefixes = character["language_prefixes"]
		if(istype(prefixes) && prefixes.len)
			preferences["language_prefixes"] = prefixes.Copy()
		return 1
