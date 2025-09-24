Scriptname RomanceAceShoutEffect extends ActiveMagicEffect  

Package Property PackageStop Auto

Function OnEffectStart(Actor aktarget, Actor akcaster)
    SkyrimNet_Cuddle_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_Cuddle.esp") as SkyrimNet_Cuddle_Main
	main.OpenMenu(Game.GetPlayer(), aktarget)
EndFunction