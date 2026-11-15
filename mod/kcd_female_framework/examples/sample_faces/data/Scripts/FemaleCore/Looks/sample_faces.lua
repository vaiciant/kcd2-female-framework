-- Written by make_face_pack.py of KCD2 Female Framework from faces.toml: the faces of sample_faces.
-- The framework reads every file of Scripts/FemaleCore/Looks and keeps these with its own looks.
if not (FemaleCore and FemaleCore.RegisterLooks) then
	System.LogAlways("[sample_faces] this version of KCD2 Female Framework has no RegisterLooks: these faces need a newer one")
	return
end
FemaleCore.RegisterLooks("sample_faces", {
	{ id = 320, name = "sample_redhead", style = 2, color = 5, age = "young", token = "96a54674-f44e-5d8e-8a8d-93a62acdde55" },
	{ id = 321, name = "sample_dark", style = 4, color = 2, age = "young", token = "542c20cc-ae85-5703-9587-1647dd946b9b" },
})
