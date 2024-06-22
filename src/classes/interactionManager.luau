local DiscordLuau = require("@Discord-Luau/init")
local Logging = require("./logging")
local Env = require("../../.env")
local fs = require("@lune/fs")

local MeteoriumInteractionManager = {}
MeteoriumInteractionManager.__index = MeteoriumInteractionManager
MeteoriumInteractionManager.__tostring = function() return "MeteoriumInteractionManager" end
MeteoriumInteractionManager.__metatable = "MeteoriumInteractionManager"

local function constructor(client: DiscordLuau.DiscordClient, lns: Logging.LoggingNamespace)
    return setmetatable({
        Client = client,
        Logging = lns,
        ChatInputInteractions = {} :: { [string]: MeteoriumChatInputInteraction },
    }, MeteoriumInteractionManager)
end

export type MeteoriumInteractionManager = typeof(constructor(DiscordLuau.DiscordClient.new(DiscordLuau.SettingsBuilder.new("")), Logging.new(""):registerNamespace("")))
export type MeteoriumInteraction = {
    name: string,
    data: DiscordLuau.CommandBuilder,
    callback: (interaction: DiscordLuau.DiscordInteraction, client: DiscordLuau.DiscordClient) -> any,
    initialize: ((client: DiscordLuau.DiscordClient) -> any)?
}
export type MeteoriumChatInputInteraction = MeteoriumInteraction & {
    autocomplete: (interaction: DiscordLuau.DiscordInteraction, client: DiscordLuau.DiscordClient) -> any,
}
export type MeteoriumMessageContextMenuInteraction = MeteoriumInteraction
export type MeteoriumUserContextMenuInteraction = MeteoriumInteraction

function MeteoriumInteractionManager.registerChatInputInteractions(self: MeteoriumInteractionManager)
    self.Logging:info("Registering ChatInput interactions")
    for _, folderName in fs.readDir("./src/interactions/command") do
        if (Env.METEORIUM_NOREG_TESTINTERACTIONS) and (folderName == "tests") then continue end

        local path = `./src/interactions/command/{folderName}`
        if (not fs.isDir(path)) then continue end

        for _, commandFileName in fs.readDir(path) do
            local commandFilePath = `{path}/{commandFileName}`
            if (not fs.isFile(commandFilePath)) then continue end
            
            self.Logging:verbose(`Registering -> {commandFilePath}`)
            local Success, Error = pcall(function()
                local Result = require(`../interactions/command/{folderName}/{string.gsub(commandFileName, ".luau", "")}`) :: MeteoriumChatInputInteraction
                assert(Result.data.commandType == DiscordLuau.CommandBuilder.Type.ChatInput, `Not a ChatInput interaction -> {commandFilePath}`)
                self.ChatInputInteractions[Result.name] = Result
                if (Result.initialize) then
                    self.Logging:verbose(`Init -> {commandFilePath}`)
                    Result.initialize(self.Client)
                end
            end)
            
            if (not Success) then
                self.Logging:error(`Could not register -> {commandFilePath}:\n{Error}`)
            end
        end
    end
end

function MeteoriumInteractionManager.registerAllInteractions(self: MeteoriumInteractionManager)
    self:registerChatInputInteractions()
    return
end

function MeteoriumInteractionManager.mergeAllCommandBuilders(self: MeteoriumInteractionManager)
    local Data = {}
    for _, command in self.ChatInputInteractions do
        table.insert(Data, command.data)
    end
    return Data
end

function MeteoriumInteractionManager.dispatchInteraction(self: MeteoriumInteractionManager, interaction: DiscordLuau.DiscordInteraction): any
    self.Logging:debug(`Dispatch: {interaction.data.name} ({interaction.data.id} - {interaction.data.types})`)
    if (interaction.data.types == nil) then
        local Selected: MeteoriumChatInputInteraction
        for _, command in self.ChatInputInteractions do
            if (command.data.commandName == interaction.data.name) then
                Selected = command
            end
        end
        if (not Selected) then
            self.Logging:error(`Could not find command {interaction.data.name} ({interaction.data.id} - {interaction.data.types})`)
            return interaction:sendMessageAsync(DiscordLuau.MessageBuilder.new():setContent("(Internal error - command not found)"))
        end
        Selected.callback(interaction, self.Client)
        return
    end
    return
end

return { new = constructor }