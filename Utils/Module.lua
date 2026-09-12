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

    warn("Fetch : ", file)

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

AddModule("Others", function()
    local Others = {}

    Others.Server = (function()
        local Server = {}

        function Server:Reversed(cursor)
            local url = `https://games.roblox.com/v1/games/{PlaceId}/servers/Public?sortOrder=Asc&limit=100`

            if cursor then
                url ..= `&cursor={cursor}`
            end

            return HttpService:JSONDecode(game:HttpGet(url))
        end

        function Server:Rejoin()
            if #Players:GetPlayers() <= 1 then
                LocalPlayer:Kick("\nRejoining");wait()

                return TeleportService:Teleport(PlaceId, LocalPlayer)
            end

            return TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
        end

        function Server:Change()
            local Server, Next

            repeat
                local Servers = Server:Reversed(Next)

                Server = Servers and Servers.data and Servers.data[1]
                Next = Servers and Servers.nextPageCursor
            until Server

            if not Server or not Server.id then return end
            return TeleportService:TeleportToPlaceInstance(PlaceId, Server.id, LocalPlayer)
        end

        function Server:Join(id)
            return TeleportService:TeleportToPlaceInstance(PlaceId, id, LocalPlayer)
        end

        return Server
    end)()

    Others.Optimize = (function()
        local Optimize = {}

        function Optimize:Set3d(value)
            RunService:Set3dRenderingEnabled(if value then false else true)
        end

        function Optimize:Low()
            local Terrain = workspace:FindFirstChildOfClass('Terrain') do
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 0
                game.Lighting.GlobalShadows = false
                game.Lighting.FogEnd = 9e9
                settings().Rendering.QualityLevel = 1
            end
        end

        return Optimize
    end)()

    return Others
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
    local Fluent = fetch('Utils/Fluent.lua')
    
    function Plugins:Window(Info)
        self.Base = Fluent:CreateWindow({
            Title = Info[1],
            TabWidth = 120,
            Size = UDim2.fromOffset(475, 300),
            Acrylic = false,
            Theme = "Dark",
            MinimizeKey = Enum.KeyCode.LeftControl
        })
        
        return self.Base
    end
    
    function Plugins:NewPage(Title, Icon)
        return self.Base:AddTab({
            Title = Title,
            Icon = "rbxassetid://" .. Icon
        })
    end
    
    function Plugins:Section(Page, Info)
        return Page:AddSection(Info[1])
    end
    
    function Plugins:Button(Section, Info, Callback)
        return Section:AddButton({
            Title = Info[1],
            Description = Info[2],
            Callback = Callback
        })
    end
    
    function Plugins:Toggle(Section, Info, Flag, Callback)
        local Thread = nil

        Fallback[Flag] = Section:AddToggle(Flag, {
            Title = Info[1],
            Description = Info[2],
            Default = Settings[Flag] or false
        })

        Fallback[Flag]:OnChanged(function(Value)
            _ENV.GLOBALS_SETTINGS[Flag] = Value
            
            Settings[Flag] = Value
            Configurations:Save(Flag, Value)
            Enabled[Flag] = Value

            if Value then
                Thread = task.spawn(function()
                    if Threads[Flag] then Threads[Flag](Settings[Flag]) end
                end)
            else
                if Thread then task.cancel(Thread) end
                Thread = nil
            end

            if Callback then Callback(Value) end
        end)

        return Fallback[Flag]
    end
    
    function Plugins:Slider(Section, Info, Value, Flag, Callback)
        local Slider = Section:AddSlider(Flag, {
            Title = Info[1],
            Description = Info[2],
            Default = Settings[Flag] or Value[1],
            Min = Value[1],
            Max = Value[2],
            Rounding = Value[3]
        })

        Slider:OnChanged(function(Value)
            Settings[Flag] = Value
            Configurations:Save(Flag, Value)
            _ENV.GLOBALS_SETTINGS[Flag] = Value
            
            if Callback then Callback(Value) end
        end)

        return Slider
    end
                                
    function Plugins:Dropdown(Section, Info, List, Flag, Multi, Callback)
        local Dropdown = Section:AddDropdown(Flag, {
            Title = Info,
            Values = List,
            Multi = Multi or false,
            Default = Settings[Flag] or (Multi and {} or List[1])
        })

        Dropdown:OnChanged(function(Value)
            if Multi then
                local Values = {}

                for i, v in next, Value do
                    if v and table.find(List, i) then
                        table.insert(Values, i)
                    end
                end

                Settings[Flag] = Values
                _ENV.GLOBALS_SETTINGS[Flag] = Values
                Configurations:Save(Flag, Values)

                if Callback then Callback(Values) end
            else
                Settings[Flag] = Value
                _ENV.GLOBALS_SETTINGS[Flag] = Value
                Configurations:Save(Flag, Value)

                if Callback then Callback(Value) end
            end
        end)

        return Dropdown
    end
    
    function Plugins:Input(Section, Info, Flag, Callback)
        local Input = Section:AddInput(Flag, {
            Title = Info[1],
            Description = Info[2],
            Default = Settings[Flag] or "",
            Placeholder = Info[1],
            Numeric = false,
            Finished = false
        })

        Input:OnChanged(function(Value)
            Settings[Flag] = Value
            Configurations:Save(Flag, Value)
            _ENV.GLOBALS_SETTINGS[Flag] = Value
            
            if Callback then Callback(Value) end
        end)

        return Input
    end
    
    function Plugins:TextLabel(Section, Info)
        return Section:AddParagraph({
            Title = Info[1],
            Content = Info[2] or ""
        })
    end
    
    function Plugins:Managers()
        local Managers = Plugins:NewPage("Managers", 134261589888025) do
            local Server = Plugins:Section(Managers, { "Server" }) do
                Configurations:Default("JobId", JobId)

                Plugins:Input(Server, { "JobId", "Put the job id." }, "JobId")

                Plugins:Button(Server, { "Join", "Connect to the server using the provided JobId." }, function()
                    Others.Server:Join(Settings.JobId)
                end)

                Plugins:Button(Server, { "Change", "Teleport to a different public server instance." }, function()
                    Others.Server:Change()
                end)

                Plugins:Button(Server, { "Rejoin", "Reconnect to the current server instance." }, function()
                    Others.Server:Rejoin()
                end)
            end
            
            local Optimization = Plugins:Section(Managers, { "Optimization" }) do
                Plugins:Toggle(Optimization, { "White Screen", "Disabled 3D Rendering to improve performance" }, "White Screen", function(Value)
                    Others.Optimize:Set3d(Value)
                end)

                Plugins:Button(Optimization, { "Fast Mode", "Set graphics quality to low" }, function()
                    Others.Optimize:Low()
                end)
            end
            
            local Interface = Plugins:Section(Managers, { "Interface" }) do
                Plugins:Button(Interface, { "Remove Worksapce", "Reset save setting file to default value." }, function()
                    local Files = Configurations.FullPaths

                    if Files and isfile(Files) then
                        pcall(delfile, Files)
                        warn("Remove Success")
                    else
                        warn("File not found")
                    end
                end)
            end
        end
        
        return Managers
    end
    
    return Plugins
end)

do
    Settings = Utils.Configurations:Load()
    Utils.Settings = Settings
end

return Utils
