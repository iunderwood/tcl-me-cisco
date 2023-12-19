# TCL Filter that skips all "DMI-5-AUTH_PASSED" messages.

set pattern "DMI-5-AUTH_PASSED"

if { [regexp $pattern $::orig_msg] == 1} {
    return ""
} else {
    return $::orig_msg
}
