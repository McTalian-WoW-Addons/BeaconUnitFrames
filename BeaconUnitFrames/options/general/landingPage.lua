---@type string
local addonName = select(1, ...)
---@class BUFNamespace
local ns = select(2, ...)

local acr = LibStub("AceConfigRegistry-3.0") --[[@as AceConfigRegistry-3.0]]

---@class BUFOptionsLandingPage: BUFParentHandler
local LandingPage = {}

LandingPage.optionsOrder = {
	TITLE = 1,
	IMAGE = 2,
	TOUR = 3,
	CONTINUE_TOUR = 4,
	ADDON_INFO = 5,
	VERSION = 6,
	AUTHOR = 7,
	CONTACT = 8,
	DISCORD = 9,
	GITHUB = 10,
	SPECIAL_THANKS = 11,
	TRANSLATORS = 12,
	SUPPORT = 13,
	MESSAGE = 14,
	COFFEE = 15,
}

LandingPage.optionsTable = {
	type = "group",
	name = ns.L["LandingPage"],
	handler = LandingPage,
	order = ns.OptionsGeneral.optionsOrder.LANDING_PAGE,
	args = {
		title = {
			type = "header",
			name = ns.L["LandingPageDesc"],
			order = LandingPage.optionsOrder.TITLE,
		},
		image = {
			type = "description",
			name = "",
			image = function()
				local path = "Interface/AddOns/BeaconUnitFrames/icons/logo.png"
				local width = 256
				local height = 256
				return path, width, height
			end,
			order = LandingPage.optionsOrder.IMAGE,
		},
		tour = {
			type = "execute",
			name = ns.L["Tour"],
			desc = ns.L["TourDesc"],
			func = "LaunchTour",
			width = "full",
			order = LandingPage.optionsOrder.TOUR,
		},
		continueTour = {
			type = "execute",
			name = ns.L["ContinueTour"],
			desc = ns.L["ContinueTourDesc"],
			func = "ContinueTour",
			width = "full",
			disabled = "IsContinueTourDisabled",
			order = LandingPage.optionsOrder.CONTINUE_TOUR,
		},
		addonInfo = {
			type = "header",
			name = ns.L["LandingPageAddonInfo"],
			order = LandingPage.optionsOrder.ADDON_INFO,
		},
		version = {
			type = "description",
			name = ns.L["Version"] .. " " .. ns.addonVersion,
			order = LandingPage.optionsOrder.VERSION,
		},
		author = {
			type = "description",
			name = ns.L["Author"] .. " McTalian",
			order = LandingPage.optionsOrder.AUTHOR,
		},
		contact = {
			type = "header",
			name = ns.L["Contact"],
			order = LandingPage.optionsOrder.CONTACT,
		},
		discord = {
			type = "description",
			name = ns.L["Discord"] .. " |cFF00AFF0https://discord.gg/czRYVWhe33|r",
			order = LandingPage.optionsOrder.DISCORD,
		},
		github = {
			type = "description",
			name = ns.L["GitHub"]
				.. " |cFF00AFF0https://github.com/McTalian-WoW-Addons/BeaconUnitFrames|r "
				.. ns.L["SubmitBugsAndFeatureRequestsHere"],
			order = LandingPage.optionsOrder.GITHUB,
		},
		-- Special Thanks and Translators will be added here once there are some
		support = {
			type = "header",
			name = ns.L["Support"],
			order = LandingPage.optionsOrder.SUPPORT,
		},
		message = {
			type = "description",
			name = ns.L["SupportMessage"],
			order = LandingPage.optionsOrder.MESSAGE,
		},
		coffee = {
			type = "description",
			name = ns.L["BuyMeACoffee"],
			order = LandingPage.optionsOrder.COFFEE,
		},
	},
}

function LandingPage:LaunchTour()
	ns.TourManager:LaunchTour()
end

function LandingPage:ContinueTour()
	ns.TourManager:ContinueTour()
end

function LandingPage:IsContinueTourDisabled()
	return ns.TourManager:areAllUnacknowledged() or ns.TourManager:areAllAcknowledged()
end

ns.options.args.general.args.landingPage = LandingPage.optionsTable

ns.LandingPage = LandingPage
