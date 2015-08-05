;EnableExplicit
; yes this is the legit serverD source code please report bugfixes/modifications/feature requests to sD/trtukz on skype
CompilerIf #PB_Compiler_OS <> #PB_OS_Windows
  #MB_ICONERROR=0
CompilerEndIf
;- Defining Structure
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

#C1 = 53761
#C2 = 32618
Global version$="serverD v"+Str(#PB_Editor_CompileCount)+"."+Str(#PB_Editor_BuildCount)
Global CommandThreading=0
Global Logging.b=0
Global LagShield=1
Global public.b=0
Global LogFile$="poker.log"
Global decryptor$="33"
Global oppass$=""
Global killed=0
Global adminpass$=""
Global opppass$=""
Global key=2
Global Quit=0
Global defbar$="10"
Global probar$="10"
Global port=27016
Global scene$="AAOPublic2"
Global characternumber=0
Global oBG.s="gs4"
Global rt.b=1
Global loghd.b=0
Global background.s
Global PV=1
Global msname$="serverD"
Global desc$="Default "+version$
Global www$
Global rf.b=0
Global msip$="127.0.0.1"
Global Replays.b=0
Global rline=0
Global replayline=0
Global replayopen.b
Global modcol=0
Global blockini.b=0
Global MOTDevi=0
Global ExpertLog=0
Global tracks=0
Global msthread=0
Global LoginReply$="CT#$HOST#Successfully connected as mod#%"
Global musicpage=0
Global EviNumber=0
Global ChatMutex = CreateMutex()
Global ListMutex = CreateMutex()
Global MusicMutex = CreateMutex()
Global RefreshMutex = CreateMutex()
Global musicmode=1
Global update=0
Global Aareas=1
Global NewList HDbans.s()
Global NewList HDmods.s()
Global NewList IPbans.s()
Global NewList SDbans.s()
Global NewList gimps.s()
Global Dim Evidences.Evidence(100)
Global Dim Icons.l(2)
Global Dim ReadyChar.s(10)
Global Dim ReadyEvidence.s(100)
Global Dim ReadyMusic.s(500)

;- Initialize The Network
CompilerIf #PB_Compiler_Debugger=0
  OnErrorGoto(?start)
CompilerEndIf

If InitNetwork() = 0
  CompilerIf #CONSOLE=0
    MessageRequester("serverD", "Can't initialize the network!",#MB_ICONERROR)
  CompilerEndIf
  End
EndIf

;- Include files

CompilerIf #CONSOLE=0
  IncludeFile "Common.pb"
CompilerEndIf
IncludeFile "server_shared.pb"

;- Define Functions
; yes after the network init and include code
; many of these depend on that

Procedure MSWait(*usagePointer.Client)
  Define wttime
  Debug areas(*usagePointer\area)\wait
  Debug *usagePointer\area
  wttime=Len(Trim(StringField(*usagePointer\last,7,"#")))*60
  If wttime>5000
    wttime=5000
  EndIf
  Delay(wttime)
  areas(*usagePointer\area)\wait=0
EndProcedure

Procedure WriteReplay(string$)
  If Replays
    If ReplayOpen
      WriteStringN(3,string$) 
      WriteStringN(3,"wait")
      rline+1
      If rline>replayline
        CloseFile(3)
        ReplayOpen=0
      EndIf
    Else
      OpenFile(3,"base/replays/AAO replay "+FormatDate("%dd-%mm-%yy %hh-%ii-%ss",Date())+".txt",#PB_File_SharedRead | #PB_File_NoBuffering)
      WriteStringN(3,"decryptor#"+decryptor$+"#%")
      ReplayOpen=1
    EndIf
  EndIf
EndProcedure

;- Load Settings function
Procedure LoadSettings(reload)
  Define loadchars
  Define loadcharsettings
  Define loaddesc
  Define loadevi
  Define iniarea,charpage,page
  Define track$,hdmod$,hdban$,ipban$,ready$,area$
  WriteLog("Loading serverD "+version$+" settings",Server)
  
  If OpenPreferences("base/settings.ini")=0
    CreateDirectory("base")
    If CreatePreferences("base/settings.ini")=0
      WriteLog("couldn't create settings file(folder missing/permissions?)",Server)
    Else
      PreferenceGroup("Net")
      WritePreferenceInteger("public",0)
      WritePreferenceString("oppassword","1333333337") 
      WritePreferenceInteger("port",27016)
      PreferenceGroup("server")
      WritePreferenceString("Name", "DEFAULT")
      WritePreferenceString("Desc", "DEFAULT")
      WritePreferenceInteger("musicmode",1)
      WritePreferenceInteger("replaysave",0)
      WritePreferenceInteger("replayline",400)
      WritePreferenceString("case", "AAOPublic2")
    EndIf
  EndIf
  PreferenceGroup("net")
  opppass$=Encode(ReadPreferenceString("oppassword","1333333337"))
  port=ReadPreferenceInteger("port",27016)
  
  public=ReadPreferenceInteger("public",0)
  CompilerIf #CONSOLE=0
    SetGadgetText(#String_5,Str(port))
    SetGadgetState(#CheckBox_MS,public)
  CompilerElse
    PrintN("OP pass:"+opppass$)
    PrintN("Server port:"+Str(port))
    PrintN("Public server:"+Str(public))
  CompilerEndIf
  PreferenceGroup("server")
  musicmode=ReadPreferenceInteger("musicmode",1)
  Replays=ReadPreferenceInteger("replaysave",0)
  LagShield=ReadPreferenceInteger("LagShield",0)
  replayline=ReadPreferenceInteger("replayline",400)
  scene$=Encode(ReadPreferenceString("case","AAOPublic2"))
  msname$=Encode(ReadPreferenceString("Name","serverD"))
  desc$=Encode(ReadPreferenceString("Desc","Default serverD"))
  CompilerIf #CONSOLE=0
    SetWindowTitle(0,msname$)
  CompilerElse
    PrintN("Musicmode:"+Str(musicmode))
    PrintN("Scene:"+scene$)
  CompilerEndIf
  
  
  If OpenPreferences("poker.ini")=0
    If CreatePreferences("poker.ini")=0
      WriteLog("couldn't create settings file(folder missing/permissions?)",Server)
    Else
      PreferenceGroup("cfg")
      WritePreferenceString("oppass","")
      WritePreferenceString("adminpass","")
      WritePreferenceInteger("BlockIni",0)
      WritePreferenceInteger("modcol",0)
      WritePreferenceInteger("motdevi",0)
      WritePreferenceString("LoginReply","CT#sD#got it#%")
      WritePreferenceString("LogFile","base/serverlog.log")
    EndIf
  EndIf
  
  PreferenceGroup("cfg")
  oppass$=Encode(ReadPreferenceString("oppass",""))
  adminpass$=Encode(ReadPreferenceString("adminpass",""))
  blockini=ReadPreferenceInteger("BlockIni",0)
  modcol=ReadPreferenceInteger("modcol",0)
  MOTDevi=ReadPreferenceInteger("motdevi",0)
  LoginReply$=ReadPreferenceString("LoginReply","CT#$HOST#Successfully connected as mod#%")
  LogFile$=ReadPreferenceString("LogFile","base/serverlog.log")
  msip$=ReadPreferenceString("MSip","127.0.0.1")
  If Logging
    CloseFile(1)
  EndIf
  Logging=ReadPreferenceInteger("Logging",1)
  ClosePreferences()
  
  If Logging
    If OpenFile(1,LogFile$,#PB_File_SharedRead | #PB_File_NoBuffering)
      FileSeek(1,Lof(1))
      WriteLog("LOGGING STARTED",Server)
    Else
      Logging=0
    EndIf
  EndIf  
  
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
  oBG.s=Encode(ReadPreferenceString("BackGround","gs4"))
  For iniarea=0 To 100
    areas(iniarea)\bg=oBG.s
    areas(iniarea)\name=oBG.s
  Next
  PreferenceGroup("chars")
  Global characternumber=ReadPreferenceInteger("number",1)
  ReDim Characters.ACharacter(characternumber)
  For loadchars=0 To characternumber
    Characters(loadchars)\name=Encode(ReadPreferenceString(Str(loadchars),"zettaslow"))
    If reload=0
      Characters(loadchars)\taken=0
    EndIf
  Next
  PreferenceGroup("desc")
  For loaddesc=0 To characternumber
    Characters(loaddesc)\desc=Encode(ReadPreferenceString(Str(loadchars),"No description"))
  Next
  ReDim Evidences(EviNumber)
  ReDim ReadyEvidence(EviNumber)
  For loadevi=0 To EviNumber
    PreferenceGroup("evi"+Str(loadevi))
    Evidences(loadevi)\type=ReadPreferenceInteger("type",1)
    Evidences(loadevi)\name=Encode(ReadPreferenceString("name","DEFAULT"))
    Evidences(loadevi)\desc=Encode(ReadPreferenceString("desc","This is default evidence"))
    Evidences(loadevi)\image=Encode(ReadPreferenceString("image","2.png"))
    
    ReadyEvidence(loadevi)="EI#" + Str(loadevi)+"#"+Evidences(loadevi)\name+"&"+Evidences(loadevi)\desc+"&"+Str(Evidences(loadevi)\type)+"&"+Evidences(loadevi)\image+"&##%"
    
  Next
  ClosePreferences()
  
  ready$="CI#"
  charpage=0
  For loadcharsettings=0 To characternumber
    OpenPreferences("base/scene/"+scene$+"/char"+Str(loadcharsettings)+".ini")
    PreferenceGroup("desc")
    Characters(loadcharsettings)\desc=Encode(ReadPreferenceString("text","No description"))
    Characters(loadcharsettings)\dj=ReadPreferenceInteger("dj",musicmode)
    Characters(loadcharsettings)\evinumber=ReadPreferenceInteger("evinumber",0)
    Characters(loadcharsettings)\evidence=Encode(ReadPreferenceString("evi",""))
    Characters(loadcharsettings)\pw=Encode(ReadPreferenceString("pass",""))
    ClosePreferences()
    ready$ = ready$ + Str(loadcharsettings)+"#"+Characters(loadcharsettings)\name+"&"+Characters(loadcharsettings)\desc+"&"+Str(Characters(loadcharsettings)\evinumber)+"&"+Characters(loadcharsettings)\evidence+"&"+Characters(loadcharsettings)\pw+"&0&#"
    
    If loadcharsettings%10 = 9
      ReadyChar(charpage)=ready$+"#%"
      charpage+1
      ready$="CI#"
    EndIf    
  Next 
  
  If Not loadcharsettings%10 = 9
    ReadyChar(charpage)=ready$+"#%"
  EndIf
  
  If ReadFile(2, "base/musiclist.txt")
    tracks=0
    musicpage=0
    ready$="EM#"
    While Eof(2) = 0
      AddElement(Music())
      track$=ReadString(2) 
      trackn$=StringField(track$,1,"#")
      dur=Val(StringField(track$,2,"#"))
      track$ = ReplaceString(track$,"%","<percent>")
      Music()\TrackName = track$
      Music()\Length =dur
      ready$ = ready$ + Str(tracks) + "#" + track$ + "#"
      If tracks%10 = 9
        ReadyMusic(musicpage)=ready$+"#%"
        musicpage+1
        ReDim ReadyMusic(musicpage)
        ready$="EM#"
      EndIf
      track$=ReplaceString(track$,".mp3","")
      tracks+1
    Wend
    If Not (tracks-1)%10 = 9
      ReadyMusic(musicpage)=ready$+"#%"
    EndIf
    ReDim ReadyMusic(musicpage) 
    CloseFile(2)
    
  Else
    WriteLog("NO MUSIC LIST",Server)
    AddElement(Music())
    Music()\TrackName="NO MUSIC LIST"
    ReadyMusic(0)="EM#0#NO MUSIC LIST##%"
    musicpage=0
    tracks=1
  EndIf
  
  If ReadFile(2, "base/op.txt")
    ClearList(HDmods())
    While Eof(2) = 0
      hdmod$=ReadString(2)
      If hdmod$<>""
        AddElement(HDmods())
        HDmods()=hdmod$
      EndIf
    Wend
    CloseFile(2)
  Else
    If CreateFile(2, "base/op.txt")
      WriteStringN(2, "127.0.0.1")
      CloseFile(2)
    EndIf
  EndIf
  
  If ReadFile(2, "base/gimp.txt")
    ClearList(gimps())
    While Eof(2) = 0
      lgimp$=ReadString(2)
      If lgimp$<>""
        AddElement(gimps())
        gimps()=lgimp$
      EndIf
    Wend
    CloseFile(2)
  Else
    If CreateFile(2, "base/gimp.txt")
      WriteStringN(2, "<3")
      CloseFile(2)
    EndIf
  EndIf
  
  If OpenPreferences( "base/scene/"+scene$+"/areas.ini")
    PreferenceGroup("Areas")
    Aareas=ReadPreferenceInteger("number",1)
    For loadareas=0 To Aareas-1
      PreferenceGroup("Areas")
      aname$=Encode(ReadPreferenceString(Str(loadareas+1),oBG.s))
      areas(loadareas)\name=aname$
      PreferenceGroup("filename")
      area$=Encode(ReadPreferenceString(Str(loadareas+1),oBG.s))
      areas(loadareas)\bg=area$
    Next  
    ClosePreferences()
  Else
    If CreatePreferences("base/scene/"+scene$+"/areas.ini")
      PreferenceGroup("Areas")
      WritePreferenceInteger("number",1)
      WritePreferenceString("1",oBG.s)
      PreferenceGroup("filename")
      WritePreferenceString("1",oBG.s)
      areas(0)\bg=oBG.s
      Aareas=1
      ClosePreferences()
    EndIf
  EndIf
  
  If ReadFile(2, "serverd.txt")
    ReadString(2)
    ReadString(2)
    ReadString(2)
    ClearList(SDbans())
    While Eof(2) = 0
      hdban$=ReadString(2)
      If hdban$<>""
        AddElement(SDbans())
        SDbans()=hdban$
      EndIf
    Wend  
    CloseFile(2)
  EndIf
  
  If ReadFile(2, "base/HDbanlist.txt")
    ClearList(HDbans())
    While Eof(2) = 0
      hdban$=ReadString(2)
      If hdban$<>""
        AddElement(HDbans())
        HDbans()=hdban$
      EndIf
    Wend
    CloseFile(2)
  Else
    If CreateFile(2,"base/HDbanlist.txt")
      ForEach SDbans()
        WriteStringN(2,SDbans())
      Next
      CloseFile(2)
    EndIf
  EndIf
  
  If ReadFile(2, "base/banlist.txt")
    ClearList(IPbans())
    While Eof(2) = 0
      ipban$=ReadString(2)
      If ipban$<>""
        AddElement(IPbans())
        IPbans()=ipban$
      EndIf
    Wend
    CloseFile(2)
  EndIf
  
EndProcedure

Procedure SendTarget(user$,message$,*sender.Client)
  Define everybody,i
  omessage$=message$
  
  If user$="*"
    everybody=1
  Else
    everybody=0
  EndIf
  
  For i=0 To characternumber
    If Characters(i)\name=user$
      user$=Str(i)
      Break
    EndIf
  Next
  
  LockMutex(ListMutex)
  
  If FindMapElement(Clients(),user$)
    
    If Clients()\websocket
      CompilerIf #WEB
        Websocket_SendTextFrame(Clients()\ClientID,message$)
      CompilerEndIf
    Else
      SendNetworkString(Clients()\ClientID,message$)  
    EndIf
  Else
    ResetMap(Clients())
    While NextMapElement(Clients())
      If user$=Str(Clients()\CID) Or user$=Clients()\HD Or user$=Clients()\IP Or (everybody And (*sender\area=Clients()\area Or *sender\area=-1)) And Clients()\master=*sender\master
        If Clients()\websocket
          CompilerIf #WEB
            Websocket_SendTextFrame(Clients()\ClientID,message$)
          CompilerEndIf
        Else
          SendNetworkString(Clients()\ClientID,message$)  
        EndIf
      EndIf
    Wend   
  EndIf
  UnlockMutex(ListMutex)
EndProcedure

Procedure ListIP(ClientID)
  Define send.b
  Define iplist$
  Define charname$
  Define char
  send=0
  iplist$="IL#"
  LockMutex(ListMutex)  
  ResetMap(Clients())
  While NextMapElement(Clients())
    char=Clients()\CID
    If char<=100 And char>=0
      If char>characternumber      ; the character id is greater than the amount of characters
        charname$="HACKER"         ; OBVIUOSLY
        Clients()\hack=1
      Else
        Select Clients()\perm
          Case 1
            charname$=GetCharacterName(Clients())+"(mod)"
          Case 2
            charname$=GetCharacterName(Clients())+"(admin)"
          Case 3
            charname$=GetCharacterName(Clients())+"(server)"
          Default
            charname$=GetCharacterName(Clients())
        EndSelect
      EndIf
    Else
      charname$="nobody"
      
    EndIf
    iplist$=iplist$+Clients()\IP+"|"+charname$+"|"+Str(char)+"|*"
  Wend
  UnlockMutex(ListMutex)
  iplist$=iplist$+"#%"
  SendTarget(Str(ClientID),iplist$,Server) 
EndProcedure

Procedure KickBan(kick$,action,*usagePointer.Client)
  Define akck
  Define everybody.b
  Define i,kclid
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
    kclid=Clients()\ClientID
    kcid=Clients()\CID
    If kick$=Str(kcid) Or kick$=Str(kclid) Or kick$=Clients()\HD Or kick$=Clients()\IP Or everybody
      If Clients()\perm<*usagePointer\perm
        Select action
          Case #KICK
            If Clients()\CID>=0
              Characters(Clients()\CID)\taken=0
            EndIf
            DeleteMapElement(Clients())
            SendNetworkString(kclid,"KK#"+Str(kcid)+"#%")
            CloseNetworkConnection(kclid) 
            actionn$="kicked"
            akck+1
            
          Case #DISCO
            If Clients()\CID>=0
              Characters(Clients()\CID)\taken=0
            EndIf
            DeleteMapElement(Clients())
            CloseNetworkConnection(kclid) 
            actionn$="disconnected"
            akck+1
            
          Case #BAN
            If Clients()\IP<>"127.0.0.1"
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
              SendNetworkString(kclid,"KB#"+Str(kcid)+"#%")
              CloseNetworkConnection(kclid)  
              actionn$="banned"
              akck+1
            EndIf
            
          Case #MUTE
            SendNetworkString(Clients()\ClientID,"MU#"+Str(Clients()\CID)+"#%")
            actionn$="muted"
            akck+1
            
          Case #UNMUTE
            SendNetworkString(Clients()\ClientID,"UM#"+Str(Clients()\CID)+"#%")
            actionn$="unmuted"
            akck+1
            
          Case #CIGNORE
            Clients()\ignore=1
            actionn$="ignored"
            akck+1
            
          Case #UNIGNORE
            Clients()\ignore=0
            actionn$="undignored"
            akck+1
            
          Case #UNDJ
            Clients()\ignoremc=1
            actionn$="undj'd"
            akck+1
            
          Case #DJ
            Clients()\ignoremc=0
            actionn$="dj'd"
            akck+1
            
          Case #GIMP
            Clients()\gimp=1
            actionn$="gimped"
            akck+1
            
          Case #UNGIMP
            Clients()\gimp=0
            actionn$="ungimped"
            akck+1
            
        EndSelect
      EndIf
    EndIf
  Wend    
  UnlockMutex(ListMutex)
  WriteLog("["+GetCharacterName(*usagePointer)+"] "+actionn$+" "+kick$+", "+Str(akck)+" people died.",*usagePointer)
  rf=1
  ProcedureReturn akck
EndProcedure

ProcedureDLL.s HexToString(hex.s)
  Define str.s="",i
  For i = 1 To Len(hex.s) Step 2
    str.s = str.s + Chr(Val("$"+Mid(hex.s, i, 2)))
  Next i
  ProcedureReturn str.s
EndProcedure

ProcedureDLL.s StringToHex(str.s)
  Define StringToHexR.s = ""
  Define hexchar.s = ""
  Define x
  For x = 1 To Len(str)
    hexchar.s = Hex(Asc(Mid(str, x, 1)))
    If Len(hexchar) = 1
      hexchar = "0" + hexchar
    EndIf
    StringToHexR.s = StringToHexR + hexchar
  Next x
  ProcedureReturn StringToHexR.s
EndProcedure

Procedure.s EncryptStr(S.s, Key.u)
  Define Result.s = S.s
  Define I
  Define *S.CharacterArray = @S
  Define *Result.CharacterArray = @Result
  
  For I = 0 To Len(S.s)-1
    *Result\c[I] = (*S\c[I] ! (Key >> 8))
    Key = ((*Result\c[I] + Key) * #C1) + #C2
  Next
  
  ProcedureReturn Result.s
EndProcedure

ProcedureDLL.s DecryptStr(S.s, Key.u)
  Define Result.s = S.s
  Define I
  Define *S.CharacterArray = @S
  Define *Result.CharacterArray = @Result
  
  For I = 0 To Len(S.s)-1
    *Result\c[I] = (*S\c[I] ! (Key >> 8))
    Key = ((*S\c[I] + Key) * #C1) + #C2
  Next
  
  ProcedureReturn Result.s
EndProcedure

ProcedureDLL MasterAdvert(port)
  Define msID=0,msinfo,NEvent,msport=27016,retries
  Define sr=-1
  Define  *null=AllocateMemory(100)
  Define master$,msrec$
  WriteLog("Masterserver adverter thread started",Server)
  OpenPreferences("base/masterserver.ini")
  PreferenceGroup("list")
  master$=ReadPreferenceString("0","54.93.210.149")
  msport=27016
  ClosePreferences()
  
  WriteLog("Using master "+master$, Server)
  
  If public
    Repeat
      
      If msID And sr
        NEvent=NetworkClientEvent(msID)
        If NEvent=#PB_NetworkEvent_Disconnect
          sr=-1
          msID=0
        ElseIf NEvent=#PB_NetworkEvent_Data
          msinfo=ReceiveNetworkData(msID,*null,100)
          If msinfo=-1
            sr=-1
          Else
            tick=0
            retries=0
          EndIf
        EndIf
        
      Else
        retries+1
        WriteLog("Masterserver adverter thread connecting...",Server)
        msID=OpenNetworkConnection(master$,msport)
        If msID
          Server\ClientID=msID
          sr=SendNetworkString(msID,"SCC#"+Str(port)+"#"+msname$+"#"+desc$+"#"+version$+"#%"+Chr(0))
          WriteLog("Server published!",Server)
        EndIf
      EndIf
      If tick>10
        sr=0
        Server\ClientID=0
        msID=0
      ElseIf tick>2
        sr=SendNetworkString(msID,"PING#%")
        EndIf
      Delay(30000)
    Until public=0
  EndIf
  WriteLog("Masterserver adverter thread stopped",Server)
  If msID
    CloseNetworkConnection(msID)
  EndIf
  FreeMemory(*null)
  msthread=0
EndProcedure


Procedure SendDone(ClientID)
  Define send$
  Define sentchar
  Dim APlayers(Aareas-1)
  send$="CharsCheck"
  For sentchar=0 To characternumber
    If Characters(sentchar)\taken Or  Characters(sentchar)\pw<>""
      send$ = send$ + "#-1"
    Else
      send$ = send$ + "#0"
    EndIf
  Next
  send$ = send$ + "#%"
  SendTarget(Str(ClientID),send$,Server)
  SendTarget(Str(ClientID),"BN#"+areas(0)\bg+"#%",Server)
  SendTarget(Str(ClientID),"OPPASS#"+StringToHex(EncryptStr(opppass$,key))+"#%",Server)
  SendTarget(Str(ClientID),"MM#"+Str(musicmode)+"#%",Server)
  Delay(10)
  SendTarget(Str(ClientID),"DONE#%",Server)
EndProcedure


;- Command Handler

Procedure HandleAOCommand(*usagePointer.Client)
  StartProfiler()
  Define rawreceive$
  Define comm$
  Define length
  Define ClientID
  Define msreply$
  Define i
  Define mss$
  Define send
  Define music
  Define ctparam$
  Define bgcomm$
  Define narea
  Define lock$
  Define pr$
  Define reply$
  Define dicemax
  Define random$
  Define smes$
  Define sname$
  Define mcid$
  Define song$
  
  rawreceive$=*usagePointer\last
  If Left(rawreceive$,1)="#"
    comm$=DecryptStr(HexToString(StringField(rawreceive$,2,"#")),key)
    length=Len(rawreceive$)
    ClientID=*usagePointer\ClientID
    Select comm$
      Case "CH"
        
      Case "MS"
        WriteLog("["+GetCharacterName(*usagePointer)+"]["+StringField(rawreceive$,7,"#")+"]",*usagePointer)
        Debug areas(*usagePointer\area)\wait
        If areas(*usagePointer\area)\wait=0 Or *usagePointer\perm
          msreply$="MS#"
          For i=3 To 17
            mss$=StringField(rawreceive$,i,"#")
            If i=17 And mss$=Str(modcol) And Not *usagePointer\perm
              msreply$=msreply$+"0#"
            ElseIf i=3
              If mss$="event"
                *usagePointer\hack=1
                msreply$=""
                rf=1
                Break
              Else
                msreply$=msreply$+"chat#"
              EndIf
            ElseIf i=5 And blockini And mss$<>GetCharacterName(*usagePointer)
              msreply$=msreply$+GetCharacterName(*usagePointer)+"#"
            ElseIf i=7 And *usagePointer\gimp
              If SelectElement(gimps(),Random(ListSize(gimps())-1,0))
                msreply$=msreply$+gimps()+"#"
              Else
                msreply$=msreply$+"gimp.txt is empty lol"+"#"
              EndIf
              SendTarget(Str(ClientID),"MS#"+Mid(rawreceive$,7),*usagePointer)
            Else
              msreply$=msreply$+mss$+"#"
            EndIf
          Next
          msreply$=msreply$+"%"        
          areas(*usagePointer\area)\wait=*usagePointer\ClientID
          CreateThread(@MSWait(),*usagePointer)
          Sendtarget("*",msreply$,*usagePointer)
          WriteReplay(rawreceive$)
        EndIf
        send=0
        
      Case "MC"
        music=0
        LockMutex(musicmutex)
        ForEach Music()
          If StringField(rawreceive$,3,"#")=Music()\TrackName
            music=1
            Break
          EndIf
        Next
        UnlockMutex(musicmutex)
        If Not (music=0 Or *usagePointer\CID <> Val(StringField(rawreceive$,4,"#")))
          If Left(StringField(rawreceive$,3,"#"),1)=">"
            
            narea=0
            Debug Mid(StringField(rawreceive$,3,"#"),2)
            For ir=0 To Aareas-1
              Debug areas(ir)\name
              If areas(ir)\name = Mid(StringField(rawreceive$,3,"#"),2)
                narea = ir
                Debug "found it"
                Break
              EndIf
            Next
            If narea<=Aareas-1 And narea>=0
              If Not areas(narea)\lock Or *usagePointer\perm>areas(narea)\mlock
                If areas(*usagePointer\area)\lock=ClientID
                  areas(*usagePointer\area)\lock=0
                  areas(*usagePointer\area)\mlock=0
                EndIf
                *usagePointer\area=narea
                Debug "RAW room changed"
                SendTarget(Str(ClientID),"BN#"+areas(*usagePointer\area)\bg+"#%",Server)
                SendTarget(Str(ClientID),"FI#area "+Str(*usagePointer\area)+" selected%",Server)
              Else
                SendTarget(Str(ClientID),"FI#area locked%",Server)
              EndIf
            Else
              SendTarget(Str(ClientID),"FI#Not a valid area%",Server)
            EndIf
            
          Else
            If *usagePointer\ignoremc=0
              If Characters(*usagePointer\CID)\dj
                Sendtarget("*","MC#"+Right(rawreceive$,length-6),*usagePointer)
                WriteReplay(rawreceive$)
              EndIf
            EndIf
          EndIf
          WriteLog("["+GetCharacterName(*usagePointer)+"] changed music to "+StringField(rawreceive$,3,"#"),*usagePointer)
        Else
          *usagePointer\hack=1
          rf=1
          WriteLog("["+GetCharacterName(*usagePointer)+"] tried changing music to "+StringField(rawreceive$,3,"#"),*usagePointer)
        EndIf 
        ;- ooc commands
      Case "CT"
        send=0
        *usagePointer\last.s=""
        ctparam$=StringField(rawreceive$,4,"#")
        If *usagePointer\CID>=0
          WriteLog("[OOC]["+GetCharacterName(*usagePointer)+"]["+StringField(rawreceive$,3,"#")+"]["+ctparam$+"]",*usagePointer)
          
          If *usagePointer\username=""
            *usagePointer\username=StringField(rawreceive$,3,"#")
          EndIf
          
          Debug ctparam$
          If Left(ctparam$,1)="/"
            Select StringField(ctparam$,1," ")
              Case "/login"
                Debug Mid(ctparam$,8)
                Select Mid(ctparam$,8)
                  Case oppass$
                    If oppass$<>""
                      SendTarget(Str(ClientID),LoginReply$,Server) 
                      *usagePointer\perm=1
                      *usagePointer\ooct=1
                      rf=1
                    EndIf
                  Case adminpass$
                    If adminpass$<>""
                      SendTarget(Str(ClientID),LoginReply$,Server) 
                      SendTarget(Str(ClientID),"UM#"+Str(*usagePointer\CID)+"#%",Server)
                      *usagePointer\perm=2
                      *usagePointer\ooct=1
                      rf=1
                    EndIf
                EndSelect
                send=0
                
              Case "/ip"
                If *usagePointer\perm
                  If CommandThreading
                    CreateThread(@ListIP(),ClientID)
                  Else
                    ListIP(ClientID)
                  EndIf
                  WriteLog("["+GetCharacterName(*usagePointer)+"] used /ip",*usagePointer)
                EndIf 
                
              Case "/bg"
                If *usagePointer\perm                            
                  bgcomm$=Mid(ctparam$,5)
                  areas(*usagePointer\area)\bg=bgcomm$
                  Sendtarget("*","BN#"+bgcomm$+"#%",*usagePointer)                      
                EndIf
                
              Case "/switch"
                If *usagePointer\cid>=0
                  Characters(*usagePointer\cid)\taken=0
                EndIf
                *usagePointer\cid=-1                    
                SendTarget(Str(ClientID),"DONE#%",Server)
                
              Case "/ooc"
                If *usagePointer\perm
                  *usagePointer\ooct=1
                EndIf
                
              Case "/area"  
                narea=Val(StringField(ctparam$,2," "))
                
                If narea=0
                  narea=0
                  For ir=0 To Aareas-1
                    If areas(ir)\bg = StringField(ctparam$,2," ")
                      narea = ir
                      Debug "found it"
                      Break
                    EndIf
                  Next
                EndIf
                
                If narea<=Aareas-1 And narea>=0
                  If Not areas(narea)\lock Or *usagePointer\perm>areas(narea)\mlock
                    If areas(*usagePointer\area)\lock=ClientID
                      areas(*usagePointer\area)\lock=0
                      areas(*usagePointer\area)\mlock=0
                    EndIf
                    *usagePointer\area=narea
                    SendTarget(Str(ClientID),"BN#"+areas(*usagePointer\area)\bg+"#%",Server)
                    SendTarget(Str(ClientID),"FI#area "+Str(*usagePointer\area)+" selected%",Server)
                  Else
                    SendTarget(Str(ClientID),"FI#area locked%",Server)
                  EndIf
                ElseIf StringField(ctparam$,2," ")=""
                  SendTarget(Str(ClientID),"FI#You are in area "+*usagePointer\area+"%",Server)
                Else
                  SendTarget(Str(ClientID),"FI#Not a valid area%",Server)
                EndIf
                
              Case "/lock"
                If *usagePointer\area
                  lock$=StringField(ctparam$,2," ")
                  Select lock$
                    Case "0"
                      areas(*usagePointer\area)\lock=0
                      areas(*usagePointer\area)\mlock=0
                      SendTarget(Str(ClientID),"FI#area unlocked%",Server)
                    Case "1"
                      areas(*usagePointer\area)\lock=*usagePointer\ClientID
                      areas(*usagePointer\area)\mlock=0
                      SendTarget(Str(ClientID),"FI#area locked%",Server)
                    Case "2"
                      If *usagePointer\perm
                        areas(*usagePointer\area)\lock=*usagePointer\ClientID
                        areas(*usagePointer\area)\mlock=1
                        SendTarget(Str(ClientID),"FI#area superlocked%",Server)
                      EndIf
                    Default
                      pr$="FI#area is "
                      If areas(*usagePointer\area)\lock=0
                        pr$+"not "
                      EndIf
                      SendTarget(Str(ClientID),pr$+"locked%",Server)
                  EndSelect
                Else
                  SendTarget(Str(ClientID),"FI#You can't lock the default area%",Server)
                EndIf
                
              Case "/nooc"
                *usagePointer\ooct=0
                
              Case "/judge"
                If *usagePointer\perm
                  *usagePointer\judget=1
                EndIf
                
              Case "/nojudge"
                If *usagePointer\perm
                  *usagePointer\judget=0
                EndIf
                
              Case "/toggle"
                If *usagePointer\perm
                  Select StringField(ctparam$,2," ")
                    Case "WTCE"
                      If rt
                        rt=0
                      Else
                        rt=1
                      EndIf
                      pr$="FI#WTCE is "
                      If rt=1
                        pr$+"enabled%"
                      Else
                        pr$+"disabled%"
                      EndIf
                      SendTarget(Str(ClientID),pr$,Server)
                    Case "LogHD"
                      If loghd
                        loghd=0
                      Else
                        loghd=1
                      EndIf
                    Case "ExpertLog"
                      If ExpertLog
                        ExpertLog=0
                      Else
                        ExpertLog=1
                      EndIf
                    Case "Threading"
                      If CommandThreading
                        CommandThreading=0
                      Else
                        CommandThreading=1
                      EndIf
                  EndSelect
                EndIf
                
              Case "/snapshot"
                If *usagePointer\perm>1
                  
                EndIf
                
              Case "/smokeweed"
                reply$="CT#stonedDiscord#where da weed at#%"
                WriteLog("smoke weed everyday",*usagePointer)
                
              Case "/help"
                SendTarget(Str(ClientID),"CT#SERVER#Check http://weedlan.de/serverd/#%",Server)
                
              Case "/public"
                Debug ctparam$
                If StringField(ctparam$,2," ")=""
                  pr$="FI#server is "
                  If public=0
                    pr$+"not "
                  EndIf
                  SendTarget(Str(ClientID),pr$+"public%",Server)
                Else
                  If *usagePointer\perm>1
                    public=Val(StringField(ctparam$,2," "))
                    If public
                      msthread=CreateThread(@MasterAdvert(),port)
                    EndIf
                    CompilerIf #CONSOLE=0
                      SetGadgetState(#CheckBox_MS,public)
                    CompilerEndIf
                  EndIf
                EndIf
                
              Case "/evi"                      
                SendTarget(Str(ClientID),"MS#chat#dolannormal#Dolan#dolannormal#"+StringField(ctparam$,2," ")+"#jud#1#0#"+Str(characternumber-1)+"#0#0#"+StringField(ctparam$,2," ")+"#"+Str(characternumber-1)+"#0#"+Str(modcol)+"#%",Server)                         
                
              Case "/roll"                        
                If ctparam$<>"/roll"
                  dicemax=Val(StringField(ctparam$,2," "))
                Else
                  dicemax=6
                EndIf
                If dicemax<=0 Or dicemax>9999
                  dicemax=6
                EndIf
                If OpenCryptRandom()
                  random$=Str(CryptRandom(dicemax))
                  CloseCryptRandom()
                Else
                  random$=Str(Random(dicemax))
                EndIf              
                Sendtarget("*","FI#dice rolled "+random$+"%",Server)
                
              Case "/pm"                    
                sname$=StringField(rawreceive$,3,"#")
                Debug sname$
                SendTarget(StringField(ctparam$,2," "),"CT#PM "+sname$+" to You#"+Mid(ctparam$,6+Len(StringField(ctparam$,2," ")))+"#%",Server)
                SendTarget(Str(ClientID),"CT#PM You to "+StringField(ctparam$,2," ")+"#"+Mid(ctparam$,6+Len(StringField(ctparam$,2," ")))+"#%",Server)
                
              Case "/send"  
                If *usagePointer\perm
                  sname$=StringField(ctparam$,2," ")
                  Debug sname$
                  smes$=Mid(ctparam$,8+Len(sname$),Len(ctparam$)-6)
                  smes$=Escape(smes$)
                  SendTarget(sname$,smes$,Server)
                EndIf
                
              Case "/sendall"
                If *usagePointer\perm
                  reply$=Mid(ctparam$,10)
                  reply$=Escape(reply$)
                EndIf
                
              Case "/reload"
                If *usagePointer\perm>1
                  LoadSettings(1)
                  SendTarget(Str(ClientID),"FI#serverD reloaded%",Server)
                EndIf
                
              Case "/play"
                If *usagePointer\perm                
                  song$=Right(ctparam$,Len(ctparam$)-6)                
                  SendTarget("*","MC#"+song$+"#"+Str(*usagePointer\CID)+"#%",*usagePointer)                
                EndIf
                
              Case "/hd"
                If *usagePointer\perm
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
                  SendTarget(Str(ClientID),hdlist$+"#%",Server)
                  WriteLog("["+GetCharacterName(*usagePointer)+"] used /hd",*usagePointer)
                EndIf 
                
                
              Case "/unban"
                If *usagePointer\perm>1
                  ub$=Mid(ctparam$,8,Len(ctparam$))
                  Debug ub$
                  If CreateFile(2,"base/banlist.txt")
                    Debug "file recreated"
                    ForEach IPbans()
                      If IPbans()=ub$
                        DeleteElement(IPbans())
                      Else
                        WriteStringN(2,IPbans())
                      EndIf
                    Next
                    CloseFile(2)                                
                  EndIf
                  
                  If CreateFile(2,"base/HDbanlist.txt")
                    ForEach HDbans()
                      If HDbans()=ub$
                        DeleteElement(HDbans())
                      Else
                        WriteStringN(2,HDbans())
                      EndIf
                    Next
                    CloseFile(2)                                
                  EndIf
                EndIf
                
              Case "/stop"
                If *usagePointer\perm>1
                  Quit=1
                  public=0
                EndIf
                
              Case "/kick"
                If *usagePointer\perm
                  akck=KickBan(Mid(ctparam$,7),#KICK,*usagePointer)
                  SendTarget(Str(ClientID),"FI#kicked "+Str(akck)+" clients%",Server)
                  
                  
                EndIf
              Case "/ban"
                If *usagePointer\perm
                  akck=KickBan(Mid(ctparam$,6),#BAN,*usagePointer)
                  SendTarget(Str(ClientID),"FI#banned "+Str(akck)+" clients%",Server)
                EndIf
                
                
              Case "/mute"
                If *usagePointer\perm
                  akck=KickBan(Mid(ctparam$,7),#MUTE,*usagePointer)
                  SendTarget(Str(ClientID),"FI#muted "+Str(akck)+" clients%",Server)
                EndIf
                
                
              Case "/unmute"
                If *usagePointer\perm
                  akck=KickBan(Mid(ctparam$,9),#UNMUTE,*usagePointer)
                  SendTarget(Str(ClientID),"FI#unmuted "+Str(akck)+" clients%",Server)
                EndIf
                
                
              Case "/ignore"
                If *usagePointer\perm
                  akck=KickBan(Mid(ctparam$,9),#CIGNORE,*usagePointer)
                  SendTarget(Str(ClientID),"FI#muted "+Str(akck)+" clients%",Server)
                EndIf
                
                
              Case "/unignore"
                If *usagePointer\perm
                  akck=KickBan(Mid(ctparam$,11),#UNIGNORE,*usagePointer)
                  SendTarget(Str(ClientID),"FI#unmuted "+Str(akck)+" clients%",Server)
                EndIf
                
                
              Case "/undj"
                If *usagePointer\perm
                  akck=KickBan(Mid(ctparam$,7),#UNDJ,*usagePointer)
                  SendTarget(Str(ClientID),"FI#muted "+Str(akck)+" clients%",Server)
                EndIf
                
                
              Case "/dj"
                If *usagePointer\perm
                  akck=KickBan(Mid(ctparam$,5),#DJ,*usagePointer)
                  SendTarget(Str(ClientID),"FI#unmuted "+Str(akck)+" clients%",Server)
                EndIf
                
              Case "/gimp"
                If *usagePointer\perm
                  akck=KickBan(Mid(ctparam$,7),#GIMP,*usagePointer)
                  SendNetworkString(ClientID,"FI#gimped "+Str(akck)+" clients%")
                EndIf
                
              Case "/ungimp"
                If *usagePointer\perm
                  akck=KickBan(Mid(ctparam$,9),#UNGIMP,*usagePointer)
                  SendNetworkString(ClientID,"FI#ungimped "+Str(akck)+" clients%")
                EndIf
                
              Case "/version"
                SendTarget(Str(ClientID),"CT#$HOST#"+version$+"#%",Server)
                
            EndSelect
          Else
            *usagePointer\last.s=rawreceive$
            SendTarget("*","CT#"+*usagePointer\username+"#"+StringField(rawreceive$,4,"#")+"#%",*usagePointer)
            CompilerIf #CONSOLE=0
              AddGadgetItem(#ListIcon_2,-1,StringField(rawreceive$,3,"#")+Chr(10)+StringField(rawreceive$,4,"#"))
              SetGadgetItemData(#ListIcon_2,CountGadgetItems(#ListIcon_2)-1,*usagePointer\ClientID)
            CompilerEndIf
          EndIf
        Else
          WriteLog("[OOC][HACKER]["+StringField(rawreceive$,3,"#")+"]["+ctparam$+"]",*usagePointer)
          *usagePointer\hack=1
          rf=1
        EndIf
        
      Case "HP" 
        bar=Val(StringField(rawreceive$,4,"#"))
        If *usagePointer\CID>=0
          If bar>=0 And bar<=10
            WriteLog("["+GetCharacterName(*usagePointer)+"] changed the bars",*usagePointer)
            If StringField(rawreceive$,3,"#")="1"
              defbar$=Str(bar)
              reply$="HP#1#"+defbar$+"#%"
            ElseIf StringField(rawreceive$,3,"#")="2"
              probar$=Str(bar)
              reply$="HP#2#"+probar$+"#%"
            EndIf
            send=1
          EndIf
        Else
          WriteLog("["+GetCharacterName(*usagePointer)+"] fucked up the bars",*usagePointer)
          *usagePointer\hack=1
          rf=1
        EndIf
        
      Case "RT"
        If *usagePointer\CID>=0
          If rt=1
            Sendtarget("*","RT#"+Right(rawreceive$,length-6),*usagePointer)
          EndIf
        Else
          *usagePointer\hack=1
          rf=1
        EndIf
        WriteLog("["+GetCharacterName(*usagePointer)+"] WT/CE button",*usagePointer)
        
      Case "AN" ; character list
        start=Val(StringField(rawreceive$,3,"#"))
        If start*10<characternumber And start>=0
          SendTarget(Str(ClientID),ReadyChar(start),Server)
        ElseIf EviNumber>0
          SendTarget(Str(ClientID),ReadyEvidence(1),Server)
        ElseIf tracks>0
          SendTarget(Str(ClientID),ReadyMusic(0),Server)
        Else ;MUSIC DONE
          SendDone(ClientID)
        EndIf
        
        
      Case "AE" ; evidence list
        Debug Evidences(0)\name
        sentevi=Val(StringField(rawreceive$,3,"#"))
        send=0
        If sentevi<EviNumber And sentevi>=0          
          SendTarget(Str(ClientID),ReadyEvidence(sentevi+1),Server)
        ElseIf tracks>0
          SendTarget(Str(ClientID),ReadyMusic(0),Server)
        Else ;MUSIC DONE
          SendDone(ClientID)
        EndIf
        
      Case "AM" ;music list
        start=Val(StringField(rawreceive$,3,"#"))
        send=0
        If start<=musicpage And start>=0 
          SendTarget(Str(ClientID),ReadyMusic(start),Server)
        Else ;MUSIC DONE
          SendDone(ClientID)
        EndIf
        
      Case "HI" ;what is this server
        hdbanned=0
        *usagePointer\HD = StringField(rawreceive$,3,"#")
        WriteLog("HdId="+*usagePointer\HD,*usagePointer)
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
            SendTarget(Str(ClientID),"BD#%",Server)
            LockMutex(ListMutex)
            CloseNetworkConnection(ClientID)
            DeleteMapElement(Clients(),Str(ClientID))
            UnlockMutex(ListMutex)
            hdbanned=1
            
            rf=1
          EndIf
        Next
        If hdbanned=0
          ForEach HDbans()
            If *usagePointer\HD = HDbans()
              send=0
              WriteLog("HdId: "+*usagePointer\HD+" is banned, disconnecting",*usagePointer)
              SendTarget(Str(ClientID),"BD#%",Server)
              LockMutex(ListMutex)
              CloseNetworkConnection(ClientID)
              DeleteMapElement(Clients(),Str(ClientID))
              UnlockMutex(ListMutex)
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
              rf=1
            EndIf
          Next
          SendTarget(Str(ClientID),"ID#"+Str(*usagePointer\AID)+"#"+version$+"#%",Server)
          players=0
          
          LockMutex(ListMutex)    
          ResetMap(Clients())
          While NextMapElement(Clients())
            If Clients()\CID>=0
              players+1
            EndIf
          Wend
          UnlockMutex(ListMutex)                      
          
          SendTarget(Str(ClientID),"PN#"+Str(players)+"#"+Str(characternumber)+"#%",Server)
        EndIf
        
      Case "askchaa" ;what is left to load
        *usagePointer\cconnect=1
        SendTarget(Str(ClientID),"SI#"+Str(characternumber)+"#"+Str(EviNumber)+"#"+Str(tracks)+"#%",Server)
        send=0
        
      Case "askchar2" ; character list
        SendTarget(Str(ClientID),ReadyChar(0),Server)
        
      Case "CC"
        send=0
        Debug rawreceive$
        char=Val(StringField(rawreceive$,4,"#"))
        If char>=0 And char<=characternumber
          If Characters(char)\taken=0 Or *usagePointer\CID=char
            SendTarget(Str(ClientID),"PV#"+Str(*usagePointer\AID)+"#CID#"+Str(char)+"#%",Server)
            If *usagePointer\CID>=0 And *usagePointer\CID<=characternumber
              Characters(*usagePointer\CID)\taken=0
            EndIf                  
            *usagePointer\CID=char
            Characters(char)\taken=1                  
            WriteLog("chose character: "+GetCharacterName(*usagePointer),*usagePointer)
            SendTarget(Str(ClientID),"HP#1#"+defbar$+"#%",Server)
            SendTarget(Str(ClientID),"HP#2#"+probar$+"#%",Server)
            If MOTDevi
              SendTarget(Str(ClientID),"MS#chat#normal#Discord#normal#Take that!#jud#1#2#"+Str(characternumber-1)+"#0#3#"+Str(MOTDevi)+"#"+Str(characternumber-1)+"#0#"+Str(modcol)+"#%",Server)
            EndIf
          EndIf 
          rf=1
        EndIf
        
      Case "DC"
        If *usagePointer\CID>=0 And *usagePointer\CID <= characternumber
          Characters(*usagePointer\CID)\taken=0
        EndIf
        If areas(*usagePointer\area)\lock=ClientID
          areas(*usagePointer\area)\lock=0
          areas(*usagePointer\area)\mlock=0
        EndIf
        
      Case "CA"
        If *usagePointer\perm
          If CommandThreading
            CreateThread(@ListIP(),ClientID)
          Else
            ListIP(ClientID)
          EndIf
          WriteLog("["+GetCharacterName(*usagePointer)+"] used /ip",*usagePointer)
        EndIf 
        
      Case "opKICK"
        If *usagePointer\perm
          akck=KickBan(StringField(rawreceive$,3,"#"),#KICK,*usagePointer)
          SendTarget(Str(ClientID),"FI#kicked "+Str(akck)+" clients%",Server)
        EndIf
        WriteLog("["+GetCharacterName(*usagePointer)+"] used opKICK",*usagePointer)
        
      Case "opBAN"
        If *usagePointer\perm
          akck=KickBan(StringField(rawreceive$,3,"#"),#BAN,*usagePointer)
          SendTarget(Str(ClientID),"FI#banned "+Str(akck)+" clients%",Server)
        EndIf
        WriteLog("["+GetCharacterName(*usagePointer)+"] used opBAN",*usagePointer)
        
      Case "opMUTE"
        If *usagePointer\perm
          akck=KickBan(StringField(rawreceive$,3,"#"),#MUTE,*usagePointer)
          SendTarget(Str(ClientID),"FI#muted "+Str(akck)+" clients%",Server)
        EndIf
        WriteLog("["+GetCharacterName(*usagePointer)+"] used opMUTE",*usagePointer)
        
      Case "opunMUTE"
        If *usagePointer\perm
          akck=KickBan(StringField(rawreceive$,3,"#"),#UNMUTE,*usagePointer)
          SendTarget(Str(ClientID),"FI#unmuted "+Str(akck)+" clients%",Server)
        EndIf
        WriteLog("["+GetCharacterName(*usagePointer)+"] used opunMUTE",*usagePointer)
        
      Case "VERSION"
        SendTarget(Str(ClientID),"FI#"+version$+"%",Server)
        
      Case "ZZ"
        If *usagePointer\CID>=0
          WriteLog("["+GetCharacterName(*usagePointer)+"] called mod",*usagePointer)
        Else
          WriteLog("[HACKER] called mod",*usagePointer)
        EndIf
        LockMutex(ListMutex)  
        ResetMap(Clients())
        While NextMapElement(Clients())
          If Clients()\perm
            SendNetworkString(Clients()\ClientID,"ZZ#"+*usagePointer\IP+"#%")  
          Else
            SendNetworkString(Clients()\ClientID,"ZZ#someone#%")  
          EndIf
        Wend   
        UnlockMutex(ListMutex)
        
      Default
        WriteLog(rawreceive$,*usagePointer)
    EndSelect
    
    If reply$<>""
      areply$=reply$
      Debug "why does this not work"
      Sendtarget("*",areply$,*usagePointer)
      reply$=""
    EndIf
    ;   Else
    ;     Debug "ahoi"
    ;     Select StringField(rawreceive$,1,"#")
    ;       Case "askforservers"
    ;         Debug "sendin"
    ;         SendTarget(Str(ClientID),"SN#"+msip$+"#"+Str(port)+"#"+msname$+"#"+desc$+"#%",Server)
    ;     EndSelect
  EndIf
  StopProfiler()
EndProcedure

CompilerIf #CONSOLE=0
  Procedure RefreshList(var)
    If TryLockMutex(RefreshMutex)
      lstate=GetGadgetState(#Listview_0)
      ClearGadgetItems(#Listview_0)
      i=0
      LockMutex(ListMutex)    
      ResetMap(Clients())
      While NextMapElement(Clients())
        listicon=ImageID(0)
        If Clients()\perm
          listicon=ImageID(1)
        EndIf
        If Clients()\hack
          listicon=ImageID(2)
        EndIf
        AddGadgetItem(#Listview_0,i,Clients()\IP+Chr(10)+GetCharacterName(Clients())+Chr(10)+Str(Clients()\CID),listicon)
        SetGadgetItemData(#Listview_0,i,Clients()\ClientID)
        i+1
      Wend
      UnlockMutex(ListMutex)
      If lstate<CountGadgetItems(#Listview_0)
        SetGadgetState(#Listview_0,lstate)
      EndIf
      UnlockMutex(RefreshMutex)
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
    SetGadgetText(#String_AD,adminpass$)
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
      WindowID = EventWindow()  ; The Window where the event is generated, can be used in the gadget procedures
      GadgetID = EventGadget()  ; Is it a gadget event?
      EventType = EventType()   ; The event type
      If Event = #PB_Event_Gadget
        If GadgetID = #String_OP
          oppass$ = GetGadgetText(#String_OP)
        ElseIf GadgetID = #String_AD
          adminpass$ = GetGadgetText(#String_AD)
        ElseIf GadgetID = #CheckBox_4
          If GetGadgetState(#CheckBox_4)
            If OpenFile(1,LogFile$,#PB_File_SharedRead | #PB_File_NoBuffering)
              Logging = 1
              FileSeek(1,Lof(1))
              WriteLog("LOGGING STARTED",Server)
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
    WritePreferenceString("adminpass",GetGadgetText(#String_AD))
    WritePreferenceInteger("ModCol",GetGadgetState(#Combo_3))
    WritePreferenceInteger("motdevi",GetGadgetState(#Combo_4))
    WritePreferenceInteger("BlockIni",GetGadgetState(#Checkbox_BlockIni))
    ClosePreferences()
  EndProcedure 
  
  Procedure Splash(ponly)
    If OpenWindow(2,#PB_Ignore,#PB_Ignore,420,263,"serverD",#PB_Window_BorderLess|#PB_Window_ScreenCentered)
      WindowEvent()
      WindowEvent()
      UsePNGImageDecoder()
      CatchImage(3,?dend)
      ImageGadget(0,0,0,420,263,ImageID(3))
      WindowEvent()
      
      WindowEvent()
      CatchImage(0,?green)
      Icons(0)=ImageID(0)
      CatchImage(1,?mod)
      Icons(1)=ImageID(1)
      CatchImage(2,?hacker)
      Icons(2)=ImageID(2)
      WindowEvent()
      Delay(500)
      Open_Window_0()  
      If ReceiveHTTPFile("http://weedlan.de/serverd/serverd.txt","serverd.txt")
        OpenPreferences("serverd.txt")
        PreferenceGroup("Version")
        newbuild=ReadPreferenceInteger("Build",#PB_Editor_BuildCount)
        If newbuild>#PB_Editor_BuildCount
          update=1
        EndIf
        ClosePreferences()
      EndIf
      LoadSettings(0)
      CloseWindow(2)
    EndIf
  EndProcedure
CompilerEndIf

;- Network Thread
Procedure Network(var)
  killed=0
  success=CreateNetworkServer(0,port,#PB_Network_TCP)
  If success
    
    Dim MaskKey.a(3)
    Quit=0
    *Buffer = AllocateMemory(1024)
    
    If public And msthread=0
      msthread=CreateThread(@MasterAdvert(),port)
    EndIf      
    
    WriteLog("Server started",Server)
    Repeat
      
      SEvent = NetworkServerEvent()
      
      Select SEvent
        Case 0
          Delay(1)
          
        Case #PB_NetworkEvent_Disconnect
          ClientID = EventClient() 
          LockMutex(ListMutex)
          If FindMapElement(Clients(),Str(ClientID))
            WriteLog("CLIENT DISCONNECTED",Clients())
            If Clients()\CID>=0 And Clients()\CID <= characternumber
              Characters(Clients()\CID)\taken=0
            EndIf
            If areas(Clients()\area)\lock=ClientID
              areas(Clients()\area)\lock=0
              areas(Clients()\area)\mlock=0
            EndIf
            DeleteMapElement(Clients(),Str(ClientID))
            UnlockMutex(ListMutex)
            rf=1
          EndIf
          
        Case #PB_NetworkEvent_Connect
          ClientID = EventClient() 
          send=1
          ip$=IPString(GetClientIP(ClientID))
          
          ForEach IPbans()
            If ip$ = IPbans()
              send=0
              WriteLog("IP: "+ip$+" is banned, disconnecting",Server)
              SendNetworkString(ClientID,"BD#%")
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
            Clients()\area=0
            Clients()\ignore=0
            Clients()\judget=0
            Clients()\ooct=0
            Clients()\websocket=0
            Clients()\username=""
            UnlockMutex(ListMutex)
            WriteLog("CLIENT CONNECTED ",Clients())
            CompilerIf #CONSOLE=0
              AddGadgetItem(#Listview_0,-1,ip$+Chr(10)+"-1"+Chr(10)+Str(PV-1),Icons(0))
            CompilerEndIf
            
            CompilerIf #WEB
              length=ReceiveNetworkData(ClientID, *Buffer, 1024)
              Debug "eaoe"
              Debug length
              If length=-1
                SendNetworkString(ClientID,"decryptor#"+decryptor$+"#%")
              Else
                Debug "wotf"
                rawreceive$=PeekS(*Buffer,length)
                Debug rawreceive$
                If ExpertLog
                  WriteLog(rawreceive$,Clients())
                EndIf
                If length>=0 And Left(rawreceive$,3)="GET"
                  Clients()\websocket=1
                  For i = 1 To CountString(rawreceive$, #CRLF$)
                    headeririda$ = StringField(rawreceive$, i, #CRLF$)
                    headeririda$ = RemoveString(headeririda$, #CR$)
                    headeririda$ = RemoveString(headeririda$, #LF$)
                    If Left(headeririda$, 19) = "Sec-WebSocket-Key: "
                      wkey$ = Right(headeririda$, Len(headeririda$) - 19)
                    EndIf
                  Next
                  Debug wkey$
                  rkey$ = SecWebsocketAccept(wkey$)
                  Debug rkey$
                  vastus$ = "HTTP/1.1 101 Web Socket Protocol Handshake" + #CRLF$
                  vastus$ = vastus$ + "Access-Control-Allow-Origin: null" + #CRLF$
                  vastus$ = vastus$ + "Connection: Upgrade"+ #CRLF$
                  vastus$ = vastus$ + "Sec-WebSocket-Accept: " + rkey$ + #CRLF$
                  vastus$ = vastus$ + "Sec-WebSocket-Version:13" + #CRLF$
                  vastus$ = vastus$ + "Server: serverD "+version$ + #CRLF$
                  vastus$ = vastus$ + "Upgrade: websocket"+ #CRLF$ + #CRLF$
                  Debug vastus$
                  SendNetworkString(ClientID, vastus$)
                  
                EndIf
              EndIf
            CompilerElse
              SendNetworkString(ClientID,"decryptor#"+decryptor$+"#%")
            CompilerEndIf
          EndIf
          
          
        Case #PB_NetworkEvent_Data ;//////////////////////////Data
          ClientID = EventClient() 
          LockMutex(ListMutex)
          *usagePointer.Client=FindMapElement(Clients(),Str(ClientID))
          UnlockMutex(ListMutex)
          If *usagePointer
            length=ReceiveNetworkData(ClientID, *Buffer, 1024)
            If length
              rawreceive$=PeekS(*Buffer,length)
              Debug rawreceive$
              CompilerIf #WEB
                If *usagePointer\websocket
                  
                  Ptr = 0
                  Byte.a = PeekA(*Buffer + Ptr)
                  If Byte & %10000000
                    Fin = #True
                  Else
                    Fin = #False
                  EndIf
                  Opcode = Byte & %00001111
                  Ptr = 1
                  
                  Debug "Fin:" + Str(Fin)
                  Debug "Opcode: " + Str(Opcode)            
                  
                  
                  Byte = PeekA(*Buffer + Ptr)
                  Masked = Byte >> 7
                  Payload = Byte & $7F            
                  Ptr + 1
                  
                  If Payload = 126
                    Payload = PeekA(*Buffer + Ptr) << 8
                    Ptr + 1
                    Payload | PeekA(*Buffer + Ptr)
                    Ptr + 1
                  ElseIf Payload = 127
                    Payload = 0
                    n = 7
                    For i = Ptr To Ptr + 7
                      Payload | PeekA(*Buffer + i) << (8 * n)
                      n - 1
                    Next i
                    Ptr + 8
                  EndIf
                  
                  Debug "Masked: " + Str(Masked)
                  Debug "Payload: " + Str(Payload)
                  
                  If Masked
                    n = 0
                    For i = Ptr To Ptr + 3
                      MaskKey(n) = PeekA(*Buffer + i)
                      Debug "MaskKey " + Str(n + 1) + ": " + RSet(Hex(MaskKey(n)), 2, "0")
                      n + 1
                    Next i
                    Ptr + 4
                  EndIf
                  
                  Select Opcode
                    Case #TextFrame
                      If Masked
                        vastus$ = ""
                        n = 0
                        For i = Ptr To Ptr + Payload - 1
                          vastus$ + Chr(PeekA(*Buffer + i) ! MaskKey(n % 4))
                          n + 1
                        Next i
                      Else
                        vastus$ = PeekS(*Buffer + Ptr, Payload)
                      EndIf
                      rawreceive$=vastus$
                    Case #PingFrame
                      Byte = PeekA(*Buffer) & %11110000
                      PokeA(*Buffer, Byte | #PongFrame)
                      SendNetworkData(ClientID, *Buffer, bytesidkokku)
                    Case #ConnectionCloseFrame
                      If *usagePointer\CID>=0 And *usagePointer\CID <= characternumber
                        Characters(*usagePointer\CID)\taken=0
                      EndIf
                      If areas(*usagePointer\area)\lock=ClientID
                        areas(*usagePointer\area)\lock=0
                        areas(*usagePointer\area)\mlock=0
                      EndIf
                    Default
                      Debug "Opcode not implemented yet!"
                      Debug Opcode
                  EndSelect
                EndIf
              CompilerEndIf
              rawreceive$=StringField(rawreceive$,1,"%")+"%"
              length=Len(rawreceive$)
              
              If ExpertLog
                WriteLog(rawreceive$,*usagePointer)
              EndIf
              
              If Not *usagePointer\last.s=rawreceive$ And *usagePointer\ignore=0
                *usagePointer\last.s=rawreceive$
                If CommandThreading
                  CreateThread(@HandleAOCommand(),*usagePointer)
                Else
                  HandleAOCommand(*usagePointer)
                EndIf
              EndIf
            EndIf
          EndIf
          
        Default
          Delay(LagShield)
          
      EndSelect
      
    Until Quit = 1
    LockMutex(ListMutex)
    ResetMap(Clients())
    While NextMapElement(Clients())
      If Clients()\ClientID
        CloseNetworkConnection(Clients()\ClientID)
      EndIf
      DeleteMapElement(Clients())
    Wend
    CloseNetworkServer(0)
    killed=1
    FreeMemory(*Buffer)
    UnlockMutex(ListMutex)
  Else
    WriteLog("server creation failed",Server)
  EndIf
  
EndProcedure

;-  PROGRAM START    

start:
CompilerIf #PB_Compiler_Debugger
  If 1
  CompilerElse
    
    If ErrorAddress()          
      
      Quit=1
      lpublic=public
      public=0
      OpenFile(5,"crash.txt",#PB_File_NoBuffering|#PB_File_Append)      
      WriteStringN(5,"it "+ErrorMessage()+"'d at this address "+Str(ErrorAddress())+" target "+Str(ErrorTargetAddress()))
      CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
        WriteStringN(5,"EAX "+ErrorRegister(#PB_OnError_EAX))
        WriteStringN(5,"EBX "+ErrorRegister(#PB_OnError_EBX))
        WriteStringN(5,"ECX "+ErrorRegister(#PB_OnError_ECX))
        WriteStringN(5,"EDX "+ErrorRegister(#PB_OnError_EDX))
        WriteStringN(5,"EBP "+ErrorRegister(#PB_OnError_EBP))
        WriteStringN(5,"ESI "+ErrorRegister(#PB_OnError_ESI))
        WriteStringN(5,"EDI "+ErrorRegister(#PB_OnError_EDI))
        WriteStringN(5,"ESP "+ErrorRegister(#PB_OnError_ESP))
        WriteStringN(5,"FLG "+ErrorRegister(#PB_OnError_Flags))
      CompilerElse
        WriteStringN(5,"RAX "+ErrorRegister(#PB_OnError_RAX))
        WriteStringN(5,"RBX "+ErrorRegister(#PB_OnError_RBX))
        WriteStringN(5,"RCX "+ErrorRegister(#PB_OnError_RCX))
        WriteStringN(5,"RDX "+ErrorRegister(#PB_OnError_RDX))
        WriteStringN(5,"RBP "+ErrorRegister(#PB_OnError_RBP))
        WriteStringN(5,"RSI "+ErrorRegister(#PB_OnError_RSI))
        WriteStringN(5,"RDI "+ErrorRegister(#PB_OnError_RDI))
        WriteStringN(5,"RSP "+ErrorRegister(#PB_OnError_RSP))
        WriteStringN(5,"FLG "+ErrorRegister(#PB_OnError_Flags))
      CompilerEndIf
      CloseFile(5)
      LoadSettings(1)
      Delay(500)
      public=lpublic
      Quit=0
      If nthread
        nthread=CreateThread(@Network(),0)
      EndIf
    Else
    CompilerEndIf
    
    CompilerIf #CONSOLE=0
      Splash(0)
    CompilerElse
      OpenConsole()
      LoadSettings(0)
    CompilerEndIf
    
    oldCLient.Client
    *clickedClient.Client        
    
    parameter$=ProgramParameter()
    If parameter$="-auto"
      CompilerIf #CONSOLE=0
        SetWindowColor(0, RGB(255,255,0))
        SetGadgetText(#Button_2,"RELOAD")
        nthread=CreateThread(@Network(),0)  
      CompilerEndIf
    EndIf         
  EndIf
  
  CompilerIf #CONSOLE
    Network(0)
  CompilerElse
    ;- WINDOW EVENT LOOP 
    Repeat ; Start of the event loop
      Event = WaitWindowEvent() ; This line waits until an event is received from Windows
      WindowID = EventWindow()  ; The Window where the event is generated, can be used in the gadget procedures
      GadgetID = EventGadget()  ; Is it a gadget event?
      EventType = EventType()   ; The event type
      If Event = #PB_Event_Gadget
        
        
        lvstate=GetGadgetState(#Listview_0)
        If lvstate>=0         
          cldata = GetGadgetItemData(#Listview_0,lvstate)
          If cldata
            LockMutex(ListMutex)
            *clickedClient=FindMapElement(Clients(),Str(cldata))
            UnlockMutex(ListMutex)
          EndIf
          
          Select GadgetID 
            Case #Button_kk ;KICK
              KickBan(Str(cldata),#KICK,Server)
              cldata=-1
              
            Case #Button_sw ;SWITCH
              If *clickedClient\cid>=0
                Characters(*clickedClient\cid)\taken=0
              EndIf
              *clickedClient\cid=-1    
              SendNetworkString(cldata,"DONE#%")
              
            Case #Button_mu ;MUTE
              KickBan(Str(cldata),#MUTE,Server)
              
            Case #Button_um ;UNMUTE
              KickBan(Str(cldata),#UNMUTE,Server)
              
            Case #Button_kb ;BAN 
              KickBan(Str(cldata),#BAN,Server)
              cldata=-1
              
            Case #Button_hd ;HDBAN
              KickBan(*clickedClient\HD,#BAN,Server)
              cldata=-1
              
            Case #Button_dc ;DISCONNECT
              KickBan(Str(cldata),#DISCO,Server)
              cldata=-1     
              
            Case #Button_ig ;IGNORE
              KickBan(Str(cldata),#CIGNORE,Server)
              
            Case #Button_si ; STOP IGNORING ME
              KickBan(Str(cldata),#UNIGNORE,Server)
              
            Case #Button_ndj ;IGNORE MUSIC
              KickBan(Str(cldata),#UNDJ,Server)
              
            Case #Button_dj ; STOP IGNORING MY MUSIC
              KickBan(Str(cldata),#DJ,Server)
              
          EndSelect
          
        EndIf
        
        Select GadgetID 
          Case #ListIcon_2
            ooclient=GetGadgetItemData(#ListIcon_2,GetGadgetState(#ListIcon_2))   
            If ooclient
              For b=0 To CountGadgetItems(#ListView_0)
                If GetGadgetItemData(#ListView_0,b) = ooclient 
                  SetGadgetState(#ListView_0,b)
                EndIf
              Next
            EndIf
            
          Case #Listview_2
            logclid=GetGadgetItemData(#Listview_2,GetGadgetState(#Listview_2))   
            If logclid
              For b=0 To CountGadgetItems(#ListView_0)
                If GetGadgetItemData(#ListView_0,b) = logclid  
                  SetGadgetState(#ListView_0,b)
                EndIf
              Next
            EndIf
            
          Case #CheckBox_MS
            public=GetGadgetState(#CheckBox_MS)
            Debug public
            If public
              msthread=CreateThread(@MasterAdvert(),port)
            EndIf
            
          Case #Button_31
            AddGadgetItem(#ListIcon_2,-1,Server\username+Chr(10)+GetGadgetText(#String_13))
            SendTarget("*","CT#"+Server\username+"#"+GetGadgetText(#String_13)+"#%",Server)                
            
          Case #Button_2 ;START
            port=Val(GetGadgetText(#String_5))
            If nthread
              LoadSettings(1)
            Else
              SetWindowColor(0, RGB(0,128,0))
              SetGadgetText(#Button_2,"RELOAD")
              nthread=CreateThread(@Network(),0)                
            EndIf
            
          Case #Button_4 ;CONFIG
            CreateThread(@ConfigWindow(),0) 
            
          Case #Button_About
            MessageRequester("serverD","This is serverD version "+Str(#PB_Editor_CompileCount)+"."+Str(#PB_Editor_BuildCount)+Chr(10)+"(c) stonedDiscord 2014-2015")
            
        EndSelect
      ElseIf Event = #PB_Event_SizeWindow
        
        ResizeGadget(#Frame_0,0,0,WindowWidth(0)/2.517,WindowHeight(0))
        ResizeGadget(#ListView_0,70,40,WindowWidth(0)/2.517-70,WindowHeight(0)-40)
        ResizeGadget(#Button_2,WindowWidth(0)/6.08,15,WindowWidth(0)/8.111,22)
        ResizeGadget(#String_5,WindowWidth(0)/3.476,15,WindowWidth(0)/10.42,22)
        ResizeGadget(#Frame_4,WindowWidth(0)/2.517,0,WindowWidth(0)/3.173,WindowHeight(0))
        ResizeGadget(#Listview_2, WindowWidth(0)/1.7, 30, WindowWidth(0)-WindowWidth(0)/1.7, WindowHeight(0)-90)
        ResizeGadget(#Listview_2,WindowWidth(0)/2.517,20,WindowWidth(0)/3.173,WindowHeight(0)-20)
        ResizeGadget(#Frame_5,WindowWidth(0)/1.4,0,WindowWidth(0)/3.476,WindowHeight(0))
        ResizeGadget(#ListIcon_2,WindowWidth(0)/1.4,20,WindowWidth(0)/3.476,WindowHeight(0)-40)  
        
        ResizeGadget(#String_13,WindowWidth(0)/1.4,WindowHeight(0)-20,WindowWidth(0)/5,20)  
        ResizeGadget(#Button_31,WindowWidth(0)/1.1,WindowHeight(0)-20,WindowWidth(0)/10,20)  
        
        
      EndIf
      
      If rf
          If CommandThreading
            CreateThread(@RefreshList(),0)
          Else
            RefreshList(0)
          EndIf
          rf=0
        EndIf 
      
    Until Event = #PB_Event_CloseWindow ; End of the event loop
    Quit=1
    
    OpenPreferences("base/settings.ini")
    PreferenceGroup("net")
    WritePreferenceInteger("public",public)
    WritePreferenceInteger("port",port)
    ClosePreferences()
    endtime=0
    While killed=0 And endtime<1000
      Delay(1)
      endtime+1
    Wend
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
  
  End
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 739
; FirstLine = 716
; Folding = ---
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0