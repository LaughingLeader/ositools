#pragma once

#include <cstdint>

namespace osidbg
{
	template <class T, class L>
	struct EnumInfoBase
	{
		struct Label
		{
			T Val;
			char const * Name;
		};

		static std::optional<T> Find(char const * name)
		{
			for (auto i = 0; i < std::size(L::Values); i++) {
				if (strcmp(name, L::Values[i].Name) == 0) {
					return L::Values[i].Val;
				}
			}

			return {};
		}

		static std::optional<char const *> Find(T val)
		{
			for (auto i = 0; i < std::size(L::Values); i++) {
				if (val == L::Values[i].Val) {
					return L::Values[i].Name;
				}
			}

			return {};
		}
	};

	template<typename T> struct EnumInfoFakeDep : public std::false_type {};

	template <class T>
	struct EnumInfo
	{
		static_assert(EnumInfoFakeDep<T>::value, "EnumInfo not implemented for this type!");
	};

	#define MAKE_ENUM_INFO(typeName, size) \
		template <> struct EnumInfo<typeName> : public EnumInfoBase<typeName, EnumInfo<typeName>> { \
			static Label const Values[size]; \
		}


	enum PathRootType
	{
		Root = 0, // Filesystem root
		Data = 1, // Game data folder
		Public = 2, // Game data/Public folder
		MyDocuments = 3, // User's My Documents folder
		GameStorage = 4 // Game settings/savegames folder
	};


	enum class GameState : uint32_t
	{
		Unknown = 0,
		Init,
		InitMenu,
		InitNetwork,
		InitConnection,
		Idle,
		LoadMenu,
		Menu,
		Exit,
		SwapLevel,
		LoadLevel = 10,
		LoadModule,
		LoadSession,
		LoadGMCampaign,
		UnloadLevel,
		UnloadModule,
		UnloadSession,
		Paused,
		PrepareRunning,
		Running,
		Disconnect = 20,
		Join,
		StartLoading,
		StopLoading,
		StartServer,
		Movie,
		Installation,
		GameMasterPause,
		ModReceiving,
		Lobby = 30,
		BuildStory
	};


	enum class ComponentType : uint32_t
	{
		AnimationBlueprint = 0,
		Spline,
		Combat,
		CustomStats,
		GameMaster,
		GMJournalNode,
		Container,
		ContainerElement,
		Net,
		OverviewMap,
		Note,
		Vignette,
		CustomStatDefinition,
		Item,
		Character,
		Egg,
		Projectile,
		// ...
	};


	enum class SystemType : uint32_t
	{
		AnimationBlueprint = 0,
		Container,
		ContainerElement,
		TurnManager,
		SightManager,
		GameAction,
		Surface,
		Character,
		Projectile,
		Trigger,
		Item,
		Egg,
		Effect,
		Shroud,
		EnvironmentalStatus,
		NetEntity,
		CustomStat,
		Reward,
		CharacterSpline,
		CameraSpline,
		GM,
		GMCampaign,
		GMJournal
	};


	enum NetMessage : uint32_t
	{
		NETMSG_CUSTOM_STATS_DEFINITION_CREATE = 315,
		NETMSG_CUSTOM_STATS_DEFINITION_REMOVE = 316,
		NETMSG_CUSTOM_STATS_DEFINITION_UPDATE = 317,
		NETMSG_CUSTOM_STATS_CREATE = 318,
		NETMSG_CUSTOM_STATS_UPDATE = 319
	};


	enum class PlayerUpgradeAttribute
	{
		Strength = 0,
		Finesse = 1,
		Intelligence = 2,
		Constitution = 3,
		Memory = 4,
		Wits = 5
	};

	MAKE_ENUM_INFO(PlayerUpgradeAttribute, 6);


	enum class StatGetterType
	{
		MaxMp = 0,
		APStart = 1,
		APRecovery = 2,
		APMaximum = 3,

		Strength = 4,
		Finesse = 5,
		Intelligence = 6,
		Vitality = 7,
		Memory = 8,
		Wits = 9,

		Accuracy = 10,
		Dodge = 11,
		CriticalChance = 12,

		FireResistance = 13,
		EarthResistance = 14,
		WaterResistance = 15,
		AirResistance = 16,
		PoisonResistance = 17,
		ShadowResistance = 18,
		CustomResistance = 19,

		LifeSteal = 20,
		Sight = 21,
		Hearing = 22,
		Movement = 23,
		Initiative = 24,
		Unknown = 25,
		ChanceToHitBoost = 26
	};

	MAKE_ENUM_INFO(StatGetterType, 27);


	enum class AbilityType
	{
		None = 0,
		WarriorLore = 1,
		RangerLore = 2,
		RogueLore = 3,
		SingleHanded = 4,
		TwoHanded = 5,
		Reflection = 6,
		Ranged = 7,
		Shield = 8,
		Reflexes = 9,
		PhysicalArmorMastery = 10,
		Sourcery = 11,
		Telekinesis = 12,
		FireSpecialist = 13,
		WaterSpecialist = 14,
		AirSpecialist = 15,
		EarthSpecialist = 16,
		Necromancy = 17,
		Summoning = 18,
		Polymorph = 19,
		Repair = 20,
		Sneaking = 21,
		Pickpocket = 22,
		Thievery = 23,
		Loremaster = 24,
		Crafting = 25,
		Barter = 26,
		Charm = 27,
		Intimidate = 28,
		Reason = 29,
		Persuasion = 30,
		Leadership = 31,
		Luck = 32,
		DualWielding = 33,
		Wand = 34,
		MagicArmorMastery = 35,
		VitalityMastery = 36,
		Perseverance = 37,
		Runecrafting = 38,
		Brewmaster = 39
	};

	MAKE_ENUM_INFO(AbilityType, 40);

	enum class CriticalRoll
	{
		Roll = 0,
		Critical = 1,
		NotCritical = 2
	};

	MAKE_ENUM_INFO(CriticalRoll, 3);

	enum class HighGroundBonus
	{
		Unknown = 0,
		HighGround = 1,
		EvenGround = 2,
		LowGround = 3
	};

	MAKE_ENUM_INFO(HighGroundBonus, 4);

	enum class EquipmentStatsType : uint32_t
	{
		Weapon = 0,
		Armor = 1,
		Shield = 2
	};

	MAKE_ENUM_INFO(EquipmentStatsType, 3);


	enum StatusFlags0 : uint8_t
	{
		SF0_KeepAlive = 1,
		SF0_IsOnSourceSurface = 2,
		SF0_IsFromItem = 4,
		SF0_Channeled = 8,
		SF0_IsLifeTimeSet = 0x10,
		SF0_InitiateCombat = 0x20,
		SF0_Influence = 0x80
	};

	MAKE_ENUM_INFO(StatusFlags0, 7);

	enum StatusFlags1 : uint8_t
	{
		SF1_BringIntoCombat = 1,
		SF1_IsHostileAct = 2,
		SF1_IsInvulnerable = 8,
		SF1_IsResistingDeath = 0x10
	};

	MAKE_ENUM_INFO(StatusFlags1, 4);

	enum StatusFlags2 : uint8_t
	{
		SF2_ForceStatus = 1,
		SF2_ForceFailStatus = 2,
		SF2_RequestDelete = 0x20,
		SF2_RequestDeleteAtTurnEnd = 0x40,
		SF2_Started = 0x80
	};

	MAKE_ENUM_INFO(StatusFlags2, 5);

	enum class StatusType : uint32_t
	{
		Hit = 1,
		Dying = 2,
		Heal = 3,
		Muted = 4,
		Charmed = 5,
		KnockedDown = 6,
		Summoning = 7,
		Healing = 8,
		Thrown = 9,
		TeleportFall = 0x0B,
		Consume = 0x0C,
		Combat = 0x0D,
		AoO = 0x0E,
		StoryFrozen = 0x0F,
		Sneaking = 0x10,
		Unlock = 0x11,
		Fear = 0x12,
		Boost = 0x13,
		Unsheathed = 0x14,
		Stance = 0x15,
		Sitting = 0x16,
		Lying = 0x17,
		Blind = 0x18,
		Smelly = 0x19,
		Clean = 0x1A,
		InfectiousDiseased = 0x1B,
		Invisible = 0x1C,
		Rotate = 0x1D,
		Encumbered = 0x1E,
		Identify = 0x1F,
		Repair = 0x20,
		Material = 0x21,
		Leadership = 0x22,
		Explode = 0x23,
		Adrenaline = 0x24,
		ShacklesOfPain = 0x25,
		ShacklesOfPainCaster = 0x26,
		WindWalker = 0x27,
		DarkAvenger = 0x28,
		Remorse = 0x29,
		DecayingTouch = 0x2A,
		Unhealable = 0x2B,
		Flanked = 0x2C,
		Channeling = 0x2D,
		Drain = 0x2E,
		LingeringWounds = 0x2F,
		Infused = 0x30,
		SpiritVision = 0x31,
		Spirit = 0x32,
		Damage = 0x33,
		ForceMove = 0x34,
		Climbing = 0x35,
		Incapacitated = 0x36,
		InSurface = 0x37,
		SourceMuted = 0x38,
		Overpowered = 0x39,
		Combustion = 0x3A,
		Polymorphed = 0x3B,
		DamageOnMove = 0x3C,
		DemonicBargain = 0x3D,
		GuardianAngel = 0x3E,
		Floating = 0x40,
		Challenge = 0x41,
		Disarmed = 0x42,
		HealSharing = 0x43,
		HealSharingCaster = 0x44,
		ExtraTurn = 0x45,
		ActiveDefense = 0x46,
		Spark = 0x47,
		PlayDead = 0x48,
		Constrained = 0x49,
		Effect = 0x4A,
		Deactivated = 0x4B,
		TutorialBed = 0x4C,
	};

	enum class CauseType : uint8_t
	{
		None = 0,
		SurfaceMove = 1,
		SurfaceCreate = 2,
		SurfaceStatus = 3,
		StatusEnter = 4,
		StatusTick = 5,
		Attack = 6,
		Offhand = 7,
		GM = 8
	};

	MAKE_ENUM_INFO(CauseType, 9);

	enum class DeathType : uint8_t
	{
		None = 0,
		Physical = 1,
		Piercing = 2,
		Arrow = 3,
		DoT = 4,
		Incinerate = 5,
		Acid = 6,
		Electrocution = 7,
		FrozenShatter = 8,
		PetrifiedShatter = 9,
		Explode = 10,
		Surrender = 11,
		Hang = 12,
		KnockedDown = 13,
		Lifetime = 14,
		Sulfur = 15,
		Sentinel = 16
	};

	MAKE_ENUM_INFO(DeathType, 17);

	enum class DamageType : uint32_t
	{
		None = 0,
		Physical = 1,
		Piercing = 2,
		Corrosive = 3,
		Magic = 4,
		Chaos = 5,
		Fire = 6,
		Air = 7,
		Water = 8,
		Earth = 9,
		Poison = 10,
		Shadow = 11,
		Sulfuric = 12,
		Sentinel = 13
	};

	MAKE_ENUM_INFO(DamageType, 14);

	enum class HitType : uint32_t
	{
		Melee = 0,
		Magic = 1,
		Ranged = 2,
		WeaponDamage = 3,
		Surface = 4,
		DoT = 5,
		Reflected = 6
	};

	MAKE_ENUM_INFO(HitType, 7);

	enum class ItemSlot : uint8_t
	{
		Helmet = 0,
		Breast = 1,
		Leggings = 2,
		Weapon = 3,
		Shield = 4,
		Ring = 5,
		Belt = 6,
		Boots = 7,
		Gloves = 8,
		Amulet = 9,
		Ring2 = 10,
		Wings = 11,
		Horns = 12,
		Overhead = 13,
		Sentinel = 14
	};

	MAKE_ENUM_INFO(ItemSlot, 15);

	enum HitFlag : uint32_t
	{
		HF_Hit = 1,
		HF_Blocked = 2,
		HF_Dodged = 4,
		HF_Missed = 8,
		HF_CriticalHit = 0x10,
		HF_AlwaysBackstab = 0x20,
		HF_FromSetHP = 0x40,
		HF_DontCreateBloodSurface = 0x80,
		HF_Reflection = 0x200,
		HF_NoDamageOnOwner = 0x400,
		HF_FromShacklesOfPain = 0x800,
		HF_DamagedMagicArmor = 0x1000,
		HF_DamagedPhysicalArmor = 0x2000,
		HF_DamagedVitality = 0x4000,
		HF_PropagatedFromOwner = 0x10000,
		HF_Surface = 0x20000,
		HF_DoT = 0x40000,
		HF_ProcWindWalker = 0x80000,
		// Custom flags
		HF_NoEvents = 0x80000000
	};

	MAKE_ENUM_INFO(HitFlag, 19);

	enum StatusHealType : uint32_t
	{
		SHT_None = 0,
		SHT_Vitality = 1,
		SHT_PhysicalArmor = 2,
		SHT_MagicArmor = 3,
		SHT_AllArmor = 4,
		SHT_All = 5,
		SHT_Source = 6
	};

	MAKE_ENUM_INFO(StatusHealType, 7);

	enum EsvCharacterFlags : uint64_t
	{
		CF_HostControl = 0x08,
		CF_OffStage = 0x20,
		CF_CannotBePossessed = 0x80
	};

	enum EsvCharacterFlags2 : uint8_t
	{
		CF_Global = 0x01,
		CF_HasOsirisDialog = 0x02,
		CF_HasDefaultDialog = 0x04,
		CF_TreasureGeneratedForTrader = 0x10,
		CF_Resurrected = 0x20
	};

	enum EsvCharacterFlags3 : uint8_t
	{
		CF_IsPet = 0x01,
		CF_IsSpectating = 0x02,
		CF_NoReptuationEffects = 0x04,
		CF_HasWalkSpeedOverride = 0x08,
		CF_HasRunSpeedOverride = 0x10,
		CF_IsGameMaster = 0x20,
		CF_IsPossessed = 0x40
	};

	enum class GameActionType
	{
		RainAction = 1,
		StormAction = 2,
		WallAction = 4,
		TornadoAction = 6,
		PathAction = 7,
		GameObjectMoveAction = 8,
		StatusDomeAction = 9
	};

	enum StatAttributeFlags : uint64_t
	{
		AF_FreezeImmunity = 1ull << 0,
		AF_BurnImmunity = 1ull << 1,
		AF_StunImmunity = 1ull << 2,
		AF_PoisonImmunity = 1ull << 3,
		AF_CharmImmunity = 1ull << 4,
		AF_FearImmunity = 1ull << 5,
		AF_KnockdownImmunity = 1ull << 6,
		AF_MuteImmunity = 1ull << 7,
		AF_ChilledImmunity = 1ull << 8,
		AF_WarmImmunity = 1ull << 9,
		AF_WetImmunity = 1ull << 10,
		AF_BleedingImmunity = 1ull << 11,
		AF_CrippledImmunity = 1ull << 12,
		AF_BlindImmunity = 1ull << 13,
		AF_CursedImmunity = 1ull << 14,
		AF_WeakImmunity = 1ull << 15,
		AF_SlowedImmunity = 1ull << 16,
		AF_DiseasedImmunity = 1ull << 17,
		AF_InfectiousDiseasedImmunity = 1ull << 18,
		AF_PetrifiedImmunity = 1ull << 19,
		AF_DrunkImmunity = 1ull << 20,
		AF_SlippingImmunity = 1ull << 21,
		AF_FreezeContact = 1ull << 22,
		AF_BurnContact = 1ull << 23,
		AF_StunContact = 1ull << 24,
		AF_PoisonContact = 1ull << 25,
		AF_ChillContact = 1ull << 26,
		AF_Torch = 1ull << 27,
		AF_Arrow = 1ull << 28,
		AF_Unbreakable = 1ull << 29,
		AF_Unrepairable = 1ull << 30,
		AF_Unstorable = 1ull << 31,
		AF_Grounded = 1ull << 32,
		AF_HastedImmunity = 1ull << 33,
		AF_TauntedImmunity = 1ull << 34,
		AF_SleepingImmunity = 1ull << 35,
		AF_AcidImmunity = 1ull << 36,
		AF_SuffocatingImmunity = 1ull << 37,
		AF_RegeneratingImmunity = 1ull << 38,
		AF_DisarmedImmunity = 1ull << 39,
		AF_DecayingImmunity = 1ull << 40,
		AF_ClairvoyantImmunity = 1ull << 41,
		AF_EnragedImmunity = 1ull << 42,
		AF_BlessedImmunity = 1ull << 43,
		AF_ProtectFromSummon = 1ull << 44,
		AF_Floating = 1ull << 45,
		AF_DeflectProjectiles = 1ull << 46,
		AF_IgnoreClouds = 1ull << 47,
		AF_MadnessImmunity = 1ull << 48,
		AF_ChickenImmunity = 1ull << 49,
		AF_IgnoreCursedOil = 1ull << 50,
		AF_ShockedImmunity = 1ull << 51,
		AF_WebImmunity = 1ull << 52,
		AF_LootableWhenEquipped = 1ull << 53,
		AF_PickpocketableWhenEquipped = 1ull << 54,
		AF_LoseDurabilityOnCharacterHit = 1ull << 55,
		AF_EntangledContact = 1ull << 56,
		AF_ShacklesOfPainImmunity = 1ull << 57,
		AF_MagicalSulfur = 1ull << 58,
		AF_ThrownImmunity = 1ull << 59,
		AF_InvisibilityImmunity = 1ull << 60
	};

	MAKE_ENUM_INFO(StatAttributeFlags, 61);


	enum TalentType
	{
		TALENT_None = 0,
		TALENT_ItemMovement = 1,
		TALENT_ItemCreation = 2,
		TALENT_Flanking = 3,
		TALENT_AttackOfOpportunity = 4,
		TALENT_Backstab = 5,
		TALENT_Trade = 6,
		TALENT_Lockpick = 7,
		TALENT_ChanceToHitRanged = 8,
		TALENT_ChanceToHitMelee = 9,
		TALENT_Damage = 10,
		TALENT_ActionPoints = 11,
		TALENT_ActionPoints2 = 12,
		TALENT_Criticals = 13,
		TALENT_IncreasedArmor = 14,
		TALENT_Sight = 15,
		TALENT_ResistFear = 16,
		TALENT_ResistKnockdown = 17,
		TALENT_ResistStun = 18,
		TALENT_ResistPoison = 19,
		TALENT_ResistSilence = 20,
		TALENT_ResistDead = 21,
		TALENT_Carry = 22,
		TALENT_Throwing = 23,
		TALENT_Repair = 24,
		TALENT_ExpGain = 25,
		TALENT_ExtraStatPoints = 26,
		TALENT_ExtraSkillPoints = 27,
		TALENT_Durability = 28,
		TALENT_Awareness = 29,
		TALENT_Vitality = 30,
		TALENT_FireSpells = 31,
		TALENT_WaterSpells = 32,
		TALENT_AirSpells = 33,
		TALENT_EarthSpells = 34,
		TALENT_Charm = 35,
		TALENT_Intimidate = 36,
		TALENT_Reason = 37,
		TALENT_Luck = 38,
		TALENT_Initiative = 39,
		TALENT_InventoryAccess = 40,
		TALENT_AvoidDetection = 41,
		TALENT_AnimalEmpathy = 42,
		TALENT_Escapist = 43,
		TALENT_StandYourGround = 44,
		TALENT_SurpriseAttack = 45,
		TALENT_LightStep = 46,
		TALENT_ResurrectToFullHealth = 47,
		TALENT_Scientist = 48,
		TALENT_Raistlin = 49,
		TALENT_MrKnowItAll = 50,
		TALENT_WhatARush = 51,
		TALENT_FaroutDude = 52,
		TALENT_Leech = 53,
		TALENT_ElementalAffinity = 54,
		TALENT_FiveStarRestaurant = 55,
		TALENT_Bully = 56,
		TALENT_ElementalRanger = 57,
		TALENT_LightningRod = 58,
		TALENT_Politician = 59,
		TALENT_WeatherProof = 60,
		TALENT_LoneWolf = 61,
		TALENT_Zombie = 62,
		TALENT_Demon = 63,
		TALENT_IceKing = 64,
		TALENT_Courageous = 65,
		TALENT_GoldenMage = 66,
		TALENT_WalkItOff = 67,
		TALENT_FolkDancer = 68,
		TALENT_SpillNoBlood = 69,
		TALENT_Stench = 70,
		TALENT_Kickstarter = 71,
		TALENT_WarriorLoreNaturalArmor = 72,
		TALENT_WarriorLoreNaturalHealth = 73,
		TALENT_WarriorLoreNaturalResistance = 74,
		TALENT_RangerLoreArrowRecover = 75,
		TALENT_RangerLoreEvasionBonus = 76,
		TALENT_RangerLoreRangedAPBonus = 77,
		TALENT_RogueLoreDaggerAPBonus = 78,
		TALENT_RogueLoreDaggerBackStab = 79,
		TALENT_RogueLoreMovementBonus = 80,
		TALENT_RogueLoreHoldResistance = 81,
		TALENT_NoAttackOfOpportunity = 82,
		TALENT_WarriorLoreGrenadeRange = 83,
		TALENT_RogueLoreGrenadePrecision = 84,
		TALENT_WandCharge = 85,
		TALENT_DualWieldingDodging = 86,
		TALENT_Human_Inventive = 87,
		TALENT_Human_Civil = 88,
		TALENT_Elf_Lore = 89,
		TALENT_Elf_CorpseEating = 90,
		TALENT_Dwarf_Sturdy = 91,
		TALENT_Dwarf_Sneaking = 92,
		TALENT_Lizard_Resistance = 93,
		TALENT_Lizard_Persuasion = 94,
		TALENT_Perfectionist = 95,
		TALENT_Executioner = 96,
		TALENT_ViolentMagic = 97,
		TALENT_QuickStep = 98,
		TALENT_Quest_SpidersKiss_Str = 99,
		TALENT_Quest_SpidersKiss_Int = 100,
		TALENT_Quest_SpidersKiss_Per = 101,
		TALENT_Quest_SpidersKiss_Null = 102,
		TALENT_Memory = 103,
		TALENT_Quest_TradeSecrets = 104,
		TALENT_Quest_GhostTree = 105,
		TALENT_BeastMaster = 106,
		TALENT_LivingArmor = 107,
		TALENT_Torturer = 108,
		TALENT_Ambidextrous = 109,
		TALENT_Unstable = 110,
		TALENT_ResurrectExtraHealth = 111,
		TALENT_NaturalConductor = 112,
		TALENT_Quest_Rooted = 113,
		TALENT_PainDrinker = 114,
		TALENT_DeathfogResistant = 115,
		TALENT_Sourcerer = 116,
		TALENT_Rager = 117,
		TALENT_Elementalist = 118,
		TALENT_Sadist = 119,
		TALENT_Haymaker = 120,
		TALENT_Gladiator = 121,
		TALENT_Indomitable = 122,
		TALENT_WildMag = 123,
		TALENT_Jitterbug = 124,
		TALENT_Soulcatcher = 125,
		TALENT_MasterThief = 126,
		TALENT_GreedyVessel = 127,
		TALENT_MagicCycles = 128,
		TALENT_Max = TALENT_MagicCycles,
	};

	MAKE_ENUM_INFO(TalentType, 129);


	enum ESurfaceFlag : uint64_t
	{
		// --- BASE TYPE START
		SurfaceFlag_Fire = 0x1000000,
		SurfaceFlag_Water = 0x2000000,
		SurfaceFlag_Blood = 0x4000000,
		SurfaceFlag_Poison = 0x8000000,
		SurfaceFlag_Oil = 0x10000000,
		SurfaceFlag_Lava = 0x20000000,
		SurfaceFlag_Source = 0x40000000,
		SurfaceFlag_Web = 0x80000000,
		SurfaceFlag_Deepwater = 0x100000000,
		SurfaceFlag_Sulfurium = 0x200000000,
		// UNUSED = 0x400000000,
		// --- BASE TYPE END


		// --- CLOUD TYPE START
		SurfaceFlag_FireCloud = 0x800000000,
		SurfaceFlag_WaterCloud = 0x1000000000,
		SurfaceFlag_BloodCloud = 0x2000000000,
		SurfaceFlag_PoisonCloud = 0x4000000000,
		SurfaceFlag_SmokeCloud = 0x8000000000,
		SurfaceFlag_ExplosionCloud = 0x10000000000,
		SurfaceFlag_FrostCloud = 0x20000000000,
		SurfaceFlag_Deathfog = 0x40000000000,
		SurfaceFlag_ShockwaveCloud = 0x80000000000,
		// UNUSED = 0x100000000000,
		// UNUSED = 0x200000000000,
		// --- CLOUD TYPE END

		SurfaceFlag_Blessed = 0x400000000000,
		SurfaceFlag_Cursed = 0x800000000000,
		SurfaceFlag_Purified = 0x1000000000000,
		// SurfaceFlag_??? = 0x2000000000000,

		// --- SURFACE ADJ START
		SurfaceFlag_CloudBlessed = 0x4000000000000,
		SurfaceFlag_CloudCursed = 0x8000000000000,
		SurfaceFlag_CloudPurified = 0x10000000000000,
		// UNUSED = 0x20000000000000,
		// --- SURFACE ADJ END

		// --- GROUND MOD START
		SurfaceFlag_Electrified = 0x40000000000000,
		SurfaceFlag_Frozen = 0x80000000000000,
		SurfaceFlag_CloudElectrified = 0x100000000000000,
		// --- GROUND MOD END

		// --- CLOUD MOD START
		SurfaceFlag_ElectrifiedDecay = 0x200000000000000,
		SurfaceFlag_SomeDecay = 0x400000000000000,
		// UNUSED = 0x800000000000000,
		// --- CLOUD MOD END
	};
}
