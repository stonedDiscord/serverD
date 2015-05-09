Structure area
  name.s
  bg.s
  wait.l
  lock.l
  mlock.w
EndStructure
Global Dim areas.area(100)
Define iniarea
For iniarea=0 To 100 
  areas(iniarea)\wait=0
  areas(iniarea)\lock=0
  areas(iniarea)\mlock=0
Next

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
EndStructure
Global Server.Client
Server\ClientID=0
Server\IP="SERVER"
Server\AID=0
Server\CID=-2
Server\perm=3
Server\ignore=0
Server\ignoremc=0
Server\hack=0
Server\area=-1
Server\last=""
Server\cconnect=0
Server\ooct=0
Server\RAW=0
Global NewMap Clients.Client()

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
#CRLF$ = Chr(13)+Chr(10)

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
    WriteStringN(1,logstr$) 
  EndIf
  CompilerIf #CONSOLE=1
    PrintN(logstr$)
  CompilerElse
    AddGadgetItem(#Listview_2,-1,string$)
    SetGadgetItemData(#Listview_2,CountGadgetItems(#Listview_2)-1,*lclient\ClientID)
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

Procedure.s GetCharacterName(*nclient.Client)
  Define name$
  If *nclient\CID>=0 And *nclient\CID<=characternumber
    name$=Characters(*nclient\CID)\name
  ElseIf *nclient\CID=-1
    name$="nobody"
  ElseIf *nclient\CID=-3
    name$="SERVER"
  Else
    name$="HACKER"
    *nclient\hack=1
    rf=1
  EndIf
  ProcedureReturn name$
EndProcedure

Procedure.s Escape(smes$)
  smes$=ReplaceString(smes$,"<num>","#")
  smes$=ReplaceString(smes$,"<pound>","#")
  smes$=ReplaceString(smes$,"<and>","&")
  smes$=ReplaceString(smes$,"<percent>","%")
  smes$=ReplaceString(smes$,"<dollar>","$")
  ProcedureReturn smes$
EndProcedure
; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 63
; FirstLine = 24
; Folding = -
; EnableXP