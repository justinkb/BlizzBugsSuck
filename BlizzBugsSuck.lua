-- UIDropDownMenu FrameLevels do not properly follow their parent and need to be
-- fixed to prevent the button being under the background.
local function FixMenuFrameLevels()
	for l=1,UIDROPDOWNMENU_MAXLEVELS do
		for b=1,UIDROPDOWNMENU_MAXBUTTONS do
			local button = _G["DropDownList"..l.."Button"..b]
			if button then 
				local button_parent = button:GetParent()
				if button_parent then 
					local button_level = button:GetFrameLevel()
					local parent_level = button_parent:GetFrameLevel()
					if button_level <= parent_level then 
						button:SetFrameLevel(parent_level + 2) 
					end  
				end  
			end  
		end  
	end  
end
hooksecurefunc("UIDropDownMenu_CreateFrames", FixMenuFrameLevels)

-- Fix incorrect translations in the German Locale.  For whatever reason
-- Blizzard changed the oneletter time abbreviations to be 3 letter in
-- the German Locale.
if GetLocale() == "deDE" then
	MINUTE_ONELETTER_ABBR = "%d m"
	DAY_ONELETTER_ABBR = "%d d"
end

-- fixes the issue with InterfaceOptionsFrame_OpenToCategory not actually opening the Category (and not even scrolling to it)
do
	local doNotRun = false
	local function InterfaceOptionsFrame_OpenToCategory_Fix(panel)
		if InCombatLockdown() then return end
		if doNotRun then
			doNotRun = false
			return
		end
		local cat = _G['INTERFACEOPTIONS_ADDONCATEGORIES']
		local panelName;
		if ( type(panel) == "string" ) then
			for i, p in pairs(cat) do
				if p.name == panel then
					panelName =  p.parent or panel
					break
				end
			end
		else
			for i, p in pairs(cat) do
				if p == panel then
					panelName =  p.parent or panel.name
					break
				end
			end
		end
		if not panelName then return end -- if its not part of our list return early
		local noncollapsedHeaders = {}
		local shownpanels = 0
		local mypanel 
		for i, panel in ipairs(cat) do
			if not panel.parent or noncollapsedHeaders[panel.parent] then
				if panel.name == panelName then
					panel.collapsed = true
					local t={}
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
		InterfaceOptionsFrameAddOnsListScrollBar:SetValue((Smax/(shownpanels-15))*(mypanel-2))
		doNotRun = true
		InterfaceOptionsFrame_OpenToCategory(panel)
	end
	hooksecurefunc("InterfaceOptionsFrame_OpenToCategory", function(panel) return InterfaceOptionsFrame_OpenToCategory_Fix(panel) end)
end

-- Block BNSendWhisper from being able to whisper yourself and thus exposing your RealName.
local BNSendWhisper_orig = _G.BNSendWhisper
-- Upvalue BNIsSelf to prevent some clever AddOn from changing it to lie to us.
local BNIsSelf = BNIsSelf
function BNSendWhisper(presenceID, ...)
	if BNIsSelf(presenceID) then
		local ds = debugstack(2,1,0)
		local addon = ds:match("Interface\\AddOns\\([^\\]*)\\")
		if not addon then
			print("|cffff0000WARNING: An unknown AddOn attempted to discover your Real Name, BlizzBugsSuck has blocked this.")
		else
			print(string.format("|cffff0000WARNING: The AddOn '%s' attempted to discover your Real Name, BlizzBugsSuck has blocked this.",addon))
		end
		return
	end
	return BNSendWhisper_orig(presenceID, ...)
end
