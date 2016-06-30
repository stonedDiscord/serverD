Global PluginName$="Empty Plugin"
Global PluginDesc$="You can use this source to make your own plugin"

ProcedureDLL.i PluginVersion()  
  ProcedureReturn 1
EndProcedure

ProcedureDLL.s PluginName()  
  ProcedureReturn PluginName$  
EndProcedure

ProcedureDLL.s PluginDescription()  
  ProcedureReturn PluginDesc$  
EndProcedure

ProcedureDLL.s SetTarget()
  ProcedureReturn "*"
EndProcedure

ProcedureDLL.s SetMessage()
  ProcedureReturn "CT#RIP BUD SPENCER#2016#%"
EndProcedure

ProcedureDLL.i PluginRAW(*usagePointer.Client)
  ;*usagePointer\last ;last sent shit
EndProcedure

ProcedureDLL.i StatusCallback(pStat)
  ProcedureReturn #NONE
EndProcedure
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 29
; Folding = --
; EnableXP