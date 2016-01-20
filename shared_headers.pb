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
  #NONE
  #DATA
  #CONN
  #DISC
  #SEND
EndEnumeration

Structure area
  name.s
  bg.s
  wait.l
  lock.l
  mlock.w
  pw.s
  players.w
  good.w
  evil.w
  track.s
  trackwait.i
EndStructure

Structure ACharacter
  name.s
  desc.s
  dj.b
  evinumber.w
  evidence.s
  pw.s
EndStructure

Structure Client
  ClientID.l
  IP.s
  AID.w
  CID.w
  sHD.b
  HD.s
  perm.w
  ignore.b
  ignoremc.b
  hack.b
  gimp.b
  area.w
  last.s
  cconnect.b
  ooct.b
  judget.b
  websocket.b
  username.s
  RAW.b
  master.b
  Inventory.i[100]
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
  #UNDJ
  #DJ
  #GIMP
  #UNGIMP
  #SWITCH
EndEnumeration
; IDE Options = PureBasic 5.11 (Windows - x64)
; CursorPosition = 13
; FirstLine = 12
; EnableXP