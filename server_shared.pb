CompilerIf #PB_Compiler_OS <> #PB_OS_Windows
  #MB_ICONERROR=0
  Global libext$=".so"
CompilerElse
  Global libext$=".dll"
CompilerEndIf

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

;- Global variables
#C1 = 53761
#C2 = 32618
Global version$=Str(#PB_Editor_CompileCount)+"."+Str(#PB_Editor_BuildCount)
Global CommandThreading=0
Global Dim MaskKey.a(3)
Global Quit=0
Global ReplayMode=0
Global ReplayLength=0
Global ReplayFile$=""
Global LoopMusic=0
Global MultiChar=1
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
Global AllowCutoff.b=0
Global CharLimit=1
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
Global ExpertLog=0
Global tracks=0
Global msthread=0
Global msvthread=0
Global LoginReply$="CT#$HOST#Successfully connected as mod#%"
Global motd$="CT#$SERVER#Running serverD version "+version$+"#%"
Global musicpage=0
Global EviNumber=0
Global ListMutex = CreateMutex()
Global EviMutex = CreateMutex()
Global MusicMutex = CreateMutex()
Global RefreshMutex = CreateMutex()
Global ActionMutex = CreateMutex()
Global musicmode=1
Global update=0
Global ChannelCount=1
Global decryptor$
Global key
Global newbuild
Global *Buffer = AllocateMemory(4096)
Global NewList HDmods.s()
Global NewList gimps.s()
Global NewList PReplay.s()
Global Dim Icons.l(2)
Global Dim ReadyChar.s(1000)
Global newcready$="SC#%"
Global newmready$="SM#%"
Global newaready$="SA#%"
Global Dim ReadyVItem.s(1000)
Global Dim ReadyVMusic.s(1000)
Global Dim ReadyEvidence.s(1000)
Global Dim ReadyMusic.s(5000)

XIncludeFile "../serverD/shared_headers.pb"
CompilerIf #PLUGINS
Global NewList Plugins.Plugin()

Prototype.i PPluginVersion()
Prototype.l PPluginName()
Prototype.l PPluginDescription()
Prototype.i PPluginRAW()
CompilerEndIf

Global Dim Channels.Channel(200)
Define InitChannel
For InitChannel=0 To 200
  Channels(InitChannel)\waitstart=ElapsedMilliseconds()
  Channels(InitChannel)\waitdur=0
  Channels(InitChannel)\lock=0
  Channels(InitChannel)\mlock=0
Next

Global Dim Evidences.Evidence(1000)

Global Dim Characters.ACharacter(200)

Global NewList Music.Track()

Global Server.Client
Server\ClientID=-1
Server\IP="$HOST"
Server\AID=-3
Server\CID=-3
Server\perm=#SERVER
Server\ignore=0
Server\ignoremc=0
Server\hack=0
Server\area=-1
Server\last=""
Server\cconnect=0
Server\ooct=0
Server\type=#MASTER
Server\username="$HOST"
Global NewMap Clients.Client()

Global NewList HDbans.TempBan()
Global NewList IPbans.TempBan()
Global NewList SDbans.TempBan()

Global NewList Actions.Action()

CompilerIf #CONSOLE=0
  IncludeFile "Common.pb"
CompilerEndIf

Procedure.s ValidateChars(source.s)
  ProcedureReturn source.s
EndProcedure

Procedure.s Encode(smes$)
  smes$=ValidateChars(smes$)
  smes$=ReplaceString(smes$,"%n",#CRLF$)
  smes$=ReplaceString(smes$,"$n",#CRLF$)
  smes$=ReplaceString(smes$,"#","<num>")
  smes$=ReplaceString(smes$,"&","<and>")
  smes$=ReplaceString(smes$,"%","<percent>")
  smes$=ReplaceString(smes$,"$","<dollar>")
  ProcedureReturn smes$
EndProcedure

Procedure.s Escape(smes$)
  smes$=ReplaceString(smes$,"<num>","#")
  smes$=ReplaceString(smes$,"<pound>","#")
  smes$=ReplaceString(smes$,"<and>","&")
  smes$=ReplaceString(smes$,"<percent>","%")
  smes$=ReplaceString(smes$,"<dollar>","$")
  ProcedureReturn smes$
EndProcedure

Procedure.s GetRankName(rank)
  Select rank
    Case #ANIM
      ProcedureReturn "(animator)"
    Case #MOD
      ProcedureReturn "(mod)"
    Case #ADMIN
      ProcedureReturn "(admin)"
    Case #SERVER
      ProcedureReturn "(server)"
    Default
      ProcedureReturn ""
  EndSelect
EndProcedure

Procedure.s GetCharacterName(*nclient.Client)
  Define name$
  If *nclient\CID>=0 And *nclient\CID<=CharacterNumber
    name$=Characters(*nclient\CID)\name
  ElseIf *nclient\CID=-1
    name$="$UNOWN"
  ElseIf *nclient\CID=-3
    name$="$HOST"
  Else
    name$="HACKER"
    *nclient\hack=1
    rf=1
  EndIf
  ProcedureReturn name$
EndProcedure

Procedure.s GetAreaName(*nclient.Client)
  Define name$
  Debug *nclient\area
  If *nclient\area>=0 And *nclient\area<=ChannelCount
    name$=Channels(*nclient\area)\name
  ElseIf *nclient\area=-3
    name$="RAM"
  Else
    name$="$NONE"
  EndIf
  ProcedureReturn name$
EndProcedure

Procedure WriteLog(string$,*lclient.Client)
  Define mstr$,logstr$
  ; [23:21:05] David Skoland: (If mod)[M][IP][Timestamp, YYYYMMDDHHMM][Character][Message]
  Select *lclient\perm
    Case #MOD
      mstr$="[M]"
    Case #ADMIN
      mstr$="[A]"
    Case #SERVER
      mstr$="[S]"
    Default
      mstr$="[U]"
  EndSelect
  logstr$=mstr$+"["+LSet(*lclient\IP,15)
  logstr$=logstr$+"]"+"["+FormatDate("%yyyy.%mm.%dd %hh:%ii:%ss",Date())+"]["+GetCharacterName(*lclient)+"]["+GetAreaName(*lclient)+"]"+string$
  If Logging
    WriteStringN(1,logstr$)
  EndIf
  CompilerIf #CONSOLE
    PrintN(logstr$)
  CompilerElse
    If Quit=0
      CompilerIf #NICE
        AddGadgetItem(#listbox_event,-1,string$)
      CompilerElse
        AddGadgetItem(#listbox_event,-1,"["+GetCharacterName(*lclient)+"]["+GetAreaName(*lclient)+"]"+string$)
      CompilerEndIf
      SetGadgetItemData(#listbox_event,CountGadgetItems(#listbox_event)-1,*lclient\ClientID)
    EndIf
  CompilerEndIf   
EndProcedure

;- Signal handling on linux
CompilerIf #PB_Compiler_OS = #PB_OS_Linux
  #SIGINT = 2
  #SIGQUIT   =   3
  #SIGABRT   =   6
  #SIGKILL       =   9
  #SIGTERM   =   15
  
  ProcedureC on_killed_do(signum)
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
    WriteLog("KILLED",Server)
    End
  EndProcedure
  signal_(#SIGINT,@on_killed_do())
  signal_(#SIGQUIT,@on_killed_do())
  signal_(#SIGABRT,@on_killed_do())
  signal_(#SIGKILL,@on_killed_do())
  signal_(#SIGTERM,@on_killed_do())
CompilerEndIf

CompilerIf #WEB
  Enumeration ;WebsocketOpcodes
    #ContinuationFrame
    #TextFrame
    #BinaryFrame
    #Reserved3Frame
    #Reserved4Frame
    #Reserved5Frame
    #Reserved6Frame
    #Reserved7Frame
    #ConnectionCloseFrame
    #PingFrame
    #PongFrame
    #ReservedBFrame
    #ReservedCFrame
    #ReservedDFrame
    #ReservedEFrame
    #ReservedFFrame
  EndEnumeration
  
  #ServerSideMasking = #False
  CompilerIf #ServerSideMasking
    #ServerSideMaskOffset = 4
  CompilerElse
    #ServerSideMaskOffset = 0
  CompilerEndIf
  
  #GUID$ = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
  
  Procedure.s SecWebsocketAccept(Client_Key.s)
    
    Protected *Temp_Data, *Temp_Data_2, *Temp_Data_3
    Protected Temp_String.s, Temp_String_ByteLength.i
    Protected Temp_SHA1.s
    Protected i
    Protected Result.s
    
    Temp_String.s = Client_Key + #GUID$
    
    ; #### Convert to ASCII
    Temp_String_ByteLength = StringByteLength(Temp_String, #PB_Ascii)
    *Temp_Data = AllocateMemory(Temp_String_ByteLength + SizeOf(Character))
    PokeS(*Temp_Data, Temp_String, -1, #PB_Ascii)
    
    ; #### Generate the SHA1
    *Temp_Data_2 = AllocateMemory(20)
    Temp_SHA1.s = SHA1Fingerprint(*Temp_Data, Temp_String_ByteLength)
    For i = 0 To 19
      PokeA(*Temp_Data_2+i, Val("$"+Mid(Temp_SHA1, 1+i*2, 2)))
    Next
    
    ; #### Encode the SHA1 as Base64
    *Temp_Data_3 = AllocateMemory(30)
    Base64Encoder(*Temp_Data_2, 20, *Temp_Data_3, 30)
    
    Result = PeekS(*Temp_Data_3, -1, #PB_Ascii)
    
    FreeMemory(*Temp_Data)
    FreeMemory(*Temp_Data_2)
    FreeMemory(*Temp_Data_3)
    
    ProcedureReturn Result
  EndProcedure
  
  Procedure.i Websocket_SendTextFrame(ClientID.i, Text$)
    
    Protected.a Byte
    Protected.i Result, Length, Add, i, Ptr
    Protected *Buffer
    Protected Dim bKey.a(3)
    
    
    Length = StringByteLength(Text$, #PB_UTF8)
    Debug Length
    If Length < 65535
      
      If Length < 126
        Add = 2 + #ServerSideMaskOffset
      Else
        Add = 4 + #ServerSideMaskOffset
      EndIf
      
      *Buffer = AllocateMemory(Length + Add + 1)
      If *Buffer
        
        Ptr = 0
        Byte = %10000000 | #TextFrame
        PokeA(*Buffer + Ptr, Byte)
        Ptr + 1
        If Add = 2 + #ServerSideMaskOffset
          CompilerIf #ServerSideMasking
            PokeA(*Buffer + Ptr, %10000000 | Length)
          CompilerElse
            PokeA(*Buffer + Ptr, %00000000 | Length)
          CompilerEndIf
          Ptr + 1
        Else
          CompilerIf #ServerSideMasking
            PokeA(*Buffer + Ptr, %10000000 | 126)
          CompilerElse
            PokeA(*Buffer + Ptr, %00000000 | 126)
          CompilerEndIf
          Ptr + 1
          PokeA(*Buffer + Ptr, Length >> 8)
          Ptr + 1
          PokeA(*Buffer + Ptr, Length & $FF)
          Ptr + 1
        EndIf
        
        CompilerIf #ServerSideMasking
          For i = 0 To 3
            bKey(i) = Random(255)
            PokeA(*Buffer + Ptr + i, bKey(i))
          Next i
          Ptr + 4
        CompilerEndIf
        
        PokeS(*Buffer + Ptr, Text$, -1, #PB_UTF8)
        
        CompilerIf #ServerSideMasking
          For i = 0 To Length - 1       
            PokeA(*Buffer + Ptr + i, PeekA(*Buffer + Ptr + i) ! bKey(i % 4))
          Next i
        CompilerEndIf
        
        If SendNetworkData(ClientID, *Buffer, Length + Add) > 0
          Result = #True
        EndIf
        
        FreeMemory(*Buffer)
      EndIf
    EndIf
    
    ProcedureReturn Result
    
  EndProcedure
  ;Used procedures
  Procedure.s DayInText(dd)
    Protected d$
    Select DayOfWeek(dd)
      Case 1: d$="Mon"
      Case 2: d$="Tue"
      Case 3: d$="Wed"
      Case 4: d$="Thu"
      Case 5: d$="Fri"
      Case 6: d$="Sat"
      Default: d$="Sun"
    EndSelect
    ProcedureReturn d$
  EndProcedure
  
  Procedure.s MonthInText(dd)
    Protected  m$
    Select Month(dd)  
      Case 1: m$="Jan"
      Case 2: m$="Feb"
      Case 3: m$="Mar"
      Case 4: m$="Apr"
      Case 5: m$="May"
      Case 6: m$="Jun"
      Case 7: m$="Jul"
      Case 8: m$="Aug"
      Case 9: m$="Sep"
      Case 10:m$="Oct"
      Case 11:m$="Nov"
      Default:m$="Dec"
    EndSelect
    ProcedureReturn m$
  EndProcedure
  
  Procedure.s MIME(RFile$)    
    Select Right(RFile$,4)
      Case ".gif"
        ContentType$ = "image/gif"                      
      Case ".png"
        ContentType$ = "image/png"                      
      Case ".ico"
        ContentType$ = "image/x-icon"
      Case ".css"
        ContentType$ = "text/css"
      Case ".htm"
        ContentType$ = "text/html"   
      Default        
        If Right(RFile$,3)=".js"
          ContentType$ = "text/javascript" 
        ElseIf Right(RFile$,5)=".html"
          ContentType$ = "text/html" 
        Else        
          ContentType$ = "text/plain"   
        EndIf
    EndSelect
    ProcedureReturn ContentType$
  EndProcedure
  
CompilerEndIf

Procedure RemoveDisconnect(ClientID)
  LockMutex(ListMutex)
  If FindMapElement(Clients(),Str(ClientID))
    WriteLog("DISCONNECTING",Clients())
    If Channels(Clients()\area)\lock=ClientID
      Channels(Clients()\area)\lock=0
      Channels(Clients()\area)\mlock=0
    EndIf
    If Clients()\area>=0
      Channels(Clients()\area)\players-1
    EndIf
    CompilerIf #NICE
      If OpenFile(7,"base/scene/"+scene$+"/PlayerData/"+Clients()\username+".txt")
        For ir=0 To itemamount
          WriteStringN(7,Str(Clients()\Inventory[ir]))
        Next
        CloseFile(7)
      EndIf
    CompilerEndIf
    CompilerIf #PLUGINS
    If ListSize(Plugins())
      ResetList(Plugins())
      While NextElement(Plugins())
        pStat=#NODATA
        CallFunctionFast(Plugins()\gcallback,#DISC)    
        CallFunctionFast(Plugins()\rawfunction,Clients())
      Wend
    EndIf
    CompilerEndIf
    DeleteMapElement(Clients(),Str(ClientID))
    rf=1
  EndIf
  UnlockMutex(ListMutex)  
EndProcedure

Procedure GETrequest(requestedFile$,ClientID)
  Debug "rfile"
  Debug RequestedFile$
  If RequestedFile$ = "" Or RequestedFile$ = "/"
    RequestedFile$ = "index.html"
  EndIf
  
  If ReadFile(0,"cbase/"+RequestedFile$)
    
    FileLength = Lof(0)
    ContentType$ = MIME(RequestedFile$)
    RFileDate=GetFileDate("cbase/"+RequestedFile$,#PB_Date_Modified)
    RHeader$="HTTP/1.0 200 OK"+#CRLF$+"Last-Modified: "+DayInText(RFileDate)+", "+Day(RFileDate)+" "+MonthInText(RFileDate)+" "+FormatDate("%yyyy %hh:%ii:%ss",RFileDate)+" GMT"+#CRLF$+"Content-Type: "+ContentType$+#CRLF$+"Content-Length: "+Str(FileLength)+#CRLF$+"Cache-Control: max-age=2628000, public"+#CRLF$+#CRLF$
    *FileBuffer   = AllocateMemory(FileLength+Len(RHeader$)+20)
    HLength=PokeS(*FileBuffer,RHeader$,#PB_String_NoZero)  
    *BufferOffset = *FileBuffer+HLength
    WriteLog(ip$+" requested file "+RequestedFile$,Server)
    ReadData(0,*BufferOffset,FileLength)
    Debug "headerlength"
    Debug HLength
    CloseFile(0)
    Debug PeekS(*FileBuffer,HLength+FileLength)
    SendNetworkData(ClientID,*FileBuffer,HLength+FileLength)
    FreeMemory(*FileBuffer)
  Else
    RHeader$="HTTP/1.0 404 NOT FOUND"+#CRLF$+#CRLF$
    SendNetworkString(ClientID,RHeader$)
  EndIf
  Debug "not funny"                    
  
EndProcedure

Procedure SendString(ClientID,message$)
  Select Clients()\type
    Case #WEBSOCKET
      CompilerIf #WEB
        Websocket_SendTextFrame(ClientID,message$)
      CompilerEndIf
    Case #AOTWO
      sresult=SendNetworkString(ClientID,message$)
    Default
      sresult=SendNetworkString(ClientID,message$)
  EndSelect
  If sresult=-1
    WriteLog("CLIENT DIED DIRECTLY",Server)
    RemoveDisconnect(ClientID)
  EndIf
EndProcedure

Procedure SendTarget(user$,message$,*sender.Client)
  Define everybody,i,omessage$,sresult
  omessage$=message$
  
  If user$="*" Or user$="everybody"
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
    SendString(Clients()\ClientID,message$)
  Else
    ResetMap(Clients())
    While NextMapElement(Clients())
      If user$=Str(Clients()\CID) Or user$=Clients()\HD Or user$=Clients()\IP Or user$=Clients()\username Or user$="Area"+Str(Clients()\area) Or everybody
        SendString(Clients()\ClientID,message$)
      EndIf
    Wend   
  EndIf
  UnlockMutex(ListMutex)
EndProcedure

Procedure SendChatMessage(*ntmes.ChatMessage,*seUser.Client)
  Define everybody,i,omessage$,sresult
  WriteLog("[MAIN]"+*ntmes\message,*seUser)
  If Channels(*seUser\area)\waitstart+Channels(*seUser\area)\waitdur<=ElapsedMilliseconds() Or AllowCutoff Or *seUser\skip
    If BlockINI
      *ntmes\char=GetCharacterName(*seUser)
    EndIf
    If *ntmes\color=modcol And *seUser\perm<#MOD
      *ntmes\color=0
    EndIf
    
    If *seUser\gimp
      If SelectElement(gimps(),Random(ListSize(gimps())-1,0))
        *ntmes\message=gimps()
      Else
        *ntmes\message="gimp.txt is empty lol"
      EndIf
    EndIf
    
    Select *ntmes\position
      Case "def"
        vpos=1;left
      Case "pro"
        vpos=2;right
      Case "wit"
        vpos=3
      Default
        vpos=3
    EndSelect
    If CharLimit
      oldCID = *seUser\CID % 100
    Else
      oldCID = *seUser\CID
    EndIf
    Channels(*seUser\area)\waitstart=ElapsedMilliseconds()
    Channels(*seUser\area)\waitdur=Len(*ntmes\message)*40
    If Channels(*seUser\area)\waitdur>600
      Channels(*seUser\area)\waitdur=1
    EndIf
    LockMutex(ListMutex)  
    ResetMap(Clients())
    While NextMapElement(Clients())
      If Clients()\area=*seUser\area And (*seUser\silence=0 Or *seUser=Clients())
        message$="MS#"+*ntmes\deskmod+"#"+*ntmes\preemote+"#"+*ntmes\char+"#"+*ntmes\emote+"#"+*ntmes\message+"#"+*ntmes\position+"#"+*ntmes\sfx+"#"
        message$=message$+Str(*ntmes\emotemod)+"#"+Str(*seUser\CID)+"#"+Str(*ntmes\animdelay)+"#"+Str(*ntmes\objmod)+"#"+Str(*ntmes\evidence)+"#"+Str(*ntmes\flip)+"#"
        message$=message$+Str(*ntmes\realization)+"#"+Str(*ntmes\color)+"#"+*ntmes\showname+"#"+*ntmes\pairchar+"###"+*ntmes\pairoffset+"#0#0#"+*ntmes\nointerrupt+"#%"
        
        Select Clients()\type
            CompilerIf #WEB
            Case #WEBSOCKET  
              Websocket_SendTextFrame(Clients()\ClientID,message$)
            CompilerEndIf
          Case #VNO
            message$="MS#"+*ntmes\char+"#"+*ntmes\emote+"#"+*ntmes\message+"#"+*ntmes\showname+"#"+*ntmes\color+"#"+Str(*seUser\CID+1)+"#"+*ntmes\background+"#"+Str(vpos)+"#"+Str(*ntmes\flip)+"#"+*ntmes\sfx+"#%"
            sresult=SendString(Clients()\ClientID,message$)
            Debug message$
            If sresult=-1
              WriteLog("CLIENT DIED",Clients())
              RemoveDisconnect(Clients()\ClientID)
            EndIf
          Case #AOTWO
            sresult=SendString(Clients()\ClientID,message$)
            If sresult=-1
              WriteLog("CLIENT DIED",Clients())
              RemoveDisconnect(Clients()\ClientID)
            EndIf
          Default
            ;MS#chat#<pre-emote>#<char>#<emote>#<mes>#<pos>#<sfx>#<zoom>#<cid>#<animdelay>#<objection-state>#<evi>#<cid>#<bling>#<color>#%%
            message$="MS#chat#"+*ntmes\preemote+"#"+*ntmes\char+"#"+*ntmes\emote+"#"+*ntmes\message+"#"+*ntmes\position+"#"+*ntmes\sfx+"#"
            message$=message$+Str(*ntmes\emotemod)+"#"+Str(oldCID)+"#"+Str(*ntmes\animdelay)+"#"+Str(*ntmes\objmod)+"#"+Str(*ntmes\evidence)+"#"+Str(oldCID)+"#"+Str(*ntmes\realization)+"#"+Str(*ntmes\color%5)+"#%"
            
            sresult=SendString(Clients()\ClientID,message$)
            If sresult=-1
              WriteLog("CLIENT DIED",Clients())
              RemoveDisconnect(Clients()\ClientID)
            EndIf
        EndSelect
      EndIf
    Wend
    UnlockMutex(ListMutex)
  EndIf
EndProcedure

Procedure TrackWait(a)
  Define stoploop,k,cw
  cw=1000
  Debug "looping enabled"
  Repeat
    For k=0 To ChannelCount
      If Channels(k)\trackwait>1
        If (Channels(k)\trackstart+Channels(k)\trackwait)<ElapsedMilliseconds()
          Channels(k)\trackstart=ElapsedMilliseconds()
          Debug "changed"
          If GetExtensionPart(Channels(k)\track)="m3u"
            If ListIndex(Channels(k)\Playlist())>=ListSize(Channels(k)\Playlist())-1
              ResetList(Channels(k)\Playlist())
            EndIf
            NextElement(Channels(k)\Playlist())
            Channels(k)\trackwait=Channels(k)\Playlist()\Length
            SendTarget("Area"+Str(k),"MC#"+Channels(k)\Playlist()\TrackName+"#"+Str(characternumber)+"#%",Server)
          Else
            SendTarget("Area"+Str(k),"MC#"+Channels(k)\track+"#"+Str(characternumber)+"#%",Server)
          EndIf
        Else
          If Channels(k)\trackwait<cw
            ;cw=(Channels(k)\trackstart+Channels(k)\trackwait)-ElapsedMilliseconds()
          EndIf
        EndIf
      EndIf
    Next
    Delay(cw)
  Until LoopMusic=0
EndProcedure
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 641
; FirstLine = 627
; Folding = -------
; EnableXP