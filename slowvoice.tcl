# slowvoice.tcl v1.1 by Solbu. Repository: https://github.com/solbu/eggdrop-scripts
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any 
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more 
# details.
#
#
# After the recent join spam tactic on FreeNode and EFnet in the fall of 2018, I needed something that voiced all users joining a moderated channel, but it needed to randomly delay the voicing to between 60 and 99 seconds after 
# they join. And this is the result after looking on the internet for ideas.
#
# The Spambots this script is made to protect against deliver their spam withing 60 seconds after join. Since I deployed this script on the moderated channels I maintain, the spam is gone. The spambots stil join, but they can't 
# deliver their cargo since the channels are moderated and they don't have voice within the timeframe they deliver their cargo.
#
# The script has been tested on eggdrop v1.8.3. So it should work fine on this version of eggdrop and higher. If you find any bug on this script, you can open a bug repport on Github https://github.com/solbu/eggdrop-scripts
## Features:
# This script will voice any user who joins a channel specified after a preset minimum and maximum time. Default is to randomly delay voice to between 60 and 99 seconds.
### Options:
## Delay in seconds before we voice someone:
# x:y random delay; minimum x sec, maximum y sec
set sv(delay) 25:45
## Which channel do you want this script to voice people on? If you have more than one channel please leave a space between the channels.(e.g "#channel1 #channel2")
set avchan "#IRC4Fun #Chat #UIN #LadyGaga #LGBT #Xtheme #CService #Usernames #Reop #SETI@Home"
### Begin Script:
bind join - * join:sv

proc join:sv {nick host hand chan} { global sv
   utimer [expr [lindex [split $sv(delay) :] 0] + [rand [lindex [split $sv(delay) :] 1]]] [list sv:voice $nick $host $hand $chan]
}

bind nick - * nick:sv

proc nick:sv {nick host hand chan newnick} { global sv
   utimer [expr [lindex [split $sv(delay) :] 0] + [rand [lindex [split $sv(delay) :] 1]]] [list sv:voice $newnick $host $hand $chan]
}
proc sv:voice {nick host hand chan} {
   global avchan botnick
 if {$nick == $botnick} {return 0}
 if { [isvoice $nick $chan] == 1 } { return 0 }
 if {([matchattr $nick |+q $chan])} { return 0 }
 if {([matchattr $nick +q])} { return 0 }
 if {$avchan == "" && [botisop $chan]} {
  pushmode $chan +v $nick
  return 0
 }
 set chan [string tolower $chan]
 foreach i [string tolower $avchan] {
  if {$i == $chan && [botisop $chan]} {
   pushmode $chan +v $nick
   return 0
  }
 }
}
putlog "slowvoice.tcl v1.2 (GPLv3+) by Solbu & siniStar - Loaded"
