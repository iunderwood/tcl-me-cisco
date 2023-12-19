::cisco::eem::event_register_timer cron name timer_natstat cron_entry "* * * * *"

## This script generates a per-minute log entry containing NAT translation statistics.

namespace import ::cisco::eem::*
namespace import ::cisco::lib::*

## Extract Statistics

# set natStat [ exec "show ip nat statistics" ]

if [catch {cli_open} result] {
	puts stderr $result
	exit 1
} else {
	array set cli1 $result
}

if [catch {cli_exec $cli1(fd) "show ip nat statistics"} result] {
    error $result $errorInfo
} else {
    set natStat $result
}

if [catch {cli_close $cli1(fd) $cli1(tty_id)} result] {
	puts stderr $result
	exit 1
}

## Process Output

set natMsg ""

# Pull out number of active translations, if we have it.

if [ regexp -all {active translations} $natStat ] {
	set natActive [ regexp -inline {active translations: ([0-9]+)} $natStat ]
	set natActive [ regexp -inline {[0-9]+} $natActive ]
	append natMsg "Active: $natActive  "
}

# Pull out number of peak translations, if we have it.

if [ regexp -all {Peak translations} $natStat ] {
	set natPeak [ regexp -inline {Peak translations: ([0-9]+)} $natStat ]
	set natPeak [ regexp -inline {[0-9]+} $natPeak ]
	append natMsg "Peak: $natPeak  "
}

# Pull out the number of expired translations, if we have it.

if [ regexp -all {Expired translations} $natStat ] {
	set natExpired [ regexp -inline {Expired translations: ([0-9]+)} $natStat ]
	set natExpired [ regexp -inline {[0-9]+} $natExpired ]

	# Load context variable natCvar.  Set to 0 if this hasn't been set.
	if { [catch {context_retrieve CONTEXT_NATEXP natCvar} result] } {
    	set natLastExpired 0
	} else {
	    set natLastExpired $result
	}

	# Return the number of translations expired in the last interval.
	# Append an asterisk for an incomplete interval.
	if [ expr $natLastExpired <= $natExpired ] {
		append natMsg "Interval Expired: " [expr $natExpired - $natLastExpired ]
	} else {
		append natMsg "Interval Expired: $natExpired*"
	}

	# Save context variable natCvar.  We'll use this to calculate the difference next time the script is run.
	set natCvar $natExpired
	catch {context_save CONTEXT_NATEXP natCvar}
}

## Send to syslog!

action_syslog priority info msg $natMsg