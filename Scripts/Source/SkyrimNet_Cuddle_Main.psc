Scriptname SkyrimNet_Cuddle_Main extends Quest 

Package PackageStop

GlobalVariable Property skyrimnet_cuddle_active Auto
Bool Property cuddle_active 
    Bool Function Get()
        return skyrimnet_cuddle_active.GetValueInt() == 1
    EndFunction 
    Function Set(Bool value)
        if value
            skyrimnet_cuddle_active.SetValue(1.0)
        else
            skyrimnet_cuddle_active.SetValue(0.0)
        endif
    EndFunction 
EndProperty

Faction Property skyrimnet_cuddle_faction Auto

int Property animations Auto
int active_animations

Function Setup()
    Debug.MessageBox("SkyrimNet_Cuddle Setup started. Please wait a moment.")
    Trace("Setup","starting")
    if animations == 0 
        animations = JArray.object() 
        JValue.retain(animations)
    else
        JValue.clear(animations)
    endif

    if active_animations == 0 
        active_animations = JArray.object()
    endif
    JValue.retain(active_animations)

    bool RomanceAceShout_found = false 
    if MiscUtil.FileExists("Data/RomanceAceShout.esp")
        RomanceAceShout_found = true
        PackageStop = Game.GetFormFromFile(0x803, "RomanceAceShout.esp") as Package
    endif 

    int anim_source = JValue.readFromFile("Data/SkyrimNet_Cuddle/animations.json")
    Trace("Setup","Loaded "+anim_source+" count:"+JArray.count(anim_source)+" animations from AceRomance.json")
    int count = JArray.count(anim_source)
    int i = 0 
    while i < count 
        int anim = JArray.getObj(anim_source, i)
        String source = JMap.getStr(anim, "source", "")

        String name = JMap.getStr(anim, "name", "")
        if source == "stop"
            Trace("Setup","adding animation "+name+" from "+source)
            JArray.addObj(animations, anim)
        elseif RomanceAceShout_found == true && source == "ace_romance"
            Trace("Setup","adding animation "+name+" from "+source)
            JArray.addObj(animations, anim)
        endif 
        i += 1
    endwhile

    SkyrimNet_Cuddle_Actions.Setup()
    SkyrimNet_Cuddle_Decorators.Setup()

EndFunction 

;---------------------------------------
; Open Cuddle Menu
;---------------------------------------
Function OpenMenu(Actor source, Actor target) 
    ;---------------------------------------
 	uilistmenu InterruptMenuUi = uiextensions.GetMenu("UIListMenu") as uilistmenu

    int count = JArray.count(animations)
    Trace("Setup","Animation count: "+JArray.count(animations))
    int i = 0 
    while i < count 
        int anim = JArray.getObj(animations, i)
        String name = JMap.getStr(anim, "name", "")
        InterruptMenuUi.AddEntryItem(name)
        Trace("OpenMenu","Added animation "+name)
        i += 1 
    endwhile 

	InterruptMenuUi.OpenMenu()
	int index = InterruptMenuUi.GetResultInt()
    if index < 0 || index >= count
        Trace("OpenMenu","Invalid index: "+index)
        return 
    endif 
    ChangeCuddle(source, target, JArray.getObj(animations, index))
EndFunction

Function ChangeCuddle_byName(Actor source, Actor target, String name)
    int count = JArray.count(animations)
    int i = 0 
    int anim = -1
    bool found = false 
    while i < count && !found 
        anim = JArray.getObj(animations, i)
        String anim_name = JMap.getStr(anim, "name", "")
        if anim_name == name 
            found = true 
        endif  
        i += 1 
    endwhile 
    if found 
        ChangeCuddle(source, target, anim) 
    endif 
    Trace("NameToAnimation","Animation "+name+" not found")
EndFunction 

Function ChangeCuddle(Actor source, Actor target, int anim)
    int index = 0
    int count = JArray.count(active_animations)
    int current = 0
    while index < count && current == 0
        int a = JArray.getObj(active_animations, index)
        Actor s = JMap.getForm(a, "source") as Actor
        Actor t = JMap.getForm(a, "target") as Actor
        if s == source || s == target || t == source || t == target
            current = a 
        endif 
        index += 1
    endwhile
    
    ;---------------------------------------
    int id = JMap.getInt(anim, "id", 0)
    String name = JMap.getStr(anim, "name", "")
    source.SetFactionRank(skyrimnet_cuddle_faction, id) 

    Actor player = Game.GetPlayer() 
    if name == "stop"
        cuddle_active = False 
        ActorUtil.RemovePackageOverride(target, PackageStop)
		(target as Actor).EvaluatePackage()
		target.SetAnimationVariableInt("IsNPC", 1) ; enable head tracking
		target.SetAnimationVariableBool("bHumanoidFootIKDisable", False) ; enable inverse kinematics

        Debug.sendanimationevent(target, "idleforcedefaultstate")
        Debug.sendanimationevent(source, "idleforcedefaultstate")
	    source.SetDontMove(false)
	    target.SetDontMove(false)
	    Utility.SetIniBool("bDisablePlayerCollision:Havok",false)
        if current != 0
            String desc = AnimationDesc(current, "stops")
            Trace("ChangeCuddle",desc)
            SkyrimNetApi.RegisterEvent("cuddle", desc, source, target)
            JArray.eraseIndex(active_animations, index)
        endif 
        return 
    endif 

    if current != 0
        JMap.setObj(current, "animation", anim)
    else 
        current = JMap.object()
        JMap.setForm(current, "source", source)
        JMap.setForm(current, "target", target)
        JMap.setObj(current, "animation", anim)
        JArray.addObj(active_animations, current)
    endif 

    String desc = AnimationDesc(anim, "starts")
    Trace("ChangeCuddle","desc:"+desc)
    JArray.eraseIndex(active_animations, index)
    ; SkyrimNetApi.DirectNarration(desc, source, target)

    String source_anim = JMap.getStr(anim, "source_anim", "")
    String target_anim = JMap.getStr(anim, "target_anim", "")

    if name == "CuddleFromBehind"
        Utility.SetIniBool("bDisablePlayerCollision:Havok", True)
                ActorUtil.AddPackageOverride(target as Actor, PackageStop, 1)
                (target as Actor).EvaluatePackage()
            target.SetAnimationVariableInt("IsNPC", 1) ; disable head tracking
            target.SetAnimationVariableBool("bHumanoidFootIKDisable", True) ; disable inverse kinematics
        target.moveto(Game.GetPlayer())
        if source != player
            source.SetDontMove()
        endif 
        target.SetDontMove()
        Trace("ChangeCuddle","CuddleFromBehind executed "+source_anim+" / "+target_anim)

        if source.GetHeight() < target.GetHeight()
            String temp = source_anim
            source_anim = target_anim
            target_anim = temp
        endif
        debug.sendanimationevent(target, target_anim)
        debug.sendanimationevent(source, source_anim)
    else 
        Utility.SetIniBool("bDisablePlayerCollision:Havok", True)
        ActorUtil.AddPackageOverride(target, PackageStop, 1)
        target.EvaluatePackage()
        target.SetAnimationVariableInt("IsNPC", 1) ; disable head tracking
        target.SetAnimationVariableBool("bHumanoidFootIKDisable", True) ; disable inverse kinematics
        
        target.moveto(Game.GetPlayer())
        if source != player
            source.SetDontMove()
        endif
        target.SetDontMove()
        debug.sendanimationevent(source, source_anim)
        debug.sendanimationevent(target, target_anim)
    endif 

EndFunction 

String Function AnimationDesc(int anim, String status)
    int a = JMap.getInt(anim, "animation", 0)
    String desc_inja = JMap.getStr(a, "description", "")
    Actor s = JMap.getForm(anim, "source") as Actor
    Actor t = JMap.getForm(anim, "target") as Actor
    String json = "{\"source\":\""+s.GetDisplayName()+"\""\
                + ",\"target\":\""+t.GetDisplayName()+"\""\
                + ",\"status\":\""+status+"\"}"
    String desc = SkyrimNetApi.ParseString(desc_inja,"cuddle", json)
    String name = JMap.getStr(anim, "name", "")
    Trace("AnimationDesc",anim+" "+name+" "+json+" "+desc_inja+" ->"+desc)
    return desc
EndFunction 

Function Trace(String func, String msg, Bool notification=False) global
    msg = "[SkyrimNet_Cuddle_Main."+func+"] "+msg
    Debug.Trace(msg) 
    if notification
        Debug.Notification(msg)
    endif 
EndFunction