local stdio = require("@lune/stdio")

local function getCurrentDTStr()
    return os.date("%d-%m-%Y %I:%M:%S %p %z")
end

local function getFullName(obj: LoggingNamespace)
    local name = obj.name
    local ptr: any = obj.parent
    while (ptr ~= nil) do
        name = `{ptr.name}/{name}`
        ptr = ptr.parent
    end
    --name = `{ptr.name}/{name}`
    return name
end

local LoggingNamespace = {}
LoggingNamespace.__index = LoggingNamespace
LoggingNamespace.__tostring = function() return "LoggingNamespace" end

local function constructor_LoggingNamespace(name: string, root: unknown)
    return setmetatable({
        name = name,
        namespaces = {} :: { LoggingNamespace },
        parent = root :: Logging | LoggingNamespace
    }, LoggingNamespace)
end
export type LoggingNamespace = typeof(constructor_LoggingNamespace(""))

function LoggingNamespace.registerNamespace(self: LoggingNamespace, name: string): LoggingNamespace
    local namespace = constructor_LoggingNamespace(name, self)
    table.insert(self.namespaces, namespace)
    return namespace
end

function LoggingNamespace.getNamespace(self: LoggingNamespace, name: string): LoggingNamespace?
    for _, namespace in self.namespaces do
        if (namespace.name == name) then
            return namespace
        end
    end
    return nil
end

function LoggingNamespace.write(_: LoggingNamespace, color: stdio.Color, ... : any)
    stdio.write(stdio.color(color))
    print(...)
    stdio.write(stdio.color("reset"))
    stdio.write(stdio.style("reset"))
    return
end

function LoggingNamespace.verbose(self: LoggingNamespace, ... : any)
    return self:write("white", `[{getCurrentDTStr()}] [VRB] [{getFullName(self)}]`, ...)
end

function LoggingNamespace.debug(self: LoggingNamespace, ... : any)
    return self:write("green", `[{getCurrentDTStr()}] [DBG] [{getFullName(self)}]`, ...)
end

function LoggingNamespace.info(self: LoggingNamespace, ... : any)
    return self:write("cyan", `[{getCurrentDTStr()}] [INF] [{getFullName(self)}]`, ...)
end

function LoggingNamespace.warn(self: LoggingNamespace, ... : any)
    return self:write("yellow", `[{getCurrentDTStr()}] [WRN] [{getFullName(self)}]`, ...)
end

function LoggingNamespace.error(self: LoggingNamespace, ... : any)
    return self:write("red", `[{getCurrentDTStr()}] [ERR] [{getFullName(self)}]`, ...)
end

local Logging = {}
Logging.__index = Logging
Logging.__tostring = function(self: Logging) return `Logging<{self.name}>` end

local function constructor_Logging(name: string)
    return setmetatable({
        name = name,
        namespaces = {} :: { LoggingNamespace }
    }, Logging)
end
export type Logging = typeof(constructor_Logging(""))

function Logging.registerNamespace(self: Logging, name: string): LoggingNamespace
    local namespace = constructor_LoggingNamespace(name, self)
    table.insert(self.namespaces, namespace)
    return namespace
end

function Logging.getNamespace(self: Logging, name: string): LoggingNamespace?
    for _, namespace in self.namespaces do
        if (namespace.name == name) then
            return namespace
        end
    end
    return nil
end

return { new = constructor_Logging }