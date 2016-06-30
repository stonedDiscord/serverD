#CRLF$ = Chr(13)+Chr(10)

Structure Action
  IP.s
  type.i  
EndStructure

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

Enumeration ;client type
  #NONE
  #VANILLA
  #MASTER
  #VNO
  #WEBSOCKET
  #AOTWO  
EndEnumeration

Structure area
  name.s
  bg.s
  wait.l
  lock.l
  mlock.w
  pw.s
  hidden.b
  players.w
  good.w
  evil.w
  track.s
  trackstart.l
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
  Inventory.i[20]
EndStructure

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
  #UNDJ
  #DJ
  #GIMP
  #UNGIMP
  #SWITCH
  #MOVE
EndEnumeration
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 33
; EnableXP