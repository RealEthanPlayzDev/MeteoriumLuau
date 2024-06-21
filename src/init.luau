local DiscordLuau = require("@Discord-Luau/init")
local Env = require("../.env")

--// local Intents = DiscordLuau.IntentsBuilder.new({  })
local Settings = DiscordLuau.SettingsBuilder.new(Env.METEORIUM_TOKEN)
local Client = DiscordLuau.DiscordClient.new(Settings)

Client.eventManager.onReady:connect(function()
    print(`OK - {Client.discordUser.username}`)

    local Activity = DiscordLuau.ActivityBuilder.new()
    Activity:setActivityName("no")
    Activity:setActivityType(DiscordLuau.ActivityBuilder.Type.Game)

    local Presence = DiscordLuau.PresenceBuilder.new()
    Presence:setStatus(DiscordLuau.PresenceBuilder.Status.Idle)
    Presence:addActivity(Activity)
    Presence:setSince(0)

    Client:updatePresenceAsync(Presence):after(function()
        print("Presence update OK")
    end)
end)

Client:connectAsync()