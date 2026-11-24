local function _buildPropertySets()
	local t = {}
	t.BasePart = {
		"Anchored","CanCollide","CanTouch","CanQuery","CastShadow",
		"Transparency","Reflectance","Size","Position","Orientation",
		"CFrame","Material","Color","BrickColor","AssemblyMass",
		"AssemblyLinearVelocity","AssemblyAngularVelocity","Massless",
		"CollisionGroupId","RootPriority","Locked","Archivable",
	}
	t.MeshPart = {"MeshId","TextureID","MeshSize","DoubleSided"}
	t.SpecialMesh = {"MeshId","TextureId","MeshType","Scale","Offset"}
	t.UnionOperation = {"UsePartColor"}
	t.Humanoid = {
		"Health","MaxHealth","WalkSpeed","JumpPower","JumpHeight",
		"HipHeight","RigType","DisplayName","NameDisplayDistance",
		"HealthDisplayDistance","AutoRotate","AutoJumpEnabled","Sit",
		"PlatformStand","DisplayDistanceType","NameOcclusion","RequiresNeck",
	}
	t.HumanoidDescription = {
		"BodyTypeScale","HeadScale","HeightScale","ProportionScale","WidthScale",
		"Face","Head","LeftArm","LeftLeg","RightArm","RightLeg","Torso",
		"BackAccessory","FaceAccessory","FrontAccessory","HairAccessory",
		"HatAccessory","NeckAccessory","ShouldersAccessory","WaistAccessory",
	}
	t.Model = {"PrimaryPart","WorldPivot","LevelOfDetail","ModelLod"}
	t.ScreenGui = {"Enabled","DisplayOrder","ZIndexBehavior","ResetOnSpawn","IgnoreGuiInset"}
	t.Frame = {"Size","Position","AnchorPoint","BackgroundColor3","BackgroundTransparency","Visible","ZIndex","BorderSizePixel"}
	t.TextLabel = {"Text","TextSize","TextColor3","Font","FontFace","TextTransparency","TextWrapped","TextScaled","Visible"}
	t.TextButton = {"Text","TextSize","TextColor3","Font","FontFace","TextTransparency","TextWrapped","Visible","Active"}
	t.TextBox = {"Text","PlaceholderText","TextSize","TextColor3","Font","Visible","MultiLine"}
	t.ImageLabel = {"Image","ImageColor3","ImageTransparency","ScaleType","Size","Position","Visible"}
	t.ImageButton = {"Image","ImageColor3","ImageTransparency","ScaleType","Visible","Active"}
	t.ProximityPrompt = {
		"ActionText","ObjectText","HoldDuration","KeyboardKeyCode",
		"MaxActivationDistance","RequiresLineOfSight","Enabled","Style",
	}
	t.ClickDetector = {"MaxActivationDistance","CursorIcon"}
	t.Tool = {"ToolTip","Enabled","RequiresHandle","ManualActivationOnly","GripForward","GripPos","GripRight","GripUp"}
	t.BackpackItem = {"TextureId"}
	t.LocalScript = {"Disabled","RunContext"}
	t.Script = {"Disabled","RunContext"}
	t.ModuleScript = {}
	t.Sound = {"SoundId","Volume","PlaybackSpeed","Looped","Playing","TimePosition","RollOffMaxDistance","RollOffMinDistance","RollOffMode"}
	t.SoundGroup = {"Volume"}
	t.EqualizerSoundEffect = {"HighGain","LowGain","MidGain"}
	t.ReverbSoundEffect = {"Density","Diffusion","DecayTime"}
	t.ParticleEmitter = {"Texture","Rate","Lifetime","Speed","Size","Color","Enabled","EmissionDirection","RotSpeed","Rotation"}
	t.Beam = {"Attachment0","Attachment1","Texture","Color","Width0","Width1","Transparency","Enabled","TextureSpeed"}
	t.Trail = {"Attachment0","Attachment1","Color","Lifetime","MinLength","Transparency","Enabled","WidthScale"}
	t.SelectionBox = {"Adornee","Color3","LineThickness","SurfaceTransparency","Visible"}
	t.BillboardGui = {"Adornee","Size","StudsOffset","AlwaysOnTop","Enabled"}
	t.SurfaceGui = {"Face","Adornee","Enabled","SizingMode","ZOffset"}
	t.PointLight = {"Brightness","Color","Range","Enabled","Shadows"}
	t.SpotLight = {"Brightness","Color","Range","Angle","Face","Enabled","Shadows"}
	t.SurfaceLight = {"Brightness","Color","Range","Angle","Face","Enabled","Shadows"}
	t.LinearVelocity = {"MaxForce","VelocityConstraintMode","PlaneVelocity","LineVelocity","LineDirection"}
	t.BodyVelocity = {"Velocity","MaxForce"}
	t.BodyPosition = {"Position","MaxForce","P","D"}
	t.BodyGyro = {"CFrame","MaxTorque","P","D"}
	t.HingeConstraint = {"LimitsEnabled","LowerAngle","UpperAngle","AngularSpeed","MotorMaxAcceleration"}
	t.IntValue = {"Value"}
	t.NumberValue = {"Value"}
	t.StringValue = {"Value"}
	t.BoolValue = {"Value"}
	t.ObjectValue = {"Value"}
	t.CFrameValue = {"Value"}
	t.Vector3Value = {"Value"}
	t.Color3Value = {"Value"}
	t.Lighting = {
		"Brightness","ClockTime","FogColor","FogEnd","FogStart",
		"GeographicLatitude","GlobalShadows","OutdoorAmbient","Ambient",
		"ShadowSoftness","Technology",
	}
	return t
end
local STRUCTURE_PROPERTY_SETS = _buildPropertySets()
local function _buildDefaultProps()
	local d = {}
	d.BasePart = {Anchored=false,CanCollide=true,CanTouch=true,CanQuery=true,Transparency=0,Reflectance=0,Massless=false,Locked=false,CastShadow=true,CollisionGroupId=0,RootPriority=0}
	d.Humanoid = {MaxHealth=100,WalkSpeed=16,JumpPower=50,JumpHeight=7.2,AutoRotate=true,AutoJumpEnabled=true,Sit=false,PlatformStand=false,HipHeight=0}
	d.Sound = {Volume=0.5,PlaybackSpeed=1,Looped=false,Playing=false,TimePosition=0}
	d.ParticleEmitter = {Rate=20,Enabled=true}
	d.Tool = {Enabled=true,RequiresHandle=true,ManualActivationOnly=false}
	d.ClickDetector = {MaxActivationDistance=32}
	d.ProximityPrompt = {HoldDuration=0,MaxActivationDistance=10,RequiresLineOfSight=true,Enabled=true}
	d.PointLight = {Brightness=1,Range=16,Enabled=true,Shadows=false}
	d.SpotLight = {Brightness=1,Range=16,Angle=45,Enabled=true,Shadows=false}
	d.SurfaceLight = {Brightness=1,Range=16,Angle=45,Enabled=true,Shadows=false}
	return d
end
local STRUCTURE_DEFAULT_PROPS = _buildDefaultProps()
local function structureProperties(instance)
	local output = {}
	if not StructureConfig.IncludeProperties then return output end
	local ignoreDefaults = StructureConfig.IgnoreDefaultProps
	local seen = {}
	for className, properties in pairs(STRUCTURE_PROPERTY_SETS) do
		if structureSafe(function() return instance:IsA(className) end, false) then
			local defaults = ignoreDefaults and STRUCTURE_DEFAULT_PROPS[className] or nil
			for _, property in ipairs(properties) do
				if not seen[property] then
					local ok, value = pcall(function() return instance[property] end)
					if ok and value ~= nil then
						local isDefault = false
						if defaults and defaults[property] ~= nil then
							local dv = defaults[property]
							local tv = typeof(value)
							if tv == "boolean" or tv == "number" or tv == "string" then
								isDefault = (value == dv)
							end
						end
						if not isDefault then
							output[property] = structureEncode(value)
							seen[property] = true
						end
					end
				end
			end
		end
	end
	return output
end
