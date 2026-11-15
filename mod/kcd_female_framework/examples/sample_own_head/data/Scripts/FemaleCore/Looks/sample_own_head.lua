-- Written by make_face_pack.py of KCD2 Female Framework from faces.toml: the faces of sample_own_head.
-- The framework reads every file of Scripts/FemaleCore/Looks and keeps these with its own looks.
if not (FemaleCore and FemaleCore.RegisterLooks) then
	System.LogAlways("[sample_own_head] this version of KCD2 Female Framework has no RegisterLooks: these faces need a newer one")
	return
end
FemaleCore.RegisterLooks("sample_own_head", {
	{ id = 210, name = "sample_own_woman", style = 5, color = 4, age = "young", token = "2b04688c-e617-56bb-a782-2ab065025b87" },
})
