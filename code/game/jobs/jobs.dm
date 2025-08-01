var/const/NUM_JOB_DEPTS     = 4 //ENGSEC, MEDSCI, SERVICE and EVENTDEPT

// ENGSEC
var/const/ENGSEC			=(1<<0)

var/const/CAPTAIN			=(1<<0)
var/const/HOS				=(1<<1)
var/const/WARDEN			=(1<<2)
var/const/FORENSICS			=(1<<3)
var/const/OFFICER			=(1<<4)
var/const/CHIEF				=(1<<5)
var/const/ENGINEER			=(1<<6)
var/const/ATMOSTECH			=(1<<7)
var/const/AI				=(1<<8)
var/const/CYBORG			=(1<<9)
var/const/INTERN_SEC		=(1<<10)
var/const/INTERN_ENG		=(1<<11)
var/const/BRIDGE_CREW		=(1<<12)
var/const/OPERATIONS_MANAGER =(1<<13)
var/const/HRA              =(1<<14)
var/const/CONSULAR_ASST	   =(1<<15)
var/const/DIPLOMAT_GUARD   =(1<<16)

// MEDSCI
var/const/MEDSCI			=(1<<1)

var/const/RD				=(1<<0)
var/const/SCIENTIST			=(1<<1)
var/const/CHEMIST			=(1<<2)
var/const/CMO				=(1<<3)
var/const/DOCTOR			=(1<<4)
var/const/SURGEON			=(1<<5)
var/const/VIROLOGIST		=(1<<6)
var/const/PSYCHIATRIST		=(1<<7)
var/const/ROBOTICIST		=(1<<8)
var/const/XENOBIOLOGIST		=(1<<9)
var/const/MED_TECH			=(1<<10)
var/const/INTERN_MED		=(1<<11)
var/const/INTERN_SCI		=(1<<12)
var/const/XENOBOTANIST		=(1<<13)
var/const/XENOARCHEOLOGIST	=(1<<14)

// SERVICE
var/const/SERVICE			=(1<<2)

var/const/XO				=(1<<0)
var/const/BARTENDER			=(1<<1)
var/const/BOTANIST			=(1<<2)
var/const/CHEF				=(1<<3)
var/const/JANITOR			=(1<<4)
var/const/LIBRARIAN			=(1<<5)
var/const/PASSENGER			=(1<<6)
var/const/CARGOTECH			=(1<<7)
var/const/MINER				=(1<<8)
var/const/LAWYER			=(1<<9)
var/const/CHAPLAIN			=(1<<10)
var/const/VISITOR			=(1<<11)
var/const/CONSULAR			=(1<<12)
var/const/MERCHANT			=(1<<13)
var/const/JOURNALIST		=(1<<14)
var/const/ASSISTANT			=(1<<15)
GLOBAL_VAR_CONST(DIPLOMAT_AIDE, 1<<16)

//EVENTDEPT
//This is needed because there are just not enough bitflags available across the other departments
var/const/EVENTDEPT			=(1<<3)

var/const/EVENTSEC			=(1<<0)
var/const/EVENTENG			=(1<<1)
var/const/EVENTMED			=(1<<2)
var/const/EVENTSCI			=(1<<3)
var/const/EVENTOPS			=(1<<4)
var/const/EVENTSRV			=(1<<5)


// Positions Lists
var/list/command_positions = list(
	"Captain",
	"Executive Officer",
	"Head of Security",
	"Chief Engineer",
	"Research Director",
	"Chief Medical Officer",
	"Operations Manager"
)

var/list/command_support_positions = list(
	"Human Resources Assistant",
	"Corporate Liaison",
	"Consular Officer",
	"Bridge Crew",
	"Diplomatic Aide",
	"Diplomatic Bodyguard",
	"Corporate Aide"
)

var/list/engineering_positions = list(
	"Chief Engineer",
	"Engineer",
	"Atmospheric Technician",
	"Engineering Apprentice",
	"Engineering Personnel"
)

var/list/medical_positions = list(
	"Chief Medical Officer",
	"Physician",
	"Surgeon",
	"Psychiatrist",
	"Pharmacist",
	"Paramedic",
	"Medical Intern",
	"Medical Personnel"
)

var/list/science_positions = list(
	"Research Director",
	"Scientist",
	"Xenoarchaeologist",
	"Xenobiologist",
	"Xenobotanist",
	"Research Intern",
	"Science Personnel"
)

var/list/cargo_positions = list(
	"Operations Manager",
	"Hangar Technician",
	"Shaft Miner",
	"Machinist",
	"Operations Personnel"
)

var/list/service_positions = list(
	"Executive Officer",
	"Bartender",
	"Gardener",
	"Chef",
	"Janitor",
	"Librarian",
	"Chaplain",
	"Service Personnel"
)

var/list/civilian_positions = list(
	"Assistant",
	"Off-Duty Crew Member",
	"Passenger",
	"Merchant",
	"Corporate Reporter"
)

var/list/security_positions = list(
	"Head of Security",
	"Warden",
	"Investigator",
	"Security Officer",
	"Security Cadet",
	"Security Personnel"
)

var/list/nonhuman_positions = list(
	"AI",
	"Cyborg",
	"pAI"
)

var/list/armory_positions = list(
	"AI",
	"Warden",
	"Captain",
	"Executive Officer",
	"Head of Security",
	"Operations Manager"
)

/proc/guest_jobbans(var/job)
	return ((job in command_positions) || job == "Corporate Liaison" || job == "Consular Officer")

/proc/get_job_datums()
	var/list/occupations = list()
	var/list/all_jobs = typesof(/datum/job)

	for(var/A in all_jobs)
		var/datum/job/job = new A()
		if(!job)	continue
		occupations += job

	return occupations

/proc/get_alternate_titles(var/job)
	var/list/jobs = get_job_datums()
	var/list/titles = list()

	for(var/datum/job/J in jobs)
		if(J.title == job)
			titles = J.alt_titles

	return titles
