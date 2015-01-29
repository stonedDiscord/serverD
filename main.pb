;EnableExplicit
; yes this is the legit serverD source code please report bugfixes/modifications/feature requests to sD or trtukz on skype
CompilerIf #PB_Compiler_OS <> #PB_OS_Windows
  #MB_ICONERROR=0
CompilerEndIf

Structure CharacterArray
  StructureUnion
    c.c[0]
    s.s{1}[0]
  EndStructureUnion
EndStructure

Structure Evidence
  type.w
  name.s
  desc.s
  image.s
EndStructure

Structure room
  bg.s
  wait.l
  lock.l
  mlock.w
EndStructure

Structure ACharacter
  name.s
  desc.s
  taken.b
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
  room.w
  last.s
  cconnect.b
  gimp.b
EndStructure

Enumeration
  #KICK
  #BAN
  #MUTE
  #UNMUTE
  #CIGNORE
  #UNIGNORE
  #UNDJ
  #DJ
  #GIMP
  #UNGIMP
EndEnumeration

Global *Buffer = AllocateMemory(1024)
Global NetworkMode=#PB_Network_TCP
Global EmptyMode.b=0
Global Logging.b=0
Global public.b=0
Global LogFile$="poker.log"
Global ServerEXP=0
Global ServerReg$=""
Global ClientEXP=0
Global ClientReg$=""
Global decryptor$=""
Global oppass$=""
Global adminpass$=""
Global opppass$=""
Global key
Global defbar$="10"
Global probar$="10"
Global port
Global ListMutex
Global str.s
Global scene$="AAOPublic2"
Global StringToHexR.s
Global Result.s=""
Global characternumber=0
Global oBG.s="gs4"
Global rt.b=1
Global loghd.b=0
Global background.s
Global PV=0
Global rf.b=0
Global Replays.b=0
Global rline=0
Global replaylines=0
Global replayopen.b
Global modcol=0
Global blockini.b=0
Global MOTDevi=0
Global tracks=0
Global LoginReply$="CT#sD#got it#%"
Global roomc=9
Global musicpage=0
Global EviNumber
Global NewMap Clients.Client()
Global NewList HDbans.s()
Global NewList HDmods.s()
Global NewList IPbans.s()
Global NewList SDbans.s()
Global NewList gimp.s()
Global NewList Music.s()
Global Dim Evidences.Evidence(EviNumber)
Global Dim Rooms.room(roomc)
Global ChatMutex = CreateMutex()
Global ListMutex = CreateMutex()
Global musicmode=1
Global update=0
Global Dim Icons.l(2)
Global Dim ReadyChar.s(10)
Global Dim ReadyEvidence.s(50)
Global Dim ReadyMusic.s(400)

If InitNetwork() = 0
  CompilerIf #CONSOLE=0
    MessageRequester("serverD", "Can't initialize the network!",#MB_ICONERROR)
  CompilerEndIf
  End
EndIf
CompilerIf #CONSOLE=0
  IncludeFile "Common.pb"
CompilerEndIf
Procedure MSWait(*p)
  Define par.s
  Define roomw
  Define time
  par.s=PeekS(*p)
  roomw=Val(Left(par.s,1))
  time=Val(Right(par.s,Len(par.s)-1))
  LockMutex(Rooms(roomw)\wait)
  Delay(time)
  UnlockMutex(Rooms(roomw)\wait)
EndProcedure

Procedure WriteLog(string$,mod.b,ip$)
  Define mstr$
  ; [23:21:05] David Skoland: (If mod)[M][IP][Timestamp, YYYYMMDDHHMM][Character]:[Message]
  If mod
    mstr$="[M]"
  Else
    mstr$="[U]"
  EndIf
  
  If Logging
    WriteStringN(1,mstr$+"["+LSet(ip$,15)+"]"+"["+FormatDate("%dd.%mm.%yyyy %hh:%ii:%ss",Date())+"]"+string$) 
    CompilerIf #CONSOLE=1
      PrintN(mstr$+"["+LSet(ip$,15)+"]"+"["+FormatDate("%dd.%mm.%yyyy %hh:%ii:%ss",Date())+"]"+string$)
    CompilerEndIf
  EndIf
EndProcedure

Procedure WriteReplay(string$)
  If Replays
    If ReplayOpen
      WriteStringN(3,string$) 
      WriteStringN(3,"wait")
      rline+1
      If rline>replaylines
        CloseFile(3)
        ReplayOpen=0
      EndIf
    Else
      OpenFile(3,"base/replays/AAO replay "+FormatDate("%dd-%mm-%yy %hh-%ii-%ss",Date())+".txt")
      WriteStringN(3,"decryptor#"+decryptor$+"#%")
      ReplayOpen=1
    EndIf
  EndIf
EndProcedure

Procedure IsNumeric(in_str.s)
  Define rex_IsNumeric
  Define Is_Numeric.b
  rex_IsNumeric = CreateRegularExpression(#PB_Any,"^[[:digit:]]+$") 
  Is_Numeric.b = MatchRegularExpression(rex_IsNumeric, in_str)
  FreeRegularExpression(rex_IsNumeric)
  ProcedureReturn Is_Numeric
EndProcedure

Procedure IsAlpha(in_str.s)
  Define rex_isAlpha
  Define is_Alpha.b
  rex_isAlpha = CreateRegularExpression(#PB_Any,"^[[:alpha:]]+$") ; A-Z and a-z
  is_Alpha.b = MatchRegularExpression(rex_isAlpha, in_str)
  FreeRegularExpression(rex_isAlpha)
  ProcedureReturn is_Alpha
EndProcedure

Procedure LoadSettings(reload)
  Define loadchars
  Define loadcharsettings
  Define loaddesc
  Define loadevi
  Define iniroom
  Define track$
  Define hdmod$
  Define hdban$
  Define ipban$
  If OpenPreferences("base/settings.ini")=0
    If CreatePreferences("base/settings.ini")=0
      CompilerIf #CONSOLE=0
        MessageRequester("serverD","dude i can't create the settings file",#MB_ICONERROR)
      CompilerElse
        PrintN("Cant create the settings file (folder missing/wrong permissions?)")
      CompilerEndIf
    Else
      PreferenceGroup("Net")
      WritePreferenceInteger("public",0)
      WritePreferenceString("oppassword", "DEFAULT")
      WritePreferenceInteger("port",27016)
      PreferenceGroup("server")
      WritePreferenceString("Name", "DEFAULT")
      WritePreferenceString("Desc", "DEFAULT")
      WritePreferenceInteger("musicmode",1)
      WritePreferenceInteger("replaysave",1)
      WritePreferenceInteger("replayline",400)
      WritePreferenceString("case", "AAOPublic2")
    EndIf
  EndIf
  PreferenceGroup("net")
  opppass$=ReadPreferenceString("oppassword","1333333337")   
  port=ReadPreferenceInteger("port",27016)
  
  public=ReadPreferenceInteger("public",0)
  CompilerIf #CONSOLE=0
    SetGadgetText(#String_5,Str(port))
    SetGadgetState(#CheckBox_MS,public)
  CompilerElse
    PrintN("Loading serverD "+Str(#PB_Editor_BuildCount)+"."+Str(#PB_Editor_CompileCount)+" settings")
    PrintN("OP pass:"+opppass$)
    PrintN("Server port:"+Str(port))
    PrintN("Public server:"+Str(public))
  CompilerEndIf
  PreferenceGroup("server")
  musicmode=ReadPreferenceInteger("musicmode",1)
  Replays=ReadPreferenceInteger("replaysave",0)
  replaylines=ReadPreferenceInteger("replaylines",400)
  scene$=ReadPreferenceString("case","AAOPublic2") 
  CompilerIf #CONSOLE=0
    SetWindowTitle(0,ReadPreferenceString("Name","serverD"))
  CompilerElse
    PrintN("Musicmode:"+Str(musicmode))
    PrintN("Scene:"+scene$)
  CompilerEndIf
  
  
  OpenPreferences("poker.ini")
  PreferenceGroup("cfg")
  oppass$=ReadPreferenceString("oppass","")
  adminpass$=ReadPreferenceString("adminpass","")
  blockini=ReadPreferenceInteger("BlockIni",0)
  modcol=ReadPreferenceInteger("modcol",0)
  MOTDevi=ReadPreferenceInteger("motdevi",0)
  LoginReply$=ReadPreferenceString("LoginReply","CT#sD#got it#%")
  LogFile$=ReadPreferenceString("LogFile","base/serverlog.log")
  If Logging
    CloseFile(1)
  EndIf
  Logging=ReadPreferenceInteger("Logging",1)
  If Logging
    If OpenFile(1,LogFile$)
      FileSeek(1,Lof(1))
      WriteLog("LOGGING STARTED",1,"SERVER")
    Else
      Logging=0
    EndIf
  EndIf
  
  ClosePreferences()
  
  OpenPreferences("base/scene/"+scene$+"/init.ini")
  CompilerIf #CONSOLE
    PrintN("OOC pass:"+oppass$)
    PrintN("Block INI edit:"+Str(blockini))
    PrintN("Moderator color:"+Str(modcol))
    PrintN("MOTD evidence:"+Str(MOTDevi))
    PrintN("Login reply:"+LoginReply$)
    PrintN("Logfile:"+LogFile$)
    PrintN("Logging:"+Str(Logging))
  CompilerEndIf
  PreferenceGroup("Global")
  EviNumber=ReadPreferenceInteger("EviNumber",0)
  oBG.s=ReadPreferenceString("BackGround","gs4")
  background.s=oBG.s
  PreferenceGroup("chars")
  Global characternumber=ReadPreferenceInteger("number",1)
  If reload=0
    Global Dim Characters.ACharacter(characternumber)
  EndIf
  For loadchars=0 To characternumber
    Characters(loadchars)\name=ReadPreferenceString(Str(loadchars),"zettaslow")
    If reload=0
      Characters(loadchars)\taken=0
    EndIf
  Next
  
  PreferenceGroup("desc")
  For loaddesc=0 To characternumber
    Characters(loaddesc)\desc=ReadPreferenceString(Str(loadchars),"No description")
  Next
  ReDim Evidences(EviNumber)
  ReDim ReadyEvidence(EviNumber-1)
  For loadevi=1 To EviNumber
    PreferenceGroup("evi"+Str(loadevi))
    Evidences(loadevi)\type=ReadPreferenceInteger("type",1)
    Evidences(loadevi)\name=ReadPreferenceString("name","DEFAULT")
    Evidences(loadevi)\desc=ReadPreferenceString("desc","This is the default evidence")
    Evidences(loadevi)\image=ReadPreferenceString("image","2.png")
    
    ReadyEvidence(loadevi-1)="EI#" + Str(loadevi)+"#"+Evidences(loadevi)\name+"&"+Evidences(loadevi)\desc+"&"+Str(Evidences(loadevi)\type)+"&"+Evidences(loadevi)\image+"&##%"
    
  Next
  ClosePreferences()
  
  For iniroom=0 To 9    
    Rooms(iniroom)\wait=CreateMutex()
    Rooms(iniroom)\bg=background
  Next
  
  ready$="CI#"
  charpage=0
  For loadcharsettings=0 To characternumber
    OpenPreferences("base/scene/"+scene$+"/char"+Str(loadcharsettings)+".ini")
    PreferenceGroup("desc")
    Characters(loadcharsettings)\desc=ReadPreferenceString("text","No description")
    Characters(loadcharsettings)\dj=ReadPreferenceInteger("dj",musicmode)
    Characters(loadcharsettings)\evinumber=ReadPreferenceInteger("evinumber",0)
    Characters(loadcharsettings)\evidence=ReadPreferenceString("evi","")
    Characters(loadcharsettings)\pw=ReadPreferenceString("pass","")
    ClosePreferences()
    Delay(10)
    
    ready$ = ready$ + Str(loadcharsettings)+"#"+Characters(loadcharsettings)\name+"&"+Characters(loadcharsettings)\desc+"&0&"+Characters(loadcharsettings)\evidence+"&"+Characters(loadcharsettings)\pw+"&0&#"
    
    If loadcharsettings%10 = 9
      ReadyChar(charpage)=ready$+"#%"
      charpage+1
      ready$="CI#"
    EndIf    
  Next 
  
  If Not loadcharsettings%10 = 9
    ReadyChar(charpage)=ready$+"#%"
  EndIf
  
  Debug ReadyChar(0)
  Debug ReadyChar(1)
  Debug ReadyChar(2)
  
  If ReadFile(2, "base/musiclist.txt")   ; wenn die Datei geöffnet werden konnte, setzen wir fort...
    tracks=0
    musicpage=0
    ready$="EM#"
    While Eof(2) = 0           ; sich wiederholende Schleife bis das Ende der Datei ("end of file") erreicht ist
      AddElement(Music())
      track$=ReadString(2) 
      track$=ReplaceString(track$,"#","<num>")
      track$ = ReplaceString(track$,"%","<percent>")
      Music() = track$
      ready$ = ready$ + Str(tracks) + "#" + track$ + "#"
      If tracks%10 = 9
        ReadyMusic(musicpage)=ready$+"#%"
        musicpage+1
        If page>10
          ReDim ReadyMusic(musicpage)
        EndIf
        ready$="EM#"
      EndIf
      tracks+1
    Wend
    ReDim ReadyMusic(musicpage)
    
    If Not tracks%10 = 9
      ReadyMusic(musicpage)=ready$+"#%"
    EndIf
    
    CloseFile(2)
    
  Else
    CompilerIf #CONSOLE=0
      MessageRequester("AO server","No music list!")
    CompilerEndIf
  EndIf
  
  
  If ReadFile(2, "base/op.txt")   ; wenn die Datei geöffnet werden konnte, setzen wir fort...
    ClearList(HDmods())
    While Eof(2) = 0           ; sich wiederholende Schleife bis das Ende der Datei ("end of file") erreicht ist
      hdmod$=ReadString(2)
      If hdmod$<>""
        AddElement(HDmods())
        HDmods()=hdmod$
      EndIf
    Wend
    CloseFile(2)               ; schließen der zuvor geöffneten Datei
  EndIf
  
  If ReadFile(2, "base/HDbanlist.txt")   ; wenn die Datei geöffnet werden konnte, setzen wir fort...
    ClearList(HDbans())
    While Eof(2) = 0           ; sich wiederholende Schleife bis das Ende der Datei ("end of file") erreicht ist
      hdban$=ReadString(2)
      If hdban$<>""
        AddElement(HDbans())
        HDbans()=hdban$
      EndIf
    Wend
    CloseFile(2)               ; schließen der zuvor geöffneten Datei
  EndIf
  
  If ReadFile(2, "serverd.txt")   ; wenn die Datei geöffnet werden konnte, setzen wir fort...
    ReadString(2)
    ReadString(2)
    ReadString(2)
    ClearList(SDbans())
    While Eof(2) = 0           ; sich wiederholende Schleife bis das Ende der Datei ("end of file") erreicht ist
      hdban$=ReadString(2)
      If hdban$<>""
        AddElement(SDbans())
        SDbans()=hdban$
      EndIf
    Wend
    CloseFile(2)               ; schließen der zuvor geöffneten Datei
  EndIf
  
  If ReadFile(2, "base/banlist.txt")   ; wenn die Datei geöffnet werden konnte, setzen wir fort...
    ClearList(IPbans())
    While Eof(2) = 0           ; sich wiederholende Schleife bis das Ende der Datei ("end of file") erreicht ist
      ipban$=ReadString(2)
      If ipban$<>""
        AddElement(IPbans())
        IPbans()=ipban$
      EndIf
    Wend
    CloseFile(2)               ; schließen der zuvor geöffneten Datei
  EndIf
  
  If ReadFile(2, "base/gimp.txt")   ; wenn die Datei geöffnet werden konnte, setzen wir fort...
    ClearList(gimp())
    While Eof(2) = 0           ; sich wiederholende Schleife bis das Ende der Datei ("end of file") erreicht ist
      AddElement(gimp())
      gimp()=ReadString(2)
    Wend
    CloseFile(2)               ; schließen der zuvor geöffneten Datei
  EndIf
  
EndProcedure

Procedure SendToAll(*p)
  Define replay$
  reply$=PeekS(*p)
  Debug PeekS(*p)
  LockMutex(ListMutex)
  ResetMap(Clients())
  While NextMapElement(Clients())
    SendNetworkString(Clients()\ClientID,reply$)    ;;;;; SERVER REPLY
  Wend
  UnlockMutex(ListMutex)
EndProcedure

Procedure ListIP(ClientID)
  Define send.b
  Define iplist$
  Define charname$
  send=0
  iplist$="IL#"
  LockMutex(ListMutex)  
  ResetMap(Clients())
  While NextMapElement(Clients())
    char=Clients()\CID
    If char<=100 And char>=0
      If char>characternumber      ; the character id is greater than the amount of characters
        charname$="HACKER"    ; OBVIUOSLY
        Clients()\hack=1
      Else
        If Clients()\perm
          charname$=Characters(char)\name+"(mod)"
        Else
          charname$=Characters(char)\name
        EndIf
      EndIf
    Else
      charname$="nobody"     
    EndIf
    iplist$=iplist$+Clients()\IP+"|"+charname$+"|"+Str(char)+"|*"
  Wend
  UnlockMutex(ListMutex)
  iplist$=iplist$+"#%"
  SendNetworkString(ClientID,iplist$) 
EndProcedure

Procedure KickBan(kick$,action,perm)
  Define akck
  Define everybody.b
  Define i
  akck=0
  If kick$="everybody"
    everybody.b=1
  EndIf
  For i=0 To characternumber
    If Characters(i)\name=kick$
      kick$=Str(i)
      Break
    EndIf
  Next
  LockMutex(ListMutex)
  ResetMap(Clients())
  While NextMapElement(Clients())
    If kick$=Str(Clients()\CID) Or kick$=Clients()\HD Or kick$=Clients()\IP Or everybody
      If Clients()\perm<perm
        Select action
          Case #KICK
            SendNetworkString(Clients()\ClientID,"KK#"+Str(Clients()\CID)+"#%")
            If Clients()\CID>=0
              Characters(Clients()\CID)\taken=0
            EndIf
            kclid=Clients()\ClientID
            DeleteMapElement(Clients())
            Delay(10)
            CloseNetworkConnection(kclid)          
            akck+1
            
          Case #BAN
            SendNetworkString(Clients()\ClientID,"KB#"+Str(Clients()\CID)+"#%")
            
            If kick$=Clients()\HD
              AddElement(HDbans())
              HDbans()=Clients()\HD
              If OpenFile(2,"base/HDbanlist.txt")
                FileSeek(2,Lof(2))
                WriteStringN(2,Clients()\HD)
                CloseFile(2)
              EndIf
            Else
              AddElement(IPbans())
              IPbans()=Clients()\IP
              If OpenFile(2,"base/banlist.txt")
                FileSeek(2,Lof(2))
                WriteStringN(2,Clients()\IP)
                CloseFile(2)
              EndIf
            EndIf
            If Clients()\CID>=0
              Characters(Clients()\CID)\taken=0
            EndIf
            kclid=Clients()\ClientID
            DeleteMapElement(Clients())
            Delay(10)
            CloseNetworkConnection(kclid) 
            akck+1
          Case #MUTE
            SendNetworkString(Clients()\ClientID,"MU#"+Str(Clients()\CID)+"#%")
            akck+1
          Case #UNMUTE
            SendNetworkString(Clients()\ClientID,"UM#"+Str(Clients()\CID)+"#%")
            akck+1
          Case #CIGNORE
            Clients()\ignore=1
            akck+1
          Case #UNIGNORE
            Clients()\ignore=0
            akck+1
          Case #UNDJ
            Clients()\ignoremc=1
            akck+1
          Case #DJ
            Clients()\ignoremc=0
            akck+1
          Case #GIMP
            Clients()\gimp=1
            akck+1
          Case #UNGIMP
            Clients()\gimp=0
            akck+1
        EndSelect
      EndIf
    EndIf
  Wend    
  UnlockMutex(ListMutex) 
  rf=1
  ProcedureReturn akck
EndProcedure


Procedure SendTarget(user$,room,message$)
  Debug user$
  Debug room
  Debug message$
  
  
  If user$="*"
    everybody.b=1
  EndIf
  
  For i=0 To characternumber
    If Characters(i)\name=user$
      user$=Str(i)
      Break
    EndIf
  Next
  
  LockMutex(ListMutex)
  ResetMap(Clients())
  While NextMapElement(Clients())
    If user$=Str(Clients()\CID) Or user$=Clients()\HD Or user$=Clients()\IP Or (everybody And room=Clients()\room)
      SendNetworkString(Clients()\ClientID,message$)      
    EndIf
  Wend      
  UnlockMutex(ListMutex)
  ProcedureReturn akck
EndProcedure

Procedure.s Escape(smes$)
  smes$=ReplaceString(smes$,"<num>","#")
  smes$=ReplaceString(smes$,"<and>","&")
  smes$=ReplaceString(smes$,"<percent>","%")
  smes$=ReplaceString(smes$,"<dollar>","$")
  ProcedureReturn smes$
EndProcedure

ProcedureDLL.s HexToString(hex.s)
  str.s=""
  For i = 1 To Len(hex.s) Step 2
    str.s = str.s + Chr(Val("$"+Mid(hex.s, i, 2)))
  Next i
  ProcedureReturn str.s
EndProcedure

ProcedureDLL.s StringToHex(str.s)
  StringToHexR.s = ""
  hexchar.s = ""
  
  For x.l = 1 To Len(str)
    hexchar.s = Hex(Asc(Mid(str, x, 1)))
    If Len(hexchar) = 1
      hexchar = "0" + hexchar
    EndIf
    StringToHexR.s = StringToHexR + hexchar
  Next x
  ProcedureReturn StringToHexR.s
EndProcedure

Procedure.s EncryptStr(S.s, Key.u)
  C1 = 53761
  C2 = 32618
  
  Result.s = S.s
  
  Define *S.CharacterArray = @S
  Define *Result.CharacterArray = @Result
  
  For I = 0 To Len(S.s)-1
    *Result\c[I] = (*S\c[I] ! (Key >> 8))
    Key = ((*Result\c[I] + Key) * C1) + C2
  Next
  
  ProcedureReturn Result.s
EndProcedure

ProcedureDLL.s DecryptStr(S.s, Key.u)
  C1 = 53761
  C2 = 32618
  Result.s = S.s
  
  Define *S.CharacterArray = @S
  Define *Result.CharacterArray = @Result
  
  For I = 0 To Len(S.s)-1
    *Result\c[I] = (*S\c[I] ! (Key >> 8))
    Key = ((*S\c[I] + Key) * C1) + C2
  Next
  
  ProcedureReturn Result.s
EndProcedure

ProcedureDLL MasterAdvert(msport)
  WriteLog("Masterserver adverter thread started",1,"SERVER")
  msID=0
  mstick=0
  *null=AllocateMemory(100)
  OpenPreferences("base/masterserver.ini")
  PreferenceGroup("list")
  master$=ReadPreferenceString("0","46.188.16.205")
  ClosePreferences()
  OpenPreferences("base/settings.ini")
  PreferenceGroup("server")
  name$=ReadPreferenceString("Name","Public Discord server")
  desc$=ReadPreferenceString("Desc","This server is powered by serverD")
  desc$=ReplaceString(desc$,"$n",Chr(13)+Chr(10))  
  desc$=ReplaceString(desc$,"%n",Chr(13)+Chr(10))  
  
  ClosePreferences()
  
  Repeat
    
    If msID
      If NetworkClientEvent(msID)=#PB_NetworkEvent_Data
        msinfo=ReceiveNetworkData(msID,*null,100)
        If msinfo=-1
          tick=200
        Else
          msrec$=PeekS(*null,msinfo)
          If Left(msrec$,7) ="CHECK#%"
            tick=0
          EndIf
        EndIf
      EndIf
      
      If tick>=200
        WriteLog("Masterserver adverter timer exceeded, reconnecting",1,"SERVER")
        CloseNetworkConnection(msID)
        msID=OpenNetworkConnection(master$,27016)
        
        If msID
          SendNetworkString(msID,"SCC#"+Str(port)+"#"+name$+"#"+desc$+"#%")
          tick=0
        EndIf
      EndIf 
      
    Else
      msID=OpenNetworkConnection(master$,27016)
      If msID
        Debug "SCC#"+Str(port)+"#"+name$+"#"+desc$+"#%"
        SendNetworkString(msID,"SCC#"+Str(msport)+"#"+name$+"#"+desc$+"#%")
        tick=0
      EndIf
    EndIf
    
    Delay(100)
    tick+1
  Until public=0
  
  WriteLog("Masterserver adverter thread stopped",1,"SERVER")
  If msID
    CloseNetworkConnection(msID)
  EndIf
  FreeMemory(*null)
  msthread=0
EndProcedure


Procedure SendDone(ClientID)
  send$="CharsCheck"
  For sentchar=0 To characternumber
    If Characters(sentchar)\taken Or  Characters(sentchar)\pw<>""
      send$ = send$ + "#-1"
    Else
      send$ = send$ + "#0"
    EndIf
  Next
  send$ = send$ + "#%"
  SendNetworkString(ClientID,send$)
  SendNetworkString(ClientID,"BN#"+Rooms(0)\bg+"#%")
  SendNetworkString(ClientID,"OPPASS#"+StringToHex(EncryptStr(opppass$,key))+"#%")
  SendNetworkString(ClientID,"MM#"+Str(musicmode)+"#%")
  Delay(10)
  SendNetworkString(ClientID,"DONE#%")
EndProcedure




CompilerIf #PB_Compiler_Debugger=0
  OnErrorGoto(?start)
CompilerEndIf

CompilerIf #CONSOLE=0
  Procedure RefreshList(var)
    lstate=GetGadgetState(#Listview_0)
    ClearGadgetItems(#Listview_0)
    i=0
    LockMutex(ListMutex)    
    ResetMap(Clients())
    While NextMapElement(Clients())
      AddGadgetItem(#Listview_0,i,Clients()\IP+Chr(10)+Str(Clients()\CID)+Chr(10)+Str(Clients()\AID),Icons(Clients()\perm))
      SetGadgetItemData(#Listview_0,i,Clients()\ClientID)
      ;SetGadgetItemColor(#Listview_0,i,#PB_Gadget_BackColor,$EEEEEE/(Clients()\icon+1))
      i+1
      Debug "clients: "+Str(i)
    Wend
    UnlockMutex(ListMutex)
    If lstate<MapSize(Clients())
      SetGadgetState(#Listview_0,lstate)
    EndIf
  EndProcedure
  
  
  Procedure ConfigWindow(var)
    Open_Window_1()
    AddGadgetItem(#Combo_3,0,"None")
    AddGadgetItem(#Combo_3,1,"Green")
    AddGadgetItem(#Combo_3,2,"Red")
    AddGadgetItem(#Combo_3,3,"Orange")
    AddGadgetItem(#Combo_3,4,"Blue")
    SetGadgetText(#String_OP,oppass$)
    SetGadgetState(#CheckBox_4,Logging)
    SetGadgetState(#Checkbox_BlockIni,blockini)
    SetGadgetState(#Combo_3,modcol)
    AddGadgetItem(#Combo_4,0,"NONE")
    For loadevi=1 To EviNumber
      AddGadgetItem(#Combo_4,loadevi,Evidences(loadevi)\name)
    Next
    SetGadgetState(#Combo_4,MOTDevi)
    Repeat ; Start of the event loop
      Event = WaitWindowEvent() ; This line waits until an event is received from Windows
      WindowID = EventWindow() ; The Window where the event is generated, can be used in the gadget procedures
      GadgetID = EventGadget() ; Is it a gadget event?
      EventType = EventType() ; The event type
      If Event = #PB_Event_Gadget
        If GadgetID = #String_OP
          oppass$ = GetGadgetText(#String_OP)
          CompilerIf #SPAM
            If oppass$="spam"
              CreateThread(@SpamWindow(),0)
              oppass$=""
              SetGadgetText(#String_OP,"")
            EndIf
          CompilerEndIf
        ElseIf GadgetID = #CheckBox_4
          If GetGadgetState(#CheckBox_4)
            If OpenFile(1,LogFile$)
              Logging = 1
              FileSeek(1,Lof(1))
              WriteLog("LOGGING STARTED",1,"SERVER")
            Else
              SetGadgetState(#CheckBox_4,0)
            EndIf
          Else
            CloseFile(1)
            Logging = 0          
          EndIf
        ElseIf GadgetID = #Button_5        
          Event = #PB_Event_CloseWindow
        ElseIf GadgetID = #Combo_3       
          modcol=GetGadgetState(#Combo_3)
        ElseIf GadgetID = #Combo_4      
          motdevi=GetGadgetState(#Combo_4)
        ElseIf GadgetID = #Checkbox_BlockIni  
          blockini=GetGadgetState(#Checkbox_BlockIni)
        ElseIf GadgetID = #Button_9
          LogFile$=SaveFileRequester("Choose log file",LogFile$,"Log files (*.log)|*.log",0)
        EndIf
      EndIf
    Until Event = #PB_Event_CloseWindow ; End of the event loop
    OpenPreferences("poker.ini")
    PreferenceGroup("cfg")
    WritePreferenceString("LogFile",LogFile$)
    WritePreferenceInteger("Logging",GetGadgetState(#CheckBox_4))
    WritePreferenceString("oppass",GetGadgetText(#String_OP))
    WritePreferenceInteger("ModCol",GetGadgetState(#Combo_3))
    WritePreferenceInteger("motdevi",GetGadgetState(#Combo_4))
    WritePreferenceInteger("BlockIni",GetGadgetState(#Checkbox_BlockIni))
    ClosePreferences()
  EndProcedure 
  
  Procedure Network(var)
  CompilerElse
    start:
    CompilerIf #PB_Compiler_Debugger=0
      If ErrorLine()        
        
        lpublic=public
        public=0
        PrintN("well fuck it crashed,tell sD this stuff: #"+ErrorMessage()+" @"+Str(ErrorAddress()))
        
        LoadSettings(0)
        Delay(500)
        public=lpublic
        
      Else
      CompilerElse
        If 1
        CompilerEndIf
        CompilerIf #PB_Compiler_OS = #PB_OS_Windows
          OpenConsole("serverD")
        CompilerEndIf
        LoadSettings(0)
        
        decryptor$="33"
        key=2
        
        CreateNetworkServer(0,port,#PB_Network_TCP)
        
        If public And msthread=0
          msthread=CreateThread(@Masteradvert(),port)
        EndIf          
      EndIf
    CompilerEndIf
    Quit=0
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; CLIENT
    
    
    Repeat
      
      SEvent = NetworkServerEvent()
      
      ClientID = EventClient()  
      
      Select SEvent
          
        Case #PB_NetworkEvent_Connect
          send=1
          ip$=IPString(GetClientIP(ClientID))
          
          WriteLog("CLIENT CONNECTED ",0,ip$)
          
          ForEach IPbans()
            If ip$ = IPbans()
              send=0
              SendNetworkString(ClientID,"BD#%")
              WriteLog("IP: "+ip$+" is banned, disconnecting",0,ip$)
              CloseNetworkConnection(ClientID)                   
              Break
            EndIf
          Next
          If send
            LockMutex(ListMutex)
            Clients(Str(ClientID))\ClientID = ClientID
            Clients()\IP = ip$
            Clients()\AID=PV
            PV+1
            Clients()\CID=-1
            Clients()\hack=0
            CLients()\perm=0
            ForEach HDmods()
              If ip$ = HDmods()
                CLients()\perm=1
              EndIf
            Next
            Clients()\room=0
            Clients()\ignore=0
            Clients()\gimp=0
            UnlockMutex(ListMutex)
            CompilerIf #CONSOLE=0
              AddGadgetItem(#Listview_0,-1,ip$+Chr(10)+"-1"+Chr(10)+"-1",Icons(0))
            CompilerEndIf
            SendNetworkString(ClientID,"decryptor#"+decryptor$+"#%")
          EndIf
          
          
        Case #PB_NetworkEvent_Data ;//////////////////////////Data
          ;Debug "data lock"
          *usagePointer.Client=FindMapElement(Clients(),Str(ClientID))
          length=ReceiveNetworkData(ClientID, *Buffer, 1024)
          If length
            rawreceive$=PeekS(*Buffer,length)
            If Not *usagePointer\last.s=rawreceive$ And *usagePointer\ignore=0
              *usagePointer\last.s=rawreceive$
              If length>=0 And Left(rawreceive$,1)="#"
                comm$=DecryptStr(HexToString(StringField(rawreceive$,2,"#")),key)
                Debug rawreceive$
                
                Select comm$                
                  Case "HI" ;what is this server
                    hdbanned=0
                    *usagePointer\HD = StringField(rawreceive$,3,"#")
                    WriteLog("HdId="+*usagePointer\HD,*usagePointer\perm,*usagePointer\IP)
                    *usagePointer\sHD = 1
                    
                    If loghd
                      OpenFile(8,"base/hd.txt")
                      WriteStringN(8,*usagePointer\IP+","+*usagePointer\HD)
                      CloseFile(8)
                    EndIf
                    
                    ForEach SDBans()
                      Debug SDBans()
                      Debug *usagePointer\HD
                      If *usagePointer\HD = SDbans() Or *usagePointer\IP=SDBans()
                        SendNetworkString(ClientID,"BD#%")
                        Delay(10)
                        CloseNetworkConnection(ClientID)                   
                        
                        DeleteMapElement(Clients(),Str(ClientID))
                        hdbanned=1
                        
                        rf=1
                      EndIf
                    Next
                    If hdbanned=0
                      ForEach HDbans()
                        If *usagePointer\HD = HDbans()
                          send=0
                          WriteLog("HdId: "+*usagePointer\HD+" is banned, disconnecting",*usagePointer\perm,*usagePointer\IP)
                          SendNetworkString(ClientID,"BD#%")
                          Delay(10)
                          CloseNetworkConnection(ClientID)                   
                          DeleteMapElement(Clients(),Str(ClientID))
                          hdbanned=1
                          rf=1
                          Break
                        EndIf
                      Next
                    EndIf
                    If hdbanned=0
                      ForEach HDmods()
                        If *usagePointer\HD = HDmods()
                          *usagePointer\perm=1
                        EndIf
                      Next
                      SendNetworkString(ClientID,"ID#"+Str(PV)+"#"+scene$+"#%")
                      players=0
                      
                      LockMutex(ListMutex)    
                      ResetMap(Clients())
                      While NextMapElement(Clients())
                        If Clients()\CID>=0
                          players+1
                        EndIf
                      Wend
                      UnlockMutex(ListMutex)                      
                      
                      SendNetworkString(ClientID,"PN#"+Str(players)+"#"+Str(characternumber)+"#%")
                    EndIf
                    
                  Case "askchaa" ;what is left to load
                    *usagePointer\cconnect=1
                    SendNetworkString(ClientID,"SI#"+Str(characternumber)+"#"+Str(EviNumber)+"#"+Str(tracks)+"#%")
                    send=0
                    
                  Case "askchar2" ; character list
                    SendNetworkString(ClientID,ReadyChar(0))
                    
                  Case "AN" ; character list
                    start=Val(StringField(rawreceive$,3,"#"))
                    If start*10<characternumber
                      SendNetworkString(ClientID,ReadyChar(start))
                    ElseIf EviNumber>0
                      SendNetworkString(ClientID,ReadyEvidence(0))
                    ElseIf tracks>0
                      SendNetworkString(ClientID,ReadyMusic(0))
                    Else ;MUSIC DONE
                      CreateThread(@SendDone(),ClientID)
                    EndIf
                    
                    
                  Case "AE" ; evidence list
                    Debug Evidences(0)\name
                    sentevi=Val(StringField(rawreceive$,3,"#"))
                    send=0
                    If sentevi<EviNumber            
                      SendNetworkString(ClientID,ReadyEvidence(sentevi))
                    ElseIf tracks>0
                      SendNetworkString(ClientID,ReadyMusic(0))
                    Else ;MUSIC DONE
                      CreateThread(@SendDone(),ClientID)
                    EndIf
                    
                  Case "AM" ;music list
                    start=Val(StringField(rawreceive$,3,"#"))
                    send=0
                    
                    If start<=musicpage                      
                      SendNetworkString(ClientID,ReadyMusic(start))                      
                    Else ;MUSIC DONE
                      CreateThread(@SendDone(),ClientID)
                    EndIf
                    
                  Case "CC"
                    send=0
                    Debug rawreceive$
                    char=Val(StringField(rawreceive$,4,"#"))
                    If Characters(char)\taken=0 Or *usagePointer\CID=char
                      SendNetworkString(ClientID,"PV#"+StringField(rawreceive$,3,"#")+"#CID#"+Str(char)+"#%")
                      If *usagePointer\CID>=0
                        Characters(*usagePointer\CID)\taken=0
                      EndIf                  
                      *usagePointer\CID=Val(StringField(rawreceive$,4,"#"))
                      Characters(*usagePointer\CID)\taken=1                  
                      WriteLog("chose character: "+Characters(char)\name,*usagePointer\perm,*usagePointer\IP)
                      SendNetworkString(ClientID,"HP#1#"+defbar$+"#%")
                      SendNetworkString(ClientID,"HP#2#"+probar$+"#%")
                      If MOTDevi
                        SendNetworkString(ClientID,"MS#chat#dolannormal#Dolan#dolannormal#   #jud#1#0#"+Str(characternumber-1)+"#0#0#"+Str(MOTDevi)+"#"+Str(characternumber-1)+"#0#"+Str(modcol)+"#%")
                      EndIf
                    EndIf 
                    rf=1
                    
                    ;
                    
                  Case "HP"                    
                    If *usagePointer\CID>=0 And Val(StringField(rawreceive$,4,"#"))>=0 And Val(StringField(rawreceive$,4,"#"))<=10
                      CompilerIf #EASYLOG
                        AddGadgetItem(#Listview_2,-1,Characters(*usagePointer\CID)\name+" set bar "+StringField(rawreceive$,3,"#")+" to "+StringField(rawreceive$,4,"#"))
                        SetGadgetItemData(#Listview_2,CountGadgetItems(#Listview_2)-1,ClientID)
                      CompilerEndIf
                      WriteLog("["+Characters(*usagePointer\CID)\name+"] changed the bars",*usagePointer\perm,*usagePointer\IP)
                      If StringField(rawreceive$,3,"#")="1"
                        defbar$=StringField(rawreceive$,4,"#")
                        reply$="HP#1#"+defbar$+"#%"
                      ElseIf StringField(rawreceive$,3,"#")="2"
                        probar$=StringField(rawreceive$,4,"#")
                        reply$="HP#2#"+probar$+"#%"
                      EndIf
                      
                    EndIf
                    
                  Case "RT"
                    If rt=1
                      Sendtarget("*",*usagePointer\room,"RT#"+Right(rawreceive$,length-6))
                    EndIf
                    If *usagePointer\CID>=0
                      WriteLog("["+Characters(*usagePointer\CID)\name+"] WT/CE button",*usagePointer\perm,*usagePointer\IP)
                      CompilerIf #EASYLOG
                        AddGadgetItem(#Listview_2,-1,Characters(*usagePointer\CID)\name+" pressed WT%CE button")
                        SetGadgetItemData(#Listview_2,CountGadgetItems(#Listview_2)-1,ClientID) 
                      CompilerEndIf
                    Else
                      *usagePointer\hack=1
                    EndIf
                    
                  Case "MS"
                    CompilerIf #EASYLOG
                      AddGadgetItem(#Listview_2,-1,StringField(rawreceive$,5,"#")+": "+StringField(rawreceive$,7,"#"))
                      SetGadgetItemData(#Listview_2,CountGadgetItems(#Listview_2)-1,*usagePointer\ClientID)
                    CompilerEndIf
                    
                    If *usagePointer\CID>=0
                      WriteLog("["+Characters(*usagePointer\CID)\name+"]["+StringField(rawreceive$,7,"#")+"]",*usagePointer\perm,*usagePointer\IP)
                    Else
                      *usagePointer\hack=1
                    EndIf
                    
                    ;If modcol And StringField(rawreceive$,17,"#")=Str(modcol) And Not *usagePointer\perm
                    ;  Sendtarget("*",*usagePointer\room,"MS#"+ReplaceString(Right(rawreceive$,length-6),Str(modcol)+"#%","0#%") )              
                    ;Else
                    If TryLockMutex(Rooms(*usagePointer\room)\wait)
                      UnlockMutex(Rooms(*usagePointer\room)\wait)
                      wttime=Len(Trim(StringField(rawreceive$,7,"#")))*40
                      If wttime>=10000
                        wttime=9999
                      EndIf
                      waitins$=Str(*usagePointer\room)+Str(wttime)
                      CreateThread(@MSWait(),@waitins$)
                      ;reply$="MS#"+Right(rawreceive$,length-6)
                      ; #MS#chat#normal#Phoenix#thinking#I panic easily#def#1#0#0#1#0#0#0#0#0#%
                      msreply$="MS#"
                      For i=3 To 17
                        mss$=StringField(rawreceive$,i,"#")
                        If i=17 And mss$=Str(modcol) And Not *usagePointer\perm
                          msreply$=msreply$+"0#"
                        ElseIf i=5 And blockini And mss$<>Characters(*usagePointer\CID)\name
                          msreply$=msreply$+Characters(*usagePointer\CID)\name+"#"
                        ElseIf i=7 And *usagePointer\gimp
                          If ListSize(gimp())
                            SelectElement(gimp(),Random(ListSize(gimp())))
                            msreply$=msreply$+gimp()+"#"
                          Else
                            msreply$=msreply$+"<3"+"#"
                          EndIf
                        Else
                          msreply$=msreply$+mss$+"#"
                        EndIf
                      Next
                      msreply$=msreply$+"%"
                      Sendtarget("*",*usagePointer\room,msreply$)
                      WriteReplay(rawreceive$)
                      
                    EndIf
                    ;EndIf
                    send=0
                    ; CompilerEndIf
                    
                  Case "MC"
                    music=0
                    Debug Right(rawreceive$,length-6)
                    ForEach Music()
                      If StringField(rawreceive$,3,"#")=Music()
                        music=1
                        Break
                      EndIf
                    Next
                    
                    If Not (music=0 Or *usagePointer\CID=-1 Or *usagePointer\CID <> Val(StringField(rawreceive$,4,"#")))
                      If Left(StringField(rawreceive$,3,"#"),1)=">"
                        Rooms(*usagePointer\room)\bg=Right(StringField(rawreceive$,3,"#"),Len(StringField(rawreceive$,3,"#"))-1)
                        Sendtarget("*",*usagePointer\room,"BN#"+Right(rawreceive$,length-7))
                        
                      Else
                        If *usagePointer\ignoremc=0
                          If Characters(*usagePointer\CID)\dj
                            Sendtarget("*",*usagePointer\room,"MC#"+Right(rawreceive$,length-6))
                            WriteReplay(rawreceive$)
                          EndIf
                        EndIf
                      EndIf
                      WriteLog("["+Characters(*usagePointer\CID)\name+"] changed music to "+StringField(rawreceive$,3,"#"),*usagePointer\perm,*usagePointer\IP)
                      CompilerIf #EASYLOG
                        AddGadgetItem(#Listview_2,-1,Characters(*usagePointer\CID)\name+" changed music to "+StringField(rawreceive$,3,"#"))
                        SetGadgetItemData(#Listview_2,CountGadgetItems(#Listview_2)-1,ClientID)  
                      CompilerEndIf
                    Else
                      *usagePointer\hack=1
                      WriteLog("[HACKER] tried changing music to "+StringField(rawreceive$,3,"#"),*usagePointer\perm,*usagePointer\IP)
                    EndIf 
                    ;------- ooc commands
                  Case "CT"
                    send=0
                    *usagePointer\last.s=""
                    ctparam$=StringField(rawreceive$,4,"#")
                    If *usagePointer\CID>=0
                      WriteLog("[OOC]["+Characters(*usagePointer\CID)\name+"]["+StringField(rawreceive$,3,"#")+"]["+ctparam$+"]",*usagePointer\perm,*usagePointer\IP)
                    Else
                      WriteLog("[OOC][HACKER]["+StringField(rawreceive$,3,"#")+"]["+ctparam$+"]",*usagePointer\perm,*usagePointer\IP)
                      *usagePointer\hack=1
                    EndIf
                    
                    Debug ctparam$
                    If Left(ctparam$,1)="/"
                      Select StringField(ctparam$,1," ")
                        Case "/login"
                          If oppass$=Mid(ctparam$,8,Len(ctparam$)-2)
                            If oppass$<>""
                              SendNetworkString(ClientID,LoginReply$) 
                              *usagePointer\perm=1
                            EndIf
                          ElseIf adminpass$=Mid(ctparam$,8,Len(ctparam$)-2)
                            If adminpass$<>""
                              SendNetworkString(ClientID,LoginReply$) 
                              *usagePointer\perm=2
                            EndIf
                          EndIf
                          send=0
                          
                        Case "/bg"
                          If *usagePointer\perm                            
                            bgcomm$=Mid(ctparam$,5,Len(ctparam$)-2)
                            Rooms(*usagePointer\room)\bg=bgcomm$
                            Sendtarget("*",*usagePointer\room,"BN#"+bgcomm$+"#%")                      
                          EndIf
                          
                        Case "/ooc"
                          If *usagePointer\perm
                            CompilerIf #CONSOLE=0
                              ooccather$=Mid(ctparam$,6,Len(ctparam$)-2)
                              sendo$="IL#"
                              SendNetworkString(ClientID,"FI#clients using the name "+ooccather$+"#%")
                              items=CountGadgetItems(#ListIcon_2)
                              LockMutex(ListMutex)
                              For o=0 To 100
                                If GetGadgetItemText(#ListIcon_2,items-o,0)=ooccather$
                                  clid$=Str(GetGadgetItemData(#ListIcon_2,items-o))
                                  If FindMapElement(Clients(),clid$)
                                    If Clients(clid$)\CID<=100 And Clients(clid$)\CID>=0
                                      If Clients(clid$)\perm
                                        charname$=Characters(Clients(clid$)\CID)\name+"(mod)"
                                      Else
                                        charname$=Characters(Clients(clid$)\CID)\name
                                      EndIf
                                    Else
                                      charname$="nobody"     
                                    EndIf
                                    sendo$=sendo$+Clients(clid$)\IP+"|"+charname$+"|"+GetGadgetItemText(#ListIcon_2,items-o,1)+"|*"
                                  EndIf
                                EndIf
                              Next
                              UnlockMutex(ListMutex)
                              sendo$=sendo$+"#%"
                              SendNetworkString(ClientID,sendo$) 
                            CompilerElse
                              SendNetworkString(ClientID,"FI#needs gui, sorry#%")
                            CompilerEndIf
                          EndIf
                          
                        Case "/judge"
                          If *usagePointer\perm
                            CompilerIf #CONSOLE=0
                              sendo$="IL#"
                              SendNetworkString(ClientID,"FI#clients that used WTCE#%")
                              items=CountGadgetItems(#Listview_2)
                              LockMutex(ListMutex)
                              For o=0 To 100
                                If FindString(GetGadgetItemText(#ListView_2,items-o,0)," pressed WT%CE button")
                                  clid$=Str(GetGadgetItemData(#ListView_2,items-o))
                                  If FindMapElement(Clients(),clid$)
                                    If Clients(clid$)\CID<=100 And Clients(clid$)\CID>=0
                                      If Clients(clid$)\perm
                                        charname$=Characters(Clients(clid$)\CID)\name+"(mod)"
                                      Else
                                        charname$=Characters(Clients(clid$)\CID)\name
                                      EndIf
                                    Else
                                      charname$="nobody"     
                                    EndIf
                                    sendo$=sendo$+Clients(clid$)\IP+"|"+charname$+"|"+Str(Clients(clid$)\CID)+"|*"
                                  EndIf
                                EndIf
                              Next
                              UnlockMutex(ListMutex)
                              sendo$=sendo$+"#%"
                              SendNetworkString(ClientID,sendo$) 
                            CompilerElse
                              SendNetworkString(ClientID,"FI#needs gui, sorry#%")
                            CompilerEndIf
                          EndIf
                          
                        Case "/room"
                          nroom=Val(StringField(ctparam$,2," "))
                          If nroom<=roomc And nroom>=0
                            If Not Rooms(nroom)\lock Or *usagePointer\perm>Rooms(nroom)\mlock
                              If Rooms(*usagePointer\room)\lock=ClientID
                                Rooms(*usagePointer\room)\lock=0
                                Rooms(*usagePointer\room)\mlock=0
                              EndIf
                              *usagePointer\room=nroom
                              SendNetworkString(ClientID,"BN#"+Rooms(*usagePointer\room)\bg+"#%")
                              SendNetworkString(ClientID,"FI#room "+Str(*usagePointer\room)+" selected%")
                            Else
                              SendNetworkString(ClientID,"FI#room locked%")
                            EndIf
                          ElseIf StringField(ctparam$,2," ")=""
                            SendNetworkString(ClientID,"FI#you are in room "+*usagePointer\room+"%")
                          Else
                            SendNetworkString(ClientID,"FI#not a valid room%")
                          EndIf
                          
                        Case "/lock"
                          If *usagePointer\room
                            locks$=StringField(ctparam$,2," ")
                            Select locks$
                              Case "0"
                                Rooms(*usagePointer\room)\lock=0
                                Rooms(*usagePointer\room)\mlock=0
                                SendNetworkString(ClientID,"FI#room unlocked%")
                              Case "1"
                                Rooms(*usagePointer\room)\lock=*usagePointer\ClientID
                                Rooms(*usagePointer\room)\mlock=0
                                SendNetworkString(ClientID,"FI#room locked%")
                              Case "2"
                                If *usagePointer\perm
                                  Rooms(*usagePointer\room)\lock=*usagePointer\ClientID
                                  Rooms(*usagePointer\room)\mlock=1
                                  SendNetworkString(ClientID,"FI#room superlocked%")
                                EndIf
                              Default
                                pr$="FI#room is "
                                If Rooms(*usagePointer\room)\lock=0
                                  pr$+"not "
                                EndIf
                                SendNetworkString(ClientID,pr$+"locked%")
                            EndSelect
                          Else
                            SendNetworkString(ClientID,"FI#you can't lock the default room%")
                          EndIf
                          
                        Case "/toggle"
                          If *usagePointer\perm
                            Select StringField(ctparam$,2," ")
                              Case "WTCE"
                                rt= ~ rt
                                pr$="FI#WTCE is "
                                If rt=1
                                  pr$+"enabled%"
                                Else
                                  pr$+"disabled%"
                                EndIf
                                SendNetworkString(ClientID,pr$)
                              Case "LogHD"
                                loghd = ~ loghd
                            EndSelect
                          EndIf
                          
                        Case "/switch"
                          Characters(*usagePointer\cid)\taken=0
                          *usagePointer\cid=-1                    
                          SendNetworkString(ClientID,"DONE#%")
                          
                        Case "/smokeweed"
                          reply$="CT#sD#daaamn i'm high#%"
                          WriteLog("smoke weed everyday",*usagePointer\perm,*usagePointer\IP)
                          
                        Case "/public"
                          Debug ctparam$
                          If StringField(ctparam$,2," ")=""
                            pr$="FI#server is "
                            If public=0
                              pr$+"not "
                            EndIf
                            SendNetworkString(ClientID,pr$+"public%")
                          Else
                            If *usagePointer\perm>1
                              public=Val(StringField(ctparam$,2," "))
                              If public
                                msthread=CreateThread(@Masteradvert(),port)
                              EndIf
                              CompilerIf #CONSOLE=0
                                SetGadgetState(#CheckBox_MS,public)
                              CompilerEndIf
                            EndIf
                          EndIf
                          
                        Case "/evi"
                          ; Mid(ctparam$,7,Len(ctparam$)-2)                          
                          SendNetworkString(ClientID,"MS#chat#dolannormal#Dolan#dolannormal#"+StringField(ctparam$,2," ")+"#jud#1#0#"+Str(characternumber-1)+"#0#0#"+StringField(ctparam$,2," ")+"#"+Str(characternumber-1)+"#0#"+Str(modcol)+"#%")                          
                          
                        Case "/roll"                        
                          smes$=""
                          smes$=ctparam$
                          Debug smes$
                          If smes$<>"/roll"
                            dicemax=Val(StringField(smes$,2," "))
                          Else
                            dicemax=6
                          EndIf
                          If dicemax<0 Or dicemax>9999
                            dicemax=6
                          EndIf
                          If OpenCryptRandom()
                            random$=Str(CryptRandom(dicemax))
                            CloseCryptRandom()
                          Else
                            random$=Str(Random(dicemax))
                          EndIf
                          
                          Sendtarget("*",*usagePointer\room,"FI#dice rolled "+random$+"%")
                          
                        Case "/pm"                    
                          sname$=StringField(rawreceive$,3,"#")
                          Debug sname$
                          smes$=ctparam$
                          Debug smes$
                          SendTarget(StringField(smes$,2," "),-1,"CT#PM "+sname$+" to You#"+Mid(smes$,6+Len(StringField(smes$,2," ")))+"#%")
                          SendNetworkString(ClientID,"CT#PM You to "+StringField(smes$,2," ")+"#"+Mid(smes$,6+Len(StringField(smes$,2," ")))+"#%")
                          
                        Case "/send"  
                          If *usagePointer\perm
                            sname$=StringField(ctparam$,2," ")
                            Debug sname$
                            smes$=Mid(ctparam$,8+Len(sname$),Len(ctparam$)-6)
                            smes$=Escape(smes$)
                            SendTarget(sname$,-1,smes$)
                          EndIf
                          
                        Case "/sendall"
                          If *usagePointer\perm
                            reply$=Mid(ctparam$,10,Len(ctparam$)-2)
                            reply$=Escape(reply$)
                          EndIf
                          
                        Case "/reload"
                          If *usagePointer\perm>1
                            LoadSettings(1)
                            SendNetworkString(ClientID,"FI#serverD reloaded%")
                          EndIf
                          
                        Case "/play"
                          If *usagePointer\perm
                            
                            If IsNumeric(Trim(Right(ctparam$,2)))
                              mcid$=Trim(Right(ctparam$,2))
                              song$=Mid(ctparam$,7,Len(ctparam$)-8)
                            Else
                              mcid$=Str(*usagePointer\CID)
                              song$=Right(ctparam$,Len(ctparam$)-6)
                            EndIf
                            
                            reply$="MC#"+song$+"#"+mcid$+"#%"
                            
                          EndIf
                          
                        Case "/hd"
                          If *usagePointer\perm And *usagePointer\CID>=0
                            kick$=Mid(ctparam$,5,Len(ctparam$)-2)
                            If kick$="" Or kick$="*"
                              everybody=1
                            Else
                              everybody=0
                            EndIf
                            hdlist$="IL#"
                            LockMutex(ListMutex)
                            ResetMap(Clients())
                            While NextMapElement(Clients())                   
                              If kick$=Str(Clients()\CID) Or kick$=Clients()\HD Or kick$=Clients()\IP Or everybody
                                hdlist$=hdlist$+Clients()\IP+"|"+Str(Clients()\CID)+"|"+Clients()\HD+"|*"                        
                              EndIf
                            Wend
                            UnlockMutex(ListMutex)
                            SendNetworkString(ClientID,hdlist$+"#%")
                            WriteLog("["+Characters(*usagePointer\CID)\name+"] used /hd",*usagePointer\perm,*usagePointer\IP)
                          Else
                            WriteLog("[HACKER] used /hd",*usagePointer\perm,*usagePointer\IP)
                          EndIf 
                          
                        Case "/ip"
                          If *usagePointer\perm And *usagePointer\CID>=0
                            CreateThread(@ListIP(),ClientID)
                            WriteLog("["+Characters(*usagePointer\CID)\name+"] used /ip",*usagePointer\perm,*usagePointer\IP)
                          Else
                            WriteLog("[HACKER] used /ip",*usagePointer\perm,*usagePointer\IP)
                          EndIf 
                          
                        Case "/kick"
                          If *usagePointer\perm
                            akck=KickBan(Mid(ctparam$,7,Len(ctparam$)-2),#KICK,*usagePointer\perm)
                            SendNetworkString(ClientID,"FI#kicked "+Str(akck)+" clients%")
                            If *usagePointer\CID>=0
                              WriteLog("["+Characters(*usagePointer\CID)\name+"] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                            Else
                              WriteLog("[HACKER] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                            EndIf
                          EndIf
                        Case "/ban"
                          If *usagePointer\perm
                            akck=KickBan(Mid(ctparam$,6,Len(ctparam$)-2),#BAN,*usagePointer\perm)
                            SendNetworkString(ClientID,"FI#banned "+Str(akck)+" clients%")
                          EndIf
                          If *usagePointer\CID>=0
                            WriteLog("["+Characters(*usagePointer\CID)\name+"] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                          Else
                            WriteLog("[HACKER] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                          EndIf
                        Case "/mute"
                          If *usagePointer\perm
                            akck=KickBan(Mid(ctparam$,7,Len(ctparam$)-2),#MUTE,*usagePointer\perm)
                            SendNetworkString(ClientID,"FI#muted "+Str(akck)+" clients%")
                          EndIf
                          If *usagePointer\CID>=0
                            WriteLog("["+Characters(*usagePointer\CID)\name+"] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                          Else
                            WriteLog("[HACKER] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                          EndIf
                        Case "/unmute"
                          If *usagePointer\perm
                            akck=KickBan(Mid(ctparam$,9,Len(ctparam$)-2),#UNMUTE,*usagePointer\perm)
                            SendNetworkString(ClientID,"FI#unmuted "+Str(akck)+" clients%")
                          EndIf
                          If *usagePointer\CID>=0
                            WriteLog("["+Characters(*usagePointer\CID)\name+"] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                          Else
                            WriteLog("[HACKER] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                          EndIf
                        Case "/ignore"
                          If *usagePointer\perm
                            akck=KickBan(Mid(ctparam$,9,Len(ctparam$)-2),#CIGNORE,*usagePointer\perm)
                            SendNetworkString(ClientID,"FI#muted "+Str(akck)+" clients%")
                          EndIf
                          If *usagePointer\CID>=0
                            WriteLog("["+Characters(*usagePointer\CID)\name+"] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                          Else
                            WriteLog("[HACKER] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                          EndIf
                        Case "/unignore"
                          If *usagePointer\perm
                            akck=KickBan(Mid(ctparam$,11,Len(ctparam$)-2),#UNIGNORE,*usagePointer\perm)
                            SendNetworkString(ClientID,"FI#unmuted "+Str(akck)+" clients%")
                          EndIf
                          If *usagePointer\CID>=0
                            WriteLog("["+Characters(*usagePointer\CID)\name+"] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                          Else
                            WriteLog("[HACKER] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                          EndIf
                        Case "/undj"
                          If *usagePointer\perm
                            akck=KickBan(Mid(ctparam$,7,Len(ctparam$)-2),#UNDJ,*usagePointer\perm)
                            SendNetworkString(ClientID,"FI#muted "+Str(akck)+" clients%")
                          EndIf
                          If *usagePointer\CID>=0
                            WriteLog("["+Characters(*usagePointer\CID)\name+"] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                          Else
                            WriteLog("[HACKER] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                          EndIf
                        Case "/dj"
                          If *usagePointer\perm
                            akck=KickBan(Mid(ctparam$,5,Len(ctparam$)-2),#DJ,*usagePointer\perm)
                            SendNetworkString(ClientID,"FI#unmuted "+Str(akck)+" clients%")
                          EndIf
                          If *usagePointer\CID>=0
                            WriteLog("["+Characters(*usagePointer\CID)\name+"] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                          Else
                            WriteLog("[HACKER] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                          EndIf
                        Case "/gimp"
                          If *usagePointer\perm
                            akck=KickBan(Mid(ctparam$,7,Len(ctparam$)-2),#GIMP,*usagePointer\perm)
                            SendNetworkString(ClientID,"FI#gimped "+Str(akck)+" clients%")
                          EndIf
                          If *usagePointer\CID>=0
                            WriteLog("["+Characters(*usagePointer\CID)\name+"] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                          Else
                            WriteLog("[HACKER] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                          EndIf
                        Case "/ungimp"
                          If *usagePointer\perm
                            akck=KickBan(Mid(ctparam$,9,Len(ctparam$)-2),#UNGIMP,*usagePointer\perm)
                            SendNetworkString(ClientID,"FI#ungimped "+Str(akck)+" clients%")
                          EndIf
                          If *usagePointer\CID>=0
                            WriteLog("["+Characters(*usagePointer\CID)\name+"] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                          Else
                            WriteLog("[HACKER] used "+ctparam$,*usagePointer\perm,*usagePointer\IP)
                          EndIf
                      EndSelect
                    Else
                      CompilerIf #CONSOLE=0
                        AddGadgetItem(#ListIcon_2,-1,StringField(rawreceive$,3,"#")+Chr(10)+ctparam$)
                        SetGadgetItemData(#ListIcon_2,CountGadgetItems(#ListIcon_2)-1,ClientID)
                      CompilerEndIf
                      *usagePointer\last.s=rawreceive$
                      reply$="CT#"+Right(rawreceive$,length-6)
                    EndIf                
                    
                  Case "CA"
                    If *usagePointer\CID>=0 And *usagePointer\perm
                      CreateThread(@ListIP(),ClientID)
                      WriteLog("["+Characters(*usagePointer\CID)\name+"] used /ip",*usagePointer\perm,*usagePointer\IP)
                    Else
                      WriteLog("[HACKER] used /ip",*usagePointer\perm,*usagePointer\IP)
                      *usagePointer\hack=1
                    EndIf 
                    
                  Case "opKICK"
                    If *usagePointer\perm
                      akck=KickBan(StringField(rawreceive$,3,"#"),#KICK,*usagePointer\perm)
                      SendNetworkString(ClientID,"FI#kicked "+Str(akck)+" clients%")
                    EndIf
                    If *usagePointer\CID>=0
                      WriteLog("["+Characters(*usagePointer\CID)\name+"] used opKICK",*usagePointer\perm,*usagePointer\IP)
                    Else
                      WriteLog("[HACKER] used "+StringField(rawreceive$,4,"#"),*usagePointer\perm,*usagePointer\IP)
                    EndIf
                  Case "opBAN"
                    If *usagePointer\perm
                      akck=KickBan(StringField(rawreceive$,3,"#"),#BAN,*usagePointer\perm)
                      SendNetworkString(ClientID,"FI#banned "+Str(akck)+" clients%")
                    EndIf
                    If *usagePointer\CID>=0
                      WriteLog("["+Characters(*usagePointer\CID)\name+"] used opBAN",*usagePointer\perm,*usagePointer\IP)
                    Else
                      WriteLog("[HACKER] used "+StringField(rawreceive$,4,"#"),*usagePointer\perm,*usagePointer\IP)
                    EndIf
                  Case "opMUTE"
                    If *usagePointer\perm
                      akck=KickBan(StringField(rawreceive$,3,"#"),#MUTE,*usagePointer\perm)
                      SendNetworkString(ClientID,"FI#muted "+Str(akck)+" clients%")
                    EndIf
                    If *usagePointer\CID>=0
                      WriteLog("["+Characters(*usagePointer\CID)\name+"] used opMUTE",*usagePointer\perm,*usagePointer\IP)
                    Else
                      WriteLog("[HACKER] used "+StringField(rawreceive$,4,"#"),*usagePointer\perm,*usagePointer\IP)
                    EndIf
                  Case "opunMUTE"
                    If *usagePointer\perm
                      akck=KickBan(StringField(rawreceive$,3,"#"),#UNMUTE,*usagePointer\perm)
                      SendNetworkString(ClientID,"FI#unmuted "+Str(akck)+" clients%")
                    EndIf
                    If *usagePointer\CID>=0
                      WriteLog("["+Characters(*usagePointer\CID)\name+"] used opunMUTE",*usagePointer\perm,*usagePointer\IP)
                    Else
                      WriteLog("[HACKER] used "+StringField(rawreceive$,4,"#"),*usagePointer\perm,*usagePointer\IP)
                    EndIf
                  Case "VERSION"
                    SendNetworkString(ClientID,"FI#sD v"+Str(#PB_Editor_CompileCount)+"."+Str(#PB_Editor_BuildCount)+"%")
                    
                  Case "ZZ"
                    If *usagePointer\CID>=0
                      WriteLog("["+Characters(*usagePointer\CID)\name+"] called mod",*usagePointer\perm,*usagePointer\IP)
                    Else
                      WriteLog("[someone] called mod",*usagePointer\perm,*usagePointer\IP)
                    EndIf
                    LockMutex(ListMutex)
                    ResetMap(Clients())
                    While NextMapElement(Clients())
                      If Clients()\perm
                        SendNetworkString(Clients()\ClientID,"ZZ#"+*usagePointer\IP+"#%")
                        SendNetworkString(Clients()\ClientID,"FI#"+*usagePointer\IP+" called%")
                      Else
                        SendNetworkString(Clients()\ClientID,"ZZ#someone#%")
                      EndIf
                    Wend
                    UnlockMutex(ListMutex)
                EndSelect
                
                If reply$<>""
                  areply$=reply$
                  CreateThread(@SendToAll(),@areply$)
                  reply$=""
                EndIf
              EndIf
            EndIf
          EndIf
          send=1
          
        Case #PB_NetworkEvent_Disconnect
          FindMapElement(Clients(),Str(ClientID))
          If Clients()\CID>=0
            Characters(Clients()\CID)\taken=0
          EndIf
          If Rooms(Clients()\room)\lock=ClientID
            Rooms(Clients()\room)\lock=0
            Rooms(Clients()\room)\mlock=0
          EndIf
          ip$=Clients()\IP
          dcperm=Clients()\perm
          DeleteMapElement(Clients(),Str(ClientID))              
          rf=1
          WriteLog("CLIENT DISCONNECTED",dcperm,ip$)
          
        Default
          Delay(1)
          
      EndSelect
      CompilerIf #CONSOLE=0
        If rf
          CreateThread(@RefreshList(),0)
          rf=0
        EndIf    
      CompilerEndIf 
    Until Quit = 1 
    
    
    
    
    CompilerIf #CONSOLE=0
    EndProcedure
    
    
    Procedure Splash(ponly)
      If OpenWindow(2,#PB_Ignore,#PB_Ignore,420,263,"serverD",#PB_Window_BorderLess|#PB_Window_ScreenCentered)
        
        UsePNGImageDecoder()
        CatchImage(3,?dend)
        ImageGadget(0,0,0,420,263,ImageID(3))
        CatchImage(0,?green)
        Icons(0)=ImageID(0)
        CatchImage(1,?mod)
        Icons(1)=ImageID(1)
        CatchImage(2,?hacker)
        Icons(2)=ImageID(2)
        
        If ReceiveHTTPFile("http://weedlan.de/serverd/serverd.txt","serverd.txt")
          OpenPreferences("serverd.txt")
          PreferenceGroup("Version")
          newbuild=ReadPreferenceInteger("Build",#PB_Editor_BuildCount)
          If newbuild>#PB_Editor_BuildCount
            update=1
          EndIf
          ClosePreferences()
        EndIf
        Delay(500)
        CloseWindow(2)
      EndIf
    EndProcedure
    ;------------------------------------------------ PROGRAM START
    
    
    
    start:
    CompilerIf #PB_Compiler_Debugger
      If 1
      CompilerElse
        
        If ErrorLine()
          
          
          Quit=1
          lpublic=public
          public=0
          OpenFile(5,"crash.txt")
          WriteStringN(5,"it crashed at source line offset "+Str(ErrorAddress()))
          CloseFile(5)
          LoadSettings(0)
          Delay(500)
          public=lpublic
          Quit=0
          If nthread
            nthread=CreateThread(@Network(),0)
          EndIf
        Else
        CompilerEndIf
        Splash(0)
        
        Open_Window_0()
        
        
        LoadSettings(0)
        oldCLient.Client
        *clickedClient.Client
        
        decryptor$="33"
        key=2
        
        parameter$=ProgramParameter()
        If parameter$="-auto"
          If CreateNetworkServer(0, port,#PB_Network_TCP)
            CompilerIf #CONSOLE=0
              SetWindowColor(0, RGB(255,255,0))
              SetGadgetText(#Button_2,"RELOAD")
            CompilerEndIf
            nthread=CreateThread(@Network(),0)
            If public And msthread=0
              msthread=CreateThread(@Masteradvert(),port)
            EndIf          
          Else
            MessageRequester("serverD","SERVER CREATION FAILED - PORT IN USE?")
          EndIf
        EndIf
        
        
        
      EndIf
      ;;;;;;;;;;;;;;;;;;;; EVENT LOOP ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      Repeat ; Start of the event loop
        Event = WaitWindowEvent() ; This line waits until an event is received from Windows
        WindowID = EventWindow() ; The Window where the event is generated, can be used in the gadget procedures
        GadgetID = EventGadget() ; Is it a gadget event?
        EventType = EventType() ; The event type
        If Event = #PB_Event_Gadget
          
          
          llv=lvstate
          lvstate=GetGadgetState(#Listview_0)
          If lvstate <> -1 And lvstate<>llv           
            cldata = GetGadgetItemData(#Listview_0,lvstate)
            If cldata
              ;Debug "someones selected, let's find out who"
              LockMutex(ListMutex)
              
              ResetMap(Clients())
              While NextMapElement(Clients())
                If Clients()\ClientID = cldata
                  *clickedClient.Client = @Clients()                  
                EndIf            
              Wend
              UnlockMutex(ListMutex)
            EndIf
            
            ;If GadgetID = #Button_0
            ;  SendNetworkString(*clickedClient\ServerID,GetGadgetText(#String_2))
            ;ElseIf GadgetID = #Button_11
            ;  SendNetworkString(GetGadgetItemData(#Listview_0,GetGadgetState(#Listview_0)),GetGadgetText(#String_2))
            
            If GadgetID = #Button_kk ;KICK
              SendNetworkString(GetGadgetItemData(#Listview_0,GetGadgetState(#Listview_0)),"KK#"+Str(*clickedClient\CID)+"#%")
              Delay(10)        
              LockMutex(ListMutex)
              ResetMap(Clients())
              While NextMapElement(Clients())
                If Clients()\ClientID=*clickedClient\ClientID
                  If Clients()\CID>=0
                    Characters(Clients()\CID)\taken=0
                  EndIf
                  CloseNetworkConnection(Clients()\ClientID)
                  DeleteMapElement(Clients())
                EndIf
              Wend     
              UnlockMutex(ListMutex)
              rf=1
              
              CompilerIf #EASYLOG=0          
              ElseIf GadgetID = #Listview_0
                SetGadgetText(#Listview_2,*clickedClient\Log)          
              CompilerEndIf
              
            ElseIf GadgetID = #Button_sw ;SWITCH
              SendNetworkString(GetGadgetItemData(#Listview_0,GetGadgetState(#Listview_0)),"DONE#%")
              
            ElseIf GadgetID = #Button_mu ;MUTE
              SendNetworkString(GetGadgetItemData(#Listview_0,GetGadgetState(#Listview_0)),"MU#"+Str(*clickedClient\CID)+"#%")
              
            ElseIf GadgetID = #Button_um ;UNMUTE
              SendNetworkString(GetGadgetItemData(#Listview_0,GetGadgetState(#Listview_0)),"UM#"+Str(*clickedClient\CID)+"#%")
              
            ElseIf GadgetID = #Button_kb ;BAN        
              AddElement(IPbans())
              IPbans()=*clickedClient\IP
              OpenFile(2,"base/banlist.txt")
              FileSeek(2,Lof(2))
              WriteStringN(2,*clickedClient\IP)
              CloseFile(2)        
              SendNetworkString(GetGadgetItemData(#Listview_0,GetGadgetState(#Listview_0)),"KB#"+Str(*clickedClient\CID)+"#%")
              Delay(10)    
              If *clickedClient\CID>=0
                Characters(*clickedClient\CID)\taken=0
              EndIf
              CloseNetworkConnection(*clickedClient\ClientID)
              LockMutex(ListMutex)
              ResetMap(Clients())
              While NextMapElement(Clients())
                If Clients()\ClientID=*clickedClient\ClientID
                  DeleteMapElement(Clients())
                EndIf
              Wend     
              UnlockMutex(ListMutex)
              rf=1
              
            ElseIf GadgetID = #Button_hd ;HDBAN
              AddElement(HDbans())
              HDbans()=*clickedClient\HD
              OpenFile(2,"base/HDbanlist.txt")
              FileSeek(2,Lof(2))
              WriteStringN(2,*clickedClient\HD)
              CloseFile(2)
              SendNetworkString(GetGadgetItemData(#Listview_0,GetGadgetState(#Listview_0)),"KB#"+Str(*clickedClient\CID)+"#%")
              Delay(10)
              If *clickedClient\CID>=0
                Characters(*clickedClient\CID)\taken=0
              EndIf
              CloseNetworkConnection(*clickedClient\ClientID)
              LockMutex(ListMutex)
              ResetMap(Clients())
              While NextMapElement(Clients())
                If Clients()\ClientID=*clickedClient\ClientID
                  DeleteMapElement(Clients())
                EndIf
              Wend     
              UnlockMutex(ListMutex)
              rf=1
              
            ElseIf GadgetID = #Button_dc ;DISCONNECT
              If *clickedClient\CID>=0
                Characters(*clickedClient\CID)\taken=0
              EndIf
              CloseNetworkConnection(*clickedClient\ClientID)
              LockMutex(ListMutex)
              ResetMap(Clients())
              While NextMapElement(Clients())
                If Clients()\ClientID=*clickedClient\ClientID
                  DeleteMapElement(Clients())
                EndIf
              Wend     
              UnlockMutex(ListMutex)
              rf=1        
              
            ElseIf GadgetID = #Button_ig ;IGNORE
              *clickedClient\ignore.b=1
              
            ElseIf GadgetID = #Button_si ; STOP IGNORING ME
              *clickedClient\ignore.b=0
              
            ElseIf GadgetID = #Button_ndj ;IGNORE
              *clickedClient\ignoremc.b=1
              
            ElseIf GadgetID = #Button_dj ; STOP IGNORING ME
              *clickedClient\ignoremc.b=0
              
            EndIf
            
          EndIf
          
          If GadgetID = #ListIcon_2
            ooclient=GetGadgetItemData(#ListIcon_2,GetGadgetState(#ListIcon_2))   
            If ooclient
              rf=1
              LockMutex(ListMutex)
              
              o=0
              ResetMap(Clients())
              While NextMapElement(Clients())
                If Clients()\ClientID = ooclient
                  SetGadgetState(#Listview_0,o)
                  Break
                EndIf
                o+1
              Wend    
              UnlockMutex(ListMutex)
            EndIf
            
          ElseIf GadgetID = #Listview_2
            CompilerIf #EASYLOG
              msclient=GetGadgetItemData(#Listview_2,GetGadgetState(#Listview_2))   
              If msclient
                rf=1
                LockMutex(ListMutex)
                
                b=0
                ResetMap(Clients())
                While NextMapElement(Clients())
                  If Clients()\ClientID = msclient  
                    SetGadgetState(#Listview_0,b)
                  EndIf
                  b+1
                Wend     
                UnlockMutex(ListMutex)
              EndIf
            CompilerEndIf
          ElseIf GadgetID = #CheckBox_MS
            public=GetGadgetState(#CheckBox_MS)
            Debug public
            If public
              msthread=CreateThread(@Masteradvert(),port)
            EndIf
            
          ElseIf GadgetID = #Button_2 ;START
            If nthread
              LoadSettings(1)
            Else
              If CreateNetworkServer(0, port,#PB_Network_TCP)
                SetWindowColor(0, RGB(0,128,0))
                SetGadgetText(#Button_2,"RELOAD")
                nthread=CreateThread(@Network(),0)
                If public And msthread=0
                  msthread=CreateThread(@Masteradvert(),port)
                EndIf       
              Else
                MessageRequester("serverD","SERVER CREATION FAILED - PORT IN USE?")
              EndIf
            EndIf
            
          ElseIf GadgetID = #Button_4 ;CONFIG
            CreateThread(@ConfigWindow(),0) 
            
          ElseIf GadgetID = #String_5 ;CONFIG
            port=Val(GetGadgetText(#String_5))
            
          ElseIf GadgetID = 1337
            MessageRequester("serverD","This is serverD version "+Str(#PB_Editor_CompileCount)+"."+Str(#PB_Editor_BuildCount)+Chr(10)+"(c) stonedDiscord 2014")
            
          EndIf
        ElseIf Event = #PB_Event_SizeWindow
          
          ResizeGadget(#Frame3D_0,0,0,WindowWidth(0)/2.517,WindowHeight(0))
          ResizeGadget(#ListView_0,70,40,WindowWidth(0)/2.517-70,WindowHeight(0)-40)
          ResizeGadget(#Button_2,WindowWidth(0)/6.08,15,WindowWidth(0)/8.111,22)
          ResizeGadget(#String_5,WindowWidth(0)/3.476,15,WindowWidth(0)/10.42,22)
          ResizeGadget(#Frame3D_4,WindowWidth(0)/2.517,0,WindowWidth(0)/3.173,WindowHeight(0))
          ResizeGadget(#Listview_2, WindowWidth(0)/1.7, 30, WindowWidth(0)-WindowWidth(0)/1.7, WindowHeight(0)-90)
          ResizeGadget(#Listview_2,WindowWidth(0)/2.517,20,WindowWidth(0)/3.173,WindowHeight(0)-20)
          ResizeGadget(#Frame3D_5,WindowWidth(0)/1.4,0,WindowWidth(0)/3.476,WindowHeight(0))
          ResizeGadget(#ListIcon_2,WindowWidth(0)/1.4,20,WindowWidth(0)/3.476,WindowHeight(0)-20)  
          
        EndIf
        
      Until Event = #PB_Event_CloseWindow ; End of the event loop
      
      Quit=1
      
      OpenPreferences("base/settings.ini")
      PreferenceGroup("net")
      WritePreferenceInteger("port",port)
      WritePreferenceInteger("public",public)
      ClosePreferences()
      
      End
      
      DataSection
        green:
        IncludeBinary "green.png"
        mod:
        IncludeBinary "mod.png"
        hacker:
        IncludeBinary "hacker.png"
        dend:
        IncludeBinary "serverd.png"
        bannerend:
      EndDataSection
      
    CompilerEndIf
; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 974
; FirstLine = 960
; Folding = ------------------------------------------
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0