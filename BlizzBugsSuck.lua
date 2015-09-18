local wow_version, wow_build, wow_data, tocversion = GetBuildInfo()
wow_build = tonumber(wow_build)

-- Fix incorrect translations in the German localization
if GetLocale() == "deDE" then
	-- Day one-letter abbreviation is using a whole word instead of one letter.
	-- Confirmed still bugged in 6.1.0.19658
	DAY_ONELETTER_ABBR = "%d d"
end

-- Fix missing bonus effects on shipyard map in non-English locales
-- Problem is caused by Blizzard checking a localized API value
-- against a hardcoded English string.
if GetLocale() ~= "enUS" then
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("ADDON_LOADED")
	frame:SetScript("OnEvent", function(self, event, name)
		if name == "Blizzard_GarrisonUI" then
			hooksecurefunc("GarrisonShipyardMap_SetupBonus", function(self, missionFrame, mission)
				if (mission.typePrefix == "ShipMissionIcon-Bonus" and not missionFrame.bonusRewardArea) then
					missionFrame.bonusRewardArea = true
					for id, reward in pairs(mission.rewards) do
						local posX = reward.posX or 0
						local posY = reward.posY or 0
						posY = posY * -1
						missionFrame.BonusAreaEffect:SetAtlas(reward.textureAtlas, true)
						missionFrame.BonusAreaEffect:ClearAllPoints()
						missionFrame.BonusAreaEffect:SetPoint("CENTER", self.MapTexture, "TOPLEFT", posX, posY)
						break
					end
				else
			end)
			self:UnregisterAllEvents()
		end
	end)
end

-- Fix category labels in the Interface Options and other windows wrapping and overlapping due to Blizzard
-- "fixing" how font strings expand from two anchors, but not updating their own UI code to account for this.
-- New in 6.1
do
	local function unwrap(f)
		for _, button in next, f.buttons do
			button:GetFontString():SetWordWrap(false)
		end
	end
	unwrap(InterfaceOptionsFrameCategories)
	unwrap(InterfaceOptionsFrameAddOns)
	unwrap(VideoOptionsFrameCategoryFrame)
	hooksecurefunc("LoadAddOn", function(name)
		if name == "Blizzard_BindingUI" then
			unwrap(KeyBindingFrameCategoryList)
		end
	end)
end

-- Fix InterfaceOptionsFrame_OpenToCategory not actually opening the category (and not even scrolling to it)
-- Confirmed still broken in 6.0.3.19243
do
	local function get_panel_name(panel)
		local tp = type(panel)
		local cat = INTERFACEOPTIONS_ADDONCATEGORIES
		if tp == "string" then
			for i = 1, #cat do
				local p = cat[i]
				if p.name == panel then
					if p.parent then
						return get_panel_name(p.parent)
					else
						return panel
					end
				end
			end
		elseif tp == "table" then
			for i = 1, #cat do
				local p = cat[i]
				if p == panel then
					if p.parent then
						return get_panel_name(p.parent)
					else
						return panel.name
					end
				end
			end
		end
	end

	local function InterfaceOptionsFrame_OpenToCategory_Fix(panel)
		if doNotRun or InCombatLockdown() then return end
		local panelName = get_panel_name(panel)
		if not panelName then return end -- if its not part of our list return early
		local noncollapsedHeaders = {}
		local shownpanels = 0
		local mypanel
		local t = {}
		local cat = INTERFACEOPTIONS_ADDONCATEGORIES
		for i = 1, #cat do
			local panel = cat[i]
			if not panel.parent or noncollapsedHeaders[panel.parent] then
				if panel.name == panelName then
					panel.collapsed = true
					t.element = panel
					InterfaceOptionsListButton_ToggleSubCategories(t)
					noncollapsedHeaders[panel.name] = true
					mypanel = shownpanels + 1
				end
				if not panel.collapsed then
					noncollapsedHeaders[panel.name] = true
				end
				shownpanels = shownpanels + 1
			end
		end
		local Smin, Smax = InterfaceOptionsFrameAddOnsListScrollBar:GetMinMaxValues()
		if shownpanels > 15 and Smin < Smax then
			local val = (Smax/(shownpanels-15))*(mypanel-2)
			InterfaceOptionsFrameAddOnsListScrollBar:SetValue(val)
		end
		doNotRun = true
		InterfaceOptionsFrame_OpenToCategory(panel)
		doNotRun = false
	end

	hooksecurefunc("InterfaceOptionsFrame_OpenToCategory", InterfaceOptionsFrame_OpenToCategory_Fix)
end

-- Avoid taint from the UIFrameFlash usage of the chat frames.  More info here:
-- http://forums.wowace.com/showthread.php?p=324936
-- Fixed by embedding LibChatAnims

-- Fix an issue where the PetJournal drag buttons cannot be clicked to link a pet into chat.
-- The necessary code is already present, but the buttons are not registered for the correct click.
-- Confirmed still bugged in 6.1.0.19658
do
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("ADDON_LOADED")
	frame:SetScript("OnEvent", function(self, event, name)
		if name == "Blizzard_Collections" then
			for i = 1, 3 do
				local button = _G["PetJournalLoadoutPet"..i]
				if button and button.dragButton then
					button.dragButton:RegisterForClicks("LeftButtonUp")
				end
			end
			self:UnregisterAllEvents()
		end
	end)
end
