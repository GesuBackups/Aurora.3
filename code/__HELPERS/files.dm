//checks if a file exists and contains text
//returns text as a string if these conditions are met
/proc/return_file_text(filename)
	if(fexists(filename) == 0)
		log_asset("File not found ([filename])")
		return

	var/text = file2text(filename)
	if(!text)
		log_asset("File empty ([filename])")
		return

	return text

/proc/get_subfolders(var/root)
	var/list/folders = list()
	var/list/contents = flist(root)

	for(var/file in contents)
		//Check if the filename ends with / to see if its a folder
		if(copytext(file,-1,0) != "/")
			continue
		folders.Add("[root][file]")

	return folders

//Sends resource files to client cache
/client/proc/getFiles()
	for(var/file in args)
		send_rsc(src, file, null)

/client/proc/browse_files(root="data/logs/", max_iterations=10, list/valid_extensions=list(".txt",".log",".htm", ".json"))
	var/path = root

	for(var/i=0, i<max_iterations, i++)
		var/list/choices = sortList(flist(path))
		if(path != root)
			choices.Insert(1,"/")

		var/choice = input(src,"Choose a file to access:","Download",null) as null|anything in choices
		switch(choice)
			if(null)
				return
			if("/")
				path = root
				continue
		path += choice

		if(copytext(path,-1,0) != "/")		//didn't choose a directory, no need to iterate again
			break

	var/valid_extension = FALSE
	for(var/e in valid_extensions)
		if(findtext(path, e, -(length(e))))
			valid_extension = TRUE

	if( !fexists(path) || !valid_extension )
		to_chat(src, SPAN_WARNING("Error: browse_files(): File not found/Invalid file([path])."))
		return

	return path

#define FTPDELAY 200	//200 tick delay to discourage spam
/*	This proc is a failsafe to prevent spamming of file requests.
	It is just a timer that only permits a download every [FTPDELAY] ticks.
	This can be changed by modifying FTPDELAY's value above.

	PLEASE USE RESPONSIBLY, Some log files canr each sizes of 4MB!	*/
/client/proc/file_spam_check()
	var/time_to_wait = GLOB.fileaccess_timer - world.time
	if(time_to_wait > 0)
		to_chat(src, SPAN_WARNING("Error: file_spam_check(): Spam. Please wait [round(time_to_wait/10)] seconds."))
		return 1
	GLOB.fileaccess_timer = world.time + FTPDELAY
	return 0
#undef FTPDELAY

/// Returns the md5 of a file at a given path.
/proc/md5filepath(path)
	. = md5(file(path))

/// Save file as an external file then md5 it.
/// Used because md5ing files stored in the rsc sometimes gives incorrect md5 results.
/proc/md5asfile(file)
	var/static/notch = 0
	// its importaint this code can handle md5filepath sleeping instead of hard blocking, if it's converted to use rust_g.
	var/filename = "tmp/md5asfile.[world.realtime].[world.timeofday].[world.time].[world.tick_usage].[notch]"
	notch = WRAP(notch+1, 0, 2**15)
	fcopy(file, filename)
	. = md5filepath(filename)
	fdel(filename)

/**
 * Takes a directory and returns every file within every sub directory.
 * If extensions_filter is provided then only files that end in that extension are given back.
 * If extensions_filter is a list, any file that matches at least one entry is given back.
 */
/proc/pathwalk(path, extensions_filter)
	var/list/jobs = list(path)
	var/list/filenames = list()

	while(jobs.len)
		var/current_dir = pop(jobs)
		var/list/new_filenames = flist(current_dir)
		for(var/new_filename in new_filenames)
			// if filename ends in / it is a directory, append to currdir
			if(findtext(new_filename, "/", -1))
				jobs += "[current_dir][new_filename]"
				continue
			// filename extension filtering
			if(extensions_filter)
				if(islist(extensions_filter))
					for(var/allowed_extension in extensions_filter)
						if(endswith(new_filename, allowed_extension))
							filenames += "[current_dir][new_filename]"
							break
				else if(endswith(new_filename, extensions_filter))
					filenames += "[current_dir][new_filename]"
			else
				filenames += "[current_dir][new_filename]"
	return filenames
