local DiscordLuau = require("@Discord-Luau/init")
local Logging = require("./classes/logging")
local MeteoriumInteractionManager = require("./classes/interactionManager")
local Env = require("../.env")

local LoggingRoot = Logging.new("MeteoriumLuau")
local Settings = DiscordLuau.SettingsBuilder.new(Env.METEORIUM_BOT_TOKEN)
local Client = DiscordLuau.DiscordClient.new(Settings)
local InteractionManager = MeteoriumInteractionManager.new(Client, LoggingRoot:registerNamespace("InteractionManager"))

InteractionManager:registerAllInteractions()

local ReadyNS = LoggingRoot:getNamespace("EventManager"):registerNamespace("Ready")
Client.eventManager.onReady:connect(function()
    ReadyNS:info(`OK - {Client.discordUser.username}`)

    local Activity = DiscordLuau.ActivityBuilder.new()
    Activity:setActivityName("no")
    Activity:setActivityType(DiscordLuau.ActivityBuilder.Type.Game)

    local Presence = DiscordLuau.PresenceBuilder.new()
    Presence:setStatus(DiscordLuau.PresenceBuilder.Status.Idle)
    Presence:addActivity(Activity)
    Presence:setSince(0)

    Client:updatePresenceAsync(Presence):after(function()
        ReadyNS:info("Presence update OK")
    end)

    Client.discordApplication:setSlashCommandsAsync(InteractionManager:mergeAllCommandBuilders()):after(function()
        ReadyNS:info("Updated interactions registry")
    end)
end)

Client.eventManager.onInteraction:connect(function(interaction: DiscordLuau.DiscordInteraction)
    InteractionManager:dispatchInteraction(interaction)
    return
end)

Client:connectAsync()