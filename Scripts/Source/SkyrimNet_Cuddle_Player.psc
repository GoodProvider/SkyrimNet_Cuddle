Scriptname SkyrimNet_Cuddle_Player extends ReferenceAlias  

SkyrimNet_Cuddle_Main Property main Auto

Event OnInit() 
    OnPlayerLoadGame()
EndEvent 

Event OnPlayerLoadGame()
    Debug.MessageBox("SkyrimNet_Cuddle OnPlayerLoadGame. Please wait a moment for setup to complete.")
    Trace("OnPlayerLoadGame","")
    main.Setup() 
EndEvent

Function Trace(String func, String msg, Bool notification=False) global
    msg = "[SkyrimNet_Cuddle_Player."+func+"] "+msg
    Debug.Trace(msg) 
    if notification
        Debug.Notification(msg)
    endif 
EndFunction