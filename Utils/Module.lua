local _ENV = (getgenv or getrenv or getfenv)()

local Utils = {}
local Settings = {}
local Threads = {}
local Fallback = {}

local Owner = "imdogkung3"
local Repository = "Sawyerx"

local THREAD_HASH = tostring(os.clock() + math.random()) do
    _ENV.__THREAD_HASH = THREAD_HASH
    _ENV.GLOBALS_SETTINGS = {}
end

local function fetch(file)
    local URL = string.format(
        "https://raw.githubusercontent.com/%s/%s/main/%s",
        Owner, Repository, file
    )

    return loadstring(game:HttpGet(URL))()
end

local function AddModule(Name, Module)
    do Utils[Name] = Module()
        return Utils[Name]
    end
end

local UserInputService = game:GetService('UserInputService')
local TeleportService = game:GetService('TeleportService')
local HttpService = game:GetService('HttpService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

AddModule("Connections", function()
    local Connections = {}
    local Cached = _ENV.Connections or {}

    do
        _ENV.Connections = Cached

        for i = 1, #Cached do
            Cached[i]:Disconnect()
        end

        table.clear(Cached)
    end

    function Connections.Connect(Instance, Callback)
        local Connection = Instance:Connect(Callback)

        table.insert(Cached, Connection)

        return Connection
    end 

    return Connections
end)

AddModule("Configurations", function()
    local Configurations = {}
    local Files = "Sawyerx"

    local makefolder = makefolder or function( ... ) return ... end
    local writefile = writefile or function( ... ) return ... end
    local isfolder = isfolder or function( ... ) return ... end
    local readfile = readfile or function( ... ) return ... end
    local isfile = isfile or function( ... ) return ... end

    Configurations.Files = Files or "Sawyerx"
    Configurations.Set = `{Files}/Settings`
    Configurations.FullPaths = `{Configurations.Set}/{game.PlaceId}.json`
    Configurations.Paths = { Files, Configurations.Set }

    do
        function Configurations:Folder()
            for i = 1, #self.Paths do
                local str = self.Paths[i]

                if not isfolder(str) then
                    makefolder(str)
                end
            end
        end

        function Configurations:Default(index, value)
            if Settings[index] == nil then
                Settings[index] = value
            end
        end

        function Configurations:Save(index, value)
            if index ~= nil then
                Settings[index] = value
            end

            if not isfolder(Files) then
                makefolder(Files)
            end

            if not isfolder(Configurations.Set) then
                makefolder(Configurations.Set)
            end

            writefile(Configurations.FullPaths, HttpService:JSONEncode(Settings))
        end

        function Configurations:Load()
            if not isfile(Configurations.FullPaths) then
                self:Save()
            end

            local Reader = readfile(Configurations.FullPaths) do
                return HttpService:JSONDecode(Reader) 
            end
        end 
    end

    do Configurations:Folder()
        Configurations:Default("Success", true)
    end

    return Configurations
end)

AddModule("Parallels", function()
    local Parallels = {}

    local Options = {}
    local clonedEnabled = {}
    local Functions = _ENV.FUNCTIONS or {}
    local FarmFunctions = _ENV.FARM_FUNCTIONS or {}

    local Enabled_Toggle_Debounce = false
    local Enabled_New_Values = {}

    do
        local function ShowErrorMessage(ErrorMessage)
            _ENV.OnFarm = false

            local text = (`error [ { _ENV.RunningOption or "Null" } ] { ErrorMessage }`)

            if _ENV.error_message then
                _ENV.error_message.Text ..= `\n\n{ text }`

                return nil
            end

            local Message = Instance.new("Message", workspace) do
                _ENV.error_message = Message
                Message.Text = text
            end
        end

        local function RunQueue(Options)
            local Success, ErrorMessage = pcall(function()
                local function GetQueue()
                    for _, Option in Options do

                        _ENV.RunningOption = Option.Name

                        local Method = Option.Function()

                        if Method then
                            if type(Method) == "string" then
                                _ENV.RunningMethod = Method
                            end

                            return Method
                        end
                    end

                    _ENV.RunningOption, _ENV.RunningMethod = nil, nil
                end

                while task.wait(0) do
                    if _ENV.__THREAD_HASH ~= THREAD_HASH then
                        _ENV.RunningOption, _ENV.RunningMethod = nil, nil
                        _ENV.OnFarm = false
                        warn('Break Old Queue')
                        break
                    end
                    
                    _ENV.OnFarm = if GetQueue() then true else false
                end
            end)

            if not Success then
                ShowErrorMessage(ErrorMessage)

                task.delay(3, function()
                    if _ENV.error_message then
                        _ENV.error_message.Text = "Sawyerx Shield\nStart Refresh Options ..."

                        task.wait(2)

                        if _ENV.RunningOption and Fallback[_ENV.RunningOption] then
                            Fallback[_ENV.RunningOption]:SetValue(false)
                            _ENV.error_message.Text = "Sawyerx Shield\nHas been Disabled " .. _ENV.RunningOption
                        end

                        task.wait(2)

                        _ENV.error_message:Destroy()
                        _ENV.error_message = nil

                        task.spawn(RunQueue, FarmFunctions)
                    end
                end)
            end
        end

        local function UpdateEnabledOptions()
            table.clear(FarmFunctions)

            for index, value in pairs(Enabled_New_Values) do
                clonedEnabled[index] = value or nil
                Enabled_New_Values[index] = nil
            end

            for i = 1, #Functions do
                local funcData = Functions[i]
                if clonedEnabled[funcData.Name] then
                    table.insert(FarmFunctions, funcData)
                end
            end
        end

        local Enabled = _ENV.ENABLED_OPTIONS or setmetatable({}, {
            __newindex = function(self, index, value)
                Enabled_New_Values[index] = value or false

                if not Enabled_Toggle_Debounce then
                    Enabled_Toggle_Debounce = false
                    task.spawn(UpdateEnabledOptions)
                end
            end,
            __index = clonedEnabled
        })

        do
            _ENV.FUNCTIONS = Functions
            _ENV.ENABLED_OPTIONS = Enabled
            _ENV.FARM_FUNCTIONS = FarmFunctions

            task.spawn(RunQueue, FarmFunctions)
        end

        do table.clear(Functions) end

        local index = {}

        local function While(a, b, c, d)
            while a do
                local t = tick()

                if c then c() end
                if d and d() then break end

                repeat
                    RunService.Heartbeat:Wait()
                until tick() - t >= (b or 0.1)
            end
        end

        local function NewOption(Tag, Function, Time)
            if Time then
                Threads[Tag] = function(Value)
                    While(Value, Time or 0.1, Function, function()
                        return not Value or _ENV.__THREAD_HASH ~= THREAD_HASH
                    end)
                end
            else
                local Data = { 
                    ["Name"] = Tag,
                    ["Function"] = Function
                }

                index[Tag] = Function
                table.insert(Functions, Data)
            end
        end

        Parallels.NewOption = NewOption
        Parallels.Options = function()
            return Enabled, Options
        end
    end

    return Parallels
end)

AddModule("Plugins", function()
    local Plugins = {}
    
    local Configurations = Utils.Configurations
    local Parallels = Utils.Parallels
    local Others = Utils.Others
    
    local Enabled, Options = Parallels.Options()
    local Library = fetch("Utils/Library.lua")

    function Plugins:Window(Info)
        self.Base = Library.Application("MyHub", {
            Title = Info[1],
            Footer = Info[2],
            Logo = Info[3]
        })

        return self.Base
    end

    function Plugins:NewPage(Info, Icon)
        return self.Base:MakeTab({
            Title = Info[1],
            Description = Info[2],
            Icon = Icon
        })
    end

    function Plugins:Section(Page, Info)
        return Page:Section(Info[1])
    end

    function Plugins:Button(Section, Info, Callback)
        return Section:Button({
            Title = Info[1],
            Description = Info[2],
            Type = Info[3] or "Primary",
            Callback = Callback
        })
    end

    function Plugins:Toggle(Section, Info, Flag, Callback)
        local Thread = nil

        Fallback[Flag] = Section:Toggle({
            Title = Info[1],
            Description = Info[2],
            Value = Settings[Flag],
            Callback = function(_, Value)
                _ENV.GLOBALS_SETTINGS[Flag] = Value

                Settings[Flag] = Value
                Configurations:Save(Flag, Value)
                Enabled[Flag] = Value

                if Value then
                    Thread = task.spawn(function()
                        if Threads[Flag] then
                            Threads[Flag](Settings[Flag])
                        end
                    end)
                else
                    if Thread then
                        task.cancel(Thread)
                    end
                end

                if Callback then
                    Callback(Value)
                end
            end
        })

        return Fallback[Flag]
    end

    function Plugins:Slider(Section, Info, Value, Flag, Callback)
        return Section:Slider({
            Title = Info[1],
            Description = Info[2],
            Min = Value[1],
            Max = Value[2],
            Rounding = Value[3],
            Value = Settings[Flag],
            Callback = function(_, NewValue)
                Settings[Flag] = NewValue
                Configurations:Save(Flag, NewValue)
                _ENV.GLOBALS_SETTINGS[Flag] = NewValue

                if Callback then
                    Callback(NewValue)
                end
            end
        })
    end

    function Plugins:Dropdown(Section, Info, List, Flag, Callback)
        return Section:Dropdown({
            Title = Info,
            List = List,
            Value = Settings[Flag] or "None",
            Callback = function(_, Value)
                Settings[Flag] = Value
                Configurations:Save(Flag, Value)
                _ENV.GLOBALS_SETTINGS[Flag] = Value

                if Callback then
                    Callback(Value)
                end
            end
        })
    end

    function Plugins:Input(Section, Info, Flag, Callback)
        return Section:Textbox({
            Title = Info[1],
            Description = Info[2],
            Value = Settings[Flag] or "None",
            TypeOfValue = "string",
            Callback = function(_, Value)
                Settings[Flag] = Value
                Configurations:Save(Flag, Value)
                _ENV.GLOBALS_SETTINGS[Flag] = Value

                if Callback then
                    Callback(Value)
                end
            end
        })
    end

    function Plugins:TextLabel(Section, Info)
        local Label = Section:Paragraph({
            Title = Info[1],
            Description = Info[2]
        })

        if Info[4] then
            Label:Typography(Info[4])
        end

        return Label
    end
    
    return Plugins
end)

do
    Settings = Utils.Configurations:Load()
    Utils.Settings = Settings
end

return Utils
