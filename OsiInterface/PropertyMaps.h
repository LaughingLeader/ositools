#pragma once

#include "CustomFunctions.h"
#include "Functions/FunctionLibrary.h"
#include "PropertyMap.h"

namespace dse
{
	struct GameObjectTemplate;
	struct EoCGameObjectTemplate;
	struct CharacterTemplate;
	struct ItemTemplate;
	struct ProjectileTemplate;
	struct CombatComponentTemplate;

	namespace esv
	{
		struct Surface;
	}

	extern PropertyMap<esv::Status, void> gStatusPropertyMap;
	extern PropertyMap<esv::StatusConsume, esv::Status> gStatusConsumePropertyMap;
	extern PropertyMap<esv::StatusHit, esv::Status> gStatusHitPropertyMap;
	extern PropertyMap<esv::StatusHeal, esv::Status> gStatusHealPropertyMap;
	extern PropertyMap<esv::StatusHealing, esv::StatusConsume> gStatusHealingPropertyMap;
	extern PropertyMap<HitDamageInfo, void> gHitDamageInfoPropertyMap;
	extern PropertyMap<esv::DamageHelpers, void> gDamageHelpersPropertyMap;
	extern PropertyMap<esv::ShootProjectileHelper, void> gShootProjectileHelperPropertyMap;
	extern PropertyMap<eoc::ItemDefinition, void> gEoCItemDefinitionPropertyMap;
	extern PropertyMap<CDivinityStats_Equipment_Attributes, void> gEquipmentAttributesPropertyMap;
	extern PropertyMap<CDivinityStats_Equipment_Attributes_Weapon, CDivinityStats_Equipment_Attributes> gEquipmentAttributesWeaponPropertyMap;
	extern PropertyMap<CDivinityStats_Equipment_Attributes_Armor, CDivinityStats_Equipment_Attributes> gEquipmentAttributesArmorPropertyMap;
	extern PropertyMap<CDivinityStats_Equipment_Attributes_Shield, CDivinityStats_Equipment_Attributes> gEquipmentAttributesShieldPropertyMap;
	extern PropertyMap<CharacterDynamicStat, void> gCharacterDynamicStatPropertyMap;
	extern PropertyMap<CDivinityStats_Character, void> gCharacterStatsPropertyMap;
	extern PropertyMap<CDivinityStats_Item, void> gItemStatsPropertyMap;
	extern PropertyMap<eoc::PlayerCustomData, void> gPlayerCustomDataPropertyMap;
	extern PropertyMap<esv::Character, void> gCharacterPropertyMap;
	extern PropertyMap<esv::Item, void> gItemPropertyMap;
	extern PropertyMap<esv::Projectile, void> gProjectilePropertyMap;
	extern PropertyMap<esv::Surface, void> gEsvSurfacePropertyMap;

	extern PropertyMap<esv::SurfaceAction, void> gEsvSurfaceActionPropertyMap;
	extern PropertyMap<esv::TransformSurfaceAction, esv::SurfaceAction> gEsvTransformSurfaceActionPropertyMap;
	extern PropertyMap<esv::CreateSurfaceActionBase, esv::SurfaceAction> gEsvCreateSurfaceActionBasePropertyMap;
	extern PropertyMap<esv::CreateSurfaceAction, esv::CreateSurfaceActionBase> gEsvCreateSurfaceActionPropertyMap;
	extern PropertyMap<esv::ChangeSurfaceOnPathAction, esv::CreateSurfaceActionBase> gEsvChangeSurfaceOnPathActionPropertyMap;
	extern PropertyMap<esv::CreatePuddleAction, esv::CreateSurfaceActionBase> gEsvCreatePuddleActionPropertyMap;
	extern PropertyMap<esv::ExtinguishFireAction, esv::CreateSurfaceActionBase> gEsvExtinguishFireActionPropertyMap;
	extern PropertyMap<esv::RectangleSurfaceAction, esv::CreateSurfaceActionBase> gEsvRectangleSurfaceActionPropertyMap;
	extern PropertyMap<esv::PolygonSurfaceAction, esv::CreateSurfaceActionBase> gEsvPolygonSurfaceActionPropertyMap;
	extern PropertyMap<esv::SwapSurfaceAction, esv::CreateSurfaceActionBase> gEsvSwapSurfaceActionPropertyMap;
	extern PropertyMap<esv::ZoneAction, esv::CreateSurfaceActionBase> gEsvZoneActionPropertyMap;


	extern PropertyMap<esv::ASAttack, void> gASAttackPropertyMap;
	extern PropertyMap<esv::ASPrepareSkill, void> gASPrepareSkillPropertyMap;
	extern PropertyMap<esv::SkillState, void> gSkillStatePropertyMap;

	extern PropertyMap<ecl::Character, void> gEclCharacterPropertyMap;
	extern PropertyMap<ecl::Item, void> gEclItemPropertyMap;
	extern PropertyMap<ecl::Status, void> gEclStatusPropertyMap;

	extern PropertyMap<GameObjectTemplate, void> gGameObjectTemplatePropertyMap;
	extern PropertyMap<EoCGameObjectTemplate, GameObjectTemplate> gEoCGameObjectTemplatePropertyMap;
	extern PropertyMap<CharacterTemplate, EoCGameObjectTemplate> gCharacterTemplatePropertyMap;
	extern PropertyMap<ItemTemplate, EoCGameObjectTemplate> gItemTemplatePropertyMap;
	extern PropertyMap<ProjectileTemplate, EoCGameObjectTemplate> gProjectileTemplatePropertyMap;
	extern PropertyMap<CombatComponentTemplate, void> gCombatComponentTemplatePropertyMap;

	void InitPropertyMaps();

	enum class OsiPropertyMapType
	{
		Integer,
		Integer64,
		Real,
		String,
		GuidStringHandle,
		Vector3
	};


	bool OsirisPropertyMapSetRaw(PropertyMapBase const & propertyMap, void * obj,
		OsiArgumentDesc const & args, uint32_t firstArg, OsiPropertyMapType type, bool throwError = true);
	bool OsirisPropertyMapGetRaw(PropertyMapBase const & propertyMap, void * obj,
		OsiArgumentDesc & args, uint32_t firstArg, OsiPropertyMapType type, bool throwError = true);

	template <class T>
	bool OsirisPropertyMapGet(PropertyMapInterface<T> const & propertyMap, T * obj,
		OsiArgumentDesc & args, uint32_t firstArg, OsiPropertyMapType type, bool throwError = true)
	{
		return OsirisPropertyMapGetRaw(propertyMap, obj, args, firstArg, type, throwError);
	}

	template <class T>
	bool OsirisPropertyMapSet(PropertyMapInterface<T> const & propertyMap, T * obj,
		OsiArgumentDesc const & args, uint32_t firstArg, OsiPropertyMapType type, bool throwError = true)
	{
		return OsirisPropertyMapSetRaw(propertyMap, obj, args, firstArg, type, throwError);
	}

	bool LuaPropertyMapGet(lua_State * L, PropertyMapBase const & propertyMap, void * obj,
		char const * propertyName, bool throwError);
	bool LuaPropertyMapGet(lua_State* L, PropertyMapBase const& propertyMap, void* obj,
		FixedString const& propertyName, bool throwError);
	bool LuaPropertyMapSet(lua_State * L, int index, PropertyMapBase const & propertyMap,
		void * obj, char const * propertyName, bool throwError);
}