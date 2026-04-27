---@class BUFNamespace
local ns = select(2, ...)

---@class BUFParty
local BUFParty = ns.BUFParty

---@class BUFParty.Frame: Demoable, Sizable, BackgroundTexturable
local BUFPartyFrame = {
	configPath = "unitFrames.party.frame",
	frameKey = BUFParty.relativeToFrames.FRAME,
}

ns.Mixin(BUFPartyFrame, ns.Demoable, ns.Sizable, ns.BackgroundTexturable)

BUFParty.Frame = BUFPartyFrame

---@class BUFDbSchema.UF.Party
ns.dbDefaults.profile.unitFrames.party = ns.dbDefaults.profile.unitFrames.party

---@class BUFDbSchema.UF.Party.Frame
ns.dbDefaults.profile.unitFrames.party.frame = {
	width = 120,
	height = 53,
	enableFrameFlash = true,
	enableFrameTexture = true,
	useBackgroundTexture = false,
	backgroundTexture = "None",
}

local frameOrder = {}

ns.Mixin(frameOrder, ns.defaultOrderMap)
frameOrder.FRAME_FLASH = frameOrder.ENABLE + 0.1
frameOrder.FRAME_TEXTURE = frameOrder.FRAME_FLASH + 0.1
frameOrder.HORIZONTAL_LAYOUT = frameOrder.FRAME_TEXTURE + 0.1
frameOrder.BACKDROP_AND_BORDER = frameOrder.HORIZONTAL_LAYOUT + 0.1

local frame = {
	type = "group",
	handler = BUFPartyFrame,
	name = ns.L["Frame"],
	order = BUFParty.optionsOrder.FRAME,
	args = {
		frameFlash = {
			type = "toggle",
			name = ns.L["EnableFrameFlash"],
			set = "SetEnableFrameFlash",
			get = "GetEnableFrameFlash",
			order = frameOrder.FRAME_FLASH,
		},
		frameTexture = {
			type = "toggle",
			name = ns.L["EnableFrameTexture"],
			set = "SetEnableFrameTexture",
			get = "GetEnableFrameTexture",
			order = frameOrder.FRAME_TEXTURE,
		},
	},
}

ns.AddDemoOptions(frame.args, frameOrder)
ns.AddSizableOptions(frame.args, frameOrder)
ns.AddBackgroundTextureOptions(frame.args, frameOrder)

ns.options.args.party.args.frame = frame

function BUFPartyFrame:SetEnableFrameFlash(info, value)
	self:DbSet("enableFrameFlash", value)
	self:SetFrameFlash()
end

function BUFPartyFrame:GetEnableFrameFlash(info)
	return self:DbGet("enableFrameFlash")
end

function BUFPartyFrame:SetEnableFrameTexture(info, value)
	self:DbSet("enableFrameTexture", value)
	self:SetFrameTexture()
end

function BUFPartyFrame:GetEnableFrameTexture(info)
	return self:DbGet("enableFrameTexture")
end

function BUFPartyFrame:SetHorizontalMode(info, value)
	self:DbSet("useHorizontalLayout", value)
	self:SetSize()
end

function BUFPartyFrame:GetHorizontalMode(info)
	return self:DbGet("useHorizontalLayout")
end

function BUFPartyFrame:ToggleDemoMode()
	self:_ToggleDemoMode(self.frame)
	for _, bpi in ipairs(BUFParty.frames) do
		if self.demoMode then
			bpi.frame:Show()
		else
			bpi.frame:Hide()
		end
	end
end

function BUFPartyFrame:RefreshConfig()
	if not self.initialized then
		BUFParty.FrameInit(self)

		self.frame = PartyFrame

		-- Disable Blizzard's stock party status highlight texture for now.
		-- We will provide BUF-owned highlight visuals separately.
		for _, bpi in ipairs(BUFParty.frames) do
			local statusTexture = bpi.frame.PartyMemberOverlay and bpi.frame.PartyMemberOverlay.Status
			if statusTexture then
				statusTexture:Hide()
				if not BUFParty:IsHooked(statusTexture, "Show") then
					BUFParty:SecureHook(statusTexture, "Show", function(s)
						s:Hide()
					end)
				end
				if not BUFParty:IsHooked(statusTexture, "SetShown") then
					BUFParty:SecureHook(statusTexture, "SetShown", function(s, shown)
						if shown then
							s:Hide()
						end
					end)
				end
			end
		end
	end
	self:SetSize()
	self:SetFrameFlash()
	self:SetFrameTexture()
	self:RefreshBackgroundTexture()
end

function BUFPartyFrame:SetSize()
	for _, bpi in ipairs(BUFParty.frames) do
		self:_SetSize(bpi.frame)
	end
	local width = self:GetWidth()
	local height = self:GetHeight() * #BUFParty.frames

	self.frame:SetSize(width, height)

	if self.frame.Selection then
		self.frame.Selection:ClearAllPoints()
		self.frame.Selection:SetAllPoints(self.frame)
	end
end

function BUFPartyFrame:SetFrameFlash()
	local enable = self:GetEnableFrameFlash()
	if enable then
		for _, bpi in ipairs(BUFParty.frames) do
			BUFParty:Unhook(bpi.frame.Flash, "Show")
			bpi.frame.Flash:Show()
		end
	else
		for _, bpi in ipairs(BUFParty.frames) do
			bpi.frame.Flash:Hide()
			if not BUFParty:IsHooked(bpi.frame.Flash, "Show") then
				BUFParty:SecureHook(bpi.frame.Flash, "Show", function(s)
					s:Hide()
				end)
			end
		end
	end
end

function BUFPartyFrame:SetFrameTexture()
	local enable = self:GetEnableFrameTexture()
	if enable then
		for _, bpi in ipairs(BUFParty.frames) do
			BUFParty:Unhook(bpi.frame.Texture, "Show")
			BUFParty:Unhook(bpi.frame.VehicleTexture, "Show")
			BUFParty:Unhook(bpi.healthBarContainer.HealthBarMask, "Show")
			BUFParty:Unhook(bpi.manaBar.ManaBarMask, "Show")
			bpi.frame.Texture:Show()
			bpi.healthBarContainer.HealthBarMask:Show()
			bpi.manaBar.ManaBarMask:Show()
		end
	else
		for _, bpi in ipairs(BUFParty.frames) do
			bpi.frame.Texture:Hide()
			bpi.frame.VehicleTexture:Hide()
			bpi.healthBarContainer.HealthBarMask:Hide()
			bpi.manaBar.ManaBarMask:Hide()

			if not BUFParty:IsHooked(bpi.frame.Texture, "Show") then
				BUFParty:SecureHook(bpi.frame.Texture, "Show", function(s)
					s:Hide()
				end)
			end

			if not BUFParty:IsHooked(bpi.frame.VehicleTexture, "Show") then
				BUFParty:SecureHook(bpi.frame.VehicleTexture, "Show", function(s)
					s:Hide()
				end)
			end

			if not BUFParty:IsHooked(bpi.healthBarContainer.HealthBarMask, "Show") then
				BUFParty:SecureHook(bpi.healthBarContainer.HealthBarMask, "Show", function(s)
					s:Hide()
				end)
			end

			if not BUFParty:IsHooked(bpi.manaBar.ManaBarMask, "Show") then
				BUFParty:SecureHook(bpi.manaBar.ManaBarMask, "Show", function(s)
					s:Hide()
				end)
			end
		end
	end
end

function BUFPartyFrame:RefreshBackgroundTexture()
	local useBackgroundTexture = self:GetUseBackgroundTexture()
	local backgroundTexture = self:GetBackgroundTexture()

	for _, bpi in ipairs(BUFParty.frames) do
		if not useBackgroundTexture then
			if bpi.backdropFrame then
				bpi.backdropFrame:Hide()
			end
		else
			if not bpi.backdropFrame then
				bpi.backdropFrame = CreateFrame("Frame", nil, bpi.frame, "BackdropTemplate")
				bpi.backdropFrame:SetFrameStrata("BACKGROUND")
			end

			local bgTexturePath = ns.lsm:Fetch(ns.lsm.MediaType.BACKGROUND, backgroundTexture)
			if not bgTexturePath then
				bgTexturePath = "Interface/None"
			end

			bpi.backdropFrame:ClearAllPoints()
			bpi.backdropFrame:SetAllPoints(bpi.frame)

			bpi.backdropFrame:SetBackdrop({
				bgFile = bgTexturePath,
				edgeFile = nil,
				tile = true,
				tileSize = 16,
				edgeSize = 0,
				insets = { left = 0, right = 0, top = 0, bottom = 0 },
			})
			bpi.backdropFrame:Show()
		end
	end
end
