Global PluginName$="Broadcaster Plugin"
Global PluginDesc$="This Plugin posts messages every set amount of time"
Global timer=600
Global lastb=0
Global active=0
Global WinID
Global message$="CT#$AUTO##%"
Global expl$=""
XIncludeFile "shared_headers.pb"

ProcedureDLL AttachProcess(Instance)
  WinID=OpenWindow(#PB_Any,300,200,130,55,"Broadcaster")
  If WinID
    StringGadget(1,3,3,82,26,message$)
    SpinGadget(2,85,3,45,26,5,10000,#PB_Spin_Numeric)
    SetGadgetState(2,timer)
    ButtonGadget(3,3,29,62,24,"start")
    ButtonGadget(4,65,29,62,24,"stop")
  EndIf
EndProcedure

ProcedureDLL.i PluginVersion()  
  ProcedureReturn 5
EndProcedure

ProcedureDLL.s PluginName()  
  ProcedureReturn PluginName$  
EndProcedure

ProcedureDLL.s PluginDescription()  
  ProcedureReturn PluginDesc$  
EndProcedure

ProcedureDLL.i PluginRAW(*usagePointer.Client)  
EndProcedure

ProcedureDLL.s SetTarget()
  ProcedureReturn "*"
EndProcedure

ProcedureDLL.s SetMessage()
  ProcedureReturn message$
EndProcedure

ProcedureDLL.i StatusCallback(pStat)
  wEv=WindowEvent()
  If wEv = #PB_Event_Gadget And winID=EventWindow()   
    GadgetID = EventGadget()           ; Is it a gadget event?
    Select GadgetID
      Case 1
        message$=GetGadgetText(1)
      Case 2
        timer=GetGadgetState(2)
      Case 3
        active=1
      Case 4
        active=0
    EndSelect
  EndIf
  If pStat=#SEND And active=1
    ctime=ElapsedMilliseconds()
    If ctime>=(timer*1000)+lastb
      lastb=ctime
      ProcedureReturn #SEND
    EndIf
  EndIf
EndProcedure
; IDE Options = PureBasic 5.31 (Windows - x86)
; ExecutableFormat = Shared Dll
; CursorPosition = 17
; Folding = --
; Executable = plugins\bcast.dll