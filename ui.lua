-- Services 
local InputService  = game:GetService("UserInputService")
local HttpService   = game:GetService("HttpService")
local GuiService    = game:GetService("GuiService")
local RunService    = game:GetService("RunService")
local CoreGui       = game:GetService("CoreGui")
local TweenService  = game:GetService("TweenService")
local Workspace     = game:GetService("Workspace")
local Players       = game:GetService("Players")

local lp            = Players.LocalPlayer
local mouse         = lp:GetMouse()

-- Short aliases
local vec2          = Vector2.new
local dim2          = UDim2.new
local dim           = UDim.new
local rect          = Rect.new
local dim_offset    = UDim2.fromOffset
local rgb           = Color3.fromRGB
local hex           = Color3.fromHex

-- Library init / globals
getgenv().Pulse = getgenv().Pulse or {}
local Pulse = getgenv().Pulse

Pulse.Directory    = "Pulse.gg"
Pulse.Folders      = {"/configs"}
Pulse.Flags        = {}
Pulse.ConfigFlags  = {}
Pulse.Connections  = {}
Pulse.Notifications= {Notifs = {}}
Pulse.__index      = Pulse

local Flags          = Pulse.Flags
local ConfigFlags    = Pulse.ConfigFlags
local Notifications  = Pulse.Notifications

local themes = {
    preset = {
        accent       = rgb(130, 150, 255),   -- Premium Blue/Purple
        
        background   = rgb(18, 18, 22),      -- Deep Dark Background
        section      = rgb(24, 24, 28),      -- Section Background
        element      = rgb(30, 30, 34),      -- Element Background
        
        outline      = rgb(40, 40, 45),      -- Subtle Outline
        text         = rgb(235, 235, 235),   -- Main Text
        subtext      = rgb(130, 130, 135),   -- Faded Subtext
        
        tab_active   = rgb(130, 150, 255),   
        tab_inactive = rgb(18, 18, 22), 
    },
    utility = {}
}

for property, _ in themes.preset do
    themes.utility[property] = {
        BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}, Color = {}, ScrollBarImageColor3 = {}
    }
end

local Keys = {
    [Enum.KeyCode.LeftShift] = "LS", [Enum.KeyCode.RightShift] = "RS",
    [Enum.KeyCode.LeftControl] = "LC", [Enum.KeyCode.RightControl] = "RC",
    [Enum.KeyCode.Insert] = "INS", [Enum.KeyCode.Backspace] = "BS",
    [Enum.KeyCode.Return] = "Ent", [Enum.KeyCode.Escape] = "ESC",
    [Enum.KeyCode.Space] = "SPC", [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2", [Enum.UserInputType.MouseButton3] = "MB3"
}

for _, path in Pulse.Folders do
    pcall(function() makefolder(Pulse.Directory .. path) end)
end

-- misc helpers ok 
function Pulse:Tween(Object, Properties, Info)
    if not Object then return end
    local tween = TweenService:Create(Object, Info or TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), Properties)
    tween:Play()
    return tween
end

function Pulse:Create(instance, options)
    local ins = Instance.new(instance)
    for prop, value in options do ins[prop] = value end
    if ins:IsA("TextButton") or ins:IsA("ImageButton") then ins.AutoButtonColor = false end
    return ins
end

-- Much stronger contrast so gradients are very visible on tiny sliders/toggles
local function AddSubtleGradient(parent, rotation)
    return Pulse:Create("UIGradient", {
        Parent = parent,
        Rotation = rotation or 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, rgb(255, 255, 255)),
            ColorSequenceKeypoint.new(1, rgb(110, 110, 110)) -- Darker bottom for highly visible 3D shading
        })
    })
end

function Pulse:Themify(instance, theme, property)
    if not themes.utility[theme] then return end
    table.insert(themes.utility[theme][property], instance)
    instance[property] = themes.preset[theme]
end

function Pulse:RefreshTheme(theme, color3)
    themes.preset[theme] = color3
    for property, instances in themes.utility[theme] do
        for _, object in instances do
            object[property] = color3
        end
    end
end

function Pulse:Resizify(Parent)
    local UIS = game:GetService("UserInputService")
    local Resizing = Pulse:Create("TextButton", {
        AnchorPoint = vec2(1, 1), Position = dim2(1, 0, 1, 0), Size = dim2(0, 34, 0, 34),
        BorderSizePixel = 0, BackgroundTransparency = 1, Text = "", Parent = Parent, ZIndex = 999,
    })
    
    local grip = Pulse:Create("ImageLabel", {
        Parent = Resizing,
        AnchorPoint = vec2(1, 1),
        Position = dim2(1, -4, 1, -4),
        Size = dim2(0, 20, 0, 20),
        BackgroundTransparency = 1,
        Image = "rbxthumb://type=Asset&id=6153965696&w=150&h=150",
        ImageColor3 = themes.preset.accent,
        ImageTransparency = 0.5
    })
    
    Pulse:Themify(grip, "accent", "ImageColor3")

    local IsResizing, StartInputPos, StartSize = false, nil, nil
    local MIN_SIZE = vec2(600, 450)
    local MAX_SIZE = vec2(1000, 800)

    Resizing.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            IsResizing = true
            StartInputPos = input.Position
            StartSize = Parent.AbsoluteSize
        end
    end)

    Resizing.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            IsResizing = false
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if not IsResizing then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - StartInputPos
            Parent.Size = UDim2.fromOffset(
                math.clamp(StartSize.X + delta.X, MIN_SIZE.X, MAX_SIZE.X),
                math.clamp(StartSize.Y + delta.Y, MIN_SIZE.Y, MAX_SIZE.Y)
            )
        end
    end)
end

-- window hahaa
function Pulse:Window(properties)
    local Cfg = {
        Title = properties.Title or properties.title or properties.Prefix or "Pulse", 
        Subtitle = properties.Subtitle or properties.subtitle or properties.Suffix or ".cc",
        Size = properties.Size or properties.size or dim2(0, 720, 0, 500), 
        TabInfo = nil, Items = {}, Tweening = false, IsSwitchingTab = false;
    }

    if Pulse.Gui then Pulse.Gui:Destroy() end
    if Pulse.Other then Pulse.Other:Destroy() end
    if Pulse.ToggleGui then Pulse.ToggleGui:Destroy() end

    Pulse.Gui = Pulse:Create("ScreenGui", { Parent = CoreGui, Name = "PulseGG", Enabled = true, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
    Pulse.Other = Pulse:Create("ScreenGui", { Parent = CoreGui, Name = "PulseOther", Enabled = false, IgnoreGuiInset = true })
    
    local Items = Cfg.Items
    local uiVisible = true

    Items.Wrapper = Pulse:Create("Frame", {
        Parent = Pulse.Gui, Position = dim2(0.5, -Cfg.Size.X.Offset / 2, 0.5, -Cfg.Size.Y.Offset / 2),
        Size = Cfg.Size, BackgroundTransparency = 1, BorderSizePixel = 0
    })
    

    Items.Window = Pulse:Create("Frame", {
        Parent = Items.Wrapper, Position = dim2(0, 0, 0, 0), Size = dim2(1, 0, 1, 0),
        BackgroundColor3 = themes.preset.background, BorderSizePixel = 0, ZIndex = 1, ClipsDescendants = true
    })
    Pulse:Themify(Items.Window, "background", "BackgroundColor3")
    Pulse:Create("UICorner", { Parent = Items.Window, CornerRadius = dim(0, 8) })
    Pulse:Themify(Pulse:Create("UIStroke", { Parent = Items.Window, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    -- Sidebar (Left)
    Items.Sidebar = Pulse:Create("Frame", {
        Parent = Items.Window, Size = dim2(0, 80, 1, 0), BackgroundColor3 = rgb(12, 12, 15), BorderSizePixel = 0, ZIndex = 2
    })
    Pulse:Create("UICorner", { Parent = Items.Sidebar, CornerRadius = dim(0, 8) })
    
    Items.Logo = Pulse:Create("ImageLabel", {
        Parent = Items.Sidebar, Position = dim2(0.5, 0, 0, 30), Size = dim2(0, 32, 0, 32), AnchorPoint = vec2(0.5, 0),
        BackgroundTransparency = 1, Image = "rbxassetid://13110298032", -- Placeholder logo
        ImageColor3 = themes.preset.accent, ZIndex = 3
    })
    Pulse:Themify(Items.Logo, "accent", "ImageColor3")

    Items.TabList = Pulse:Create("Frame", {
        Parent = Items.Sidebar, Position = dim2(0, 0, 0, 80), Size = dim2(1, 0, 1, -160), BackgroundTransparency = 1, ZIndex = 3
    })
    Pulse:Create("UIListLayout", { Parent = Items.TabList, Padding = dim(0, 15), HorizontalAlignment = Enum.HorizontalAlignment.Center })

    -- Header (Top Area for Tabs)
    Items.Header = Pulse:Create("Frame", { 
        Parent = Items.Window, Position = dim2(0, 80, 0, 0), Size = dim2(1, -80, 0, 50), 
        BackgroundTransparency = 1, Active = true, ZIndex = 2 
    })

    Items.TabHolder = Pulse:Create("Frame", { 
        Parent = Items.Header, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 20, 0.5, 0),
        Size = dim2(1, -60, 1, 0), BackgroundTransparency = 1, ZIndex = 4
    })
     Pulse:Create("UIListLayout", { Parent = Items.TabHolder, FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = dim(0, 12) })

    Items.SearchBtn = Pulse:Create("ImageButton", {
        Parent = Items.Header, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -20, 0.5, 0),
        Size = dim2(0, 18, 0, 18), BackgroundTransparency = 1, Image = "rbxassetid://11293977111", -- Search icon
        ImageColor3 = themes.preset.subtext, ZIndex = 5
    })
    Pulse:Themify(Items.SearchBtn, "subtext", "ImageColor3")

    -- User Area (Sidebar Bottom)
    local headshot = "rbxthumb://type=AvatarHeadShot&id="..lp.UserId.."&w=48&h=48"
    Items.UserFrame = Pulse:Create("Frame", {
        Parent = Items.Sidebar, AnchorPoint = vec2(0.5, 1), Position = dim2(0.5, 0, 1, -20),
        Size = dim2(0, 40, 0, 40), BackgroundColor3 = themes.preset.element, BorderSizePixel = 0, ZIndex = 5
    })
    Pulse:Themify(Items.UserFrame, "element", "BackgroundColor3")
    Pulse:Create("UICorner", { Parent = Items.UserFrame, CornerRadius = dim(1, 0) })
    
    Items.Avatar = Pulse:Create("ImageLabel", { 
        Parent = Items.UserFrame, AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0), 
        Size = dim2(0.8, 0, 0.8, 0), BackgroundTransparency = 1, Image = headshot, ZIndex = 6 
    })
    Pulse:Create("UICorner", { Parent = Items.Avatar, CornerRadius = dim(1, 0) })

    Items.PageHolder = Pulse:Create("Frame", { 
        Parent = Items.Window, Position = dim2(0, 80, 0, 50), Size = dim2(1, -80, 1, -50), 
        BackgroundTransparency = 1, ClipsDescendants = true 
    })

    -- Watermark System (Floating)
    local drawWatermark = properties.Watermark
    if drawWatermark == nil then drawWatermark = true end

    Pulse.Watermark = Pulse:Create("Frame", {
        Parent = Pulse.Gui, Position = dim2(1, -20, 0, 20), AnchorPoint = vec2(1, 0),
        Size = dim2(0, 0, 0, 0), BackgroundTransparency = 1, ZIndex = 1000, AutomaticSize = Enum.AutomaticSize.XY
    })
    Pulse:Create("UIListLayout", { Parent = Pulse.Watermark, FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = dim(0, 6) })

    local function CreateStatusBox(icon, text_content, isRich, iconColor)
        local box = Pulse:Create("Frame", {
            Parent = Pulse.Watermark, Size = dim2(0, 0, 0, 26), BackgroundColor3 = rgb(25, 25, 29),
            BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.X
        })
        Pulse:Create("UICorner", { Parent = box, CornerRadius = dim(0, 6) })
        Pulse:Create("UIPadding", { Parent = box, PaddingLeft = dim(0, 10), PaddingRight = dim(0, 10) })
        
        Pulse:Create("UIListLayout", { Parent = box, FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = dim(0, 6) })
        
        if icon then
            Pulse:Create("ImageLabel", {
                Parent = box, Size = dim2(0, 14, 0, 14), BackgroundTransparency = 1, Image = icon, ImageColor3 = iconColor or themes.preset.subtext
            })
        end
        
        local lbl = Pulse:Create("TextLabel", {
            Parent = box, BackgroundTransparency = 1, Size = dim2(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
            Text = text_content, TextColor3 = themes.preset.text, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
            RichText = isRich or false
        })
        return lbl
    end

    local WatermarkLbl = nil
    if drawWatermark then
        local wtext = type(properties.Watermark) == "string" and properties.Watermark or "this is a <font color=\"#" .. themes.preset.accent:ToHex() .. "\">watermark.</font>"
        WatermarkLbl = CreateStatusBox(nil, wtext, true)
    end
    
    local FPSLbl = CreateStatusBox("rbxassetid://11293975734", "0 fps")
    local PingLbl = CreateStatusBox("rbxassetid://11293976662", "0 ping")
    local UserLbl = CreateStatusBox("rbxassetid://11293977610", "logged in as " .. lp.Name)
    Items.UserStatus = UserLbl

    task.spawn(function()
        while task.wait(1) do
            PingLbl.Text = math.floor(lp:GetNetworkPing() * 1000) .. " ping"
            FPSLbl.Text = math.floor(Workspace:GetRealPhysicsFPS()) .. " fps"
        end
    end)

    -- Dragging Logic
    local Dragging, DragInput, DragStart, StartPos
    Items.Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true; DragStart = input.Position; StartPos = Items.Wrapper.Position
        end
    end)
    Items.Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = false end
    end)
    InputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - DragStart
            Items.Wrapper.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
        end
    end)
    Pulse:Resizify(Items.Wrapper)

    function Cfg.ToggleMenu(bool)
        if Cfg.Tweening then return end
        if bool == nil then uiVisible = not uiVisible else uiVisible = bool end
        Items.Wrapper.Visible = uiVisible
    end

    if InputService.TouchEnabled then
        Pulse.ToggleGui = Pulse:Create("ScreenGui", { Parent = CoreGui, Name = "PulseToggle", IgnoreGuiInset = true })
        local ToggleButton = Pulse:Create("ImageButton", {
            Name = "ToggleButton", Parent = Pulse.ToggleGui, Position = UDim2.new(1, -80, 0, 150), Size = UDim2.new(0, 50, 0, 50),
            BackgroundColor3 = themes.preset.background, Image = "rbxassetid://13110298032", -- Main Logo Icon
            ImageColor3 = themes.preset.accent, ZIndex = 10000,
        })
        Pulse:Create("UICorner", { Parent = ToggleButton, CornerRadius = dim(0, 10) })
        Pulse:Themify(ToggleButton, "background", "BackgroundColor3")
        Pulse:Themify(ToggleButton, "accent", "ImageColor3")
        Pulse:Themify(Pulse:Create("UIStroke", { Parent = ToggleButton, Color = themes.preset.outline, Thickness = 1.5 }), "outline", "Color")

        local isTDrag, tDragStart, tStartPos, hasTDragged = false, nil, nil, false
        ToggleButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isTDrag = true; hasTDragged = false; tDragStart = input.Position; tStartPos = ToggleButton.Position
            end
        end)
        ToggleButton.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isTDrag = false; if not hasTDragged then Cfg.ToggleMenu() end
            end
        end)
        InputService.InputChanged:Connect(function(input)
            if isTDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - tDragStart
                if delta.Magnitude > 5 then hasTDragged = true; ToggleButton.Position = UDim2.new(tStartPos.X.Scale, tStartPos.X.Offset + delta.X, tStartPos.Y.Scale, tStartPos.Y.Offset + delta.Y) end
            end
        end)
    end

    return setmetatable(Cfg, Pulse)
end

-- tabs okk :joy:
function Pulse:Tab(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Tab", 
        Icon = properties.Icon or properties.icon or "rbxassetid://11293977610", 
        Items = {}, SubTabs = {}, ActiveSubTab = nil, Window = self
    }
    if tonumber(Cfg.Icon) then Cfg.Icon = "rbxassetid://" .. tostring(Cfg.Icon) end
    local Items = Cfg.Items

    -- Sidebar Icon Button
    Items.SidebarButton = Pulse:Create("TextButton", { 
        Parent = self.Items.TabList, Size = dim2(0, 45, 0, 45), 
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5 
    })
    Pulse:Create("UICorner", { Parent = Items.SidebarButton, CornerRadius = dim(0, 8) })
    
    Items.SidebarIcon = Pulse:Create("ImageLabel", { 
        Parent = Items.SidebarButton, AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0),
        Size = dim2(0, 22, 0, 22), BackgroundTransparency = 1, 
        Image = Cfg.Icon, ImageColor3 = themes.preset.subtext, ZIndex = 6 
    })
    Pulse:Themify(Items.SidebarIcon, "subtext", "ImageColor3")

    function Cfg.OpenTab()
        if self.IsSwitchingTab or self.TabInfo == Cfg then return end
        local oldTab = self.TabInfo
        self.TabInfo = Cfg

        local buttonTween = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        if oldTab then
            Pulse:Tween(oldTab.Items.SidebarIcon, {ImageColor3 = themes.preset.subtext}, buttonTween)
            Pulse:Tween(oldTab.Items.SidebarButton, {BackgroundTransparency = 1}, buttonTween)
            for _, sub in ipairs(oldTab.SubTabs) do sub.Items.Button.Visible = false end
            if oldTab.ActiveSubTab then
                Pulse:Tween(oldTab.ActiveSubTab.Items.Pages, {GroupTransparency = 1, Position = dim2(0, 0, 0, 10)}, buttonTween)
                task.wait(0.25)
                oldTab.ActiveSubTab.Items.Pages.Visible = false
                oldTab.ActiveSubTab.Items.Pages.Parent = Pulse.Other
            end
        end

        Pulse:Tween(Items.SidebarIcon, {ImageColor3 = themes.preset.accent}, buttonTween)
        Pulse:Tween(Items.SidebarButton, {BackgroundTransparency = 0.9}, buttonTween) 
        
        for _, sub in ipairs(Cfg.SubTabs) do sub.Items.Button.Visible = true end
        if Cfg.ActiveSubTab then Cfg.ActiveSubTab.OpenSubTab() 
        elseif Cfg.SubTabs[1] then Cfg.SubTabs[1].OpenSubTab() end
    end

    Items.SidebarButton.MouseButton1Down:Connect(Cfg.OpenTab)
    if not self.TabInfo then task.spawn(Cfg.OpenTab) end

    -- Backward compatibility for Section to SubTab
    function Cfg:Section(props)
        if not self.DefaultSubTab then self.DefaultSubTab = self:SubTab({ Name = "Main", Hidden = true }) end
        return self.DefaultSubTab:Section(props)
    end

    return setmetatable(Cfg, Pulse)
end

function Pulse:SubTab(properties)
    local Cfg = {
        Name = properties.Name or properties.name or "SubTab",
        Hidden = properties.Hidden or properties.hidden or false,
        Items = {}
    }
    local window = self.Window
    local Items = Cfg.Items
    table.insert(self.SubTabs, Cfg)

    Items.Button = Pulse:Create("TextButton", { 
        Parent = window.Items.TabHolder, Size = dim2(0, 0, 1, -16), 
        BackgroundTransparency = 1, BackgroundColor3 = themes.preset.element, Text = Cfg.Name:lower(), 
        TextColor3 = themes.preset.subtext, TextSize = 13, 
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
        AutomaticSize = Enum.AutomaticSize.X, AutoButtonColor = false, ZIndex = 5,
        Visible = (window.TabInfo == self)
    })
    Pulse:Themify(Items.Button, "element", "BackgroundColor3")
    Pulse:Create("UICorner", {Parent = Items.Button, CornerRadius = dim(0, 4)})
    Pulse:Create("UIPadding", {Parent = Items.Button, PaddingLeft = dim(0, 12), PaddingRight = dim(0, 12)})
    Pulse:Themify(Items.Button, "subtext", "TextColor3")

    Items.Pages = Pulse:Create("CanvasGroup", { Parent = Pulse.Other, Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1 })
    Pulse:Create("UIListLayout", { Parent = Items.Pages, FillDirection = Enum.FillDirection.Horizontal, Padding = dim(0, 14) })
    Pulse:Create("UIPadding", { Parent = Items.Pages, PaddingTop = dim(0, 10), PaddingBottom = dim(0, 10), PaddingRight = dim(0, 20), PaddingLeft = dim(0, 20) })

    Items.Left = Pulse:Create("ScrollingFrame", { Parent = Items.Pages, Size = dim2(0.5, -7, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y })
    Pulse:Create("UIListLayout", { Parent = Items.Left, Padding = dim(0, 14) })
    Pulse:Create("UIPadding", { Parent = Items.Left, PaddingBottom = dim(0, 10) })

    Items.Right = Pulse:Create("ScrollingFrame", { Parent = Items.Pages, Size = dim2(0.5, -7, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y })
    Pulse:Create("UIListLayout", { Parent = Items.Right, Padding = dim(0, 14) })
    Pulse:Create("UIPadding", { Parent = Items.Right, PaddingBottom = dim(0, 10) })

    function Cfg.OpenSubTab()
        if window.IsSwitchingTab or self.ActiveSubTab == Cfg then return end
        local oldSub = self.ActiveSubTab
        window.IsSwitchingTab = true
        self.ActiveSubTab = Cfg

        local buttonTween = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        if oldSub then
            Pulse:Tween(oldSub.Items.Button, {TextColor3 = themes.preset.subtext, BackgroundTransparency = 1}, buttonTween)
            Pulse:Tween(oldSub.Items.Pages, {GroupTransparency = 1, Position = dim2(0, 0, 0, 10)}, buttonTween)
            task.wait(0.25)
            oldSub.Items.Pages.Visible = false
            oldSub.Items.Pages.Parent = Pulse.Other
        end

        Pulse:Tween(Items.Button, {TextColor3 = themes.preset.accent, BackgroundTransparency = 0}, buttonTween)
        
        Items.Pages.Position = dim2(0, 0, 0, 10)
        Items.Pages.Parent = window.Items.PageHolder
        Items.Pages.Visible = true
        Pulse:Tween(Items.Pages, {GroupTransparency = 0, Position = dim2(0, 0, 0, 0)}, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
        task.wait(0.35)
        window.IsSwitchingTab = false
    end

    Items.Button.MouseButton1Down:Connect(Cfg.OpenSubTab)
    if Cfg.Hidden then Items.Button.Size = dim2(0, 0, 0, 0); Items.Button.Visible = false end

    return setmetatable(Cfg, Pulse)
end

-- sections okk
function Pulse:Section(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Section", 
        Side = properties.Side or properties.side or "Left", 
        RightIcon = properties.RightIcon or properties.righticon or "rbxassetid://12338898398",
        Items = {} 
    }
    Cfg.Side = (Cfg.Side:lower() == "right") and "Right" or "Left"
    local Items = Cfg.Items

    Items.Section = Pulse:Create("Frame", { 
        Parent = self.Items[Cfg.Side], Size = dim2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, 
        BackgroundColor3 = themes.preset.section, BorderSizePixel = 0, ClipsDescendants = true 
    })
    Pulse:Themify(Items.Section, "section", "BackgroundColor3")
    Pulse:Create("UICorner", { Parent = Items.Section, CornerRadius = dim(0, 6) })
    
    -- Gradient for Section background
    Pulse:Create("UIGradient", {
        Parent = Items.Section, Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, rgb(255, 255, 255)),
            ColorSequenceKeypoint.new(1, rgb(225, 225, 225))
        })
    })
    Items.Header = Pulse:Create("Frame", { Parent = Items.Section, Size = dim2(1, 0, 0, 36), BackgroundTransparency = 1 })
    
    -- Section Title (Shifted left since there's no icon anymore)
    Items.Title = Pulse:Create("TextLabel", { 
        Parent = Items.Header, Position = dim2(0, 14, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -46, 0, 14), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left 
    })
    Pulse:Themify(Items.Title, "text", "TextColor3")

    Items.Chevron = Pulse:Create("ImageLabel", {
        Parent = Items.Header, Position = dim2(1, -14, 0.5, 0), AnchorPoint = vec2(1, 0.5), Size = dim2(0, 12, 0, 12),
        BackgroundTransparency = 1, Image = Cfg.RightIcon, ImageColor3 = themes.preset.subtext, 
        Rotation = 0
    })
    Pulse:Themify(Items.Chevron, "subtext", "ImageColor3")

    Items.Container = Pulse:Create("Frame", { 
        Parent = Items.Section, Position = dim2(0, 0, 0, 36), Size = dim2(1, 0, 0, 0), 
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 
    })
    Pulse:Create("UIListLayout", { Parent = Items.Container, Padding = dim(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
    Pulse:Create("UIPadding", { Parent = Items.Container, PaddingBottom = dim(0, 12), PaddingLeft = dim(0, 14), PaddingRight = dim(0, 14) })

    return setmetatable(Cfg, Pulse)
end

-- elements okk
function Pulse:Toggle(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Toggle", 
        Flag = properties.Flag or properties.flag, 
        Default = properties.Default or properties.default or false, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Button = Pulse:Create("TextButton", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 24), BackgroundTransparency = 1, Text = "" })
    
    Items.Title = Pulse:Create("TextLabel", { 
        Parent = Items.Button, Position = dim2(0, 4, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -50, 1, 0), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left 
    })
    Pulse:Themify(Items.Title, "subtext", "TextColor3")

    Items.Box = Pulse:Create("Frame", { 
        Parent = Items.Button, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -4, 0.5, 0), Size = dim2(0, 16, 0, 16), 
        BackgroundColor3 = themes.preset.element, BorderSizePixel = 0 
    })
    Pulse:Themify(Items.Box, "element", "BackgroundColor3")
    Pulse:Create("UICorner", { Parent = Items.Box, CornerRadius = dim(0, 4) })

    local State = false
    function Cfg.set(bool)
        State = bool
        Pulse:Tween(Items.Box, {BackgroundColor3 = State and rgb(80, 200, 100) or themes.preset.element}, TweenInfo.new(0.2))
        Pulse:Tween(Items.Title, {TextColor3 = State and themes.preset.text or themes.preset.subtext}, TweenInfo.new(0.2))
        if Cfg.Flag then Flags[Cfg.Flag] = State end
        Cfg.Callback(State)
    end

    Items.Button.MouseButton1Click:Connect(function() Cfg.set(not State) end)
    if Cfg.Default then Cfg.set(true) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

    return setmetatable(Cfg, Pulse)
end

function Pulse:Checkbox(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Checkbox", 
        Flag = properties.Flag or properties.flag, 
        Default = properties.Default or properties.default or false, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Button = Pulse:Create("TextButton", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 22), BackgroundTransparency = 1, Text = "" })
    
    Items.Box = Pulse:Create("Frame", { 
        Parent = Items.Button, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -4, 0.5, 0), Size = dim2(0, 16, 0, 16), 
        BackgroundColor3 = themes.preset.element, BorderSizePixel = 0 
    })
    Pulse:Themify(Items.Box, "element", "BackgroundColor3")
    Pulse:Create("UICorner", { Parent = Items.Box, CornerRadius = dim(0, 4) })

    Items.CheckImage = Pulse:Create("ImageLabel", {
        Parent = Items.Box, ActionPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0), Size = dim2(0.8, 0, 0.8, 0),
        BackgroundTransparency = 1, Image = "rbxassetid://11293976451", -- Checkmark icon
        ImageColor3 = themes.preset.accent, ImageTransparency = 1, ZIndex = 2
    })
    Pulse:Themify(Items.CheckImage, "accent", "ImageColor3")

    Items.Title = Pulse:Create("TextLabel", { 
        Parent = Items.Button, Position = dim2(0, 4, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -30, 1, 0), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left 
    })
    Pulse:Themify(Items.Title, "subtext", "TextColor3")

    local State = false
    function Cfg.set(bool)
        State = bool
        Pulse:Tween(Items.Box, {BackgroundColor3 = State and rgb(40, 45, 60) or themes.preset.element}, TweenInfo.new(0.2))
        Pulse:Tween(Items.CheckImage, {ImageTransparency = State and 0 or 1}, TweenInfo.new(0.2))
        Pulse:Tween(Items.Title, {TextColor3 = State and themes.preset.text or themes.preset.subtext}, TweenInfo.new(0.2))
        if Cfg.Flag then Flags[Cfg.Flag] = State end
        Cfg.Callback(State)
    end

    Items.Button.MouseButton1Click:Connect(function() Cfg.set(not State) end)
    if Cfg.Default then Cfg.set(true) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

    return setmetatable(Cfg, Pulse)
end

function Pulse:Button(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Button", 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Button = Pulse:Create("TextButton", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 32), BackgroundColor3 = themes.preset.element, 
        Text = Cfg.Name, TextColor3 = themes.preset.text, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), AutoButtonColor = false 
    })
    Pulse:Themify(Items.Button, "element", "BackgroundColor3")
    Pulse:Themify(Items.Button, "text", "TextColor3")
    Pulse:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 6) })

    Items.Button.MouseButton1Click:Connect(function()
        Pulse:Tween(Items.Button, {BackgroundColor3 = themes.preset.outline}, TweenInfo.new(0.1))
        task.wait(0.1)
        Pulse:Tween(Items.Button, {BackgroundColor3 = themes.preset.element}, TweenInfo.new(0.2))
        Cfg.Callback()
    end)
    return setmetatable(Cfg, Pulse)
end

function Pulse:Slider(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Slider", 
        Flag = properties.Flag or properties.flag, 
        Min = properties.Min or properties.min or 0, 
        Max = properties.Max or properties.max or 100, 
        Default = properties.Default or properties.default or properties.Value or properties.value or 0, 
        Increment = properties.Increment or properties.increment or 1, 
        Suffix = properties.Suffix or properties.suffix or "", 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Container = Pulse:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 38), BackgroundTransparency = 1 })
    Items.Title = Pulse:Create("TextLabel", { Parent = Items.Container, Size = dim2(1, 0, 0, 20), BackgroundTransparency = 1, Text = "  " .. Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    Pulse:Themify(Items.Title, "subtext", "TextColor3")

    Items.Val = Pulse:Create("TextLabel", { Parent = Items.Container, Size = dim2(1, 0, 0, 20), BackgroundTransparency = 1, Text = tostring(Cfg.Default)..Cfg.Suffix, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Right })
    Pulse:Themify(Items.Val, "subtext", "TextColor3")

    Items.Track = Pulse:Create("TextButton", { Parent = Items.Container, Position = dim2(0, 4, 0, 24), Size = dim2(1, -8, 0, 8), BackgroundColor3 = themes.preset.element, Text = "", AutoButtonColor = false })
    Pulse:Themify(Items.Track, "element", "BackgroundColor3")
    Pulse:Create("UICorner", { Parent = Items.Track, CornerRadius = dim(1, 0) })

    Items.Fill = Pulse:Create("Frame", { Parent = Items.Track, Size = dim2(0, 0, 1, 0), BackgroundColor3 = themes.preset.accent })
    Pulse:Themify(Items.Fill, "accent", "BackgroundColor3")
    Pulse:Create("UICorner", { Parent = Items.Fill, CornerRadius = dim(1, 0) })
    
    -- Sub-gradient for fill (Blue to Purple)
    Pulse:Create("UIGradient", {
        Parent = Items.Fill,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, themes.preset.accent),
            ColorSequenceKeypoint.new(1, rgb(180, 120, 255))
        })
    })

    Items.Knob = Pulse:Create("Frame", { Parent = Items.Fill, AnchorPoint = vec2(0.5, 0.5), Position = dim2(1, 0, 0.5, 0), Size = dim2(0, 14, 0, 14), BackgroundColor3 = rgb(255, 255, 255) })
    Pulse:Create("UICorner", { Parent = Items.Knob, CornerRadius = dim(1, 0) })
    Pulse:Create("UIStroke", { Parent = Items.Knob, Color = rgb(0, 0, 0), Transparency = 0.8 })

    local Value = Cfg.Default
    function Cfg.set(val)
        Value = math.clamp(math.round(val / Cfg.Increment) * Cfg.Increment, Cfg.Min, Cfg.Max)
        Items.Val.Text = tostring(Value) .. Cfg.Suffix
        Pulse:Tween(Items.Fill, {Size = dim2((Value - Cfg.Min) / (Cfg.Max - Cfg.Min), 0, 1, 0)}, TweenInfo.new(0.15))
        if Cfg.Flag then Flags[Cfg.Flag] = Value end
        Cfg.Callback(Value)
    end

    local Dragging = false
    Items.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = true; Cfg.set(Cfg.Min + (Cfg.Max - Cfg.Min) * math.clamp((input.Position.X - Items.Track.AbsolutePosition.X) / Items.Track.AbsoluteSize.X, 0, 1)) end
    end)
    InputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = false end
    end)
    InputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            Cfg.set(Cfg.Min + (Cfg.Max - Cfg.Min) * math.clamp((input.Position.X - Items.Track.AbsolutePosition.X) / Items.Track.AbsoluteSize.X, 0, 1))
        end
    end)

    Cfg.set(Cfg.Default)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Pulse)
end

function Pulse:Textbox(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "", 
        Placeholder = properties.Placeholder or properties.placeholder or "Enter text...", 
        Default = properties.Default or properties.default or "", 
        Flag = properties.Flag or properties.flag, 
        Numeric = properties.Numeric or properties.numeric or false, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Container = Pulse:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 32), BackgroundTransparency = 1 })
    Items.Bg = Pulse:Create("Frame", { Parent = Items.Container, Size = dim2(1, 0, 1, 0), BackgroundColor3 = themes.preset.element })
    Pulse:Themify(Items.Bg, "element", "BackgroundColor3")
    Pulse:Create("UICorner", { Parent = Items.Bg, CornerRadius = dim(0, 6) })

    Items.Input = Pulse:Create("TextBox", { 
        Parent = Items.Bg, Position = dim2(0, 12, 0, 0), Size = dim2(1, -40, 1, 0), BackgroundTransparency = 1, 
        Text = Cfg.Default, PlaceholderText = Cfg.Placeholder, TextColor3 = themes.preset.text, PlaceholderColor3 = themes.preset.subtext, 
        TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false 
    })
    Pulse:Themify(Items.Input, "text", "TextColor3")

    Items.Icon = Pulse:Create("ImageLabel", {
        Parent = Items.Bg, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -10, 0.5, 0), Size = dim2(0, 16, 0, 16),
        BackgroundTransparency = 1, Image = "rbxassetid://11293980133", -- Edit/Pencil icon
        ImageColor3 = themes.preset.subtext
    })
    Pulse:Themify(Items.Icon, "subtext", "ImageColor3")

    function Cfg.set(val)
        if Cfg.Numeric and tonumber(val) == nil and val ~= "" then return end
        Items.Input.Text = tostring(val)
        if Cfg.Flag then Flags[Cfg.Flag] = val end
        Cfg.Callback(val)
    end
    
    Items.Input.FocusLost:Connect(function() Cfg.set(Items.Input.Text) end)
    if Cfg.Default ~= "" then Cfg.set(Cfg.Default) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

    return setmetatable(Cfg, Pulse)
end

-- animated dropdown lolz with search
function Pulse:Dropdown(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Dropdown", 
        Flag = properties.Flag or properties.flag, 
        Options = properties.Options or properties.options or properties.items or {}, 
        Default = properties.Default or properties.default, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items
    
    Items.Container = Pulse:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 46), BackgroundTransparency = 1 })
    Items.Title = Pulse:Create("TextLabel", { Parent = Items.Container, Size = dim2(1, 0, 0, 16), BackgroundTransparency = 1, Text = "  " .. Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    Pulse:Themify(Items.Title, "subtext", "TextColor3")

    Items.Main = Pulse:Create("TextButton", { 
        Parent = Items.Container, Position = dim2(0, 0, 0, 20), Size = dim2(1, 0, 0, 26), 
        BackgroundColor3 = themes.preset.element, Text = "", AutoButtonColor = false 
    })
    Pulse:Themify(Items.Main, "element", "BackgroundColor3")
    Pulse:Create("UICorner", { Parent = Items.Main, CornerRadius = dim(0, 4) })
    AddSubtleGradient(Items.Main, 90) -- Dropdown Main Gradient

    Items.SelectedText = Pulse:Create("TextLabel", { Parent = Items.Main, Position = dim2(0, 12, 0, 0), Size = dim2(1, -24, 1, 0), BackgroundTransparency = 1, Text = "...", TextColor3 = themes.preset.text, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    Pulse:Themify(Items.SelectedText, "text", "TextColor3")
    
    Items.Icon = Pulse:Create("ImageLabel", { Parent = Items.Main, Position = dim2(1, -22, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(0, 14, 0, 14), BackgroundTransparency = 1, Image = "rbxassetid://11293976193", ImageColor3 = themes.preset.subtext, Rotation = 0 })
    Pulse:Themify(Items.Icon, "subtext", "ImageColor3")

    Items.DropFrame = Pulse:Create("Frame", { 
        Parent = Pulse.Gui, Size = dim2(1, 0, 0, 0), Position = dim2(0, 0, 0, 0), 
        BackgroundColor3 = themes.preset.element, Visible = false, ZIndex = 200, ClipsDescendants = true 
    })
    Pulse:Themify(Items.DropFrame, "element", "BackgroundColor3")
    Pulse:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 4) })

    -- Search implementation inside dropdown
    Items.SearchBg = Pulse:Create("Frame", { Parent = Items.DropFrame, Size = dim2(1, -12, 0, 24), Position = dim2(0, 6, 0, 6), BackgroundColor3 = themes.preset.background, BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = 201 })
    Pulse:Themify(Items.SearchBg, "background", "BackgroundColor3")
    Pulse:Create("UICorner", { Parent = Items.SearchBg, CornerRadius = dim(0, 4) })
    AddSubtleGradient(Items.SearchBg, 90) -- Search Input Gradient

    Items.SearchInput = Pulse:Create("TextBox", {
        Parent = Items.SearchBg, Size = dim2(1, -16, 1, 0), Position = dim2(0, 8, 0, -4), BackgroundTransparency = 1, 
        Text = "", PlaceholderText = "Search...", TextColor3 = themes.preset.text, PlaceholderColor3 = themes.preset.subtext, 
        TextSize = 12, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, TextTransparency = 1, ZIndex = 202
    })
    Pulse:Themify(Items.SearchInput, "text", "TextColor3")

    Items.Scroll = Pulse:Create("ScrollingFrame", { 
        Parent = Items.DropFrame, Size = dim2(1, 0, 1, -36), Position = dim2(0, 0, 0, 32), 
        BackgroundTransparency = 1, ScrollBarThickness = 0, BorderSizePixel = 0, ZIndex = 201 
    })
    Pulse:Create("UIListLayout", { Parent = Items.Scroll, SortOrder = Enum.SortOrder.LayoutOrder })

    local Open = false
    local isTweening = false
    local OptionBtns = {}

    function Cfg.UpdatePosition()
        local absPos = Items.Main.AbsolutePosition
        local absSize = Items.Main.AbsoluteSize
        Items.DropFrame.Position = dim2(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
        local visibleCount = 0
        for _, data in ipairs(OptionBtns) do
            if data.btn.Size.Y.Offset > 0 then visibleCount += 1 end
        end
        Items.Scroll.CanvasSize = dim2(0, 0, 0, visibleCount * 24)
    end

    local function FilterOptions()
        local text = Items.SearchInput.Text:lower()
        local visibleCount = 0
        
        for _, data in ipairs(OptionBtns) do
            local btn = data.btn
            local optText = data.text:lower()
            
            if text == "" or optText:find(text) then
                visibleCount += 1
                Pulse:Tween(btn, {Size = dim2(1, 0, 0, 24), TextTransparency = 0}, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            else
                Pulse:Tween(btn, {Size = dim2(1, 0, 0, 0), TextTransparency = 1}, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            end
        end
        
        if Open and not isTweening then
            local targetHeight = math.clamp(visibleCount * 24 + 38, 38, 180)
            Pulse:Tween(Items.DropFrame, {Size = dim2(0, Items.Main.AbsoluteSize.X, 0, targetHeight)}, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            Items.Scroll.CanvasSize = dim2(0, 0, 0, visibleCount * 24)
        end
    end
    Items.SearchInput:GetPropertyChangedSignal("Text"):Connect(FilterOptions)

    local function ToggleDropdown()
        if isTweening then return end
        isTweening = true

        if not Open then
            Items.SearchInput.Text = "" -- Reset before setting Open to true
            Open = true
            
            Items.DropFrame.Visible = true
            Cfg.UpdatePosition()
            Items.DropFrame.Size = dim2(0, Items.Main.AbsoluteSize.X, 0, 0)
            
            local visibleCount = #Cfg.Options
            local targetHeight = math.clamp(visibleCount * 24 + 38, 38, 180)
            
            Pulse:Tween(Items.Icon, {Rotation = 180}, TweenInfo.new(0.3))
            
            -- Tuff Search Animation (Fade & Slide in)
            Items.SearchBg.BackgroundTransparency = 1
            Items.SearchInput.TextTransparency = 1
            Items.SearchInput.Position = dim2(0, 8, 0, -4)
            Pulse:Tween(Items.SearchBg, {BackgroundTransparency = 0}, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            Pulse:Tween(Items.SearchInput, {TextTransparency = 0, Position = dim2(0, 8, 0, 0)}, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            
            local tw = Pulse:Tween(Items.DropFrame, {Size = dim2(0, Items.Main.AbsoluteSize.X, 0, targetHeight)}, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
        else
            Open = false
            Pulse:Tween(Items.Icon, {Rotation = 0}, TweenInfo.new(0.3))
            
            -- Reverse Search Animation
            Pulse:Tween(Items.SearchBg, {BackgroundTransparency = 1}, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
            Pulse:Tween(Items.SearchInput, {TextTransparency = 1, Position = dim2(0, 8, 0, -4)}, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
            
            local tw = Pulse:Tween(Items.DropFrame, {Size = dim2(0, Items.Main.AbsoluteSize.X, 0, 0)}, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
            Items.DropFrame.Visible = false
        end
        isTweening = false
    end
    Items.Main.MouseButton1Click:Connect(ToggleDropdown)

    InputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if Open and not isTweening then
                local mx, my = input.Position.X, input.Position.Y
                local p0, s0 = Items.DropFrame.AbsolutePosition, Items.DropFrame.AbsoluteSize
                local p1, s1 = Items.Main.AbsolutePosition, Items.Main.AbsoluteSize
                
                if not (mx >= p0.X and mx <= p0.X + s0.X and my >= p0.Y and my <= p0.Y + s0.Y) and 
                   not (mx >= p1.X and mx <= p1.X + s1.X and my >= p1.Y and my <= p1.Y + s1.Y) then
                    ToggleDropdown()
                end
            end
        end
    end)

    function Cfg.RefreshOptions(newList)
        Cfg.Options = newList or Cfg.Options
        for _, data in ipairs(OptionBtns) do data.btn:Destroy() end
        table.clear(OptionBtns)
        for _, opt in ipairs(Cfg.Options) do
            local btn = Pulse:Create("TextButton", { 
                Parent = Items.Scroll, Size = dim2(1, 0, 0, 24), BackgroundTransparency = 1, 
                Text = "   " .. tostring(opt), TextColor3 = themes.preset.subtext, TextSize = 13, 
                FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 202,
                ClipsDescendants = true -- Required for "tuff" filtering animation
            })
            Pulse:Themify(btn, "subtext", "TextColor3")
            btn.MouseButton1Click:Connect(function() Cfg.set(opt); ToggleDropdown() end)
            table.insert(OptionBtns, {btn = btn, text = tostring(opt)})
        end
        FilterOptions()
    end

    function Cfg.set(val)
        Items.SelectedText.Text = tostring(val)
        if Cfg.Flag then Flags[Cfg.Flag] = val end
        Cfg.Callback(val)
    end

    Cfg.RefreshOptions(Cfg.Options)
    if Cfg.Default then Cfg.set(Cfg.Default) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

    task.spawn(function()
        while true do
            if Open or isTweening then 
                Items.DropFrame.Position = dim2(0, Items.Main.AbsolutePosition.X, 0, Items.Main.AbsolutePosition.Y + Items.Main.AbsoluteSize.Y + 4)
            end 
            task.wait() -- Run only when needed or use a slower poll if acceptable, but for UI movement task.wait() is standard
        end
    end)
    return setmetatable(Cfg, Pulse)
end

function Pulse:Label(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Label", 
        Wrapped = properties.Wrapped or properties.wrapped or false, 
        Items = {} 
    }
    local Items = Cfg.Items
    Items.Title = Pulse:Create("TextLabel", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, Cfg.Wrapped and 26 or 18), BackgroundTransparency = 1, 
        Text = "  " .. Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, TextWrapped = Cfg.Wrapped, 
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, 
        TextYAlignment = Cfg.Wrapped and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center 
    })
    Pulse:Themify(Items.Title, "subtext", "TextColor3")
    
    function Cfg.set(val) Items.Title.Text = "  " .. tostring(val) end
    return setmetatable(Cfg, Pulse)
end

-- animated colorpicker so sexy 
function Pulse:Colorpicker(properties)
    local Cfg = { 
        Color = properties.Color or properties.color or rgb(255, 255, 255), 
        Callback = properties.Callback or properties.callback or function() end, 
        Flag = properties.Flag or properties.flag, 
        Items = {} 
    }
    local Items = Cfg.Items

    local btn = Pulse:Create("TextButton", { Parent = self.Items.Title or self.Items.Button or self.Items.Container, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -6, 0.5, 0), Size = dim2(0, 30, 0, 14), BackgroundColor3 = Cfg.Color, Text = "" })
    Pulse:Create("UICorner", {Parent = btn, CornerRadius = dim(0, 4)})
    AddSubtleGradient(btn, 90) -- ADDED: Gradient on the color preview box

    local h, s, v = Color3.toHSV(Cfg.Color)
    local alpha = 1
    
    Items.DropFrame = Pulse:Create("Frame", { Parent = Pulse.Gui, Size = dim2(0, 160, 0, 0), BackgroundColor3 = themes.preset.element, Visible = false, ZIndex = 200, ClipsDescendants = true })
    Pulse:Themify(Items.DropFrame, "element", "BackgroundColor3")
    Pulse:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 6) })
    Pulse:Create("UIStroke", { Parent = Items.DropFrame, Color = themes.preset.outline, Thickness = 1 })

    -- Copy/Paste Buttons (Top Right of picker)
    local CopyBtn = Pulse:Create("ImageButton", { Parent = Items.DropFrame, Position = dim2(0, 8, 0, 8), Size = dim2(0, 14, 0, 14), BackgroundTransparency = 1, Image = "rbxassetid://11293978296", ImageColor3 = themes.preset.subtext })
    local PasteBtn = Pulse:Create("ImageButton", { Parent = Items.DropFrame, Position = dim2(0, 28, 0, 8), Size = dim2(0, 14, 0, 14), BackgroundTransparency = 1, Image = "rbxassetid://11293981881", ImageColor3 = themes.preset.subtext })

    Items.SVMap = Pulse:Create("TextButton", { Parent = Items.DropFrame, Position = dim2(0, 8, 0, 30), Size = dim2(1, -16, 0, 100), AutoButtonColor = false, Text = "", BackgroundColor3 = Color3.fromHSV(h, 1, 1), ZIndex = 201 })
    Pulse:Create("UICorner", { Parent = Items.SVMap, CornerRadius = dim(0, 4) })
    Items.SVImage = Pulse:Create("ImageLabel", { Parent = Items.SVMap, Size = dim2(1, 0, 1, 0), Image = "rbxassetid://4155801252", BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 202 })
    Pulse:Create("UICorner", { Parent = Items.SVImage, CornerRadius = dim(0, 4) })
    
    Items.SVKnob = Pulse:Create("Frame", { Parent = Items.SVMap, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 4, 0, 4), BackgroundColor3 = rgb(255,255,255), ZIndex = 203 })
    Pulse:Create("UICorner", { Parent = Items.SVKnob, CornerRadius = dim(1, 0) })
    Pulse:Create("UIStroke", { Parent = Items.SVKnob, Color = rgb(0,0,0) })

    Items.HueBar = Pulse:Create("TextButton", { Parent = Items.DropFrame, Position = dim2(0, 8, 0, 136), Size = dim2(1, -16, 0, 10), AutoButtonColor = false, Text = "", BorderSizePixel = 0, BackgroundColor3 = rgb(255, 255, 255), ZIndex = 201 })
    Pulse:Create("UICorner", { Parent = Items.HueBar, CornerRadius = dim(1, 0) })
    Pulse:Create("UIGradient", { Parent = Items.HueBar, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, rgb(255,0,0)), ColorSequenceKeypoint.new(0.167, rgb(255,0,255)), ColorSequenceKeypoint.new(0.333, rgb(0,0,255)), ColorSequenceKeypoint.new(0.5, rgb(0,255,255)), ColorSequenceKeypoint.new(0.667, rgb(0,255,0)), ColorSequenceKeypoint.new(0.833, rgb(255,255,0)), ColorSequenceKeypoint.new(1, rgb(255,0,0))}) })
    
    Items.HueKnob = Pulse:Create("Frame", { Parent = Items.HueBar, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 2, 1, 4), BackgroundColor3 = rgb(255,255,255), ZIndex = 203 })
    Pulse:Create("UIStroke", { Parent = Items.HueKnob, Color = rgb(0,0,0) })

    Items.AlphaBar = Pulse:Create("TextButton", { Parent = Items.DropFrame, Position = dim2(0, 8, 0, 152), Size = dim2(1, -16, 0, 10), AutoButtonColor = false, Text = "", BorderSizePixel = 0, BackgroundColor3 = rgb(255, 255, 255), ZIndex = 201 })
    Pulse:Create("UICorner", { Parent = Items.AlphaBar, CornerRadius = dim(1, 0) })
    local AlphaGradient = Pulse:Create("UIGradient", { Parent = Items.AlphaBar, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, themes.preset.element), ColorSequenceKeypoint.new(1, Cfg.Color)}) })
    
    Items.AlphaKnob = Pulse:Create("Frame", { Parent = Items.AlphaBar, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 2, 1, 4), BackgroundColor3 = rgb(255,255,255), ZIndex = 203 })
    Pulse:Create("UIStroke", { Parent = Items.AlphaKnob, Color = rgb(0,0,0) })

    local Open = false
    local isTweening = false

    local function Toggle() 
        if isTweening then return end
        Open = not Open
        isTweening = true
        
        if Open then
            Items.DropFrame.Visible = true
            local tw = Pulse:Tween(Items.DropFrame, {Size = dim2(0, 160, 0, 180)}, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
        else
            local tw = Pulse:Tween(Items.DropFrame, {Size = dim2(0, 160, 0, 0)}, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
            Items.DropFrame.Visible = false
        end
        isTweening = false
    end
    btn.MouseButton1Click:Connect(Toggle)

    InputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if Open and not isTweening then
                local mx, my = input.Position.X, input.Position.Y
                local p0, s0 = Items.DropFrame.AbsolutePosition, dim2(0, 150, 0, 140)
                local p1, s1 = btn.AbsolutePosition, btn.AbsoluteSize
                if not (mx >= p0.X and mx <= p0.X + s0.X.Offset and my >= p0.Y and my <= p0.Y + s0.Y.Offset) and not (mx >= p1.X and mx <= p1.X + s1.X and my >= p1.Y and my <= p1.Y + s1.Y) then
                    Toggle()
                end
            end
        end
    end)

    function Cfg.set(color3)
        Cfg.Color = color3
        btn.BackgroundColor3 = color3
        if Cfg.Flag then Flags[Cfg.Flag] = color3 end
        Cfg.Callback(color3)
    end

    local svDragging, hueDragging, alphaDragging = false, false, false
    Items.SVMap.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then svDragging = true end end)
    Items.HueBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hueDragging = true end end)
    Items.AlphaBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then alphaDragging = true end end)
    InputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then svDragging = false; hueDragging = false; alphaDragging = false end end)

    InputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if svDragging then
                local x = math.clamp((input.Position.X - Items.SVMap.AbsolutePosition.X) / Items.SVMap.AbsoluteSize.X, 0, 1)
                local y = math.clamp((input.Position.Y - Items.SVMap.AbsolutePosition.Y) / Items.SVMap.AbsoluteSize.Y, 0, 1)
                s, v = x, 1 - y
                Items.SVKnob.Position = dim2(x, 0, y, 0)
                Cfg.set(Color3.fromHSV(h, s, v))
            elseif hueDragging then
                local x = math.clamp((input.Position.X - Items.HueBar.AbsolutePosition.X) / Items.HueBar.AbsoluteSize.X, 0, 1)
                h = 1 - x
                Items.HueKnob.Position = dim2(x, 0, 0.5, 0)
                Items.SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                AlphaGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, themes.preset.element), ColorSequenceKeypoint.new(1, Color3.fromHSV(h, s, v))})
                Cfg.set(Color3.fromHSV(h, s, v))
            elseif alphaDragging then
                local x = math.clamp((input.Position.X - Items.AlphaBar.AbsolutePosition.X) / Items.AlphaBar.AbsoluteSize.X, 0, 1)
                alpha = x
                Items.AlphaKnob.Position = dim2(x, 0, 0.5, 0)
                Cfg.set(Color3.fromHSV(h, s, v), alpha)
            end
        end
    end)

    task.spawn(function()
        while true do
            if Open or isTweening then Items.DropFrame.Position = dim2(0, btn.AbsolutePosition.X - 160 + btn.AbsoluteSize.X, 0, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + 2) end
            task.wait()
        end
    end)
    
    Items.SVKnob.Position = dim2(s, 0, 1 - v, 0)
    Items.HueKnob.Position = dim2(1 - h, 0, 0.5, 0)
    
    Cfg.set(Cfg.Color)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Pulse)
end

function Pulse:Keybind(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Keybind", 
        Flag = properties.Flag or properties.flag, 
        Default = properties.Default or properties.default or Enum.KeyCode.Unknown, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local KeyBtn = Pulse:Create("TextButton", { Parent = self.Items.Title or self.Items.Container, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -6, 0.5, 0), Size = dim2(0, 50, 0, 22), BackgroundColor3 = themes.preset.element, TextColor3 = themes.preset.text, Text = Keys[Cfg.Default] or "None", TextSize = 12, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), })
    Pulse:Themify(KeyBtn, "element", "BackgroundColor3")
    Pulse:Themify(KeyBtn, "text", "TextColor3")

    Pulse:Create("UICorner", {Parent = KeyBtn, CornerRadius = dim(0, 6)})

    local binding = false
    KeyBtn.MouseButton1Click:Connect(function() binding = true; KeyBtn.Text = "..." end)
    
    InputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed and not binding then return end
        if binding then
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
                binding = false; Cfg.set(input.KeyCode)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                binding = false; Cfg.set(input.UserInputType)
            end
        elseif (input.KeyCode == Cfg.Default or input.UserInputType == Cfg.Default) and not binding then
            Cfg.Callback()
        end
    end)
    
    function Cfg.set(val)
        if not val or type(val) == "boolean" then return end
        Cfg.Default = val
        local keyName = Keys[val] or (typeof(val) == "EnumItem" and val.Name) or tostring(val)
        KeyBtn.Text = keyName
        if Cfg.Flag then Flags[Cfg.Flag] = val end
    end
    
    Cfg.set(Cfg.Default)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Pulse)
end

-- notifs
function Notifications:RefreshNotifications()
    local offset = 20
    for _, v in ipairs(Notifications.Notifs) do
        local ySize = v.AbsoluteSize.Y
        Pulse:Tween(v, {Position = dim2(1, -20, 1, -offset - ySize)}, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
        offset += (ySize + 10)
    end
end

function Notifications:Create(properties)
    local Cfg = { 
        Title = properties.Title or properties.title or "Pulse",
        Content = properties.Content or properties.content or properties.Name or "Notification",
        Lifetime = properties.LifeTime or properties.lifetime or 3; 
        Items = {}; 
    }
    local Items = Cfg.Items
   
    Items.Outline = Pulse:Create("Frame", { 
        Parent = Pulse.Gui; Position = dim2(1, 350, 1, -100); Size = dim2(0, 320, 0, 0); 
        AutomaticSize = Enum.AutomaticSize.Y; BackgroundColor3 = themes.preset.background; 
        BorderSizePixel = 0; ZIndex = 300, ClipsDescendants = true 
    })
    Pulse:Themify(Items.Outline, "background", "BackgroundColor3")
    Pulse:Create("UICorner", { Parent = Items.Outline, CornerRadius = dim(0, 8) })
    Pulse:Create("UIStroke", { Parent = Items.Outline, Color = themes.preset.outline, Thickness = 1 })

    Items.TitleText = Pulse:Create("TextLabel", {
        Parent = Items.Outline; Text = Cfg.Title; TextColor3 = themes.preset.text; FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold);
        BackgroundTransparency = 1; Size = dim2(1, 0, 0, 20); TextSize = 13; TextXAlignment = Enum.TextXAlignment.Right; ZIndex = 302
    })
    Pulse:Themify(Items.TitleText, "text", "TextColor3")

    Items.ContentText = Pulse:Create("TextLabel", {
        Parent = Items.Outline; Text = Cfg.Content; TextColor3 = themes.preset.subtext; FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium);
        BackgroundTransparency = 1; Size = dim2(1, 0, 0, 0); AutomaticSize = Enum.AutomaticSize.Y; TextWrapped = true; TextSize = 12; TextXAlignment = Enum.TextXAlignment.Right; ZIndex = 302
    })
    Pulse:Themify(Items.ContentText, "subtext", "TextColor3")
   
    Pulse:Create("UIPadding", { Parent = Items.Outline; PaddingTop = dim(0, 12); PaddingBottom = dim(0, 14); PaddingRight = dim(0, 15); PaddingLeft = dim(0, 15); })
    Pulse:Create("UIListLayout", { Parent = Items.Outline, Padding = dim(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Right })

    Items.TimeBar = Pulse:Create("Frame", { Parent = Items.Outline, AnchorPoint = vec2(1, 1), Position = dim2(1, 15, 1, 14), Size = dim2(1, 30, 0, 2), BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0, ZIndex = 303 })
    Pulse:Themify(Items.TimeBar, "accent", "BackgroundColor3")
    table.insert(Notifications.Notifs, Items.Outline)
   
    task.spawn(function()
        RunService.RenderStepped:Wait()
        Notifications:RefreshNotifications()
        
        Pulse:Tween(Items.TimeBar, {Size = dim2(0, 0, 0, 2)}, TweenInfo.new(Cfg.Lifetime, Enum.EasingStyle.Linear))
        task.wait(Cfg.Lifetime)
        
        Pulse:Tween(Items.Outline, {Position = dim2(1, 350, Items.Outline.Position.Y.Scale, Items.Outline.Position.Y.Offset)}, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
        task.wait(0.4)
        local idx = table.find(Notifications.Notifs, Items.Outline)
        if idx then table.remove(Notifications.Notifs, idx) end
        Items.Outline:Destroy()
        Notifications:RefreshNotifications()
    end)
end

-- save and load stuff yes
function Pulse:GetConfig()
    local g = {}
    for Idx, Value in Flags do g[Idx] = Value end
    return HttpService:JSONEncode(g)
end

function Pulse:LoadConfig(JSON)
    local g = HttpService:JSONDecode(JSON)
    for Idx, Value in g do
        if Idx == "config_Name_list" or Idx == "config_Name_text" then continue end
        local Function = ConfigFlags[Idx]
        if Function then Function(Value) end
    end
end

-- configs and server menu 
local ConfigHolder
function Pulse:UpdateConfigList()
    if not ConfigHolder then return end
    local List = {}
    for _, file in listfiles(Pulse.Directory .. "/configs") do
        local Name = file:gsub(Pulse.Directory .. "/configs\\", ""):gsub(".cfg", ""):gsub(Pulse.Directory .. "\\configs\\", "")
        List[#List + 1] = Name
    end
    ConfigHolder.RefreshOptions(List)
end

function Pulse:Configs(window)
    local Text

    local Tab = window:Tab({ Name = "", Hidden = true })
    window.SettingsTabOpen = Tab.OpenTab

    local Section = Tab:Section({Name = "Configs", Side = "Left"})

    ConfigHolder = Section:Dropdown({
        Name = "Available Configs",
        Options = {},
        Callback = function(option) if Text then Text.set(option) end end,
        Flag = "config_Name_list"
    })

    Pulse:UpdateConfigList()

    Text = Section:Textbox({ Name = "Config Name:", Flag = "config_Name_text", Default = "" })

    Section:Button({
        Name = "Save Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            writefile(Pulse.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg", Pulse:GetConfig())
            Pulse:UpdateConfigList()
            Notifications:Create({Name = "Saved Config: " .. Flags["config_Name_text"]})
        end
    })

    Section:Button({
        Name = "Load Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            Pulse:LoadConfig(readfile(Pulse.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg"))
            Pulse:UpdateConfigList()
            Notifications:Create({Name = "Loaded Config: " .. Flags["config_Name_text"]})
        end
    })

    Section:Button({
        Name = "Delete Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            delfile(Pulse.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg")
            Pulse:UpdateConfigList()
            Notifications:Create({Name = "Deleted Config: " .. Flags["config_Name_text"]})
        end
    })

    local SectionRight = Tab:Section({Name = "Settings & Themes", Side = "Right"})

    -- Streamer Mode added
    SectionRight:Toggle({
        Name = "Streamer Mode",
        Flag = "Pulse_StreamerMode",
        Callback = function(state)
            if state then
                window.Items.UserStatus.Text = "logged in as hidden"
                window.Items.Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=1&w=48&h=48" 
            else
                window.Items.UserStatus.Text = "logged in as " .. lp.Name
                window.Items.Avatar.Image = "rbxthumb://type=AvatarHeadShot&id="..lp.UserId.."&w=48&h=48"
            end
        end
    })

    SectionRight:Label({Name = "Accent Color"}):Colorpicker({ Callback = function(color3) Pulse:RefreshTheme("accent", color3) end, Color = themes.preset.accent })
    SectionRight:Label({Name = "Background Color"}):Colorpicker({ Callback = function(color3) Pulse:RefreshTheme("background", color3) end, Color = themes.preset.background })
    SectionRight:Label({Name = "Section Color"}):Colorpicker({ Callback = function(color3) Pulse:RefreshTheme("section", color3) end, Color = themes.preset.section })
    SectionRight:Label({Name = "Element Color"}):Colorpicker({ Callback = function(color3) Pulse:RefreshTheme("element", color3) end, Color = themes.preset.element })
    SectionRight:Label({Name = "Text Color"}):Colorpicker({ Callback = function(color3) Pulse:RefreshTheme("text", color3) end, Color = themes.preset.text })

    window.Tweening = true
    SectionRight:Label({Name = "Menu Bind"}):Keybind({
        Name = "Menu Bind",
        Callback = function(bool) if window.Tweening then return end window.ToggleMenu(bool) end,
        Default = Enum.KeyCode.RightShift
    })

    task.delay(1, function() window.Tweening = false end)

    local ServerSection = Tab:Section({Name = "Server", Side = "Right"})

    ServerSection:Button({ Name = "Rejoin Server", Callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId, Players.LocalPlayer) end })

    ServerSection:Button({
        Name = "Server Hop",
        Callback = function()
            local servers, cursor = {}, ""
            repeat
                local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor ~= "" and "&cursor=" .. cursor or "")
                local data = HttpService:JSONDecode(game:HttpGet(url))
                for _, server in ipairs(data.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then table.insert(servers, server) end
                end
                cursor = data.nextPageCursor
            until not cursor or #servers > 0
            if #servers > 0 then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)].id, Players.LocalPlayer) end
        end
    })
end

return Pulse, Flags
