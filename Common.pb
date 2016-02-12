;- Window Constants
;
Enumeration
  #Window_0
  #Window_1
  #Window_2
  #Window_3
EndEnumeration

;- Gadget Constants
;
Enumeration
  #Frame_0
  #String_5
  #Button_4
  #Button_2
  #Button_5
  #Frame_2
  #Frame_3
  #String_7
  #String_8
  #Button_6
  #Button_7
  #Button_8
  #CheckBox_4
  #Button_9
  #Combo_0
  #Combo_1
  #String_9
  #String_10
  #Button_kk
  #Button_dc
  #Button_kb
  #Button_mu
  #Button_um
  #Button_ig
  #Button_hd
  #Button_sw
  #Button_si
  #Listview_0
  #Button_dj
  #Button_ndj
  #Text_3
  #String_12
  #Button_27
  #Button_28
  #Button_29
  #Frame_4
  #CheckBox_6
  #TrackBar_1
  #ListIcon_2
  #CheckBox_MS
  #Text_6
  #String_OP
  #Frame_5
  #listbox_event
  #Button_BG
  #Text_7
  #Combo_3
  #Text_8
  #Combo_4
  #Checkbox_BlockIni
  #String_AD
  #Text_AD
  #String_13
  #Button_31
  #Button_About
  #Button_Load
EndEnumeration

Procedure BalloonTip(WindowID, Gadget, Text$ , Title$, Icon)
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Define ToolTip=0
    Define Balloon.TOOLINFO
    ToolTip=CreateWindowEx_(0,"ToolTips_Class32","",#WS_POPUP | #TTS_NOPREFIX | #TTS_BALLOON,0,0,0,0,WindowID,0,GetModuleHandle_(0),0)
    SendMessage_(ToolTip,#TTM_SETTIPTEXTCOLOR,GetSysColor_(#COLOR_INFOTEXT),0)
    SendMessage_(ToolTip,#TTM_SETTIPBKCOLOR,GetSysColor_(#COLOR_INFOBK),0)
    SendMessage_(ToolTip,#TTM_SETMAXTIPWIDTH,0,180)
    Balloon.TOOLINFO\cbSize=SizeOf(TOOLINFO)
    Balloon\uFlags=#TTF_IDISHWND | #TTF_SUBCLASS
    Balloon\hWnd=GadgetID(Gadget)
    Balloon\uId=GadgetID(Gadget)
    Balloon\lpszText=@Text$
    SendMessage_(ToolTip, #TTM_ADDTOOL, 0, Balloon)
    If Title$ > ""
      SendMessage_(ToolTip, #TTM_SETTITLE, Icon, @Title$)
    EndIf
  CompilerElse
    #TOOLTIP_NO_ICON=0
    #TOOLTIP_INFO_ICON=0
    #TOOLTIP_WARNING_ICON=0
    #TOOLTIP_ERROR_ICON=0
  CompilerEndIf
EndProcedure

Procedure Open_Window_0()
  If OpenWindow(#Window_0   , 300, 180, 730, 370, "serverD",  #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_SizeGadget | #PB_Window_TitleBar )
    Frame3DGadget(#Frame_0, 0, 0, 290, 370, "Serverside")
    CheckBoxGadget(#CheckBox_MS, 10, 15, 110, 20, "Public server mode")
    BalloonTip(GadgetID(#CheckBox_MS), #CheckBox_MS, "Makes this server appear on the Masterserver list", "", #TOOLTIP_NO_ICON)
    StringGadget(#String_5, 210, 15, 70, 22, "27015", #PB_String_Numeric)
    BalloonTip(GadgetID(#String_5), #String_5, "The public port goes here", "", #TOOLTIP_NO_ICON)
    ButtonGadget(#Button_4, -30, 280, 100, 30, "CONFIG", #PB_Button_Right)
    BalloonTip(GadgetID(#Button_4), #Button_4, "Opens the configuration page", "", #TOOLTIP_NO_ICON)
    ButtonGadget(#Button_2, 120, 15, 90, 22, "START")
    BalloonTip(GadgetID(#Button_2), #Button_2, "Start listening for connections", "", #TOOLTIP_NO_ICON)
    ButtonGadget(#Button_kk, -10, 40, 80, 30, "KICK", #PB_Button_Right)
    BalloonTip(GadgetID(#Button_kk), #Button_kk, "Send KB to the client and close the connection", "", #TOOLTIP_INFO_ICON)
    ButtonGadget(#Button_dc, -10, 70, 80, 30, "DISCONNECT", #PB_Button_Right)
    BalloonTip(GadgetID(#Button_dc), #Button_dc, "Disconnects this client from the server", "", #TOOLTIP_WARNING_ICON)
    ButtonGadget(#Button_kb, -10, 100, 80, 30, "BAN", #PB_Button_Right)
    BalloonTip(GadgetID(#Button_kb), #Button_kb, "Send KB to the client and add him to the banlist", "For this IP", #TOOLTIP_WARNING_ICON)
    ButtonGadget(#Button_mu, 30, 190, 40, 30, "MUTE", #PB_Button_Right)
    BalloonTip(GadgetID(#Button_mu), #Button_mu, "Send MU#-1#% to the client", "", #TOOLTIP_INFO_ICON)
    ButtonGadget(#Button_um, 0, 190, 30, 30, "UN", #PB_Button_Right)
    BalloonTip(GadgetID(#Button_um), #Button_um, "Send UM#-1#% to the client", "", #TOOLTIP_INFO_ICON)
    ButtonGadget(#Button_ig, 20, 160, 50, 30, "IGNORE")
    BalloonTip(GadgetID(#Button_ig), #Button_ig, "Ignore this clients commands", "", #TOOLTIP_INFO_ICON)
    ButtonGadget(#Button_hd, -10, 130, 80, 30, "HDBAN", #PB_Button_Right)
    BalloonTip(GadgetID(#Button_hd), #Button_hd, "Send KB to the client and add him to the HDbanlist", "PERMANENT", #TOOLTIP_ERROR_ICON)
    ButtonGadget(#Button_sw, -10, 220, 80, 30, "SWITCH", #PB_Button_Right)
    BalloonTip(GadgetID(#Button_sw), #Button_sw, "Drops this client to character selection", "", #TOOLTIP_INFO_ICON)
    ButtonGadget(#Button_si, 0, 160, 20, 30, "S")
    BalloonTip(GadgetID(#Button_si), #Button_si, "Stop ignoring this client", "", #TOOLTIP_INFO_ICON)
    ButtonGadget(#Button_About, -30, 310, 100, 30, "ABOUT", #PB_Button_Right)
    ButtonGadget(#Button_Load, -30, 340, 100, 30, "LOAD", #PB_Button_Right)
    ListIconGadget(#Listview_0, 70, 40, 220, 330, "IP", 100, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect | #PB_ListIcon_AlwaysShowSelection)
    CompilerIf #PB_Compiler_OS=#PB_OS_Windows
      SendMessage_ (GadgetID(#Listview_0), #LVS_SHOWSELALWAYS, 1, 0)
    CompilerEndIf
    AddGadgetColumn(#Listview_0, 1, "Character", 80)
    AddGadgetColumn(#Listview_0, 2, "Area", 50)
    AddGadgetColumn(#Listview_0, 3, "HDID", 80)
    BalloonTip(GadgetID(#Listview_0), #Listview_0, "Shows all connected clients", "", #TOOLTIP_NO_ICON)
    ButtonGadget(#Button_dj, 40, 250, 30, 30, "DJ")
    BalloonTip(GadgetID(#Button_dj), #Button_dj, "Allows this client to change the music", "", #TOOLTIP_INFO_ICON)
    ButtonGadget(#Button_ndj, -20, 250, 60, 30, "UN", #PB_Button_Right)
    BalloonTip(GadgetID(#Button_ndj), #Button_ndj, "Stops this client from changing the music", "", #TOOLTIP_INFO_ICON)
    Frame3DGadget(#Frame_4, 290, 0, 230, 340, "Log")
    ListIconGadget(#ListIcon_2, 520, 20, 210, 330, "Name", 80, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect | #PB_ListIcon_AlwaysShowSelection)
    AddGadgetColumn(#ListIcon_2, 1, "Message", 100)
    StringGadget(#String_13,520,350,160,20,"")
    ButtonGadget(#Button_31,680,350,50,20,"SEND")
    BalloonTip(GadgetID(#ListIcon_2), #ListIcon_2, "Shows the OOC chat history", "", #TOOLTIP_NO_ICON)
    Frame3DGadget(#Frame_5, 520, 0, 210, 370, "OOC")
      ListViewGadget(#listbox_event, 290, 20, 230, 350)
      AddGadgetItem(#listbox_event,0,"serverD "+Str(#PB_Editor_CompileCount)+"."+Str(#PB_Editor_BuildCount))
      AddGadgetItem(#listbox_event,0,"Check out http://stoned.ddns.net/serverd.html for updates")
      If update
        AddGadgetItem(#listbox_event,0,"UPDATE AVAILABLE",#PB_ListIcon_AlwaysShowSelection)
      EndIf
    BalloonTip(GadgetID(#listbox_event), #listbox_event, "Shows all activity", "", #TOOLTIP_NO_ICON)
  EndIf
EndProcedure

Procedure Open_Window_1()
  If OpenWindow(#Window_1, 303, 568, 150, 195, "Config",  #PB_Window_SystemMenu | #PB_Window_TitleBar )
    
    TextGadget(#Text_6, 10, 10, 40, 20, "OP pass")
    StringGadget(#String_OP, 60, 10, 80, 20, "", #PB_String_Password)
    BalloonTip(GadgetID(#String_OP), #String_OP, "Enter the OOC password here", "", #TOOLTIP_NO_ICON)
    
    TextGadget(#Text_AD, 10, 35, 40, 20, "Admin ''")
    StringGadget(#String_AD, 60, 35, 80, 20, "", #PB_String_Password)
    BalloonTip(GadgetID(#String_AD), #String_AD, "Enter the Admin password here", "", #TOOLTIP_NO_ICON)
    
    CheckBoxGadget(#CheckBox_4, 10, 55, 60, 20, "Logging")
    BalloonTip(GadgetID(#CheckBox_4), #CheckBox_4, "Log all network traffic to a file", "", #TOOLTIP_NO_ICON)
    ButtonGadget(#Button_9, 70, 55, 70, 20, "Log file...")
    
    TextGadget(#Text_7, 10, 85, 60, 20, "Mod colour:")
    ComboBoxGadget(#Combo_3, 70, 85, 70, 20)
    TextGadget(#Text_8, 10, 105, 50, 30, "MOTD evidence:")
    ComboBoxGadget(#Combo_4, 60, 115, 80, 20)
    CheckBoxGadget(#Checkbox_BlockIni,10,145,120,20,"Block Ini char swap")
    
    ButtonGadget(#Button_5, 0, 165, 150, 30, "DONE")
  EndIf
EndProcedure

Procedure ConfigWindow(var)
  Define loadevi
  Define Event,WindowID,GadgetID,EventType
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
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 132
; FirstLine = 95
; Folding = -
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0