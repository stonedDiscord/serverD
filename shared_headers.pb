#CRLF$ = Chr(13)+Chr(10)

Structure Action
  IP.s
  type.i  
EndStructure

CompilerIf #PLUGINS
Structure Plugin
  ID.i
  version.i
  name.s
  description.s
  *rawfunction
  *gtarget
  *gmessage
  *gcallback
  active.b
EndStructure

Enumeration ;plugin status
  #NODATA
  #DATA
  #CONN
  #DISC
  #SEND
EndEnumeration
CompilerEndIf

Structure Track
  TrackName.s
  Length.i
EndStructure

Enumeration ;ranks
  #USER
  #ANIM
  #MOD
  #ADMIN
  #SERVER  
EndEnumeration

Enumeration ;client type
  #NOTYPE
  #VANILLA
  #MASTER
  #VNO
  #AOA
  #WEBSOCKET
  #WEBBROWSER
  #AOTWO  
EndEnumeration

Enumeration ;area status
  #IDLE
  #BUILDINGOPEN
  #BUILDINGFULL
  #CASINGOPEN
  #CASINGFULL
  #RECESS
  #REPLAY
EndEnumeration

Structure Channel
  name.s
  bg.s
  waitstart.l
  waitdur.l
  lock.l
  mlock.w
  pw.s
  hidden.b
  players.w
  hideplayers.b
  good.w
  evil.w
  maxhp.w
  replaytime.w
  replayfile.s
  track.s
  trackstart.l
  trackwait.i
  List PlayList.Track()
  status.w
EndStructure

Structure ACharacter
  name.s
  desc.s
  dj.b
  evinumber.w
  evidence.s
  pw.s
EndStructure

Structure ItemData
  name.s
  price.w
  filename.s
  desc.s
EndStructure

Structure Client
  ClientID.l
  IP.s
  AID.w
  CID.w
  sHD.b
  HD.s
  type.b
  perm.w
  ignore.b
  silence.b
  ignoremc.b
  hack.b
  gimp.b
  pos.s
  area.w
  last.s
  command.s
  cconnect.b
  ooct.b
  judget.b
  username.s
  skip.b
  Inventory.i[50]
EndStructure

Structure ChatMessage
  deskmod.s
  message.s
  char.s
  emote.s
  preemote.s
  position.s
  sfx.s
  sfxdelay.w
  animdelay.w
  showname.s
  background.s
  emotemod.w
  flip.b
  objmod.w
  realization.w
  color.w
  evidence.w
EndStructure

; SENDING MESSAGES
; okay.. this is the big bomb
; 
; Client: MS#message#character#side#sfx#pre_emote#emote#emote_modifier#objection_modifier#realization#text_color#evidence#%
; MS#chat#<pre-emote>#<char>#<emote>#<mes>#<pos>#<sfx>#emote_modifier#objection_modifier#realization#text_color#evidence#%
; side = wit, def, pro, jud, hld, hlp
; sfx = sound effect(.wav) that should be played
; emote_modifier = 
; 0: do Not play preanimation Or sound effect unless objection_modifier is Not 0
; 1: play preanimation And sound effect
; 5: ZOOM - hide desk And set background As speedlines, direction based on side


Structure TempBan
  banned.s
  reason.s
  type.b
  time.l
EndStructure

Enumeration
  #KICK
  #DISCO
  #BAN
  #IDBAN
  #MUTE
  #UNMUTE
  #CIGNORE
  #UNIGNORE
  #SILENCE
  #UNSILENCE
  #UNDJ
  #DJ
  #GIMP
  #UNGIMP
  #SWITCH
  #MOVE
EndEnumeration
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 7
; Folding = -
; EnableXP