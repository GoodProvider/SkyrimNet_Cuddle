Scriptname SkyrimNet_Cuddle_Decorators

Function Setup() global 
    SkyrimNetApi.RegisterDecorator("cuddle_animation", "SkyrimNet_AceRomance_Decorators", "Get_Animation")
EndFunction 

Function Get_Animation(Actor akActor) global 
EndFunction 

Function Trace(String func, String msg, Bool notification=False) global
    msg = "[SkyrimNet_Cuddle_Decorators."+func+"] "+msg
    Debug.Trace(msg) 
    if notification
        Debug.Notification(msg)
    endif 
EndFunction