Scriptname SkyrimNet_Cuddle_Actions

Function Setup() global 
    SkyrimNet_Cuddle_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_Cuddle.esp") as SkyrimNet_Cuddle_Main
    if main == None 
        Trace("Setup","SkyrimNet_Cuddle_Main is None")
    endif 

    String types = "" 
    int i = 0 
    int count = JArray.count(main.animations)
    while i < count 
        String name = JValue.solveStr(main.animations, "."+i+".name", "")
        if name != "Stop" && name != ""
            if types != "" 
                types += "|"
            endif 
            types += name 
        endif 
        i -= 1 
    endwhile 
    Trace("Setup","cuddles: "+types)

    SkyrimNetApi.RegisterAction("CuddleTarget", \
            "Starting to {cuddle_type} with {target}.", \
            "SkyrimNet_Cuddle_Actions", "IsEligibleStart",  \
            "SkyrimNet_Cuddle_Actions", "Execute",  \
            "", "PAPYRUS", 1, \
            "{\"target\": \"Actor\", \"cuddle_type\":\""+types+"\"")
    SkyrimNetApi.RegisterAction("CuddleTarget", \
            "Stop {cuddle_type} with {target}.", \
            "SkyrimNet_Cuddle_Actions", "IsEligibleStop",  \
            "SkyrimNet_Cuddle_Actions", "Execute",  \
            "", "PAPYRUS", 1, \
            "{\"target\": \"Actor\", \"cuddle_type\":\"stop\"")

    if !MiscUtil.FileExists("Data/SkyrimNet_SexLab.esp")
        SkyrimNetApi.RegisterTag("BodyAnimation", "SkyrimNet_SexLab_Actions", "BodyAnimation_Tag")
    endif 
EndFunction 

; -------------------------------------------------
; Body Animation Tag 
; -------------------------------------------------

Bool Function BodyAnimation_Tag(String tag, Actor akActor) global
    if akActor.IsDead() || akActor.IsInCombat() 
        Trace("BodyAnimation_Tag", akActor.GetDisplayName()+" is dead or in combat")
        return false 
    endif 

    ; Cuddle check 
    SkyrimNet_Cuddle_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_Cuddle.esp") as SkyrimNet_Cuddle_Main
    if main == None 
        Trace("IsEligible","SkyrimNet_Cuddle_Main is None")
        return false
    endif
    int rank = akActor.GetFactionRank(main.skyrimnet_cuddle_faction)
    if rank > 0
        Trace("IsEligible",akActor.GetDisplayName()+" is already cuddling")
        return false
    endif

    ; SexLab check
    if MiscUtil.FileExists("Data/SkyrimNet_SexLab.esp")
        SkyrimNet_SexLab_Main sexlab_main = Game.GetFormFromFile(0x800, "SkyrimNet_SexLab.esp") as SkyrimNet_SexLab_Main
        if sexlab_main.IsActorLocked(akActor) || sexlab_main.sexLab.IsActorActive(akActor) 
            Trace("BodyAnimation_Tag", akActor.GetDisplayName()+" is locked or SexLab animation")
            return false 
        endif

    elseif MiscUtil.FileExists("Data/SexLab.esm")
        SexLabFramework SexLab = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
        if sexlab != None && sexlab.IsActorActive(akActor)
            Trace("BodyAnimation_Tag", akActor.GetDisplayName()+" is in SexLab animation")
            return false
        endif 
    endif 

    ; Ostim check 
    if MiscUtil.FileExists("Data/OStim.esp") && OActor.IsInOStim(akActor)
        return false 
    endif 

    Trace("BodyAnimation_Tag", akActor.GetDisplayName()+" is eligible for sex")
    return True
EndFunction


bool Function IsEligibleStart(Actor akActor) global 
    return true 
EndFunction 

bool Function IsEligibleStop(Actor akActor) global 
    ; Is cuddling check 
    SkyrimNet_Cuddle_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_Cuddle.esp") as SkyrimNet_Cuddle_Main
    if main == None 
        Trace("IsEligible","SkyrimNet_Cuddle_Main is None")
        return false
    endif
    int rank = akActor.GetFactionRank(main.skyrimnet_cuddle_faction)
    return rank > 0 
EndFunction 

Function Execute(Actor source, string contextJson, string paramsJson) global

    Actor target = SkyrimNetApi.GetJsonActor(paramsJson, "target", None)
    if source == None || target == None 
        Trace("Execute","source or target is None")
        return 
    endif 

    SkyrimNet_Cuddle_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_Cuddle.esp") as SkyrimNet_Cuddle_Main
    if main == None 
        Trace("Execute","SkyrimNet_Cuddle_Main is None")
        return 
    endif

    String cuddle_type = SkyrimNetApi.GetJsonString(paramsJson, "type","")
    main.ChangeCuddle_byName(source, target, cuddle_type)
EndFunction

Function Trace(String func, String msg, Bool notification=False) global
    msg = "[SkyrimNet_Cuddle_Actions."+func+"] "+msg
    Debug.Trace(msg) 
    if notification
        Debug.Notification(msg)
    endif 
EndFunction