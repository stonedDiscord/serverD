; yes this is the legit serverD source code please report bugfixes/modifications/feature requests to sD/trtukz on skype

CompilerIf #PB_Compiler_Debugger=0
  OnErrorGoto(?start)
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
Global version$="v"+Str(#PB_Editor_CompileCount)+"."+Str(#PB_Editor_BuildCount)
Global CommandThreading=0
Global Dim MaskKey.a(3)
Global Quit=0
Global ReplayMode=0
Global ReplayLength=0
Global ReplayFile$=""
Global LoopMusic=0
Global MultiChar=1
Global nthread=0
Global error=0
Global lasterror=0
Global WebSockets=1
Global Logging.b=0
Global LagShield=10
Global public.b=0
Global LogFile$="poker.log"
Global oppass$=""
Global killed=0
Global success=0
Global adminpass$=""
Global opppass$=""
Global Quit=0
Global Port=27016
Global scene$="AAOPublic2"
Global CharacterNumber=0
Global slots$="100"
Global oBG.s="gs4"
Global rt.b=1
Global loghd.b=0
Global background.s
Global PV=1
Global msname$="serverD"
Global desc$="Default serverD "+version$
Global www$
Global rf.b=0
Global msip$="127.0.0.1"
Global Replays.b=0
Global rline=0
Global replayline=0
Global replayopen.b
Global modcol=0
Global BlockINI.b=0
Global BlockTaken.b=1
Global MOTDevi=0
Global ExpertLog=0
Global tracks=0
Global msthread=0
Global LoginReply$="CT#$HOST#Successfully connected as mod#%"
Global motd$="Take that!"
Global musicpage=0
Global EviNumber=0
Global ListMutex = CreateMutex()
Global MusicMutex = CreateMutex()
Global RefreshMutex = CreateMutex()
Global ActionMutex = CreateMutex()
Global musicmode=1
Global update=0
Global AreaNumber=1
Global decryptor$
Global key
Global newbuild
Global *Buffer
Global NewList HDmods.s()
Global NewList gimps.s()
Global NewList PReplay.s()
Global Dim Evidences.Evidence(100)
Global Dim Icons.l(2)
Global Dim ReadyChar.s(100)
Global newcready$="SC#%"
Global newmready$="SM#%"
Global newaready$="SA#%"
Global Dim ReadyVItem.s(100)
Global Dim ReadyVMusic.s(1000)
Global Dim ReadyEvidence.s(100)
Global Dim ReadyMusic.s(500)

;- Include files

CompilerIf #CONSOLE=0
  IncludeFile "Common.pb"
CompilerEndIf

IncludeFile "server_shared.pb"

Global NewList HDbans.TempBan()
Global NewList IPbans.TempBan()
Global NewList SDbans.TempBan()

; Initialize The Network
If InitNetwork() = 0
  CompilerIf #CONSOLE=0
    MessageRequester("serverD "+version$, "Can't initialize the network!",#MB_ICONERROR)
  CompilerEndIf
  End
EndIf


;- Define Functions
; yes after the network init and include code
; many of these depend on that

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
      ReplayOpen=OpenFile(3,"base/replays/AAO replay "+FormatDate("%dd-%mm-%yy %hh-%ii-%ss",Date())+".txt",#PB_File_SharedRead | #PB_File_NoBuffering)
      If ReplayOpen
        WriteStringN(3,"decryptor#"+decryptor$+"#%")
      EndIf
    EndIf
  EndIf
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

;- Load Settings function
Procedure LoadSettings(reload)
  Define loadchars,loadcharsettings,loaddesc, loadevi, loadareas
  Define iniarea,charpage,page,dur,ltracks,nplg
  Define track$,trackn$,hdmod$,hdban$,ipban$,ready$,area$,lgimp$,aname$
  WriteLog("Loading serverD "+version$+" settings",Server)
  If update
    WriteLog("UPDATE AVAILABLE",Server)
    WriteLog("check https://github.com/stonedDiscord/serverD/releases",Server)
  EndIf
  
  If OpenPreferences("base/settings.ini")=0
    CreateDirectory("base")
    If CreatePreferences("base/settings.ini")=0
      WriteLog("couldn't create settings file(folder missing/permissions?)",Server)
    Else
      PreferenceGroup("Net")
      WritePreferenceInteger("public",0)
      WritePreferenceString("oppassword","change_me_people_can_use_this_to_take_passworded_chars") 
      WritePreferenceInteger("Port",27016)
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
  opppass$=Encode(ReadPreferenceString("oppassword","change_me_people_can_use_this_to_take_passworded_chars"))
  Port=ReadPreferenceInteger("Port",27016)
  public=ReadPreferenceInteger("public",0)
  CompilerIf #CONSOLE=0
    SetGadgetText(#String_5,Str(Port))
    SetGadgetState(#CheckBox_MS,public)
  CompilerElse
    PrintN("OP pass:"+opppass$)
    PrintN("Server Port:"+Str(Port))
    PrintN("Public server:"+Str(public))
  CompilerEndIf
  
  PreferenceGroup("server")
  musicmode=ReadPreferenceInteger("musicmode",1)
  Replays=ReadPreferenceInteger("replaysave",0)
  LagShield=ReadPreferenceInteger("LagShield",10)
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
      WritePreferenceString("OPpass","")
      WritePreferenceString("adminpass","")
      WritePreferenceInteger("BlockTaken",1)
      WritePreferenceInteger("BlockINI",0)
      WritePreferenceInteger("ModColor",0)
      WritePreferenceInteger("MOTDevi",0)
      WritePreferenceString("MOTD","Take that!")
      WritePreferenceInteger("LoopMusic",0)
      WritePreferenceInteger("MultiChar",1)
      WritePreferenceInteger("WTCE",1)
      WritePreferenceInteger("ExpertLog",0)
      WritePreferenceInteger("WebSockets",1)
      WritePreferenceString("LoginReply","CT#sD#got it#%")
      WritePreferenceString("LogFile","base/serverlog.log")
    EndIf
  EndIf
  
  PreferenceGroup("cfg")
  oppass$=Encode(ReadPreferenceString("OPpass",""))
  adminpass$=Encode(ReadPreferenceString("adminpass",""))
  BlockINI=ReadPreferenceInteger("BlockINI",0)
  BlockTaken=ReadPreferenceInteger("BlockTaken",1)
  modcol=ReadPreferenceInteger("ModColor",0)
  LoopMusic=ReadPreferenceInteger("LoopMusic",0)
  MOTDevi=ReadPreferenceInteger("MOTDevi",0)
  MultiChar=ReadPreferenceInteger("MultiChar",1)
  rt=ReadPreferenceInteger("WTCE",1)
  ExpertLog=ReadPreferenceInteger("ExpertLog",0)
  WebSockets=ReadPreferenceInteger("WebSockets",1)
  LoginReply$=ReadPreferenceString("LoginReply","CT#$HOST#Successfully connected as mod#%")
  LogFile$=ReadPreferenceString("LogFile","base/serverlog.log")
  decryptor$=ReadPreferenceString("decryptor","34")
  motd$=ReadPreferenceString("MOTD","Take that!")
  key=Val(DecryptStr(HexToString(decryptor$),322))
  If Logging
    CloseFile(1)
  EndIf
  Logging=ReadPreferenceInteger("Logging",1)
  ClosePreferences()
  
  If Logging
    If OpenFile(1,LogFile$,#PB_File_Append|#PB_File_SharedRead)
      FileSeek(1,Lof(1))
      WriteLog("LOGGING STARTED",Server)
    Else
      Logging=0
    EndIf
  EndIf  
  
  OpenPreferences("base/scene/"+scene$+"/init.ini")
  
  CompilerIf #CONSOLE
    PrintN("OOC pass:"+oppass$)
    PrintN("Block INI edit:"+Str(BlockINI))
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
    areas(iniarea)\good=10
    areas(iniarea)\evil=10
  Next
  PreferenceGroup("chars")
  characternumber=ReadPreferenceInteger("number",1)
  If ReadPreferenceInteger("slots",characternumber)=-1
    slots$="Unlimited"
  Else
    slots$=Str(ReadPreferenceInteger("slots",characternumber))
  EndIf
  ReDim Characters.ACharacter(characternumber)
  ReDim ReadyChar(characternumber/10)
  Debug "rcharpages"
  Debug characternumber/10
  For loadchars=0 To characternumber
    Characters(loadchars)\name=Encode(ReadPreferenceString(Str(loadchars),"zettaslow"))
  Next
  PreferenceGroup("desc")
  For loaddesc=0 To characternumber
    Characters(loaddesc)\desc=Encode(ReadPreferenceString(Str(loadchars),""))
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
  newcready$="SC#"
  charpage=0
  Debug CharacterNumber
  For loadcharsettings=0 To CharacterNumber
    OpenPreferences("base/scene/"+scene$+"/char"+Str(loadcharsettings)+".ini")
    PreferenceGroup("desc")
    Characters(loadcharsettings)\desc=Encode(ReadPreferenceString("text","No description"))
    Characters(loadcharsettings)\dj=ReadPreferenceInteger("dj",musicmode)
    Characters(loadcharsettings)\evinumber=ReadPreferenceInteger("evinumber",0)
    If MOTDevi
      Characters(loadcharsettings)\evidence=Encode(Str(MOTDevi)+","+ReadPreferenceString("evi",""))
      Characters(loadcharsettings)\evinumber+1
    Else
      Characters(loadcharsettings)\evidence=Encode(ReadPreferenceString("evi",""))
    EndIf
    Characters(loadcharsettings)\pw=Encode(ReadPreferenceString("pass",""))
    If Characters(loadcharsettings)\pw<>""
      passworded$="1"
    Else
      passworded$="0"
    EndIf
    ClosePreferences()
    ready$ = ready$ + Str(loadcharsettings)+"#"+Characters(loadcharsettings)\name+"&"+Characters(loadcharsettings)\desc+"&"+Str(Characters(loadcharsettings)\evinumber)+"&"+Characters(loadcharsettings)\evidence+"&"+Characters(loadcharsettings)\pw+"&0&#"
    newcready$ = newcready$ + Characters(loadcharsettings)\name+"&"+Characters(loadcharsettings)\desc+"&0&"+passworded$+"#"
    If loadcharsettings%10 = 9 Or loadcharsettings=CharacterNumber
      ready$=ready$+"#%"
      ReadyChar(charpage)=ready$
      Debug ready$
      Debug charpage
      Debug loadcharsettings
      charpage+1
      ready$="CI#"
    EndIf    
  Next
  newcready$=newcready$+"%"
  
  If ReadFile(2, "base/musiclist.txt")
    tracks=0
    ltracks=0
    musicpage=0
    ready$="EM#"
    newmready$="SM#"
    While Eof(2) = 0
      AddElement(Music())
      trackn$=ReadString(2) 
      track$=StringField(trackn$,1,"*")
      dur=Val(StringField(trackn$,2,"*"))
      track$ = ReplaceString(track$,"#","<num>")
      track$ = ReplaceString(track$,"%","<percent>")
      Music()\TrackName = track$
      Music()\Length = dur*1000
      ready$ = ready$ + Str(tracks) + "#" + track$ + "#"
      newmready$=newmready$+track$+"#"
      ltracks+1
      tracks+1
      If ltracks = 10
        ReadyMusic(musicpage)=ready$+"#%"
        musicpage+1
        ltracks=0
        ReDim ReadyMusic(musicpage)
        ready$="EM#"
      EndIf
    Wend
    If Not ltracks = 10
      ReadyMusic(musicpage)=ready$+"#%"
    EndIf
    newmready$+"%"
    ReDim ReadyMusic(musicpage) 
    CloseFile(2)
    ResetList(Music())
    NextElement(Music())
    ReadyVMusic(0) = "MD#1#"+ Music()\TrackName +"#%"
    readytracks=1
    If tracks>1
      Repeat
        NextElement(Music())
        ReadyVMusic(readytracks) = "MD#" + Str(readytracks+1) + "#" + Music()\TrackName
        If NextElement(Music())
          ReadyVMusic(readytracks) + "#" + Str(readytracks+2) + "#" + Music()\TrackName
          PreviousElement(Music())
        EndIf
        ReadyVMusic(readytracks)+"#%"
        readytracks+1
      Until readytracks=tracks
    EndIf
  Else
    WriteLog("NO MUSIC LIST",Server)
    AddElement(Music())
    Music()\TrackName="NO MUSIC LIST"
    ReadyMusic(0)="EM#0#NO MUSIC LIST##%"
    newmready$="SM#NO MUSIC LIST#%"
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
    AreaNumber=ReadPreferenceInteger("number",1)
    newaready$="SA#"
    For loadareas=0 To AreaNumber-1
      PreferenceGroup("Areas")
      aname$=Encode(ReadPreferenceString(Str(loadareas+1),oBG.s))
      areas(loadareas)\name=aname$
      PreferenceGroup("filename")
      area$=Encode(ReadPreferenceString(Str(loadareas+1),oBG.s))
      areas(loadareas)\bg=area$
      PreferenceGroup("hidden")
      areas(loadareas)\hidden=ReadPreferenceInteger(Str(loadareas+1),0)
      PreferenceGroup("pass")
      areas(loadareas)\pw=Encode(ReadPreferenceString(Str(loadareas+1),""))
      If areas(loadareas)\pw=""
        passworded$="0"
      Else
        passworded$="1"
      EndIf
      If areas(loadareas)\hidden=0
        newaready$+aname$+"&"+area$+"&"+passworded$+"#"
      EndIf
    Next
    newaready$+"%"
    ClosePreferences()
  Else
    If CreatePreferences("base/scene/"+scene$+"/areas.ini")
      PreferenceGroup("Areas")
      WritePreferenceInteger("number",1)
      WritePreferenceString("1",oBG.s)
      PreferenceGroup("filename")
      WritePreferenceString("1",oBG.s)
      areas(0)\bg=oBG.s
      AreaNumber=1
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
        SDbans()\banned=StringField(hdban$,1,"#")
        SDbans()\time=Val(StringField(hdban$,2,"#"))
        SDbans()\reason=StringField(hdban$,3,"#")
        SDbans()\type=Val(StringField(hdban$,4,"#"))
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
        HDbans()\banned=StringField(hdban$,1,"#")
        HDbans()\time=Val(StringField(hdban$,2,"#"))
        HDbans()\reason=StringField(hdban$,3,"#")
        HDbans()\type=Val(StringField(hdban$,4,"#"))
      EndIf
    Wend
    CloseFile(2)
  Else
    If CreateFile(2,"base/HDbanlist.txt")
      CloseFile(2)
    EndIf
  EndIf
  
  If ReadFile(2, "base/banlist.txt")
    ClearList(IPbans())
    While Eof(2) = 0
      ipban$=ReadString(2)
      If ipban$<>""
        AddElement(IPbans())
        IPbans()\banned=StringField(ipban$,1,"#")
        IPbans()\time=Val(StringField(ipban$,2,"#"))
        IPbans()\reason=StringField(ipban$,3,"#")
        IPbans()\type=Val(StringField(ipban$,4,"#"))
      EndIf
    Wend
    CloseFile(2)
  EndIf
  
  CloseLibrary(#PB_All)
  If ExamineDirectory(0, "plugins/", "*"+libext$)  
    While NextDirectoryEntry(0)
      If DirectoryEntryType(0) = #PB_DirectoryEntry_File
        Debug "file"
        If OpenLibrary(nplg,"plugins/"+DirectoryEntryName(0))
          PluginVersion.PPluginVersion = GetFunction(nplg,"PluginVersion")
          Debug "loading"
          If PluginVersion() >= 1
            Debug "checked"
            AddElement(Plugins())
            Plugins()\version=PluginVersion()
            Plugins()\ID=nplg
            PluginName.PPluginName = GetFunction(nplg,"PluginName")
            PluginDescription.PPluginDescription = GetFunction(nplg,"PluginDescription")
            
            Plugins()\rawfunction = GetFunction(nplg,"PluginRAW")
            Plugins()\gtarget = GetFunction(nplg,"SetTarget")
            Plugins()\gmessage = GetFunction(nplg,"SetMessage")
            Plugins()\gcallback = GetFunction(nplg,"StatusCallback")
            
            Plugins()\name = PeekS(PluginName())
            Plugins()\description = PeekS(PluginDescription())
            Plugins()\active=1
          EndIf
          nplg+1
        EndIf
      EndIf
    Wend
    FinishDirectory(0)
  EndIf
  
  
EndProcedure

Procedure ListIP(ClientID)
  Define iplist$
  Define charname$
  iplist$="IL#"
  LockMutex(ListMutex)
  PushMapPosition(Clients())
  ResetMap(Clients())
  While NextMapElement(Clients())
    Select Clients()\perm
      Case 1
        charname$=GetCharacterName(Clients())+"(mod)"+" in "+GetAreaName(Clients())
      Case 2
        charname$=GetCharacterName(Clients())+"(admin)"+" in "+GetAreaName(Clients())
      Case 3
        charname$=GetCharacterName(Clients())+"(server) also this is not good, you better see a sDoctor"
      Default
        charname$=GetCharacterName(Clients())+" in "+GetAreaName(Clients())
    EndSelect
    iplist$=iplist$+Clients()\IP+"|"+charname$+"|"+Str(Clients()\CID)+"|*"
  Wend
  PopMapPosition(Clients())
  UnlockMutex(ListMutex)
  iplist$=iplist$+"#%"
  SendTarget(Str(ClientID),iplist$,Server) 
EndProcedure

Procedure ListIPSI(ClientID)
  Define iplist$
  Define charname$
  iplist$="SI#"
  LockMutex(ListMutex)
  PushMapPosition(Clients())
  ResetMap(Clients())
  While NextMapElement(Clients())
    Select Clients()\perm
      Case 1
        charname$=GetCharacterName(Clients())+"(mod)"+" in "+GetAreaName(Clients())
      Case 2
        charname$=GetCharacterName(Clients())+"(admin)"+" in "+GetAreaName(Clients())
      Case 3
        charname$=GetCharacterName(Clients())+"(server) also this is not good, you better see a sDoctor"
      Default
        charname$=GetCharacterName(Clients())+" in "+GetAreaName(Clients())
    EndSelect
    iplist$=iplist$+Clients()\IP+"&"+charname$+"&"+Str(Clients()\CID)+"#"
  Wend
  PopMapPosition(Clients())
  UnlockMutex(ListMutex)
  iplist$=iplist$+"%"
  SendTarget(Str(ClientID),iplist$,Server) 
EndProcedure

ProcedureDLL MasterAdvert(Port)
  Define msID=0,msinfo,NEvent,msPort=27016,retries,tick
  Define sr=-1
  Define  *null=AllocateMemory(512)
  Define master$,msrec$
  WriteLog("Masterserver adverter thread started",Server)
  OpenPreferences("base/masterserver.ini")
  PreferenceGroup("list")
  master$=ReadPreferenceString("0","51.255.160.217")
  msPort=ReadPreferenceInteger("Port",27016)
  ClosePreferences()
  
  WriteLog("Using master "+master$, Server)
  
  If public
    Repeat
      
      If msID
        
        If tick>10
          sr=SendNetworkString(msID,"PING#%")
        EndIf
        
        NEvent=NetworkClientEvent(msID)
        If NEvent=#PB_NetworkEvent_Disconnect
          msID=0
        ElseIf NEvent=#PB_NetworkEvent_Data
          msinfo=ReceiveNetworkData(msID,*null,512)
          If msinfo=-1
            msID=0
          Else
            msrec$=PeekS(*null,msinfo)
            Debug msrec$
            If msrec$="NOSERV#%"
              WriteLog("Fell off the serverlist, fixing...",Server)
              sr=SendNetworkString(msID,"SCC#"+Str(Port)+"#"+msname$+"#"+desc$+"#serverD "+version$+"#%"+Chr(0))
              WriteLog("Server published!",Server)
            EndIf
            tick=0
            retries=0
          EndIf
        EndIf
        
      Else
        retries+1
        WriteLog("Masterserver adverter thread connecting...",Server)
        msID=OpenNetworkConnection(master$,msPort)
        If msID
          Server\ClientID=msID
          sr=SendNetworkString(msID,"SCC#"+Str(Port)+"#"+msname$+"#"+desc$+"#serverD "+version$+"#%"+Chr(0))
          WriteLog("Server published!",Server)
        EndIf
      EndIf
      If tick>100
        WriteLog("Masterserver adverter thread timed out",Server)
        If msID
          CloseNetworkConnection(msID)
        EndIf
        Server\ClientID=0
        msID=0
      EndIf
      Delay(3000)
      tick+1
    Until public=0
  EndIf
  WriteLog("Masterserver adverter thread stopped",Server)
  If msID
    CloseNetworkConnection(msID)
  EndIf
  FreeMemory(*null)
  msthread=0
EndProcedure

Procedure SendDone(*usagePointer.Client)
  Define send$
  Define sentchar
  Dim APlayers(characternumber)
  
  
  send$="CharsCheck"
  LockMutex(ListMutex)
  PushMapPosition(Clients())
  ResetMap(Clients())
  While NextMapElement(Clients())
    If Clients()\CID>=0 And Clients()\CID <= characternumber
      If Clients()\area=*usagePointer\area
        APlayers(Clients()\CID)=1
      EndIf
    EndIf
  Wend
  PopMapPosition(Clients())
  UnlockMutex(ListMutex)
  For sentchar=0 To characternumber
    If APlayers(sentchar)=1 Or Characters(sentchar)\pw<>""
      send$ = send$ + "#-1"
    Else
      send$ = send$ + "#0"
    EndIf
  Next
  send$ = send$ + "#%"
  SendTarget(Str(*usagePointer\ClientID),send$,Server)
  SendTarget(Str(*usagePointer\ClientID),"BN#"+areas(*usagePointer\area)\bg+"#%",Server)
  SendTarget(Str(*usagePointer\ClientID),"OPPASS#"+StringToHex(EncryptStr(opppass$,key))+"#%",Server)
  SendTarget(Str(*usagePointer\ClientID),"MM#"+Str(musicmode)+"#%",Server)
  SendTarget(Str(*usagePointer\ClientID),"DONE#%",Server)
EndProcedure

Procedure SwitchAreas(*usagePointer.Client,narea$,apass$)
  Define sendd=0
  Define ir
  Debug narea$
  For ir=0 To AreaNumber
    areas(ir)\players=0
    Debug areas(ir)\name
    If areas(ir)\name = narea$
      narea$ = Str(ir)
      Break
    EndIf
  Next
  
  LockMutex(ListMutex)
  PushMapPosition(Clients())
  ResetMap(Clients())
  While NextMapElement(Clients())
    If Clients()\CID=*usagePointer\CID And Clients()\ClientID<>*usagePointer\ClientID
      If Clients()\area=Val(narea$) Or MultiChar=0
        sendd=1
      EndIf
    EndIf
    If Clients()\area>=0
      areas(Clients()\area)\players+1
    EndIf
  Wend
  PopMapPosition(Clients())
  UnlockMutex(ListMutex)
  
  If narea$="0"
    If areas(*usagePointer\area)\lock=*usagePointer\ClientID
      areas(*usagePointer\area)\lock=0
      areas(*usagePointer\area)\mlock=0
    EndIf
    areas(*usagePointer\area)\players-1
    *usagePointer\area=0
    areas(0)\players+1
    If sendd=1
      *usagePointer\CID=-1
      SendDone(*usagePointer)
    Else
      SendTarget(Str(*usagePointer\ClientID),"BN#"+areas(0)\bg+"#%",Server)      
    EndIf
    If *usagePointer\type>=#AOTWO
      SendTarget(Str(*usagePointer\ClientID),"OA#0#0#%",Server)
      send$="TA"
      For carea=0 To AreaNumber
        send$ = send$ + "#"+Str(areas(carea)\players)
      Next
      send$ = send$ + "#%"
      SendTarget(Str(*usagePointer\ClientID),send$,Server)
    Else
      SendTarget(Str(*usagePointer\ClientID),"CT#$HOST#area 0 selected#%",Server)
      SendTarget(Str(*usagePointer\ClientID),"HP#1#"+Str(Areas(0)\good)+"#%",Server)
      SendTarget(Str(*usagePointer\ClientID),"HP#2#"+Str(Areas(0)\evil)+"#%",Server)
    EndIf
  Else
    If Val(narea$)<=AreaNumber-1 And Val(narea$)>=0
      If Not areas(Val(narea$))\lock Or *usagePointer\perm>areas(Val(narea$))\mlock
        If areas(Val(narea$))\pw="" Or areas(Val(narea$))\pw=apass$ Or *usagePointer\perm
          If areas(*usagePointer\area)\lock=*usagePointer\ClientID
            areas(*usagePointer\area)\lock=0
            areas(*usagePointer\area)\mlock=0
          EndIf
          areas(*usagePointer\area)\players-1
          *usagePointer\area=Val(narea$)
          areas(*usagePointer\area)\players+1
          If sendd=1
            *usagePointer\CID=-1
            SendDone(*usagePointer)
          Else
            SendTarget(Str(*usagePointer\ClientID),"BN#"+areas(*usagePointer\area)\bg+"#%",Server)
          EndIf
          If *usagePointer\type>=#AOTWO
            SendTarget(Str(*usagePointer\ClientID),"OA#"+narea$+"#0#%",Server)
            send$="TA"
            For carea=0 To AreaNumber
              send$ = send$ + "#"+Str(areas(carea)\players)
            Next
            send$ = send$ + "#%"
            SendTarget(Str(*usagePointer\ClientID),send$,Server)
          Else
            SendTarget(Str(*usagePointer\ClientID),"CT#$HOST#area "+Str(*usagePointer\area)+" selected#%",Server)
            SendTarget(Str(*usagePointer\ClientID),"HP#1#"+Str(Areas(*usagePointer\area)\good)+"#%",Server)
            SendTarget(Str(*usagePointer\ClientID),"HP#2#"+Str(Areas(*usagePointer\area)\evil)+"#%",Server)
          EndIf
        Else
          If *usagePointer\type>=#AOTWO
            SendTarget(Str(*usagePointer\ClientID),"OA#"+narea$+"#1#%",Server)
          Else
            SendTarget(Str(*usagePointer\ClientID),"CT#$HOST#wrong password#%",Server)
          EndIf
        EndIf
      Else
        SendTarget(Str(*usagePointer\ClientID),"CT#$HOST#area locked#%",Server)
      EndIf
    Else
      SendTarget(Str(*usagePointer\ClientID),"CT#$HOST#Not a valid area#%",Server)
    EndIf
  EndIf
EndProcedure

Procedure KickBan(kick$,param$,action,*usagePointer.Client)
  Define actionn$
  Define akck,newchar=-1
  Define everybody
  Define i,kclid,kcid
  akck=0
  If kick$="everybody" Or kick$="*"
    everybody=1
  EndIf
  Debug "kick$"
  Debug kick$
  LockMutex(ListMutex)
  ResetMap(Clients())
  While NextMapElement(Clients())
    kclid=Clients()\ClientID
    kcid=Clients()\CID
    Debug "wkick$"
    Debug kick$
    Debug kclid
    If Clients()\ClientID
      If kick$=Str(kcid) Or kick$=Str(kclid) Or kick$=ReplaceString(GetCharacterName(Clients())," ","_") Or kick$=Clients()\HD Or kick$=Clients()\IP Or kick$="Area"+Str(Clients()\area) Or everybody
        If Clients()\perm<*usagePointer\perm Or (*usagePointer\perm And Clients()=*usagePointer)
          LockMutex(ActionMutex)
          Select action
            Case #KICK
              SendNetworkString(kclid,"KK#"+Str(kcid)+"#"+param$+"#%")
              RemoveDisconnect(kclid)
              CloseNetworkConnection(kclid)
              actionn$="kicked"
              akck+1
              
            Case #DISCO
              RemoveDisconnect(kclid)
              CloseNetworkConnection(kclid)
              actionn$="disconnected"
              akck+1
              
            Case #BAN
              If Clients()\IP<>"127.0.0.1"
                If kick$=Clients()\HD
                  AddElement(HDbans())
                  HDbans()\banned=Clients()\HD
                  HDbans()\reason=param$
                  HDbans()\time=btime
                  HDbans()\type=#BAN
                  If OpenFile(2,"base/HDbanlist.txt")
                    FileSeek(2,Lof(2))
                    WriteStringN(2,Clients()\HD+"#"+ HDbans()\reason+"#"+Str(HDbans()\time)+"#"+Str(#BAN))
                    CloseFile(2)
                  EndIf
                Else
                  AddElement(IPbans())
                  IPbans()\banned=Clients()\IP
                  IPbans()\reason=param$
                  IPbans()\time=btime
                  IPbans()\type=#BAN
                  If OpenFile(2,"base/banlist.txt")
                    FileSeek(2,Lof(2))
                    WriteStringN(2,Clients()\IP+"#"+IPbans()\reason+"#"+Str(IPbans()\time)+"#"+Str(#BAN))
                    CloseFile(2)
                  EndIf
                EndIf
                SendNetworkString(kclid,"KB#"+Str(kcid)+"#"+param$+"#%")
                RemoveDisconnect(kclid)
                CloseNetworkConnection(kclid)
                actionn$="banned"
                akck+1
              EndIf
              
            Case #MUTE
              SendNetworkString(kclid,"MU#"+Str(kcid)+"#%")
              actionn$="muted"
              akck+1
              AddElement(Actions())
              Actions()\IP=Clients()\IP
              Actions()\type=#MUTE
              
            Case #UNMUTE
              SendNetworkString(kclid,"UM#"+kcid+"#%")
              actionn$="unmuted"
              akck+1
              ResetList(Actions())
              While NextElement(Actions())
                If Actions()\IP=Clients()\IP And Actions()\type=#MUTE
                  DeleteElement(Actions())
                EndIf
              Wend
              
            Case #CIGNORE
              Clients()\ignore=1
              actionn$="ignored"
              akck+1
              
            Case #UNIGNORE
              Clients()\ignore=0
              actionn$="undignored"
              akck+1
              ResetList(Actions())
              While NextElement(Actions())
                If Actions()\IP=Clients()\IP And Actions()\type=#CIGNORE
                  DeleteElement(Actions())
                EndIf
              Wend
              
            Case #UNDJ
              Clients()\ignoremc=1
              actionn$="undj'd"
              akck+1
              AddElement(Actions())
              Actions()\IP=Clients()\IP
              Actions()\type=#UNDJ
              
            Case #DJ
              Clients()\ignoremc=0
              actionn$="dj'd"
              akck+1
              ResetList(Actions())
              While NextElement(Actions())
                If Actions()\IP=Clients()\IP And Actions()\type=#UNDJ
                  DeleteElement(Actions())
                EndIf
              Wend
              
            Case #GIMP
              Clients()\gimp=1
              actionn$="gimped"
              akck+1
              AddElement(Actions())
              Actions()\IP=Clients()\IP
              Actions()\type=#GIMP
              
            Case #UNGIMP
              Clients()\gimp=0
              actionn$="ungimped"
              akck+1
              ResetList(Actions())
              While NextElement(Actions())
                If Actions()\IP=Clients()\IP And Actions()\type=#GIMP
                  DeleteElement(Actions())
                EndIf
              Wend
              
            Case #SWITCH
              Debug "swkick$"
              Debug kick$
              Debug kclid
              actionn$="switched"              
              For scid=0 To CharacterNumber
                If param$=ReplaceString(Characters(scid)\name," ","_")
                  newchar=scid
                  Break
                EndIf
              Next
              If newchar<>-1
                Clients()\CID=newchar
                akck+1
                SendTarget(Str(Clients()\ClientID),"PV#"+Str(Clients()\AID)+"#CID#"+Str(newchar)+"#%",Server)
              Else
                Clients()\CID=-1 
                akck+1
                SendTarget(Str(Clients()\ClientID),"DONE#%",Server)
              EndIf
            Case #MOVE
              SwitchAreas(Clients(),param$,"")
              
          EndSelect
          UnlockMutex(ActionMutex)
        EndIf
      EndIf
    Else
      DeleteMapElement(Clients())
      actionn$+" whoopie "
      akck+1
    EndIf
  Wend
  UnlockMutex(ListMutex)
  Debug "akick$"
  Debug kick$
  WriteLog(actionn$+" "+kick$+", "+Str(akck)+" people died.",*usagePointer)
  rf=1
  ProcedureReturn akck
EndProcedure

;- Command Handler

Procedure HandleAOCommand(ClientID)
  StartProfiler()
  Define rawreceive$,subcommand$
  Define comm$,rline$
  Define length,start,akchar
  Define ClientID,char,coff
  Define msreply$
  Define i,ir,players,mdur
  Define mss$,kick$
  Define send,bar,hdbanned
  Define music,sentevi
  Define ctparam$
  Define bgcomm$
  Define narea$,everybody
  Define lock$
  Define pr$,ub$
  Define reply$
  Define dicemax,akck
  Define random$
  Define smes$
  Define sname$
  Define mcid$,hdlist$
  Define song$,arep$,status$
  Dim CPlayers(characternumber)
  
  If ClientID>0
    *usagePointer.Client=FindMapElement(Clients(),Str(ClientID))
    Debug "sc"
  ElseIf ClientID=-1
    *usagePointer.Client=@Server
    Debug "server"
  Else
    *usagePointer=0
    Debug "error"
  EndIf
  If *usagePointer    
    If Left(*usagePointer\last,1)="#"
      *usagePointer\last=Mid(*usagePointer\last,2)
      Debug *usagePointer\last
      Debug StringField(*usagePointer\last,1,"#")
      Debug StringField(*usagePointer\last,2,"#")
      *usagePointer\command=DecryptStr(HexToString(StringField(*usagePointer\last,1,"#")),key)
      rawreceive$=*usagePointer\last
      coff=6
    ElseIf Left(*usagePointer\last,1)="4" Or Left(*usagePointer\last,1)="3"
      *usagePointer\command=DecryptStr(HexToString(StringField(*usagePointer\last,1,"#")),key)
      rawreceive$=*usagePointer\last
      coff=6
    Else
      *usagePointer\command=StringField(*usagePointer\last,1,"#")
      rawreceive$=*usagePointer\last
      coff=4
    EndIf    
    Debug *usagePointer\command
    length=Len(rawreceive$)    
    
    If StringField(rawreceive$,2,"#")="chat"
      *usagePointer\command="MS"
    ElseIf Right(StringField(rawreceive$,2,"#"),4)=".mp3"
      *usagePointer\command="MC"
    ElseIf Left(*usagePointer\command,3)="GET"
      *usagePointer\command="GET"
    EndIf
    
    
    Debug rawreceive$
    Debug *usagePointer\command
    Select *usagePointer\command
      Case "wait"        
      Case "CH"
        SendTarget(Str(ClientID),"CHECK#%",*usagePointer)
      Case "MS"
        msreplayfix:
        
        nmes.ChatMessage
        Select *usagePointer\type
          Case #VNO
            nmes\char=StringField(rawreceive$,2,"#")
            nmes\emote=StringField(rawreceive$,3,"#")
            nmes\message=StringField(rawreceive$,4,"#")
            nmes\showname=StringField(rawreceive$,5,"#")
            nmes\background=StringField(rawreceive$,8,"#")
          Default
            ;MS#chat#<pre-emote>#<char>#<emote>#<mes>#<pos>#<sfx>#<zoom>#<cid>#<animdelay>#<objection-state>#<evi>#<cid>#<bling>#<color>#%%
            nmes\preemote=StringField(rawreceive$,3,"#")
            nmes\char=StringField(rawreceive$,4,"#")
            nmes\emote=StringField(rawreceive$,5,"#")
            nmes\message=StringField(rawreceive$,6,"#")
            If *usagePointer\pos=""
              nmes\position=StringField(rawreceive$,7,"#")
            Else
              nmes\position=*usagePointer\pos
            EndIf
            nmes\sfx=StringField(rawreceive$,8,"#")
            nmes\emotemod=Val(StringField(rawreceive$,9,"#"))
            nmes\animdelay=Val(StringField(rawreceive$,11,"#"))
            nmes\objmod=Val(StringField(rawreceive$,12,"#"))
            nmes\evidence=Val(StringField(rawreceive$,13,"#"))
            nmes\flip=Val(StringField(rawreceive$,14,"#"))
            nmes\realization=Val(StringField(rawreceive$,15,"#"))
            nmes\color=Val(StringField(rawreceive$,16,"#"))
        EndSelect
        If ReplayMode=0 Or *usagePointer\perm=#SERVER
          SendChatMessage(nmes,*usagePointer)
        Else
          Select Trim(nmes\message)
            Case "<"
              If ListIndex(PReplay())>0
                PreviousElement(PReplay())
                Server\last=PReplay()
                HandleAOCommand(-1)
              Else
                SendTarget("*","MS#chat#dolannormal#Dolan#dolannormal#START!#jud#1#2#"+Str(characternumber-1)+"#0#3#0#"+Str(characternumber-1)+"#0#"+Str(modcol)+"#%",Server)
              EndIf
            Case ">"
              Debug "next"
              If ListIndex(PReplay())<ListSize(PReplay())
                NextElement(PReplay())
                Server\last=PReplay()
                Debug PReplay()
                HandleAOCommand(-1)
              Else
                SendTarget("*","MS#chat#dolannormal#Dolan#dolannormal#FIN!#jud#1#2#"+Str(characternumber-1)+"#0#3#0#"+Str(characternumber-1)+"#0#"+Str(modcol)+"#%",Server)
              EndIf
            Case "Q"
              ReplayMode=0
            Default
              SendTarget("*","MS#chat#dolanangry#Dolan#dolanangry#EEK! Valid: <, >, Q#jud#1#2#"+Str(characternumber-1)+"#0#3#0#"+Str(characternumber-1)+"#0#"+Str(modcol)+"#%",Server)
          EndSelect
        EndIf
        
      Case "MC"
        replaymusicfix:
        If *usagePointer\perm=3
          Sendtarget("*","MC#"+Mid(rawreceive$,coff),*usagePointer)
        Else
          music=0
          LockMutex(musicmutex)
          ForEach Music()
            If StringField(rawreceive$,2,"#")=Music()\TrackName
              music=1
              mdur=Music()\Length
              Debug Music()\Length
              Break
            EndIf
          Next
          UnlockMutex(musicmutex)
          
          If music=1
            If Left(StringField(rawreceive$,2,"#"),1)=">"              
              SwitchAreas(*usagePointer,Mid(StringField(rawreceive$,2,"#"),2),"")              
            Else
              If *usagePointer\ignoremc=0 And *usagePointer\CID>=0 And *usagePointer\CID<=CharacterNumber
                If Characters(*usagePointer\CID)\dj
                  Debug mdur
                  areas(*usagePointer\area)\trackstart=ElapsedMilliseconds()
                  areas(*usagePointer\area)\trackwait=mdur
                  areas(*usagePointer\area)\track=StringField(rawreceive$,2,"#")
                  Sendtarget("Area"+Str(*usagePointer\area),"MC#"+StringField(rawreceive$,2,"#")+"#"+Str(*usagePointer\CID)+"#%",*usagePointer)
                  WriteLog("changed music to "+StringField(rawreceive$,2,"#"),*usagePointer)
                  WriteReplay(rawreceive$)
                EndIf
              EndIf
            EndIf
          Else
            *usagePointer\hack=1
            rf=1
            WriteLog("tried changing music to "+StringField(rawreceive$,2,"#"),*usagePointer)
          EndIf 
        EndIf
        
        ;- ooc commands
      Case "CT"
        send=0
        *usagePointer\last.s=""
        ctparam$=StringField(rawreceive$,3,"#")
        WriteLog("[OOC]"+StringField(rawreceive$,2,"#")+":"+ctparam$,*usagePointer)
        
        If *usagePointer\username=""
          *usagePointer\username=RemoveString(StringField(rawreceive$,2,"#"),"<dollar>")
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
                    Select *usagePointer\type
                      Case #VNO
                        SendTarget(Str(ClientID),"MODOK#%",Server)
                      Case #AOTWO
                        SendTarget(Str(ClientID),"MK#%",Server)
                    EndSelect
                    *usagePointer\perm=1
                    *usagePointer\ooct=1
                    rf=1
                  EndIf
                Case adminpass$
                  If adminpass$<>""
                    SendTarget(Str(ClientID),LoginReply$,Server)
                    Select *usagePointer\type
                      Case #VNO
                        SendTarget(Str(ClientID),"MODOK#%",Server)
                      Case #AOTWO
                        SendTarget(Str(ClientID),"MK#%",Server)
                    EndSelect
                    *usagePointer\perm=2
                    *usagePointer\ooct=1
                    rf=1
                  EndIf
              EndSelect
              send=0
              
            Case "/cmds"
              SendTarget(Str(ClientID),"CT#$HOST#help,cmds,login,g,pos,change,switch,online,area,evi,roll,pm,version,smokeweed#%",Server)
              If *usagePointer\perm
                SendTarget(Str(ClientID),"CT#$HOST#ip,bg,move,lock,(no)skip,play,hd,(un)ban,kick,disconnect,(un)mute,(un)ignore,(un)dj,(un)gimp#%",Server)
              EndIf
              If *usagePointer\perm>1
                SendTarget(Str(ClientID),"CT#$HOST#public,send,sendall,reload,toggle,decryptor,snapshot,stop,loadreplay#%",Server)
              EndIf
            Case "/ip"
              If *usagePointer\perm
                If *usagePointer\type=#AOTWO
                  ListIPSI(ClientID)
                Else
                  ListIP(ClientID)
                EndIf
                WriteLog("["+GetCharacterName(*usagePointer)+"] used /ip",*usagePointer)
              EndIf 
              
            Case "/bg"
              If *usagePointer\perm                            
                bgcomm$=Mid(ctparam$,5)
                areas(*usagePointer\area)\bg=bgcomm$
                Sendtarget("Area"+Str(*usagePointer\area),"BN#"+bgcomm$+"#%",*usagePointer)                      
              EndIf
              
            Case "/pos"
              npos$=Mid(ctparam$,6)
              If npos$="def" Or npos$="pro" Or npos$="hlp" Or npos$="hld" Or npos$="wit" Or npos$="jud"
                *usagePointer\pos=npos$
              Else
                *usagePointer\pos=""
              EndIf
              
            Case "/g"
              SendTarget("*","CT#[G]"+*usagePointer\username+"#"+Mid(StringField(rawreceive$,3,"#"),3)+"#%",*usagePointer)
              
            Case "/change"
              nchar$=Mid(ctparam$,9)
              For nch=0 To CharacterNumber
                If Characters(nch)\name=nchar$ And Characters(nch)\pw=""
                  If BlockTaken=1
                    LockMutex(ListMutex)
                    PushMapPosition(Clients())
                    ResetMap(Clients())
                    While NextMapElement(Clients())
                      If Clients()\CID=nch
                        If Clients()\area=*usagePointer\area
                          akchar=1
                          Break
                        Else
                          akchar=0
                        EndIf
                        If MultiChar=0
                          akchar=1
                          Break
                        EndIf
                      EndIf
                    Wend
                    PopMapPosition(Clients())
                    UnlockMutex(ListMutex)     
                  EndIf
                  If akchar=0 Or *usagePointer\CID=nch Or BlockTaken=0
                    SendTarget(Str(ClientID),"PV#"+Str(*usagePointer\AID)+"#CID#"+Str(nch)+"#%",Server)               
                    *usagePointer\CID=nch       
                    WriteLog("chose character: "+GetCharacterName(*usagePointer),*usagePointer)
                    SendTarget(Str(ClientID),"HP#1#"+Str(Areas(*usagePointer\area)\good)+"#%",Server)
                    SendTarget(Str(ClientID),"HP#2#"+Str(Areas(*usagePointer\area)\evil)+"#%",Server)
                  EndIf
                  Break
                  rf=1
                EndIf
              Next
              
            Case "/switch"
              If Mid(ctparam$,9)=""
                *usagePointer\cid=-1
                SendDone(*usagePointer)
              Else
                KickBan(StringField(ctparam$,2," "),StringField(ctparam$,3," "),#SWITCH,*usagePointer)
              EndIf
              
            Case "/move"
              KickBan(StringField(ctparam$,2," "),StringField(ctparam$,3," "),#MOVE,*usagePointer)
              
            Case "/online"
              players=0          
              LockMutex(ListMutex)
              PushMapPosition(Clients())
              ResetMap(Clients())
              While NextMapElement(Clients())
                If Clients()\CID>=0
                  players+1
                EndIf
              Wend
              UnlockMutex(ListMutex)
              SendTarget(Str(ClientID),"CT#$HOST#"+Str(players)+"/"+slots$+" characters online#%",Server)
              
            Case "/area"
              If *usagePointer\perm
                For ir=0 To AreaNumber-1
                  areas(ir)\players=0
                Next
                
                LockMutex(ListMutex)
                PushMapPosition(Clients())
                ResetMap(Clients())
                While NextMapElement(Clients())
                  If Clients()\area>=0
                    areas(Clients()\area)\players+1
                  EndIf
                Wend
                PopMapPosition(Clients())
                UnlockMutex(ListMutex)
              EndIf
              
              narea$=StringField(ctparam$,2," ")
              apass$=StringField(ctparam$,3," ")
              If narea$=""
                arep$="CT#$HOST#Areas:"
                For ir=0 To AreaNumber-1
                  If areas(ir)\hidden=0 Or *usagePointer\perm
                    arep$+#CRLF$
                    arep$=arep$+areas(ir)\name+": "+Str(areas(ir)\players)+" users"
                    If ir=*usagePointer\area
                      arep$+" (including you)"
                    EndIf
                    If areas(ir)\mlock
                      arep$+" super"
                    EndIf
                    If areas(ir)\lock
                      arep$+"locked"                      
                    EndIf
                  EndIf
                Next
                arep$+"#%"
                SendTarget(Str(ClientID),arep$,Server)
              Else                  
                SwitchAreas(*usagePointer,narea$,apass$)
              EndIf
              
            Case "/loadreplay"
              If *usagePointer\perm>1                  
                ReplayFile$="base/replays/"+Mid(ctparam$,13)
                If ReadFile(8, ReplayFile$)
                  Debug "loaded replay"
                  ClearList(PReplay())
                  ResetList(PReplay())
                  While Eof(8) = 0
                    rline$=ReadString(8)
                    AddElement(PReplay())
                    ReplayMode=1
                    PReplay()=rline$
                  Wend
                  ResetList(PReplay())
                  CloseFile(8)
                EndIf
              EndIf
              
            Case "/lock"
              If *usagePointer\area
                lock$=StringField(ctparam$,2," ")
                Select lock$
                  Case "0"
                    If areas(*usagePointer\area)\lock=*usagePointer\ClientID Or *usagePointer\perm>areas(*usagePointer\area)\mlock
                      areas(*usagePointer\area)\lock=0
                      areas(*usagePointer\area)\mlock=0
                      SendTarget(Str(ClientID),"CT#$HOST#area unlocked#%",Server)
                    EndIf
                  Case "1"
                    If *usagePointer\perm
                      areas(*usagePointer\area)\lock=*usagePointer\ClientID
                      areas(*usagePointer\area)\mlock=0
                      SendTarget(Str(ClientID),"CT#$HOST#area locked#%",Server)
                    EndIf
                  Case "2"
                    If *usagePointer\perm>1
                      areas(*usagePointer\area)\lock=*usagePointer\ClientID
                      areas(*usagePointer\area)\mlock=1
                      SendTarget(Str(ClientID),"CT#$HOST#area superlocked#%",Server)
                    EndIf
                  Default
                    pr$="CT#$HOST#area is "
                    If areas(*usagePointer\area)\lock=0
                      pr$+"not "
                    EndIf
                    SendTarget(Str(ClientID),pr$+"locked#%",Server)
                EndSelect
              Else
                SendTarget(Str(ClientID),"CT#$HOST#You can't lock the default area#%",Server)
              EndIf
              
            Case "/skip"
              If *usagePointer\perm
                *usagePointer\skip=1
              EndIf
              
            Case "/noskip"
              If *usagePointer\perm
                *usagePointer\skip=0
              EndIf
              
            Case "/toggle"
              If *usagePointer\perm
                status$="invalid"
                Select StringField(ctparam$,2," ")
                  Case "WTCE"
                    If rt
                      rt=0
                      status$="disabled"
                    Else
                      rt=1
                      status$="enabled"
                    EndIf
                  Case "LogHD"
                    If loghd
                      loghd=0
                      status$="disabled"
                    Else
                      loghd=1
                      status$="enabled"
                    EndIf
                  Case "ExpertLog"
                    If ExpertLog
                      ExpertLog=0
                      status$="disabled"
                    Else
                      ExpertLog=1
                      status$="enabled"
                    EndIf
                  Case "Threading"
                    If CommandThreading
                      CommandThreading=0
                      status$="disabled"
                    Else
                      CommandThreading=1
                      status$="enabled"
                    EndIf
                EndSelect
                SendTarget(Str(ClientID),"CT#$HOST#"+StringField(ctparam$,2," ")+" is "+status$+"#%",Server)
              EndIf
              
            Case "/decryptor"
              If *usagePointer\perm>1
                decryptor$=StringField(ctparam$,2," ")
                key=Val(DecryptStr(HexToString(decryptor$),322))
                SendTarget("*","decryptor#"+decryptor$+"#%",Server)
              EndIf
              
            Case "/snapshot"
              If *usagePointer\perm>1
                If CreateFile(33,"snap.txt")
                  LockMutex(ListMutex)
                  PushMapPosition(Clients())
                  ResetMap(Clients())
                  While NextMapElement(Clients())
                    WriteStringN(33,"Client "+Str(Clients()\ClientID))
                    WriteStringN(33,Clients()\IP)
                    WriteStringN(33,Str(Clients()\CID))
                    WriteStringN(33,Str(Clients()\perm))
                    WriteStringN(33,Str(Clients()\hack))
                    WriteStringN(33,Str(Clients()\area))
                    WriteStringN(33,Clients()\last)
                  Wend
                  PopMapPosition(Clients())
                  UnlockMutex(ListMutex)
                  LockMutex(ListMutex)
                  For sa=0 To areas
                    WriteStringN(33,"Area "+Str(sa))
                    WriteStringN(33,Areas(sa)\name)
                    WriteStringN(33,Areas(sa)\bg)
                    WriteStringN(33,Str(Areas(sa)\players))
                    WriteStringN(33,Str(Areas(sa)\lock))
                    WriteStringN(33,Str(Areas(sa)\mlock))
                    WriteStringN(33,Areas(sa)\track)
                    WriteStringN(33,Str(Areas(sa)\trackwait))
                  Next
                  CloseFile(33)
                EndIf
              EndIf
              
            Case "/smokeweed"
              reply$="CT#stonedDiscord#where da weed at#%"
              WriteLog("smoke weed everyday",*usagePointer)
              
            Case "/help"
              SendTarget(Str(ClientID),"CT#$HOST#Check https://github.com/stonedDiscord/serverD/blob/master/README.md#%",Server)
              
            Case "/public"
              Debug ctparam$
              If StringField(ctparam$,2," ")=""
                pr$="CT#$HOST#server is "
                If public=0
                  pr$+"not "
                EndIf
                SendTarget(Str(ClientID),pr$+"public#%",Server)
              Else
                If *usagePointer\perm>1
                  public=Val(StringField(ctparam$,2," "))
                  If public
                    msthread=CreateThread(@MasterAdvert(),Port)
                    SendTarget(Str(ClientID),"CT#$HOST# published server#%",Server)
                  EndIf
                  CompilerIf #CONSOLE=0
                    SetGadgetState(#CheckBox_MS,public)
                  CompilerEndIf
                EndIf
              EndIf
              
            Case "/evi"                      
              SendTarget(Str(ClientID),"MS#chat#dolannormal#Dolan#dolannormal#"+StringField(ctparam$,2," ")+"#jud#1#0#"+Str(characternumber-1)+"#0#0#"+StringField(ctparam$,2," ")+"#"+Str(characternumber-1)+"#0#"+Str(modcol)+"#%",Server)                         
              
            Case "/roll"                     
              If Len(ctparam$)<=6
                dicemax=6
              Else
                dicemax=Val(StringField(ctparam$,2," "))
              EndIf
              If dicemax<=1 Or dicemax>9999
                dicemax=6
              EndIf
              If OpenCryptRandom()
                random$=Str(CryptRandom(dicemax-1)+1)
                CloseCryptRandom()
              Else
                random$=Str(Random(dicemax,1))
              EndIf              
              Sendtarget("Area"+Str(*usagePointer\area),"CT#$HOST#"+GetCharacterName(*usagePointer)+" rolled "+random$+" of "+Str(dicemax)+"#%",Server)
              
            Case "/pm"
              SendTarget(StringField(ctparam$,2," "),"CT#PM "+*usagePointer\username+" to You#"+Mid(ctparam$,6+Len(StringField(ctparam$,2," ")))+"#%",Server)
              SendTarget(Str(ClientID),"CT#PM You to "+StringField(ctparam$,2," ")+"#"+Mid(ctparam$,6+Len(StringField(ctparam$,2," ")))+"#%",Server)
              
            Case "/send"  
              If *usagePointer\perm>1
                sname$=StringField(ctparam$,2," ")
                Debug sname$
                smes$=Mid(ctparam$,8+Len(sname$),Len(ctparam$)-6)
                smes$=Escape(smes$)
                SendTarget(sname$,smes$,Server)
              EndIf
              
            Case "/sendall"
              If *usagePointer\perm
                smes$=Mid(ctparam$,10)
                smes$=Escape(smes$)
                SendTarget("*",smes$,Server)
              EndIf
              
            Case "/reload"
              If *usagePointer\perm>1
                LoadSettings(1)
                SendTarget(Str(ClientID),"CT#$HOST#serverD reloaded#%",Server)
              EndIf
              
            Case "/play"
              If *usagePointer\perm                
                song$=Right(ctparam$,Len(ctparam$)-6)
                SendTarget("Area"+Str(*usagePointer\area),"MC#"+song$+"#"+Str(*usagePointer\CID)+"#%",*usagePointer)                
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
                    If IPbans()\banned=ub$
                      DeleteElement(IPbans())
                    Else
                      WriteStringN(2,IPbans()\banned+"#"+IPbans()\reason+"#"+Str(IPbans()\time)+"#"+Str(IPbans()\type))
                    EndIf
                  Next
                  CloseFile(2)                                
                EndIf
                
                If CreateFile(2,"base/HDbanlist.txt")
                  ForEach HDbans()
                    If HDbans()\banned=ub$
                      DeleteElement(HDbans())
                    Else
                      WriteStringN(2,HDbans()\banned+"#"+HDbans()\reason+"#"+Str(HDbans()\time)+"#"+Str(HDbans()\type))
                    EndIf
                  Next
                  CloseFile(2)                                
                EndIf
              EndIf
              
            Case "/stop"
              If *usagePointer\perm>1
                public=0
                WriteLog("stopping server...",*usagePointer)
                Quit=1
              EndIf
              
            Case "/kick"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,7),StringField(ctparam$,3," "),#KICK,*usagePointer)
                SendTarget(Str(ClientID),"CT#$HOST#kicked "+Str(akck)+" clients#%",Server) 
              EndIf
              
            Case "/disconnect"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,13),StringField(ctparam$,3," "),#DISCO,*usagePointer)
                SendTarget(Str(ClientID),"CT#$HOST#disconnected "+Str(akck)+" clients#%",Server) 
              EndIf
              
            Case "/ban"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,6),StringField(ctparam$,3," "),#BAN,*usagePointer)
                SendTarget(Str(ClientID),"CT#$HOST#banned "+Str(akck)+" clients#%",Server)
              EndIf
              
            Case "/mute"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,7),StringField(ctparam$,3," "),#MUTE,*usagePointer)
                SendTarget(Str(ClientID),"CT#$HOST#muted "+Str(akck)+" clients#%",Server)
              EndIf
              
              
            Case "/unmute"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,9),StringField(ctparam$,3," "),#UNMUTE,*usagePointer)
                SendTarget(Str(ClientID),"CT#$HOST#unmuted "+Str(akck)+" clients#%",Server)
              EndIf
              
              
            Case "/ignore"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,9),StringField(ctparam$,3," "),#CIGNORE,*usagePointer)
                SendTarget(Str(ClientID),"CT#$HOST#muted "+Str(akck)+" clients#%",Server)
              EndIf
              
              
            Case "/unignore"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,11),StringField(ctparam$,3," "),#UNIGNORE,*usagePointer)
                SendTarget(Str(ClientID),"CT#$HOST#unmuted "+Str(akck)+" clients#%",Server)
              EndIf
              
              
            Case "/undj"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,7),StringField(ctparam$,3," "),#UNDJ,*usagePointer)
                SendTarget(Str(ClientID),"CT#$HOST#muted "+Str(akck)+" clients#%",Server)
              EndIf
              
              
            Case "/dj"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,5),StringField(ctparam$,3," "),#DJ,*usagePointer)
                SendTarget(Str(ClientID),"CT#$HOST#unmuted "+Str(akck)+" clients#%",Server)
              EndIf
              
            Case "/gimp"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,7),StringField(ctparam$,3," "),#GIMP,*usagePointer)
                SendNetworkString(ClientID,"CT#$HOST#gimped "+Str(akck)+" clients#%")
              EndIf
              
            Case "/ungimp"
              If *usagePointer\perm
                akck=KickBan(Mid(ctparam$,9),StringField(ctparam$,3," "),#UNGIMP,*usagePointer)
                SendNetworkString(ClientID,"CT#$HOST#ungimped "+Str(akck)+" clients#%")
              EndIf
              
            Case "/version"
              SendTarget(Str(ClientID),"CT#$HOST#serverD "+version$+"#%",Server)
              
          EndSelect
        Else
          *usagePointer\last.s=rawreceive$
          SendTarget("Area"+Str(*usagePointer\area),"CT#"+*usagePointer\username+"#"+StringField(rawreceive$,3,"#")+"#%",*usagePointer)
          CompilerIf #CONSOLE=0
            AddGadgetItem(#ListIcon_2,-1,StringField(rawreceive$,2,"#")+Chr(10)+StringField(rawreceive$,3,"#"))
            Debug "guys"
            SetGadgetItemData(#ListIcon_2,CountGadgetItems(#ListIcon_2)-1,*usagePointer\ClientID)
          CompilerEndIf
        EndIf
        ;- Fuck OOC
        
      Case "HP" 
        bar=Val(StringField(rawreceive$,3,"#"))
        If *usagePointer\CID>=0
          If bar>=0 And bar<=10
            WriteLog("["+GetCharacterName(*usagePointer)+"] changed the bars",*usagePointer)
            If StringField(rawreceive$,2,"#")="1"
              Areas(*usagePointer\area)\good=bar
              SendTarget("Area"+Str(*usagePointer\area),"HP#1#"+Str(Areas(*usagePointer\area)\good)+"#%",*usagePointer)
            ElseIf StringField(rawreceive$,2,"#")="2"
              Areas(*usagePointer\area)\evil=bar
              SendTarget("Area"+Str(*usagePointer\area),"HP#2#"+Str(Areas(*usagePointer\area)\evil)+"#%",*usagePointer)
            EndIf
            send=1
          Else
            WriteLog("["+GetCharacterName(*usagePointer)+"] fucked up the bars",*usagePointer)
            *usagePointer\hack=1
            rf=1
          EndIf
        EndIf
        
      Case "CC"
        akchar=0
        char=Val(StringField(rawreceive$,3,"#"))
        If char>=0 And char<=characternumber
          If BlockTaken=1
            LockMutex(ListMutex)
            PushMapPosition(Clients())
            ResetMap(Clients())
            While NextMapElement(Clients())
              If Clients()\CID=char
                If Clients()\area=*usagePointer\area
                  akchar=1
                  Break
                Else
                  akchar=0
                EndIf
                If MultiChar=0
                  akchar=1
                  Break
                EndIf
              EndIf
            Wend
            PopMapPosition(Clients())
            UnlockMutex(ListMutex)     
          EndIf
          If *usagePointer\perm Or Characters(char)\pw=""
            If akchar=0 Or *usagePointer\CID=char Or BlockTaken=0
              SendTarget(Str(ClientID),"PV#"+Str(*usagePointer\AID)+"#CID#"+Str(char)+"#%",Server)               
              *usagePointer\CID=char                
              WriteLog("chose character: "+GetCharacterName(*usagePointer),*usagePointer)
              SendTarget(Str(ClientID),"HP#1#"+Str(Areas(*usagePointer\area)\good)+"#%",Server)
              SendTarget(Str(ClientID),"HP#2#"+Str(Areas(*usagePointer\area)\evil)+"#%",Server)
              If (MOTDevi And Characters(char)\evinumber<2 ) Or motd$<>"Take that!"
                SendTarget(Str(ClientID),"MS#chat#dolannormal#Dolan#dolannormal#"+motd$+"#jud#0#0#"+Str(characternumber-1)+"#0#0#"+Str(MOTDevi)+"#"+Str(characternumber-1)+"#0#"+Str(modcol)+"#%",Server)
              EndIf
              rf=1
            EndIf          
          EndIf
        EndIf
        
      Case "Req"
        akchar=0
        start=Val(StringField(rawreceive$,2,"#"))-1
        If start<characternumber And start>=0
          If BlockTaken=1
            LockMutex(ListMutex)
            PushMapPosition(Clients())
            ResetMap(Clients())
            While NextMapElement(Clients())
              If Clients()\CID=start
                If Clients()\area=*usagePointer\area
                  akchar=1
                  Break
                Else
                  akchar=0
                EndIf
                If MultiChar=0
                  akchar=1
                  Break
                EndIf
              EndIf
            Wend
            PopMapPosition(Clients())
            UnlockMutex(ListMutex)     
          EndIf
          If akchar=0
            If StringField(rawreceive$,3,"#")=Characters(start)\pw
              *usagePointer\CID=start
              SendTarget(Str(ClientID),"Allowed#"+GetCharacterName(*usagePointer)+"#%",Server)
              SendTarget(Str(ClientID),"YI#0#"+Str(*usagePointer\Inventory[0])+"#%",Server)
              WriteLog("chose character: "+GetCharacterName(*usagePointer),*usagePointer)
              For ac=0 To areas
                If Areas(ac)\players>0
                  SendTarget(Str(ClientID),"RaC#"+Str(ac+1)+"#"+Areas(ac)\players+"#%",Server)
                EndIf
              Next
              rf=1
            Else
              SendTarget(Str(ClientID),"WP#%",Server)
            EndIf
          Else
            SendTarget(Str(ClientID),"TKN#%",Server)
          EndIf
        EndIf
        
      Case "UC"
        password$=StringField(rawreceive$,3,"#")
        akchar=0
        char=Val(StringField(rawreceive$,2,"#"))
        If char>=0 And char<=characternumber
          If BlockTaken=1
            LockMutex(ListMutex)
            PushMapPosition(Clients())
            ResetMap(Clients())
            While NextMapElement(Clients())
              If Clients()\CID=char
                If Clients()\area=*usagePointer\area
                  akchar=1
                  Break
                Else
                  akchar=0
                EndIf
                If MultiChar=0
                  akchar=1
                  Break
                EndIf
              EndIf
            Wend
            PopMapPosition(Clients())
            UnlockMutex(ListMutex)     
          EndIf
          If akchar=0
            If Characters(char)\pw=password$
              *usagePointer\CID=char
              SendTarget(Str(ClientID),"OC#"+Str(char)+"#0#%",Server)
              WriteLog("chose character: "+GetCharacterName(*usagePointer),*usagePointer)
            ElseIf password$=oppass$
              *usagePointer\CID=char
              *usagePointer\perm=#MOD
              SendTarget(Str(ClientID),"OC#"+Str(char)+"#3#%",Server)
              SendTarget(Str(ClientID),"MK#%",Server)
              WriteLog("chose character: "+GetCharacterName(*usagePointer)+" and logged in as mod",*usagePointer)
            ElseIf password$=adminpass$
              *usagePointer\CID=char
              *usagePointer\perm=#ADMIN
              SendTarget(Str(ClientID),"OC#"+Str(char)+"#3#%",Server)
              SendTarget(Str(ClientID),"MK#%",Server)
              WriteLog("chose character: "+GetCharacterName(*usagePointer)+" and logged in as admin",*usagePointer)
            Else
              SendTarget(Str(ClientID),"OC#"+Str(char)+"#2#%",Server)
            EndIf
          Else
            SendTarget(Str(ClientID),"OC#"+Str(char)+"#1#%",Server)
          EndIf
        EndIf
        
      Case "AA"
        SwitchAreas(*usagePointer,StringField(rawreceive$,2,"#"),StringField(rawreceive$,3,"#"))
        
      Case "RT"
        If *usagePointer\CID>=0
          If rt=1
            Sendtarget("Area"+Str(*usagePointer\area),"RT#"+Mid(rawreceive$,coff),*usagePointer)
          EndIf
        Else
          *usagePointer\hack=1
          rf=1
        EndIf
        
        WriteLog("["+GetCharacterName(*usagePointer)+"] WT/CE button",*usagePointer)
        
      Case "askchaa" ;what is left to load
        *usagePointer\cconnect=1
        If CharacterNumber>100
          If *usagePointer\type>=#AOA
            SendTarget(Str(ClientID),"SI#"+Str(characternumber)+"#"+Str(EviNumber)+"#"+Str(tracks)+"#%",Server)
          Else
            SendTarget(Str(ClientID),"SI#100#"+Str(EviNumber)+"#"+Str(tracks)+"#%",Server)
          EndIf
        Else
          SendTarget(Str(ClientID),"SI#"+Str(characternumber)+"#"+Str(EviNumber)+"#"+Str(tracks)+"#%",Server)
        EndIf
        
      Case "askchar2" ; character list
        SendTarget(Str(ClientID),ReadyChar(0),Server)
        *usagePointer\type=#VANILLA
        
      Case "RC"
        SendTarget(Str(ClientID),newcready$,Server)
        Dim APlayers(characternumber)
        send$="TC"
        LockMutex(ListMutex)
        PushMapPosition(Clients())
        ResetMap(Clients())
        While NextMapElement(Clients())
          If Clients()\CID>=0 And Clients()\CID <= characternumber
            If Clients()\area=*usagePointer\area
              APlayers(Clients()\CID)=1
            EndIf
          EndIf
        Wend
        PopMapPosition(Clients())
        UnlockMutex(ListMutex)
        For sentchar=0 To characternumber
          If APlayers(sentchar)=1 And Characters(sentchar)\pw<>""
            send$ = send$ + "#3"
          ElseIf APlayers(sentchar)=1
            send$ = send$ + "#1"
          ElseIf Characters(sentchar)\pw<>""
            send$ = send$ + "#2"
          Else
            send$ = send$ + "#0"
          EndIf
        Next
        send$ = send$ + "#%"
        SendTarget(Str(*usagePointer\ClientID),send$,Server)
        
      Case "RM"
        SendTarget(Str(ClientID),newmready$,Server)
        SendTarget(Str(ClientID),"DONE#%",Server)
        
      Case "RA"
        SendTarget(Str(ClientID),newaready$,Server)
        send$="TA"
        For carea=0 To AreaNumber
          send$ = send$ + "#"+Str(areas(carea)\players)
        Next
        send$ = send$ + "#%"
        SendTarget(Str(*usagePointer\ClientID),send$,Server)
        
      Case "AN" ; character list
        start=Val(StringField(rawreceive$,2,"#"))
        If start*10<characternumber And start>=0 ;And ( start*10<100 Or *usagePointer\type>4 )
          Debug "huh"
          SendTarget(Str(ClientID),ReadyChar(start),Server)
        ElseIf EviNumber>0
          SendTarget(Str(ClientID),ReadyEvidence(1),Server)
        Else
          SendTarget(Str(ClientID),ReadyMusic(0),Server)
        EndIf
        
        
      Case "AE" ; evidence list
        Debug Evidences(0)\name
        sentevi=Val(StringField(rawreceive$,2,"#"))
        If sentevi<EviNumber And sentevi>=0          
          SendTarget(Str(ClientID),ReadyEvidence(sentevi+1),Server)
        Else
          SendTarget(Str(ClientID),ReadyMusic(0),Server)
        EndIf
        
      Case "AM" ;music list
        start=Val(StringField(rawreceive$,2,"#"))
        If start<=musicpage And start>=0 
          SendTarget(Str(ClientID),ReadyMusic(start),Server)
        Else ;MUSIC DONE
          SendDone(*usagePointer)
        EndIf
        
      Case "RCD" ; character list
        start=Val(StringField(rawreceive$,2,"#"))-1
        *usagePointer\type=#VNO
        If start=0
          SendTarget(Str(ClientID),"PC#"+Str(players)+"#"+Str(characternumber)+"#"+Str(characternumber)+"#"+Str(tracks)+"#"+Str(Aareas)+"#"+Str(itemamount)+"#%",Server)
        EndIf
        If start<characternumber And start>=0
          sendstring$="CAD#"+Str(start+1)+"#"+Characters(start)\name+"#"+Str(0)
          start+1
          If start<characternumber
            sendstring$+"#"+Str(start+1)+"#"+Characters(start)\name+"#"+Str(0)
          EndIf
          SendTarget(Str(ClientID),sendstring$+"#%",Server)
        Else
          SendTarget(Str(ClientID),ReadyVMusic(0),Server)
        EndIf
        
        
      Case "RMD" ;music list
        start=Val(StringField(rawreceive$,2,"#"))-1
        If start<=tracks-1 And start>=0
          SendTarget(Str(ClientID),ReadyVMusic(start),Server)
        Else
          SendTarget(Str(ClientID),"AD#1#" + Areas(0)\name + "#"+Str(Areas(0)\players)+"#"+ Areas(0)\bg + "##%",Server)
        EndIf
        
      Case "RAD" ; area list
        start=Val(StringField(rawreceive$,2,"#"))-1
        If start<=AreaNumber And start>=0
          If areas(start)\pw<>""
            passworded$="LOCK"
          Else
            passworded$=""
          EndIf
          Readyv$ = "AD#" + Str(start+1) + "#" + Areas(start)\name + "#0#"+ Areas(start)\bg + "#"+passworded$ + "#%"
          SendTarget(Str(ClientID),Readyv$,Server)        
        ElseIf itemamount>0
          SendTarget(Str(ClientID),ReadyVItem(0),Server)
        Else
          SendTarget(Str(ClientID),"LCA#"+*usagePointer\username+"#$NO#%",Server)
        EndIf
        
      Case "ITD" ; item list
        start=Val(StringField(rawreceive$,2,"#"))-1
        If start<=itemamount-1 And start>=0          
          SendTarget(Str(ClientID),ReadyVItem(start),Server)
        Else
          SendTarget(Str(ClientID),"LCA#"+*usagePointer\username+"#$NO#%",Server)
        EndIf
        
      Case "HI" ;what is this server
        hdbanned=0
        *usagePointer\HD = StringField(rawreceive$,2,"#")
        WriteLog("HdId="+*usagePointer\HD,*usagePointer)
        *usagePointer\sHD = 1
        
        If loghd
          OpenFile(8,"base/hd.txt")
          WriteStringN(8,*usagePointer\IP+","+*usagePointer\HD)
          CloseFile(8)
        EndIf
        
        ForEach SDBans()
          Debug *usagePointer\HD
          If *usagePointer\HD = SDbans()\banned Or *usagePointer\IP=SDBans()\banned
            SendTarget(Str(ClientID),"BD#%",Server)
            LockMutex(ListMutex)
            CloseNetworkConnection(ClientID)
            DeleteMapElement(Clients(),Str(ClientID))
            UnlockMutex(ListMutex)
            hdbanned=1
          EndIf
        Next
        If hdbanned=0
          ForEach HDbans()
            If *usagePointer\HD = HDbans()\banned
              WriteLog("HD: "+*usagePointer\HD+" is banned, reason: "+HDbans()\reason,*usagePointer)
              SendTarget(Str(ClientID),"BD#%",Server)
              LockMutex(ListMutex)
              CloseNetworkConnection(ClientID)
              DeleteMapElement(Clients(),Str(ClientID))
              UnlockMutex(ListMutex)
              hdbanned=1
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
          
          If StringField(rawreceive$,4,"#")<>""
            *usagePointer\type=#AOTWO
          EndIf
          SendTarget(Str(ClientID),"HI#serverD#"+version$+"#%",Server)
          
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
          
          SendTarget(Str(ClientID),"PN#"+Str(players)+"#"+slots$+"#%",Server)
        EndIf
        rf=1
        
        
      Case "DC"
        If areas(*usagePointer\area)\lock=ClientID
          areas(*usagePointer\area)\lock=0
          areas(*usagePointer\area)\mlock=0
        EndIf
        *usagePointer\CID=-1
        *usagePointer\ignore=1
        
      Case "FC"
        *usagePointer\CID=-1
        SendTarget(Str(*usagePointer\ClientID),"DONE#%",Server)
        WriteLog("freed char",*usagePointer)
        
      Case "Change"
        *usagePointer\CID=-1
        WriteLog("freed char",*usagePointer)
        
      Case "CA"
        If *usagePointer\perm
          If CommandThreading
            CreateThread(@ListIP(),ClientID)
          Else
            ListIP(ClientID)
          EndIf
          WriteLog("["+GetCharacterName(*usagePointer)+"] used /ip (clientside)",*usagePointer)
        EndIf 
        
      Case "opKICK"
        If *usagePointer\perm
          akck=KickBan(StringField(rawreceive$,2,"#"),"",#KICK,*usagePointer)
          SendTarget(Str(ClientID),"CT#$HOST#kicked "+Str(akck)+" clients#%",Server)
        EndIf
        WriteLog("["+GetCharacterName(*usagePointer)+"] used opKICK",*usagePointer)
        
      Case "opBAN"
        If *usagePointer\perm
          akck=KickBan(StringField(rawreceive$,2,"#"),"",#BAN,*usagePointer)
          SendTarget(Str(ClientID),"CT#$HOST#banned "+Str(akck)+" clients#%",Server)
        EndIf
        WriteLog("["+GetCharacterName(*usagePointer)+"] used opBAN",*usagePointer)
        
      Case "opMUTE"
        If *usagePointer\perm
          akck=KickBan(StringField(rawreceive$,2,"#"),"",#MUTE,*usagePointer)
          SendTarget(Str(ClientID),"CT#$HOST#muted "+Str(akck)+" clients#%",Server)
        EndIf
        WriteLog("["+GetCharacterName(*usagePointer)+"] used opMUTE",*usagePointer)
        
      Case "opunMUTE"
        If *usagePointer\perm
          akck=KickBan(StringField(rawreceive$,2,"#"),"",#UNMUTE,*usagePointer)
          SendTarget(Str(ClientID),"CT#$HOST#unmuted "+Str(akck)+" clients#%",Server)
        EndIf
        WriteLog("["+GetCharacterName(*usagePointer)+"] used opunMUTE",*usagePointer)
        
      Case "VERSION"
        SendTarget(Str(ClientID),"CT#$HOST#"+version$+"#%",Server)
        
      Case "ZZ"
        If *usagePointer\CID>=0
          WriteLog("called mod",*usagePointer)
        EndIf
        LockMutex(ListMutex)  
        ResetMap(Clients())
        While NextMapElement(Clients())
          If Clients()\perm
            SendTarget(Str(Clients()\ClientID),"ZZ#"+*usagePointer\IP+" in "+GetAreaName(*usagePointer)+"#%",*usagePointer)  
          Else
            SendTarget(Str(Clients()\ClientID),"ZZ#someone in "+GetAreaName(*usagePointer)+"#%",*usagePointer)  
          EndIf
        Wend   
        UnlockMutex(ListMutex)
        CompilerIf #WEB
        Case "GET"
          *usagePointer\type=#WEBSOCKET
          RequestedFile$=StringField(StringField(rawreceive$,2," "),1,"?")
          Debug "rfile"
          Debug RequestedFile$
          If RequestedFile$ = ""
            RequestedFile$ = "index.html"
          EndIf
          
          If ReadFile(0, "cbase/"+RequestedFile$)
            
            FileLength = Lof(0)
            ContentType$ = MIME(RequestedFile$)
            RFileDate=GetFileDate("cbase/"+RequestedFile$,#PB_Date_Modified)
            RHeader$="HTTP/1.0 200 OK"+#CRLF$+"Date: "+DayInText(RFileDate)+", "+Day(RFileDate)+" "+MonthInText(RFileDate)+" "+FormatDate("%yyyy %hh:%ii:%ss",RFileDate)+" GMT"+#CRLF$+"Content-Type: "+ContentType$+#CRLF$+"Content-Length: "+Str(FileLength)+#CRLF$+#CRLF$
            *FileBuffer   = AllocateMemory(FileLength+Len(RHeader$)+20)
            HLength=PokeS(*FileBuffer,RHeader$)  
            *BufferOffset = *FileBuffer+HLength
            WriteLog(ip$+" requested file "+RequestedFile$,Server)
            ReadData(0, *BufferOffset, FileLength)
            Debug "headerlength"
            Debug HLength
            CloseFile(0)
            Debug PeekS(*FileBuffer, HLength+FileLength)
            SendNetworkData(ClientID, *FileBuffer, HLength+FileLength)
            FreeMemory(*FileBuffer)
          EndIf     
        CompilerEndIf
      Default
        WriteLog(rawreceive$,*usagePointer)
    EndSelect
  EndIf
  StopProfiler()
EndProcedure

;- Network Thread
Procedure Network(var)
  Define SEvent,ClientID,send,length
  Define ip$,rawreceive$,sc
  Define *usagePointer.Client
  
  SEvent = NetworkServerEvent()
  
  Select SEvent
    Case 0
      Delay(LagShield)
      
    Case #PB_NetworkEvent_Disconnect
      ClientID = EventClient() 
      RemoveDisconnect(ClientID)
      
    Case #PB_NetworkEvent_Connect
      ClientID = EventClient()
      cType=0
      If ClientID
        send=1
        ip$=IPString(GetClientIP(ClientID))
        
        ForEach IPbans()
          If Left(ip$,Len(IPbans()\banned)) = IPbans()\banned
            send=0
            WriteLog("IP: "+ip$+" is banned, reason: "+IPbans()\reason,Server)
            CloseNetworkConnection(ClientID)                   
            Break
          EndIf
        Next 
        
        CompilerIf #WEB
          Delay(100)
          length=ReceiveNetworkData(ClientID, *Buffer, 2048)
          Debug "eaoe"
          Debug length
          If length<>-1
            Debug "wotf"
            rawreceive$=PeekS(*Buffer,length)
            Debug rawreceive$
            If ExpertLog
              WriteLog(rawreceive$,Clients())
            EndIf
            If length>=0 And Left(rawreceive$,3)="GET"
              cType=#WEBSOCKET
              Debug "get request"
              For i = 1 To CountString(rawreceive$, #CRLF$)
                headeririda$ = StringField(rawreceive$, i, #CRLF$)
                headeririda$ = RemoveString(headeririda$, #CR$)
                headeririda$ = RemoveString(headeririda$, #LF$)
                If Left(headeririda$, 3) = "GET"
                  Debug "getline"
                  RequestedFile$=StringField(StringField(headeririda$,2," "),1,"?")
                  Debug "rfile"
                  Debug RequestedFile$
                  If RequestedFile$ = ""
                    Break
                  EndIf
                  
                  If ReadFile(0, "cbase/"+RequestedFile$)
                    
                    FileLength = Lof(0)
                    
                    ContentType$=MIME(RequestedFile$)
                    RFileDate=GetFileDate("cbase/"+RequestedFile$,#PB_Date_Modified)
                    RHeader$="HTTP/1.0 200 OK"+#CRLF$+"Date: "+DayInText(RFileDate)+", "+Day(RFileDate)+" "+MonthInText(RFileDate)+" "+FormatDate("%yyyy %hh:%ii:%ss",RFileDate)+" GMT"+#CRLF$+"Content-Type: "+ContentType$+#CRLF$+"Content-Length: "+Str(FileLength)+#CRLF$+#CRLF$
                    *FileBuffer   = AllocateMemory(FileLength+Len(RHeader$)+20)
                    HLength=PokeS(*FileBuffer,RHeader$)  
                    *BufferOffset = *FileBuffer+HLength
                    WriteLog(ip$+" requested file "+RequestedFile$,Server)
                    ReadData(0, *BufferOffset, FileLength)
                    Debug "headerlength"
                    Debug HLength
                    CloseFile(0)
                    Debug PeekS(*FileBuffer, HLength+FileLength)
                    SendNetworkData(ClientID, *FileBuffer, HLength+FileLength)
                    FreeMemory(*FileBuffer)
                    CloseNetworkConnection(ClientID)
                    send=0
                  EndIf
                EndIf
                If Left(headeririda$, 17) = "Sec-WebSocket-Key"
                  wkey$ = Right(headeririda$, Len(headeririda$) - 19)
                  Debug wkey$
                  rkey$ = SecWebsocketAccept(wkey$)
                  Debug rkey$
                  vastus$ = "HTTP/1.1 101 Switching Protocols" + #CRLF$
                  vastus$ = vastus$ + "Connection: Upgrade"+ #CRLF$
                  vastus$ = vastus$ + "Sec-WebSocket-Accept: " + rkey$ + #CRLF$
                  vastus$ = vastus$ + "Server: serverD "+version$ + #CRLF$
                  vastus$ = vastus$ + "Upgrade: websocket"+ #CRLF$ + #CRLF$
                  Debug vastus$
                  send=1
                  SendNetworkString(ClientID, vastus$)
                EndIf
              Next
            EndIf
          Else
            SendNetworkString(ClientID,"decryptor#"+decryptor$+"#%")
          EndIf
        CompilerElse
          SendNetworkString(ClientID,"decryptor#"+decryptor$+"#%")
        CompilerEndIf
        
        If send
          
          LockMutex(ListMutex)
          Clients(Str(ClientID))\ClientID = ClientID
          Clients()\IP = ip$
          Clients()\AID=PV
          PV+1
          Clients()\CID=-1
          Clients()\hack=0
          Clients()\perm=0
          ForEach HDmods()
            If ip$ = HDmods()
              Clients()\perm=1
            EndIf
          Next
          Clients()\area=0
          areas(0)\players+1
          Clients()\ignore=0
          Clients()\judget=0
          Clients()\ooct=0
          Clients()\gimp=0
          Clients()\ignoremc=0
          Clients()\type=cType
          Clients()\username=""
          
          LockMutex(ActionMutex)
          ResetList(Actions())
          While NextElement(Actions())
            If Actions()\IP=ip$
              Select Actions()\type
                Case #UNDJ
                  Clients()\ignoremc=1
                Case #GIMP
                  Clients()\gimp=1
              EndSelect
            EndIf
          Wend
          UnlockMutex(ActionMutex)
          
          WriteLog("CLIENT CONNECTED ",Clients())
          CompilerIf #CONSOLE=0
            AddGadgetItem(#Listview_0,-1,ip$,Icons(0))
          CompilerEndIf
          If ListSize(Plugins())
            ResetList(Plugins())
            While NextElement(Plugins())
              pStat=#NODATA
              CallFunctionFast(Plugins()\gcallback,#CONN)    
              CallFunctionFast(Plugins()\rawfunction,Clients())
            Wend
          EndIf
          UnlockMutex(ListMutex)
        EndIf
      EndIf
      
    Case #PB_NetworkEvent_Data ;//////////////////////////Data
      ClientID = EventClient()
      *usagePointer.Client=FindMapElement(Clients(),Str(ClientID))
      If *usagePointer
        length=ReceiveNetworkData(ClientID, *Buffer, 1024)
        If length
          rawreceive$=PeekS(*Buffer,length)
          Debug rawreceive$
          CompilerIf #WEB
            If *usagePointer\type=#WEBSOCKET And WebSockets              
              Ptr = 0
              Byte.a = PeekA(*Buffer + Ptr)
              If Byte & %10000000
                Fin = #True
              Else
                Fin = #False
              EndIf
              Opcode = Byte & %00001111
              Ptr = 1
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
                  RemoveDisconnect(ClientID)
              EndSelect
            EndIf
          CompilerEndIf
          
          sc=1
          While StringField(rawreceive$,sc,"%")<>""
            subcommand$=StringField(rawreceive$,sc,"%")+"%"
            
            subcommand$=ValidateChars(subcommand$)
            length=Len(subcommand$)
            
            If ExpertLog
              WriteLog(subcommand$,*usagePointer)
            EndIf
            
            If ReplayMode=1 Or Not *usagePointer\last.s=subcommand$ And *usagePointer\ignore=0 
              *usagePointer\last.s=subcommand$
              If CommandThreading
                CreateThread(@HandleAOCommand(),ClientID)
              Else
                HandleAOCommand(ClientID)
              EndIf
              If ListSize(Plugins())
                ResetList(Plugins())
                While NextElement(Plugins())
                  pStat=#NODATA
                  CallFunctionFast(Plugins()\gcallback,#DATA)    
                  CallFunctionFast(Plugins()\rawfunction,*usagePointer)
                  pStat=CallFunctionFast(Plugins()\gcallback,#SEND)
                  Select pStat
                    Case #SEND
                      ptarget$=PeekS(CallFunctionFast(Plugins()\gtarget))
                      pmes$=PeekS(CallFunctionFast(Plugins()\gmessage))
                      SendTarget(ptarget$,pmes$,Server)
                  EndSelect
                Wend
              EndIf
            EndIf
            sc+1
          Wend
          
        ElseIf length=-1
          RemoveDisconnect(ClientID)
        EndIf
      EndIf
      
    Default
      Delay(LagShield)
      
  EndSelect
  
EndProcedure

;-  PROGRAM START    

If ReceiveHTTPFile("https://raw.githubusercontent.com/stonedDiscord/serverD/master/version.txt","version.txt")
  OpenPreferences("version.txt")
  PreferenceGroup("Version")
  newbuild=ReadPreferenceInteger("Build",#PB_Editor_BuildCount)
  If newbuild>#PB_Editor_BuildCount
    update=1
  EndIf
  ClosePreferences()
EndIf
start:
CompilerIf #CONSOLE=0
  IncludeFile "gui.pb"      
CompilerElse
  OpenConsole()
  LoadSettings(0)
  
  killed=0
  success=CreateNetworkServer(0,Port,#PB_Network_TCP)
  If success
    
    *Buffer = AllocateMemory(1024)
    
    WriteLog("Server started",Server)
    
    If public And msthread=0
      msthread=CreateThread(@MasterAdvert(),Port)
    EndIf      
    
    If LoopMusic
      CreateThread(@TrackWait(),0)
    EndIf                
    
    Repeat
      
      Network(0)
      
    Until Quit = 1
    WriteLog("stopping server...",Server)
    LockMutex(ListMutex)
    ResetMap(Clients())
    While NextMapElement(Clients())
      If Clients()\ClientID
        CloseNetworkConnection(Clients()\ClientID)
      EndIf
      DeleteMapElement(Clients())
    Wend
    killed=1
    UnlockMutex(ListMutex)    
    CloseNetworkServer(0)
    FreeMemory(*Buffer)
  Else
    WriteLog("server creation failed",Server)
  EndIf
  
CompilerEndIf

End
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 1954
; FirstLine = 1949
; Folding = ---
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0