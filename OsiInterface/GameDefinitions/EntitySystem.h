#pragma once

#include "BaseTypes.h"
#include "Enumerations.h"
#include "Net.h"
#include "Module.h"
#include "Stats.h"

namespace dse
{

#pragma pack(push, 1)
	template <class T, uint32_t TypeIndex>
	struct NetworkObjectFactory : public ObjectFactory<T, TypeIndex>
	{
		Map<FixedString, T *> ObjectMap;
		uint32_t _Pad2;
		Map<uint16_t, T *> NetIds;
		uint32_t _Pad3;
		Map<uint16_t, void *> FreeNetIdMap;
		uint32_t _Pad4;
		Set<uint32_t> Unknown4;
		uint32_t NumFreeNetIDs;
		uint8_t _Pad42[4];
		Array<uint16_t> NetIdSalts;
		uint16_t NextFreeNetIndex;
		bool CanCreateNetIDs;
		uint8_t _Pad5[5];

		T* FindByNetId(NetId netId) const
		{
			if (!netId) return nullptr;

			auto index = netId.GetIndex();
			if (index >= NetIdSalts.Size
				|| netId.GetSalt() != NetIdSalts[index]) {
				return nullptr;
			}

			auto object = NetIds.Find(index);
			if (object != nullptr) {
				return *object;
			} else {
				return nullptr;
			}
		}
	};

	struct ComponentTypeEntry
	{
		// todo
		Component * component;
		uint64_t dummy[31];
	};

	struct ComponentLayout
	{
		struct LayoutEntry
		{
			uint64_t unkn1;
			ComponentHandle Handle;
		};

		Array<LayoutEntry> Entries;
	};

	struct SystemTypeEntry
	{
		void * System;
		int64_t Unkn1;
		uint32_t Unkn2;
		uint8_t _Pad[4];
		void * PrimitiveSetVMT;
		PrimitiveSet<uint64_t> PSet;
		uint8_t Unkn3;
		uint8_t _Pad2[7];
	};

	struct EntityEntry
	{
		void * VMT;
		ComponentLayout Layout;
	};

	namespace eoc
	{
		struct CombatComponent;
		struct CustomStatsComponent;
	}
	
	struct BaseComponentProcessingSystem
	{
		void * VMT;
		void * field_8;
	};

	template <class TComponentType>
	struct EntityWorldBase : public ProtectedGameObject<EntityWorldBase<TComponentType>>
	{
		void * VMT;
		Array<EntityEntry *> EntityEntries;
		Array<uint32_t> EntitySalts;
		uint64_t Unkn1[4];
		PrimitiveSet<EntityEntry *> EntityEntries2;
		uint64_t Unkn2;
		uint8_t Unkn3;
		uint8_t _Pad3[3];
		uint32_t Unkn4;
		Array<ComponentTypeEntry> Components;
		ObjectSet<void *> KeepAlives; // ObjectSet<ObjectHandleRefMap<ComponentKeepAliveDesc>>
		Array<SystemTypeEntry> SystemTypes;
		Array<void *> EventTypes; // Array<EventTypeEntry>
		void * EntityWorldManager;
		void * SystemTypeEntry_PrimSetVMT;
		PrimitiveSet<SystemTypeEntry> SystemTypes2;
		uint64_t Unkn5;
		ObjectSet<void *> Funcs; // ObjectSet<function>
		RefMap<FixedString, int> RefMap; // ???


		void* GetComponent(TComponentType type, ObjectHandle componentHandle, bool logError = true)
		{
			if (this == nullptr) {
				OsiError("Tried to find component on null EntityWorld!");
				return nullptr;
			}

			if (!componentHandle) {
				return nullptr;
			}

			if ((uint32_t)type >= Components.Size) {
				OsiError("Component type index " << (uint32_t)type << " too large!");
				return nullptr;
			}

			auto componentMgr = Components[(uint32_t)type].component;
			if (componentMgr == nullptr) {
				OsiError("Component type " << (uint32_t)type << " not bound!");
				return nullptr;
			}

			return componentMgr->FindComponentByHandle(&componentHandle);
		}

		void* GetComponent(TComponentType componentType, char const* nameGuid, bool logError = true)
		{
			if (this == nullptr) {
				OsiError("Tried to find component on null EntityWorld!");
				return nullptr;
			}

			if (nameGuid == nullptr) {
				OsiError("Attempted to look up component with null name!");
				return nullptr;
			}

			auto fs = NameGuidToFixedString(nameGuid);
			if (!fs) {
				OsiError("Could not map GUID '" << nameGuid << "' to FixedString");
				return nullptr;
			}

			auto component = Components[(uint32_t)componentType].component->FindComponentByGuid(&fs);
			if (component != nullptr) {
				return component;
			}
			else {
				if (logError) {
					OsiError("No " << ComponentTypeToName(componentType) << " component found with GUID '" << nameGuid << "'");
				}
				return nullptr;
			}
		}

		void* GetComponent(TComponentType type, NetId netId, bool logError = true)
		{
			if (this == nullptr) {
				OsiError("Tried to find component on null EntityWorld!");
				return nullptr;
			}

			if (!netId) {
				return nullptr;
			}

			if ((uint32_t)type >= Components.Size) {
				OsiError("Component type index " << (uint32_t)type << " too large!");
				return nullptr;
			}

			auto componentMgr = Components[(uint32_t)type].component;
			if (componentMgr == nullptr) {
				OsiError("Component type " << (uint32_t)type << " not bound!");
				return nullptr;
			}

			return componentMgr->FindComponentByNetId(netId, true);
		}

		void* GetComponentByEntityHandle(TComponentType type, ObjectHandle entityHandle)
		{
			if (this == nullptr) {
				OsiError("Tried to find component on null EntityWorld!");
				return nullptr;
			}

			if (entityHandle.GetType() != 0) {
				OsiError("Entity handle has invalid type " << entityHandle.GetType());
				return nullptr;
			}

			auto index = entityHandle.GetIndex();
			if (index >= EntityEntries.Size) {
				OsiError("Entity index " << index << " too large!");
				return nullptr;
			}

			auto salt = entityHandle.GetSalt();
			if (salt != EntitySalts[index]) {
				OsiError("Salt mismatch on index " << index << "; " << salt << " != " << EntitySalts[index]);
				return nullptr;
			}

			auto entity = EntityEntries[index];
			if ((uint32_t)type >= entity->Layout.Entries.Size) {
				OsiError("Entity " << index << " has no component slot for " << (uint32_t)type);
				return nullptr;
			}

			auto const& layoutEntry = entity->Layout.Entries[(uint32_t)type];
			if (!layoutEntry.Handle.IsValid()) {
				OsiError("Entity " << index << " has no component bound to slot " << (uint32_t)type);
				return nullptr;
			}

			ObjectHandle componentHandle{ layoutEntry.Handle.Handle };
			auto componentMgr = Components[(uint32_t)type].component;
			return componentMgr->FindComponentByHandle(&componentHandle);
		}

		std::string ComponentTypeToName(TComponentType type)
		{
			auto label = EnumInfo<TComponentType>::Find(type);
			if (label) {
				return *label;
			}
			else {
				return std::string("<Type ") + std::to_string((uint32_t)type) + ">";
			}
		}
	};

	struct IGameObject : public ProtectedGameObject<IGameObject>
	{
		virtual ~IGameObject() = 0;
		virtual void HandleTextKeyEvent() = 0;
		virtual uint64_t Ret5() = 0;
		virtual void SetObjectHandle(ObjectHandle Handle) = 0;
		virtual void GetObjectHandle(ObjectHandle& Handle) const = 0;
		virtual void SetGuid(FixedString const& fs) = 0;
		virtual FixedString* GetGuid() const = 0;
		virtual void SetNetID(NetId netId) = 0;
		virtual void GetNetID(NetId& netId) const = 0;
		virtual void SetCurrentTemplate(void* esvTemplate) = 0;
		virtual void* GetCurrentTemplate() const = 0;
		virtual void SetGlobal(bool isGlobal) = 0;
		virtual bool IsGlobal() const = 0;
		virtual uint32_t GetComponentType() = 0;
		virtual void* GetEntityObjectByHandle(ObjectHandle handle) = 0;
		virtual STDWString* GetName() = 0;
		virtual void SetFlags(uint64_t flag) = 0;
		virtual void ClearFlags(uint64_t flag) = 0;
		virtual bool HasFlag(uint64_t flag) const = 0;
		virtual void SetAiColliding(bool colliding) = 0;
		virtual void GetTags(ObjectSet<FixedString> & tags) = 0;
		virtual bool IsTagged(FixedString & tag) = 0;
		virtual Vector3 const* GetTranslate() const = 0;
		virtual glm::mat3 const* GetRotation() const = 0;
		virtual float GetScale() const = 0;
		virtual void SetTranslate(Vector3 const& translate) = 0;
		virtual void SetRotation(glm::mat3 const& rotate) = 0;
		virtual void SetScale(float scale) = 0;
		virtual Vector3 const* GetVelocity() = 0;
		virtual void SetVelocity(Vector3 const& translate) = 0;
		virtual void LoadVisual() = 0;
		virtual void UnloadVisual() = 0;
		virtual void ReloadVisual() = 0;
		virtual void GetVisual() = 0;
		virtual void GetPhysics() = 0;
		virtual void SetPhysics() = 0;
		virtual void LoadPhysics() = 0;
		virtual void UnloadPhysics() = 0;
		virtual void ReloadPhysics() = 0;
		virtual void GetHeight() = 0;
		virtual void GetParentUUID() = 0;
		virtual FixedString* GetCurrentLevel() const = 0;
		virtual void SetCurrentLevel(FixedString const& level) = 0;

		BaseComponent Base;
		FixedString MyGuid;

		NetId NetID;
		uint32_t _Pad1;
		glm::vec3 WorldPos; // Saved
		uint32_t _Pad2;
		uint64_t Flags; // Saved
		uint32_t U2;
		uint32_t _Pad3;
		FixedString CurrentLevel; // Saved
	};

	struct IEocClientObject : public IGameObject
	{
		virtual void * GetAi() = 0;
		virtual void LoadAi() = 0;
		virtual void UnloadAi() = 0;
		virtual void Unknown0() = 0;
		virtual void Unknown1() = 0;
		virtual void Unknown2() = 0;
		virtual void Unknown3() = 0;
		virtual FixedString * Unknown4() = 0;
		virtual bool Unknown5() = 0;
		virtual TranslatedString* GetDisplayName(TranslatedString* name) = 0;
		virtual float Unknown6() = 0;
		virtual void SavegameVisit() = 0;
		virtual void SetLight(FixedString *) = 0;
		virtual void * GetLight() = 0;
		virtual void RemoveLight() = 0;
		virtual FixedString * GetPlayerRace(bool returnPolymorph, bool excludeUninitialized) = 0;
		virtual FixedString* GetPlayerOrigin(bool returnPolymorph, bool excludeUninitialized) = 0;
	};

	struct IEoCServerObject : public IGameObject
	{
		virtual void AddPeer() = 0;
		virtual void UNK1() = 0;
		virtual void UNK2() = 0;
		virtual void UNK3() = 0;
		virtual void GetAi() = 0;
		virtual void LoadAi() = 0;
		virtual void UnloadAi() = 0;
		virtual TranslatedString* GetDisplayName(TranslatedString* name) = 0;
		virtual void SavegameVisit() = 0;
		virtual void GetEntityNetworkId() = 0;
		virtual void SetTemplate() = 0;
		virtual void SetOriginalTemplate_M() = 0;
	};

	namespace esv
	{
		struct CustomStatDefinitionComponent;
		struct CustomStatSystem;
		struct NetComponent;
		struct Item;
		struct Character;
		struct Inventory;
		struct TurnManager;

		struct EntityWorld : public EntityWorldBase<ComponentType>
		{
			inline CustomStatDefinitionComponent* GetCustomStatDefinitionComponent(ObjectHandle componentHandle)
			{
				auto component = GetComponent(ComponentType::CustomStatDefinition, componentHandle);
				if (component != nullptr) {
					return (CustomStatDefinitionComponent*)((uint8_t*)component - 80);
				}
				else {
					return nullptr;
				}
			}

			inline Character* GetCharacterComponentByEntityHandle(ObjectHandle entityHandle)
			{
				auto ptr = GetComponentByEntityHandle(ComponentType::Character, entityHandle);
				if (ptr != nullptr) {
					return (Character*)((uint8_t*)ptr - 8);
				}
				else {
					return nullptr;
				}
			}

			inline Item* GetItemComponentByEntityHandle(ObjectHandle entityHandle)
			{
				auto ptr = GetComponentByEntityHandle(ComponentType::Item, entityHandle);
				if (ptr != nullptr) {
					return (Item*)((uint8_t*)ptr - 8);
				}
				else {
					return nullptr;
				}
			}

			inline eoc::CombatComponent* GetCombatComponentByEntityHandle(ObjectHandle entityHandle)
			{
				return (eoc::CombatComponent*)GetComponentByEntityHandle(ComponentType::Combat, entityHandle);
			}

			inline eoc::CustomStatsComponent* GetCustomStatsComponentByEntityHandle(ObjectHandle entityHandle)
			{
				return (eoc::CustomStatsComponent*)GetComponentByEntityHandle(ComponentType::CustomStats, entityHandle);
			}

			inline NetComponent* GetNetComponentByEntityHandle(ObjectHandle entityHandle)
			{
				return (NetComponent*)GetComponentByEntityHandle(ComponentType::Net, entityHandle);
			}

			inline CustomStatSystem* GetCustomStatSystem()
			{
				auto sys = SystemTypes.Buf[(uint32_t)SystemType::CustomStat].System;
				return (CustomStatSystem*)((uint8_t*)sys - 0x18);
			}

			inline TurnManager* GetTurnManager()
			{
				auto const& system = SystemTypes[(unsigned)SystemType::TurnManager];
				return (TurnManager*)((uint8_t*)system.System - 8);
			}

			inline Character* GetCharacter(char const* nameGuid, bool logError = true)
			{
				auto component = GetComponent(ComponentType::Character, nameGuid, logError);
				if (component != nullptr) {
					return (Character*)((uint8_t*)component - 8);
				}
				else {
					return nullptr;
				}
			}

			inline Character* GetCharacter(ObjectHandle handle, bool logError = true)
			{
				auto component = GetComponent(ComponentType::Character, handle, logError);
				if (component != nullptr) {
					return (Character*)((uint8_t*)component - 8);
				}
				else {
					return nullptr;
				}
			}

			inline Character* GetCharacter(NetId netId, bool logError = true)
			{
				auto component = GetComponent(ComponentType::Character, netId, logError);
				if (component != nullptr) {
					return (Character*)((uint8_t*)component - 8);
				}
				else {
					return nullptr;
				}
			}

			inline Item* GetItem(char const* nameGuid, bool logError = true)
			{
				auto component = GetComponent(ComponentType::Item, nameGuid, logError);
				if (component != nullptr) {
					return (Item*)((uint8_t*)component - 8);
				}
				else {
					return nullptr;
				}
			}

			inline Item* GetItem(ObjectHandle handle, bool logError = true)
			{
				auto component = GetComponent(ComponentType::Item, handle, logError);
				if (component != nullptr) {
					return (Item*)((uint8_t*)component - 8);
				}
				else {
					return nullptr;
				}
			}

			IEoCServerObject* GetGameObject(char const* nameGuid, bool logError = true);
			IEoCServerObject* GetGameObject(ObjectHandle handle, bool logError = true);
		};

		struct CharacterFactory : public NetworkObjectFactory<esv::Character, (uint32_t)ObjectType::Character>
		{
			void* VMT2;
			void* VMT3;
			Map<FixedString, void*> FSMap_ReloadComponent;
			uint32_t _Pad4;
			EntityWorld* Entities;
			uint64_t Unkn8[2];
		};

		struct ItemFactory : public NetworkObjectFactory<esv::Item, (uint32_t)ObjectType::Item>
		{
			void* VMT2;
			void* VMT3;
			Map<FixedString, void*> FSMap_ReloadComponent;
			uint32_t _Pad4;
			EntityWorld* Entities;
			uint64_t Unkn8[2];
		};

		struct InventoryFactory : public NetworkObjectFactory<esv::Inventory, (uint32_t)ObjectType::Inventory>
		{
			// TODO
		};

		struct GameStateMachine : public ProtectedGameObject<GameStateMachine>
		{
			uint8_t Unknown;
			uint8_t _Pad1[7];
			void * CurrentState;
			GameState State;
			uint8_t _Pad2[4];
			void ** TargetStates;
			uint32_t TargetStateBufSize;
			uint32_t NumTargetStates;
			uint32_t ReadStateIdx;
			uint32_t WriteStateIdx;
		};

		struct EoCServer
		{
			bool Unknown1;
			uint8_t _Pad1[7];
			uint64_t EoC;
			uint64_t GameTime_M;
			ScratchBuffer ScratchBuffer1;
			uint8_t _Pad2[4];
			ScratchBuffer ScratchBuffer2;
			uint8_t _Pad3[4];
			FixedString FS1;
			FixedString FS2;
			FixedString FS3;
			FixedString FSGUID4;
			GameStateMachine * StateMachine;
			net::GameServer * GameServer;
			void * field_88;
			void * GlobalRandom;
			void * ItemCombinationManager;
			void * CombineManager;
			ModManager * ModManagerServer;
			bool ShutDown;
			uint8_t _Pad4[7];
			void * EntityWorldManager;
			EntityWorld * EntityWorld;
			void * EntityManager;
			void * ArenaManager;
			void * GameMasterLobbyManager;
			void * LobbyManagerOrigins;
			bool field_E8;
		};

		EntityWorld* GetEntityWorld();
	}

	namespace ecl
	{
		struct Item;
		struct Character;

		struct EntityWorld : public EntityWorldBase<ComponentType>
		{
			inline Character* GetCharacter(ObjectHandle handle, bool logError = true)
			{
				auto component = GetComponent(ComponentType::Character, handle, logError);
				if (component != nullptr) {
					return (Character*)((uint8_t*)component - 8);
				}
				else {
					return nullptr;
				}
			}

			inline Character* GetCharacter(NetId netId, bool logError = true)
			{
				auto component = GetComponent(ComponentType::Character, netId, logError);
				if (component != nullptr) {
					return (Character*)((uint8_t*)component - 8);
				}
				else {
					return nullptr;
				}
			}

			inline Item* GetItem(char const* nameGuid, bool logError = true)
			{
				auto component = GetComponent(ComponentType::Item, nameGuid, logError);
				if (component != nullptr) {
					return (Item*)((uint8_t*)component - 8);
				}
				else {
					return nullptr;
				}
			}

			inline Item* GetItem(ObjectHandle handle, bool logError = true)
			{
				auto component = GetComponent(ComponentType::Item, handle, logError);
				if (component != nullptr) {
					return (Item*)((uint8_t*)component - 8);
				}
				else {
					return nullptr;
				}
			}

			inline Item* GetItem(NetId netId, bool logError = true)
			{
				auto component = GetComponent(ComponentType::Item, netId, logError);
				if (component != nullptr) {
					return (Item*)((uint8_t*)component - 8);
				}
				else {
					return nullptr;
				}
			}

			inline eoc::CustomStatsComponent* GetCustomStatsComponentByEntityHandle(ObjectHandle entityHandle)
			{
				return (eoc::CustomStatsComponent*)GetComponentByEntityHandle(ComponentType::CustomStats, entityHandle);
			}
		};

		struct GameStateMachine : public ProtectedGameObject<GameStateMachine>
		{
			uint8_t Unknown;
			uint8_t _Pad1[7];
			void* CurrentState;
			GameState State;
		};

		struct EoCClient : public ProtectedGameObject<EoCClient>
		{
			void* VMT;
			void* GameEventManagerVMT;
			uint64_t field_10;
			void* NetEventManagerVMT;
			uint64_t field_20;
			void* VMT2;
			void* VMT3;
			void* EoC;
			GameStateMachine** GameStateMachine;
			net::Client* GameClient;
			uint64_t field_50;
			uint64_t field_58;
			uint64_t field_60;
			FixedString FS1;
			FixedString LevelName;
			FixedString SomeGUID;
			FixedString FS_CurrentSaveGameGUID;
			bool IsLoading;
			bool IsLoading2;
			uint8_t _Pad1[6];
			void* PrimitiveSetVMT;
			PrimitiveSet<int> PrimitiveSetUnkn;
			uint64_t field_A8;
			uint16_t field_B0;
			uint8_t _Pad2[6];
			void* Random;
			void* ItemCombinationManager;
			char field_C8;
			uint8_t _Pad3[7];
			uint64_t ScratchStr[4];
			ScratchBuffer ScratchBuf;
			uint8_t _Pad4[4];
			ModManager* ModManager;
			void* ChatManager;
			STDWString WStr_CurrentHost_M;
			uint64_t SomeObject[16];
			int field_1C0;
			uint8_t _Pad5[4];
			uint64_t field_1C8[2];
			void* EntityWorldManager;
			EntityWorld* EntityWorld;
			void* EntityManager;
		};

		typedef void (*EoCClient__HandleError)(void* self, STDWString const* message, bool exitGame, STDWString const* a4);
		typedef void (*GameStateThreaded__GameStateWorker__DoWork)(void* self);
		typedef void (*GameStateEventManager__ExecuteGameStateChangedEvent)(void* self, GameState fromState, GameState toState);

		EntityWorld* GetEntityWorld();
	}
#pragma pack(pop)
}