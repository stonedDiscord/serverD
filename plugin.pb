Global PluginName$="Test Plugin"
Global PluginDesc$="This Plugin tests the plugin system"

#CONSOLE=1
#WEB=0

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
  
  MessageRequester("plg",*usagePointer\last.s)
  
EndProcedure

ProcedureDLL.i SetTarget()
EndProcedure

ProcedureDLL.i SetMessage()
EndProcedure

ProcedureDLL.i StatusCallback()
EndProcedure
; IDE Options = PureBasic 5.11 (Windows - x64)
; ExecutableFormat = Shared Dll
; CursorPosition = 28
; Folding = --
; Executable = plugins\test.dll