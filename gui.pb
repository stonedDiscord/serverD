Define *clickedClient.Client        

Procedure RefreshList(var)
  Define lstate,listicon,i
  If TryLockMutex(RefreshMutex)
    lstate=GetGadgetState(#Listview_0)
    ClearGadgetItems(#Listview_0)
    i=0
    LockMutex(ListMutex)    
    ResetMap(Clients())
    While NextMapElement(Clients())
      listicon=ImageID(0)
      If Clients()\perm
        listicon=ImageID(1)
      EndIf
      If Clients()\hack
        listicon=ImageID(2)
      EndIf
      AddGadgetItem(#Listview_0,i,Clients()\IP+Chr(10)+GetCharacterName(Clients())+Chr(10)+Str(Clients()\CID),listicon)
      SetGadgetItemData(#Listview_0,i,Clients()\ClientID)
      i+1
    Wend
    UnlockMutex(ListMutex)
    If lstate<CountGadgetItems(#Listview_0)
      SetGadgetState(#Listview_0,lstate)
    EndIf
    UnlockMutex(RefreshMutex)
  EndIf
EndProcedure

If OpenWindow(2,#PB_Ignore,#PB_Ignore,420,263,"serverD",#PB_Window_BorderLess|#PB_Window_ScreenCentered)
  WindowEvent()
  WindowEvent()
  UsePNGImageDecoder()
  CatchImage(3,?dend)
  ImageGadget(0,0,0,420,263,ImageID(3))
  WindowEvent()
  Delay(100)
  WindowEvent()
  CatchImage(0,?green)
  Icons(0)=ImageID(0)
  CatchImage(1,?mod)
  Icons(1)=ImageID(1)
  CatchImage(2,?hacker)
  Icons(2)=ImageID(2)
  WindowEvent()
  *Buffer = AllocateMemory(1024)
  Open_Window_0()
  LoadSettings(0)
  Delay(100)
  CloseWindow(2)
EndIf

If ProgramParameter()="-auto"
  SetWindowColor(0, RGB(255,255,0))
  SetGadgetText(#Button_2,"RELOAD")
  nthread=CreateThread(@Network(),0)  
EndIf        

;- WINDOW EVENT LOOP 
Repeat ; Start of the event loop
  Define Event,WindowID,GadgetID,EventType,NStatus
  Define lvstate,cldata,ooclient,logclid,b
  If success
    NStatus=Network(0)
    EndIf
  Event = WaitWindowEvent(LagShield) ; This line waits until an event is received from Windows
  WindowID = EventWindow()  ; The Window where the event is generated, can be used in the gadget procedures
  GadgetID = EventGadget()  ; Is it a gadget event?
  EventType = EventType()   ; The event type
  If Event = #PB_Event_Gadget    
    
    lvstate=GetGadgetState(#Listview_0)
    If lvstate>=0         
      cldata = GetGadgetItemData(#Listview_0,lvstate)
      If cldata
        LockMutex(ListMutex)
        *clickedClient=FindMapElement(Clients(),Str(cldata))
        UnlockMutex(ListMutex)
      EndIf
      
      Select GadgetID 
        Case #Button_kk ;KICK
          KickBan(Str(cldata),#KICK,Server)
          cldata=-1
          
        Case #Button_sw ;SWITCH
          KickBan(Str(cldata),#SWITCH,Server)
          
        Case #Button_mu ;MUTE
          Debug cldata
          KickBan(Str(cldata),#MUTE,Server)
          
        Case #Button_um ;UNMUTE
          KickBan(Str(cldata),#UNMUTE,Server)
          
        Case #Button_kb ;BAN 
          KickBan(Str(cldata),#BAN,Server)
          cldata=-1
          
        Case #Button_hd ;HDBAN
          KickBan(*clickedClient\HD,#BAN,Server)
          cldata=-1
          
        Case #Button_dc ;DISCONNECT
          KickBan(Str(cldata),#DISCO,Server)
          cldata=-1     
          
        Case #Button_ig ;IGNORE
          KickBan(Str(cldata),#CIGNORE,Server)
          
        Case #Button_si ; STOP IGNORING ME
          KickBan(Str(cldata),#UNIGNORE,Server)
          
        Case #Button_ndj ;IGNORE MUSIC
          KickBan(Str(cldata),#UNDJ,Server)
          
        Case #Button_dj ; STOP IGNORING MY MUSIC
          KickBan(Str(cldata),#DJ,Server)
          
      EndSelect
      
    EndIf
    
    Select GadgetID 
      Case #ListIcon_2
        ooclient=GetGadgetItemData(#ListIcon_2,GetGadgetState(#ListIcon_2))   
        If ooclient
          For b=0 To CountGadgetItems(#ListView_0)
            If GetGadgetItemData(#ListView_0,b) = ooclient 
              SetGadgetState(#ListView_0,b)
            EndIf
          Next
        EndIf
        
      Case #listbox_event
        logclid=GetGadgetItemData(#listbox_event,GetGadgetState(#listbox_event))   
        If logclid
          For b=0 To CountGadgetItems(#ListView_0)
            If GetGadgetItemData(#ListView_0,b) = logclid  
              SetGadgetState(#ListView_0,b)
            EndIf
          Next
        EndIf
        
      Case #CheckBox_MS
        public=GetGadgetState(#CheckBox_MS)
        Debug public
        If public
          msthread=CreateThread(@MasterAdvert(),port)
        EndIf
        
      Case #Button_31
        AddGadgetItem(#ListIcon_2,-1,Server\username+Chr(10)+GetGadgetText(#String_13))
        SendTarget("*","CT#"+Server\username+"#"+GetGadgetText(#String_13)+"#%",Server)                
        
      Case #Button_2 ;START
        port=Val(GetGadgetText(#String_5))
        If success
          LoadSettings(1)
        Else
          success=CreateNetworkServer(0,port,#PB_Network_TCP)
          If success
            SetWindowColor(0, RGB(0,128,0))
            SetGadgetText(#Button_2,"RELOAD")  
          Else
            SetWindowColor(0, RGB(128,0,0))
            SetGadgetText(#Button_2,"RETRY")  
            EndIf
        EndIf
        
      Case #Button_4 ;CONFIG
        CreateThread(@ConfigWindow(),0) 
        
      Case #Button_About
        MessageRequester("serverD","This is serverD version "+Str(#PB_Editor_CompileCount)+"."+Str(#PB_Editor_BuildCount)+Chr(10)+"(c) stonedDiscord 2014-2015"+Chr(10)+"no one helped me with this, especially not FanatSors")
        
    EndSelect
  ElseIf Event = #PB_Event_SizeWindow
    
    ResizeGadget(#Frame_0,0,0,WindowWidth(0)/2.517,WindowHeight(0))
    ResizeGadget(#ListView_0,70,40,WindowWidth(0)/2.517-70,WindowHeight(0)-40)
    ResizeGadget(#Button_2,WindowWidth(0)/6.08,15,WindowWidth(0)/8.111,22)
    ResizeGadget(#String_5,WindowWidth(0)/3.476,15,WindowWidth(0)/10.42,22)
    ResizeGadget(#Frame_4,WindowWidth(0)/2.517,0,WindowWidth(0)/3.173,WindowHeight(0))
    ResizeGadget(#listbox_event, WindowWidth(0)/1.7, 30, WindowWidth(0)-WindowWidth(0)/1.7, WindowHeight(0)-90)
    ResizeGadget(#listbox_event,WindowWidth(0)/2.517,20,WindowWidth(0)/3.173,WindowHeight(0)-20)
    ResizeGadget(#Frame_5,WindowWidth(0)/1.4,0,WindowWidth(0)/3.476,WindowHeight(0))
    ResizeGadget(#ListIcon_2,WindowWidth(0)/1.4,20,WindowWidth(0)/3.476,WindowHeight(0)-40)  
    
    ResizeGadget(#String_13,WindowWidth(0)/1.4,WindowHeight(0)-20,WindowWidth(0)/5,20)  
    ResizeGadget(#Button_31,WindowWidth(0)/1.1,WindowHeight(0)-20,WindowWidth(0)/10,20)  
    
    
  EndIf
  
  If rf
    If CommandThreading
      CreateThread(@RefreshList(),0)
    Else
      RefreshList(0)
    EndIf
    rf=0
  EndIf 
  
Until Event = #PB_Event_CloseWindow ; End of the event loop
Quit=1

OpenPreferences("base/settings.ini")
PreferenceGroup("net")
WritePreferenceInteger("public",public)
WritePreferenceInteger("port",port)
ClosePreferences()

End

DataSection
  green:
  IncludeBinary "green.png"
  mod:
  IncludeBinary "mod.png"
  hacker:
  IncludeBinary "hacker.png"
  dend:
  IncludeBinary "serverd.png"
  bannerend:
EndDataSection
; IDE Options = PureBasic 5.11 (Linux - x64)
; CursorPosition = 49
; FirstLine = 17
; Folding = -
; EnableXP