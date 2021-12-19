#############################################################################
#                                                                           #
# Modified for use on IRC4Fun, by: siniStar (siniStar@IRC4Fun.net)          #
# Originally coded by: Opposing (Fz_Egg@yahoo.com)                          #
# Version : 1.4.2                                                           #
# New Release: December 19, 2021                                            #
# Released: November 29, 2010                                               #
##                                                                          #
# Description: A blacklist script that stores the banned masks in a db file #
#              and bans everyone who matches the blacklisted masks on join  #
#              or when the bot gets op.                                     #
#                                                                           #
# Available Commands:                                                       #
# - DCC: .addbl <nick>!<user>@<host> [reason] [bantime] : Adds ban.         #
#        .rembl <nick>!<user>@<host>                    : Deletes ban.      #
#        .listbl                                        : Lists bans.       #
# - PUB: addbl <nick>!<user>@<host> [reason] [bantime]  : Adds ban          #
#        rembl <nick>!<user>@<host>                     : Deletes ban.      #
#        listbl                                         : Lists bans.       #
#                                                                           #
# USE (DCC) .chanset #channel +blacklist to enable blacklist on a channel.  #
#                                                                           #
# Credits:                                                                  #
#         Thanks to strikelite and user (if I recall correctly) from the    #
#         egghelp.org forum for helping me with this script (back in 2003). #
#         Also used user's (egghelp.org forum) maskhost proc.               #
#                                                                           #
# History:                                                                  #
#         - 1.4.2: Configured script to use ChanServ (Anope) for KICKS&Bans #
#         - 1.4.1: Configured script to use X (GNUworld) for KICKS & Bans   #
#         - 1.4: Fixed a bug when using the bansame option where nicknames  #
#           with special characters (\, [, ]) were not properly banned.     #
#         - 1.3: Added Flooding out protection, where the bot will start    #
#           using the slowest queue in case a number of blacklisted users   #
#           join in a certain period of seconds which can be defined by the #
#           user. + fixed a bug with brackets.                              #
#         - 1.2: Fixed a few bugs and made the script create the blacklist  #
#           file if it doesn't exist.                                       #
#         - 1.1: added the black list chan flag, and other features into    #
#           patterns of handling the blacklist.                             #
#         - 1.0: First release.                                             #
#                                                                           #
# Report bugs/suggestions to Fz_Egg@yahoo.com                               #
#                                                                           #
# Copyright � 2005 Opposing (aka Sir_Fz)                                    #
#                                                                           #
# This program is free software; you can redistribute it and/or modify      #
# it under the terms of the GNU General Public License as published by      #
# the Free Software Foundation; either version 2 of the License, or         #
# (at your option) any later version.                                       #
#                                                                           #
# This program is distributed in the hope that it will be useful,           #
# but WITHOUT ANY WARRANTY; without even the implied warranty of            #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             #
# GNU General Public License for more details.                              #
#                                                                           #
# You should have received a copy of the GNU General Public License         #
# along with this program; if not, write to the Free Software               #
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA #
#                                                                           #
#############################################################################
#
##############################
# Configurations start here: #
# __________________________ #

## Blacklist File:
set blackl(file) "scripts/blacklist.txt"

## Blacklist "Excess Flood" protection. Set here how many blacklisted users are allowed
## to join in how many seconds before using the slow queue in order for the bot not to
## flood out with reason "Excess Flood."
set blackl(punish) 4:2

## Do you want the bot to also check for blacklisted users on op ? (0: no / 1: yes)
set blackl(checkop) 0

## Do you want to ban the same ban from the blacklist file
## or do you want it to be spcific ? (0: specific / 1: same ban as the file)
### example:
## Suppose that *!lamest@* is banned.
# .. joins lamer!lamest@lamer.org
# .. bot sets mode +b *!lamest@*
# .. lamer kicked by bot "Blacklisted user."
## This happens if this option is set to 1.
## but if you set it to 0, then you can choose what bantype you want to ban.
set blackl(bansame) 0

## if blackl(bansame) is set to 0:
## What ban type do you want to ban ?
# 0: *!user@full.host.tld
# 1: *!*user@full.host.tld
# 2: *!*@full.host.tld
# 3: *!*user@*.host.tld
# 4: *!*@*.host.tld
# 5: nick!user@full.host.tld
# 6: nick!*user@full.host.tld
# 7: nick!*@full.host.tld
# 8: nick!*user@*.host.tld
# 9: nick!*@*.host.tld
set blackl(btype) 2

## Set default ban reason if not specified.
## NOTE: use %requester to use the nick of the one who set the ban.
set blackl(kmsg) "User matched in Blacklist"

## set default ban time (in minutes) if no bantime specified. (0 means no ban time)
set blackl(btime) 480

## Do you want the ban to be removed from the file after ban time expires ? (0: no / 1: yes)
## if set to 0, the bot will only remove the ban from the channel but not from the file.
set blackl(rbabt) 0

## Set here the trigger for public commands.
## example: set blackl(trig) "!"
## now using !listbl on main will show the blacklist.
set blackl(trig) "^"

## Set flags that are allowed to use these commands.
## <global flags>|<channel flags>
set blackl(flags) m|-

# Configurations end here. #
############################
#
######################################################################
# Code starts here, please do not edit anything unless you know TCL: #
# __________________________________________________________________ #

bind join - * bl:ban
bind dcc $blackl(flags) addbl bl:add
bind dcc $blackl(flags) rembl bl:rem
bind dcc $blackl(flags) listbl bl:list
bind pubm $blackl(flags) * bl:pub
bind mode - "* +o" bl:cop
setudef flag blacklist

if {[file exists $blackl(file)]} {
 set BLNicks [split [string tolower [read [set inf [open $blackl(file)]]]] "\n"][close $inf]
} {
 set BLNicks [list]
}

foreach {blackl(lim) blackl(secs)} [split $blackl(punish) :] {break}

proc bl:ban {nick uhost hand chan} {
 global BLNicks blackl blflood
 if {![botisop $chan] || ![channel get $chan blacklist]} {return 0}
 if {![info exists blflood([set chan [string tolower $chan]])]} { set blflood($chan) 0 }
 foreach blnick $BLNicks {
  if {[string match -nocase [set ban [lindex [split $blnick] 0]] $nick!$uhost]} {
   set ban [string map {\\\\ \\ \\\[ \[ \\\] \]} $ban]
   if {[blfollow $blackl(secs) blflood($chan)] < $blackl(lim)} {
    putquick "PRIVMSG ChanServ :BAN $chan +4h $nick [string map [list %requester [lindex [split $blnick] 1]] [join [lrange [split $blnick] 2 end-1]]]"
    if {$blackl(bansame)} {
     putquick "MODE $chan -o+b $nick $ban"
     if {!([set btime [lindex [split $blnick] end]] <= 0)} {
      timer $btime [list rem:blban $chan $ban]
     }
    } {
     putquick "MODE $chan -o+b $nick [set aban [blbtype $nick!$uhost $blackl(btype)]]"
     if {!([set btime [lindex [split $blnick] end]] <= 0)} {
      timer $btime [list rem:blban $chan $aban]
     }
    }
   } {
    putquick "PRIVMSG ChanServ :BAN $chan +4h [set aban [blbtype $nick!$uhost $blackl(btype)]] [string map [list %requester [lindex [split $blnick] 1]] [join [lrange [split $blnick] 2 end-1]]]"
    if {$blackl(bansame)} {
     pushmode $chan -o $nick
     pushmode $chan +b $ban
     if {!([set btime [lindex [split $blnick] end]] <= 0)} {
      timer $btime [list rem:blban $chan $ban]
     }
    } {
     pushmode $chan -o $nick
     pushmode $chan +b [set aban [blbtype $nick!$uhost $blackl(btype)]]
     if {!([set btime [lindex [split $blnick] end]] <= 0)} {
      timer $btime [list rem:blban $chan $aban]
     }
    }
   }
   putlog "\[\002BlackList\002\]: Banned \002$nick\002!\002$uhost\002 matching [string map {! \002!\002 @ \002@\002} \002$ban\002] on \002$chan\002"
   break
  }
 }
}

proc bl:add {hand idx arg} {
 if {$arg == ""} { putlog "SYNTAX: \003.addbl <nick!user@host> \[reason\] \[btime\]\003"; return 0 }
 if {![string match -nocase *!*@* [set blnick [lindex [split $arg] 0]]]} {
  putlog "SYNTAX: \003.addbl \002<nick>\002!\002<user>\002@\002<host>\002 \[reason\] \[bantime\]\003"
  return 0
 }
 if {[bl:do:add $hand $arg]} {
  foreach chan [channels] {
   if {![channel get $chan blacklist]} { continue }
   foreach ubchecked [chanlist $chan] {
    bl:ban $ubchecked [getchanhost $ubchecked $chan] [nick2hand $ubchecked] $chan
   }
  }
  putlog "[string map {! \002!\002 @ \002@\002} \002$blnick\002] has been \002added\002 to the blacklist."
 } {
  putlog "[string map {! \002!\002 @ \002@\002} \002$blnick\002] already \002exists\002 in the blacklist."
 }
}

proc bl:do:add {hand arg} {
 global blackl BLNicks
 set added 0
 if {[llength [lrange [split $arg] 1 end]] == 1} {
  if {[string is integer [lindex [split $arg] end]]} {
   set kreason "$blackl(kmsg)"
   set btime "[lindex [split $arg] end]"
  } else {
   set kreason "[lrange [split $arg] 1 end]"
   set btime "$blackl(btime)"
  }
 } elseif {[llength [lrange [split $arg] 1 end]] > 1} {
  if {[string is integer [lindex [split $arg] end]]} {
   set kreason "[join [lrange [split $arg] 1 end-1]]"
   set btime "[lindex [split $arg] end]"
  } else {
   set kreason "[join [lrange [split $arg] 1 end]]"
   set btime "$blackl(btime)"
  }
 } else {
  set kreason "$blackl(kmsg)"
  set btime "$blackl(btime)"
 }
 if {![file exists $blackl(file)]} {
  set temp [open $blackl(file) w]
  close $temp
 }
 set blnick "[string map {\\ \\\\ \[ \\\[ \] \\\]} [lindex [split $arg] 0]]"
 if {![we:can:find:ban $blnick add]} {
  puts [set fs [open $blackl(file) a]] "$blnick $hand $kreason $btime"
  close $fs
  set BLNicks [split [string tolower [read [set inf [open $blackl(file)]]]] "\n"][close $inf]
  set added 1
 }
 set added
}

proc bl:rem {hand idx arg} {
 if {$arg == ""} { putlog "SYNTAX: \003.rembl <nick!user@host>\003"; return 0 }
 if {![string match -nocase *!*@* [set blnick [lindex [split $arg] 0]]]} {
  putlog "SYNTAX: \003.rembl \002<nick>\002!\002<user>\002@\002<host>\002\003"
  return 0
 }
 if {[bl:do:rem $arg]} {
  foreach chan [channels] {
   if {![channel get $chan blacklist]} { continue }
   foreach ban [chanbans $chan] {
    if {[string match -nocase $blnick [set sban [lindex $ban 0]]]} {
     pushmode $chan -b $sban
    }
   }
  }
  putlog "[string map {! \002!\002 @ \002@\002} \002$blnick\002] was \002deleted\002 from the blacklist."
 } {
  putlog "[string map {! \002!\002 @ \002@\002} \002$blnick\002] was \002not\002 found in the blacklist."
 }
}

proc bl:do:rem arg {
 global blackl BLNicks
 set remmed 0
 set blnick [lindex [split $arg] 0]
 if {![file exists $blackl(file)]} {
  set temp [open $blackl(file) w]
  close $temp
 }
 if {[we:can:find:ban $blnick rem]} {
  set z ""
  set a [open $blackl(file) r]
  while {![eof $a]} {
   set b [gets $a]
   if {![string equal -nocase [lindex $b 0] $blnick]} { lappend z ${b} }
  }
  close $a
  set n [open $blackl(file) w]
  foreach k $z {
   if {$k != ""} { puts $n $k }
  }
  close $n
  set BLNicks [split [string tolower [read [set inf [open $blackl(file)]]]] "\n"][close $inf]
  set remmed 1
 }
 set remmed
}

proc bl:list {hand idx arg} {
 global BLNicks
 if {[string equal "{} {}" $BLNicks] || [string equal "" $BLNicks]} {
  putlog "There are \002no\002 bans in the blacklist."
 } {
  set c 1
  foreach blnick $BLNicks {
   if {$blnick != ""} {
    putlog "\[\002$c\002\] - \002Mask\002: [lindex [split $blnick] 0] - \002Requester\002: [lindex [split $blnick] 1] - \002Bantime\002: [lindex [split $blnick] end] -- \002Reason\002: [join [lrange [split $blnick] 2 end-1]]"
    incr c
   } {
    putlog "\[\002*\002\] - End of list."
   }
  }
 }
}

proc bl:pub {nick uhost hand chan arg} {
 global blackl BLNicks
 if {![string equal $blackl(trig) [string index $arg 0]]} {return 0}
 switch -- [lindex [lindex [split $arg $blackl(trig)] 1] 0] {
  "addbl" {
   if {[join [lrange [split $arg] 1 end]] == ""} { puthelp "NOTICE $nick :SYNTAX: \003$blackl(trig)addbl <nick!user@host> \[reason\] \[btime\]\003"; return 0 }
   if {![string match -nocase *!*@* [set blnick [lindex [split $arg] 1]]]} {
    puthelp "NOTICE $nick :SYNTAX: \003$blackl(trig)addbl \002<nick>\002!\002<user>\002@\002<host>\002 \[reason\] \[bantime\]\003"
    return 0
   }
   if {[bl:do:add $hand [join [lrange [split $arg] 1 end]]]} {
    if {[channel get $chan blacklist]} {
     foreach ubchecked [chanlist $chan] {
      bl:ban $ubchecked [getchanhost $ubchecked $chan] [nick2hand $ubchecked] $chan
     }
    }
    puthelp "NOTICE $nick :[string map {! \002!\002 @ \002@\002} \002$blnick\002] has been \002added\002 to the blacklist."
   } {
    puthelp "NOTICE $nick :[string map {! \002!\002 @ \002@\002} \002$blnick\002] already \002exists\002 in the blacklist."
   }
  }
  "rembl" {
   if {[join [lrange [split $arg] 1 end]] == ""} { puthelp "NOTICE $nick :SYNTAX: \003$blackl(trig)rembl <nick!user@host>\003"; return 0 }
   if {![string match -nocase *!*@* [set blnick [lindex [split $arg] 1]]]} {
    puthelp "NOTICE $nick :SYNTAX: \003$blackl(trig)rembl \002<nick>\002!\002<user>\002@\002<host>\002\003"
    return 0
   }
   if {[bl:do:rem [join [lrange [split $arg] 1 end]]]} {
    if {[channel get $chan blacklist]} {
     foreach ban [chanbans $chan] {
      if {[string match -nocase $blnick [set sban [lindex $ban 0]]]} {
       pushmode $chan -b $sban
      }
     }
    }
    puthelp "NOTICE $nick :[string map {! \002!\002 @ \002@\002} \002$blnick\002] was \002deleted\002 from the blacklist."
   } {
    puthelp "NOTICE $nick :[string map {! \002!\002 @ \002@\002} \002$blnick\002] was \002not\002 found in the blacklist."
   }
  }
  "listbl" {
   if {[string equal "{} {}" $BLNicks] || [string equal "" $BLNicks]} {
    puthelp "NOTICE $nick :There are \002no\002 bans in the blacklist."
   } {
    set c 1
    foreach blnick $BLNicks {
     if {$blnick != ""} {
      puthelp "NOTICE $nick :\[\002$c\002\] - \002Mask\002: [lindex [split $blnick] 0] - \002Requester\002: [lindex [split $blnick] 1] - \002Bantime\002: [lindex [split $blnick] end]"
      incr c
     } {
      puthelp "NOTICE $nick :\[\002*\002\] - End of list."
     }
    }
   }
  }
 }
}

proc bl:cop {nick uhost hand chan mc targ} {
 global blackl
 if {[isbotnick $targ] && $blackl(checkop) && [channel get $chan blacklist]} {
  foreach blnick [chanlist $chan] {
   bl:ban $blnick [getchanhost $blnick $chan] [nick2hand $blnick] $chan
  }
 }
}

proc rem:blban {chan ban} {
 global blackl
 if {$blackl(rbabt)} {
  pushmode $chan -b $ban
  bl:do:rem $ban
 } {
  pushmode $chan -b $ban
 }
}

proc we:can:find:ban {blnick type} {
 global blackl
 set spfound 0
 switch -- $type {
  "add" {
   foreach temp [split [string tolower [read [set inf [open $blackl(file)]]]] "\n"][close $inf] {
    if {[string equal -nocase [lindex [split $temp] 0] $blnick]} { set spfound 1 ; break }
   }
  }
  "rem" {
   foreach temp [split [string tolower [read [set inf [open $blackl(file)]]]] "\n"][close $inf] {
    if {[string equal -nocase [lindex [split $temp] 0] [string map {\\ \\\\ \[ \\\[ \] \\\]} $blnick]]} { set spfound 1 ; break }
   }
  }
 }
 set spfound
}

proc blfollow {secs blvar} {
 upvar $blvar fvar
 utimer $secs [list bldicr $blvar]
 incr fvar
}

proc bldicr blvar {
 upvar $blvar fvar
 if {$fvar > 0} {
  incr fvar -1
 }
}

set blbtypeDefaultType 3

proc blbtype [list name [list type $blbtypeDefaultType]] {
 if {[scan $name {%[^!]!%[^@]@%s} nick user host]!=3} {
  error "Usage: maskbhost <nick!user@host> \[type\]"
 }
 if [string match {[3489]} $type] {
  if [string match {*[0-9]} $host] {
   set host [join [lrange [split $host .] 0 2] .].*
  } elseif {[string match *.*.* $host]} {
   set host *.[join [lrange [split $host .] end-1 end] .]
  }
 }
 if [string match {[1368]} $type] {
  set user *[string trimleft $user ~]
 } elseif {[string match {[2479]} $type]} {
  set user *
 }
 if [string match {[01234]} $type] {
  set nick *
 }
 set name $nick!$user@$host
}

putlog "BlackList v1.4 By Opposing (a.k.a Sir_Fz) Loaded..."
