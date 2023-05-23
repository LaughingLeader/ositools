return [[--- @meta
--- @diagnostic disable

--- Table that contains every ModTable entry for active mods.
Mods = {}

--- Special global value that contains the current mod UUID during load
--- @type FixedString
ModuleUUID = "UUID"

--- Table that gets stored in the save, unique for each ModTable entry.
--- @type table
PersistentVars = {}

--- @alias OsirisValue number|string
--- @alias OsiFunction (fun(...:OsirisValue):OsirisValue|nil)

--- @alias OsirisEventType string
---|"before" # Trigger event before a call/DB insert is performed
---|"after" # Trigger event after a call/DB insert is performed
---|"beforeDelete" # Trigger event before a DB delete is performed (databases only!)
---|"afterDelete" # Trigger event after a DB delete is performed (databases only!)

--- Using a DB like a function will allow inserting new values into the database (ex. `Osi.DB_IsPlayer("02a77f1f-872b-49ca-91ab-32098c443beb")`
--- @overload fun(...:OsirisValue|nil)
--- @class OsiDatabase
local OsiDatabase = {}
--- Databases can be read using the Get method. The method checks its parameters against the database and only returns rows that match the query.
--- The number of parameters passed to Get must be equivalent to the number of columns in the target database.
--- Each parameter defines an (optional) filter on the corresponding column.
--- If the parameter is nil, the column is not filtered (equivalent to passing _ in Osiris). If the parameter is not nil, only rows with matching values will be returned.
--- @vararg OsirisValue|nil
--- @return table<integer,table<integer,OsirisValue>>
function OsiDatabase:Get(...) end
--- The Delete method can be used to delete rows from databases.
--- The number of parameters passed to Delete must be equivalent to the number of columns in the target database.
--- Each parameter defines an (optional) filter on the corresponding column.
--- If the parameter is nil, the column is not filtered (equivalent to passing _ in Osiris). If the parameter is not nil, only rows with matching values will be deleted.
--- @vararg OsirisValue|nil
function OsiDatabase:Delete(...) end

--- The Osi table contains databases as well as calls, queries, events, and custom PROC / QRY defintions, as long as they are used in a script.
Osi = {
	---All player characters
	---@type OsiDatabase|fun(guid:Guid)
	DB_IsPlayer = {},
	---All origin characters
	---@type OsiDatabase|fun(guid:Guid)
	DB_Origins = {},
	---All player characters that were created in character creation, or that have an `AVATAR` tag
	---@type OsiDatabase|fun(guid:Guid)
	DB_Avatars = {},
	---All objects in combat
	---@type OsiDatabase|fun(guid:Guid, combatID:integer)
	DB_CombatObjects = {},
	---All characters in combat
	---@type OsiDatabase|fun(guid:Guid, combatID:integer)
	DB_CombatCharacters = {},
	---All registered dialogs for objects, the most common being the version with a single character
	---@type OsiDatabase|fun(guid:Guid, dialog:string)|fun(GUID1:Guid, GUID2:Guid, dialog:string)|fun(GUID1:Guid, GUID2:Guid, GUID3:Guid, dialog:string)|fun(GUID1:Guid, GUID2:Guid, GUID3:Guid, GUID4:Guid, dialog:string)
	DB_Dialogs = {},
}

--- @alias i16vec2 int16[]

--- @alias SkillAbility "None"|"Warrior"|"Ranger"|"Rogue"|"Source"|"Fire"|"Water"|"Air"|"Earth"|"Death"|"Summoning"|"Polymorph"
--- @alias SkillElement SkillAbility
--- @alias YesNo "Yes"|"No"

--- @alias GameDifficultyValue uint32
---|0 # Story
---|1 # Explorer
---|2 # Classic
---|3 # Tactician
---|4 # Honour

--- @alias RTPCName "PlaybackSpeed"|"RTPC_Rumble"|"RTPC_Volume_Ambient"|"RTPC_Volume_Cinematic"|"RTPC_Volume_FX"|"RTPC_Volume_MAIN"|"RTPC_Volume_Music"|"RTPC_Volume_Music_Fight"|"RTPC_Volume_UI"|"RTPC_Volume_VO_Dialog"|"RTPC_Volume_VO_Master"|"RTPC_Volume_VO_Narrator"|"RTPC_Volume_VO_Overhead"
--- @alias SoundObjectId "Global"|"Music"|"Ambient"|"HUD"|"GM"|"Player1"|"Player2"|"Player3"|"Player4"
--- @alias StateGroupName "ARX_Dead"|"ARX_Krakenbattle"|"Amb_ARX_Frozen"|"Amb_Endgame_State"|"Amb_LV_State"|"Amb_Tuto_State"|"COS_OrcTemple"|"CoS_ElfTempleNuked"|"DLC_01_Amb_LV_State"|"DLC_01_Amb_WindBlender"|"GM_Theme"|"Items_Objects_MCH_Laboratory_Machines_Turbine_A"|"Menu_Themes"|"Music_Theme"|"Music_Type"|"Proj_Gren_ClusterBomb_Impact_Multi_VoiceLimitSwitch"|"Skill_NPC_VoidGlide"|"Soundvol_Arx_Sewers_DeathfogMachine_Active"|"State_Dialogue"
--- @alias SwitchGroupName "Armor_Type"|"Bear"|"Boar"|"Burning_Witch"|"Cat"|"Chicken"|"Deer"|"Dog"|"Dragon"|"Drillworm_Hatchlings"|"Elemental_Ooze"|"Items_Material"|"Items_Objects_TOOL_Ladder_Material"|"Items_SurfaceType"|"Items_Weight"|"Movement_FX_Type"|"PlayerType"|"Raanaar_Automaton"|"Race"|"Sex"|"Skill_CharacterType"|"Spider"|"Steps_Speed"|"Steps_Terrain"|"Steps_Type"|"Steps_Weight"|"Tiger"|"Troll"|"Variation"|"Vocal_Combat_Type"|"WarOwl"|"Weapon_Action"|"Weapon_Hit_Armor_Type"|"Weapon_Hit_Bloodtype"|"Weapon_Hit_Material_Type"|"Weapon_Material"|"Weapon_Race"|"Weapon_Type"|"Whoosh_Magic"|"Whoosh_Type"|"Whoosh_Weight"|"Wolf"

--- @alias LevelMapName "Armor ArmorValue"|"Armor ConstitutionBoost"|"Armor FinesseBoost"|"Armor HearingBoost"|"Armor IntelligenceBoost"|"Armor MagicArmorValue"|"Armor MagicPointsBoost"|"Armor MemoryBoost"|"Armor SightBoost"|"Armor StrengthBoost"|"Armor Value"|"Armor VitalityBoost"|"Armor WitsBoost"|"ArmorUsageSkill"|"Character Act Strength"|"Character AirSpecialist"|"Character Armor"|"Character Constitution"|"Character Critical Chance"|"Character DualWielding"|"Character EarthSpecialist"|"Character Finesse"|"Character FireSpecialist"|"Character Gain"|"Character Hearing"|"Character Intelligence"|"Character Leadership"|"Character MagicArmor"|"Character Memory"|"Character Necromancy"|"Character Polymorph"|"Character Ranged"|"Character RangerLore"|"Character RogueLore"|"Character Sight"|"Character SingleHanded"|"Character Sourcery"|"Character Strength"|"Character Summoning"|"Character Telekinesis"|"Character TwoHanded"|"Character WarriorLore"|"Character WaterSpecialist"|"Character Wits"|"EmbellishSkill"|"IdentifyRangeSkill"|"Object Armor"|"Object Constitution"|"Object MagicArmor"|"Object Value"|"ObjectDurabilitySkill"|"Potion Armor"|"Potion Constitution"|"Potion Damage"|"Potion Finesse"|"Potion Gain"|"Potion Hearing"|"Potion Intelligence"|"Potion MagicArmor"|"Potion Memory"|"Potion Strength"|"Potion Value"|"Potion Vitality"|"Potion Wits"|"RepairRangeSkill"|"RewardExperience"|"Shield ArmorValue"|"Shield Blocking"|"Shield ConstitutionBoost"|"Shield FinesseBoost"|"Shield HearingBoost"|"Shield IntelligenceBoost"|"Shield MagicArmorValue"|"Shield MagicPointsBoost"|"Shield MemoryBoost"|"Shield SightBoost"|"Shield StrengthBoost"|"Shield Value"|"Shield VitalityBoost"|"Shield WitsBoost"|"SkillData AreaRadius"|"SkillData BackStart"|"SkillData ChanceToPierce"|"SkillData Duration"|"SkillData EndPosRadius"|"SkillData ExplodeRadius"|"SkillData ForkChance"|"SkillData FrontOffset"|"SkillData GrowSpeed"|"SkillData GrowTimeout"|"SkillData HealAmount"|"SkillData Height"|"SkillData HitPointsPercent"|"SkillData HitRadius"|"SkillData Lifetime"|"SkillData MaxDistance"|"SkillData NextAttackChance"|"SkillData NextAttackChanceDivider"|"SkillData Offset"|"SkillData Radius"|"SkillData Range"|"SkillData StatusChance"|"SkillData StatusClearChance"|"SkillData StatusLifetime"|"SkillData SurfaceRadius"|"SkillData TargetRadius"|"SkillData TravelSpeed"|"StatusData Radius"|"Value"|"Weapon ConstitutionBoost"|"Weapon Damage"|"Weapon FinesseBoost"|"Weapon HearingBoost"|"Weapon IntelligenceBoost"|"Weapon MagicPointsBoost"|"Weapon MemoryBoost"|"Weapon SightBoost"|"Weapon StrengthBoost"|"Weapon Value"|"Weapon VitalityBoost"|"Weapon WitsBoost"|"WisdomSkill"

---@alias ModifierValueType "Ability"|"Act"|"ActPart"|"AIFlags"|"AnimType"|"ArmorType"|"AtmosphereType"|"AttributeFlag"|"AttributeFlags"|"BigQualifier"|"CastCheckType"|"Conditions"|"ConstantInt"|"CraftingStationType"|"Custom Properties"|"Damage Type"|"DamageSourceType"|"Death Type"|"FixedString"|"FormatStringColor"|"Game Action"|"Handedness"|"HealValueType"|"IngredientTransformType"|"IngredientType"|"InventoryTabs"|"ItemDataRarity"|"Itemslot"|"MaterialType"|"MemorizationRequirements"|"ModifierType"|"Osiris Task"|"Penalty PreciseQualifier"|"Penalty Qualifier"|"PickingState"|"PreciseQualifier"|"ProjectileDistribution"|"ProjectileType"|"Properties"|"Qualifier"|"RecipeCategory"|"Requirements"|"SavingThrow"|"SkillAbility"|"SkillElement"|"SkillRequirement"|"SkillTargetCondition"|"SkillTier"|"StatusEvent"|"StatusHealType"|"StepsType"|"Surface Change"|"Surface Type"|"SurfaceCollisionFlags"|"VampirismType"|"WeaponType"|"YesNo"
---@alias ModifierListType "Armor"|"Character"|"Object"|"Potion"|"Shield"|"SkillData"|"StatusData"|"Weapon"

--- @alias StatsHealValueType "FixedValue"|"Percentage"|"Qualifier"|"Shield"|"TargetDependent"|"DamagePercentage"

--- @alias CustomConditionEvaluateCallback (fun(condition:EsvServerConditionCheck|EclClientConditionCheck, conditionId:uint32, param:FixedString):boolean|nil)
--- @alias CustomRequirementEvaluateCallback (fun(req:StatsRequirement, ctx:CustomRequirementContext):boolean|nil)

--- @alias EsvGameState ServerGameState|ClientGameState

--- Languages supported by default.
--- @alias LarianSupportedLanguage "Amlatspanish"|"Chinese"|"Chinesetraditional"|"Czech"|"English"|"French"|"German"|"Italian"|"Japanese"|"Korean"|"Polish"|"Portuguesebrazil"|"Russian"|"Spanish"
]]