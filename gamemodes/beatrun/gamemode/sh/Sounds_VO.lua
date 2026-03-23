local FaithVO = CreateConVar("Beatrun_FaithVO", 0, {FCVAR_REPLICATED, FCVAR_ARCHIVE})
local meta = FindMetaTable("Player")

sound.Add( {
	name = "Faith.StrainSoft",
	channel = CHAN_VOICE,
	volume = 0.75,
	level = 40,
	pitch = 100,
	sound = {
	"MirrorsEdge/Strain_Soft_1.wav",
	"MirrorsEdge/Strain_Soft_2.wav",
	"MirrorsEdge/Strain_Soft_3.wav",
	"MirrorsEdge/Strain_Soft_4.wav",
	"MirrorsEdge/Strain_Soft_5.wav",
	"MirrorsEdge/Strain_Soft_6.wav",
	"MirrorsEdge/Strain_Soft_7.wav",
	"MirrorsEdge/Strain_Soft_8.wav",
	}
} )

function meta:FaithVO(vo)
	if FaithVO:GetBool() then
		self:EmitSound(vo)
	end
end