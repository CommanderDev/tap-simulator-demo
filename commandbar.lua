-- R6: Keep DEFAULT_RIG essentials, weld MERGE_RIG visuals on top (Command Bar)
-- Select 2 Models:
--   DEFAULT_RIG = valid R6 rig (Humanoid + HRP + Motor6Ds + attachments, etc.)
--   MERGE_RIG   = visual rig with parts named:
--                Head, Torso, Left Arm, Right Arm, Left Leg, Right Leg
-- Output: "<MERGE_RIG>_MergedR6" in Workspace

local Selection = game:GetService("Selection")
local sel = Selection:Get()
assert(#sel == 2, "Select exactly TWO Models: DEFAULT_RIG and MERGE_RIG")

local REQUIRED = { "Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg" }
local REQUIRED_SET = {}
for _, n in ipairs(REQUIRED) do REQUIRED_SET[n] = true end

local function isDefaultR6Rig(m)
	if not m:IsA("Model") then return false end
	local hum = m:FindFirstChildOfClass("Humanoid")
	local hrp = m:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp and hrp:IsA("BasePart")) then return false end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("Motor6D") then return true end
	end
	return false
end

local DEFAULT_RIG, MERGE_RIG
if isDefaultR6Rig(sel[1]) then
	DEFAULT_RIG = sel[1]
	MERGE_RIG = sel[2]
elseif isDefaultR6Rig(sel[2]) then
	DEFAULT_RIG = sel[2]
	MERGE_RIG = sel[1]
else
	error("Neither selected model looks like a valid DEFAULT_RIG (needs Humanoid + HumanoidRootPart + Motor6D).")
end

local function findPartDeep(model, name)
	local inst = model:FindFirstChild(name, true)
	if inst and inst:IsA("BasePart") then
		return inst
	end
	return nil
end

local function rotationOnly(cf)
	local _, _, _, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	local right = Vector3.new(r00, r10, r20)
	local up    = Vector3.new(r01, r11, r21)
	local back  = Vector3.new(r02, r12, r22)
	return CFrame.fromMatrix(Vector3.zero, right, up, back)
end

local function safeUniformScale(a, b)
	local am = math.max(a.Magnitude, 1e-6)
	local bm = math.max(b.Magnitude, 1e-6)
	return math.clamp(am / bm, 0.25, 4)
end

local function safePartDefaults(p)
	p.Anchored = false
	p.CanCollide = false
	p.Massless = true
end

local function applyUniformScale(part, s)
	if not s or s == 1 then return end
	part.Size = part.Size * s
	local sm = part:FindFirstChildOfClass("SpecialMesh")
	if sm then
		sm.Scale = sm.Scale * s
	end
end

local function weldTo(parentPart, childPart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = parentPart
	w.Part1 = childPart
	w.Parent = childPart
	return w
end

local function findNearestRequiredAncestor(inst, rootModel)
	local cur = inst
	while cur and cur ~= rootModel do
		if cur:IsA("BasePart") and REQUIRED_SET[cur.Name] then
			return cur
		end
		cur = cur.Parent
	end
	return nil
end

-- 1) Clone DEFAULT_RIG as output (keeps ALL essentials)
local out = DEFAULT_RIG:Clone()
out.Name = MERGE_RIG.Name .. "_MergedR6"
local visualFolder = Instance.new("Folder")
visualFolder.Name = "Visuals"
visualFolder.Parent = out
out:PivotTo(MERGE_RIG:GetPivot())
out.Parent = workspace

-- 2) Remove non-essential junk from DEFAULT clone (Accessories/Hats)
for _, inst in ipairs(out:GetDescendants()) do
	if inst:IsA("Accessory") or inst:IsA("Hat") then
		inst:Destroy()
	end
end

-- 3) Grab default base parts (these contain attachments/etc. — we KEEP them)
local defaultParts = {}
for _, n in ipairs(REQUIRED) do
	local p = out:FindFirstChild(n, true)
	assert(p and p:IsA("BasePart"), "DEFAULT_RIG is missing expected R6 part: " .. n)
	defaultParts[n] = p
end

-- 4) Grab merge body parts (visual sources)
local mergeParts = {}
for _, n in ipairs(REQUIRED) do
	local p = findPartDeep(MERGE_RIG, n)
	assert(p, ("MERGE_RIG is missing '%s' (rename parts to R6 names)"):format(n))
	mergeParts[n] = p
end

-- 5) Compute uniform scale based on torso (prevents stretched head)
local uniformScale = safeUniformScale(defaultParts["Torso"].Size, mergeParts["Torso"].Size)

-- 6) Hide default body parts but KEEP them (preserve attachments/motors)
for _, n in ipairs(REQUIRED) do
	local p = defaultParts[n]
	p.Transparency = 1
	if p:IsA("BasePart") then
		p.CastShadow = false
	end
	safePartDefaults(p)
end

-- 7) Add visual shells: clone merge limbs, scale uniformly, snap to default limb, weld to default limb
local visuals = {} -- map: limbName -> visual part

for _, limbName in ipairs(REQUIRED) do
	local base = defaultParts[limbName]
	local srcVis = mergeParts[limbName]

	local vis = srcVis:Clone()
	vis.Name = limbName .. "_Visual"
	safePartDefaults(vis)
	applyUniformScale(vis, uniformScale)

	-- Snap to base limb
	vis.CFrame = base.CFrame
	vis.Parent = visualFolder

	-- Weld to base limb (Motors stay on base, attachments stay on base)
	weldTo(base, vis)

	visuals[limbName] = vis
end

-- 8) Copy "extra visuals" (hair/hats/face parts that aren't Accessories and aren't the 6 limbs)
-- We attach them to the corresponding default limb (not the visual limb) so attachments/motors remain authoritative.
for _, inst in ipairs(MERGE_RIG:GetDescendants()) do
	if inst:IsA("BasePart") and not REQUIRED_SET[inst.Name] then
		-- If it's already inside one of the 6 merge limbs, it came along when that limb was cloned
		local nearest = findNearestRequiredAncestor(inst, MERGE_RIG)
		if nearest == nil then
			-- If it isn't under a limb, assume it's a head cosmetic by default
			nearest = mergeParts["Head"]
		end

		local attachName = nearest and nearest.Name or "Head"
		local attachTo = defaultParts[attachName] or defaultParts["Head"]
		if attachTo then
			local c = inst:Clone()
			c.Name = inst.Name
			safePartDefaults(c)
			applyUniformScale(c, uniformScale)

			-- Preserve relative offset from the merge ancestor limb -> then apply to default limb
			local rel = nearest.CFrame:ToObjectSpace(inst.CFrame)
			local relPos = rel.Position * uniformScale
			local relRot = rotationOnly(rel)
			c.CFrame = attachTo.CFrame * (CFrame.new(relPos) * relRot)

			c.Parent = out
			weldTo(attachTo, c)
		end
	end
end

-- 9) If "Face" is a Decal on MERGE Head, it came with Head_Visual already.
-- If "Face" is a separate Part, it's handled in extra visuals above.
-- If you have a Decal named "face" somewhere else, it stays on the visual.

Selection:Set({out})
