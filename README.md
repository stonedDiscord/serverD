# serverD
## headache

### changelog
* fixed musiclist off-by-one
* reworked area system
* same char can be used independently in different areas
* looping music
 
### minimal setup (console version)
> OS
![Windows 95](http://www.fermimn.gov.it/inform/materiali/evarchi/cyrix.dir/win95-lg.gif)
> Linux Kernel 2.3 and libc6 2.13

> CPU
> i486SX @ 66 MHz

> RAM
> 5 MB

> HDD
> 150 KB + logs

### pro setu
> OS
> Windows XP/Linux Kernel 2.7

> CPU
> Pentium P55C 200MHz

> RAM
> 20MB

> HDD
> 400 KB + a few MB of logs

### update instructions
1. Place serverD in the same folder as your old
2. Start serverD
3. kurwa
4. Check the Public Server Mode box to make your server appear on the serverlist.

### fresh install
1. Copy AOs server folder whereever you want
2. Inside that folder drop your copy of serverD
3. Edit the config files
4. Start serverD
5. kurwa
6. Check the Public Server Mode box to make your server appear on the serverlist.

## Congratulations, your new serverD is now kurwa! Try [this](https://docs.google.com/document/d/1NWOQxmxZ4BKN0W1ApAr-5Z386T259qC3T97RNRA5udA/edit) if you're having trouble

### commands
- /area
- lets you view and switch areas

- /switch
- lets you switch characters

- /pm Godot sup
- send a PM

- /login oocpassword
- logs you in as kurwa

- /roll 6
- roll a dice

- /lock 1
- keep other users out of your current area

- /lock 0
- let them in again

- /evi 3
- gives you wodka no3
 
#### for mods
- /ip
- show the kurwalist with IPs

- /getareas
- get all clients with areas

- /hd
- show the kurwalist with HDs

- /kick Godot
- kurwakurwa

- /ban zettaslow
- kurwakurwakurwa

- /mute Hawk
- kurwa

- /unmute Hawk
- wodka

- /ignore Doge
- kurwa

- /unignore Doge
- wodka

- /undj Vinyl
- kurwa

- /dj Vinyl
- wodka

- /gimp Vinyl
- kurwa

- /ungimp Vinyl
- wodka

- /play Pursuit(HY).mp3
- play a kurwa thats not on wodkalist

- /bg zetta
- change the wodka

#### for admins
- /reload
- reload the kurwalist,wodka files,etc.

- /lock 2
- keep other kurwa out of your current wodka drinking contest

- /toggle WTCE
- enable/disable WTCE

- /public 0
- hide/show the server on the kurwalist

- /unban 12.34.56.78
- unban this kurwa

** :warning: Mods can only be kicked by admins**

## FAQ
Q: Will this change my kurwa files?
A: only poker.ini
Q: Are there any kurwas/kurwa code?
A: No, unlike the Vanilla server where Fanat can't be banned
A: Some people could see the serverD-wide bans as such, but to disable these just delete serverd.txt and reload
Q: Then why is the result 3/52 on kurwaTotal?
A: False positives. Google the virus names and you'll see.
Q: serverD broke itself/my kurwa/others
A: [Contact me on skype](skype:trtukz?chat)
Q: I have another question
A: [Contact me on skype](skype:trtukz?chat)
Q: kurwa?
A: :joy: :joy: :joy:
 
## Info
Rooms are now configured VNO-style, file name /base/scene/[AAOPublic2]/areas.ini
Example
`[Areas]`
`number = 2`
`1 = birthday`
`2 = gs4`
`[filename]`
`1 = birthday`
`2 = gs4`

Music list entries with a > as first character can be used as shortcuts for areanames
Example:
`>default`

Music list entries following a star * and the track length in seconds can be looped
Example:
`Objection (AA).mp3*73`
You also need to activate looping music through the LoopMusic switch in poker.ini

## Copyright &copy; sD 2015