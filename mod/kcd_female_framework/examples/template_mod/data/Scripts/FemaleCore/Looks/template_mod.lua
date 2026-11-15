-- Written by make_face_pack.py of KCD2 Female Framework from faces.toml: the faces of template_mod.
-- The framework reads every file of Scripts/FemaleCore/Looks and keeps these with its own looks.
if not (FemaleCore and FemaleCore.RegisterLooks) then
	System.LogAlways("[template_mod] this version of KCD2 Female Framework has no RegisterLooks: these faces need a newer one")
	return
end
FemaleCore.RegisterLooks("template_mod", {
	{ id = 280, name = "template_heroine", style = 3, color = 1, age = "young", token = "bd43e407-5c79-572f-b929-4ea3ca182127" },
})
