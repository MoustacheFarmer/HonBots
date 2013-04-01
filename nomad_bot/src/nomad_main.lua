-- Nomadbot

--####################################################################
--####################################################################
--#                                                                 ##
--#                       Bot Initiation                            ##
--#                                                                 ##
--####################################################################
--####################################################################


local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

object.bRunLogic         = true
object.bRunBehaviors    = true
object.bUpdates         = true
object.bUseShop         = true

object.bRunCommands     = true 
object.bMoveCommands     = true
object.bAttackCommands     = true
object.bAbilityCommands = true
object.bOtherCommands     = true

object.bReportBehavior = false
object.bDebugUtility = false

object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false

object.core         = {}
object.eventsLib     = {}
object.metadata     = {}
object.behaviorLib     = {}
object.skills         = {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
    = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
    = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho(object:GetName()..' loading scorcher_main...')




--####################################################################
--####################################################################
--#                                                                 ##
--#                  Bot Constant Definitions                       ##
--#                                                                 ##
--####################################################################
--####################################################################

-- Hero_<hero>  to reference the internal HoN name of a hero, Hero_Yogi ==Wildsoul
object.heroName = 'Hero_Nomad'


--   Item Buy order. Internal names  
behaviorLib.StartingItems  = { "Item_RunesOfTheBlight", "Item_Hatchet", "Item_IronBuckler"}
behaviorLib.LaneItems  = {"Item_Marchers","Item_BottleOfTears"}
behaviorLib.MidItems  = {"Item_LifeTube", "Item_HelmOfTheBlackLegion"}
behaviorLib.LateItems  = {"Item_Shieldbreaker", "Item_ShrunkenHead", "Item_GhostShroud", "Item_Genjuro"}


-- Skillbuild table, 0=Q, 1=W, 2=E, 3=R, 4=Attri
object.tSkills = {
    2, 1, 0, 1, 1,
    3, 1, 2, 2, 2, 
    3, 0, 0, 0, 4,
    3, 4, 4, 4, 4,
    4, 4, 4, 4, 4,
}

-- These are bonus agression points if a skill/item is available for use
object.nSandstormUp = 10
object.nMirageStrikeRealUp = 15
object.nMirageStrikeFakeUp = 30
object.nCounterEdgeUp = 40

-- These are bonus agression points that are applied to the bot upon successfully using a skill/item
object.nSandStormUse = 10
object.nMirageStrikeUseFake = 20
object.nMirageStrikeUseReal = 10
object.nCounterEdgeUse = 50

--Ingame name for shrunken head is Item_Immunity
object.nImmunityUse = 100;
--Ingame name for assasin's shroud is Item_Shroud, and genjuro is Item_Sasuke
object.nShroudUse = 40;

--These are thresholds of aggression the bot must reach to use these abilities
object.nSandStormTreshold = 0
object.nMirageStrikeTreshold = 0
object.nShroudTreshold = 0
object.nImmunityTreshold = 0;

object.tItems.itemShroud.assetName = "Item_Shroud"
object.tItems.itemSasuke.assetName = "Item_Immunity"
object.tItems.itemImmunity.assetName = "Item_Sasuke"

object.tItems.itemShroud.item = nil
object.tItems.itemSasuke.item = nil
object.tItems.itemImmunity.item = nil

--####################################################################
--####################################################################
--#                                                                 ##
--#   Bot Function Overrides                                        ##
--#                                                                 ##
--####################################################################
--####################################################################

------------------------------
--     Skills               --
------------------------------
-- @param: none
-- @return: none
function object:SkillBuild()
    core.VerboseLog("SkillBuild()")

-- takes care at load/reload, <NAME_#> to be replaced by some convinient name.
    local unitSelf = self.core.unitSelf
    if  skills.abilQ == nil then
        skills.abilQ = unitSelf:GetAbility(0)
        skills.abilW = unitSelf:GetAbility(1)
        skills.abilE = unitSelf:GetAbility(2)
        skills.abilR = unitSelf:GetAbility(3)
        skills.abilAttributeBoost = unitSelf:GetAbility(4)
    end
    if unitSelf:GetAbilityPointsAvailable() <= 0 then
        return
    end
    
   
    local nLev = unitSelf:GetLevel()
    local nLevPts = unitSelf:GetAbilityPointsAvailable()
    for i = nLev, nLev+nLevPts do
        unitSelf:GetAbility( object.tSkills[i] ):LevelUp()
    end
end


------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function object:onthinkOverride(tGameVariables)
    self:onthinkOld(tGameVariables)

    -- custom code here
end
object.onthinkOld = object.onthink
object.onthink 	= object.onthinkOverride





----------------------------------------------
--            OncombatEvent Override        --
-- Use to check for Infilictors (fe. Buffs) --
----------------------------------------------
-- @param: EventData
-- @return: none 
function object:oncombateventOverride(EventData)
    self:oncombateventOld(EventData)

    local nAddBonus = 0

    if EventData.Type == "Ability" then
        if EventData.InflictorName == "Ability_Nomad1" then
            nAddBonus = nAddBonus + object.nSandstormUse
        elseif EventData.InflictorName == "Ability_Nomad2a" then
            nAddBonus = nAddBonus + object.nMirageStrikeUseReal
        elseif EventData.InflictorName == "Ability_Nomad2b" then
            nAddBonus = nAddBonus + object.nMirageStrikeUseFake
      elseif EventData.InflictorName == "Ability_Nomad4" then
            nAddBonus = nAddBonus + object.nCounterEdgeUse
        end
	elseif EventData.Type == "Item" then
		if core.tItems.itemImmunity.item ~= nil and EventData.SourceUnit == core.unitSelf:GetUniqueID() and EventData.InflictorName == core.core.tItems.itemImmunity.item:GetName() then
			nAddBonus = nAddBonus + self.nImmunityUse
			if core.tItems.itemShroud.item~= nil and EventData.SourceUnit == core.unitSelf:GetUniqueID() and EventData.InflictorName == core.tItems.itemShroud.item:GetName() then
				nAddBonus = nAddBonus + self.nShroudUse
			end
			if core.core.tItems.itemSasuke.item ~= nil and EventData.SourceUnit == core.unitSelf:GetUniqueID() and EventData.InflictorName == core.core.tItems.itemSasuke.item:GetName() then
				nAddBonus = nAddBonus + self.nShroudUse
			end
		end
	end

   if nAddBonus > 0 then
        core.DecayBonus(self)
        core.nHarassBonus = core.nHarassBonus + nAddBonus
    end

end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent     = object.oncombateventOverride



------------------------------------------------------
--            CustomHarassUtility Override          --
-- Change Utility according to usable spells here   --
------------------------------------------------------
-- @param: IunitEntity hero
-- @return: number
local function CustomHarassUtilityFnOverride(hero)
    local nUtil = 0
    
    if skills.abilQ:CanActivate() then
        nUtil = nUtil + object.nSandstormUp
    end

    if skills.abilW:CanActivate() then
        nUtil = nUtil + object.nMirageStrikeRealUp
    end
    
    if skills.abilE:CanActivate() then
        nUtil = nUtil + object.nMirageStrikeFakeUp
    end

    if skills.abilR:CanActivate() then
        nUtil = nUtil + object.nCounterEdgeUp
    end

    return nUtil
end
-- assisgn custom Harrass function to the behaviourLib object
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride   


----------------------------------
--  FindItems Override
----------------------------------
local function funcFindItemsOverride(botBrain)
	local bUpdated = object.FindItemsOld(botBrain)

	for i, item in ipairs(core.tItems) do
		if core.tItems[i].item ~= nil and not core.tItems[i].item:isValid() then
			core.tItems[i].item = nil
		end
	end
	
	if bUpdated then
		--only update if we need to
		if core.itemSheepstick then
			return
		end
		
		local inventory = core.unitSelf:GetInventory(true)
		for i, itemName in ipairs(core.tItems) do
			for slot = 1, 12, 1 do
				local curItem = inventory[slot]
				if curItem then
					if core.tItems[i].item == nil and curItem:GetName() == core.tItems[i].assetName then
						core.tItems[i].item = core.WrapInTable(curItem)
					end
				end
			end
		end
	end
end
object.FindItemsOld = core.FindItems
core.FindItems = funcFindItemsOverride



--------------------------------------------------------------
--                    Harass Behavior                       --
-- All code how to use abilities against enemies goes here  --
--------------------------------------------------------------
-- @param botBrain: CBotBrain
-- @return: none
--
local function HarassHeroExecuteOverride(botBrain)
    
    local unitTarget = behaviorLib.heroTarget
    if unitTarget == nil then
        return object.harassExecuteOld(botBrain)  --Target is invalid, move on to the next behavior
    end
    
    
    local unitSelf = core.unitSelf
    local vecMyPosition = unitSelf:GetPosition() 
    local nAttackRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
    local nMyExtraRange = core.GetExtraRange(unitSelf)
    
    local vecTargetPosition = unitTarget:GetPosition()
    local nTargetExtraRange = core.GetExtraRange(unitTarget)
    local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)

    
    local nLastHarassUtility = behaviorLib.lastHarassUtil
    local bCanSee = core.CanSeeUnit(botBrain, unitTarget)    
    local bActionTaken = false

    --since we are using an old pointer, ensure we can still see the target for entity targeting
	if core.CanSeeUnit(botBrain, unitTarget) then
		local bTargetVuln = unitTarget:IsStunned() or unitTarget:IsImmobilized() or unitTarget:IsPerplexed()
        local abilDragon = skills.abilW
        local abilBlazing = skills.abilR
        core.FindItems()
        local itemShroud = core.itemShroud
        local itemSasuke =  core.itemSasuke
        local itemImmunity = core.itemImmunity
   
        -- Dragon Fire or Sheep - on unit.
        if not bActionTaken and not bTargetVuln then            
            if itemSheepstick then
                local nRange = itemSheepstick:GetRange()
                if itemSheepstick:CanActivate() and nLastHarassUtility > botBrain.nSheepstickThreshold then
                    if nTargetDistanceSq < (nRange*nRange) then
                        bActionTaken = core.OrderItemEntityClamp(botBrain, unitSelf, itemSheepstick, unitTarget)
                    end
                end 
            end
   
            if abilDragon:CanActivate() and nLastHarassUtility > botBrain.nDragonThreshold then
                local nRange = abilDragon:GetRange()
                if nTargetDistanceSq < (nRange * nRange) then
                    bActionTaken = core.OrderAbilityPosition(botBrain, abilDragon, vecTargetPosition)
                end           
            end 
        end
    end


     -- Sandstorm
    if not bActionTaken then
        local abilSandstorm = skills.abilQ
        if abilSandstorm:CanActivate() and nLastHarassUtility > botBrain.nSandstormTreshold then
				bActionTaken = core.OrderAbility(botBrain, abilSandstorm)
        end
    end 
    
    --Mirage Strike
	-- Nomad has two types or mirage strike, one where he sends the illusion and one where he dashes in himself
    if core.CanSeeUnit(botBrain, unitTarget) then
    	local abilMirageReal = skills.abilW
    	local abilMirageFake = skills.abilE
    		if not bActionTaken then
    			if abilMirage:CanActivate() and nLastHarassUtility > botBrain.nMirageStrikeRealTreshold then
    				local nRange = abilMirageReal:GetRange()
    					if nTargetDistanceSq < (nRange * nRange) then
    						bActionTaken = core.OrderAbilityEntity(botBrain, abilMirageReal, unitTarget)
    					end
    			end
    			else if 
    			 	abilMirage:CanActivate() and nLastHarassUtility > botBrain.nMirageStrikeFakeTreshold then
    				local nRange = abilMirageFake:GetRange()
    					if nTargetDistanceSq < (nRange * nRange) then
    						bActionTaken = core.OrderAbilityEntity(botBrain, abilMirageFake, unitTarget)
    					end
				end
			end
	end
    
    if not bActionTaken then
        return object.harassExecuteOld(botBrain) 
    end 
end



-- overload the behaviour stock function with custom 
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

