local math = math
local table = table
local pairs = pairs
local Ext = Ext
local type = type

---@alias GameMathHelperSkillData StatEntrySkillData|StatsSkillPrototype

if Game == nil then Game = {} end

Game.Math = {
	Utils = {}
}

Game.Math.DamageTypeToDeathTypeMap = {
	Physical = "Physical",
	Piercing = "Piercing",
	Fire = "Incinerate",
	Air = "Electrocution",
	Water = "FrozenShatter",
	Earth = "PetrifiedShatter",
	Poison = "Acid",
	Sulfuric = "Sulfur"
}

--- @param damageType string DamageType enumeration
--- @return string
function Game.Math.DamageTypeToDeathType(damageType)
	local deathType = Game.Math.DamageTypeToDeathTypeMap[damageType]
	if deathType ~= nil then
		return deathType
	else
		return "DoT"
	end
end

--- @param item CDivinityStatsItem
function Game.Math.IsRangedWeapon(item)
	local type = item.WeaponType
	return type == "Bow" or type == "Crossbow" or type == "Wand" or type == "Rifle"
end

--- @param primaryAttr integer
function Game.Math.ScaledDamageFromPrimaryAttribute(primaryAttr)
	return (primaryAttr - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DamageBoostFromAttribute
end

--- @param skill GameMathHelperSkillData
--- @param character CDivinityStatsCharacter
function Game.Math.GetPrimaryAttributeAmount(skill, character)
	if skill.UseWeaponDamage == "Yes" and character.MainWeapon ~= nil then
		local main = character.MainWeapon
		local offHand = character.OffHandWeapon
		if offHand ~= nil and Game.Math.IsRangedWeapon(main) == Game.Math.IsRangedWeapon(offHand) then
			return (Game.Math.GetItemRequirementAttribute(character, main) + Game.Math.GetItemRequirementAttribute(character, offHand)) * 0.5
		else
			return Game.Math.GetItemRequirementAttribute(character, main)
		end
	end

	local ability = skill.Ability
	if ability == "Warrior" or ability == "Polymorph" then
		return character.Strength
	elseif ability == "Ranger" or ability == "Rogue" then
		return character.Finesse
	else
		return character.Intelligence
	end
end

--- @param skill GameMathHelperSkillData
--- @param attacker CDivinityStatsCharacter
function Game.Math.GetSkillAttributeDamageScale(skill, attacker)
	if attacker == nil or skill.UseWeaponDamage == "Yes" or skill.Ability == "None" then
		return 1.0
	else
		local primaryAttr = Game.Math.GetPrimaryAttributeAmount(skill, attacker)
		return 1.0 + Game.Math.ScaledDamageFromPrimaryAttribute(primaryAttr)
	end
end

--- @param skill GameMathHelperSkillData
--- @param stealthed boolean
--- @param attackerPos number[]
--- @param targetPos number[]
function Game.Math.GetDamageMultipliers(skill, stealthed, attackerPos, targetPos)
	local stealthDamageMultiplier = 1.0
	if stealthed then
		stealthDamageMultiplier = skill['Stealth Damage Multiplier'] * 0.01
	end

	local targetDistance = math.sqrt((attackerPos[1] - targetPos[1])^2 + (attackerPos[3] - targetPos[3])^2)
	local distanceDamageMultiplier = 1.0
	if targetDistance > 1.0 then
		distanceDamageMultiplier = Ext.Utils.Round(targetDistance) * skill['Distance Damage Multiplier'] * 0.01 + 1
	end

	local damageMultiplier = skill['Damage Multiplier'] * 0.01
	return stealthDamageMultiplier * distanceDamageMultiplier * damageMultiplier
end

--- @param level integer
function Game.Math.GetVitalityBoostByLevel(level)
	local extra = Ext.ExtraData
	local expGrowth = extra.VitalityExponentialGrowth
	local growth = expGrowth ^ (level - 1)

	if level >= extra.FirstVitalityLeapLevel then
		growth = growth * extra.FirstVitalityLeapGrowth / expGrowth
	end

	if level >= extra.SecondVitalityLeapLevel then
		growth = growth * extra.SecondVitalityLeapGrowth / expGrowth
	end

	if level >= extra.ThirdVitalityLeapLevel then
		growth = growth * extra.ThirdVitalityLeapGrowth / expGrowth
	end

	if level >= extra.FourthVitalityLeapLevel then
		growth = growth * extra.FourthVitalityLeapGrowth / expGrowth
	end

	local vit = level * extra.VitalityLinearGrowth + extra.VitalityStartingAmount * growth
	return math.floor(vit / 5.0) * 5.0
end

--- @param level integer
function Game.Math.GetLevelScaledDamage(level)
	local vitalityBoost = Game.Math.GetVitalityBoostByLevel(level)
	return vitalityBoost / (((level - 1) * Ext.ExtraData.VitalityToDamageRatioGrowth) + Ext.ExtraData.VitalityToDamageRatio)
end

--- @param level integer
function Game.Math.GetAverageLevelDamage(level)
	local scaled = Game.Math.GetLevelScaledDamage(level)
	return ((level * Ext.ExtraData.ExpectedDamageBoostFromAttributePerLevel) + 1.0) * scaled
		* ((level * Ext.ExtraData.ExpectedDamageBoostFromSkillAbilityPerLevel) + 1.0)
end

--- @param level integer
function Game.Math.GetLevelScaledWeaponDamage(level)
	local scaledDmg = Game.Math.GetLevelScaledDamage(level)
	return scaledDmg / ((level * Ext.ExtraData.ExpectedDamageBoostFromWeaponAbilityPerLevel) + 1.0)
end

--- @param level integer
function Game.Math.GetLevelScaledMonsterWeaponDamage(level)
	local weaponDmg = Game.Math.GetLevelScaledWeaponDamage(level)
	return ((level * Ext.ExtraData.MonsterDamageBoostPerLevel) + 1.0) * weaponDmg
end

--- @param attacker CDivinityStatsCharacter
function Game.Math.GetShieldPhysicalArmor(attacker)
	local shield = attacker:GetItemBySlot("Shield", true)
	if shield == nil or shield.ItemType ~= "Shield" then
		return 0
	end
	local stats = shield.DynamicStats
	local armor = 0
	local boost = 0
	for i, stat in pairs(stats) do
		if stat.StatsType == "Shield" then
			---@cast stat CDivinityStatsEquipmentAttributesShield
			armor = armor + stat.ArmorValue
			boost = boost + stat.ArmorBoost * 0.01
		end
	end
	return armor * (1.0 + boost)
end

Game.Math.DamageBoostTable = {
	--- @param character CDivinityStatsCharacter
	Physical = function (character)
		return character.WarriorLore * Ext.ExtraData.SkillAbilityPhysicalDamageBoostPerPoint
	end,
	--- @param character CDivinityStatsCharacter
	Fire = function (character)
		return character.FireSpecialist * Ext.ExtraData.SkillAbilityFireDamageBoostPerPoint
	end,
	--- @param character CDivinityStatsCharacter
	Air = function (character)
		return character.AirSpecialist * Ext.ExtraData.SkillAbilityAirDamageBoostPerPoint
	end,
	--- @param character CDivinityStatsCharacter
	Water = function (character)
		return character.WaterSpecialist * Ext.ExtraData.SkillAbilityWaterDamageBoostPerPoint
	end,
	--- @param character CDivinityStatsCharacter
	Earth = function (character)
		return character.EarthSpecialist * Ext.ExtraData.SkillAbilityPoisonAndEarthDamageBoostPerPoint
	end,
	--- @param character CDivinityStatsCharacter
	Poison = function (character)
		return character.EarthSpecialist * Ext.ExtraData.SkillAbilityPoisonAndEarthDamageBoostPerPoint
	end
}

--- @param character CDivinityStatsCharacter
--- @param damageType string See DamageType enum
function Game.Math.GetDamageBoostByType(character, damageType)
	if type(character) == "table" then
		local boostFunc = Game.Math.DamageBoostTable[damageType]
		if boostFunc ~= nil then
			return boostFunc(character) * 0.01
		end
	else
		local boost = Ext.Stats.Math.GetDamageBoostByType(character, damageType)
		if boost then
			return boost * 0.01
		end
	end
	return 0
end

--- @param character CDivinityStatsCharacter
--- @param damageList StatsDamagePairList
function Game.Math.ApplyDamageBoosts(character, damageList)
	for i, damage in pairs(damageList:ToTable()) do
		local boost = Game.Math.GetDamageBoostByType(character, damage.DamageType)
		if boost > 0.0 then
			damageList:Add(damage.DamageType, Ext.Utils.Round(damage.Amount * boost))
		end
	end
end

local DamageSourceCalcTable = {
	BaseLevelDamage = function (attacker, target, level)
		return math.max(0, Ext.Utils.Round(Game.Math.GetLevelScaledDamage(level)))
	end,
	AverageLevelDamge = function (attacker, target, level)
		return math.max(0, Ext.Utils.Round(Game.Math.GetAverageLevelDamage(level)))
	end,
	MonsterWeaponDamage = function (attacker, target, level)
		return math.max(0, Ext.Utils.Round(Game.Math.GetLevelScaledMonsterWeaponDamage(level)))
	end,
	SourceMaximumVitality = function (attacker, target, level)
		return attacker.MaxVitality
	end,
	SourceMaximumPhysicalArmor = function (attacker, target, level)
		return attacker.MaxArmor
	end,
	SourceMaximumMagicArmor = function (attacker, target, level)
		return attacker.MaxMagicArmor
	end,
	SourceCurrentVitality = function (attacker, target, level)
		return attacker.CurrentVitality
	end,
	SourceCurrentPhysicalArmor = function (attacker, target, level)
		return attacker.CurrentArmor
	end,
	SourceCurrentMagicArmor = function (attacker, target, level)
		return attacker.CurrentMagicArmor
	end,
	SourceShieldPhysicalArmor = function (attacker, target, level)
		return Ext.Utils.Round(Game.Math.GetShieldPhysicalArmor(attacker))
	end,
	TargetMaximumVitality = function (attacker, target, level)
		return target.MaxVitality
	end,
	TargetMaximumPhysicalArmor = function (attacker, target, level)
		return target.MaxArmor
	end,
	TargetMaximumMagicArmor = function (attacker, target, level)
		return target.MaxMagicArmor
	end,
	TargetCurrentVitality = function (attacker, target, level)
		return target.CurrentVitality
	end,
	TargetCurrentPhysicalArmor = function (attacker, target, level)
		return target.CurrentArmor
	end,
	TargetCurrentMagicArmor = function (attacker, target, level)
		return target.CurrentMagicArmor
	end
}

--- @param skillDamageType string See DamageType enumeration
--- @param attacker CDivinityStatsCharacter
--- @param target CDivinityStatsCharacter|CDivinityStatsItem
--- @param level integer
function Game.Math.CalculateBaseDamage(skillDamageType, attacker, target, level)
	return DamageSourceCalcTable[skillDamageType](attacker, target, level)
end

--- @param damageList StatsDamagePairList
function Game.Math.GetDamageListDeathType(damageList)
	local biggestDamage = -1
	local deathType

	for i, damage in pairs(damageList:ToTable()) do
		if damage.Amount > biggestDamage then
			deathType = Game.Math.DamageTypeToDeathType(damage.DamageType)
			biggestDamage = damage.Amount
		end
	end

	return deathType
end

--- @param character CDivinityStatsCharacter
--- @param weapon CDivinityStatsItem
function Game.Math.GetWeaponAbility(character, weapon)
	if weapon == nil then
		return nil
	end

	local offHandWeapon = character.OffHandWeapon
	if offHandWeapon ~= nil and Game.Math.IsRangedWeapon(weapon) == Game.Math.IsRangedWeapon(offHandWeapon) then
		return "DualWielding"
	end

	local weaponType = weapon.WeaponType
	if weaponType == "Bow" or weaponType == "Crossbow" or weaponType == "Rifle" then
		return "Ranged"
	end

	if weapon.IsTwoHanded then
		return "TwoHanded"
	end

	return "SingleHanded"
end

--- @param character CDivinityStatsCharacter
--- @param weapon CDivinityStatsItem
function Game.Math.ComputeWeaponCombatAbilityBoost(character, weapon)
	local abilityType = Game.Math.GetWeaponAbility(character, weapon)

	if abilityType == "SingleHanded" or abilityType == "TwoHanded" or abilityType == "Ranged" or abilityType == "DualWielding" then
		local abilityLevel = character[abilityType]
		return abilityLevel * Ext.ExtraData.CombatAbilityDamageBonus
	else
		return 0
	end
end

--- @param weapon CDivinityStatsItem
function Game.Math.GetWeaponScalingRequirement(weapon)
	local requirementName
	-- Stat requirements without points (i.e. just "Strength") get -1 as their Param value, so we need a -2 minimum to capture them
	local largestRequirement = -2

	for i, requirement in pairs(weapon.Requirements) do
		local reqName = requirement.Requirement
		if not requirement.Not and requirement.Param > largestRequirement and
			(reqName == "Strength" or reqName == "Finesse" or reqName == "Intelligence" or
			reqName == "Constitution" or reqName == "Memory" or reqName == "Wits") then
			requirementName = reqName
			largestRequirement = requirement.Param
		end
	end

	return requirementName
end

--- @param character CDivinityStatsCharacter
--- @param weapon CDivinityStatsItem
function Game.Math.GetItemRequirementAttribute(character, weapon)
	local attribute = Game.Math.GetWeaponScalingRequirement(weapon)
	if attribute ~= nil then
		return character[attribute]
	else
		return 0
	end
end

--- @param character CDivinityStatsCharacter
--- @param weapon CDivinityStatsItem
function Game.Math.ComputeWeaponRequirementScaledDamage(character, weapon)
	local scalingReq = Game.Math.GetWeaponScalingRequirement(weapon)
	if scalingReq ~= nil then
		return Game.Math.ScaledDamageFromPrimaryAttribute(character[scalingReq]) * 100.0
	else
		return 0
	end
end

-- from CDivinityStats_Item::ComputeDamage
--- @param weapon CDivinityStatsItem
--- @return table<DamageType, {Min:integer, Max:integer}> damages
--- @return number damageBoost
function Game.Math.ComputeBaseWeaponDamage(weapon)
	local damages = {}
	local stats = weapon.DynamicStats
	local baseStat = stats[1] --[[@as CDivinityStatsEquipmentAttributesWeapon]]
	local baseDmgFromBase = baseStat.DamageFromBase * 0.01
	local baseMinDamage = baseStat.MinDamage
	local baseMaxDamage = baseStat.MaxDamage
	local damageBoost = 0

	for i, stat in pairs(stats) do
		if stat.StatsType == "Weapon" then
			---@cast stat CDivinityStatsEquipmentAttributesWeapon

			damageBoost = damageBoost + stat.DamageBoost

			if stat.DamageType ~= "None" then
				local dmgType = stat.DamageType
				local dmgFromBase = stat.DamageFromBase * 0.01
				local minDamage = stat.MinDamage
				local maxDamage = stat.MaxDamage

				if dmgFromBase ~= 0 then
					if stat == baseStat then
						if baseMinDamage ~= 0 then
							minDamage = math.max(dmgFromBase * baseMinDamage, 1.0)
						end
						if baseMaxDamage ~= 0 then
							maxDamage = math.max(dmgFromBase * baseMaxDamage, 1.0)
						end
					else
						minDamage = math.max(baseDmgFromBase * dmgFromBase * baseMinDamage, 1.0)
						maxDamage = math.max(baseDmgFromBase * dmgFromBase * baseMaxDamage, 1.0)
					end
				end

				if minDamage > 0 then
					maxDamage = math.max(maxDamage, minDamage + 1.0)
				end

				if damages[dmgType] == nil then
					damages[dmgType] = {
						Min = minDamage,
						Max = maxDamage
					}
				else
					local damage = damages[dmgType]
					damage.Min = damage.Min + minDamage
					damage.Max = damage.Max + maxDamage
				end
			end
		end
	end

	return damages, damageBoost
end

-- from CDivinityStats_Item::ComputeDamage
--- @param weapon CDivinityStatsItem
function Game.Math.CalculateWeaponDamageWithDamageBoost(weapon)
	local damages, damageBoost = Game.Math.ComputeBaseWeaponDamage(weapon)
	local boost = 1.0 + damageBoost * 0.01

	for damageType, damage in pairs(damages) do
		if damageBoost ~= 0 then
			damage.Min = math.ceil(damage.Min * boost)
			damage.Max = math.ceil(damage.Max * boost)
		else
			damage.Min = Ext.Utils.Round(damage.Min)
			damage.Max = Ext.Utils.Round(damage.Max)
		end
	end

	return damages
end

-- from CDivinityStats_Item::ComputeScaledDamage
--- @param character CDivinityStatsCharacter
--- @param weapon CDivinityStatsItem
function Game.Math.CalculateWeaponScaledDamageRanges(character, weapon)
	local damages = Game.Math.CalculateWeaponDamageWithDamageBoost(weapon)

	local boost = character.DamageBoost
		+ Game.Math.ComputeWeaponCombatAbilityBoost(character, weapon)
		+ Game.Math.ComputeWeaponRequirementScaledDamage(character, weapon)
	boost = boost / 100.0

	if character.IsSneaking then
		boost = boost + Ext.ExtraData['Sneak Damage Multiplier']
	end

	local boostMin = math.max(-1.0, boost)

	for damageType, damage in pairs(damages) do
		damage.Min = damage.Min + math.ceil(damage.Min * boostMin)
		damage.Max = damage.Max + math.ceil(damage.Max * boost)
	end

	return damages
end

-- from CDivinityStats_Character::Game.Math.CalculateWeaponDamageInner
--- @param character CDivinityStatsCharacter
--- @param weapon CDivinityStatsItem
--- @param damageList StatsDamagePairList
--- @param noRandomization boolean
function Game.Math.CalculateWeaponScaledDamage(character, weapon, damageList, noRandomization)
	local damages = Game.Math.CalculateWeaponScaledDamageRanges(character, weapon)

	for damageType, damage in pairs(damages) do
		local randRange = 1
		if damage.Max - damage.Min + 1 >= 1 then
			randRange = damage.Max - damage.Min + 1
		end
		local finalAmount = 0

		if noRandomization then
			finalAmount = damage.Min + math.floor(randRange / 2)
		else
			finalAmount = damage.Min + Ext.Utils.Random(0, randRange)
		end

		damageList:Add(damageType, finalAmount)
	end
end

--- @param attacker CDivinityStatsCharacter
--- @param weapon CDivinityStatsItem
--- @param noRandomization boolean
function Game.Math.CalculateWeaponDamage(attacker, weapon, noRandomization)
	local damageList = Ext.Stats.NewDamageList()

	Game.Math.CalculateWeaponScaledDamage(attacker, weapon, damageList, noRandomization)

	local offhand = attacker.OffHandWeapon

	if offhand == nil or weapon.InstanceId ~= offhand.InstanceId then
		---@type table<integer, {Name:FixedString, Multiplier:number}>
		local bonusWeapons = {}

		local len = #attacker.DynamicStats
		if len >= 3 then
			for i=3,len do
				local v = attacker.DynamicStats[i]
				--Needs an IsBoostActive check
				if v and v.BonusWeapon and v.BonusWeapon ~= "" then
					bonusWeapons[#bonusWeapons+1] = {
						Name = v.BonusWeapon,
						Multiplier = v.BonusWeaponDamageMultiplier or 0 -- Affected by Status.StatsMultiplier
					}
				end
			end
		end
		for i, bonusWeapon in pairs(bonusWeapons) do
			local name = bonusWeapon.Name
			local multiplier = bonusWeapon.Multiplier
			local bonusWeaponStats = Ext.Stats.GetItemBaseStats(name, attacker.Level)
			if bonusWeaponStats then
				local bonusWeaponDamage = Ext.Stats.NewDamageList()
				if multiplier ~= 0 then
					local base = bonusWeaponStats.DynamicStats[1] --[[@as CDivinityStatsEquipmentAttributesWeapon]]
					base.DamageBoost = multiplier
				end
				Game.Math.CalculateWeaponScaledDamage(attacker, bonusWeaponStats, bonusWeaponDamage, noRandomization)
				damageList:Merge(bonusWeaponDamage)
			end
		end
	end

	Game.Math.ApplyDamageBoosts(attacker, damageList)

	if offhand ~= nil and weapon.InstanceId == offhand.InstanceId then
		damageList:Multiply(Ext.ExtraData.DualWieldingDamagePenalty)
	end

	return damageList
end

--- @param skill GameMathHelperSkillData
--- @param attacker CDivinityStatsCharacter
--- @param isFromItem boolean
--- @param stealthed boolean
--- @param attackerPos number[]
--- @param targetPos number[]
--- @param level integer
--- @param noRandomization boolean
--- @param mainWeapon CDivinityStatsItem  Optional mainhand weapon to use in place of the attacker's.
--- @param offHandWeapon CDivinityStatsItem   Optional offhand weapon to use in place of the attacker's.
function Game.Math.GetSkillDamage(skill, attacker, isFromItem, stealthed, attackerPos, targetPos, level, noRandomization, mainWeapon, offHandWeapon)
	if attacker ~= nil and level < 0 then
		level = attacker.Level
	end

	---@cast attacker CDivinityStatsCharacter

	local damageMultiplier = skill['Damage Multiplier'] * 0.01
	local damageMultipliers = Game.Math.GetDamageMultipliers(skill, stealthed, attackerPos, targetPos)
	local skillDamageType = nil

	if level <= 0 and skill.OverrideSkillLevel == "Yes" and skill.Level > 0 then
		level = skill.Level
	end

	local damageList = Ext.Stats.NewDamageList()

	if damageMultiplier <= 0 then
		return
	end

	if skill.UseWeaponDamage == "Yes" then

		---@type DamageType|nil
		local damageType = skill.DamageType
		if damageType == "None" or damageType == "Sentinel" then
			damageType = nil
		end

		local weapon = mainWeapon or attacker.MainWeapon
		local offHand = offHandWeapon or attacker.OffHandWeapon

		if weapon ~= nil then
			local mainDmgs = Game.Math.CalculateWeaponDamage(attacker, weapon, noRandomization)
			mainDmgs:Multiply(damageMultipliers)
			if damageType ~= nil then
				mainDmgs:ConvertDamageType(damageType)
			end
			damageList:Merge(mainDmgs)
		end

		if offHand ~= nil and Game.Math.IsRangedWeapon(weapon) == Game.Math.IsRangedWeapon(offHand) then
			local offHandDmgs = Game.Math.CalculateWeaponDamage(attacker, offHand, noRandomization)
			offHandDmgs:Multiply(damageMultipliers)
			if damageType ~= nil then
				offHandDmgs:ConvertDamageType(damageType)
				skillDamageType = damageType
			end
			damageList:Merge(offHandDmgs)
		end

		damageList:AggregateSameTypeDamages()
	else
		local damageType = skill.DamageType

		local baseDamage = Game.Math.CalculateBaseDamage(skill.Damage, attacker, nil, level)
		local damageRange = skill['Damage Range']
		local randomMultiplier
		if noRandomization then
			randomMultiplier = 0.0
		else
			randomMultiplier = 1.0 + (Ext.Utils.Random(0, damageRange) - damageRange/2) * 0.01
		end

		local attrDamageScale
		local skillDamage = skill.Damage
		if skillDamage == "BaseLevelDamage" or skillDamage == "AverageLevelDamge" or skillDamage == "MonsterWeaponDamage" then
			attrDamageScale = Game.Math.GetSkillAttributeDamageScale(skill, attacker)
		else
			attrDamageScale = 1.0
		end

		local damageBoost
		if attacker ~= nil then
			damageBoost = attacker.DamageBoost / 100.0 + 1.0
		else
			damageBoost = 1.0
		end

		local finalDamage = baseDamage * randomMultiplier * attrDamageScale * damageMultipliers
		finalDamage = math.max(Ext.Utils.Round(finalDamage), 1)
		finalDamage = math.ceil(finalDamage * damageBoost)
		damageList:Add(damageType, finalDamage)

		if attacker ~= nil then
			Game.Math.ApplyDamageBoosts(attacker, damageList)
		end
	end

	local deathType = skill.DeathType
	if deathType == "None" then
		if skill.UseWeaponDamage == "Yes" then
			deathType = Game.Math.GetDamageListDeathType(damageList)
		else
			if skillDamageType == nil then
				skillDamageType = skill.DamageType
			end

			deathType = Game.Math.DamageTypeToDeathType(skillDamageType)
		end
	end

	return damageList, deathType
end

Game.Math.HitFlag = {
	Hit = 1,
	Blocked = 2,
	Dodged = 4,
	Missed = 8,
	CriticalHit = 0x10,
	Backstab = 0x20,
	FromSetHP = 0x40,
	DontCreateBloodSurface = 0x80,
	Reflection = 0x200,
	NoDamageOnOwner = 0x400,
	FromShacklesOfPain = 0x800,
	DamagedMagicArmor = 0x1000,
	DamagedPhysicalArmor = 0x2000,
	DamagedVitality = 0x4000,
	Flanking = 0x8000,
	PropagatedFromOwner = 0x10000,
	Surface = 0x20000,
	DoT = 0x40000,
	ProcWindWalker = 0x80000,
	CounterAttack = 0x100000,
	Poisoned = 0x200000,
	Burning = 0x400000,
	Bleeding = 0x800000,
	NoEvents = 0x80000000
}

--- @param damageList StatsDamagePairList
--- @param attacker CDivinityStatsCharacter
function Game.Math.ApplyDamageSkillAbilityBonuses(damageList, attacker)

	if attacker == nil then
		return
	 end

	 local magicArmorDamage = 0
	 local armorDamage = 0

	 for i,damage in pairs(damageList:ToTable()) do
		 local type = damage.DamageType
		 if type == "Magic" or type == "Fire" or type == "Air" or type == "Water" or type == "Earth" then
			 magicArmorDamage = magicArmorDamage + damage.Amount
		 end

		 if type == "Physical" or type == "Corrosive" or type == "Sulfuric" then
			 armorDamage = armorDamage + damage.Amount
		 end
	 end

	 if magicArmorDamage > 0 then
		 local airSpecialist = attacker.AirSpecialist
		 if airSpecialist > 0 then
			 local magicBonus = airSpecialist * Ext.ExtraData.SkillAbilityDamageToMagicArmorPerPoint
			 if magicBonus > 0 then
				 magicArmorDamage = math.ceil((magicArmorDamage * magicBonus) / 100.0)
				 damageList:Add("Magic", magicArmorDamage)
			 end
		 end
	 end

	 if armorDamage > 0 then
		 local armorBonus = attacker.WarriorLore * Ext.ExtraData.SkillAbilityDamageToPhysicalArmorPerPoint
		 if armorBonus > 0 then
			 armorDamage = math.ceil((armorDamage * armorBonus) / 100.0)
			 damageList:Add("Corrosive", armorDamage)
		 end
	 end
end

--- @param character CDivinityStatsCharacter
--- @param damageType DamageType
function Game.Math.GetResistance(character, damageType)
	if damageType == "None" or damageType == "Chaos" then
		return 0
	end

	if type(character) == "table" then
		return character[damageType .. "Resistance"]
	end

	return Ext.Stats.Math.GetResistance(character, damageType, false)
end

--- @param character CDivinityStatsCharacter
--- @param damageList StatsDamagePairList
function Game.Math.ApplyHitResistances(character, damageList)
	for i,damage in pairs(damageList:ToTable()) do
		local resistance = Game.Math.GetResistance(character, damage.DamageType)
		damageList:Add(damage.DamageType, math.floor(damage.Amount * -resistance / 100.0))
	end
end

--- @param character CDivinityStatsCharacter
--- @param attacker CDivinityStatsCharacter
--- @param damageList StatsDamagePairList
function Game.Math.ApplyDamageCharacterBonuses(character, attacker, damageList)
	damageList:AggregateSameTypeDamages()
	Game.Math.ApplyHitResistances(character, damageList)

	Game.Math.ApplyDamageSkillAbilityBonuses(damageList, attacker)
end


--- @param character CDivinityStatsCharacter
--- @param ability string Ability enumeration
function Game.Math.GetAbilityCriticalHitMultiplier(character, ability)
	if ability == "TwoHanded" then
		return Ext.Utils.Round(character.TwoHanded * Ext.ExtraData.CombatAbilityCritMultiplierBonus)
	end

	if ability == "RogueLore" then
		return Ext.Utils.Round(character.RogueLore * Ext.ExtraData.SkillAbilityCritMultiplierPerPoint)
	end

	return 0
end

--- @param weapon CDivinityStatsItem
--- @param character CDivinityStatsCharacter
--- @param criticalMultiplier number
--- @return number
function Game.Math.GetCriticalHitMultiplier(weapon, character, criticalMultiplier)
	criticalMultiplier = criticalMultiplier or 0
	if weapon.ItemType == "Weapon" then
		for i,stat in pairs(weapon.DynamicStats) do
			---@cast stat CDivinityStatsEquipmentAttributesWeapon
			criticalMultiplier = criticalMultiplier + stat.CriticalDamage
		end

		if character ~= nil then
			local ability = Game.Math.GetWeaponAbility(character, weapon)
			criticalMultiplier = criticalMultiplier + Game.Math.GetAbilityCriticalHitMultiplier(character, ability) + Game.Math.GetAbilityCriticalHitMultiplier(character, "RogueLore")

			if character.TALENT_Human_Inventive then
				criticalMultiplier = criticalMultiplier + Ext.ExtraData.TalentHumanCriticalMultiplier
			end
		end
	end

	return criticalMultiplier * 0.01
end

--- @param hit StatsHitDamageInfo
--- @param attacker CDivinityStatsCharacter
--- @param damageMultiplier number
--- @param criticalMultiplier number
--- @return number
function Game.Math.ApplyCriticalHit(hit, attacker, damageMultiplier, criticalMultiplier)
	local mainWeapon = attacker.MainWeapon
	if mainWeapon ~= nil then
		hit.CriticalHit = true
		damageMultiplier = damageMultiplier + (Game.Math.GetCriticalHitMultiplier(mainWeapon, attacker, criticalMultiplier) - 1.0)
	end
	return damageMultiplier
end

--- @param hit StatsHitDamageInfo
--- @param attacker CDivinityStatsCharacter
--- @param hitType string HitType enumeration
--- @param criticalRoll string CriticalRoll enumeration
function Game.Math.ShouldApplyCriticalHit(hit, attacker, hitType, criticalRoll)
	if criticalRoll ~= "Roll" then
		return criticalRoll == "Critical"
	end

	if attacker.TALENT_Haymaker then
		return false
	end

	if hitType == "DoT" or hitType == "Surface" then
		return false
	end

	local critChance = attacker.CriticalChance
	if attacker.TALENT_ViolentMagic and hitType == "Magic" then
		critChance = critChance * Ext.ExtraData.TalentViolentMagicCriticalChancePercent * 0.01
		critChance = math.max(critChance, 1)
	else
		if hit.Backstab then
			return true
		end

		if hitType == "Magic" then
			return false
		end
	end

	return math.random(0, 99) < critChance
end

--- @param hit StatsHitDamageInfo
--- @param target CDivinityStatsCharacter
--- @param attacker CDivinityStatsCharacter
--- @param hitType string HitType enumeration
--- @param criticalRoll string CriticalRoll enumeration
--- @param damageMultiplier number
--- @param criticalMultiplier number
--- @return number
function Game.Math.ConditionalApplyCriticalHitMultiplier(hit, target, attacker, hitType, criticalRoll, damageMultiplier, criticalMultiplier)
	if Game.Math.ShouldApplyCriticalHit(hit, attacker, hitType, criticalRoll) then
		damageMultiplier = Game.Math.ApplyCriticalHit(hit, attacker, damageMultiplier, criticalMultiplier)
	end
	return damageMultiplier
end

--- @param hit StatsHitDamageInfo
--- @param target CDivinityStatsCharacter
--- @param attacker CDivinityStatsCharacter
--- @param hitType string HitType enumeration
function Game.Math.ApplyLifeSteal(hit, target, attacker, hitType)
	if attacker == nil or hitType == "DoT" or hitType == "Surface" then
		return
	end

	local magicDmg = hit.DamageList:GetByType("Magic")
	local corrosiveDmg = hit.DamageList:GetByType("Corrosive")
	local lifesteal = hit.TotalDamageDone - hit.ArmorAbsorption - corrosiveDmg - magicDmg

	if hit.FromShacklesOfPain or hit.NoDamageOnOwner or hit.Reflection then
		local modifier = Ext.ExtraData.LifestealFromReflectionModifier
		lifesteal = math.floor(lifesteal * modifier)
	end

	if lifesteal > target.CurrentVitality then
		lifesteal = target.CurrentVitality
	end

	if lifesteal > 0 then
		hit.LifeSteal = math.max(math.ceil(lifesteal * attacker.LifeSteal / 100), 0)
	end
end

--- @param damageList StatsDamagePairList
--- @param hit StatsHitDamageInfo
function Game.Math.ApplyDamagesToHitInfo(damageList, hit)
	local totalDamage = 0
	for i,damage in pairs(damageList:ToTable()) do
		totalDamage = totalDamage + damage.Amount
		if damage.DamageType == "Chaos" then
			hit.DamageList:Add(hit.DamageType, damage.Amount)
		else
			hit.DamageList:Add(damage.DamageType, damage.Amount)
		end
	end

	hit.TotalDamageDone = hit.TotalDamageDone + totalDamage
end

--- @param damageList StatsDamagePairList
--- @param armor integer
function Game.Math.ComputeArmorDamage(damageList, armor)
	local damage = damageList:GetByType("Corrosive") + damageList:GetByType("Physical") + damageList:GetByType("Sulfuric")
	return math.min(armor, damage)
end

--- @param damageList StatsDamagePairList
--- @param magicArmor integer
function Game.Math.ComputeMagicArmorDamage(damageList, magicArmor)
	local damage = damageList:GetByType("Magic")
		+ damageList:GetByType("Fire")
		+ damageList:GetByType("Water")
		+ damageList:GetByType("Air")
		+ damageList:GetByType("Earth")
		+ damageList:GetByType("Poison")
	return math.min(magicArmor, damage)
end

--- Returns true if the hit is Missed/Dodged/Blocked, or Invulnerable (with specific conditions).
--- @param hit StatsHitDamageInfo
--- @return boolean
function Game.Math.Utils.HitFailed(hit)
	if hit.Missed or hit.Dodged or hit.Blocked then
		return true
	elseif not hit.Hit and hit.Invulnerable then
		---hit.Invulnerable requires Missed/Dodged/Blocked/Hit to be false.
		return true
	end
	return false
end

--- @param hit StatsHitDamageInfo
--- @param damageList StatsDamagePairList
--- @param statusBonusDmgTypes StatsDamagePairList
--- @param hitType string HitType enumeration
--- @param target CDivinityStatsCharacter
--- @param attacker CDivinityStatsCharacter
--- @param damageMultiplier number
function Game.Math.DoHit(hit, damageList, statusBonusDmgTypes, hitType, target, attacker, damageMultiplier)
	--Extender logic:
	--Tweak to support mods modifying these flags before CCH.
	--The regular engine code just sets hit.Hit = true, which will cause Missed/etc hits to still hit.
	hit.Hit = not Game.Math.Utils.HitFailed(hit)
	damageList:AggregateSameTypeDamages()
	damageList:Multiply(damageMultiplier)

	local totalDamage = 0
	for i,damage in pairs(damageList:ToTable()) do
		totalDamage = totalDamage + damage.Amount
	end

	if totalDamage < 0 then
		damageList:Clear()
	end

	Game.Math.ApplyDamageCharacterBonuses(target, attacker, damageList)
	damageList:AggregateSameTypeDamages()
	hit.DamageList = Ext.Stats.NewDamageList()

	for i,damageType in pairs(statusBonusDmgTypes:ToTable()) do
		damageList:Add(damageType, math.ceil(totalDamage * 0.1))
	end

	Game.Math.ApplyDamagesToHitInfo(damageList, hit)
	hit.ArmorAbsorption = hit.ArmorAbsorption + Game.Math.ComputeArmorDamage(damageList, target.CurrentArmor)
	hit.ArmorAbsorption = hit.ArmorAbsorption + Game.Math.ComputeMagicArmorDamage(damageList, target.CurrentMagicArmor)

	if hit.TotalDamageDone > 0 then
		Game.Math.ApplyLifeSteal(hit, target, attacker, hitType)
	else
		hit.DontCreateBloodSurface = true
	end

	if hitType == "Surface" then
		hit.Surface = true
	end

	if hitType == "DoT" then
		hit.DoT = true
	end
end

--- @param attacker CDivinityStatsCharacter
--- @param target CDivinityStatsCharacter
--- @param highGround string HighGround enumeration
function Game.Math.GetAttackerDamageMultiplier(attacker, target, highGround)
	if target == nil then
		return 0.0
	end

	if highGround == "HighGround" then
		local rangerLoreBonus = attacker.RangerLore * Ext.ExtraData.SkillAbilityHighGroundBonusPerPoint * 0.01
		return math.max(rangerLoreBonus + Ext.ExtraData.HighGroundBaseDamageBonus, 0.0)
	elseif highGround == "LowGround" then
		return Ext.ExtraData.LowGroundBaseDamagePenalty
	else
		return 0.0
	end
end

--- @param character CDivinityStatsCharacter
--- @param item CDivinityStatsItem
function Game.Math.DamageItemDurability(character, item)
	local degradeSpeed = 0
	for i,stats in pairs(item.DynamicStats) do
		degradeSpeed = degradeSpeed + stats.DurabilityDegradeSpeed
	end

	if degradeSpeed > 0 then
		local durability = math.max(0, item.Durability)
		item.Durability = durability
		item.ShouldSyncStats = 1

		if durability == 0 then
			-- FIXME not implemented yet
			-- Ext.ReevaluateItems(character)
		end
	end
end

--- @param character CDivinityStatsCharacter
--- @param item CDivinityStatsItem
function Game.Math.ConditionalDamageItemDurability(character, item)
	if not character.InParty or not item.LoseDurabilityOnCharacterHit or item.Unbreakable or not Game.Math.IsRangedWeapon(item) then
		return
	end

	local chance = 100
	if character.TALENT_Durability then
		chance = 50
	end

	if math.random(0, 99) < chance then
		Game.Math.DamageItemDurability(character, item)
	end
end

--- @param attacker CDivinityStatsCharacter
--- @param target CDivinityStatsCharacter
function Game.Math.CalculateHitChance(attacker, target)
	if attacker.TALENT_Haymaker then
		return 100
	end

	local ranged = Game.Math.IsRangedWeapon(attacker.MainWeapon.WeaponType)
	local accuracy = attacker.Accuracy
	local dodge = 0
	if (not attacker.Invisible or ranged) and target.IsIncapacitatedRefCount == 0 then
		dodge = target.Dodge
	end

	local chanceToHit1 = Ext.Utils.Round(((100.0 - dodge) * accuracy) / 100)
	chanceToHit1 = math.max(0, math.min(100, chanceToHit1))
	return chanceToHit1 + attacker.ChanceToHitBoost
end

--- @param target CDivinityStatsCharacter|IGameObject
--- @param attacker CDivinityStatsCharacter|IGameObject
function Game.Math.IsInFlankingPosition(target, attacker)
	local tPos = target.Position
	local aPos = attacker.Position
	local rotation = target.Rotation

	local dx, dy, dz = tPos[1] - aPos[1], tPos[2] - aPos[2], tPos[3] - aPos[3]
	local distanceSq = 1.0 / math.sqrt(dx^2 + dy^2 + dz^2)
	local nx, ny, nz = dx * distanceSq, dy * distanceSq, dz * distanceSq

	local ang = -rotation[6] * nx - rotation[7] * ny - rotation[8] * nz
	return ang > math.cos(0.52359879)
end

--- @param target CDivinityStatsCharacter|IGameObject
--- @param attacker CDivinityStatsCharacter|IGameObject
function Game.Math.CanBackstab(target, attacker)
	local targetPos = target.Position
	local attackerPos = attacker.Position

	local atkDir = {}
	for i=1,3 do
		atkDir[i] = attackerPos[i] - targetPos[i]
	end

	local atkAngle = math.deg(math.atan(atkDir[3], atkDir[1]))
	if atkAngle < 0 then
		atkAngle = 360 + atkAngle
	end

	local targetRot = target.Rotation
	local angle = math.deg(math.atan(-targetRot[1], targetRot[3]))
	if angle < 0 then
		angle = 360 + angle
	end

	local relAngle = atkAngle - angle
	if relAngle < 0 then
		relAngle = 360 + relAngle
	end

	return relAngle >= 150 and relAngle <= 210
end

--- @param attacker CDivinityStatsCharacter
--- @param target CDivinityStatsCharacter
local function CCH_CalculateHitChance(attacker, target)
	local evt = {
		Name = "GetHitChance",
		Stopped = false,
		CanPreventAction = false,
		ActionPrevented = false,
		Attacker = attacker,
		Target = target,
		PreventAction = function () end
	}
	evt.StopPropagation = function (self)
		evt.Stopped = true
	end
	Ext.Events.GetHitChance:Throw(evt)
	if type(evt.HitChance) == "number" then
		return evt.HitChance
	else
		return Game.Math.CalculateHitChance(attacker, target)
	end
end

--- @param target CDivinityStatsCharacter
--- @param attacker CDivinityStatsCharacter
--- @param weapon CDivinityStatsItem
--- @param preDamageList StatsDamagePairList
--- @param hitType string HitType enumeration
--- @param noHitRoll boolean
--- @param forceReduceDurability boolean
--- @param hit StatsHitDamageInfo
--- @param alwaysBackstab boolean
--- @param highGroundFlag string HighGround enumeration
--- @param criticalRoll string CriticalRoll enumeration
function Game.Math.ComputeCharacterHit(target, attacker, weapon, preDamageList, hitType, noHitRoll, forceReduceDurability, hit, alwaysBackstab, highGroundFlag, criticalRoll)
	--Extender logic:
	--Skip doing anything if a mod has modified this hit already.
	local hitBlocked = Game.Math.Utils.HitFailed(hit)

	local damageMultiplier = 1.0
	local criticalMultiplier = 0.0
	local statusBonusDmgTypes = {}
	local damageList = Ext.Stats.NewDamageList()
	damageList:CopyFrom(preDamageList)

	if attacker == nil then
		if not hitBlocked then
			Game.Math.DoHit(hit, damageList, statusBonusDmgTypes, hitType, target, attacker, damageMultiplier)
		end
		return hit
	end

	damageMultiplier = 1.0 + Game.Math.GetAttackerDamageMultiplier(attacker, target, highGroundFlag)
	if hitType == "Magic" or hitType == "Surface" or hitType == "DoT" or hitType == "Reflected" then
		damageMultiplier = Game.Math.ConditionalApplyCriticalHitMultiplier(hit, target, attacker, hitType, criticalRoll, damageMultiplier, criticalMultiplier)
		if hitBlocked then
			goto postHitBlocked
		end
		Game.Math.DoHit(hit, damageList, statusBonusDmgTypes, hitType, target, attacker, damageMultiplier)
		return hit
	end

	if alwaysBackstab or (weapon ~= nil and weapon.WeaponType == "Knife" and Game.Math.CanBackstab(target, attacker)) then
		hit.Backstab = true
	end

	if hitType == "Melee" then
		if Game.Math.IsInFlankingPosition(target, attacker) then
			hit.Flanking = true
		end

		-- Apply Sadist talent
		if attacker.TALENT_Sadist then
			if hit.Poisoned then
				table.insert(statusBonusDmgTypes, "Poison")
			end
			if hit.Burning then
				table.insert(statusBonusDmgTypes, "Fire")
			end
			if hit.Bleeding then
				table.insert(statusBonusDmgTypes, "Physical")
			end
		end
	end

	if attacker.TALENT_Damage then
		damageMultiplier = damageMultiplier + 0.1
	end

	if not hitBlocked and not noHitRoll then
		local hitChance = CCH_CalculateHitChance(attacker, target)
		local hitRoll = math.random(0, 99)
		if hitRoll >= hitChance then
			if target.TALENT_RangerLoreEvasionBonus and hitRoll < hitChance + 10 then
				hit.Dodged = true
			else
				hit.Missed = true
			end
			hitBlocked = true
		else
			local blockChance = target.BlockChance
			if not hit.Backstab and blockChance > 0 and math.random(0, 99) < blockChance then
				hit.Blocked = true
				hitBlocked = true
			end
		end
	end

	::postHitBlocked::

	if weapon ~= nil and weapon.Name ~= "DefaultWeapon" and hitType ~= "Magic"
	and forceReduceDurability and not hit.Missed and not hit.Dodged then
		Game.Math.ConditionalDamageItemDurability(attacker, weapon)
	end

	if not hitBlocked then
		damageMultiplier = Game.Math.ConditionalApplyCriticalHitMultiplier(hit, target, attacker, hitType, criticalRoll, damageMultiplier, criticalMultiplier)
		Game.Math.DoHit(hit, damageList, statusBonusDmgTypes, hitType, target, attacker, damageMultiplier)
	end

	return hit
end

--- @param character CDivinityStatsCharacter
--- @param skill GameMathHelperSkillData
--- @param mainWeapon CDivinityStatsItem|nil  Optional mainhand weapon to use in place of the character's.
--- @param offHandWeapon CDivinityStatsItem|nil   Optional offhand weapon to use in place of the character's.
function Game.Math.GetSkillDamageRange(character, skill, mainWeapon, offHandWeapon)
	local damageMultiplier = skill['Damage Multiplier'] * 0.01

	if skill.UseWeaponDamage == "Yes" then
		local mainWeapon = mainWeapon or character.MainWeapon
		local offHandWeapon = offHandWeapon or character.OffHandWeapon
		local mainDamageRange = Game.Math.CalculateWeaponScaledDamageRanges(character, mainWeapon)

		if offHandWeapon ~= nil and Game.Math.IsRangedWeapon(mainWeapon) == Game.Math.IsRangedWeapon(offHandWeapon) then
			local offHandDamageRange = Game.Math.CalculateWeaponScaledDamageRanges(character, offHandWeapon)

			-- Note: This differs from the way the game applies DualWieldingDamagePenalty.
			-- In the original tooltip code, it is applied for the whole damage value,
			-- not per damage type, so the result may differ from the original tooltip code
			-- if DualWieldingDamagePenalty is not 1.0 or 0.5.
			-- However, this formula is the correct one and the vanilla tooltip returns
			-- buggy values if DualWieldingDamagePenalty ~= 1.0 and ~= 0.5
			local dualWieldPenalty = Ext.ExtraData.DualWieldingDamagePenalty
			for damageType, range in pairs(offHandDamageRange) do
				local min = math.ceil(range.Min * dualWieldPenalty)
				local max = math.ceil(range.Max * dualWieldPenalty)
				local range = mainDamageRange[damageType]
				if mainDamageRange[damageType] ~= nil then
					range.Min = range.Min + min
					range.Max = range.Max + max
				else
					mainDamageRange[damageType] = {Min = min, Max = max}
				end
			end
		end

		for damageType, range in pairs(mainDamageRange) do
			local min = Ext.Utils.Round(range.Min * damageMultiplier)
			local max = Ext.Utils.Round(range.Max * damageMultiplier)
			range.Min = min + math.ceil(min * Game.Math.GetDamageBoostByType(character, damageType))
			range.Max = max + math.ceil(max * Game.Math.GetDamageBoostByType(character, damageType))
		end

		local damageType = skill.DamageType
		if damageType ~= "None" and damageType ~= "Sentinel" then
			local min, max = 0, 0
			local boost = Game.Math.GetDamageBoostByType(character, damageType)
			for _, range in pairs(mainDamageRange) do
				min = min + range.Min + math.ceil(range.Min * boost)
				max = max + range.Max + math.ceil(range.Min * boost)
			end

			mainDamageRange = {}
			mainDamageRange[damageType] = {Min = min, Max = max}
		end

		return mainDamageRange
	else
		local damageType = skill.DamageType
		if damageMultiplier <= 0 then
			return {}
		end

		local level = character.Level
		if (level < 0 or skill.OverrideSkillLevel == "Yes") and skill.Level > 0 then
			level = skill.Level
		end

		local skillDamageType = skill.Damage
		local attrDamageScale
		if skillDamageType == "BaseLevelDamage" or skillDamageType == "AverageLevelDamge" or skillDamageType == "MonsterWeaponDamage" then
			attrDamageScale = Game.Math.GetSkillAttributeDamageScale(skill, character)
		else
			attrDamageScale = 1.0
		end

		local baseDamage = Game.Math.CalculateBaseDamage(skill.Damage, character, nil, level) * attrDamageScale * damageMultiplier
		local damageRange = skill['Damage Range'] * baseDamage * 0.005

		local damageTypeBoost = 1.0 + Game.Math.GetDamageBoostByType(character, damageType)
		local damageBoost = 1.0 + (character.DamageBoost / 100.0)

		local finalMin = math.ceil(math.ceil(Ext.Utils.Round(baseDamage - damageRange) * damageBoost) * damageTypeBoost)
		local finalMax = math.ceil(math.ceil(Ext.Utils.Round(baseDamage + damageRange) * damageBoost) * damageTypeBoost)

		if finalMin > 0 then
			finalMax = math.max(finalMin + 1.0, finalMax)
		end

		local damageRanges = {}
		damageRanges[damageType] = {
			Min = finalMin, Max = finalMax
		}
		return damageRanges
	end
end

Game.Math.StatusSavingThrows = {
	MUTED = "MagicArmor",
	CHARMED = "MagicArmor",
	DRAIN = "MagicArmor",
	SOURCE_MUTED = "MagicArmor",

	KNOCKED_DOWN = "SavingThrow",
	CONSUME = "SavingThrow",
	DAMAGE = "SavingThrow",
	INCAPACITATED = "SavingThrow",
	POLYMORPHED = "SavingThrow",
	DAMAGE_ON_MOVE = "SavingThrow",
	DEMONIC_BARGAIN = "SavingThrow",
	CHALLENGE = "SavingThrow",
	DISARMED = "SavingThrow",
	HEAL_SHARING = "SavingThrow",

	INFECTIOUS_DISEASED = "PhysicalArmor",
	SHACKLES_OF_PAIN = "PhysicalArmor",
	DECAYING_TOUCH = "PhysicalArmor",
	REMORSE = "Remorse"
}

--- @param status EsvStatus
function Game.Math.GetSavingThrowForStatus(status)
	if status.StatusId ~= status.StatusType then
		local stat = Ext.Stats.Get(status.StatusId, nil, false)
		if stat then
			return stat.SavingThrow
		end
	end

	local savingThrow = Game.Math.StatusSavingThrows[status.StatusType]
	if savingThrow == nil then
		return "None"
	elseif savingThrow == "SavingThrow" then
		local stat = Ext.Stats.Get(status.StatusId, nil, false)
		if stat then
			return stat.SavingThrow
		end
	else
		return savingThrow
	end
end

Game.Math.MagicSavingThrows = {
	Frozen = true,
	Mute = true,
	Stunned = true,
	Fear = true,
	Charm = true,
	Petrified = true,
	Taunted = true,
	MagicArmor = true
}

--- @param character CDivinityStatsCharacter
--- @param savingThrow string SavingThrow enumeration
function Game.Math.GetSavingThrowChanceMultiplier(character, savingThrow)
	if savingThrow == "PhysicalArmor" then
		if character.CurrentArmor > 0 and not character.TALENT_Raistlin then
			return 0.0
		end
	elseif Game.Math.MagicSavingThrows[savingThrow] ~= nil then
		if character.CurrentMagicArmor > 0 and not character.TALENT_Raistlin then
			return 0.0
		end
	end

	return 1.0
end

--- @param status EsvStatus
--- @return boolean
function Game.Math.CanTriggerTorturer(status)
	if Ext.Utils.IsValidHandle(status.StatusSourceHandle) then
		local source = Ext.Entity.GetGameObject(status.StatusSourceHandle) --[[@as EsvCharacter]]
		local causeType = status.DamageSourceType
		local statusType = status.StatusType

		return source ~= nil and
			source.Stats ~= nil and
			source.Stats.TALENT_Torturer and
			causeType ~= "SurfaceMove" and causeType ~= "SurfaceCreate" and causeType ~= "SurfaceStatus" and
			(statusType == "DAMAGE" or statusType == "DAMAGE_ON_MOVE")
	end
	return false
end

--- @param status EsvStatus
--- @param isEnterCheck boolean
function Game.Math.StatusGetEnterChance(status, isEnterCheck)
	if Ext.Utils.IsValidHandle(status.TargetHandle) then
		local target = Ext.Entity.GetGameObject(status.TargetHandle)
		if target ~= nil and not target.Dead and not target:HasTag("GHOST") then
			if status.ForceStatus then
				return 100
			end

			local savingThrow = Game.Math.GetSavingThrowForStatus(status)
			if savingThrow ~= "None" then
				if isEnterCheck then
					if Game.Math.CanTriggerTorturer(status) then
						return 100
					else
						return status.CanEnterChance * Game.Math.GetSavingThrowChanceMultiplier(target, savingThrow)
					end
				end
			elseif not isEnterCheck then
				return 100
			end
		end
	end

	return status.CanEnterChance
end


--- @param character CDivinityStatsCharacter
--- @param weapon CDivinityStatsItem
function Game.Math.GetWeaponAPCost(character, weapon)
	if weapon.ItemType ~= "Weapon" then
		return 0
	end

	---@cast weapon +CDivinityStatsEquipmentAttributesWeapon

	local ap = weapon.AttackAPCost
	if weapon.WeaponType == "Knife" and character.TALENT_RogueLoreDaggerAPBonus then
		ap = ap - 1
	end

	return math.max(ap, 1)
end


--- @param character CDivinityStatsCharacter
function Game.Math.GetCharacterWeaponAPCost(character)
	local mainWeapon = character.MainWeapon
	local offHandWeapon = character.OffHandWeapon

	local ap = Game.Math.GetWeaponAPCost(character, mainWeapon)

	if offHandWeapon ~= nil and Game.Math.IsRangedWeapon(mainWeapon) == Game.Math.IsRangedWeapon(offHandWeapon) then
		ap = ap + Game.Math.GetWeaponAPCost(character, offHandWeapon) - Ext.ExtraData.DualWieldingAPPenalty
	else
		--- @type CDivinityStatsItem
		local offHandItem = character:GetItemBySlot("Shield")
		if offHandItem ~= nil and offHandItem.ItemType == "Shield" then
			ap = ap + Ext.ExtraData.ShieldAPCost
		end
	end

	return ap
end


local ElementalAffinityAiFlags = {
	Fire = { "Lava", "Fire" },
	Water = { "Water" },
	Air = { "Electrified" },
	Earth = { "Oil", "Poison" },
	Death = { "Blood" },
	Sulfurology = { "Sulfurium" }
}

--- @param skill GameMathHelperSkillData
--- @param character CDivinityStatsCharacter
--- @param grid EocAiGrid
--- @param position number[]
--- @param radius number
function Game.Math.GetSkillAPCost(skill, character, grid, position, radius)
	local baseAP = skill.ActionPoints
	if character == nil or baseAP <= 0 then
		return baseAP, false
	end

	local ability = skill.Ability
	local elementalAffinity = false
	if ability ~= "None" and baseAP > 1 and character.TALENT_ElementalAffinity and grid ~= nil and position ~= nil and radius ~= nil then
		local aiFlags = ElementalAffinityAiFlags[ability]
		if aiFlags ~= nil then
			elementalAffinity = grid:SearchForCell(position[1], position[3], radius, aiFlags, -1.0)
			if elementalAffinity then
				baseAP = baseAP - 1
			end
		end
	end

	local characterAP = 1
	if skill.Requirement ~= "None" and skill.OverrideMinAP == "No" then
		characterAP = Game.Math.GetCharacterWeaponAPCost(character)
	end

	return math.max(characterAP, baseAP), elementalAffinity
end