; yes this is the legit serverD source code please report bugfixes/modifications/feature requests to sD/trtukz on skype

;- Include files

IncludeFile "server_shared.pb"

; Initialize The Network
If InitNetwork() = 0
  CompilerIf #CONSOLE=0
    MessageRequester("serverD "+version$,"Can't initialize the network!",#MB_ICONERROR)
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

; used for fantacrypt
ProcedureDLL.s HexToString(hex.s)
  Define str.s="",i
  For i = 1 To Len(hex.s) Step 2
    str.s = str.s + Chr(Val("$"+Mid(hex.s,i,2)))
  Next i
  ProcedureReturn str.s
EndProcedure

ProcedureDLL.s StringToHex(str.s)
  Define StringToHexR.s = ""
  Define hexchar.s = ""
  Define x
  For x = 1 To Len(str)
    hexchar.s = Hex(Asc(Mid(str,x,1)))
    If Len(hexchar) = 1
      hexchar = "0" + hexchar
    EndIf
    StringToHexR.s = StringToHexR + hexchar
  Next x
  ProcedureReturn StringToHexR.s
EndProcedure

Procedure.s EncryptStr(S.s,Key.u)
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

ProcedureDLL.s DecryptStr(S.s,Key.u)
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

;- Load Settings
Procedure LoadSettings(reload)
  Define loadchars,loadcharsettings,loaddesc,loadevi,loadareas
  Define InitChannel,charpage,page,dur,ltracks,nplg
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
      WritePreferenceString("Name","DEFAULT")
      WritePreferenceString("Desc","DEFAULT")
      WritePreferenceInteger("musicmode",1)
      WritePreferenceInteger("replaysave",0)
      WritePreferenceInteger("replayline",400)
      WritePreferenceString("case","AAOPublic2")
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
  Debug "done loading oldsettings"
  
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
      WritePreferenceString("MOTD","")
      WritePreferenceInteger("LoopMusic",0)
      WritePreferenceInteger("MultiChar",1)
      WritePreferenceInteger("CharLimit",1)
      WritePreferenceInteger("WTCE",1)
      WritePreferenceInteger("ExpertLog",0)
      WritePreferenceInteger("AllowCutoff",0)
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
  MultiChar=ReadPreferenceInteger("MultiChar",1)
  CharLimit=ReadPreferenceInteger("CharLimit",1)
  rt=ReadPreferenceInteger("WTCE",1)
  ExpertLog=ReadPreferenceInteger("ExpertLog",0)
  AllowCutoff=ReadPreferenceInteger("AllowCutoff",0)
  WebSockets=ReadPreferenceInteger("WebSockets",1)
  LoginReply$=ReadPreferenceString("LoginReply","CT#$HOST#Successfully connected as mod#%")
  LogFile$=ReadPreferenceString("LogFile","base/serverlog.log")
  decryptor$=ReadPreferenceString("decryptor","34")
  motd$=ReadPreferenceString("MOTD","CT#$SERVER#Running serverD version "+version$+"#%")
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
  
  ; Load scene file
  OpenPreferences("base/scene/"+scene$+"/init.ini")
  
  CompilerIf #CONSOLE
    PrintN("OOC pass:"+oppass$)
    PrintN("Block INI edit:"+Str(BlockINI))
    PrintN("Moderator color:"+Str(modcol))
    PrintN("MOTD:"+motd$)
    PrintN("Login reply:"+LoginReply$)
    PrintN("Logfile:"+LogFile$)
    PrintN("Logging:"+Str(Logging))
  CompilerEndIf
  PreferenceGroup("Global")
  EviNumber=ReadPreferenceInteger("EviNumber",0)
  oBG.s=Encode(ReadPreferenceString("BackGround","gs4"))
  For InitChannel=0 To 100
    Channels(InitChannel)\bg=oBG.s
    Channels(InitChannel)\name=oBG.s
    Channels(InitChannel)\good=10
    Channels(InitChannel)\evil=10
  Next
  
; Load Characters
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
  
  ; Load Evidence
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
  
  ; Load Character Files and prepare Speedloading
  ready$="CI#"
  newcready$="SC#"
  charpage=0
  Debug CharacterNumber
  For loadcharsettings=0 To CharacterNumber
    OpenPreferences("base/scene/"+scene$+"/char"+Str(loadcharsettings)+".ini")
    PreferenceGroup("desc")
    Characters(loadcharsettings)\desc=Encode(ReadPreferenceString("text",""))
    Characters(loadcharsettings)\dj=ReadPreferenceInteger("dj",musicmode)
    Characters(loadcharsettings)\evinumber=ReadPreferenceInteger("evinumber",0)
    Characters(loadcharsettings)\evidence=Encode(ReadPreferenceString("evi",""))

    Characters(loadcharsettings)\pw=Encode(ReadPreferenceString("pass",""))
    If Characters(loadcharsettings)\pw<>""
      passworded$="1"
    Else
      passworded$="0"
    EndIf
    ClosePreferences()
    ready$ = ready$ + Str(loadcharsettings)+"#"+Characters(loadcharsettings)\name+"&"+Characters(loadcharsettings)\desc+"&"+Str(Characters(loadcharsettings)\evinumber)+"&"+Characters(loadcharsettings)\evidence+"&"+Characters(loadcharsettings)\pw+"&"+Str(Characters(loadcharsettings)\evinumber)+"&#"
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
  
  ; Load music
  If ReadFile(2,"base/musiclist.txt")
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
      track$ = Encode(track$)
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
  
  ; these IP/HDs are mods when they log on
  If ReadFile(2,"base/op.txt")
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
    If CreateFile(2,"base/op.txt")
      WriteStringN(2,"127.0.0.1")
      CloseFile(2)
    EndIf
  EndIf
  
  ; funny meme sentences
  If ReadFile(2,"base/gimp.txt")
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
    If CreateFile(2,"base/gimp.txt")
      WriteStringN(2,"<3")
      CloseFile(2)
    EndIf
  EndIf
  
  ; Load areas
  If OpenPreferences( "base/scene/"+scene$+"/areas.ini")
    PreferenceGroup("Areas")
    ChannelCount=ReadPreferenceInteger("number",1)
    newaready$="SA#"
    For loadareas=0 To ChannelCount-1
      PreferenceGroup("Areas")
      aname$=Encode(ReadPreferenceString(Str(loadareas+1),oBG.s))
      Channels(loadareas)\name=aname$
      PreferenceGroup("filename")
      area$=Encode(ReadPreferenceString(Str(loadareas+1),oBG.s))
      Channels(loadareas)\bg=area$
      PreferenceGroup("hidden")
      Channels(loadareas)\hidden=ReadPreferenceInteger(Str(loadareas+1),0)
      PreferenceGroup("pass")
      Channels(loadareas)\pw=Encode(ReadPreferenceString(Str(loadareas+1),""))
      If Channels(loadareas)\pw=""
        passworded$="0"
      Else
        passworded$="1"
      EndIf
      If Channels(loadareas)\hidden=0
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
      Channels(0)\bg=oBG.s
      ChannelCount=1
      ClosePreferences()
    EndIf
  EndIf
  
; HDbans 
  If ReadFile(2,"base/HDbanlist.txt")
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
  
  ;  IPbans
  If ReadFile(2,"base/banlist.txt")
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
  
  ; Load plugins
  CompilerIf #PLUGINS
  CloseLibrary(#PB_All)
  If ExamineDirectory(0,"plugins/","*"+libext$)  
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
  CompilerEndIf
  
EndProcedure
; IP list for old clients
; the list disappears on the client once you switch between server and master chat
Procedure ListIP(ClientID)
  Define iplist$
  Define charname$
  iplist$="IL#"
  LockMutex(ListMutex)
  PushMapPosition(Clients())
  ResetMap(Clients())
  While NextMapElement(Clients())
    charname$=GetCharacterName(Clients())+GetRankName(Clients()\perm)+" in "+GetAreaName(Clients())
    iplist$=iplist$+Clients()\IP+"|"+charname$+"|"+Str(Clients()\CID)+"|*"
  Wend
  PopMapPosition(Clients())
  UnlockMutex(ListMutex)
  iplist$=iplist$+"#%"
  SendTarget(Str(ClientID),iplist$,Server) 
EndProcedure

; AO2 doesn't know that command
Procedure ListIPSI(ClientID)
  Define iplist$
  Define charname$
  iplist$="CT#$HOST#"
  LockMutex(ListMutex)
  PushMapPosition(Clients())
  ResetMap(Clients())
  While NextMapElement(Clients())
    charname$=GetCharacterName(Clients())+GetRankName(Clients()\perm)+" in "+GetAreaName(Clients())
    iplist$=iplist$+"IP: "+Clients()\IP+" "+charname$+" ID: "+Str(Clients()\CID)+" HDID: "+Clients()\HD+#CRLF$
  Wend
  PopMapPosition(Clients())
  UnlockMutex(ListMutex)
  iplist$=iplist$+"#%"
  SendTarget(Str(ClientID),iplist$,Server) 
EndProcedure

;masterserver stuff
ProcedureDLL MasterAdvert(Port)
  Define msID=0,msinfo,NEvent,msPort=27016,retries,tick
  Define sr=-1
  Define *aom=AllocateMemory(512)
  Define master$,msrec$
  WriteLog("Masterserver adverter thread started",Server)
  OpenPreferences("base/masterserver.ini")
  PreferenceGroup("list")
  master$=ReadPreferenceString("0","master.aceattorneyonline.com")
  msPort=ReadPreferenceInteger("Port",27016)
  ClosePreferences()
  
  WriteLog("Using master "+master$,Server)
  
  If public
    Repeat
      
      If msID<>0
        
        If tick>10
          sr=SendNetworkString(msID,"PING#%")
        EndIf
        
        NEvent=NetworkClientEvent(msID)
        If NEvent=#PB_NetworkEvent_Disconnect
          msID=0
        ElseIf NEvent=#PB_NetworkEvent_Data
          msinfo=ReceiveNetworkData(msID,*aom,512)
          If msinfo=-1
            msID=0
          Else
            msrec$=PeekS(*aom,msinfo)
            Debug msrec$
            If msrec$="NOSERV#%"
              WriteLog("Fell off the serverlist,fixing...",Server)
              port$ = Str(Port)
              If WebSockets
                port$ = port$ + "&" + Str(Port)
              EndIf
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
          port$ = Str(Port)
          If WebSockets
            port$ = port$ + "&" + Str(Port)
          EndIf
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
  FreeMemory(*aom)
  msthread=0
EndProcedure

Procedure MasterAdvertVNO(port)
  Define msID=0,msinfo,NEvent,MVNO=0,msport=6543,retries
  Define sr=-1
  Define *vnom=AllocateMemory(512)
  Define master$,msrec$,mspass$,mscpass$,msuser$
  WriteLog("Masterserver adverter thread started",Server)
  OpenPreferences("base/AS.ini")
  PreferenceGroup("AS")
  master$=ReadPreferenceString("1","99.105.12.119")
  PreferenceGroup("login")
  msuser$=ReadPreferenceString("user","Username")
  mspass$=ReadPreferenceString("pass","Password")
  mscpass$=UCase(MD5Fingerprint(@mspass$,StringByteLength(mspass$)))
  msport=6543
  ClosePreferences() 
  desc$=ReplaceString(desc$,"$n","|")  
  desc$=ReplaceString(desc$,"%n","|") 
  desc$=ReplaceString(desc$,"#","!") 
  desc$=ReplaceString(desc$,"%","!") 
  
  WriteLog("Using master "+master$, Server)
  Global msstop=0
  Repeat      
    If msID
      NEvent=NetworkClientEvent(msID)
      If NEvent=#PB_NetworkEvent_Disconnect
        sr=-1
        msID=0
        Server\ClientID=msID
      ElseIf NEvent=#PB_NetworkEvent_Data
        msinfo=ReceiveNetworkData(msID,*vnom,100)
        If msinfo=-1
          sr=-1
        Else
          tick=0
          retries=0
          mrawreceive$=PeekS(*vnom,msinfo)
          If ExpertLog
            WriteLog(msrec$,Server)
          EndIf
          
          mcommandlist=1
          While StringField(mrawreceive$,mcommandlist,"%")<>""
            msrec$=StringField(mrawreceive$,mcommandlist,"%")+"%"
            Debug msrec$
            
            Select StringField(msrec$,1,"#")    
              Case "CV"
                sr=SendNetworkString(msID,"VER#S#1.5#%")
                CompilerIf #NICE
                  Delay(50)
                  sr=SendNetworkString(msID,"CO#Username#DC647EB65E6711E155375218212B3964#%")
                  Delay(50)
                CompilerEndIf
                Debug mscpass$
                sr=SendNetworkString(msID,"CO#"+msuser$+"#"+mscpass$+"#%")
              Case "VEROK"
                WriteLog("Running latest VNO server version.",Server)
              Case "VERPB"
                WriteLog("VNO Protocol outdated!",Server)
                public=0
              Case "VNAL"
                If public
                  sr=SendNetworkString(msID,"RequestPub#"+msname$+"#"+Str(port)+"#"+desc$+"#"+www$+"#%")
                EndIf
              Case "No"
                WriteLog("Wrong master credentials",Server)
              Case "VNOBD"
                WriteLog("Banned from master",Server)
                public=0
              Case "NOPUB"
                WriteLog("Banned from hosting",Server)
                public=0
              Case "OKAY"                
                LockMutex(ListMutex)
                ResetMap(Clients())
                While NextMapElement(Clients())
                  Debug "ip "+StringField(msrec$,3,"#")
                  If Clients()\IP=StringField(msrec$,3,"#")
                    Clients()\username=StringField(msrec$,2,"#")
                    WriteLog("[AUTH.] "+Clients()\username+":"+Clients()\IP+":"+Str(Clients()\AID),Server)
                    If ReadFile(7,"base/scene/"+scene$+"/PlayerData/"+Clients()\username+".txt")
                      While Eof(7) = 0
                        Clients()\Inventory[ir]=Val(ReadString(7))
                        ir+1
                      Wend
                      
                      CloseFile(7)
                    EndIf
                  EndIf
                Wend
                UnlockMutex(ListMutex)
            EndSelect
            mcommandlist+1
          Wend
        EndIf
      EndIf
      
      If sr=-1
        retries+1
        WriteLog("Masterserver adverter thread connecting...",Server)
        msID=OpenNetworkConnection(master$,msport)
        Server\ClientID=msID
      EndIf 
      
    Else
      retries+1
      WriteLog("Masterserver adverter thread connecting...",Server)
      msID=OpenNetworkConnection(master$,msport)
      Server\ClientID=msID
      If msID
      EndIf
    EndIf
    If retries>50
      WriteLog("Too many masterserver connect retries, aborting...",Server)
      public=0
    EndIf
    Delay(1000)
  Until msstop=1
  
  WriteLog("Masterserver adverter thread stopped",Server)
  If msID
    CompilerIf #NICE
      sr=SendNetworkString(msID,"KSID#%")
      Delay(50)
    CompilerEndIf
    CloseNetworkConnection(msID)
  EndIf
  FreeMemory(*vnom)
  msvthread=0
EndProcedure

;send a list of evidence to everyone once it updates
Procedure SendUpdatedEvi(target$)
  evilist$="LE#"
    For loadevi=0 To EviNumber

    evilist$+Evidences(loadevi)\name+"&"+Evidences(loadevi)\desc+"&"+Evidences(loadevi)\image+"#"
    
  Next
  evilist$+"%"
  SendTarget(target$,evilist$,Server)
EndProcedure

; this triggers the charselect on clients
Procedure SendDone(*thisClient.Client)
  Define send$
  Define sentchar
  Dim APlayers(characternumber)
  
  
  send$="CharsCheck"
  LockMutex(ListMutex)
  PushMapPosition(Clients())
  ResetMap(Clients())
  While NextMapElement(Clients())
    If Clients()\CID>=0 And Clients()\CID <= characternumber
      If Clients()\area=*thisClient\area
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
  SendTarget(Str(*thisClient\ClientID),send$,Server)
  SendTarget(Str(*thisClient\ClientID),"BN#"+Channels(*thisClient\area)\bg+"#%",Server)
  SendTarget(Str(*thisClient\ClientID),"OPPASS#"+StringToHex(EncryptStr(opppass$,key))+"#%",Server)
  SendTarget(Str(*thisClient\ClientID),"MM#"+Str(musicmode)+"#%",Server)
  SendUpdatedEvi(Str(*thisClient\ClientID))
  SendTarget(Str(*thisClient\ClientID),"DONE#%",Server)
EndProcedure

; switching areas
Procedure AreaSelected(*thisClient.Client)
  WriteLog("Switched Area to "+GetAreaName(*thisClient),*thisClient)
  
  SendTarget(Str(*thisClient\ClientID),"CT#$HOST#area "+Str(*thisClient\area)+" selected#%",Server)
  SendTarget(Str(*thisClient\ClientID),"HP#1#"+Str(Channels(*thisClient\area)\good)+"#%",Server)
  SendTarget(Str(*thisClient\ClientID),"HP#2#"+Str(Channels(*thisClient\area)\evil)+"#%",Server)
  
  players$="ARUP#0"
  status$ ="ARUP#1"
  cm$     ="ARUP#2"
  locked$ ="ARUP#3"
  For carea=0 To ChannelCount
    players$ = players$ + "#"+Str(Channels(carea)\players)
    status$  = status$  + "#IDLE"
    cm$      = cm$      + "#FREE"
    locked$  = locked$  + "#FREE"
  Next
  players$ = players$ + "#%"
  status$  = status$  + "#%"
  cm$      = cm$      + "#%"
  locked$  = locked$ + "#%"
  SendTarget("*",players$,Server)
  SendTarget("*",status$,Server)
  SendTarget("*",cm$,Server)
  SendTarget("*",locked$,Server)
EndProcedure

Procedure UpdateAreaPlayercount()
  ;reset all to zero
  For ir=0 To ChannelCount-1
    Channels(ir)\players=0
  Next
  
  LockMutex(ListMutex)
  PushMapPosition(Clients())
  ResetMap(Clients())
  While NextMapElement(Clients())
    If Clients()\area>=0
      Channels(Clients()\area)\players+1
    EndIf
  Wend
  PopMapPosition(Clients())
  UnlockMutex(ListMutex)
EndProcedure

Procedure SwitchChannels(*thisClient.Client,narea$,apass$)
  Define sendd=0
  Define newarea
  For ir=0 To ChannelCount
    If Channels(ir)\name = narea$
      newarea = ir
      Break
    EndIf
  Next
  
  If newarea=0 ;bypass almost all checks for the default area
    If Channels(*thisClient\area)\lock=*thisClient\ClientID
      Channels(*thisClient\area)\lock=0
      Channels(*thisClient\area)\mlock=0
    EndIf
    Channels(*thisClient\area)\players-1
    *thisClient\area=0 ; set area to 0
    Channels(0)\players+1
    If sendd=1
      *thisClient\CID=-1
      SendDone(*thisClient)
    Else
      SendTarget(Str(*thisClient\ClientID),"BN#"+Channels(0)\bg+"#%",Server)      
    EndIf
    AreaSelected(*thisClient)
  Else
    If newarea<=ChannelCount-1 And newarea>=0
      If Not Channels(newarea)\lock Or *thisClient\perm>Channels(newarea)\mlock
        If Channels(newarea)\pw="" Or Channels(newarea)\pw=apass$ Or *thisClient\perm
          If Channels(*thisClient\area)\lock=*thisClient\ClientID
            Channels(*thisClient\area)\lock=0
            Channels(*thisClient\area)\mlock=0
          EndIf
          Channels(*thisClient\area)\players-1
          *thisClient\area=newarea  ; set the players area
          Channels(*thisClient\area)\players+1
          If sendd=1
            *thisClient\CID=-1
            SendDone(*thisClient)
          Else
            SendTarget(Str(*thisClient\ClientID),"BN#"+Channels(*thisClient\area)\bg+"#%",Server)
          EndIf
          AreaSelected(*thisClient)
        Else
          SendTarget(Str(*thisClient\ClientID),"CT#$HOST#wrong password#%",Server)
        EndIf
      Else
        SendTarget(Str(*thisClient\ClientID),"CT#$HOST#area locked#%",Server)
      EndIf
    Else
      SendTarget(Str(*thisClient\ClientID),"CT#$HOST#Not a valid area#%",Server)
    EndIf
  EndIf
EndProcedure

; handle mod operations
Procedure KickBan(kick$,param$,action,*thisClient.Client)
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
      If ((kick$=Str(kcid) Or kick$=Str(kclid) Or kick$=ReplaceString(GetCharacterName(Clients())," ","_")) And Clients()\area=*thisClient\area) Or kick$=Clients()\HD Or kick$=Clients()\IP Or kick$="Area"+Str(Clients()\area) Or everybody
        If Clients()\perm<*thisClient\perm Or (*thisClient\perm And Clients()=*thisClient)
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
              
            Case #SILENCE
              Clients()\silence=1
              actionn$="silenced"
              akck+1
              
            Case #UNSILENCE
              Clients()\silence=0
              actionn$="unsilenced"
              akck+1
              
            Case #UNDJ
              Clients()\ignoremc=1
              actionn$="undj'd"
              akck+1
              
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
              SwitchChannels(Clients(),param$,"")
              
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
  WriteLog(actionn$+" "+kick$+","+Str(akck)+" people died.",*thisClient)
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
    *thisClient.Client=FindMapElement(Clients(),Str(ClientID))
    Debug "sc"
  ElseIf ClientID=-1
    *thisClient.Client=@Server
    Debug "server"
  Else
    *thisClient=0
    Debug "error"
  EndIf
  If *thisClient    
    If Left(*thisClient\last,1)="#"
      *thisClient\last=Mid(*thisClient\last,2)
      Debug *thisClient\last
      Debug StringField(*thisClient\last,1,"#")
      Debug StringField(*thisClient\last,2,"#")
      *thisClient\command=DecryptStr(HexToString(StringField(*thisClient\last,1,"#")),key)
      rawreceive$=*thisClient\last
      coff=6
    ElseIf Left(*thisClient\last,1)="4" Or Left(*thisClient\last,1)="3"
      *thisClient\command=DecryptStr(HexToString(StringField(*thisClient\last,1,"#")),key)
      rawreceive$=*thisClient\last
      coff=6
    Else
      *thisClient\command=StringField(*thisClient\last,1,"#")
      rawreceive$=*thisClient\last
      coff=4
    EndIf    
    Debug *thisClient\command
    length=Len(rawreceive$)    
    
    If StringField(rawreceive$,2,"#")="chat"
      *thisClient\command="MS"
    ElseIf Right(StringField(rawreceive$,2,"#"),4)=".mp3"
      *thisClient\command="MC"
    ElseIf Left(*thisClient\command,3)="GET"
      *thisClient\command="GET"
    EndIf
    
    
    Debug rawreceive$
    Debug *thisClient\command
    Select *thisClient\command
      Case "wait"        
      Case "CH"
        SendTarget(Str(ClientID),"CHECK#%",*thisClient)
      Case "MS"
        msreplayfix:
        
        nmes.ChatMessage
        Select *thisClient\type
          Case #VNO
            nmes\char=Encode(StringField(rawreceive$,2,"#"))
            nmes\emote=Encode(StringField(rawreceive$,3,"#"))
            nmes\message=Encode(StringField(rawreceive$,4,"#"))
            nmes\showname=Encode(StringField(rawreceive$,5,"#"))
            nmes\color=Val(StringField(rawreceive$,6,"#"))
            ;7 is charid
            nmes\background=Encode(StringField(rawreceive$,8,"#"))
            Select Val(StringField(rawreceive$,9,"#"))
              Case 1
                nmes\position="def"
              Case 2
                nmes\position="pro"
              Default
                nmes\position="wit"
            EndSelect
            nmes\flip=Val(StringField(rawreceive$,10,"#"))
            nmes\sfx=Encode(StringField(rawreceive$,11,"#"))
          Default
            ;MS#chat#<pre-emote>#<char>#<emote>#<mes>#<pos>#<sfx>#<zoom>#<cid>#<animdelay>#<objection-state>#<evi>#<cid>#<bling>#<color>#%%
            nmes\deskmod=Encode(StringField(rawreceive$,2,"#"))
            nmes\preemote=Encode(StringField(rawreceive$,3,"#"))
            nmes\char=Encode(StringField(rawreceive$,4,"#"))
            nmes\showname="char"
            nmes\emote=Encode(StringField(rawreceive$,5,"#"))
            nmes\message=Encode(StringField(rawreceive$,6,"#"))
            If *thisClient\pos=""
              nmes\position=Encode(StringField(rawreceive$,7,"#"))
            Else
              nmes\position=*thisClient\pos
            EndIf
            nmes\sfx=Encode(StringField(rawreceive$,8,"#"))
            nmes\emotemod=Val(StringField(rawreceive$,9,"#"))
            nmes\animdelay=Val(StringField(rawreceive$,11,"#"))
            nmes\objmod=Val(StringField(rawreceive$,12,"#"))
            nmes\evidence=Val(StringField(rawreceive$,13,"#"))
            nmes\flip=Val(StringField(rawreceive$,14,"#"))
            nmes\realization=Val(StringField(rawreceive$,15,"#"))
            nmes\color=Val(StringField(rawreceive$,16,"#"))
            nmes\background="[Default]"
        EndSelect
        If ReplayMode=0 Or *thisClient\perm=#SERVER
          SendChatMessage(nmes,*thisClient)
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
              SendTarget("*","MS#chat#dolanangry#Dolan#dolanangry#Invalid command! Valid: <,>,Q#jud#1#2#"+Str(characternumber-1)+"#0#3#0#"+Str(characternumber-1)+"#0#"+Str(modcol)+"#%",Server)
          EndSelect
        EndIf
        
      Case "MC"
        replaymusicfix:
        If *thisClient\type=#VNO
          mcparam$=StringField(rawreceive$,3,"#")
          Else
            mcparam$=StringField(rawreceive$,2,"#")
            EndIf
        If *thisClient\perm=#SERVER
          Sendtarget("*","MC#"+Mid(rawreceive$,coff),*thisClient)
        Else
          music=0
          LockMutex(musicmutex)
          ForEach Music()
            If mcparam$=Music()\TrackName
              music=1
              mdur=Music()\Length
              Debug Music()\Length
              Break
            EndIf
          Next
          UnlockMutex(musicmutex)
          
          If music=1
            If Left(mcparam$,1)=">"              
              SwitchChannels(*thisClient,Mid(mcparam$,2),"")
            Else
              If *thisClient\ignoremc=0 And *thisClient\CID>=0 And *thisClient\CID<=CharacterNumber
                If Characters(*thisClient\CID)\dj
                  
                  If GetExtensionPart(mcparam$)="m3u"
                    
                    If ReadFile(23,"base\"+GetFilePart(mcparam$))
                      
                      Repeat
                        playliststring$=ReadString(23)
                        If Left(playliststring$,4)="#EXT"
                          If Left(playliststring$,8)="#EXTINF:"
                            playliststring$=Mid(playliststring$,9)
                            AddElement(Channels(*thisClient\area)\Playlist())
                            Debug StringField(playliststring$,1,",")
                            Channels(*thisClient\area)\Playlist()\Length = Val(StringField(playliststring$,1,","))*1000
                          EndIf
                        Else
                          Channels(*thisClient\area)\Playlist()\TrackName = GetFilePart(playliststring$)
                        EndIf
                      Until Eof(23)                      
                      CloseFile(23)
                      ResetList(Channels(*thisClient\area)\Playlist())
                      NextElement(Channels(*thisClient\area)\Playlist())
                      Channels(*thisClient\area)\trackstart=ElapsedMilliseconds()
                      Channels(*thisClient\area)\trackwait=Channels(*thisClient\area)\Playlist()\Length
                      Channels(*thisClient\area)\track=mcparam$
                      Sendtarget("Area"+Str(*thisClient\area),"MC#"+Channels(*thisClient\area)\Playlist()\TrackName+"#"+Str(CharacterNumber)+"#%",*thisClient)                      
                    EndIf                    
                    
                  Else
                    Debug mdur
                    Channels(*thisClient\area)\trackstart=ElapsedMilliseconds()
                    Channels(*thisClient\area)\trackwait=mdur
                    Channels(*thisClient\area)\track=mcparam$
                    Sendtarget("Area"+Str(*thisClient\area),"MC#"+mcparam$+"#"+Str(*thisClient\CID)+"#%",*thisClient)
                  EndIf
                  WriteLog("changed music to "+mcparam$,*thisClient)
                  WriteReplay(rawreceive$)
                EndIf
              EndIf
            EndIf
          Else
            *thisClient\hack=1
            rf=1
            WriteLog("tried changing music to "+mcparam$,*thisClient)
          EndIf 
        EndIf
        
        ;- ooc commands
      Case "CT"
        send=0
        *thisClient\last.s=""
        ctparam$=StringField(rawreceive$,3,"#")
        WriteLog("[OOC]"+StringField(rawreceive$,2,"#")+":"+ctparam$,*thisClient)
        
        If *thisClient\username=""
          *thisClient\username=RemoveString(StringField(rawreceive$,2,"#"),"<dollar>")
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
                    Select *thisClient\type
                      Case #VNO
                        SendTarget(Str(ClientID),"MODOK#%",Server)
                      Case #AOTWO
                        SendTarget(Str(ClientID),"MK#%",Server)
                    EndSelect
                    *thisClient\perm=#MOD
                    *thisClient\ooct=1
                    rf=1
                  EndIf
                Case adminpass$
                  If adminpass$<>""
                    SendTarget(Str(ClientID),LoginReply$,Server)
                    Select *thisClient\type
                      Case #VNO
                        SendTarget(Str(ClientID),"MODOK#%",Server)
                      Case #AOTWO
                        SendTarget(Str(ClientID),"MK#%",Server)
                    EndSelect
                    *thisClient\perm=#ADMIN
                    *thisClient\ooct=1
                    rf=1
                  EndIf
              EndSelect
              send=0
              
            Case "/cmds"
              SendTarget(Str(ClientID),"CT#$HOST#help,cmds,login,g,pos,change,switch,online,area,evi,roll,pm,version,smokeweed#%",Server)
              If *thisClient\perm
                SendTarget(Str(ClientID),"CT#$HOST#ip,bg,move,lock,(no)skip,play,hd,(un)ban,kick,disconnect,(un)mute,(un)ignore,(unsilence),(un)dj,(un)gimp#%",Server)
              EndIf
              If *thisClient\perm>=#ADMIN
                SendTarget(Str(ClientID),"CT#$HOST#public,send,sendall,reload,toggle,decryptor,snapshot,stop,loadreplay#%",Server)
              EndIf
            Case "/ip"
              If *thisClient\perm
                If *thisClient\type=#AOTWO
                  ListIPSI(ClientID)
                Else
                  ListIP(ClientID)
                EndIf
                WriteLog("["+GetCharacterName(*thisClient)+"] used /ip",*thisClient)
              EndIf 
              
            Case "/bg"
              If *thisClient\perm                            
                bgcomm$=Mid(ctparam$,5)
                Debug bgcomm$
                Channels(*thisClient\area)\bg=bgcomm$
                Sendtarget("Area"+Str(*thisClient\area),"BN#"+bgcomm$+"#%",*thisClient)                      
              EndIf
              
            Case "/pos"
              npos$=Mid(ctparam$,6)
              If npos$="def" Or npos$="pro" Or npos$="hlp" Or npos$="hld" Or npos$="wit" Or npos$="jud"
                *thisClient\pos=npos$
                SendTarget(Str(ClientID),"CT#$HOST#Your position is now: "+*thisClient\pos+"#%",Server)
              Else
                *thisClient\pos=""
                SendTarget(Str(ClientID),"CT#$HOST#You're back in the default position#%",Server)
              EndIf
              
            Case "/g"
              SendTarget("*","CT#[G]"+*thisClient\username+"#"+Mid(StringField(rawreceive$,3,"#"),3)+"#%",*thisClient)
              
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
                        If Clients()\area=*thisClient\area
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
                  If akchar=0 Or *thisClient\CID=nch Or BlockTaken=0
                    SendTarget(Str(ClientID),"PV#"+Str(*thisClient\AID)+"#CID#"+Str(nch)+"#%",Server)               
                    *thisClient\CID=nch       
                    WriteLog("chose character: "+GetCharacterName(*thisClient),*thisClient)
                    SendTarget(Str(ClientID),"HP#1#"+Str(Channels(*thisClient\area)\good)+"#%",Server)
                    SendTarget(Str(ClientID),"HP#2#"+Str(Channels(*thisClient\area)\evil)+"#%",Server)
                  EndIf
                  Break
                  rf=1
                EndIf
              Next
              
            Case "/switch"
              If Mid(ctparam$,9)=""
                *thisClient\cid=-1
                SendDone(*thisClient)
              Else
                KickBan(StringField(ctparam$,2," "),StringField(ctparam$,3," "),#SWITCH,*thisClient)
              EndIf
              
            Case "/charselect"
              *thisClient\cid=-1
              SendDone(*thisClient)
              
            Case "/move"
              KickBan(StringField(ctparam$,2," "),StringField(ctparam$,3," "),#MOVE,*thisClient)
              
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
              If *thisClient\perm
                UpdateAreaPlayercount()
              EndIf
              
              narea$=StringField(ctparam$,2," ")
              apass$=StringField(ctparam$,3," ")
              If narea$=""
                arep$="CT#$HOST#Areas:"
                For ir=0 To ChannelCount-1
                  If Channels(ir)\hidden=0 Or *thisClient\perm
                    arep$+#CRLF$
                    arep$=arep$+Channels(ir)\name
                    If Channels(ir)\hideplayers=0
                      arep$=arep$+": "+Str(Channels(ir)\players)+" users"
                      EndIf
                    If ir=*thisClient\area
                      arep$+" (you are here)"
                    EndIf
                    If Channels(ir)\mlock
                      arep$+" super"
                    EndIf
                    If Channels(ir)\lock
                      arep$+"locked"                      
                    EndIf
                  EndIf
                Next
                arep$+"#%"
                SendTarget(Str(ClientID),arep$,Server)
              Else                  
                SwitchChannels(*thisClient,narea$,apass$)
              EndIf
              
            Case "/loadreplay"
              If *thisClient\perm>=#MOD
                ReplayFile$="base/replays/"+Mid(ctparam$,13)
                If ReadFile(8,ReplayFile$)
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
              If *thisClient\area
                lock$=StringField(ctparam$,2," ")
                Select lock$
                  Case "0"
                    If Channels(*thisClient\area)\lock=*thisClient\ClientID Or *thisClient\perm>Channels(*thisClient\area)\mlock
                      Channels(*thisClient\area)\lock=0
                      Channels(*thisClient\area)\mlock=0
                      SendTarget(Str(ClientID),"CT#$HOST#area unlocked#%",Server)
                    EndIf
                  Case "1"
                    If *thisClient\perm
                      Channels(*thisClient\area)\lock=*thisClient\ClientID
                      Channels(*thisClient\area)\mlock=0
                      SendTarget(Str(ClientID),"CT#$HOST#area locked#%",Server)
                    EndIf
                  Case "2"
                    If *thisClient\perm>#MOD
                      Channels(*thisClient\area)\lock=*thisClient\ClientID
                      Channels(*thisClient\area)\mlock=1
                      SendTarget(Str(ClientID),"CT#$HOST#area superlocked#%",Server)
                    EndIf
                  Default
                    pr$="CT#$HOST#area is "
                    If Channels(*thisClient\area)\lock=0
                      pr$+"not "
                    EndIf
                    SendTarget(Str(ClientID),pr$+"locked#%",Server)
                EndSelect
              Else
                SendTarget(Str(ClientID),"CT#$HOST#You can't lock the default area#%",Server)
              EndIf
              
            Case "/skip"
              If *thisClient\perm
                *thisClient\skip=1
                SendTarget(Str(ClientID),"CT#$HOST#You can now skip others#%",Server)
              EndIf
              
            Case "/noskip"
              If *thisClient\perm
                *thisClient\skip=0
                SendTarget(Str(ClientID),"CT#$HOST#You can no longer skip others#%",Server)
              EndIf
              
            Case "/toggle"
              If *thisClient\perm>#MOD
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
              If *thisClient\perm>#MOD
                decryptor$=StringField(ctparam$,2," ")
                key=Val(DecryptStr(HexToString(decryptor$),322))
                SendTarget("*","decryptor#"+decryptor$+"#%",Server)
              EndIf
              
            Case "/snapshot"
              If *thisClient\perm>#MOD
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
                    WriteStringN(33,Channels(sa)\name)
                    WriteStringN(33,Channels(sa)\bg)
                    WriteStringN(33,Str(Channels(sa)\players))
                    WriteStringN(33,Str(Channels(sa)\lock))
                    WriteStringN(33,Str(Channels(sa)\mlock))
                    WriteStringN(33,Channels(sa)\track)
                    WriteStringN(33,Str(Channels(sa)\trackwait))
                  Next
                  CloseFile(33)
                EndIf
              EndIf
              
            Case "/smokeweed"
              reply$="CT#stonedDiscord#where da weed at#%"
              WriteLog("smoke weed everyday",*thisClient)
              
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
                If *thisClient\perm>#MOD
                  public=Val(StringField(ctparam$,2," "))
                  If public=2
                    msvthread=CreateThread(@MasterAdvertVNO(),Port)
                    SendTarget(Str(ClientID),"CT#$HOST#published server on VNO#%",Server)
                    ElseIf public
                    msthread=CreateThread(@MasterAdvert(),Port)
                    SendTarget(Str(ClientID),"CT#$HOST#published server#%",Server)
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
              Sendtarget("Area"+Str(*thisClient\area),"CT#$HOST#"+GetCharacterName(*thisClient)+" rolled "+random$+" of "+Str(dicemax)+"#%",Server)
              
            Case "/pm"
              SendTarget(StringField(ctparam$,2," "),"CT#PM "+*thisClient\username+" to You#"+Mid(ctparam$,6+Len(StringField(ctparam$,2," ")))+"#%",Server)
              SendTarget(Str(ClientID),"CT#PM You to "+StringField(ctparam$,2," ")+"#"+Mid(ctparam$,6+Len(StringField(ctparam$,2," ")))+"#%",Server)
              
            Case "/send"  
              If *thisClient\perm>#MOD
                sname$=StringField(ctparam$,2," ")
                Debug sname$
                smes$=Mid(ctparam$,8+Len(sname$),Len(ctparam$)-6)
                smes$=Escape(smes$)
                SendTarget(sname$,smes$,Server)
              EndIf
              
            Case "/sendall"
              If *thisClient\perm>#MOD
                smes$=Mid(ctparam$,10)
                smes$=Escape(smes$)
                SendTarget("*",smes$,Server)
              EndIf
              
            Case "/reload"
              If *thisClient\perm>#MOD
                LoadSettings(1)
                SendTarget(Str(ClientID),"CT#$HOST#serverD reloaded#%",Server)
              EndIf
              
            Case "/play"
              If *thisClient\perm
                song$=Right(ctparam$,Len(ctparam$)-6)
                Channels(*thisClient\area)\trackstart=ElapsedMilliseconds()
                Channels(*thisClient\area)\trackwait=0
                Channels(*thisClient\area)\track=song$
                SendTarget("Area"+Str(*thisClient\area),"MC#"+song$+"#"+Str(*thisClient\CID)+"#%",*thisClient)                
              EndIf
              
            Case "/hd"
              If *thisClient\perm>=#MOD
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
                WriteLog("["+GetCharacterName(*thisClient)+"] used /hd",*thisClient)
              EndIf 
              
              
            Case "/unban"
              If *thisClient\perm>#MOD
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
              If *thisClient\perm>=#ADMIN
                public=0
                WriteLog("stopping server...",*thisClient)
                Quit=1
              EndIf
              
            Case "/kick"
              If *thisClient\perm>=#MOD
                akck=KickBan(Mid(ctparam$,7),StringField(ctparam$,3," "),#KICK,*thisClient)
                SendTarget(Str(ClientID),"CT#$HOST#kicked "+Str(akck)+" clients#%",Server) 
              EndIf
              
            Case "/disconnect"
              If *thisClient\perm>=#MOD
                akck=KickBan(Mid(ctparam$,13),StringField(ctparam$,3," "),#DISCO,*thisClient)
                SendTarget(Str(ClientID),"CT#$HOST#disconnected "+Str(akck)+" clients#%",Server) 
              EndIf
              
            Case "/ban"
              If *thisClient\perm>=#MOD
                akck=KickBan(Mid(ctparam$,6),StringField(ctparam$,3," "),#BAN,*thisClient)
                SendTarget(Str(ClientID),"CT#$HOST#banned "+Str(akck)+" clients#%",Server)
              EndIf
              
            Case "/mute"
              If *thisClient\perm>=#MOD
                akck=KickBan(Mid(ctparam$,7),StringField(ctparam$,3," "),#MUTE,*thisClient)
                SendTarget(Str(ClientID),"CT#$HOST#muted "+Str(akck)+" clients#%",Server)
              EndIf
              
              
            Case "/unmute"
              If *thisClient\perm>=#MOD
                akck=KickBan(Mid(ctparam$,9),StringField(ctparam$,3," "),#UNMUTE,*thisClient)
                SendTarget(Str(ClientID),"CT#$HOST#unmuted "+Str(akck)+" clients#%",Server)
              EndIf
              
              
            Case "/ignore"
              If *thisClient\perm>=#MOD
                akck=KickBan(Mid(ctparam$,9),StringField(ctparam$,3," "),#CIGNORE,*thisClient)
                SendTarget(Str(ClientID),"CT#$HOST#muted "+Str(akck)+" clients#%",Server)
              EndIf
              
              
            Case "/unignore"
              If *thisClient\perm>=#MOD
                akck=KickBan(Mid(ctparam$,11),StringField(ctparam$,3," "),#UNIGNORE,*thisClient)
                SendTarget(Str(ClientID),"CT#$HOST#unmuted "+Str(akck)+" clients#%",Server)
              EndIf
              
              Case "/silence"
              If *thisClient\perm>=#MOD
                akck=KickBan(Mid(ctparam$,10),StringField(ctparam$,3," "),#SILENCE,*thisClient)
                SendTarget(Str(ClientID),"CT#$HOST#silenced "+Str(akck)+" clients#%",Server)
              EndIf
              
              
            Case "/unsilence"
              If *thisClient\perm>=#MOD
                akck=KickBan(Mid(ctparam$,12),StringField(ctparam$,3," "),#UNSILENCE,*thisClient)
                SendTarget(Str(ClientID),"CT#$HOST#unsilenced "+Str(akck)+" clients#%",Server)
              EndIf
              
            Case "/undj"
              If *thisClient\perm>=#MOD
                akck=KickBan(Mid(ctparam$,7),StringField(ctparam$,3," "),#UNDJ,*thisClient)
                SendTarget(Str(ClientID),"CT#$HOST#muted "+Str(akck)+" clients#%",Server)
              EndIf
              
              
            Case "/dj"
              If *thisClient\perm>=#MOD
                akck=KickBan(Mid(ctparam$,5),StringField(ctparam$,3," "),#DJ,*thisClient)
                SendTarget(Str(ClientID),"CT#$HOST#unmuted "+Str(akck)+" clients#%",Server)
              EndIf
              
            Case "/gimp"
              If *thisClient\perm
                akck=KickBan(Mid(ctparam$,7),StringField(ctparam$,3," "),#GIMP,*thisClient)
                SendTarget(Str(ClientID),"CT#$HOST#gimped "+Str(akck)+" clients#%",Server)
              EndIf
              
            Case "/ungimp"
              If *thisClient\perm
                akck=KickBan(Mid(ctparam$,9),StringField(ctparam$,3," "),#UNGIMP,*thisClient)
                SendTarget(Str(ClientID),"CT#$HOST#ungimped "+Str(akck)+" clients#%",Server)
              EndIf
              
            Case "/version"
              SendTarget(Str(ClientID),"CT#$HOST#serverD "+version$+"#%",Server)
              
          EndSelect
        Else
          *thisClient\last.s=rawreceive$
          SendTarget("Area"+Str(*thisClient\area),"CT#"+*thisClient\username+"#"+StringField(rawreceive$,3,"#")+"#%",*thisClient)
          CompilerIf #CONSOLE=0
            AddGadgetItem(#ListIcon_2,-1,StringField(rawreceive$,2,"#")+Chr(10)+StringField(rawreceive$,3,"#"))
            Debug "guys"
            SetGadgetItemData(#ListIcon_2,CountGadgetItems(#ListIcon_2)-1,*thisClient\ClientID)
          CompilerEndIf
        EndIf
        ;- Fuck OOC
        
      Case "HP"         
        If *thisClient\CID>=0
          If *thisClient\type=#VNO
            
          Else            
          bar=Val(StringField(rawreceive$,3,"#"))
          If bar>=0 And bar<=10
            WriteLog("["+GetCharacterName(*thisClient)+"] changed the bars",*thisClient)
            If StringField(rawreceive$,2,"#")="1"
              Channels(*thisClient\area)\good=bar
              SendTarget("Area"+Str(*thisClient\area),"HP#1#"+Str(Channels(*thisClient\area)\good)+"#%",*thisClient)
            ElseIf StringField(rawreceive$,2,"#")="2"
              Channels(*thisClient\area)\evil=bar
              SendTarget("Area"+Str(*thisClient\area),"HP#2#"+Str(Channels(*thisClient\area)\evil)+"#%",*thisClient)
            EndIf
            send=1
          Else
            WriteLog("["+GetCharacterName(*thisClient)+"] fucked up the bars",*thisClient)
            *thisClient\hack=1
            rf=1
          EndIf
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
                If Clients()\area=*thisClient\area
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
          If *thisClient\perm Or Characters(char)\pw=""
            If akchar=0 Or *thisClient\CID=char Or BlockTaken=0
              SendTarget(Str(ClientID),"PV#"+Str(*thisClient\AID)+"#CID#"+Str(char)+"#%",Server)               
              *thisClient\CID=char                
              WriteLog("chose character: "+GetCharacterName(*thisClient),*thisClient)
              SendTarget(Str(ClientID),"HP#1#"+Str(Channels(*thisClient\area)\good)+"#%",Server)
              SendTarget(Str(ClientID),"HP#2#"+Str(Channels(*thisClient\area)\evil)+"#%",Server)
              If motd$<>""
                SendTarget(Str(ClientID),motd$,Server)
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
                If Clients()\area=*thisClient\area
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
              *thisClient\CID=start
              SendTarget(Str(ClientID),"Allowed#"+GetCharacterName(*thisClient)+"#%",Server)
              SendTarget(Str(ClientID),"YI#0#"+Str(*thisClient\Inventory[0])+"#%",Server)
              WriteLog("chose character: "+GetCharacterName(*thisClient),*thisClient)
              For ac=0 To areas
                If Channels(ac)\players>0
                  SendTarget(Str(ClientID),"RaC#"+Str(ac+1)+"#"+Channels(ac)\players+"#%",Server)
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
                If Clients()\area=*thisClient\area
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
              *thisClient\CID=char
              SendTarget(Str(ClientID),"OC#"+Str(char)+"#0#%",Server)
              WriteLog("chose character: "+GetCharacterName(*thisClient),*thisClient)
            ElseIf password$=oppass$
              *thisClient\CID=char
              *thisClient\perm=#MOD
              SendTarget(Str(ClientID),"OC#"+Str(char)+"#3#%",Server)
              SendTarget(Str(ClientID),"MK#%",Server)
              WriteLog("chose character: "+GetCharacterName(*thisClient)+" and logged in as mod",*thisClient)
            ElseIf password$=adminpass$
              *thisClient\CID=char
              *thisClient\perm=#ADMIN
              SendTarget(Str(ClientID),"OC#"+Str(char)+"#3#%",Server)
              SendTarget(Str(ClientID),"MK#%",Server)
              WriteLog("chose character: "+GetCharacterName(*thisClient)+" and logged in as admin",*thisClient)
            Else
              SendTarget(Str(ClientID),"OC#"+Str(char)+"#2#%",Server)
            EndIf
            rf=1
          Else
            SendTarget(Str(ClientID),"OC#"+Str(char)+"#1#%",Server)
          EndIf
        EndIf
        
      Case "AA"
        SwitchChannels(*thisClient,StringField(rawreceive$,2,"#"),StringField(rawreceive$,3,"#"))
        
      Case "RT"
        WriteLog("WT/CE "+Mid(rawreceive$,coff),*thisClient)
        If *thisClient\CID>=0
          If rt=1
            Sendtarget("Area"+Str(*thisClient\area),"RT#"+Mid(rawreceive$,coff),*thisClient)
          EndIf
        Else
          *thisClient\hack=1
          rf=1
        EndIf
        
        WriteLog("["+GetCharacterName(*thisClient)+"] WT/CE button",*thisClient)
        
      Case "askchaa" ;what is left to load
        *thisClient\cconnect=1
        If CharacterNumber>100
          If *thisClient\type>=#AOA Or CharLimit=0
            SendTarget(Str(ClientID),"SI#"+Str(characternumber)+"#"+Str(EviNumber)+"#"+Str(tracks)+"#%",Server)
          Else
            SendTarget(Str(ClientID),"SI#100#"+Str(EviNumber)+"#"+Str(tracks)+"#%",Server)
          EndIf
        Else
          SendTarget(Str(ClientID),"SI#"+Str(characternumber)+"#"+Str(EviNumber)+"#"+Str(tracks)+"#%",Server)
        EndIf
        
      Case "askchar2" ; character list
        SendTarget(Str(ClientID),ReadyChar(0),Server)
        
      Case "RC"
        If *thisClient\type=#NOTYPE
          *thisClient\type=#AOTWO
          EndIf
        SendTarget(Str(ClientID),newcready$,Server)
;         Dim APlayers(characternumber)
;         send$="TC"
;         LockMutex(ListMutex)
;         PushMapPosition(Clients())
;         ResetMap(Clients())
;         While NextMapElement(Clients())
;           If Clients()\CID>=0 And Clients()\CID <= characternumber
;             If Clients()\area=*thisClient\area
;               APlayers(Clients()\CID)=1
;             EndIf
;           EndIf
;         Wend
;         PopMapPosition(Clients())
;         UnlockMutex(ListMutex)
;         For sentchar=0 To characternumber
;           If APlayers(sentchar)=1 And Characters(sentchar)\pw<>""
;             send$ = send$ + "#3"
;           ElseIf APlayers(sentchar)=1
;             send$ = send$ + "#1"
;           ElseIf Characters(sentchar)\pw<>""
;             send$ = send$ + "#2"
;           Else
;             send$ = send$ + "#0"
;           EndIf
;         Next
;         send$ = send$ + "#%"
;         SendTarget(Str(ClientID),send$,Server)
        
      Case "RM"
        SendTarget(Str(ClientID),newmready$,Server)
        
        Case "RD"
        SendDone(*thisClient)
        
      Case "RA"
        SendTarget(Str(ClientID),newaready$,Server)
        send$="TA"
        For carea=0 To ChannelCount
          send$ = send$ + "#"+Str(Channels(carea)\players)
        Next
        send$ = send$ + "#%"
        SendTarget(Str(*thisClient\ClientID),send$,Server)
        
      Case "AN" ; character list
        start=Val(StringField(rawreceive$,2,"#"))
        If start*10<characternumber And start>=0 ;And ( start*10<100 Or *thisClient\type>4 )
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
          SendDone(*thisClient)
        EndIf
        
      Case "RCD" ; character list
        start=Val(StringField(rawreceive$,2,"#"))-1
        *thisClient\type=#VNO
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
          SendTarget(Str(ClientID),"AD#1#" + Channels(0)\name + "#"+Str(Channels(0)\players)+"#"+ Channels(0)\bg + "##%",Server)
        EndIf
        
      Case "RAD" ; area list
        start=Val(StringField(rawreceive$,2,"#"))-1
        If start<=ChannelCount And start>=0
          If Channels(start)\pw<>""
            passworded$="LOCK"
          Else
            passworded$=""
          EndIf
          Readyv$ = "AD#" + Str(start+1) + "#" + Channels(start)\name + "#0#"+ Channels(start)\bg + "#"+passworded$ + "#%"
          SendTarget(Str(ClientID),Readyv$,Server)        
        ElseIf itemamount>0
          SendTarget(Str(ClientID),ReadyVItem(0),Server)
        Else
          SendTarget(Str(ClientID),"LCA#"+*thisClient\username+"#$NO#%",Server)
        EndIf
        
       Case "PE"
        If *thisClient\perm>=#ANIM
          WriteLog("Add Evidence "+StringField(rawreceive$,2,"#"),*thisClient)
          EviNumber+1
          eeid=EviNumber
            ReDim Evidences(EviNumber)
            Evidences(eeid)\name=StringField(rawreceive$,2,"#")
            Evidences(eeid)\desc=StringField(rawreceive$,3,"#")
            Evidences(eeid)\type=0
            Evidences(eeid)\image=StringField(rawreceive$,4,"#")
            SendUpdatedEvi("*")
          EndIf
        
         Case "DE"
        If *thisClient\perm>=#ANIM
          eeid=Val(StringField(rawreceive$,2,"#"))
          WriteLog("Delete Evidence "+Str(eeid),*thisClient)
          If eeid>=0 And eeid<=EviNumber
            eepar$=StringField(rawreceive$,3,"#")
            Evidences(eeid)\name=""
            Evidences(eeid)\desc=""
            Evidences(eeid)\type=0
            Evidences(eeid)\image=""
            If EviNumber=eeid
            EviNumber-1
            EndIf
            SendUpdatedEvi("*")
          EndIf
        EndIf
        
      Case "EE"
        If *thisClient\perm>=#ANIM
          eeid=Val(StringField(rawreceive$,2,"#"))
          WriteLog("Edit Evidence "+Str(eeid),*thisClient)
          If eeid>=0 And eeid<=EviNumber
            Evidences(eeid)\name=StringField(rawreceive$,3,"#")
            Evidences(eeid)\desc=StringField(rawreceive$,4,"#")
            Evidences(eeid)\image=StringField(rawreceive$,5,"#")
            SendUpdatedEvi("*")
          EndIf
        EndIf
        
      Case "ITD" ; item list
        start=Val(StringField(rawreceive$,2,"#"))-1
        If start<=itemamount-1 And start>=0          
          SendTarget(Str(ClientID),ReadyVItem(start),Server)
        Else
          SendTarget(Str(ClientID),"LCA#"+*thisClient\username+"#$NO#%",Server)
        EndIf
        
      Case "ID"
        Debug rawreceive$
        If StringField(rawreceive$,2,"#")="AO2"
          *thisClient\type=#AOTWO
        EndIf
        
      Case "HI" ;what is this server
        hdbanned=0
        *thisClient\HD = StringField(rawreceive$,2,"#")
        WriteLog("HdId="+*thisClient\HD,*thisClient)
        *thisClient\sHD = 1
        
        If loghd
          OpenFile(8,"base/hd.txt")
          WriteStringN(8,*thisClient\IP+","+*thisClient\HD)
          CloseFile(8)
        EndIf
        
        ForEach SDBans()
          Debug *thisClient\HD
          If *thisClient\HD = SDbans()\banned Or *thisClient\IP=SDBans()\banned
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
            If *thisClient\HD = HDbans()\banned
              WriteLog("HD: "+*thisClient\HD+" is banned, reason: "+HDbans()\reason,*thisClient)
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
            If *thisClient\HD = HDmods()
              *thisClient\perm=#MOD
            EndIf
          Next
          
          If StringField(rawreceive$,4,"#")<>"" Or Left(*thisClient\HD,2)="2."
            *thisClient\type=#AOTWO
          EndIf
          
          SendTarget(Str(ClientID),"ID#"+Str(*thisClient\AID)+"#serverD&"+version$+"#%",Server)
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
          SendTarget(Str(ClientID),"FL#noencryption#yellowtext#arup#customobjections#flipping#fastloading#deskmod#evidence#%",Server)
        EndIf
        rf=1
        
        
      Case "DC"
        If Channels(*thisClient\area)\lock=ClientID
          Channels(*thisClient\area)\lock=0
          Channels(*thisClient\area)\mlock=0
        EndIf
        *thisClient\CID=-1
        *thisClient\ignore=1
        
      Case "FC"
        *thisClient\CID=-1
        SendTarget(Str(*thisClient\ClientID),"DONE#%",Server)
        WriteLog("freed char",*thisClient)
        
      Case "Change"
        *thisClient\CID=-1
        WriteLog("freed char",*thisClient)
        
      Case "ARC"
        SwitchChannels(*thisClient,StringField(rawreceive$,2,"#"),StringField(rawreceive$,3,"#"))
        
      Case "CA"
        If *thisClient\perm
          If CommandThreading
            CreateThread(@ListIP(),ClientID)
          Else
            ListIP(ClientID)
          EndIf
          WriteLog("["+GetCharacterName(*thisClient)+"] used /ip (clientside)",*thisClient)
        EndIf 
        
      Case "opKICK"
        If *thisClient\perm>=#MOD
          akck=KickBan(StringField(rawreceive$,2,"#"),"",#KICK,*thisClient)
          SendTarget(Str(ClientID),"CT#$HOST#kicked "+Str(akck)+" clients#%",Server)
        EndIf
        WriteLog("["+GetCharacterName(*thisClient)+"] used opKICK",*thisClient)
        
      Case "opBAN"
        If *thisClient\perm>=#MOD
          akck=KickBan(StringField(rawreceive$,2,"#"),"",#BAN,*thisClient)
          SendTarget(Str(ClientID),"CT#$HOST#banned "+Str(akck)+" clients#%",Server)
        EndIf
        WriteLog("["+GetCharacterName(*thisClient)+"] used opBAN",*thisClient)
        
      Case "opMUTE"
        If *thisClient\perm
          akck=KickBan(StringField(rawreceive$,2,"#"),"",#MUTE,*thisClient)
          SendTarget(Str(ClientID),"CT#$HOST#muted "+Str(akck)+" clients#%",Server)
        EndIf
        WriteLog("["+GetCharacterName(*thisClient)+"] used opMUTE",*thisClient)
        
      Case "opunMUTE"
        If *thisClient\perm
          akck=KickBan(StringField(rawreceive$,2,"#"),"",#UNMUTE,*thisClient)
          SendTarget(Str(ClientID),"CT#$HOST#unmuted "+Str(akck)+" clients#%",Server)
        EndIf
        WriteLog("["+GetCharacterName(*thisClient)+"] used opunMUTE",*thisClient)
        
      Case "VERSION"
        SendTarget(Str(ClientID),"CT#$HOST#"+version$+"#%",Server)
        
      Case "ZZ"
        If *thisClient\CID>=0
          WriteLog("called mod",*thisClient)
        EndIf
        LockMutex(ListMutex)  
        ResetMap(Clients())
        While NextMapElement(Clients())
          If Clients()\perm
            SendTarget(Str(Clients()\ClientID),"ZZ#"+*thisClient\IP+" in "+GetAreaName(*thisClient)+", reason: "+StringField(rawreceive$,2,"#")+"#%",*thisClient)  
          Else
            SendTarget(Str(Clients()\ClientID),"ZZ#someone#%",*thisClient)
          EndIf
        Wend   
        UnlockMutex(ListMutex)
        CompilerIf #WEB
        Case "GET"
          *thisClient\type=#WEBBROWSER
          RequestedFile$=StringField(StringField(rawreceive$,2," "),1,"?")
          GETrequest(RequestedFile$,ClientID)
        CompilerEndIf
      Default
        WriteLog(rawreceive$,*thisClient)
    EndSelect
  EndIf
  StopProfiler()
EndProcedure

;- Network Thread
Procedure Network(var)
  Define SEvent,ClientID,send,length
  Define ip$,rawreceive$,sc
  Define *thisClient.Client
  
  SEvent = NetworkServerEvent()
  ClientID = EventClient()
  Select SEvent
    Case 0
      Delay(LagShield)
      
    Case #PB_NetworkEvent_Disconnect      
      RemoveDisconnect(ClientID)
      
    Case #PB_NetworkEvent_Connect
      cType=#NOTYPE
      If ClientID
        send=1
        ip$=IPString(GetClientIP(ClientID))
        
        ForEach IPbans()
          If Left(ip$,Len(IPbans()\banned)) = IPbans()\banned
            send=0
            WriteLog("IP: "+ip$+" is banned,reason: "+IPbans()\reason,Server)
            CloseNetworkConnection(ClientID)                   
            Break
          EndIf
        Next 
        
        CompilerIf #WEB
          Delay(100)
          length=ReceiveNetworkData(ClientID,*Buffer,2048)
          Debug "eaoe"
          Debug length
          If length<>-1
            Debug "wotf"
            rawreceive$=PeekS(*Buffer,length)
            Debug rawreceive$
            If length>=0
              headeririda$ = StringField(rawreceive$,1,#CRLF$)
              wkeypos=FindString(rawreceive$,"Sec-WebSocket-Key")
                If wkeypos
                  cType=#WEBSOCKET
                  wkey$ = Mid(rawreceive$,wkeypos+19,24)
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
                  Debug vastus$
                  SendNetworkString(ClientID,vastus$)
                ElseIf Left(rawreceive$,3) = "GET"
                  Debug "getline"
                  cType=#WEBBROWSER
                  RequestedFile$=StringField(StringField(headeririda$,2," "),1,"?")
                  GETrequest(RequestedFile$,ClientID)
                  CloseNetworkConnection(ClientID)
                  send=0
                EndIf
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
          Clients()\perm=#USER
          ForEach HDmods()
            If ip$ = HDmods()
              Clients()\perm=#ANIM
            EndIf
          Next
          Clients()\area=0
          Channels(0)\players+1
          Clients()\ignore=0
          Clients()\judget=0
          Clients()\ooct=0
          Clients()\gimp=0
          Clients()\ignoremc=0
          Clients()\type=cType
          Clients()\username=""
          SendTarget(Str(ClientID),"PC#"+Str(players)+"#"+slots$+"#"+Str(CharacterNumber)+"#"+Str(tracks)+"#"+Str(ChannelCount)+"#"+Str(EviNumber)+"#%",Server)
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
          CompilerIf #PLUGINS
          If ListSize(Plugins())
            ResetList(Plugins())
            While NextElement(Plugins())
              pStat=#NODATA
              CallFunctionFast(Plugins()\gcallback,#CONN)    
              CallFunctionFast(Plugins()\rawfunction,Clients())
            Wend
          EndIf
          CompilerEndIf
          UnlockMutex(ListMutex)
        EndIf
      EndIf
      
    Case #PB_NetworkEvent_Data ;- Received Data
      *thisClient.Client=FindMapElement(Clients(),Str(ClientID))
      If *thisClient
        length=ReceiveNetworkData(ClientID,*Buffer,2048)
        If length
          rawreceive$=PeekS(*Buffer,length)
          Debug rawreceive$
          CompilerIf #WEB
            If *thisClient\type=#WEBSOCKET And WebSockets              
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
                  Debug "MaskKey " + Str(n + 1) + ": " + RSet(Hex(MaskKey(n)),2,"0")
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
                    vastus$ = PeekS(*Buffer + Ptr,Payload)
                  EndIf
                  rawreceive$=vastus$
                Case #PingFrame
                  Byte = PeekA(*Buffer) & %11110000
                  PokeA(*Buffer,Byte | #PongFrame)
                  SendNetworkData(ClientID,*Buffer,bytesidkokku)
                Case #ConnectionCloseFrame
                  RemoveDisconnect(ClientID)
                  rawreceive$=""
              EndSelect
            EndIf
          CompilerEndIf
          
          sc=1
          While StringField(rawreceive$,sc,"%")<>""
            subcommand$=ValidateChars(StringField(rawreceive$,sc,"%")+"%")
            Debug subcommand$
            length=Len(subcommand$)
            
            If ExpertLog
              WriteLog(subcommand$,*thisClient)
            EndIf
            
            If ReplayMode=1 Or Not *thisClient\last.s=subcommand$ And *thisClient\ignore=0 
              *thisClient\last.s=subcommand$
              If CommandThreading
                CreateThread(@HandleAOCommand(),ClientID)
              Else
                HandleAOCommand(ClientID)
              EndIf
              CompilerIf #PLUGINS
              If ListSize(Plugins())
                ResetList(Plugins())
                While NextElement(Plugins())
                  pStat=#NODATA
                  CallFunctionFast(Plugins()\gcallback,#DATA)    
                  CallFunctionFast(Plugins()\rawfunction,*thisClient)
                  pStat=CallFunctionFast(Plugins()\gcallback,#SEND)
                  Select pStat
                    Case #SEND
                      ptarget$=PeekS(CallFunctionFast(Plugins()\gtarget))
                      pmes$=PeekS(CallFunctionFast(Plugins()\gmessage))
                      SendTarget(ptarget$,pmes$,Server)
                  EndSelect
                Wend
              EndIf
              CompilerEndIf
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

If ReceiveHTTPFile("http://raw.githubusercontent.com/stonedDiscord/serverD/master/version.txt","version.txt")
  OpenPreferences("version.txt")
  PreferenceGroup("Version")
  newbuild=ReadPreferenceInteger("Build",#PB_Editor_BuildCount)
  Debug newbuild
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
; CursorPosition = 2288
; FirstLine = 2265
; Folding = ------
; EnableUnicode
; EnableXP