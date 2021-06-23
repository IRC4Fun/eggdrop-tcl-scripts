#############################################################################
##         _   _   _   _   _   _   _   _   _   _   _   _   _   _           ##
##        / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \          ##
##       ( T | C | L | S | C | R | I | P | T | S | . | N | E | T )         ##
##        \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/          ##
##                                                                         ##
##                       ® BLaCkShaDoW Production ®                        ##
##                                                                         ##
##                                PRESENTS                                 ##
#############################################################################
##                                                        spammyBL.tcl 1.0 ##
##                                Ooooh spaamo mio...                      ##
##                              .'                                         ##
##                             _        :--..----.                         ##
##                       \   o')        |spamboat|                         ##
##                        ;-._:         |-.__.---'                         ##
##                         \  |       _,:                                  ##
##              ':-:._______\/|____,-'.'                                   ##
##                '-.__.____.\__.__,-'                                     ##
##   nO mOrE SPAM              \.       nO mOrE SPAM nO mOrE SPAM amSP     ##
##  nO mOrE SPAM nO mOrE SPAM '    nO mOrE SPAM nO mOrE SPAM nO mOrE SPAM  ##
##                                                                         ##
##                      - #TCL-HELP @ UNDERNET -     	                   ##
##                                                                         ##
#############################################################################
##								           ##
##  INSTALLATION: 						           ##
##     ++ Edit spammyBL.tcl script & place it into your /scripts directory.##
##     ++ add "source scripts/spammyBL.tcl" to your eggdrop.conf & rehash. ##
##								           ##
#############################################################################
##								           ##
##  COMMANDS:                                                              ##
##								           ##
##  To activate:                                                           ##
##  .chanset +nospammy | from BlackTools: .set #channel +nospammy          ##
##                                                                         ##
##  !rem <IP> - removes an IP from SpammyBlackList.                        ##
##              (without *!*@, just digits | eq: !rem 12.12.12.12)         ##
##								           ##
##  !set [+|-]nospammy.xonly - activate/deactivate X ban support.          ##
##                                                                         ##
#############################################################################
##								           ##
##  PERSONAL AND NON-COMMERCIAL USE LIMITATION.                            ##
##                                                                         ##
##  This program is provided on an "as is" and "as available" basis,       ##
##  with ABSOLUTELY NO WARRANTY. Use it at your own risk.                  ##
##                                                                         ##
##  Use this code for personal and NON-COMMERCIAL purposes ONLY.           ##
##                                                                         ##
##  Unless otherwise specified, YOU SHALL NOT copy, reproduce, sublicense, ##
##  distribute, disclose, create derivatives, in any way ANY PART OF       ##
##  THIS CONTENT, nor sell or offer it for sale.                           ##
##                                                                         ##
##  You will NOT take and/or use any screenshots of this source code for   ##
##  any purpose without the express written consent or knowledge of author.##
##                                                                         ##
##  You may NOT alter or remove any trademark, copyright or other notice   ##
##  from this source code.                                                 ##
##                                                                         ##
##              Copyright 2008 - 2018 @ WwW.TCLScripts.NET                 ##
##                                                                         ##
## ** based on ideas picked & sugested by psycho@undernet.org              ##
##                                                                         ##
#############################################################################

#############################################################################
##                              CONFIGURATIONS                             ##
#############################################################################

# SpammyList default reason
set spammy(breason) "Spam is off-topic on this network"

# SpammyList X Ban Time
set spammy(xban_time) "24h"

# SpammyList X Ban Level
set spammy(xban_level) "75"

###
# Flags needed for !rem command
# - like (mn|o or mn for global only)
###
set spammy(flags) "mno|MAO"

##############################################################################
###          DO NOT MODIFY HERE UNLESS YOU KNOW WHAT YOU'RE DOING          ###
##############################################################################

###
# Bindings
# - using commands
bind join - * spammy:ident:check
bind pubm - * spammy:message:check
bind join - * spammy:blacklist
bind pub $spammy(flags) !rem spammy:black:remove

###
# Channel flags
setudef flag nospammy
setudef flag nospammy.xonly

###
# SpammyList database file
set spammy(black_file) "freenode_black.txt"
if {![file exists $spammy(black_file)]} {
	set file [open $spammy(black_file) w]
	close $file
}

###
# SpammyList counter file
set spammy(count_file) "freenode_counter.txt"
if {![file exists $spammy(count_file)]} {
	set file [open $spammy(count_file) w]
	close $file
}

###
proc spammy:ident:check {nick host hand chan} {
	global spammy
if {![channel get $chan nospammy]} {
	return
}
if {![regexp {^[~]} [lindex [split $host "@"] 0]]} {
	return
}
	set ident [string map {"~" ""} [string tolower [lindex [split $host "@"] 0]]]
if {[string match -nocase "$ident*" $nick]} {
	set spammy(check:$nick) 1
	utimer 20 [list spammy:unset $nick]
	}
}

###
proc spammy:unset {var} {
	global spammy
if {[info exists spammy(check:$var)]} {
	unset spammy(check:$var)
	}
}

###
proc spammy:message:check {nick host hand chan arg} {
	global spammy
if {![channel get $chan nospammy]} {
	return
}
	set host [lindex [split $host "@"] 1]
	set message [lrange [split $arg] 0 end]
if {[info exists spammy(check:$nick)]} {
if {[regexp {(ј|о|Ꭲ|ᥱ|ᥒ|і|！|ዘ|Ꭱ|Ϻ|Ϲ|ᖇ|Ꮤ|Ꭰ)} $message]} {
	spammy:black:add $host
	spammy:banall:chans $nick $host
		}
	}
}

###
proc spammy:black:add {host} {
	global spammy
	set check_valid [spammy:black:check $host]
if {$check_valid > -1} {
	return 0
}
	set file [open $spammy(black_file) a]
	puts $file $host
	close $file
}

###
proc spammy:black:check {host} {
	global spammy
	set file [open $spammy(black_file) r]
	set size [file size $spammy(black_file)]
	set data [split [read $file $size] \n]
	close $file
	set get [lsearch $data $host]
	return $get
}

###
proc spammy:black:rem {host} {
	global spammy
	set file [open $spammy(black_file) "r"]
	set timestamp [clock format [clock seconds] -format {%Y%m%d%H%M%S}]
	set temp "spammy_temp.$timestamp"
	set tempwrite [open $temp w]
while {[gets $file line] != -1} {
	set read_ip [lindex [split $line] 0]
if {[string equal -nocase $read_ip $host]} {
	continue
} else {
	puts $tempwrite $line
		}
    }
	close $tempwrite
	close $file
    file rename -force $temp $spammy(black_file)
}

###
proc spammy:blacklist {nick host hand chan} {
	global spammy
#if {![botisop $chan]} { return }
	set host [lindex [split $host "@"] 1]
	set check_valid [spammy:black:check $host]
if {$check_valid < 0} {
	return 0
}
	set counter [spammy:incr:count]
if {[channel get $chan nospammy.xonly] && [onchan "X" $chan]} {
#New Functionality -- be more Sigyn-ish.
# Stop spambots more effectively (and quickly) by sending a KILL,
# followed by an immediate GLINE. (Then duplicate it to either
# Uworld2 or EUworld)
# -- siniStar
	putquick "KILL $nick :Spam is off-topic on this network - $counter"
	putquick "GLINE +*@$host * 3600 :Banned for spamming - Contact Help@IRC4Fun.net for more information. ($chan - $counter)"
	putquick "PRIVMSG Uworld2 :GLINE ADD *@$host !T 14d Banned for spamming - Contact Help@IRC4Fun.net with GID# for more information. ($chan - $counter)"
	putserv "PRIVMSG #Opers :*** \002Warning\002 Spam-Characters activated by $nick in $chan"
#	putquick "PRIVMSG X :ban $chan *!*@$host $spammy(xban_time) $spammy(breason) - $counter -"
#	putquick "PRIVMSG EUworld :GLINE ADD *@$host !T 7d Spam is off-topic on this network - $counter"
} else {
#	putquick "MODE $chan +b $host"
#	putquick "KICK $chan $nick :$spammy(breason) - $counter -"
        putquick "KILL $nick :Spam is off-topic on this network - $counter"
        putquick "GLINE +*@$host * 3600 :Banned for spamming - Contact Help@IRC4Fun.net for more information. ($chan - $counter)"
        putquick "PRIVMSG Uworld2 :GLINE ADD *@$host !T 14d Banned for spamming - Contact Help@IRC4Fun.net with GID# for more information. ($chan - $counter)"
				putserv "PRIVMSG #Opers :*** \002Warning\002 Spam-Characters activated by $nick in $chan"
#        putquick "PRIVMSG EUworld :GLINE ADD *@$host !T 7d Spam is off-topic on this network - $counter"
	putlog "$spammy(projectName) - Kicked $nick from '$chan' - '$spammy(breason)'."
	}
}

# Credits
set spammy(projectName) "spammyBL"
set spammy(author) "BLaCkShaDoW & skew"
set spammy(website) "wWw.TCLScriptS.NeT"
set spammy(email) "info\[at\]tclscripts.net"
set spammy(version) "v1.0"

###
proc spammy:banall:chans {nick host} {
	global spammy
	set channels ""
foreach chan [channels] {
if {[botisop $chan]} {
if {[channel get $chan nospammy]} {
if {[onchan $nick $chan]} {
	lappend channels $chan
				}
			}
		}
	}
if {$channels != ""} {
	spammy:ban:chan $channels $nick $host 0
	}
}

###
proc spammy:ban:chan {channels nick host num} {
	global spammy
	set incr 0
	set counter [spammy:incr:count]
	set chan [lindex $channels $num]
if {[channel get $chan nospammy.xonly] && [onchan "X" $chan]} {
	putquick "PRIVMSG X :ban $chan *!*@$host $spammy(xban_time) $spammy(breason) - $counter -"
} else {
	putquick "MODE $chan +b $host"
	putquick "KICK $chan $nick :$spammy(breason) - $counter -"
	putlog "$spammy(projectName) - Kicked $nick from '$chan' - '$spammy(breason)'."
	}
	set incr [expr $num + 1]
if {[lindex $channels $incr] != ""} {
	spammy:ban:chan $channels $nick $host $incr
	}
}

###
proc spammy:black:remove {nick host hand chan arg} {
	global spammy
	set ip [lindex [split $arg] 0]
if {$ip == ""} {
	putserv "NOTICE $nick :USAGE SYNTAX:\002 !rem\002 \[host|ip\]"
	return
}
	set check_it [spammy:black:check $ip]
if {$check_it < 0} {
	putserv "NOTICE $nick :Didn't found \002$ip\002 in spammyBL."
	return
}
	spammy:black:rem $ip
	putserv "NOTICE $nick :Removed \002$ip\002 from spammyBL."
}

###
proc spammy:incr:count {} {
	global spammy
	set file [open $spammy(count_file) r]
	set data [read -nonewline $file]
	close $file
if {$data == ""} { set data 0 }
	set incr [expr $data + 1]
	set file [open $spammy(count_file) w]
	puts $file $incr
	close $file
	return $incr
}

putlog "\002$spammy(projectName) $spammy(version)\002 by\002 $spammy(author)\002 ($spammy(website)): Loaded & initialised.."

#########
##############################################################################
###                  *** THE END ***                                       ###
##############################################################################
