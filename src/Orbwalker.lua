--[[
    API:

    _G.SDK.DAMAGE_TYPE_PHYSICAL
    _G.SDK.DAMAGE_TYPE_MAGICAL
    _G.SDK.DAMAGE_TYPE_TRUE
    _G.SDK.ORBWALKER_MODE_NONE
    _G.SDK.ORBWALKER_MODE_COMBO
    _G.SDK.ORBWALKER_MODE_HARASS
    _G.SDK.ORBWALKER_MODE_LANECLEAR
    _G.SDK.ORBWALKER_MODE_JUNGLECLEAR
    _G.SDK.ORBWALKER_MODE_LASTHIT
    _G.SDK.ORBWALKER_MODE_FLEE

    _G.SDK.Orbwalker
        .ForceTarget -- unit
        .ForceMovement -- Vector
        .Modes[mode: enum] -- if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then DoCombo() end
        :CanMove(unit or myHero) -- returns a boolean
        :CanAttack(unit or myHero) -- returns a boolean
        :GetTarget() -- returns a unit
        :ShouldWait() -- returns a boolean
        :OnPreAttack(function({ Process: boolean, Target: unit }) end) -- Suscribe to event
        :OnPreMovement(function({ Process: boolean, Target: Vector }) end) -- Suscribe to event
        :OnAttack(function() end) -- Suscribe to event
        :OnPostAttack(function() end) -- Suscribe to event
        :RegisterMenuKey(mode: enum, key: menu) -- _G.SDK.Orbwalker:RegisterMenuKey(_G.SDK.ORBWALKER_MODE_COMBO, Menu.Keys.Combo); Only needed for extra keys

    _G.SDK.TargetSelector
        :GetTarget(enemies: table, damageType: enum) -- returns a unit or nil
        :GetTarget(range: number, damageType: enum, from: Vector or myHero.pos) -- local target = _G.SDK.TargetSelector:GetTarget(1000, _G.SDK.DAMAGE_TYPE_PHYSICAL);

    _G.SDK.ObjectManager
        :GetMinions(range: number or math.huge)
        :GetAllyMinions(range: number or math.huge)
        :GetEnemyMinions(range: number or math.huge)
        :GetOtherMinions(range: number or math.huge)
        :GetOtherAllyMinions(range: number or math.huge)
        :GetOtherEnemyMinions(range: number or math.huge)
        :GetMonsters(range: number or math.huge)
        :GetHeroes(range: number or math.huge)
        :GetAllyHeroes(range: number or math.huge)
        :GetEnemyHeroes(range: number or math.huge)
        :GetTurrets(range: number or math.huge)
        :GetAllyTurrets(range: number or math.huge)
        :GetEnemyTurrets(range: number or math.huge)

    _G.SDK.HealthPrediction
        :GetPrediction(unit, time)
]]

if _G.SDK then
	return;
end

_G.SDK = {
	DAMAGE_TYPE_PHYSICAL			= 0,
	DAMAGE_TYPE_MAGICAL				= 1,
	DAMAGE_TYPE_TRUE				= 2,
	ORBWALKER_MODE_NONE				= -1,
	ORBWALKER_MODE_COMBO			= 0,
	ORBWALKER_MODE_HARASS			= 1,
	ORBWALKER_MODE_LANECLEAR		= 2,
	ORBWALKER_MODE_JUNGLECLEAR		= 3,
	ORBWALKER_MODE_LASTHIT			= 4,
	ORBWALKER_MODE_FLEE				= 5,
	Linq 							= nil,
	ObjectManager 					= nil,
	Utilities 						= nil,
	BuffManager 					= nil,
	ItemManager 					= nil,
	Damage 							= nil,
	TargetSelector 					= nil,
	HealthPrediction 				= nil,
	Orbwalker 						= nil,
};
local LocalVector					= Vector;
local LocalCallbackAdd				= Callback.Add;
local LocalCallbackDel				= Callback.Del;
local LocalDrawColor				= Draw.Color;
local LocalDrawCircle				= Draw.Circle;
local LocalDrawText					= Draw.Text;
local LocalControlIsKeyDown			= Control.IsKeyDown;
local LocalControlMouseEvent		= Control.mouse_event;
local LocalControlSetCursorPos		= Control.SetCursorPos;
local LocalControlKeyUp				= Control.KeyUp;
local LocalControlKeyDown			= Control.KeyDown;
local LocalGameLatency				= Game.Latency;
local LocalGameTimer				= Game.Timer;
local LocalGameHeroCount 			= Game.HeroCount;
local LocalGameHero 				= Game.Hero;
local LocalGameMinionCount 			= Game.MinionCount;
local LocalGameMinion 				= Game.Minion;
local LocalGameTurretCount 			= Game.TurretCount;
local LocalGameTurret 				= Game.Turret;
local LocalGameWardCount 			= Game.WardCount;
local LocalGameWard 				= Game.Ward;
local LocalGameObjectCount 			= Game.ObjectCount;
local LocalGameObject				= Game.Object;
local LocalGameIsChatOpen			= Game.IsChatOpen;
local LocalGameIsOnTop				= Game.IsOnTop;
local STATE_UNKNOWN					= STATE_UNKNOWN;
local STATE_ATTACK					= STATE_ATTACK;
local STATE_WINDUP					= STATE_WINDUP;
local STATE_WINDDOWN				= STATE_WINDDOWN;
local ITEM_1						= ITEM_1;
local ITEM_2						= ITEM_2;
local ITEM_3						= ITEM_3;
local ITEM_4						= ITEM_4;
local ITEM_5						= ITEM_5;
local ITEM_6						= ITEM_6;
local ITEM_7						= ITEM_7;
local _Q							= _Q;
local _W							= _W;
local _E							= _E;
local _R							= _R;
local MOUSEEVENTF_LEFTDOWN			= MOUSEEVENTF_LEFTDOWN;
local MOUSEEVENTF_LEFTUP			= MOUSEEVENTF_LEFTUP;
local MOUSEEVENTF_RIGHTDOWN			= MOUSEEVENTF_RIGHTDOWN;
local MOUSEEVENTF_RIGHTUP			= MOUSEEVENTF_RIGHTUP;
local KEY_UP						= KEY_UP;
local KEY_DOWN						= KEY_DOWN;
local Obj_AI_SpawnPoint				= Obj_AI_SpawnPoint;
local Obj_AI_Camp					= Obj_AI_Camp;
local Obj_AI_Barracks				= Obj_AI_Barracks;
local Obj_AI_Hero					= Obj_AI_Hero;
local Obj_AI_Minion					= Obj_AI_Minion;
local Obj_AI_Turret					= Obj_AI_Turret;
local Obj_AI_LineMissle				= Obj_AI_LineMissle;
local Obj_AI_Shop					= Obj_AI_Shop;
local Obj_HQ 						= "obj_HQ";
local Obj_GeneralParticleEmitter	= "obj_GeneralParticleEmitter";

local LocalTableInsert				= table.insert;
local LocalTableSort				= table.sort;
local LocalTableRemove				= table.remove;

local tonumber						= tonumber;
local ipairs						= ipairs;
local pairs							= pairs;

local LocalMathCeil					= math.ceil;
local LocalMathMax					= math.max;
local LocalMathMin					= math.min;
local LocalMathSqrt					= math.sqrt;
local LocalMathHuge					= math.huge;
local LocalMathAbs					= math.abs;

local EPSILON						= 1E-12;

-- _G Globals
local COLOR_LIGHT_GREEN				= LocalDrawColor(255, 144, 238, 144);
local COLOR_ORANGE_RED				= LocalDrawColor(255, 255, 69, 0);
local COLOR_WHITE					= LocalDrawColor(255, 255, 255, 255);
local COLOR_BLACK					= LocalDrawColor(255, 0, 0, 0);
local COLOR_RED						= LocalDrawColor(255, 255, 0, 0);

local DAMAGE_TYPE_PHYSICAL			= _G.SDK.DAMAGE_TYPE_PHYSICAL;
local DAMAGE_TYPE_MAGICAL			= _G.SDK.DAMAGE_TYPE_MAGICAL;
local DAMAGE_TYPE_TRUE				= _G.SDK.DAMAGE_TYPE_TRUE;

local TARGET_SELECTOR_MODE_AUTO							= 1;
local TARGET_SELECTOR_MODE_MOST_STACK					= 2;
local TARGET_SELECTOR_MODE_MOST_ATTACK_DAMAGE			= 3;
local TARGET_SELECTOR_MODE_MOST_MAGIC_DAMAGE			= 4;
local TARGET_SELECTOR_MODE_LEAST_HEALTH					= 5;
local TARGET_SELECTOR_MODE_CLOSEST						= 6;
local TARGET_SELECTOR_MODE_HIGHEST_PRIORITY				= 7;
local TARGET_SELECTOR_MODE_LESS_ATTACK					= 8;
local TARGET_SELECTOR_MODE_LESS_CAST					= 9;
local TARGET_SELECTOR_MODE_NEAR_MOUSE					= 10;

local Linq = nil;
local Utilities = nil;
local BuffManager = nil;
local ItemManager = nil;
local Damage = nil;
local ObjectManager = nil;
local TargetSelector = nil;
local HealthPrediction = nil;
local Orbwalker = nil;

local myHero = _G.myHero;
local EnemiesInGame = {};

local LoadCallbacks = {};
_G.AddLoadCallback = function(cb)
	LocalTableInsert(LoadCallbacks, cb);
end

LocalCallbackAdd('Load', function()
	local Loaded = false;
	myHero = _G.myHero;
	local id = LocalCallbackAdd('Tick', function()
		if not Loaded then
			if LocalGameHeroCount() > 1 or LocalGameTimer() > 30 then
				for i = 1, LocalGameHeroCount() do
					EnemiesInGame[LocalGameHero(i).charName] = true;
				end
				myHero = _G.myHero;
				for i = 1, #LoadCallbacks do
					LoadCallbacks[i]();
				end
				Loaded = true;
				LocalCallbackDel('Tick', id);
			end
		end
	end);
end);


--[[
AddLoadCallback(function()
	LocalCallbackAdd('Tick', function()
		if _G.Game.CanUseSpell(_Q) == READY then
			local t = ObjectManager:GetEnemyMinions(1500);
			for i = 1, #t do
				_G.Control.CastSpell(HK_Q)
			end
		end
	end);
end);
class "__ClickBlocker"
	function __ClickBlocker:__init()
		local CLICK_TYPE_CASTSPELL 			= 1;
		local CLICK_TYPE_ATTACK				= 2;
		local CLICK_TYPE_MOVE				= 3;
		local LocalControlCastSpell			= Control.CastSpell;
		local LocalControlMove				= Control.Move;
		local LocalControlAttack			= Control.Attack;
		
		local NextClick = 0;
		local LastClickType = -1;
		_G.Control.CastSpell = function(...)
			if LocalGameTimer() < NextClick and LastClickType ~= CLICK_TYPE_CASTSPELL then
				return nil;
			end
			NextClick = LocalGameTimer() + 0.25;
			LastClickType = CLICK_TYPE_CASTSPELL;
			return LocalControlCastSpell(...);
		end

		_G.Control.Attack = function(...)
			if LocalGameTimer() < NextClick and LastClickType ~= CLICK_TYPE_ATTACK then
				return nil;
			end
			NextClick = LocalGameTimer() + 0.25;
			LastClickType = CLICK_TYPE_ATTACK;
			return LocalControlAttack(...);
		end
		
		_G.Control.Move = function(...)
			if LocalGameTimer() < NextClick and LastClickType ~= CLICK_TYPE_MOVE then
				return nil;
			end
			NextClick = LocalGameTimer() + 0.25;
			LastClickType = CLICK_TYPE_MOVE;
			return LocalControlMove(...);
		end
	end


]]

--__ClickBlocker();

AddLoadCallback(function()
	local ControlOrder = nil;
	local CONTROL_TYPE_ATTACK			= 1;
	local CONTROL_TYPE_MOVE				= 2;
	local CONTROL_TYPE_CASTSPELL		= 3;
	local ControlTypeTable = {};

	local FlashKey = Utilities:GetHotKeyFromSlot(Utilities:GetSlotFromName(myHero, "SummonerFlash"));
	local FlashPressed = false;
	
	local ControlAttackTable = {};
	local CONTROL_ATTACK_STEP_SET_TARGET_POSITION		= 1;
	local CONTROL_ATTACK_STEP_PRESS_TARGET				= 2;
	local CONTROL_ATTACK_STEP_RELEASE_TARGET			= 3;
	local CONTROL_ATTACK_STEP_SET_MOUSE_POSITION		= 4;
	local CONTROL_ATTACK_STEP_CHECK_MOUSE_POSITION		= 5;
	
	ControlAttackTable = {
		[CONTROL_ATTACK_STEP_SET_TARGET_POSITION] = function()
			LocalControlSetCursorPos(ControlOrder.Target.pos);
			ControlOrder.NextStep = CONTROL_ATTACK_STEP_PRESS_TARGET;
		end,
		[CONTROL_ATTACK_STEP_PRESS_TARGET] = function()
			if ControlOrder.TargetIsHero then
				LocalControlKeyDown(_G.HK_TCO);
			end
			if LocalControlMouseEvent(MOUSEEVENTF_RIGHTDOWN) then
				ControlOrder.NextStep = CONTROL_ATTACK_STEP_RELEASE_TARGET;
			end
		end,
		[CONTROL_ATTACK_STEP_RELEASE_TARGET] = function()
			if LocalControlMouseEvent(MOUSEEVENTF_RIGHTUP) then
				ControlOrder.NextStep = CONTROL_ATTACK_STEP_SET_MOUSE_POSITION;
				if ControlOrder.TargetIsHero then
					LocalControlKeyUp(_G.HK_TCO);
				end
			end
		end,
		[CONTROL_ATTACK_STEP_SET_MOUSE_POSITION] = function()
			local position = ControlOrder.MousePosition;
			LocalControlSetCursorPos(position.x, position.y);
			ControlOrder.NextStep = CONTROL_ATTACK_STEP_CHECK_MOUSE_POSITION;
		end,
		[CONTROL_ATTACK_STEP_CHECK_MOUSE_POSITION] = function()
			ControlOrder = nil;
		end,
	};
	
	_G.Control.Attack = function(target)
		local isNil = ControlOrder == nil;
		if isNil then
			ControlOrder = {
				Type = CONTROL_TYPE_ATTACK;
				Target = target,
				NextStep = CONTROL_ATTACK_STEP_SET_TARGET_POSITION,
				MousePosition = _G.cursorPos,
				TargetIsHero = target.type == Obj_AI_Hero
			};
			ControlTypeTable[ControlOrder.Type]();
		end
		return isNil;
	end

	local ControlMoveTable = {};
	local CONTROL_MOVE_STEP_SET_TARGET_POSITION			= 1;
	local CONTROL_MOVE_STEP_PRESS_POSITION				= 2;
	local CONTROL_MOVE_STEP_RELEASE_POSITION			= 3;
	local CONTROL_MOVE_STEP_SET_MOUSE_POSITION			= 4;
	local CONTROL_MOVE_STEP_CHECK_MOUSE_POSITION		= 5;
	
	ControlMoveTable = {
		[CONTROL_MOVE_STEP_SET_TARGET_POSITION] = function()
			if ControlOrder.TargetPosition.z ~= nil then
				LocalControlSetCursorPos(ControlOrder.TargetPosition);
			else
				LocalControlSetCursorPos(ControlOrder.TargetPosition.x, ControlOrder.TargetPosition.y);
			end
			ControlOrder.NextStep = CONTROL_MOVE_STEP_PRESS_POSITION;
		end,
		[CONTROL_MOVE_STEP_PRESS_POSITION] = function()
			LocalControlKeyDown(_G.HK_TCO);
			if LocalControlMouseEvent(MOUSEEVENTF_RIGHTDOWN) then
				ControlOrder.NextStep = CONTROL_MOVE_STEP_RELEASE_POSITION;
			end
		end,
		[CONTROL_MOVE_STEP_RELEASE_POSITION] = function()
			if LocalControlMouseEvent(MOUSEEVENTF_RIGHTUP) then
				LocalControlKeyUp(_G.HK_TCO);
				if ControlOrder.TargetPosition ~= nil then
					ControlOrder.NextStep = CONTROL_MOVE_STEP_SET_MOUSE_POSITION;
				else
					ControlOrder = nil;
				end
			end
		end,
		[CONTROL_MOVE_STEP_SET_MOUSE_POSITION] = function()
			local position = ControlOrder.MousePosition;
			LocalControlSetCursorPos(position.x, position.y);
			ControlOrder.NextStep = CONTROL_MOVE_STEP_CHECK_MOUSE_POSITION;
		end,
		[CONTROL_MOVE_STEP_CHECK_MOUSE_POSITION] = function()
			ControlOrder = nil;
		end,
	};
	
	_G.Control.Move = function(a, b, c)
		local isNil = ControlOrder == nil;
		if isNil then
			if a and b and c then
				ControlOrder = {
					Type = CONTROL_TYPE_MOVE,
					TargetPosition = LocalVector(a, b, c),
					NextStep = CONTROL_MOVE_STEP_SET_TARGET_POSITION,
					MousePosition = _G.cursorPos,
				};
			elseif a and b then
				ControlOrder = {
					Type = CONTROL_TYPE_MOVE,
					TargetPosition = LocalVector({ x = a, y = b}),
					NextStep = CONTROL_MOVE_STEP_SET_TARGET_POSITION,
					MousePosition = _G.cursorPos,
				};
			elseif a then
				ControlOrder = {
					Type = CONTROL_TYPE_MOVE,
					TargetPosition = a,
					NextStep = CONTROL_MOVE_STEP_SET_TARGET_POSITION,
					MousePosition = _G.cursorPos,
				};
			else
				ControlOrder = {
					Type = CONTROL_TYPE_MOVE,
					NextStep = CONTROL_MOVE_STEP_PRESS_POSITION,
					MousePosition = _G.cursorPos,
				};
			end
			ControlTypeTable[ControlOrder.Type]();
		end
		return isNil;
	end
	
	local ControlCastSpellTable = {};
	local CONTROL_CASTSPELL_STEP_SET_TARGET_POSITION		= 1;
	local CONTROL_CASTSPELL_STEP_PRESS_KEY					= 2;
	local CONTROL_CASTSPELL_STEP_PRESS_POSITION				= 3;
	local CONTROL_CASTSPELL_STEP_RELEASE_POSITION			= 4;
	local CONTROL_CASTSPELL_STEP_RELEASE_KEY				= 5;
	local CONTROL_CASTSPELL_STEP_SET_MOUSE_POSITION			= 6;
	local CONTROL_CASTSPELL_STEP_CHECK_MOUSE_POSITION		= 7;
	
	ControlCastSpellTable = {
		[CONTROL_CASTSPELL_STEP_SET_TARGET_POSITION] = function()
			local position = ControlOrder.Target ~= nil and ControlOrder.Target.pos or ControlOrder.TargetPosition;
			LocalControlSetCursorPos(position);
			ControlOrder.NextStep = CONTROL_CASTSPELL_STEP_PRESS_KEY;
		end,
		[CONTROL_CASTSPELL_STEP_PRESS_KEY] = function()
			LocalControlKeyDown(ControlOrder.Key);
			if ControlOrder.TargetPosition ~= nil then
				ControlOrder.NextStep = CONTROL_CASTSPELL_STEP_PRESS_POSITION;
			else
				ControlOrder.NextStep = CONTROL_CASTSPELL_STEP_RELEASE_KEY;
			end
		end,
		[CONTROL_CASTSPELL_STEP_PRESS_POSITION] = function()
			if LocalControlMouseEvent(MOUSEEVENTF_LEFTDOWN) then
				ControlOrder.NextStep = CONTROL_CASTSPELL_STEP_RELEASE_POSITION;
			end
		end,
		[CONTROL_CASTSPELL_STEP_RELEASE_POSITION] = function()
			if LocalControlMouseEvent(MOUSEEVENTF_LEFTUP) then
				ControlOrder.NextStep = CONTROL_CASTSPELL_STEP_RELEASE_KEY;
			end
		end,
		[CONTROL_CASTSPELL_STEP_RELEASE_KEY] = function()
			LocalControlKeyUp(ControlOrder.Key);
			if ControlOrder.TargetPosition ~= nil then
				ControlOrder.NextStep = CONTROL_CASTSPELL_STEP_SET_MOUSE_POSITION;
			else
				ControlOrder = nil;
			end
		end,
		[CONTROL_CASTSPELL_STEP_SET_MOUSE_POSITION] = function()
			local position = ControlOrder.MousePosition;
			LocalControlSetCursorPos(position.x, position.y);
			ControlOrder.NextStep = CONTROL_CASTSPELL_STEP_CHECK_MOUSE_POSITION;
		end,
		[CONTROL_CASTSPELL_STEP_CHECK_MOUSE_POSITION] = function()
			ControlOrder = nil;
		end,
	};

	_G.Control.CastSpell = function(key, a, b, c)
		local isNil = ControlOrder == nil;
		if isNil then
			if a and b and c then
				ControlOrder = {
					Type = CONTROL_TYPE_CASTSPELL,
					Key = key,
					TargetPosition = LocalVector(a, b, c),
					NextStep = CONTROL_CASTSPELL_STEP_SET_TARGET_POSITION,
					MousePosition = _G.cursorPos,
				};
			elseif a and b then
				ControlOrder = {
					Type = CONTROL_TYPE_CASTSPELL,
					Key = key,
					TargetPosition = LocalVector({ x = a, y = b}),
					NextStep = CONTROL_CASTSPELL_STEP_SET_TARGET_POSITION,
					MousePosition = _G.cursorPos,
				};
			elseif a then
				if a.pos then
					ControlOrder = {
						Type = CONTROL_TYPE_CASTSPELL,
						Key = key,
						Target = a,
						TargetPosition = a.pos,
						NextStep = CONTROL_CASTSPELL_STEP_SET_TARGET_POSITION,
						MousePosition = _G.cursorPos,
					};
				else
					ControlOrder = {
						Type = CONTROL_TYPE_CASTSPELL,
						Key = key,
						TargetPosition = a,
						NextStep = CONTROL_CASTSPELL_STEP_SET_TARGET_POSITION,
						MousePosition = _G.cursorPos,
					};
				end
			else
				ControlOrder = {
					Type = CONTROL_TYPE_CASTSPELL,
					Key = key,
					NextStep = CONTROL_CASTSPELL_STEP_PRESS_KEY,
				};
			end
			ControlTypeTable[ControlOrder.Type]();
		end
		return isNil;
	end

	ControlTypeTable = {
		[CONTROL_TYPE_ATTACK] = function()
			ControlAttackTable[ControlOrder.NextStep]();
		end,
		[CONTROL_TYPE_MOVE] = function()
			ControlMoveTable[ControlOrder.NextStep]();
		end,
		[CONTROL_TYPE_CASTSPELL] = function()
			ControlCastSpellTable[ControlOrder.NextStep]();
		end
	};
	LocalCallbackAdd('Draw', function()
		if ControlOrder ~= nil then
			ControlTypeTable[ControlOrder.Type]();
		end
	end);

	--[[
	if FlashKey ~= nil then
		LocalCallbackAdd('WndMsg', function(msg, wParam)
			if wParam == FlashKey then
				if msg == KEY_UP then
					FlashPressed = true;
				elseif msg == KEY_DOWN then
					if ControlOrder ~= nil then
						print("Cancelling");
						local MousePosition = ControlOrder.MousePosition;
						ControlOrder = nil;
						_G.Control.Move(MousePosition);
					end
					FlashPressed = false;
				end
			end
		end);
	end
	]]
	
end);

class "__BuffManager"
	function __BuffManager:__init()
		self.CachedBuffStacks = {};
		LocalCallbackAdd('Tick', function()
			self.CachedBuffStacks = {};
		end);
	end

	function __BuffManager:BuffIsValid(buff)
		return buff ~= nil and buff.startTime <= LocalGameTimer() and buff.expireTime >= LocalGameTimer() and buff.count > 0;
	end

	function __BuffManager:CacheBuffs(unit)
		if self.CachedBuffStacks[unit.networkID] == nil then
			local t = {};
			for i = 0, unit.buffCount do
				local buff = unit:GetBuff(i);
				if self:BuffIsValid(buff) then
					t[buff.name] = buff.count;
				end
			end
			self.CachedBuffStacks[unit.networkID] = t;
		end
	end

	function __BuffManager:HasBuff(unit, name)
		self:CacheBuffs(unit);
		return self.CachedBuffStacks[unit.networkID][name] ~= nil;
	end

	function __BuffManager:GetBuffCount(unit, name)
		self:CacheBuffs(unit);
		local count = self.CachedBuffStacks[unit.networkID][name];
		return count ~= nil and count or -1;
	end

	function __BuffManager:GetBuff(unit, name)
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i);
			if self:BuffIsValid(buff) then
				if buff.name == name then
					return buff;
				end
			end
		end
		return nil;
	end

class "__ItemManager"
	function __ItemManager:__init()
		self.ItemSlots = {
			ITEM_1,
			ITEM_2,
			ITEM_3,
			ITEM_4,
			ITEM_5,
			ITEM_6,
			ITEM_7,
		};
		self.CachedItems = {};
		LocalCallbackAdd('Tick', function()
			self.CachedItems = {};
		end);
	end

	function __ItemManager:CacheItems(unit)
		if self.CachedItems[unit.networkID] == nil then
			local t = {};
			for i = 1, #self.ItemSlots do
				local slot = self.ItemSlots[i];
				local item = unit:GetItemData(slot);
				if item ~= nil and item.itemID > 0 then
					t[item.itemID] = item;
				end
			end
			self.CachedItems[unit.networkID] = t;
		end
	end

	function __ItemManager:GetItemByID(unit, id)
		self:CacheItems(unit);
		return self.CachedItems[unit.networkID][id];
	end

	function __ItemManager:HasItem(unit, id)
		return self:GetItemByID(unit, id) ~= nil;
	end

	function __ItemManager:GetItemSlot(unit, id)
		for i = 1, #self.ItemSlots do
			local slot = self.ItemSlots[i];
			local item = unit:GetItemData(slot);
			if item ~= nil and item.itemID > 0 then
				return slot;
			end
		end
		return nil;
	end

class "__Damage"
	function __Damage:__init()
		self.StaticChampionDamageDatabase = {
			["Caitlyn"] = function(args)
				if BuffManager:HasBuff(args.From, "caitlynheadshot") then
					if args.TargetIsMinion then
						args.RawPhysical = args.RawPhysical + args.From.totalDamage * 1.5;
					else
						--TODO
					end
				end
			end,
			["Corki"] = function(args)
				args.RawTotal = args.RawTotal * 0.5;
				args.RawMagical = args.RawTotal;
			end,
			["Diana"] = function(args)
				local level = Utilities:GetLevel(args.From);
				args.RawMagical = args.RawMagical + LocalMathMax(15 + 5 * level, -10 + 10 * level, -60 + 15 * level, -125 + 20 * level, -200 + 25 * level) + 0.8 * args.From.ap;
			end,
			["Draven"] = function(args)
				if BuffManager:HasBuff(args.From, "DravenSpinningAttack") then
					local level = Utilities:GetSpellLevel(args.From, _Q);
					args.RawPhysical = args.RawPhysical + 25 + 5 * level + (0.55 + 0.1 * level) * args.From.bonusDamage; 
				end

			end,
			["Graves"] = function(args)
				local t = { 70, 71, 72, 74, 75, 76, 78, 80, 81, 83, 85, 87, 89, 91, 95, 96, 97, 100 };
				args.RawTotal = args.RawTotal * t[self:GetMaxLevel(args.From)] * 0.01;
			end,
			["Jinx"] = function(args)
				if BuffManager:HasBuff(args.From, "JinxQ") then
					args.RawPhysical = args.RawPhysical + args.From.totalDamage * 0.1;
				end
			end,
			["Kalista"] = function(args)
				args.RawPhysical = args.RawPhysical - args.From.totalDamage * 0.1;
			end,
			["Nasus"] = function(args)
				if BuffManager:HasBuff(args.From, "NasusQ") then
					args.RawPhysical = args.RawPhysical + LocalMathMax(BuffManager:GetBuffCount(args.From, "NasusQStacks"), 0) + 10 + 20 * Utilities:GetSpellLevel(args.From, _Q);
				end
			end,
			["Thresh"] = function(args)
				local level = Utilities:GetSpellLevel(args.From, _E);
				if level > 0 then
					local damage = LocalMathMax(BuffManager:GetBuffCount(args.From, "threshpassivesouls"), 0) + (0.5 + 0.3 * level) * args.From.totalDamage;
					if BuffManager:HasBuff(args.From, "threshqpassive4") then
						damage = damage * 1;
					elseif BuffManager:HasBuff(args.From, "threshqpassive3") then
						damage = damage * 0.5;
					elseif BuffManager:HasBuff(args.From, "threshqpassive2") then
						damage = damage * 1/3;
					else
						damage = damage * 0.25;
					end
					args.RawMagical = args.RawMagical + damage;
				end
			end,
			["TwistedFate"] = function(args)
				if BuffManager:HasBuff(args.From, "cardmasterstackparticle") then
					args.RawMagical = args.RawMagical + 30 + 25 * Utilities:GetSpellLevel(args.From, _E) + 0.5 * args.From.ap;
				end
				if BuffManager:HasBuff(args.From, "BlueCardPreAttack") then
					args.DamageType = DAMAGE_TYPE_MAGICAL;
					args.RawMagical = args.RawMagical + 20 + 20 * Utilities:GetSpellLevel(args.From, _W) + 0.5 * args.From.ap;
				elseif BuffManager:HasBuff(args.From, "RedCardPreAttack") then
					args.DamageType = DAMAGE_TYPE_MAGICAL;
					args.RawMagical = args.RawMagical + 15 + 15 * Utilities:GetSpellLevel(args.From, _W) + 0.5 * args.From.ap;
				elseif BuffManager:HasBuff(args.From, "GoldCardPreAttack") then
					args.DamageType = DAMAGE_TYPE_MAGICAL;
					args.RawMagical = args.RawMagical + 7.5 + 7.5 * Utilities:GetSpellLevel(args.From, _W) + 0.5 * args.From.ap;
				end
			end,
			["Varus"] = function(args)
				local level = Utilities:GetSpellLevel(args.From, _W);
				if level > 0 then
					args.RawMagical = args.RawMagical + 6 + 4 * level + 0.25 * args.From.ap;
				end
			end,
			["Viktor"] = function(args)
				if BuffManager:HasBuff(args.From, "ViktorPowerTransferReturn") then
					args.DamageType = DAMAGE_TYPE_MAGICAL;
					args.RawMagical = args.RawMagical + 20 * Utilities:GetSpellLevel(args.From, _Q) + 0.5 * args.From.ap;
				end
			end,
			["Vayne"] = function(args)
				if BuffManager:HasBuff(args.From, "vaynetumblebonus") then
					args.RawPhysical = args.RawPhysical + (0.25 + 0.05 * Utilities:GetSpellLevel(args.From, _Q)) * args.From.totalDamage;
				end
			end,
		};
		self.VariableChampionDamageDatabase = {
			["Jhin"] = function(args)
				if BuffManager:HasBuff(args.From, "jhinpassiveattackbuff") then
					args.CriticalStrike = true;
					args.RawPhysical = args.RawPhysical + LocalMathMin(0.25, 0.1 + 0.05 * LocalMathCeil(Utilities:GetLevel(args.From) / 5)) * (args.Target.maxHealth - args.Target.health);
				end
			end,
			["Orianna"] = function(args)
				local level = LocalMathCeil(Utilities:GetLevel(args.From) / 3);
				args.RawMagical = args.RawMagical + 2 + 8 * level + 0.15 * args.From.ap;
				if args.Target.handle == Utilities:GetAttackDataTarget(args.From) then
					args.RawMagical = args.RawMagical + LocalMathMax(BuffManager:GetBuffCount(args.From, "orianapowerdaggerdisplay"), 0) * (0.4 + 1.6 * level + 0.03 * args.From.ap);
				end
			end,
			["Quinn"] = function(args)
				if BuffManager:HasBuff(args.Target, "QuinnW") then
					local level = Utilities:GetLevel(args.From);
					args.RawPhysical = args.RawPhysical + 10 + level * 5 + (0.14 + 0.02 * level) * args.From.totalDamage;
				end
			end,
			["Vayne"] = function(args)
				if BuffManager:GetBuffCount(args.Target, "VayneSilveredDebuff") == 2 then
					local level = Utilities:GetSpellLevel(args.From, _W);
					args.CalculatedTrue = args.CalculatedTrue + LocalMathMax((0.045 + 0.015 * level) * args.Target.maxHealth, 20 + 20 * level);
				end
			end,
			["Zed"] = function(args)
				if Utilities:GetHealthPercent(args.Target) <= 50 and not BuffManager:HasBuff(args.From, "zedpassivecd") then
					args.RawMagical = args.RawMagical + args.Target.maxHealth * (4 + 2 * LocalMathCeil(Utilities:GetLevel(args.From) / 6)) * 0.01;
				end
			end,
		};
		self.StaticItemDamageDatabase = {
			[1043] = function(args)
				args.RawPhysical = args.RawPhysical + 15;
			end,
			[2015] = function(args)
				if BuffManager:GetBuffCount(args.From, "itemstatikshankcharge") == 100 then
					args.RawMagical = args.RawMagical + 40;
				end
			end,
			[3057] = function(args)
				if BuffManager:HasBuff(args.From, "sheen") then
					args.RawPhysical = args.RawPhysical + 1 * args.From.baseDamage;
				end
			end,
			[3078] = function(args)
				if BuffManager:HasBuff(args.From, "sheen") then
					args.RawPhysical = args.RawPhysical + 2 * args.From.baseDamage;
				end
			end,
			[3085] = function(args)
				args.RawPhysical = args.RawPhysical + 15;
			end,
			[3087] = function(args)
				if BuffManager:GetBuffCount(args.From, "itemstatikshankcharge") == 100 then
					local t = { 50, 50, 50, 50, 50, 56, 61, 67, 72, 77, 83, 88, 94, 99, 104, 110, 115, 120 };
					args.RawMagical = args.RawMagical + (1 + (args.TargetIsMinion and 1.2 or 0)) * t[self:GetMaxLevel(args.From)];
				end
			end,
			[3091] = function(args)
				args.RawMagical = args.RawMagical + 40;
			end,
			[3094] = function(args)
				if BuffManager:GetBuffCount(args.From, "itemstatikshankcharge") == 100 then
					local t = { 50, 50, 50, 50, 50, 58, 66, 75, 83, 92, 100, 109, 117, 126, 134, 143, 151, 160 };
					args.RawMagical = args.RawMagical + t[self:GetMaxLevel(args.From)];
				end
			end,
			[3100] = function(args)
				if BuffManager:HasBuff(args.From, "lichbane") then
					args.RawMagical = args.RawMagical + 0.75 * args.From.baseDamage + 0.5 * args.From.ap;
				end
			end,
			[3115] = function(args)
				args.RawMagical = args.RawMagical + 15 + 0.15 * args.From.ap;
			end,
			[3124] = function(args)
				args.CalculatedMagical = args.CalculatedMagical + 15;
			end,
		};
		self.VariableItemDamageDatabase = {
			[1041] = function(args)
				if Utilities:IsMonster(args.Target) then
					args.CalculatedPhysical = args.CalculatedPhysical + 25;
				end
			end,
		};
		self.TurretToMinionPercentMod = {};
		for i = 1, #ObjectManager.MinionTypesDictionary["Melee"] do
			local charName = ObjectManager.MinionTypesDictionary["Melee"][i];
			self.TurretToMinionPercentMod[charName] = 0.45;
		end
		for i = 1, #ObjectManager.MinionTypesDictionary["Ranged"] do
			local charName = ObjectManager.MinionTypesDictionary["Ranged"][i];
			self.TurretToMinionPercentMod[charName] = 0.7;
		end
		for i = 1, #ObjectManager.MinionTypesDictionary["Siege"] do
			local charName = ObjectManager.MinionTypesDictionary["Siege"][i];
			self.TurretToMinionPercentMod[charName] = 0.14;
		end
		for i = 1, #ObjectManager.MinionTypesDictionary["Super"] do
			local charName = ObjectManager.MinionTypesDictionary["Super"][i];
			self.TurretToMinionPercentMod[charName] = 0.05;
		end

	end

	function __Damage:GetMaxLevel(hero)
		return LocalMathMax(LocalMathMin(Utilities:GetLevel(hero), 18), 1);
	end

	function __Damage:CalculateDamage(from, target, damageType, rawDamage, isAbility, isAutoAttackOrTargetted)
		if from == nil or target == nil then
			return 0;
		end
		if isAbility == nil then
			isAbility = true;
		end
		if isAutoAttackOrTargetted == nil then
			isAutoAttackOrTargetted = false;
		end

		local fromIsMinion = from.type == Obj_AI_Minion;
		local targetIsMinion = target.type == Obj_AI_Minion;

		local baseResistance = 0;
		local bonusResistance = 0;
		local penetrationFlat = 0;
		local penetrationPercent = 0;
		local bonusPenetrationPercent = 0;

		if damageType == DAMAGE_TYPE_PHYSICAL then
			baseResistance = LocalMathMax(target.armor - target.bonusArmor, 0);
			bonusResistance = target.bonusArmor;
			penetrationFlat = from.armorPen;
			penetrationPercent = from.armorPenPercent;
			bonusPenetrationPercent = from.bonusArmorPenPercent;

			--  Minions return wrong percent values.
			if fromIsMinion then
				penetrationFlat = 0;
				penetrationPercent = 0;
				bonusPenetrationPercent = 0;
			elseif from.type == Obj_AI_Turret then
				penetrationPercent = (not Utilities:IsBaseTurret(from)) and 0.3 or 0.75;
				penetrationFlat = 0;
				bonusPenetrationPercent = 0;
			end
		elseif damageType == DAMAGE_TYPE_MAGICAL then
			baseResistance = LocalMathMax(target.magicResist - target.bonusMagicResist, 0);
			bonusResistance = target.bonusMagicResist;
			penetrationFlat = from.magicPen;
			penetrationPercent = from.magicPenPercent;
			bonusPenetrationPercent = 0;
		elseif damageType == DAMAGE_TYPE_TRUE then
			return rawDamage;
		end
		local resistance = baseResistance + bonusResistance;
		if resistance > 0 then
			if penetrationPercent > 0 then
				baseResistance = baseResistance * penetrationPercent;
				bonusResistance = bonusResistance * penetrationPercent;
			end
			if bonusPenetrationPercent > 0 then
				bonusResistance = bonusResistance * bonusPenetrationPercent;
			end
			resistance = baseResistance + bonusResistance;
			resistance = resistance - penetrationFlat;
		end

		local percentMod = 1;
		-- Penetration cant reduce resistance below 0.
		if resistance >= 0 then
			percentMod = percentMod * (100 / (100 + resistance));
		else
			percentMod = percentMod * (2 - 100 / (100 - resistance));
		end
		local percentReceived = 1;
		local flatPassive = 0;

		local percentPassive = 1;
		if fromIsMinion and targetIsMinion then
			percentPassive = percentPassive * (1 + from.bonusDamagePercent);
		end

		local flatReceived = 0;
		if fromIsMinion and targetIsMinion then
			flatReceived = flatReceived - target.flatDamageReduction;
		end

		return LocalMathMax(percentReceived * percentPassive * percentMod * (rawDamage + flatPassive) + flatReceived, 0);
	end

	function __Damage:GetStaticAutoAttackDamage(from, targetIsMinion)
		local args = {
			From = from,
			RawTotal = from.totalDamage,
			RawPhysical = 0,
			RawMagical = 0,
			CalculatedTrue = 0,
			CalculatedPhysical = 0,
			CalculatedMagical = 0,
			DamageType = DAMAGE_TYPE_PHYSICAL,
			TargetIsMinion = targetIsMinion,
		};
		if self.StaticChampionDamageDatabase[args.From.charName] ~= nil then
			self.StaticChampionDamageDatabase[args.From.charName](args);
		end

		local HashSet = {};
		for i = 1, #ItemManager.ItemSlots do
			local slot = ItemManager.ItemSlots[i];
			local item = args.From:GetItemData(slot);
			if item ~= nil and item.itemID > 0 then
				if HashSet[item.itemID] == nil then
					if self.StaticItemDamageDatabase[item.itemID] ~= nil then
						self.StaticItemDamageDatabase[item.itemID](args);
					end
					HashSet[item.itemID] = true;
				end
			end
		end

		return args;
	end

	function __Damage:GetHeroAutoAttackDamage(from, target, static)
		local args = {
			From = from,
			Target = target,
			RawTotal = static.RawTotal,
			RawPhysical = static.RawPhysical,
			RawMagical = static.RawMagical,
			CalculatedTrue = static.CalculatedTrue,
			CalculatedPhysical = static.CalculatedPhysical,
			CalculatedMagical = static.CalculatedMagical,
			DamageType = static.DamageType,
			TargetIsMinion = target.type == Obj_AI_Minion,
			CriticalStrike = false,
		};
		if args.TargetIsMinion and Utilities:IsOtherMinion(args.Target) then
			return 1;
		end

		if self.VariableChampionDamageDatabase[args.From.charName] ~= nil then
			self.VariableChampionDamageDatabase[args.From.charName](args);
		end

		if args.DamageType == DAMAGE_TYPE_PHYSICAL then
			args.RawPhysical = args.RawPhysical + args.RawTotal;
		elseif args.DamageType == DAMAGE_TYPE_MAGICAL then
			args.RawMagical = args.RawMagical + args.RawTotal;
		elseif args.DamageType == DAMAGE_TYPE_TRUE then
			args.CalculatedTrue = args.CalculatedTrue + args.RawTotal;
		end

		if args.RawPhysical > 0 then
			args.CalculatedPhysical = args.CalculatedPhysical + self:CalculateDamage(from, target, DAMAGE_TYPE_PHYSICAL, args.RawPhysical, false, args.DamageType == DAMAGE_TYPE_PHYSICAL);
		end

		if args.RawMagical > 0 then
			args.CalculatedMagical = args.CalculatedMagical + self:CalculateDamage(from, target, DAMAGE_TYPE_MAGICAL, args.RawMagical, false, args.DamageType == DAMAGE_TYPE_MAGICAL);
		end

		local percentMod = 1;
		if LocalMathAbs(args.From.critChance - 1) < EPSILON or args.CriticalStrike then
			percentMod = percentMod * self:GetCriticalStrikePercent(args.From);
		end
		return percentMod * args.CalculatedPhysical + args.CalculatedMagical + args.CalculatedTrue;
	end

	function __Damage:GetAutoAttackDamage(from, target, respectPassives)
		if respectPassives == nil then
			respectPassives = true;
		end
		if from == nil or target == nil then
			return 0;
		end
		local targetIsMinion = target.type == Obj_AI_Minion;
		if respectPassives and from.type == Obj_AI_Hero then
			return self:GetHeroAutoAttackDamage(from, target, self:GetStaticAutoAttackDamage(from, targetIsMinion));
		end
		if targetIsMinion then
			if Utilities:IsOtherMinion(target) then
				return 1;
			end
			if from.type == Obj_AI_Turret and not Utilities:IsBaseTurret(from) then
				local percentMod = self.TurretToMinionPercentMod[target.charName];
				if percentMod ~= nil then
					return target.maxHealth * percentMod;
				end
			end
		end
		return self:CalculateDamage(from, target, DAMAGE_TYPE_PHYSICAL, from.totalDamage, false, true);
	end

	function __Damage:GetCriticalStrikePercent(from)
		local baseCriticalDamage = 2 + (ItemManager:HasItem(from, 3031) and 0.5 or 0);
		local percentMod = 1;
		local fixedMod = 0;
		if from.charName == "Jhin" then
			percentMod = 0.75;
		elseif from.charName == "XinZhao" then
			baseCriticalDamage = baseCriticalDamage - (0.875 - 0.125 * Utilities:GetSpellLevel(from, _W));
		elseif from.charName == "Yasuo" then
			percentMod = 0.9;
		end
		return baseCriticalDamage * percentMod;
	end

class "__Utilities"
	function __Utilities:__init()
		self.ChannelingBuffs = {
			["Caitlyn"] = function(unit)
				return BuffManager:HasBuff(unit, "CaitlynAceintheHole");
			end,
			["Fiddlesticks"] = function(unit)
				return BuffManager:HasBuff(unit, "Drain") or BuffManager:HasBuff(unit, "Crowstorm");
			end,
			["Galio"] = function(unit)
				return BuffManager:HasBuff(unit, "GalioIdolOfDurand");
			end,
			["Janna"] = function(unit)
				return BuffManager:HasBuff(unit, "ReapTheWhirlwind");
			end,
			["Karthus"] = function(unit)
				return BuffManager:HasBuff(unit, "karthusfallenonecastsound");
			end,
			["Katarina"] = function(unit)
				return BuffManager:HasBuff(unit, "katarinarsound");
			end,
			["Lucian"] = function(unit)
				return BuffManager:HasBuff(unit, "LucianR");
			end,
			["Malzahar"] = function(unit)
				return BuffManager:HasBuff(unit, "alzaharnethergraspsound");
			end,
			["MasterYi"] = function(unit)
				return BuffManager:HasBuff(unit, "Meditate");
			end,
			["MissFortune"] = function(unit)
				return BuffManager:HasBuff(unit, "missfortunebulletsound");
			end,
			["Nunu"] = function(unit)
				return BuffManager:HasBuff(unit, "AbsoluteZero");
			end,
			["Pantheon"] = function(unit)
				return BuffManager:HasBuff(unit, "pantheonesound") or BuffManager:HasBuff(unit, "PantheonRJump");
			end,
			["Shen"] = function(unit)
				return BuffManager:HasBuff(unit, "shenstandunitedlock");
			end,
			["TwistedFate"] = function(unit)
				return BuffManager:HasBuff(unit, "Destiny");
			end,
			["Urgot"] = function(unit)
				return BuffManager:HasBuff(unit, "UrgotSwap2");
			end,
			["Varus"] = function(unit)
				return BuffManager:HasBuff(unit, "VarusQ");
			end,
			["VelKoz"] = function(unit)
				return BuffManager:HasBuff(unit, "VelkozR");
			end,
			["Vi"] = function(unit)
				return BuffManager:HasBuff(unit, "ViQ");
			end,
			["Vladimir"] = function(unit)
				return BuffManager:HasBuff(unit, "VladimirE");
			end,
			["Warwick"] = function(unit)
				return BuffManager:HasBuff(unit, "infiniteduresssound");
			end,
			["Xerath"] = function(unit)
				return BuffManager:HasBuff(unit, "XerathArcanopulseChargeUp") or BuffManager:HasBuff(unit, "XerathLocusOfPower2");
			end,
		};
		self.SpecialAutoAttackRanges = {
			["Caitlyn"] = function(from, target)
				if target ~= nil and BuffManager:HasBuff(target, "caitlynyordletrapinternal") then
					return 650;
				end
				return 0;
			end,
		};
		self.SpecialWindUpTimes = {
			["TwistedFate"] = function(unit, target)
				if BuffManager:HasBuff(unit, "BlueCardPreAttack") or BuffManager:HasBuff(unit, "RedCardPreAttack") or BuffManager:HasBuff(unit, "GoldCardPreAttack") then
					return 0.125;
				end
				return nil;
			end,
		};

		self.SpecialMissileSpeeds = {
			["Caitlyn"] = function(unit, target)
				if BuffManager:HasBuff(unit, "caitlynheadshot") then
					return 3000;
				end
				return nil;
			end,
			["Graves"] = function(unit, target)
				return 3800;
			end,
			["Illaoi"] = function(unit, target)
				if BuffManager:HasBuff(unit, "IllaoiW") then
					return 1600;
				end
				return nil;
			end,
			["Jayce"] = function(unit, target)
				if BuffManager:HasBuff(unit, "jaycestancegun") then
					return 2000;
				end
				return nil;
			end,
			["Jhin"] = function(unit, target)
				if BuffManager:HasBuff(unit, "jhinpassiveattackbuff") then
					return 3000;
				end
				return nil;
			end,
			["Jinx"] = function(unit, target)
				if BuffManager:HasBuff(unit, "JinxQ") then
					return 2000;
				end
				return nil;
			end,
			["Poppy"] = function(unit, target)
				if BuffManager:HasBuff(unit, "poppypassivebuff") then
					return 1600;
				end
				return nil;
			end,
			["Twitch"] = function(unit, target)
				if BuffManager:HasBuff(unit, "TwitchFullAutomatic") then
					return 4000;
				end
				return nil;
			end,
		};

		self.SpecialMelees = {
			["Azir"] = function(unit) return true end,
			["Thresh"] = function(unit) return true end,
			["Velkoz"] = function(unit) return true end,
			["Viktor"] = function(unit) return BuffManager:HasBuff(unit, "ViktorPowerTransferReturn") end,
		};
		self.UndyingBuffs = {
			["Aatrox"] = function(target, addHealthCheck)
				return BuffManager:HasBuff(target, "aatroxpassivedeath");
			end,
			["Fiora"] = function(target, addHealthCheck)
				return BuffManager:HasBuff(target, "FioraW");
			end,
			["Tryndamere"] = function(target, addHealthCheck)
				return BuffManager:HasBuff(target, "UndyingRage") and (not addHealthCheck or target.health <= 30);
			end,
			["Vladimir"] = function(target, addHealthCheck)
				return BuffManager:HasBuff(target, "VladimirSanguinePool");
			end,
		};

		for i = 1, #ObjectManager.MinionTypesDictionary["Melee"] do
			local charName = ObjectManager.MinionTypesDictionary["Melee"][i];
			self.SpecialMelees[charName] = function(target) return true end;
		end
		self.BaseTurrets = {
			["SRUAP_Turret_Order3"] = true,
			["SRUAP_Turret_Order4"] = true,
			["SRUAP_Turret_Chaos3"] = true,
			["SRUAP_Turret_Chaos4"] = true,
		};
		self.Obj_AI_Bases = {
			[Obj_AI_Hero] = true,
			[Obj_AI_Minion] = true,
			[Obj_AI_Turret] = true,
		};
		self.Structures = {
			[Obj_AI_Barracks] = true,
			[Obj_AI_Turret] = true,
			[Obj_HQ] = true,
		};
		self.CachedValidTargets = {};

		self.SlotToHotKeys = {
			[_Q]			= function() return _G.HK_Q end,
			[_W]			= function() return _G.HK_W end,
			[_E]			= function() return _G.HK_E end,
			[_R]			= function() return _G.HK_R end,
			[ITEM_1]		= function() return _G.HK_ITEM_1 end,
			[ITEM_2]		= function() return _G.HK_ITEM_2 end,
			[ITEM_3]		= function() return _G.HK_ITEM_3 end,
			[ITEM_4]		= function() return _G.HK_ITEM_4 end,
			[ITEM_5]		= function() return _G.HK_ITEM_5 end,
			[ITEM_6]		= function() return _G.HK_ITEM_6 end,
			[ITEM_7]		= function() return _G.HK_ITEM_7 end,
			[SUMMONER_1]	= function() return _G.HK_SUMMONER_1 end,
			[SUMMONER_2]	= function() return _G.HK_SUMMONER_2 end,
		};

		self.DisableSpellWindUpTime = {
			["Kalista"] = true,
			["Thresh"] = true,
		};
		self.Slots = {
			_Q,
			_W,
			_E,
			_R,
			ITEM_1,
			ITEM_2,
			ITEM_3,
			ITEM_4,
			ITEM_5,
			ITEM_6,
			ITEM_7,
			SUMMONER_1,
			SUMMONER_2,
		};

		LocalCallbackAdd('Tick', function()
			self.CachedValidTargets = {};
		end);

		self.MenuIsOpen = false;
		--[[
		LocalCallbackAdd('WndMsg', function(msg, wParam)
			if wParam == 160 then
				if msg == KEY_DOWN then
					self.MenuIsOpen = not self.MenuIsOpen;
				end
			end
		end);
		]]
	end

	function __Utilities:GetAutoAttackRange(from, target)
		if from.type == Obj_AI_Minion then
			return 0;
		elseif from.type == Obj_AI_Turret then
			return 775;
		end
		local range = from.range + from.boundingRadius + (target ~= nil and (target.boundingRadius - 30) or 35);
		if self.SpecialAutoAttackRanges[from.charName] ~= nil then
			range = range + self.SpecialAutoAttackRanges[from.charName](from, target);
		end
		return range;
	end

	function __Utilities:IsMelee(unit)
		if LocalMathAbs(unit.attackData.projectileSpeed) < EPSILON then
			return true;
		end
		if self.SpecialMelees[unit.charName] ~= nil then
			return self.SpecialMelees[unit.charName](unit);
		end
		if unit.type == Obj_AI_Hero then
			return unit.range <= 275;
		else
			return false;
		end
	end

	function __Utilities:IsRanged(unit)
		return not self:IsMelee(unit);
	end

	function __Utilities:IsMonster(unit)
		return unit.team == 300;
	end

	function __Utilities:IsOtherMinion(unit)
		return unit.maxHealth <= 6;
	end

	function __Utilities:IsBaseTurret(turret)
		return self.BaseTurrets[turret.charName] ~= nil;
	end

	function __Utilities:IsSiegeMinion(minion)
		return minion.charName:find("Siege");
	end

	function __Utilities:IsObj_AI_Base(obj)
		return self.Obj_AI_Bases[obj.type] ~= nil;
	end

	function __Utilities:IsStructure(obj)
		return self.Structures[obj.type] ~= nil;
	end

	function __Utilities:IdEquals(a, b)
		if a == nil or b == nil then
			return false;
		end
		return a.networkID == b.networkID;
	end

	function __Utilities:GetDistance2DSquared(a, b)
		local x = (a.x - b.x);
		local y = (a.y - b.y);
		return x * x + y * y;
	end


	function __Utilities:GetDistanceSquared(a, b, includeY)
		if a.pos ~= nil then
			a = a.pos;
		end
		if b.pos ~= nil then
			b = b.pos;
		end
		if a.z and b.z then
			if includeY then
				local x = (a.x - b.x);
				local y = (a.y - b.y);
				local z = (a.z - b.z);
				return x * x + y * y + z * z;
			else

				local x = (a.x - b.x);
				local z = (a.z - b.z);
				return x * x + z * z;
			end
		else
			local x = (a.x - b.x);
			local y = (a.y - b.y);
			return x * x + y * y;
		end
	end

	function __Utilities:GetDistance(a, b, includeY)
		return LocalMathSqrt(self:GetDistanceSquared(a, b, includeY));
	end

	function __Utilities:IsInRange(from, target, range, includeY)
		if range == nil then
			return true;
		end
		return self:GetDistanceSquared(from, target, includeY) <= range * range;
	end

	function __Utilities:IsInAutoAttackRange(from, target, includeY)
		if from.charName == "Azir" then
			-- charName: "AzirSoldier", buffName: "azirwspawnsound", not valid
		end
		return self:IsInRange(from, target, self:GetAutoAttackRange(from, target, includeY));
	end

	function __Utilities:TotalShield(target)
		local result = target.shieldAD + target.shieldAP;
		if target.charName == "Blitzcrank" then
			if not BuffManager:HasBuff(target, "manabarriercooldown") and not BuffManager:HasBuff(target, "manabarrier") then
				result = result + target.mana * 0.5;
			end
		end
		return result;
	end

	function __Utilities:TotalShieldHealth(target)
		return target.health + self:TotalShield(target);
	end

	function __Utilities:TotalShieldMaxHealth(target)
		return target.maxHealth + self:TotalShield(target);
	end

	function __Utilities:GetLatency()
		return LocalGameLatency() * 0.001;
	end

	function __Utilities:GetHealthPercent(unit)
		return 100 * unit.health / unit.maxHealth;
	end

	function __Utilities:__IsValidTarget(target)
		if self:IsObj_AI_Base(target) then
			if not target.valid then
				return false;
			end
		end
		if target.dead or (not target.visible) or (not target.isTargetable) then
			return false;
		end
		return true;
	end

	function __Utilities:IsValidTarget(target)
		if target == nil or target.networkID == nil then
			return false;
		end
		if self.CachedValidTargets[target.networkID] == nil then
			self.CachedValidTargets[target.networkID] = self:__IsValidTarget(target);
		end
		return self.CachedValidTargets[target.networkID];
	end

	function __Utilities:IsValidMissile(missile)
		if missile == nil then
			return false;
		end
		if missile.dead then
			return false;
		end
		return true;
	end

	function __Utilities:HasUndyingBuff(target, addHealthCheck)
		if self.UndyingBuffs[target.charName] ~= nil then
			if self.UndyingBuffs[target.charName](target, addHealthCheck) then
				return true;
			end
		end
		if EnemiesInGame["Kayle"] and BuffManager:HasBuff(target, "JudicatorIntervention") then
			return true;
		end
		if EnemiesInGame["Kindred"] and BuffManager:HasBuff(target, "kindredrnodeathbuff") and (not addHealthCheck or self:GetHealthPercent(target) <= 10) then
			return true;
		end
		if EnemiesInGame["Zilean"] and (BuffManager:HasBuff(target, "ChronoShift") or BuffManager:HasBuff(target, "chronorevive")) and (not addHealthCheck or self:GetHealthPercent(target) <= 10) then
			return true;
		end
		return target.isImmortal;
	end

	function __Utilities:GetHotKeyFromSlot(slot)
		if slot ~= nil and self.SlotToHotKeys[slot] ~= nil then
			return self.SlotToHotKeys[slot]();
		end
		return nil;
	end

	function __Utilities:IsChanneling(unit)
		if self.ChannelingBuffs[unit.charName] ~= nil then
			return self.ChannelingBuffs[unit.charName](unit);
		end
		return false;
	end

	function __Utilities:GetSpellLevel(unit, slot)
		return unit:GetSpellData(slot).level;
	end

	function __Utilities:GetLevel(unit)
		return unit.levelData.lvl;
	end

	function __Utilities:GetDamageDelay()
		return 0.03;
	end

	function __Utilities:IsWindingUp(unit)
		return unit.activeSpell.valid;
	end

	function __Utilities:IsAutoAttack(name)
		return name:lower():find("basicattack");
	end

	function __Utilities:IsAutoAttacking(unit)
		if self:IsWindingUp(unit) then
			if unit.activeSpell.target > 0 then
				return not unit.isChanneling;
			end
		end
		return false;
	end

	function __Utilities:IsCastingSpell(unit)
		if self:IsWindingUp(unit) then
			return unit.isChanneling;
		end
		return false;
	end

	function __Utilities:GetSpellWindUpTime(unit)
		if self.DisableSpellWindUpTime[unit.charName] then
			return self:GetAttackDataWindUpTime(unit);
		end
		return unit.activeSpell.windup;
	end

	function __Utilities:GetSpellAnimationTime(unit)
		return unit.activeSpell.animation;
	end

	function __Utilities:GetActiveSpellSlot(unit)
		return unit.activeSpellSlot;
	end

	function __Utilities:GetActiveSpellName(unit, slot)
		return unit.activeSpell.name;
	end

	function __Utilities:GetAttackDataWindUpTime(unit)
		if self.SpecialWindUpTimes[unit.charName] ~= nil then
			local SpecialWindUpTime = self.SpecialWindUpTimes[unit.charName](unit);
			if SpecialWindUpTime then
				return SpecialWindUpTime;
			end
		end
		return unit.attackData.windUpTime;
	end

	function __Utilities:GetAttackDataAnimationTime(unit)
		return unit.attackData.animationTime;
	end

	function __Utilities:GetAttackDataEndTime(unit)
		return unit.attackData.endTime;
	end

	function __Utilities:GetAttackDataState(unit)
		return unit.attackData.state;
	end

	function __Utilities:GetAttackDataTarget(unit)
		return unit.attackData.target;
	end

	function __Utilities:GetAttackDataProjectileSpeed(unit)
		if self.SpecialMissileSpeeds[unit.charName] ~= nil then
			local projectileSpeed = self.SpecialMissileSpeeds[unit.charName](unit);
			if projectileSpeed then
				return projectileSpeed;
			end
		end
		if Utilities:IsMelee(unit) then
			return LocalMathHuge;
		end
		return unit.attackData.projectileSpeed;
	end

	function __Utilities:GetSlotFromName(unit, name)
		for i = 1, #self.Slots do
			local slot = self.Slots[i];
			local spellData = unit:GetSpellData(slot);
			if spellData ~= nil and spellData.name == name then
				return slot;
			end
		end
		return nil;
	end

class "__Linq"
	function __Linq:__init()

	end

	function __Linq:Add(t, value)
		t[#t + 1] = value;
	end

local MINION_TYPE_OTHER_MINION = 1;
local MINION_TYPE_MONSTER = 2;
local MINION_TYPE_LANE_MINION = 3;

class "__ObjectManager"
	function __ObjectManager:__init()
		local MinionMaps 		= { "SRU", "HA" };
		local MinionTeams 		= { "Chaos", "Order" };
		local MinionTypes 		= { "Melee", "Ranged", "Siege", "Super" };
		self.MinionNames = {};
		self.MinionTypesDictionary = {};
		for i = 1, #MinionMaps do
			local map = MinionMaps[i];
			for j = 1, #MinionTeams do
				local team = MinionTeams[j];
				for k = 1, #MinionTypes do
					local t = MinionTypes[k];
					if self.MinionTypesDictionary[t] == nil then
						self.MinionTypesDictionary[t] = {};
					end
					local charName = map .. "_" .. team .. "Minion" .. t;
					Linq:Add(self.MinionTypesDictionary[t], charName);
					Linq:Add(self.MinionNames, charName);
				end
			end
		end
	end

	function __ObjectManager:GetMinionType(minion)
		if Utilities:IsMonster(minion) then
			return MINION_TYPE_MONSTER;
		elseif Utilities:IsOtherMinion(minion) then
			return MINION_TYPE_OTHER_MINION;
		else
			return MINION_TYPE_LANE_MINION;
		end
	end

	function __ObjectManager:GetMinions(range)
		local result = {};
		for i = 1, LocalGameMinionCount() do
			local minion = LocalGameMinion(i);
			if Utilities:IsValidTarget(minion) and self:GetMinionType(minion) == MINION_TYPE_LANE_MINION then
				if Utilities:IsInRange(myHero, minion, range) then
					Linq:Add(result, minion);
				end
			end
		end
		return result;
	end

	function __ObjectManager:GetAllyMinions(range)
		local result = {};
		for i = 1, LocalGameMinionCount() do
			local minion = LocalGameMinion(i);
			if Utilities:IsValidTarget(minion) and minion.isAlly and self:GetMinionType(minion) == MINION_TYPE_LANE_MINION then
				if Utilities:IsInRange(myHero, minion, range) then
					Linq:Add(result, minion);
				end
			end
		end
		return result;
	end

	function __ObjectManager:GetEnemyMinions(range)
		local result = {};
		for i = 1, LocalGameMinionCount() do
			local minion = LocalGameMinion(i);
			if Utilities:IsValidTarget(minion) and minion.isEnemy and self:GetMinionType(minion) == MINION_TYPE_LANE_MINION then
				if Utilities:IsInRange(myHero, minion, range) then
					Linq:Add(result, minion);
				end
			end
		end
		return result;
	end

	function __ObjectManager:GetOtherMinions(range)
		local result = {};
		for i = 1, LocalGameWardCount() do
			local minion = LocalGameWard(i);
			if Utilities:IsValidTarget(minion) and self:GetMinionType(minion) == MINION_TYPE_OTHER_MINION then
				if Utilities:IsInRange(myHero, minion, range) then
					Linq:Add(result, minion);
				end
			end
		end
		return result;
	end

	function __ObjectManager:GetOtherAllyMinions(range)
		local result = {};
		for i = 1, LocalGameWardCount() do
			local minion = LocalGameWard(i);
			if Utilities:IsValidTarget(minion) and minion.isAlly and self:GetMinionType(minion) == MINION_TYPE_OTHER_MINION then
				if Utilities:IsInRange(myHero, minion, range) then
					Linq:Add(result, minion);
				end
			end
		end
		return result;
	end

	function __ObjectManager:GetOtherEnemyMinions(range)
		local result = {};
		for i = 1, LocalGameWardCount() do
			local minion = LocalGameWard(i);
			if Utilities:IsValidTarget(minion) and minion.isEnemy and self:GetMinionType(minion) == MINION_TYPE_OTHER_MINION then
				if Utilities:IsInRange(myHero, minion, range) then
					Linq:Add(result, minion);
				end
			end
		end
		return result;
	end

	function __ObjectManager:GetMonsters(range)
		local result = {};
		for i = 1, LocalGameMinionCount() do
			local minion = LocalGameMinion(i);
			if Utilities:IsValidTarget(minion) and self:GetMinionType(minion) == MINION_TYPE_MONSTER then
				if Utilities:IsInRange(myHero, minion, range) then
					Linq:Add(result, minion);
				end
			end
		end
		return result;
	end

	function __ObjectManager:GetHeroes(range)
		local result = {};
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i);
			if Utilities:IsValidTarget(hero) then
				if Utilities:IsInRange(myHero, hero, range) then
					Linq:Add(result, hero);
				end
			end
		end
		return result;
	end

	function __ObjectManager:GetAllyHeroes(range)
		local result = {};
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i);
			if Utilities:IsValidTarget(hero) and hero.isAlly then
				if Utilities:IsInRange(myHero, hero, range) then
					Linq:Add(result, hero);
				end
			end
		end
		return result;
	end

	function __ObjectManager:GetEnemyHeroes(range)
		local result = {};
		for i = 1, LocalGameHeroCount() do
			local hero = LocalGameHero(i);
			if Utilities:IsValidTarget(hero) and hero.isEnemy then
				if Utilities:IsInRange(myHero, hero, range) then
					Linq:Add(result, hero);
				end
			end
		end
		return result;
	end

	function __ObjectManager:GetTurrets(range)
		local result = {};
		for i = 1, LocalGameTurretCount() do
			local turret = LocalGameTurret(i);
			if Utilities:IsValidTarget(turret) then
				if Utilities:IsInRange(myHero, turret, range) then
					Linq:Add(result, turret);
				end
			end
		end
		return result;
	end

	function __ObjectManager:GetAllyTurrets(range)
		local result = {};
		for i = 1, LocalGameTurretCount() do
			local turret = LocalGameTurret(i);
			if Utilities:IsValidTarget(turret) and turret.isAlly then
				if Utilities:IsInRange(myHero, turret, range) then
					Linq:Add(result, turret);
				end
			end
		end
		return result;
	end

	function __ObjectManager:GetEnemyTurrets(range)
		local result = {};
		for i = 1, LocalGameTurretCount() do
			local turret = LocalGameTurret(i);
			if Utilities:IsValidTarget(turret) and turret.isEnemy then
				if Utilities:IsInRange(myHero, turret, range) then
					Linq:Add(result, turret);
				end
			end
		end
		return result;
	end

class "__HealthPrediction"
	function __HealthPrediction:__init()
		self.IncomingAttacks = {}; -- networkID => [__IncomingAttack]
		self.AlliesState = {}; -- networkID => state
		self.AlliesTarget = {}; -- handle => boolean
		LocalCallbackAdd('Tick', function()
			self:OnTick();
		end);
	end

	function __HealthPrediction:OnTick()
		local newAlliesState = {};
		local newAlliesTarget = {};
		local t = ObjectManager:GetAllyMinions(1500);
		for i = 1, #t do
			local minion = t[i];
			self:CheckNewState(minion);
			newAlliesState[minion.networkID] = Utilities:GetAttackDataState(minion);
			local target = Utilities:GetAttackDataTarget(minion);
			if target ~= nil and target > 0 then
				newAlliesTarget[target] = true;
			end
		end
		local t = ObjectManager:GetAllyTurrets(1500);
		for i = 1, #t do
			local turret = t[i];
			self:CheckNewState(turret);
			newAlliesState[turret.networkID] = Utilities:GetAttackDataState(turret);
			local target = Utilities:GetAttackDataTarget(turret);
			if target ~= nil and target > 0 then
				newAlliesTarget[target] = true;
			end
		end
		self.AlliesState = newAlliesState;
		self.AlliesTarget = newAlliesTarget;
		local removeFromIncomingAttacks = {};
		local removeFromAttacks = {};
		-- remove older attacks
		for networkID, attacks in pairs(self.IncomingAttacks) do
			if #attacks > 0 then
				removeFromAttacks = {};
				for i = 1, #attacks do
					if attacks[i]:ShouldRemove() then
						Linq:Add(removeFromAttacks, i);
					end
				end
				for i = 1, #removeFromAttacks do
					table.remove(attacks, removeFromAttacks[i]);
				end
			else
				Linq:Add(removeFromIncomingAttacks, networkID);
			end
		end
		for i = 1, #removeFromIncomingAttacks do
			table.remove(self.IncomingAttacks, removeFromIncomingAttacks[i]);
		end
	end

	function __HealthPrediction:CheckNewState(unit)
		local currentState = Utilities:GetAttackDataState(unit);
		local prevState = self.AlliesState[unit.networkID];
		if prevState ~= nil then
			if prevState ~= STATE_WINDUP and currentState == STATE_WINDUP then
				self:OnBasicAttack(unit);
			end
		end
	end

	function __HealthPrediction:OnBasicAttack(sender)
		local target = Utilities:GetAttackDataTarget(sender);
		if target == nil or target <= 0 then
			return;
		end
		if Utilities:IsBaseTurret(sender) then -- fps drops
			return;
		end
		if not Utilities:IsInRange(myHero, sender, 1500) then
			return;
		end
		if self.IncomingAttacks[sender.networkID] == nil then
			self.IncomingAttacks[sender.networkID] = {};
		else
			local t = self.IncomingAttacks[sender.networkID];
			for i = 1, #t do
				t[i].IsActiveAttack = false;
			end
		end
		Linq:Add(self.IncomingAttacks[sender.networkID], __IncomingAttack(sender));
	end

	function __HealthPrediction:GetPrediction(target, time)
		local health = Utilities:TotalShieldHealth(target);
		for _, attacks in pairs(self.IncomingAttacks) do
			if #attacks > 0 then
				for i = 1, #attacks do
					local attack = attacks[i];
					if attack:EqualsTarget(target) then
						health = health - attack:GetPredictedDamage(target, time, true);
					end
				end
			end
		end
		return health;
	end

class "__IncomingAttack"
	function __IncomingAttack:__init(source)
		self.Source = source;
		self.TargetHandle = Utilities:GetAttackDataTarget(self.Source);
		self.SourceIsValid = true;
		self.boundingRadius = 0;--self.Source.boundingRadius;
		self.Arrived = false;
		self.Invalid = false;
		self.IsActiveAttack = true;
		self.SourceIsMelee = Utilities:IsMelee(self.Source);
		self.MissileSpeed = self.SourceIsMelee and LocalMathHuge or Utilities:GetAttackDataProjectileSpeed(self.Source);
		self.SourcePosition = self.Source.pos;
		self.WindUpTime = Utilities:GetAttackDataWindUpTime(self.Source);
		self.AnimationTime = Utilities:GetAttackDataAnimationTime(self.Source);
		self.StartTime = Utilities:GetAttackDataEndTime(self.Source) - self.AnimationTime;--LocalGameTimer();
	end

	function __IncomingAttack:GetAutoAttackDamage(target)
		if self.AutoAttackDamage == nil then
			self.AutoAttackDamage = Damage:GetAutoAttackDamage(self.Source, target);
		end
		return self.AutoAttackDamage;
	end

	function __IncomingAttack:GetMissileTime(target)
		if self.SourceIsMelee then
			return 0;
		end
		return LocalMathMax(Utilities:GetDistance(self.SourcePosition, target, true) - self.boundingRadius, 0) / self.MissileSpeed;
	end

	function __IncomingAttack:GetArrivalTime(target)
		return self.StartTime + self.WindUpTime + self:GetMissileTime(target) + Utilities:GetDamageDelay();
	end

	function __IncomingAttack:GetMissileCreationTime()
		return self.StartTime + self.WindUpTime;
	end

	function __IncomingAttack:EqualsTarget(target)
		return target.handle == self.TargetHandle;
	end

	function __IncomingAttack:ShouldRemove()
		return self.Invalid or LocalGameTimer() - self.StartTime > 3;-- or self.Arrived;
	end

	function __IncomingAttack:GetPredictedDamage(target, delay, addNextAutoAttacks)
		local damage = 0;
		if not self:ShouldRemove() then
			delay = delay + Utilities:GetLatency() - 0.1;
			local CurrentTime = LocalGameTimer();
			local timeTillHit = self:GetArrivalTime(target) - CurrentTime;
			if timeTillHit < 0 then
				self.Arrived = true;
			end
			if not self.Arrived then
				local count = 0;
				local willHit = timeTillHit < delay and timeTillHit > 0;
				if Utilities:IsValidTarget(self.Source) then
					if self.IsActiveAttack then
						if addNextAutoAttacks then
							while timeTillHit < delay do
								if timeTillHit > 0 then
									count = count + 1;
								end
								timeTillHit = timeTillHit + self.AnimationTime;
							end
						else
							if willHit then
								count = count + 1;
							end
						end
					else
						if not self.SourceIsMelee then
							if willHit then
								count = count + 1;
							end
						end
					end
				else
					if not self.SourceIsMelee then
						if CurrentTime >= self:GetMissileCreationTime() then
							if willHit then
								count = count + 1;
							end
						else
							self.Invalid = true;
						end
					else
						self.Invalid = true;
					end
				end
				if count > 0 then
					damage = damage + self:GetAutoAttackDamage(target) * count;
				end
			end
		end
		return damage;
	end

	function __IncomingAttack:Draw(target)
		local damage = 0;
		if not self:ShouldRemove() then
			local timeTillHit = self.StartTime + self.WindUpTime + self:GetMissileTime(target) - LocalGameTimer();
			if timeTillHit <= 0 and timeTillHit > -0.25 then
				LocalDrawText("Will Hit: " .. timeTillHit, target.pos:To2D());
			end
		end
	end

class "__TargetSelector"
	function __TargetSelector:__init()
		self.Loaded = false;
		self.Menu = MenuElement({ id = "TargetSelector", name = "IC's Target Selector", type = MENU });
		self.EnemiesAdded = {};
		self.SelectedTarget = nil;
		self.Modes = {
			"Auto",
			"Most Stack",
			"Most Attack Damage",
			"Most Magic Damage",
			"Least Health",
			"Closest",
			"Highest Priority",
			"Less Attack",
			"Less Cast",
			"Near Mouse",
		};
		self.Priorities = {
			["Aatrox"] = 2,
			["Ahri"] = 4,
			["Akali"] = 3,
			["Alistar"] = 1,
			["Amumu"] = 1,
			["Anivia"] = 4,
			["Annie"] = 4,
			["Ashe"] = 4,
			["AurelionSol"] = 4,
			["Azir"] = 4,
			["Bard"] = 1,
			["Blitzcrank"] = 1,
			["Brand"] = 4,
			["Braum"] = 1,
			["Caitlyn"] = 4,
			["Cassiopeia"] = 4,
			["Chogath"] = 2,
			["Corki"] = 4,
			["Darius"] = 2,
			["Diana"] = 3,
			["Draven"] = 4,
			["DrMundo"] = 1,
			["Ekko"] = 4,
			["Elise"] = 2,
			["Evelynn"] = 2,
			["Ezreal"] = 4,
			["Fiddlesticks"] = 3,
			["Fiora"] = 3,
			["Fizz"] = 3,
			["Galio"] = 2,
			["Gangplank"] = 2,
			["Garen"] = 1,
			["Gnar"] = 1,
			["Gragas"] = 2,
			["Graves"] = 4,
			["Hecarim"] = 1,
			["Heimerdinger"] = 3,
			["Illaoi"] =  2,
			["Irelia"] = 2,
			["Ivern"] = 2,
			["Janna"] = 1,
			["JarvanIV"] = 1,
			["Jax"] = 2,
			["Jayce"] = 3,
			["Jhin"] = 4,
			["Jinx"] = 4,
			["Kalista"] = 4,
			["Karma"] = 4,
			["Karthus"] = 4,
			["Kassadin"] = 3,
			["Katarina"] = 4,
			["Kayle"] = 3,
			["Kennen"] = 4,
			["Khazix"] = 3,
			["Kindred"] = 4,
			["Kled"] = 2,
			["KogMaw"] = 4,
			["Leblanc"] = 4,
			["LeeSin"] = 2,
			["Leona"] = 1,
			["Lissandra"] = 3,
			["Lucian"] = 4,
			["Lulu"] = 1,
			["Lux"] = 4,
			["Malphite"] = 1,
			["Malzahar"] = 4,
			["Maokai"] = 2,
			["MasterYi"] = 4,
			["MissFortune"] = 4,
			["MonkeyKing"] = 1,
			["Mordekaiser"] = 3,
			["Morgana"] = 2,
			["Nami"] = 1,
			["Nasus"] = 1,
			["Nautilus"] = 1,
			["Nidalee"] = 3,
			["Nocturne"] = 2,
			["Nunu"] = 1,
			["Olaf"] = 1,
			["Orianna"] = 4,
			["Pantheon"] = 2,
			["Poppy"] = 2,
			["Quinn"] = 4,
			["Rammus"] = 1,
			["RekSai"] = 2,
			["Renekton"] = 1,
			["Rengar"] = 2,
			["Riven"] = 3,
			["Rumble"] = 2,
			["Ryze"] = 2,
			["Sejuani"] = 1,
			["Shaco"] = 3,
			["Shen"] = 1,
			["Shyvana"] = 1,
			["Singed"] = 1,
			["Sion"] = 1,
			["Sivir"] = 4,
			["Skarner"] = 1,
			["Sona"] = 1,
			["Soraka"] = 4,
			["Swain"] = 2,
			["Syndra"] = 4,
			["TahmKench"] = 1,
			["Taliyah"] = 3,
			["Talon"] = 4,
			["Taric"] = 1,
			["Teemo"] = 4,
			["Thresh"] = 1,
			["Tristana"] = 4,
			["Trundle"] = 2,
			["Tryndamere"] = 2,
			["TwistedFate"] = 4,
			["Twitch"] = 4,
			["Udyr"] = 2,
			["Urgot"] = 2,
			["Varus"] = 4,
			["Vayne"] = 4,
			["Veigar"] = 4,
			["Velkoz"] = 4,
			["Vi"] = 2,
			["Viktor"] = 4,
			["Vladimir"] = 3,
			["Volibear"] = 1,
			["Warwick"] = 1,
			["Xerath"] = 4,
			["XinZhao"] = 2,
			["Yasuo"] = 3,
			["Yorick"] = 1,
			["Zac"] = 1,
			["Zed"] = 4,
			["Ziggs"] = 4,
			["Zilean"] = 3,
			["Zyra"] = 1,
		};
		self.BuffStackNames = {
			["All"]			= { "BraumMark" },
			["Darius"]		= { "DariusHemo" },
			["Ekko"]		= { "EkkoStacks" },
			["Gnar"]		= { "GnarWProc" },
			["Kalista"]		= { "KalistaExpungeMarker" },
			["Kennen"]		= { "kennenmarkofstorm" },
			["Kindred"]		= { "KindredHitCharge", "kindredecharge" },
			["TahmKench"]	= { "tahmkenchpdebuffcounter" },
			["Tristana"]	= { "tristanaecharge" },
			["Twitch"]		= { "TwitchDeadlyVenom" },
			["Varus"]		= { "VarusWDebuff" },
			["Vayne"]		= { "VayneSilverDebuff" },
			["Velkoz"]		= { "VelkozResearchStack" },
			["Vi"]			= { "ViWProc" },	
		};
		self.Selector = {
			[TARGET_SELECTOR_MODE_AUTO] = function(targets, damageType)
				LocalTableSort(targets, function(a, b)
					local first = self:GetReductedPriority(a) * Damage:CalculateDamage(myHero, a, (damageType == DAMAGE_TYPE_MAGICAL) and DAMAGE_TYPE_MAGICAL or DAMAGE_TYPE_PHYSICAL, 100) / a.health;
					local second = self:GetReductedPriority(b) * Damage:CalculateDamage(myHero, b, (damageType == DAMAGE_TYPE_MAGICAL) and DAMAGE_TYPE_MAGICAL or DAMAGE_TYPE_PHYSICAL, 100) / b.health;
					return first > second;
				end);
				return targets[1];
			end,
			[TARGET_SELECTOR_MODE_MOST_STACK] = function(targets, damageType)
				LocalTableSort(targets, function(a, b)
					local firstStack = 1;
					local secondStack = 1;
					local t = self.BuffStackNames["All"];
					for i = 1, #t do
						local buffName = t[i];
						firstStack = firstStack + LocalMathMax(0, BuffManager:GetBuffCount(a, buffName));
						secondStack = secondStack + LocalMathMax(0, BuffManager:GetBuffCount(b, buffName));
					end
					if self.BuffStackNames[myHero.charName] ~= nil then
						local t = self.BuffStackNames[myHero.charName];
						for i = 1, #t do
							local buffName = t[i];
							firstStack = firstStack + LocalMathMax(0, BuffManager:GetBuffCount(a, buffName)); 
							secondStack = secondStack + LocalMathMax(0, BuffManager:GetBuffCount(b, buffName));
						end
					end
					local first = firstStack * self:GetReductedPriority(a) * Damage:CalculateDamage(myHero, a, (damageType == DAMAGE_TYPE_MAGICAL) and DAMAGE_TYPE_MAGICAL or DAMAGE_TYPE_PHYSICAL, 100) / a.health;
					local second = secondStack * self:GetReductedPriority(b) * Damage:CalculateDamage(myHero, b, (damageType == DAMAGE_TYPE_MAGICAL) and DAMAGE_TYPE_MAGICAL or DAMAGE_TYPE_PHYSICAL, 100) / b.health;
					return first > second;
				end);
				return targets[1];
			end,
			[TARGET_SELECTOR_MODE_MOST_ATTACK_DAMAGE] = function(targets, damageType)
				LocalTableSort(targets, function(a, b)
					local first = a.totalDamage;
					local second = b.totalDamage;
					return first > second;
				end);
				return targets[1];
			end,
			[TARGET_SELECTOR_MODE_MOST_MAGIC_DAMAGE] = function(targets, damageType)
				LocalTableSort(targets, function(a, b)
					local first = a.ap;
					local second = b.ap;
					return first > second;
				end);
				return targets[1];
			end,
			[TARGET_SELECTOR_MODE_LEAST_HEALTH] = function(targets, damageType)
				LocalTableSort(targets, function(a, b)
					local first = a.health;
					local second = b.health;
					return first < second;
				end);
				return targets[1];
			end,
			[TARGET_SELECTOR_MODE_CLOSEST] = function(targets, damageType)
				LocalTableSort(targets, function(a, b)
					local first = Utilities:GetDistanceSquared(myHero, a);
					local second = Utilities:GetDistanceSquared(myHero, b);
					return first < second;
				end);
				return targets[1];
			end,
			[TARGET_SELECTOR_MODE_HIGHEST_PRIORITY] = function(targets, damageType)
				LocalTableSort(targets, function(a, b)
					local first = self:GetPriority(a);
					local second = self:GetPriority(b);
					return first > second;
				end);
				return targets[1];
			end,
			[TARGET_SELECTOR_MODE_LESS_ATTACK] = function(targets, damageType)
				LocalTableSort(targets, function(a, b)
					local first = self:GetReductedPriority(a) * Damage:CalculateDamage(myHero, a, DAMAGE_TYPE_PHYSICAL, 100) / a.health;
					local second = self:GetReductedPriority(b) * Damage:CalculateDamage(myHero, b, DAMAGE_TYPE_PHYSICAL, 100) / b.health;
					return first > second;
				end);
				return targets[1];
			end,
			[TARGET_SELECTOR_MODE_LESS_CAST] = function(targets, damageType)
				LocalTableSort(targets, function(a, b)
					local first = self:GetReductedPriority(a) * Damage:CalculateDamage(myHero, a, DAMAGE_TYPE_MAGICAL, 100) / a.health;
					local second = self:GetReductedPriority(b) * Damage:CalculateDamage(myHero, b, DAMAGE_TYPE_MAGICAL, 100) / b.health;
					return first > second;
				end);
				return targets[1];
			end,
			[TARGET_SELECTOR_MODE_NEAR_MOUSE] = function(targets, damageType)
				LocalTableSort(targets, function(a, b)
					local first = Utilities:GetDistanceSquared(a, _G.mousePos);
					local second = Utilities:GetDistanceSquared(b, _G.mousePos);
					return first < second;
				end);
				return targets[1];
			end,
		};
		AddLoadCallback(function()
			self:OnLoad();
		end);
	end

	function __TargetSelector:OnLoad()
		self.Menu:MenuElement({ id = "Mode", name = "Mode", value = 1, drop = self.Modes });
		self.Menu:MenuElement({ id = "Priorities", name = "Priorities", type = MENU });
		local EnemyHeroes = {};
		if LocalGameHeroCount() > 0 then
			for i = 1, LocalGameHeroCount() do
				local hero = LocalGameHero(i);
				if hero.isEnemy and not hero.isAlly then
					Linq:Add(EnemyHeroes, hero);
				end
			end
		end
		if #EnemyHeroes > 0 then
			for i = 1, #EnemyHeroes do
				local hero = EnemyHeroes[i];
				if self.EnemiesAdded[hero.charName] == nil then
					self.EnemiesAdded[hero.charName] = true;
					local priority = self.Priorities[hero.charName] ~= nil and self.Priorities[hero.charName] or 1;
					self.Menu.Priorities:MenuElement({ id = hero.charName, name = hero.charName, value = priority, min = 1, max = 5, step = 1 });
				end
			end
			self.Menu.Priorities:MenuElement({ id = "Reset", name = "Reset priorities to default values", value = false, callback = function()
				if self.Loaded then
					if self.Menu.Priorities.Reset:Value() then
						for charName, _ in pairs(self.EnemiesAdded) do
							local priority = self.Priorities[charName] ~= nil and self.Priorities[charName] or 1;
							self.Menu.Priorities[charName]:Value(priority);
						end
						self.Menu.Priorities.Reset:Value(false);
					end
				end
			end });
		end

		self.Menu:MenuElement({ id = "Advanced", name = "Advanced", type = MENU });
			self.Menu.Advanced:MenuElement({ id = "SelectedTarget", name = "Enable Select Target Manually", value = true });
			--TODO

		self.Menu:MenuElement({ id = "Drawings", name = "Drawings", type = MENU });
			self.Menu.Drawings:MenuElement({ id = "SelectedTarget", name = "Draw circle around Selected Target", value = true });
		
		LocalCallbackAdd('Draw', function()
			self:OnDraw();
		end);
		LocalCallbackAdd('WndMsg', function(msg, wParam)
			self:OnWndMsg(msg, wParam);
		end);
		self.Loaded = true;
	end

	function __TargetSelector:OnDraw()
		if self.Menu.Drawings.SelectedTarget:Value() then
			if self.SelectedTarget ~= nil and Utilities:IsValidTarget(self.SelectedTarget) then
				LocalDrawCircle(self.SelectedTarget.pos, 120, 4, COLOR_RED);
			end
		end
	end

	function __TargetSelector:OnWndMsg(msg, wParam)
		if msg == WM_LBUTTONDOWN then
			if self.Menu.Advanced.SelectedTarget:Value() and not Utilities.MenuIsOpen then
				local t = ObjectManager:GetEnemyHeroes();
				for i = 1, #t do
					local hero = t[i];
					if Utilities:IsInRange(hero.pos:To2D(), _G.cursorPos, 100) then
						self.SelectedTarget = hero;
						break;
					end
				end
			end
		end
		if msg == KEY_DOWN then

		end
	end

	function __TargetSelector:GetPriority(target)
		if self.EnemiesAdded[target.charName] ~= nil then
			return self.Menu.Priorities[target.charName]:Value();
		end
		return self.Priorities[target.charName] ~= nil and self.Priorities[target.charName] or 1;
	end

	function __TargetSelector:GetReductedPriority(target)
		local priority = self:GetPriority(target);
		if priority == 5 then
			return 2.5;
		elseif priority == 4 then
			return 2;
		elseif priority == 3 then
			return 1.75;
		elseif priority == 2 then
			return 1.5;
		elseif priority == 1 then
			return 1;
		end
	end

	function __TargetSelector:GetTarget(a, damageType, from, addBoundingRadius)
		if type(a) == "table" then
			local targets = a;
			local validTargets = {};
			for i = 1, #targets do
				local target = targets[i];
				if not Utilities:HasUndyingBuff(target) then
					Linq:Add(validTargets, target);
				end
			end
			if #validTargets > 0 then
				targets = validTargets;
			end
			if #targets == 0 then
				return nil;
			end
			if #targets == 1 then
				return targets[1];
			end
			if Utilities:IsValidTarget(self.SelectedTarget) then
				for i = 1, #targets do
					if Utilities:IdEquals(targets[i], self.SelectedTarget) then
						return self.SelectedTarget;
					end
				end
			end
			local Mode = self.Menu.Mode:Value();
			if self.Selector[Mode] ~= nil then
				return self.Selector[Mode](targets, damageType);
			end
		else
			local range = a;
			local from = from ~= nil and from or myHero;
			local t = {};
			local enemies = ObjectManager:GetEnemyHeroes();
			for i = 1, #enemies do
				local enemy = enemies[i];
				if Utilities:IsInRange(from, enemy, range) then
					Linq:Add(t, enemy);
				end
			end
			return self:GetTarget(t, damageType);
		end
		return nil;
	end

local ORBWALKER_MODE_NONE				= _G.SDK.ORBWALKER_MODE_NONE;
local ORBWALKER_MODE_COMBO				= _G.SDK.ORBWALKER_MODE_COMBO;
local ORBWALKER_MODE_HARASS				= _G.SDK.ORBWALKER_MODE_HARASS;
local ORBWALKER_MODE_LANECLEAR			= _G.SDK.ORBWALKER_MODE_LANECLEAR;
local ORBWALKER_MODE_JUNGLECLEAR		= _G.SDK.ORBWALKER_MODE_JUNGLECLEAR;
local ORBWALKER_MODE_LASTHIT			= _G.SDK.ORBWALKER_MODE_LASTHIT;
local ORBWALKER_MODE_FLEE				= _G.SDK.ORBWALKER_MODE_FLEE;

local ORBWALKER_TARGET_TYPE_HERO			= 0;
local ORBWALKER_TARGET_TYPE_MONSTER			= 1;
local ORBWALKER_TARGET_TYPE_LANE_MINION		= 2;
local ORBWALKER_TARGET_TYPE_OTHER_MINION	= 3;
local ORBWALKER_TARGET_TYPE_STRUCTURE		= 4;

class "__Orbwalker"
	function __Orbwalker:__init()
		self.Menu = MenuElement({ id = "IC's Orbwalker 2", name = "IC's Orbwalker", type = MENU });

		self.Loaded = false;

		self.DamageOnMinions = {};
		self.LastHitMinion = nil;
		self.AlmostLastHitMinion = nil;
		self.LaneClearMinion = nil;
		self.StaticAutoAttackDamage = nil;

		self.EnemyStructures = {};

		self.LastAutoAttackSent = 0;
		self.LastMovementSent = 0;
		self.LastShouldWait = 0;
		self.ForceTarget = nil;
		self.ForceMovement = nil;

		self.IsNone = false;
		self.OnlyLastHit = false;

		self.MyHeroIsAutoAttacking = false;
		self.MyHeroState = STATE_ATTACK;

		self.MyHeroAttacks = {};

		self.FastKiting = false;
		self.AutoAttackResetted = false;
		self.AutoAttackResetCastTime = 0;

		self.MenuKeys = {
			[ORBWALKER_MODE_COMBO] = {},
			[ORBWALKER_MODE_HARASS] = {},
			[ORBWALKER_MODE_LANECLEAR] = {},
			[ORBWALKER_MODE_JUNGLECLEAR] = {},
			[ORBWALKER_MODE_LASTHIT] = {},
			[ORBWALKER_MODE_FLEE] = {},
		};

		self.Modes = {
			[ORBWALKER_MODE_COMBO] = false,
			[ORBWALKER_MODE_HARASS] = false,
			[ORBWALKER_MODE_LANECLEAR] = false,
			[ORBWALKER_MODE_JUNGLECLEAR] = false,
			[ORBWALKER_MODE_LASTHIT] = false,
			[ORBWALKER_MODE_FLEE] = false,
		};

		self.OnUnkillableMinionCallbacks = {};
		self.OnPreAttackCallbacks = {};
		self.OnPreMovementCallbacks = {};
		self.OnAttackCallbacks = {};
		self.OnPostAttackCallbacks = {};

		self.HoldPosition = nil;
		self.LastHoldPosition = 0;

		self.LastMinionHealth = {};
		self.LastMinionDraw = {};

		self.ExtraWindUpTimes = {

		};

		self.AttackDataWindUpTime = 0;
		self.SpellWindUpTime = 0;
		self.AttackDataAnimationTime = 0;
		self.SpellAnimationTime = 0;

		self.AllowMovement = {
			["Lucian"] = function(unit)
				return BuffManager:HasBuff(unit, "LucianR");
			end,
			["Varus"] = function(unit)
				return BuffManager:HasBuff(unit, "VarusQ");
			end,
			["Vi"] = function(unit)
				return BuffManager:HasBuff(unit, "ViQ");
			end,
			["Vladimir"] = function(unit)
				return BuffManager:HasBuff(unit, "VladimirE");
			end,
			["Xerath"] = function(unit)
				return BuffManager:HasBuff(unit, "XerathArcanopulseChargeUp");
			end,
		};
		self.DisableAutoAttack = {
			["Darius"] = function(unit)
				return BuffManager:HasBuff(unit, "dariusqcast");
			end,
			["Graves"] = function(unit)
				if LocalMathAbs(unit.hudAmmo) < EPSILON then
					return true;
				end
				return false;
			end,
			["Jhin"] = function(unit)
				if BuffManager:HasBuff(unit, "JhinPassiveReload") then
					return true;
				end
				if LocalMathAbs(unit.hudAmmo) < EPSILON then
					return true;
				end
				return false;
			end,
		};
		self.SupportHeroes = {
			["Alistar"]			= true,
			["Bard"]			= true,
			["Braum"]			= true,
			["Janna"]			= true,
			["Karma"]			= true,
			["Leona"]			= true,
			["Lulu"]			= true,
			["Morgana"]			= true,
			["Nami"]			= true,
			["Sona"]			= true,
			["Soraka"]			= true,
			["TahmKench"]		= true,
			["Taric"]			= true,
			["Thresh"]			= true,
			["Zilean"]			= true,
			["Zyra"]			= true,
		};

		self.AutoAttackResets = {
			["Blitzcrank"] = { Slot = _E },
			["Camille"] = { Slot = _Q },
			["Darius"] = { Slot = _W },
			["DrMundo"] = { Slot = _E },
			["Elise"] = { Slot = _W, Name = "EliseSpiderW"},
			["Fiora"] = { Slot = _E },
			["Gangplank"] = { Slot = _Q },
			["Garen"] = { Slot = _Q },
			["Graves"] = { Slot = _E },
			["Kassadin"] = { Slot = _W },
			["Illaoi"] = { Slot = _W },
			["Jax"] = { Slot = _W },
			["Jayce"] = { Slot = _W, Name = "JayceHyperCharge"},
			["Katarina"] = { Slot = _E },
			["Kindred"] = { Slot = _Q },
			["Leona"] = { Slot = _Q },
			["Lucian"] = { Slot = _E },
			["MasterYi"] = { Slot = _W },
			["Mordekaiser"] = { Slot = _Q },
			["Nautilus"] = { Slot = _W },
			["Nidalee"] = { Slot = _Q, Name = "Takedown" },
			["Nasus"] = { Slot = _Q },
			["RekSai"] = { Slot = _Q, Name = "RekSaiQ" },
			["Renekton"] = { Slot = _W },
			["Rengar"] = { Slot = _Q },
			["Riven"] = { Slot = _Q },
			["Sejuani"] = { Slot = _W },
			["Sivir"] = { Slot = _W },
			["Talon"] = { Slot = _Q },
			["Teemo"] = { Slot = _Q },
			["Trundle"] = { Slot = _Q },
			["Vayne"] = { Slot = _Q },
			["Vi"] = { Slot = _E },
			["Volibear"] = { Slot = _Q },
			["MonkeyKing"] = { Slot = _Q },
			["XinZhao"] = { Slot = _Q },
			["Yorick"] = { Slot = _Q },
		};

		self.TargetByType = {
			[ORBWALKER_TARGET_TYPE_HERO] = function()
				if myHero.charName == "Azir" then
					--TODO
				end
				local targets = {};
				local t = ObjectManager:GetEnemyHeroes(1500);
				for i = 1, #t do
					local hero = t[i];
					if Utilities:IsInAutoAttackRange(myHero, hero) then
						Linq:Add(targets, hero);
					end
				end
				return TargetSelector:GetTarget(targets, DAMAGE_TYPE_PHYSICAL);
			end,
			[ORBWALKER_TARGET_TYPE_MONSTER] = function()
				local t = ObjectManager:GetMonsters(1500);
				LocalTableSort(t, function(a, b)
					return a.maxHealth > b.maxHealth;
				end);
				for i = 1, #t do
					local minion = t[i];
					if Utilities:IsInAutoAttackRange(myHero, minion) then
						return minion;
					end
				end
				return nil;
			end,
			[ORBWALKER_TARGET_TYPE_LANE_MINION] = function()
				local SupportMode = false;
				if self.Menu.General["SupportMode." .. myHero.charName]:Value() then
					local t = ObjectManager:GetAllyHeroes(1500);
					for i = 1, #t do
						local hero = t[i];
						if not hero.isMe then
							SupportMode = true;
							break;
						end
					end
				end
				if (not SupportMode) or (BuffManager:GetBuffCount(myHero, "TalentReaper") > 0) then
					if self.LastHitMinion ~= nil then
						if self.AlmostLastHitMinion ~= nil and not Utilities:IdEquals(self.AlmostLastHitMinion, self.LastHitMinion) and Utilities:IsSiegeMinion(self.AlmostLastHitMinion) then
							return nil;
						end
						return self.LastHitMinion;
					end
					if self:ShouldWait() or self.OnlyLastHit then
						return nil;
					end
					return (not SupportMode) and self.LaneClearMinion or nil;
				end
			end,
			[ORBWALKER_TARGET_TYPE_OTHER_MINION] = function()
				local t = ObjectManager:GetOtherEnemyMinions(1500);
				LocalTableSort(t, function(a, b)
					return a.health < b.health;
				end);
				for i = 1, #t do
					local minion = t[i];
					if Utilities:IsInAutoAttackRange(myHero, minion) then
						return minion;
					end
				end
				return nil;
			end,
			[ORBWALKER_TARGET_TYPE_STRUCTURE] = function()
				for i = 1, #self.EnemyStructures do
					local structure = self.EnemyStructures[i];
					if Utilities:IsValidTarget(structure) and Utilities:IsInRange(myHero, structure, Utilities:GetAutoAttackRange(myHero, structure)) then
						return structure;
					end
				end
				return nil;
			end,
		};

		AddLoadCallback(function()
			self:OnLoad();
		end);
	end

	function __Orbwalker:OnLoad()
		if LocalGameObjectCount() > 0 then
			for i = 1, LocalGameObjectCount() do
				local object = LocalGameObject(i);
				if object ~= nil and object.isEnemy and Utilities:IsStructure(object) then
					Linq:Add(self.EnemyStructures, object);
				end
			end
		end
			
		self.Menu:MenuElement({ id = "Keys", name = "Keys Settings", type = MENU });
			self.Menu.Keys:MenuElement({ id = "Combo", name = "Combo", key = string.byte(" ") });
			self:RegisterMenuKey(ORBWALKER_MODE_COMBO, self.Menu.Keys.Combo);
			self.Menu.Keys:MenuElement({ id = "Harass", name = "Harass", key = string.byte("C") });
			self:RegisterMenuKey(ORBWALKER_MODE_HARASS, self.Menu.Keys.Harass);
			self.Menu.Keys:MenuElement({ id = "LaneClear", name = "Lane Clear", key = string.byte("V") });
			self:RegisterMenuKey(ORBWALKER_MODE_LANECLEAR, self.Menu.Keys.LaneClear);
			self.Menu.Keys:MenuElement({ id = "JungleClear", name = "Jungle Clear", key = string.byte("V") });
			self:RegisterMenuKey(ORBWALKER_MODE_JUNGLECLEAR, self.Menu.Keys.JungleClear);
			self.Menu.Keys:MenuElement({ id = "LastHit", name = "Last Hit", key = string.byte("X") });
			self:RegisterMenuKey(ORBWALKER_MODE_LASTHIT, self.Menu.Keys.LastHit);
			self.Menu.Keys:MenuElement({ id = "Flee", name = "Flee", key = string.byte("T") });
			self:RegisterMenuKey(ORBWALKER_MODE_FLEE, self.Menu.Keys.Flee);

		self.Menu:MenuElement({ id = "General", name = "General Settings", type = MENU });
			self.Menu.General:MenuElement({ id = "FastKiting", name = "Fast Kiting", value = true });
			self.Menu.General:MenuElement({ id = "LaneClearHeroes", name = "Attack heroes in Lane Clear mode", value = true });
			self.Menu.General:MenuElement({ id = "StickToTarget", name = "Stick to target (only melee)", value = true });
			self.Menu.General:MenuElement({ id = "MovementDelay", name = "Movement Delay", value = 250, min = 0, max = 1000, step = 25 });
			self.Menu.General:MenuElement({ id = "SupportMode." .. myHero.charName, name = "Support Mode", value = self.SupportHeroes[myHero.charName] ~= nil });
			self.Menu.General:MenuElement({ id = "HoldRadius", name = "Hold Radius", value = 120, min = 100, max = 250, step = 10 });
			self.Menu.General:MenuElement({ id = "ExtraWindUpTime", name = "Extra WindUpTime", value = 0, min = 0, max = 200, step = 20 });

		self.Menu:MenuElement({ id = "Farming", name = "Farming Settings", type = MENU });
			self.Menu.Farming:MenuElement({ id = "LastHitPriority", name = "Priorize Last Hit over Harass", value = true });
			self.Menu.Farming:MenuElement({ id = "PushPriority", name = "Priorize Push over Freeze", value = true });
			self.Menu.Farming:MenuElement({ id = "ExtraFarmDelay", name = "ExtraFarmDelay", value = 0, min = -80, max = 80, step = 10 });
			self.Menu.Farming:MenuElement({ id = "Tiamat", name = "Use Tiamat/Hydra on unkillable minions", value = true });

		self.Menu:MenuElement({ id = "Drawings", name = "Drawings Settings", type = MENU });
			self.Menu.Drawings:MenuElement({ id = "Range", name = "AutoAttack Range", value = true });
			self.Menu.Drawings:MenuElement({ id = "EnemyRange", name = "Enemy AutoAttack Range", value = true });
			self.Menu.Drawings:MenuElement({ id = "HoldRadius", name = "Hold Radius", value = false });
			self.Menu.Drawings:MenuElement({ id = "LastHittableMinions", name = "Last Hittable Minions", value = true });
		
		LocalCallbackAdd('Tick', function()
			self:OnTick();
		end);
		LocalCallbackAdd('Draw', function()
			self:OnDraw();
		end);
		LocalCallbackAdd('Draw', function()
			self:OnUpdate();
		end);

		self.Loaded = true;
	end

	function __Orbwalker:Clear()
		self.DamageOnMinions = {};
		self.LastHitMinion = nil;
		self.AlmostLastHitMinion = nil;
		self.LaneClearMinion = nil;
		self.StaticAutoAttackDamage = nil;
	end

	function __Orbwalker:OnUpdate()
		if Utilities:IsAutoAttacking(myHero) then
			self.AttackDataWindUpTime = Utilities:GetAttackDataWindUpTime(myHero);
			self.SpellWindUpTime = Utilities:GetSpellWindUpTime(myHero);
			self.AttackDataAnimationTime = Utilities:GetAttackDataAnimationTime(myHero);
			self.SpellAnimationTime = Utilities:GetSpellAnimationTime(myHero);
		end

		local AutoAttackReset = self.AutoAttackResets[myHero.charName];
		if AutoAttackReset ~= nil then
			local castTime = myHero:GetSpellData(AutoAttackReset.Slot).castTime;
			if castTime > self.AutoAttackResetCastTime then
				if self.AutoAttackResetCastTime > 0 then
					local name = AutoAttackReset["Name"];
					if name == nil or name == myHero:GetSpellData(AutoAttackReset.Slot).name then
						self:__OnAutoAttackReset();
					end
				end
				self.AutoAttackResetCastTime = castTime;
			end
		end

		local state = Utilities:GetAttackDataState(myHero);
		if state == STATE_WINDUP then
			if self.MyHeroState ~= STATE_WINDUP then
				self:__OnAttack();
			end
		end
		self.MyHeroState = state;

		local IsAutoAttacking = self:IsAutoAttacking();
		if not IsAutoAttacking then
			if self.MyHeroIsAutoAttacking then
				self:__OnPostAttack();
			end
		end
		self.MyHeroIsAutoAttacking = IsAutoAttacking;


		if (not self.IsNone) then
			self:Orbwalk();
		end
	end

	function __Orbwalker:OnTick()
		self:Clear();
		self.Modes = self:GetModes();
		self.IsNone = self:HasMode(ORBWALKER_MODE_NONE);
		--[[
			for i = 1, #self.MyHeroAttacks do
				if self.MyHeroAttacks[i]:ShouldRemove() then
					table.remove(self.MyHeroAttacks, i);
					break;
				end
			end
		]]

		if (not self.IsNone) or self.Menu.Drawings.LastHittableMinions:Value() then
			self.OnlyLastHit = (not self.Modes[ORBWALKER_MODE_LANECLEAR]);
			if (not self.IsNone) or self.Menu.Drawings.LastHittableMinions:Value() then
				self:CalculateLastHittableMinions();
			end
		end
		if self.LastHoldPosition > 0 and LocalGameTimer() - self.LastHoldPosition > 0.025 then
			LocalControlKeyUp(72);
			self.LastHoldPosition = 0;
		end
	end

	function __Orbwalker:__OnAutoAttackReset()
		self.AutoAttackResetted = true;
		self.LastAutoAttackSent = 0;
	end

	function __Orbwalker:__OnAttack()
		--Linq:Add(self.MyHeroAttacks, __IncomingAttack(myHero));
		--print(tostring(LocalGameTimer() - self.LastAutoAttackSent));
		self.FastKiting = true;
		self.AutoAttackResetted = false;
		for i = 1, #self.OnAttackCallbacks do
			self.OnAttackCallbacks[i]();
		end
	end

	function __Orbwalker:__OnPostAttack()
		for i = 1, #self.OnPostAttackCallbacks do
			self.OnPostAttackCallbacks[i]();
		end
	end

	function __Orbwalker:Orbwalk()
		if LocalGameIsChatOpen() or (not LocalGameIsOnTop()) then
			return;
		end

		if self:CanAttack() then
			local target = self:GetTarget();
			if target ~= nil then
				local args = {
					Target = target,
					Process = true,
				};
				for i = 1, #self.OnPreAttackCallbacks do
					self.OnPreAttackCallbacks[i](args);
				end
				if args.Process and args.Target ~= nil then
					local boolean = _G.Control.Attack(args.Target);
					if boolean == nil or boolean == true then
						self.LastAutoAttackSent = LocalGameTimer();
						self.HoldPosition = nil;
					end
					return;
				end
			end
		end
		if LocalGameTimer() - self.LastAutoAttackSent <= 0.2 then
			--return;
		end
		self:Move();
	end

	function __Orbwalker:Move()
		if not self:CanMove() then
			return;
		end
		if LocalGameTimer() - self.LastMovementSent <= self.Menu.General.MovementDelay:Value() * 0.001 then
			if self.Menu.General.FastKiting:Value() then
				if self.FastKiting then
					self.FastKiting = false;
				else
					return;
				end
			else
				return;
			end
		end
		local position = self:GetMovementPosition();
		local movePosition = Utilities:IsInRange(myHero, position, 100) and myHero.pos:Extend(position, 100) or position;
		local HoldRadius = self.Menu.General.HoldRadius:Value();
		local move = false;
		local hold = false;
		if HoldRadius > 0 then
			if Utilities:IsInRange(myHero, position, HoldRadius) then
				hold = true;
			else
				move = true;
			end
		else
			move = true;
		end
		if move then
			local args = {
				Target = movePosition,
				Process = true,
			};
			for i = 1, #self.OnPreMovementCallbacks do
				self.OnPreMovementCallbacks[i](args);
			end
			if args.Process and args.Target ~= nil then
				if args.Target == _G.mousePos then
					local boolean = _G.Control.Move();
					if boolean == nil or boolean == true then
						self.LastMovementSent = LocalGameTimer();
					end
				else
					local boolean = _G.Control.Move(args.Target);
					if boolean == nil or boolean == true then
						self.LastMovementSent = LocalGameTimer();
					end
				end
				return;
			end
		end
		if hold then
			if self.HoldPosition == nil or (not (self.HoldPosition == myHero.pos)) then
				LocalControlKeyDown(72);
				self.HoldPosition = myHero.pos;
				self.LastHoldPosition = LocalGameTimer();
			end
		end
	end

	function __Orbwalker:OnDraw()
		if self.Menu.Drawings.Range:Value() then
			LocalDrawCircle(myHero.pos, Utilities:GetAutoAttackRange(myHero), COLOR_LIGHT_GREEN);
		end
		if self.Menu.Drawings.HoldRadius:Value() then
			LocalDrawCircle(myHero.pos, self.Menu.General.HoldRadius:Value(), COLOR_LIGHT_GREEN);
		end
		if self.Menu.Drawings.EnemyRange:Value() then
			local t = ObjectManager:GetEnemyHeroes();
			for i = 1, #t do
				local enemy = t[i];
				local range = Utilities:GetAutoAttackRange(enemy, myHero);
				LocalDrawCircle(enemy.pos, range, Utilities:IsInRange(enemy, myHero, range) and COLOR_ORANGE_RED or COLOR_LIGHT_GREEN);
			end
		end
		if self.Menu.Drawings.LastHittableMinions:Value() then
			if self.LastHitMinion ~= nil then
				LocalDrawCircle(self.LastHitMinion.pos, LocalMathMax(65, self.LastHitMinion.boundingRadius), COLOR_WHITE);
			end
			if self.AlmostLastHitMinion ~= nil and not Utilities:IdEquals(self.AlmostLastHitMinion, self.LastHitMinion) then
				LocalDrawCircle(self.AlmostLastHitMinion.pos, LocalMathMax(65, self.AlmostLastHitMinion.boundingRadius), COLOR_ORANGE_RED);
			end
		end
		--[[
		local minions = {};
		local t = ObjectManager:GetEnemyHeroes(1500);
		for i = 1, #t do
			local minion = t[i];
			minions[minion.handle] = minion;
		end
		local t = ObjectManager:GetEnemyMinions(1500);
		for i = 1, #t do
			local minion = t[i];
			minions[minion.handle] = minion;
		end
		local t = ObjectManager:GetMonsters(1500);
		for i = 1, #t do
			local minion = t[i];
			minions[minion.handle] = minion;
		end
		local counter = 0;
		for i = 1, #self.MyHeroAttacks do
			local attack = self.MyHeroAttacks[i];
			local position = myHero.pos:To2D();
			position.y = position.y + counter * 18;
			if minions[attack.TargetHandle] ~= nil then
				local time = attack:GetArrivalTime(minions[attack.TargetHandle]) - LocalGameTimer();
				LocalDrawText(tostring(time), position);
			end
			counter = counter + 1;
		end
		local stateTable = {};
		stateTable[STATE_UNKNOWN] 	= "STATE_UNKNOWN";
		stateTable[STATE_ATTACK]	= "STATE_ATTACK";
		stateTable[STATE_WINDUP] 	= "STATE_WINDUP";
		stateTable[STATE_WINDDOWN] 	= "STATE_WINDDOWN";
		--LocalDrawText(tostring(self:CanAttackTime()) .. " " .. tostring(self:CanIssueOrder()) .. " " .. tostring(stateTable[Utilities:GetAttackDataState(myHero)]), myHero.pos:To2D());
		local tempLastMinionHealth = {};
		local EnemyMinionsInRange = ObjectManager:GetEnemyMinions();
		for i = 1, #EnemyMinionsInRange do
			local minion = EnemyMinionsInRange[i];
			if Utilities:IsInRange(myHero, minion, 1500) then
				local health = minion.health;
				if self.LastMinionHealth[minion.networkID] ~= nil and self.LastMinionHealth[minion.networkID] > health then
					local time = LocalGameTimer() + 0.25;
					if self.LastMinionDraw[time] == nil then
						self.LastMinionDraw[time] = {};
					end
					Linq:Add(self.LastMinionDraw[time], { Text = "Lost " .. LocalMathAbs(self.LastMinionHealth[minion.networkID] - health), Position = minion.pos:To2D() });
					local counter = 1;
					for _, attacks in pairs(HealthPrediction.IncomingAttacks) do
						if #attacks > 0 then
							for i = 1, #attacks do
								local attack = attacks[i];
								if attack.TargetHandle == minion.handle then
									local timeTillHit = attack:GetArrivalTime(minion) - LocalGameTimer();
									if timeTillHit <= 0.25 and timeTillHit > -0.5 then
										local position = minion.pos:To2D();
										position.y = position.y + 18 * counter;
										Linq:Add(self.LastMinionDraw[time], { Text = "Attack " .. timeTillHit, Position = position });
										counter = counter + 1;
									end
								end
							end
						end
					end
				end
				tempLastMinionHealth[minion.networkID] = health;
			end
		end
		self.LastMinionHealth = tempLastMinionHealth;
		for key, tab in pairs(self.LastMinionDraw) do
			if LocalGameTimer() < key then
				for i = 1, #tab do
					local value = tab[i];
					LocalDrawText(value.Text, value.Position);
				end
			end
		end
		]]
	end

	function __Orbwalker:GetUnit(unit)
		return (unit ~= nil) and unit or myHero;
	end

	function __Orbwalker:IsAutoAttacking(unit)
		unit = self:GetUnit(unit);
		local ExtraWindUpTime = self.Menu.General.ExtraWindUpTime:Value() * 0.001;
		if self.ExtraWindUpTimes[unit.charName] ~= nil then
			ExtraWindUpTime = ExtraWindUpTime + self.ExtraWindUpTimes[unit.charName];
		end
		local endTime = Utilities:GetAttackDataEndTime(unit) - self:GetAnimationTime(unit) + self:GetWindUpTime(unit) + ExtraWindUpTime;
		if LocalGameTimer() - endTime + 0.03 >= 0 then
			return false;
		end
		return true;
	end

	function __Orbwalker:GetMaximumIssueOrderDelay()
		return LocalMathMax(self:GetIssueOrderDelay(), 0.15);
	end

	function __Orbwalker:IsWaitingResponseFromServer()
		return LocalGameTimer() - self.LastAutoAttackSent <= self:GetMaximumIssueOrderDelay();
	end
	
	function __Orbwalker:CanMove(unit)
		unit = self:GetUnit(unit);
		local IsAutoAttacking = self:IsAutoAttacking(unit);
		if unit.isMe then
			if self:IsWaitingResponseFromServer() then
				if not IsAutoAttacking then
					return false;
				end
			end
		end
		if Utilities:IsChanneling(unit) then
			if self.AllowMovement[unit.charName] == nil or (not self.AllowMovement[unit.charName](unit)) then
				return false;
			end
		end
		return not IsAutoAttacking;
	end

	function __Orbwalker:CanAttack(unit)
		unit = self:GetUnit(unit);
		if Utilities:IsChanneling(unit) then
			return false;
		end
		if self.DisableAutoAttack[unit.charName] ~= nil and self.DisableAutoAttack[unit.charName](unit) then
			return false;
		end
		if unit.isMe then
			if self:IsWaitingResponseFromServer() then
				if not self:IsAutoAttacking(unit) then
					return false;
				end
			end
		end
		return self:CanIssueOrder(unit);
	end

	function __Orbwalker:GetIssueOrderDelay()
		return Utilities:GetLatency() * 1.5 - 0.005;
	end

	function __Orbwalker:CanAttackTime(unit)
		unit = self:GetUnit(unit);
		return LocalGameTimer() - Utilities:GetAttackDataEndTime(unit) + self:GetIssueOrderDelay();
	end

	function __Orbwalker:CanIssueOrder(unit)
		unit = self:GetUnit(unit);
		if unit.isMe then
			if self.AutoAttackResetted then
				return true;
			end
		end
		return self:CanAttackTime(unit) >= 0;
	end

	function __Orbwalker:GetWindUpTime(unit, target)
		unit = self:GetUnit(unit);
		local windUpTime = Utilities:GetAttackDataWindUpTime(unit);
		if unit.isMe then
			if LocalMathAbs(self.AttackDataWindUpTime - windUpTime) < EPSILON then
				return self.SpellWindUpTime;
			end
		end
		if unit.charName == "Azir" then
			--TODO
		end
		return windUpTime;
	end

	function __Orbwalker:GetAnimationTime(unit, target)
		unit = self:GetUnit(unit);
		local animationTime = Utilities:GetAttackDataAnimationTime(unit);
		if unit.isMe then
			if LocalMathAbs(self.AttackDataAnimationTime - animationTime) < EPSILON then
				return self.SpellAnimationTime;
			end
		end
		if unit.charName == "Azir" then
			--TODO
		end
		return animationTime;
	end


	function __Orbwalker:GetMissileSpeed(unit)
		unit = self:GetUnit(unit);
		return Utilities:GetAttackDataProjectileSpeed(unit);
	end

	function __Orbwalker:GetTarget()
		if Utilities:IsValidTarget(self.ForceTarget) then
			return Utilities:IsInAutoAttackRange(myHero, self.ForceTarget) and self.ForceTarget or nil;
		end
		if self.IsNone then
			return nil;
		end
		local potentialTargets = {};

		local hero = nil;
		local heroChecked = false;
		if self.Modes[ORBWALKER_MODE_COMBO] or self.Modes[ORBWALKER_MODE_HARASS] then
			hero = self:GetTargetByType(ORBWALKER_TARGET_TYPE_HERO);
			heroChecked = true;
		end

		local laneMinion = nil;
		if self.Modes[ORBWALKER_MODE_HARASS] or self.Modes[ORBWALKER_MODE_LANECLEAR] or self.Modes[ORBWALKER_MODE_LASTHIT] then
			laneMinion = self:GetTargetByType(ORBWALKER_TARGET_TYPE_LANE_MINION);
		end

		local otherMinion = nil;
		local otherMinionIsLastHittable = false;
		if self.Modes[ORBWALKER_MODE_LANECLEAR] or self.Modes[ORBWALKER_MODE_LASTHIT] or self.Modes[ORBWALKER_MODE_JUNGLECLEAR] then
			otherMinion = self:GetTargetByType(ORBWALKER_TARGET_TYPE_OTHER_MINION);
			otherMinionIsLastHittable = otherMinion ~= nil and otherMinion.health <= 1;
		end

		local monster = nil
		if self.Modes[ORBWALKER_MODE_JUNGLECLEAR] then
			monster = self:GetTargetByType(ORBWALKER_TARGET_TYPE_MONSTER);
		end

		local structure = nil;
		if self.Modes[ORBWALKER_MODE_HARASS] or self.Modes[ORBWALKER_MODE_LANECLEAR] then
			structure = self:GetTargetByType(ORBWALKER_TARGET_TYPE_STRUCTURE);
		end

		local LastHitPriority = self.Menu.Farming.LastHitPriority:Value();

		if self.Modes[ORBWALKER_MODE_COMBO] then
			Linq:Add(potentialTargets, hero);
		end

		if self.Modes[ORBWALKER_MODE_HARASS] then
			if structure ~= nil then
				if not LastHitPriority then
					Linq:Add(potentialTargets, structure);
				end
				Linq:Add(potentialTargets, laneMinion);
				if LastHitPriority and not self:ShouldWait() then
					Linq:Add(potentialTargets, structure);
				end
				Linq:Add(potentialTargets, laneMinion);
			else
				if not LastHitPriority then
					Linq:Add(potentialTargets, hero);
				end
				Linq:Add(potentialTargets, laneMinion);
				if LastHitPriority and not self:ShouldWait() then
					Linq:Add(potentialTargets, hero);
				end
			end
		end
		if self.Modes[ORBWALKER_MODE_LASTHIT] then
			Linq:Add(potentialTargets, laneMinion);
			if otherMinionIsLastHittable then
				Linq:Add(potentialTargets, otherMinion);
			end
		end
		if self.Modes[ORBWALKER_MODE_JUNGLECLEAR] then
			Linq:Add(potentialTargets, monster);
			Linq:Add(potentialTargets, otherMinion);
		end
		if self.Modes[ORBWALKER_MODE_LANECLEAR] then
			local LaneClearHeroes = self.Menu.General.LaneClearHeroes:Value();
			if structure ~= nil then
				if not LastHitPriority then
					Linq:Add(potentialTargets, structure);
				end
				if Utilities:IdEquals(laneMinion, self.LastHitMinion) then
					Linq:Add(potentialTargets, laneMinion);
				end
				if otherMinionIsLastHittable then
					Linq:Add(potentialTargets, otherMinion);
				end
				if LastHitPriority and not self:ShouldWait() then
					Linq:Add(potentialTargets, structure);
				end
			else
				if not heroChecked then
					hero = self:GetTargetByType(ORBWALKER_TARGET_TYPE_HERO);
					heroChecked = true;
				end
				if not LastHitPriority and LaneClearHeroes then
					Linq:Add(potentialTargets, hero);
				end
				if Utilities:IdEquals(laneMinion, self.LastHitMinion) then
					Linq:Add(potentialTargets, laneMinion);
				end
				if LastHitPriority and LaneClearHeroes and not self:ShouldWait() then
					Linq:Add(potentialTargets, hero);
				end
				if Utilities:IdEquals(laneMinion, self.LaneClearMinion) then
					Linq:Add(potentialTargets, laneMinion);
				end
				Linq:Add(potentialTargets, otherMinion);
			end
		end
		for i = 1, #potentialTargets do
			local target = potentialTargets[i];
			if target ~= nil then
				return target;
			end
		end
		return nil;
	end

	function __Orbwalker:GetTargetByType(t)
		return (self.TargetByType[t] ~= nil) and self.TargetByType[t]() or nil;
	end

	function __Orbwalker:GetMovementPosition()
		if self.ForceMovement ~= nil then
			return self.ForceMovement;
		end
		return _G.mousePos;
	end

	function __Orbwalker:RegisterMenuKey(mode, key)
		Linq:Add(self.MenuKeys[mode], key);
	end

	function __Orbwalker:HasMode(mode)
		if mode == ORBWALKER_MODE_NONE then
			for _, value in pairs(self:GetModes()) do
				if value then
					return false;
				end
			end
			return true;
		end
		for i = 1, #self.MenuKeys[mode] do
			local key = self.MenuKeys[mode][i];
			if key:Value() then
				return true;
			end
		end
		return false;
	end

	function __Orbwalker:GetModes()
		return {
			[ORBWALKER_MODE_COMBO] 			= self:HasMode(ORBWALKER_MODE_COMBO),
			[ORBWALKER_MODE_HARASS] 		= self:HasMode(ORBWALKER_MODE_HARASS),
			[ORBWALKER_MODE_LANECLEAR] 		= self:HasMode(ORBWALKER_MODE_LANECLEAR),
			[ORBWALKER_MODE_JUNGLECLEAR] 	= self:HasMode(ORBWALKER_MODE_JUNGLECLEAR),
			[ORBWALKER_MODE_LASTHIT] 		= self:HasMode(ORBWALKER_MODE_LASTHIT),
			[ORBWALKER_MODE_FLEE] 			= self:HasMode(ORBWALKER_MODE_FLEE),
		};
	end

	function __Orbwalker:CalculateLastHittableMinions()
		local IsMelee = Utilities:IsMelee(myHero);
		local extraTime = 0;--TODO (not self:CanIssueOrder()) and LocalMathMax(0, Utilities:GetAttackDataEndTime(myHero) - LocalGameTimer()) or 0;
		local maxMissileTravelTime = IsMelee and 0 or (Utilities:GetAutoAttackRange(myHero) / self:GetMissileSpeed());
		local Minions = {};
		local EnemyMinionsInRange = ObjectManager:GetEnemyMinions();
		local ExtraFarmDelay = self.Menu.Farming.ExtraFarmDelay:Value() * 0.001;
		local DamageDelay = Utilities:GetDamageDelay();
		local boundingRadius = 0;--myHero.boundingRadius;
		for i = 1, #EnemyMinionsInRange do
			local minion = EnemyMinionsInRange[i];
			if Utilities:IsInRange(myHero, minion, 1500) then
				local windUpTime = self:GetWindUpTime(myHero, minion) + DamageDelay + ExtraFarmDelay;
				local missileTravelTime = IsMelee and 0 or (LocalMathMax(Utilities:GetDistance(myHero, minion) - boundingRadius, 0) / self:GetMissileSpeed());
				local orbwalkerMinion = __OrbwalkerMinion(minion);
				orbwalkerMinion.LastHitTime = windUpTime + missileTravelTime + extraTime; -- + LocalMathMax(0, 2 * (Utilities:GetDistance(myHero, minion) - Utilities:GetAutoAttackRange(myHero, minion)) / myHero.ms);
				orbwalkerMinion.LaneClearTime = windUpTime + self:GetAnimationTime(myHero, minion) + maxMissileTravelTime;
				Minions[minion.handle] = orbwalkerMinion;
			end
		end
		for _, attacks in pairs(HealthPrediction.IncomingAttacks) do
			if #attacks > 0 then
				for i = 1, #attacks do
					local attack = attacks[i];
					local minion = Minions[attack.TargetHandle];
					if minion ~= nil then
						minion.LastHitHealth = minion.LastHitHealth - attack:GetPredictedDamage(minion.Minion, minion.LastHitTime, true);
						minion.LaneClearHealth = minion.LaneClearHealth - attack:GetPredictedDamage(minion.Minion, minion.LaneClearTime, true);
					end
				end
			end
		end
		local UnkillableMinions = {};
		local LastHitMinions = {};
		local AlmostLastHitMinions = {};
		local LaneClearMinions = {};
		for _, minion in pairs(Minions) do
			if minion:IsUnkillable() then
				Linq:Add(UnkillableMinions, minion);
			elseif minion:IsLastHittable() then
				Linq:Add(LastHitMinions, minion);
			elseif minion:IsAlmostLastHittable() then
				Linq:Add(AlmostLastHitMinions, minion);
			elseif minion:IsLaneClearable() then
				Linq:Add(LaneClearMinions, minion);
			end
		end
		LocalTableSort(UnkillableMinions, function(a, b)
			return a.LastHitHealth < b.LastHitHealth;
		end);

		LocalTableSort(LastHitMinions, function(a, b)
			if a.Minion.maxHealth == b.Minion.maxHealth then
				return a.LastHitHealth < b.LastHitHealth;
			else
				return a.Minion.maxHealth > b.Minion.maxHealth;
			end
		end);
		for i = 1, #LastHitMinions do
			local minion = LastHitMinions[i].Minion;
			if Utilities:IsInAutoAttackRange(myHero, minion) then
				self.LastHitMinion = minion;
				break;
			end
		end

		LocalTableSort(AlmostLastHitMinions, function(a, b)
			if a.Minion.maxHealth == b.Minion.maxHealth then
				return a.LaneClearHealth < b.LaneClearHealth;
			else
				return a.Minion.maxHealth > b.Minion.maxHealth;
			end
		end);
		for i = 1, #AlmostLastHitMinions do
			local minion = AlmostLastHitMinions[i].Minion;
			if Utilities:IsInAutoAttackRange(myHero, minion) then
				self.AlmostLastHitMinion = minion;
				break;
			end
		end

		local PushPriority = self.Menu.Farming.PushPriority:Value();
		LocalTableSort(LaneClearMinions, function(a, b)
			if PushPriority then
				return a.LaneClearHealth < b.LaneClearHealth;
			else
				return a.LaneClearHealth > b.LaneClearHealth;
			end
		end);

		for i = 1, #LaneClearMinions do
			local minion = LaneClearMinions[i].Minion;
			if Utilities:IsInAutoAttackRange(myHero, minion) then
				self.LaneClearMinion = minion;
				break;
			end
		end

		if self.AlmostLastHitMinion ~= nil then
			self.LastShouldWait = LocalGameTimer();
		end
	end

	function __Orbwalker:ShouldWait()
		return LocalGameTimer() - self.LastShouldWait <= 0.4 or self.AlmostLastHitMinion ~= nil;
	end

	function __Orbwalker:GetAutoAttackDamage(minion)
		if self.StaticAutoAttackDamage == nil then
			self.StaticAutoAttackDamage = Damage:GetStaticAutoAttackDamage(myHero, true);
		end
		if self.DamageOnMinions[minion.networkID] == nil then
			self.DamageOnMinions[minion.networkID] = Damage:GetHeroAutoAttackDamage(myHero, minion, self.StaticAutoAttackDamage);
		end
		return self.DamageOnMinions[minion.networkID];
	end

	function __Orbwalker:OnUnkillableMinion(cb)
		Linq:Add(self.OnUnkillableMinionCallbacks, cb);
	end

	function __Orbwalker:OnPreAttack(cb)
		Linq:Add(self.OnPreAttackCallbacks, cb);
	end

	function __Orbwalker:OnPreMovement(cb)
		Linq:Add(self.OnPreMovementCallbacks, cb);
	end

	function __Orbwalker:OnAttack(cb)
		Linq:Add(self.OnAttackCallbacks, cb);
	end

	function __Orbwalker:OnPostAttack(cb)
		Linq:Add(self.OnPostAttackCallbacks, cb);
	end


class "__OrbwalkerMinion"
	function __OrbwalkerMinion:__init(minion)
		self.Minion = minion;
		self.LastHitHealth = self.Minion.health;
		self.LaneClearHealth = self.Minion.health;
		self.LastHitTime = 0;
		self.LaneClearTime = 0;
	end

	function __OrbwalkerMinion:IsUnkillable()
		return self.LastHitHealth < 0;
	end

	function __OrbwalkerMinion:IsLastHittable()
		return self.LastHitHealth <= Orbwalker:GetAutoAttackDamage(self.Minion);
	end

	function __OrbwalkerMinion:IsAlmostLastHittable()
		if LocalMathAbs(self.LaneClearHealth - self.Minion.health) < EPSILON then
			return false;
		end
		local health = (false) --[[TODO]] and self.LastHitHealth or self.LaneClearHealth;
		local percentMod = Utilities:IsSiegeMinion(self.Minion) and 1.5 or 1;
		return health <= percentMod * Orbwalker:GetAutoAttackDamage(self.Minion);
	end

	function __OrbwalkerMinion:IsLaneClearable()
		if Orbwalker.OnlyLastHit then
			return false;
		end
		--[[
			if LocalMathAbs(self.LaneClearHealth - self.Minion.health) < 1E-12 then
				return true;
			end
		]]
		if LocalMathAbs(self.LaneClearHealth - self.Minion.health) < EPSILON then
			return true;
		end
		local percentMod = 2;
		if false --[[TODO]] then
			percentMod = percentMod * 2;
		end
		return self.LaneClearHealth > percentMod * Orbwalker:GetAutoAttackDamage(self.Minion);
	end


-- Replicate EOW
class "__EOW"
	function __EOW:__init()
		_G.EOWMenu.Config.AE:Value(false);
		_G.EOWMenu.Config.ME:Value(false);
		_G.EOWMenu.Draw.DA:Value(true);
	end

	function __EOW:GetTarget()
		return Orbwalker:GetTarget();
	end

	function __EOW:GetOrbTarget()
		return Orbwalker:GetTarget();
	end

	function __EOW:Mode()
		if Orbwalker.Modes[ORBWALKER_MODE_COMBO] then
			return "Combo";
		elseif Orbwalker.Modes[ORBWALKER_MODE_HARASS] then
			return "Harass";
		elseif Orbwalker.Modes[ORBWALKER_MODE_LANECLEAR] then
			return "LaneClear";
		elseif Orbwalker.Modes[ORBWALKER_MODE_LASTHIT] then
			return "LastHit";
		end
		return "";
	end

	function __EOW:CalcPhysicalDamage(from, target, rawDamage)
		return Damage:CalculateDamage(from, target, DAMAGE_TYPE_PHYSICAL, rawDamage);
	end

	function __EOW:CalcMagicalDamage(from, target, rawDamage)
		return Damage:CalculateDamage(from, target, DAMAGE_TYPE_MAGICAL, rawDamage);
	end

Linq = __Linq();
ObjectManager = __ObjectManager();
Utilities = __Utilities();
BuffManager = __BuffManager();
ItemManager = __ItemManager();
Damage = __Damage();
TargetSelector = __TargetSelector();
HealthPrediction = __HealthPrediction();
Orbwalker = __Orbwalker();

_G.SDK.Linq = Linq;
_G.SDK.ObjectManager = ObjectManager;
_G.SDK.Utilities = Utilities;
_G.SDK.BuffManager = BuffManager;
_G.SDK.ItemManager = ItemManager;
_G.SDK.Damage = Damage;
_G.SDK.TargetSelector = TargetSelector;
_G.SDK.HealthPrediction = HealthPrediction;
_G.SDK.Orbwalker = Orbwalker;

-- Disabling GoS Orbwalker
if _G.Orbwalker then
	_G.Orbwalker.Enabled:Value(false);
	_G.Orbwalker.Drawings.Enabled:Value(false);
	--_G.Orbwalker:Remove();
	--_G.Orbwalker = nil;
end

AddLoadCallback(function()
	if _G.EOW then
		_G.EOW = __EOW();
	end
end);