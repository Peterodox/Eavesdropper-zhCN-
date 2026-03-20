-- Copyright The Eavesdropper Authors
-- SPDX-License-Identifier: Apache-2.0

---@type EavesdropperPlayerName
local PlayerName = ED.PlayerName;

---@class EavesdropperNPCDialogue
local NPCDialogue = {};

function NPCDialogue.GetPlayerPreferredName()
	return PlayerName.preferredName;
end

function NPCDialogue.RefreshPlayerPreferredName()
	if not ED.MSP.IsEnabled() then
		return;
	end
	PlayerName.RefreshPlayerPreferredName();
end

---@param npcDialogue string
function NPCDialogue.SubstitutePlayerPreferredName(npcDialogue)
	if ED.Database:GetSetting("NPCAndQuestNameDisplayMode") == 3 or not ED.Database:GetSetting("UseRPNameInNPCDialogue") then
		return npcDialogue;
	end

	return PlayerName:SubstitutePlayerPreferredName(npcDialogue);
end

function NPCDialogue:Init()
	self:RefreshPlayerPreferredName();
end

ED.NPCDialogue = NPCDialogue;
