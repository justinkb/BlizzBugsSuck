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
	MINUTE_ONLETTER_ABBR = "%d m"
	DAY_ONELETTER_ABBR = "%d d"
end
