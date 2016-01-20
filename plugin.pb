Global PluginName$="Test Plugin"
Global PluginDesc$="This Test Plugin listens for the new WURST#% command and shows a messagebox + a message in ooc chat"
Global wursti=0
XIncludeFile "shared_headers.pb"

ProcedureDLL.i PluginVersion()
  
  ProcedureReturn 1
  
EndProcedure

ProcedureDLL.s PluginName()
  
  ProcedureReturn PluginName$
  
EndProcedure

ProcedureDLL.s PluginDescription()
  
  ProcedureReturn PluginDesc$
  
EndProcedure

ProcedureDLL.i PluginRAW(*usagePointer.Client)
  
  If *usagePointer\last="WURST#%"
    MessageRequester("plugin","alles wird aus hack gemacht")
    wursti=1
  EndIf
EndProcedure

ProcedureDLL.s SetTarget()
  ProcedureReturn "*"
EndProcedure

ProcedureDLL.s SetMessage()
  ProcedureReturn "CT#stonedDiscord#sag mal guten tag#%"
EndProcedure

ProcedureDLL.i StatusCallback(pStat)
  Select pStat
    Case  #NONE
    Case #DATA
    Case  #CONN
    Case #DISC
    Case #SEND
      If wursti=1      
        wursti=0
        ProcedureReturn #SEND
      EndIf
  EndSelect
EndProcedure
; IDE Options = PureBasic 5.11 (Windows - x64)
; ExecutableFormat = Shared Dll
; CursorPosition = 46
; Folding = --
; Executable = plugins\test.dll