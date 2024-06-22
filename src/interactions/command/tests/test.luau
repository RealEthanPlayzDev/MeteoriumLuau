local DiscordLuau = require("@Discord-Luau/init")
local InteractionManager = require("../../../classes/interactionManager")

return {
    name = "Test",
    data = DiscordLuau.CommandBuilder.new()
        :setName("test")
        :setDescription("Test command for checking command handling and dispatching")
        :setType(DiscordLuau.CommandBuilder.Type.ChatInput)
        :addIntegration(DiscordLuau.CommandBuilder.IntegrationType.GuildCommand)
        :addIntegration(DiscordLuau.CommandBuilder.IntegrationType.UserCommand)
        :addContext(DiscordLuau.CommandBuilder.Context.Guild)
        :addContext(DiscordLuau.CommandBuilder.Context.BotDM),
    callback = function(interaction: DiscordLuau.DiscordInteraction, _: DiscordLuau.DiscordClient)
        local Message = DiscordLuau.MessageBuilder.new()
        Message:setContent(`OK`)
        return interaction:sendMessageAsync(Message)
    end
} :: InteractionManager.MeteoriumChatInputInteraction