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
EndStructure
Global Dim areas.area(100)
Define iniarea
For iniarea=0 To 100 
  areas(iniarea)\wait=0
  areas(iniarea)\lock=0
  areas(iniarea)\mlock=0
Next

Structure ACharacter
  name.s
  desc.s
  taken.w
  dj.b
  evinumber.w
  evidence.s
  pw.s
EndStructure
Global Dim Characters.ACharacter(100)

Structure Track
  TrackName.s
  Length.i
EndStructure
Global NewList Music.Track()

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
Global Server.Client
Server\ClientID=0
Server\IP="$HOST"
Server\AID=-3
Server\CID=-3
Server\perm=3
Server\ignore=0
Server\ignoremc=0
Server\hack=0
Server\area=-1
Server\last=""
Server\cconnect=0
Server\ooct=0
Server\RAW=0
Server\username="$HOST"
Global NewMap Clients.Client()

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

Structure Action
  IP.s
  type.i  
EndStructure
Global NewList Actions.Action()

#CRLF$ = Chr(13)+Chr(10)

Procedure.s Encode(smes$)
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

Procedure WriteLog(string$,*lclient.Client)
  Define mstr$,logstr$
  ; [23:21:05] David Skoland: (If mod)[M][IP][Timestamp, YYYYMMDDHHMM][Character][Message]
  Select *lclient\perm
    Case 1
      mstr$="[M]"
    Case 2
      mstr$="[A]"
    Case 3
      mstr$="[S]"
    Default
      mstr$="[U]"
  EndSelect
  logstr$=mstr$+"["+LSet(*lclient\IP,15)
  logstr$=logstr$+"]"+"["+FormatDate("%dd.%mm.%yyyy %hh:%ii:%ss",Date())+"]"+string$
  If Logging
    WriteStringN(1,Escape(logstr$))
  EndIf
  CompilerIf #CONSOLE
    PrintN(Escape(logstr$))
  CompilerElse
    AddGadgetItem(#listbox_event,-1,string$)
    SetGadgetItemData(#listbox_event,CountGadgetItems(#listbox_event)-1,*lclient\ClientID)
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
    CloseNetworkServer(0)
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
    *Temp_Data = AllocateMemory(Temp_String_ByteLength)
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
CompilerEndIf

Procedure.s GetCharacterName(*nclient.Client)
  Define name$
  If *nclient\CID>=0 And *nclient\CID<=characternumber
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
  If *nclient\area>=0 And *nclient\area<=Aareas
    name$=Areas(*nclient\area)\name
  ElseIf *nclient\area=-3
    name$="RAM"
  Else
    name$="$NONE"
  EndIf
  ProcedureReturn name$
EndProcedure
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 36
; FirstLine = 22
; Folding = --
; EnableXP