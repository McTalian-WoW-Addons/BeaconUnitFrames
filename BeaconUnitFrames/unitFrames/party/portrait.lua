---@class BUFNamespace
local ns = select(2, ...)

---@class BUFParty
local BUFParty = ns.BUFParty

---@class BUFParty.Portrait: BUFFramePortrait
local BUFPartyPortrait = {
	configPath = "unitFrames.party.portrait",
	frameKey = BUFParty.relativeToFrames.PORTRAIT,
	module = BUFParty,
}

BUFPartyPortrait.optionsTable = {
	type = "group",
	handler = BUFPartyPortrait,
	name = ns.L["Portrait"],
	order = BUFParty.optionsOrder.PORTRAIT,
	args = {},
}

---@class BUFDbSchema.UF.Party.Portrait
BUFPartyPortrait.dbDefaults = {
	enabled = true,
	width = 37,
	height = 37,
	scale = 1.0,
	anchorPoint = "TOPLEFT",
	relativeTo = BUFParty.relativeToFrames.FRAME,
	relativePoint = "TOPLEFT",
	xOffset = 7,
	yOffset = -6,
	mask = "interface/hud/uiunitframeplayerportraitmask.blp",
	maskWidthScale = 1,
	maskHeightScale = 1,
	alpha = 1.0,
}

ns.BUFFramePortrait:ApplyMixin(BUFPartyPortrait)
ns.Mixin(BUFPartyPortrait, ns.BUFPartyPositionable)

---@class BUFDbSchema.UF.Party
ns.dbDefaults.profile.unitFrames.party = ns.dbDefaults.profile.unitFrames.party
ns.dbDefaults.profile.unitFrames.party.portrait = BUFPartyPortrait.dbDefaults

ns.options.args.party.args.portrait = BUFPartyPortrait.optionsTable

function BUFPartyPortrait:RefreshConfig()
	if not self.initialized then
		BUFParty.FrameInit(self)

		for _, bpi in ipairs(BUFParty.frames) do
			bpi.portrait = {}
			bpi.portrait.texture = bpi.frame.Portrait
			bpi.portrait.texture.bufOverrideParentFrame = bpi.frame
			bpi.portrait.maskTexture = bpi.frame.PortraitMask
		end
	end

	self:RefreshPortraitConfig()
	BUFParty:RefreshPartyHighlights()
end

function BUFPartyPortrait:ToggleDemoMode()
	self.demoMode = not self.demoMode
	for _, bpi in ipairs(BUFParty.frames) do
		if self.demoMode then
			bpi.portrait.texture:Show()
			bpi.portrait.maskTexture:Show()
			if UnitExists(bpi.unit) then
				RunNextFrame(function()
					SetPortraitTexture(bpi.portrait.texture, bpi.unit)
				end)
			else
				SetPortraitTexture(bpi.portrait.texture, "player")
			end
		else
			bpi.portrait.texture:Hide()
			bpi.portrait.maskTexture:Hide()
		end
	end
end

function BUFPartyPortrait:ShowHidePortrait()
	for _, bpi in ipairs(BUFParty.frames) do
		self:_ShowHidePortrait(bpi.portrait.texture, bpi.portrait.maskTexture)
		bpi.frame.showPortrait = self:GetEnabled()
		if UnitExists(bpi.unit) then
			RunNextFrame(function()
				SetPortraitTexture(bpi.portrait.texture, bpi.unit)
			end)
		end
	end
end

function BUFPartyPortrait:SetSize()
	for _, bpi in ipairs(BUFParty.frames) do
		self:_SetPortraitSize(bpi.portrait.texture, bpi.portrait.maskTexture)
	end
end

function BUFPartyPortrait:SetPosition()
	for _, bpi in ipairs(BUFParty.frames) do
		self:_SetPortraitPosition(bpi.portrait.texture, bpi.portrait.maskTexture)
	end
end

function BUFPartyPortrait:SetScaleFactor()
	for _, bpi in ipairs(BUFParty.frames) do
		self:_SetPortraitScaleFactor(bpi.portrait.texture, bpi.portrait.maskTexture)
	end
end

function BUFPartyPortrait:RefreshMask()
	for _, bpi in ipairs(BUFParty.frames) do
		self:_RefreshMask(bpi.portrait.maskTexture)
	end
end

BUFParty.Portrait = BUFPartyPortrait
