local Cerberus = {}
Cerberus.__index = Cerberus

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local function ProtectGui(gui)
    if syn and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    elseif protectgui then
        pcall(protectgui, gui)
    end
end

local function GetParent()
    local ok, hui = pcall(function()
        return gethui and gethui()
    end)
    if ok and hui then
        return hui
    end
    return CoreGui
end

local function Clamp(v, a, b)
    return math.max(a, math.min(b, v))
end

local function Copy(tbl)
    local n = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            n[k] = Copy(v)
        else
            n[k] = v
        end
    end
    return n
end

local function Create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

local function Corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 0)
    c.Parent = obj
    return c
end

local function Stroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local function Padding(obj, l, r, t, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.Parent = obj
    return p
end

local function List(obj, pad)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, pad or 0)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = obj
    return l
end

local function ApplyText(obj, size, color, bold)
    obj.Font = bold and Enum.Font.SourceSansSemibold or Enum.Font.SourceSans
    obj.TextSize = size
    obj.TextColor3 = color
    obj.TextXAlignment = Enum.TextXAlignment.Left
    obj.TextYAlignment = Enum.TextYAlignment.Center
end

local function Tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function UpdateScroll(scroll, layout, extra)
    local function u()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + (extra or 0))
    end
    u()
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(u)
end

local function MakeDraggable(handle, target)
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local ThemeDefaults = {
    Background = Color3.fromRGB(26, 26, 34),
    Topbar = Color3.fromRGB(34, 34, 44),
    Sidebar = Color3.fromRGB(31, 31, 42),
    Section = Color3.fromRGB(31, 31, 42),
    Element = Color3.fromRGB(35, 35, 46),
    Element2 = Color3.fromRGB(28, 28, 38),
    Border = Color3.fromRGB(64, 64, 79),
    BorderSoft = Color3.fromRGB(48, 48, 60),
    Text = Color3.fromRGB(240, 240, 245),
    SubText = Color3.fromRGB(170, 170, 180),
    Accent = Color3.fromRGB(232, 40, 40),
    AccentDark = Color3.fromRGB(140, 20, 20),
    Success = Color3.fromRGB(80, 220, 120),
    Danger = Color3.fromRGB(255, 80, 90),
    Warning = Color3.fromRGB(225, 190, 60),
    Overlay = Color3.fromRGB(0, 0, 0)
}

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

function Cerberus:CreateWindow(options)
    options = options or {}

    local selfWindow = setmetatable({}, Window)
    selfWindow.Theme = Copy(ThemeDefaults)
    selfWindow.ThemeObjects = {}
    selfWindow.Flags = options.Flags or {}
    selfWindow.Tabs = {}
    selfWindow.Keybinds = {}
    selfWindow.Name = options.Name or "Cerberus"
    selfWindow.Width = options.Width or 925
    selfWindow.Height = options.Height or 600
    selfWindow.ToggleKey = options.ToggleKey or Enum.KeyCode.RightShift
    selfWindow.Minimized = false
    selfWindow.ConfigFolder = options.ConfigFolder or "CerberusUI"
    selfWindow.ConfigName = options.ConfigName or "default"
    selfWindow.UIVisible = true

    local old = GetParent():FindFirstChild("CerberusLibrary")
    if old then
        old:Destroy()
    end

    local gui = Create("ScreenGui", {
        Name = "CerberusLibrary",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = GetParent()
    })
    ProtectGui(gui)

    local root = Create("Frame", {
        Name = "Root",
        Size = UDim2.new(0, selfWindow.Width, 0, selfWindow.Height),
        Position = UDim2.new(0.5, -selfWindow.Width / 2, 0.5, -selfWindow.Height / 2),
        BackgroundColor3 = selfWindow.Theme.Background,
        BorderSizePixel = 1,
        BorderColor3 = selfWindow.Theme.Border,
        Parent = gui
    })

    local topbar = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = selfWindow.Theme.Topbar,
        BorderSizePixel = 0,
        Parent = root
    })

    local title = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        Text = selfWindow.Name,
        Parent = topbar
    })
    ApplyText(title, 22, selfWindow.Theme.Text, true)

    local minBtn = Create("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -52, 0, 0),
        Size = UDim2.new(0, 24, 1, 0),
        Text = "—",
        Parent = topbar
    })
    ApplyText(minBtn, 20, selfWindow.Theme.SubText, false)
    minBtn.TextXAlignment = Enum.TextXAlignment.Center

    local closeBtn = Create("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -26, 0, 0),
        Size = UDim2.new(0, 24, 1, 0),
        Text = "×",
        Parent = topbar
    })
    ApplyText(closeBtn, 22, selfWindow.Theme.SubText, false)
    closeBtn.TextXAlignment = Enum.TextXAlignment.Center

    local sidebar = Create("Frame", {
        Position = UDim2.new(0, 0, 0, 32),
        Size = UDim2.new(0, 214, 1, -32),
        BackgroundColor3 = selfWindow.Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = root
    })

    local tabScroll = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = selfWindow.Theme.Border,
        Parent = sidebar
    })
    local tabLayout = List(tabScroll, 2)
    Padding(tabScroll, 0, 0, 8, 8)
    UpdateScroll(tabScroll, tabLayout, 8)

    local main = Create("Frame", {
        Position = UDim2.new(0, 214, 0, 32),
        Size = UDim2.new(1, -214, 1, -32),
        BackgroundTransparency = 1,
        Parent = root
    })

    local pages = Create("Frame", {
        Position = UDim2.new(0, 5, 0, 5),
        Size = UDim2.new(1, -10, 1, -10),
        BackgroundTransparency = 1,
        Parent = main
    })

    local notifHolder = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 330, 1, -20),
        Position = UDim2.new(1, -340, 0, 10),
        Parent = gui
    })
    local notifLayout = List(notifHolder, 6)
    notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

    local watermark = Create("Frame", {
        BackgroundColor3 = selfWindow.Theme.Topbar,
        BorderColor3 = selfWindow.Theme.Border,
        BorderSizePixel = 1,
        Position = UDim2.new(0, 12, 0, 12),
        Size = UDim2.new(0, 190, 0, 26),
        Parent = gui
    })

    local wmAccent = Create("Frame", {
        BackgroundColor3 = selfWindow.Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
        Parent = watermark
    })

    local wmText = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -10, 1, 0),
        Text = selfWindow.Name .. " | Ready",
        Parent = watermark
    })
    ApplyText(wmText, 18, selfWindow.Theme.Text, true)

    selfWindow.Gui = gui
    selfWindow.Root = root
    selfWindow.Topbar = topbar
    selfWindow.Sidebar = sidebar
    selfWindow.TabScroll = tabScroll
    selfWindow.Pages = pages
    selfWindow.NotificationHolder = notifHolder
    selfWindow.Watermark = watermark
    selfWindow.WatermarkText = wmText

    table.insert(selfWindow.ThemeObjects, {root, "BackgroundColor3", "Background"})
    table.insert(selfWindow.ThemeObjects, {root, "BorderColor3", "Border"})
    table.insert(selfWindow.ThemeObjects, {topbar, "BackgroundColor3", "Topbar"})
    table.insert(selfWindow.ThemeObjects, {sidebar, "BackgroundColor3", "Sidebar"})
    table.insert(selfWindow.ThemeObjects, {title, "TextColor3", "Text"})
    table.insert(selfWindow.ThemeObjects, {minBtn, "TextColor3", "SubText"})
    table.insert(selfWindow.ThemeObjects, {closeBtn, "TextColor3", "SubText"})
    table.insert(selfWindow.ThemeObjects, {tabScroll, "ScrollBarImageColor3", "Border"})
    table.insert(selfWindow.ThemeObjects, {watermark, "BackgroundColor3", "Topbar"})
    table.insert(selfWindow.ThemeObjects, {watermark, "BorderColor3", "Border"})
    table.insert(selfWindow.ThemeObjects, {wmAccent, "BackgroundColor3", "Accent"})
    table.insert(selfWindow.ThemeObjects, {wmText, "TextColor3", "Text"})

    MakeDraggable(topbar, root)

    minBtn.MouseButton1Click:Connect(function()
        selfWindow:SetMinimized(not selfWindow.Minimized)
    end)

    closeBtn.MouseButton1Click:Connect(function()
        selfWindow:Destroy()
    end)

    UIS.InputBegan:Connect(function(input, gp)
        if gp then
            return
        end

        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == selfWindow.ToggleKey then
                selfWindow:SetVisible(not selfWindow.UIVisible)
            end

            for _, bind in ipairs(selfWindow.Keybinds) do
                if bind.Enabled and input.KeyCode == bind.Key then
                    if bind.Mode == "Hold" then
                        bind.Held = true
                        bind.Callback(true, bind.Key)
                    elseif bind.Mode == "Toggle" then
                        bind.State = not bind.State
                        bind.Callback(bind.State, bind.Key)
                    elseif bind.Mode == "Always" then
                        bind.Callback(true, bind.Key)
                    end
                end
            end
        end
    end)

    UIS.InputEnded:Connect(function(input, gp)
        if gp then
            return
        end

        if input.UserInputType == Enum.UserInputType.Keyboard then
            for _, bind in ipairs(selfWindow.Keybinds) do
                if bind.Enabled and input.KeyCode == bind.Key and bind.Mode == "Hold" then
                    bind.Held = false
                    bind.Callback(false, bind.Key)
                end
            end
        end
    end)

    function selfWindow:SetVisible(state)
        self.UIVisible = state
        if state then
            self.Root.Visible = true
            Tween(self.Root, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
            self.Sidebar.Visible = not self.Minimized
            self.Pages.Visible = not self.Minimized
        else
            self.Root.Visible = false
        end
    end

    function selfWindow:SetMinimized(state)
        self.Minimized = state
        if state then
            Tween(self.Root, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, self.Width, 0, 32)
            })
            task.delay(0.18, function()
                if self.Root.Parent then
                    self.Sidebar.Visible = false
                    self.Pages.Visible = false
                end
            end)
        else
            self.Sidebar.Visible = true
            self.Pages.Visible = true
            Tween(self.Root, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, self.Width, 0, self.Height)
            })
        end
    end

    function selfWindow:SetWatermark(text)
        self.WatermarkText.Text = tostring(text)
        local size = TextService:GetTextSize(self.WatermarkText.Text, self.WatermarkText.TextSize, self.WatermarkText.Font, Vector2.new(1000, 100))
        self.Watermark.Size = UDim2.new(0, size.X + 18, 0, 26)
    end

    function selfWindow:Notify(options2)
        options2 = options2 or {}
        local color = options2.Color or self.Theme.Accent
        local titleText = options2.Title or "Notification"
        local contentText = options2.Content or ""
        local duration = options2.Duration or 4

        local card = Create("Frame", {
            BackgroundColor3 = self.Theme.Section,
            BorderColor3 = self.Theme.Border,
            BorderSizePixel = 1,
            Size = UDim2.new(1, 0, 0, 10),
            BackgroundTransparency = 1,
            Parent = self.NotificationHolder
        })

        local left = Create("Frame", {
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 3, 1, 0),
            Parent = card
        })

        local title2 = Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 4),
            Size = UDim2.new(1, -16, 0, 18),
            Text = titleText,
            TextTransparency = 1,
            Parent = card
        })
        ApplyText(title2, 18, self.Theme.Text, true)

        local desc = Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 22),
            Size = UDim2.new(1, -16, 0, 18),
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            Text = contentText,
            TextTransparency = 1,
            Parent = card
        })
        ApplyText(desc, 16, self.Theme.SubText, false)

        local size = TextService:GetTextSize(contentText, 16, desc.Font, Vector2.new(300, 1000))
        local finalHeight = math.max(46, 26 + size.Y + 8)

        card.Size = UDim2.new(1, 0, 0, finalHeight)
        card.Position = UDim2.new(1, 20, 0, 0)

        Tween(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
            Position = UDim2.new(0, 0, 0, 0)
        })
        Tween(title2, TweenInfo.new(0.2), {TextTransparency = 0})
        Tween(desc, TweenInfo.new(0.2), {TextTransparency = 0})

        task.delay(duration, function()
            if not card.Parent then
                return
            end
            Tween(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, 20, 0, 0)
            })
            Tween(title2, TweenInfo.new(0.18), {TextTransparency = 1})
            Tween(desc, TweenInfo.new(0.18), {TextTransparency = 1})
            task.delay(0.22, function()
                if card.Parent then
                    card:Destroy()
                end
            end)
        end)

        return card
    end

    function selfWindow:SetTheme(themeTable)
        for k, v in pairs(themeTable) do
            self.Theme[k] = v
        end
        for _, info in ipairs(self.ThemeObjects) do
            local obj, prop, key = info[1], info[2], info[3]
            if obj and obj.Parent and self.Theme[key] ~= nil then
                pcall(function()
                    obj[prop] = self.Theme[key]
                end)
            end
        end
    end

    function selfWindow:GetTheme()
        return Copy(self.Theme)
    end

    function selfWindow:SaveConfig(name)
        local data = {
            Flags = {},
            Theme = {},
        }

        for k, v in pairs(self.Flags) do
            if typeof(v) == "Color3" then
                data.Flags[k] = {__type = "Color3", R = v.R, G = v.G, B = v.B}
            elseif typeof(v) == "EnumItem" and v.EnumType == Enum.KeyCode then
                data.Flags[k] = {__type = "KeyCode", Value = v.Name}
            else
                data.Flags[k] = v
            end
        end

        for k, v in pairs(self.Theme) do
            if typeof(v) == "Color3" then
                data.Theme[k] = {R = v.R, G = v.G, B = v.B}
            end
        end

        local json = HttpService:JSONEncode(data)
        local folder = self.ConfigFolder
        local file = (name or self.ConfigName) .. ".json"

        if makefolder and not isfolder(folder) then
            makefolder(folder)
        end
        if writefile then
            writefile(folder .. "/" .. file, json)
            return true
        end
        return false
    end

    function selfWindow:LoadConfig(name)
        local folder = self.ConfigFolder
        local file = (name or self.ConfigName) .. ".json"

        if not (readfile and isfile and isfile(folder .. "/" .. file)) then
            return false
        end

        local raw = readfile(folder .. "/" .. file)
        local decoded = HttpService:JSONDecode(raw)

        if decoded.Theme then
            local themePatch = {}
            for k, v in pairs(decoded.Theme) do
                themePatch[k] = Color3.new(v.R, v.G, v.B)
            end
            self:SetTheme(themePatch)
        end

        if decoded.Flags then
            for k, v in pairs(decoded.Flags) do
                if type(v) == "table" and v.__type == "Color3" then
                    self.Flags[k] = Color3.new(v.R, v.G, v.B)
                elseif type(v) == "table" and v.__type == "KeyCode" then
                    self.Flags[k] = Enum.KeyCode[v.Value]
                else
                    self.Flags[k] = v
                end
            end
        end

        for _, tab in ipairs(self.Tabs) do
            for _, section in ipairs(tab.Sections) do
                for _, element in ipairs(section.Elements) do
                    if element.Flag and self.Flags[element.Flag] ~= nil and element.Set then
                        element:Set(self.Flags[element.Flag], true)
                    end
                end
            end
        end

        return true
    end

    function selfWindow:Destroy()
        if self.Gui then
            self.Gui:Destroy()
        end
    end

    return selfWindow
end

function Window:CreateTab(options)
    options = options or {}
    local tab = setmetatable({}, Tab)
    tab.Window = self
    tab.Name = options.Name or "Tab"
    tab.Icon = options.Icon
    tab.Sections = {}

    local theme = self.Theme

    local button = Create("TextButton", {
        BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, 34),
        Text = "",
        Parent = self.TabScroll
    })

    local activeBar = Create("Frame", {
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 4, 1, 0),
        Visible = false,
        Parent = button
    })

    local iconObj
    if tab.Icon then
        iconObj = Create("ImageLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0.5, -10),
            Size = UDim2.new(0, 20, 0, 20),
            Image = tab.Icon,
            ImageColor3 = theme.Text,
            Parent = button
        })
    else
        iconObj = Create("Frame", {
            BackgroundColor3 = theme.Text,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 18, 0.5, -6),
            Size = UDim2.new(0, 12, 0, 12),
            Parent = button
        })
    end

    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 44, 0, 0),
        Size = UDim2.new(1, -52, 1, 0),
        Text = tab.Name,
        Parent = button
    })
    ApplyText(label, 19, theme.SubText, false)

    local page = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        Parent = self.Pages
    })

    local left = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0.5, -4, 1, 0),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Border,
        Parent = page
    })
    local right = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 4, 0, 0),
        Size = UDim2.new(0.5, -4, 1, 0),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Border,
        Parent = page
    })

    local leftLayout = List(left, 6)
    local rightLayout = List(right, 6)
    UpdateScroll(left, leftLayout, 8)
    UpdateScroll(right, rightLayout, 8)

    tab.Button = button
    tab.ActiveBar = activeBar
    tab.Label = label
    tab.IconObject = iconObj
    tab.Page = page
    tab.Left = left
    tab.Right = right

    table.insert(self.ThemeObjects, {activeBar, "BackgroundColor3", "Accent"})
    table.insert(self.ThemeObjects, {label, "TextColor3", "SubText"})
    table.insert(self.ThemeObjects, {left, "ScrollBarImageColor3", "Border"})
    table.insert(self.ThemeObjects, {right, "ScrollBarImageColor3", "Border"})

    function tab:Select()
        for _, t in ipairs(self.Window.Tabs) do
            t.Page.Visible = false
            t.ActiveBar.Visible = false
            t.Button.BackgroundColor3 = self.Window.Theme.Sidebar
            t.Label.TextColor3 = self.Window.Theme.SubText
        end
        self.Page.Visible = true
        self.ActiveBar.Visible = true
        self.Button.BackgroundColor3 = self.Window.Theme.Section
        self.Label.TextColor3 = self.Window.Theme.Text
        Tween(self.Button, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = self.Window.Theme.Section
        })
    end

    button.MouseButton1Click:Connect(function()
        tab:Select()
    end)

    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then
        tab:Select()
    end

    return tab
end

function Tab:CreateSection(options)
    options = options or {}
    local side = (options.Side or "Left"):lower()
    local parentCol = side == "right" and self.Right or self.Left
    local theme = self.Window.Theme

    local section = setmetatable({}, Section)
    section.Window = self.Window
    section.Tab = self
    section.Title = options.Name or "Section"
    section.Elements = {}
    section.Collapsed = false

    local holder = Create("Frame", {
        BackgroundColor3 = theme.Section,
        BorderColor3 = theme.Border,
        BorderSizePixel = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = parentCol
    })
    local holderList = List(holder, 4)
    Padding(holder, 4, 4, 4, 4)

    local header = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        AutoButtonColor = false,
        Text = "",
        Parent = holder
    })

    local title = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 1, 0),
        Text = section.Title,
        Parent = header
    })
    ApplyText(title, 20, theme.Text, false)

    local arrow = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 0, 0),
        Size = UDim2.new(0, 20, 1, 0),
        Text = "⌄",
        Parent = header
    })
    ApplyText(arrow, 18, theme.SubText, false)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    local line = Create("Frame", {
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        Parent = holder
    })

    local content = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = holder
    })
    local contentLayout = List(content, 4)

    table.insert(self.Window.ThemeObjects, {holder, "BackgroundColor3", "Section"})
    table.insert(self.Window.ThemeObjects, {holder, "BorderColor3", "Border"})
    table.insert(self.Window.ThemeObjects, {title, "TextColor3", "Text"})
    table.insert(self.Window.ThemeObjects, {arrow, "TextColor3", "SubText"})
    table.insert(self.Window.ThemeObjects, {line, "BackgroundColor3", "Accent"})

    local function refresh()
        content.Size = UDim2.new(1, 0, 0, contentLayout.AbsoluteContentSize.Y)
        local h = 4 + 20 + 4 + 2 + 4
        if not section.Collapsed then
            h = h + contentLayout.AbsoluteContentSize.Y
        end
        holder.Size = UDim2.new(1, 0, 0, h)
        content.Visible = not section.Collapsed
        arrow.Text = section.Collapsed and ">" or "⌄"
    end

    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh)

    header.MouseButton1Click:Connect(function()
        section.Collapsed = not section.Collapsed
        if section.Collapsed then
            Tween(holder, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, 34)
            })
        end
        refresh()
    end)

    section.Holder = holder
    section.Content = content
    section.Refresh = refresh

    table.insert(self.Sections, section)
    refresh()

    return section
end

function Section:_Register(api)
    table.insert(self.Elements, api)
    return api
end

function Section:AddLabel(options)
    options = options or {}
    local theme = self.Window.Theme

    local frame = Create("Frame", {
        BackgroundColor3 = theme.Element2,
        BorderColor3 = theme.BorderSoft,
        BorderSizePixel = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Parent = self.Content
    })

    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 4, 0, 0),
        Size = UDim2.new(1, -8, 1, 0),
        Text = options.Text or "Label",
        Parent = frame
    })
    ApplyText(label, 18, theme.Text, false)

    table.insert(self.Window.ThemeObjects, {frame, "BackgroundColor3", "Element2"})
    table.insert(self.Window.ThemeObjects, {frame, "BorderColor3", "BorderSoft"})
    table.insert(self.Window.ThemeObjects, {label, "TextColor3", "Text"})

    local api = {}
    function api:Set(v)
        label.Text = tostring(v)
    end

    self:Refresh()
    return self:_Register(api)
end

function Section:AddParagraph(options)
    options = options or {}
    local theme = self.Window.Theme

    local frame = Create("Frame", {
        BackgroundColor3 = theme.Element2,
        BorderColor3 = theme.BorderSoft,
        BorderSizePixel = 1,
        Size = UDim2.new(1, 0, 0, 40),
        Parent = self.Content
    })

    local title = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 4, 0, 2),
        Size = UDim2.new(1, -8, 0, 18),
        Text = options.Title or "Paragraph",
        Parent = frame
    })
    ApplyText(title, 18, theme.Text, true)

    local body = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 4, 0, 20),
        Size = UDim2.new(1, -8, 0, 18),
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = options.Content or "",
        Parent = frame
    })
    ApplyText(body, 16, theme.SubText, false)

    local function resize()
        local bound = TextService:GetTextSize(body.Text, 16, body.Font, Vector2.new(math.max(frame.AbsoluteSize.X - 8, 50), 9999))
        frame.Size = UDim2.new(1, 0, 0, 24 + bound.Y + 4)
        body.Size = UDim2.new(1, -8, 0, bound.Y)
        self:Refresh()
    end

    resize()

    local api = {}
    function api:SetTitle(v)
        title.Text = tostring(v)
        resize()
    end
    function api:SetContent(v)
        body.Text = tostring(v)
        resize()
    end

    self:Refresh()
    return self:_Register(api)
end

function Section:AddButton(options)
    options = options or {}
    local theme = self.Window.Theme

    local button = Create("TextButton", {
        BackgroundColor3 = theme.Element2,
        BorderColor3 = theme.BorderSoft,
        BorderSizePixel = 1,
        Size = UDim2.new(1, 0, 0, 22),
        AutoButtonColor = false,
        Text = "",
        Parent = self.Content
    })

    local text = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 4, 0, 0),
        Size = UDim2.new(1, -8, 1, 0),
        Text = options.Text or "Button",
        Parent = button
    })
    ApplyText(text, 18, theme.Text, false)

    local function flash()
        Tween(button, TweenInfo.new(0.08), {BackgroundColor3 = theme.Element})
        task.delay(0.08, function()
            if button.Parent then
                Tween(button, TweenInfo.new(0.12), {BackgroundColor3 = theme.Element2})
            end
        end)
    end

    button.MouseEnter:Connect(function()
        Tween(button, TweenInfo.new(0.12), {BackgroundColor3 = theme.Element})
    end)
    button.MouseLeave:Connect(function()
        Tween(button, TweenInfo.new(0.12), {BackgroundColor3 = theme.Element2})
    end)
    button.MouseButton1Click:Connect(function()
        flash()
        if options.Callback then
            options.Callback()
        end
    end)

    local api = {}
    function api:SetText(v)
        text.Text = tostring(v)
    end
    function api:Fire()
        if options.Callback then
            options.Callback()
        end
    end

    self:Refresh()
    return self:_Register(api)
end

function Section:AddToggle(options)
    options = options or {}
    local theme = self.Window.Theme
    local flag = options.Flag
    local state = options.Default or false

    if flag then
        self.Window.Flags[flag] = state
    end

    local row = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Text = "",
        AutoButtonColor = false,
        Parent = self.Content
    })

    local box = Create("Frame", {
        BackgroundColor3 = theme.Element2,
        BorderColor3 = theme.Border,
        BorderSizePixel = 1,
        Position = UDim2.new(0, 0, 0.5, -6),
        Size = UDim2.new(0, 12, 0, 12),
        Parent = row
    })

    local fill = Create("Frame", {
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 2, 0, 2),
        Size = UDim2.new(1, -4, 1, -4),
        BackgroundTransparency = state and 0 or 1,
        Parent = box
    })

    local text = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0, 0),
        Size = UDim2.new(1, -18, 1, 0),
        Text = options.Text or "Toggle",
        Parent = row
    })
    ApplyText(text, 18, theme.Text, false)

    local api = {Flag = flag}
    function api:Set(v, silent)
        state = not not v
        Tween(fill, TweenInfo.new(0.12), {
            BackgroundTransparency = state and 0 or 1
        })
        if flag then
            self.Window.Flags[flag] = state
        end
        if not silent and options.Callback then
            options.Callback(state)
        end
    end
    function api:Get()
        return state
    end

    row.MouseButton1Click:Connect(function()
        api:Set(not state)
    end)

    self:Refresh()
    return self:_Register(api)
end

function Section:AddTextbox(options)
    options = options or {}
    local theme = self.Window.Theme
    local flag = options.Flag
    local value = options.Default or ""

    if flag then
        self.Window.Flags[flag] = value
    end

    local row = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Parent = self.Content
    })

    local text = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.46, 0, 1, 0),
        Text = options.Text or "Textbox",
        Parent = row
    })
    ApplyText(text, 18, theme.Text, false)

    local box = Create("TextBox", {
        BackgroundColor3 = theme.Element2,
        BorderColor3 = theme.BorderSoft,
        BorderSizePixel = 1,
        Position = UDim2.new(1, -82, 0, 2),
        Size = UDim2.new(0, 82, 1, -4),
        Text = value,
        PlaceholderText = options.Placeholder or "Type here...",
        ClearTextOnFocus = false,
        Parent = row
    })
    ApplyText(box, 16, theme.SubText, false)

    box.Focused:Connect(function()
        Tween(box, TweenInfo.new(0.12), {BorderColor3 = theme.Accent})
    end)
    box.FocusLost:Connect(function(enter)
        Tween(box, TweenInfo.new(0.12), {BorderColor3 = theme.BorderSoft})
        value = box.Text
        if flag then
            self.Window.Flags[flag] = value
        end
        if options.Callback then
            options.Callback(value, enter)
        end
    end)

    local api = {Flag = flag}
    function api:Set(v, silent)
        value = tostring(v)
        box.Text = value
        if flag then
            self.Window.Flags[flag] = value
        end
        if not silent and options.Callback then
            options.Callback(value, false)
        end
    end
    function api:Get()
        return value
    end

    self:Refresh()
    return self:_Register(api)
end

function Section:AddSlider(options)
    options = options or {}
    local theme = self.Window.Theme
    local min = options.Min or 0
    local max = options.Max or 100
    local decimals = options.Decimals or 0
    local value = options.Default or min
    local flag = options.Flag
    local dragging = false

    if flag then
        self.Window.Flags[flag] = value
    end

    local row = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 38),
        Parent = self.Content
    })

    local text = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.75, 0, 0, 16),
        Text = options.Text or "Slider",
        Parent = row
    })
    ApplyText(text, 18, theme.Text, false)

    local number = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -40, 0, 0),
        Size = UDim2.new(0, 40, 0, 16),
        Text = tostring(value),
        Parent = row
    })
    ApplyText(number, 18, theme.SubText, false)
    number.TextXAlignment = Enum.TextXAlignment.Right

    local bar = Create("Frame", {
        BackgroundColor3 = theme.Element2,
        BorderColor3 = theme.Border,
        BorderSizePixel = 1,
        Position = UDim2.new(0, 0, 0, 20),
        Size = UDim2.new(1, 0, 0, 12),
        Parent = row
    })

    local fill = Create("Frame", {
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
        Parent = bar
    })

    local knob = Create("Frame", {
        BackgroundColor3 = theme.Text,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 4, 1, 0),
        Parent = fill
    })

    local api = {Flag = flag}

    function api:Set(v, silent)
        v = Clamp(v, min, max)
        if decimals <= 0 then
            v = math.floor(v + 0.5)
        else
            local p = 10 ^ decimals
            v = math.floor(v * p + 0.5) / p
        end
        value = v
        local pct = (value - min) / (max - min)
        Tween(fill, TweenInfo.new(dragging and 0.04 or 0.1), {
            Size = UDim2.new(pct, 0, 1, 0)
        })
        number.Text = tostring(value)
        if flag then
            self.Window.Flags[flag] = value
        end
        if not silent and options.Callback then
            options.Callback(value)
        end
    end

    function api:Get()
        return value
    end

    local function setFromX(x)
        local rel = Clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        api:Set(min + (max - min) * rel)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setFromX(input.Position.X)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(input.Position.X)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    api:Set(value, true)

    self:Refresh()
    return self:_Register(api)
end

function Section:AddDropdown(options)
    options = options or {}
    local theme = self.Window.Theme
    local items = options.Values or {}
    local multi = options.Multi or false
    local searchable = if options.Searchable == nil then true else options.Searchable
    local flag = options.Flag
    local opened = false
    local selected = multi and (options.Default or {}) or (options.Default or nil)
    local buttons = {}

    if flag then
        self.Window.Flags[flag] = selected
    end

    local holder = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, searchable and 48 or 24),
        Parent = self.Content
    })

    local top = Create("TextButton", {
        BackgroundColor3 = theme.Element2,
        BorderColor3 = theme.BorderSoft,
        BorderSizePixel = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Text = "",
        AutoButtonColor = false,
        Parent = holder
    })

    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 4, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Text = options.Text or "Dropdown",
        Parent = top
    })
    ApplyText(label, 18, theme.Text, false)

    local arrow = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -16, 0, 0),
        Size = UDim2.new(0, 16, 1, 0),
        Text = "^",
        Parent = top
    })
    ApplyText(arrow, 16, theme.SubText, false)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    local search = Create("TextBox", {
        Visible = searchable,
        BackgroundColor3 = theme.Element2,
        BorderColor3 = theme.BorderSoft,
        BorderSizePixel = 1,
        Position = UDim2.new(0, 0, 0, 26),
        Size = UDim2.new(1, 0, 0, 20),
        Text = "",
        PlaceholderText = options.Placeholder or "Search...",
        ClearTextOnFocus = false,
        Parent = holder
    })
    ApplyText(search, 16, theme.SubText, false)

    local dropdown = Create("Frame", {
        BackgroundColor3 = theme.Section,
        BorderColor3 = theme.Border,
        BorderSizePixel = 1,
        Position = UDim2.new(0, 0, 0, searchable and 50 or 24),
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
        ClipsDescendants = true,
        Parent = holder
    })

    local scroll = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Border,
        Parent = dropdown
    })
    Padding(scroll, 2, 2, 2, 2)
    local layout = List(scroll, 2)
    UpdateScroll(scroll, layout, 4)

    local function contains(tbl, val)
        for i, v in ipairs(tbl) do
            if v == val then
                return i
            end
        end
    end

    local function getText()
        if multi then
            if #selected == 0 then
                return options.Text or "Dropdown"
            end
            local parts = {}
            for _, v in ipairs(selected) do
                table.insert(parts, tostring(v))
            end
            return table.concat(parts, ", ")
        end
        return selected and tostring(selected) or (options.Text or "Dropdown")
    end

    local function callback(silent)
        label.Text = getText()
        if flag then
            self.Window.Flags[flag] = selected
        end
        if not silent and options.Callback then
            options.Callback(selected)
        end
    end

    local function clearButtons()
        for _, b in ipairs(buttons) do
            b:Destroy()
        end
        buttons = {}
    end

    local function rebuild(filter)
        clearButtons()
        local count = 0
        for _, item in ipairs(items) do
            local textItem = tostring(item)
            local show = true
            if filter and filter ~= "" then
                show = textItem:lower():find(filter:lower(), 1, true) ~= nil
            end
            if show then
                count += 1
                local btn = Create("TextButton", {
                    BackgroundColor3 = theme.Element2,
                    BorderColor3 = theme.BorderSoft,
                    BorderSizePixel = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Text = textItem,
                    AutoButtonColor = false,
                    Parent = scroll
                })
                ApplyText(btn, 17, theme.Text, false)
                btn.MouseEnter:Connect(function()
                    Tween(btn, TweenInfo.new(0.1), {BackgroundColor3 = theme.Element})
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn, TweenInfo.new(0.1), {BackgroundColor3 = theme.Element2})
                end)
                btn.MouseButton1Click:Connect(function()
                    if multi then
                        local idx = contains(selected, item)
                        if idx then
                            table.remove(selected, idx)
                        else
                            table.insert(selected, item)
                        end
                    else
                        selected = item
                        opened = false
                        arrow.Text = "^"
                        Tween(dropdown, TweenInfo.new(0.14), {Size = UDim2.new(1, 0, 0, 0)})
                        task.delay(0.14, function()
                            if dropdown.Parent then
                                dropdown.Visible = false
                                holder.Size = UDim2.new(1, 0, 0, searchable and 48 or 24)
                                self:Refresh()
                            end
                        end)
                    end
                    callback()
                end)
                table.insert(buttons, btn)
            end
        end

        local h = math.min(count * 22 + 4, 132)
        holder.Size = UDim2.new(1, 0, 0, (searchable and 48 or 24) + (opened and h + 4 or 0))
        Tween(dropdown, TweenInfo.new(0.14), {Size = UDim2.new(1, 0, 0, opened and h or 0)})
        self:Refresh()
    end

    local api = {Flag = flag}
    function api:Set(v, silent)
        selected = v
        callback(silent)
    end
    function api:Get()
        return selected
    end
    function api:Refresh(values, keep)
        items = values or {}
        if not keep then
            selected = multi and {} or nil
        end
        rebuild(search.Text)
        callback(true)
    end
    function api:Add(v)
        table.insert(items, v)
        rebuild(search.Text)
    end
    function api:Remove(v)
        for i, it in ipairs(items) do
            if it == v then
                table.remove(items, i)
                break
            end
        end
        rebuild(search.Text)
    end

    top.MouseButton1Click:Connect(function()
        opened = not opened
        dropdown.Visible = true
        arrow.Text = opened and "⌄" or "^"
        rebuild(search.Text)
        if not opened then
            Tween(dropdown, TweenInfo.new(0.14), {Size = UDim2.new(1, 0, 0, 0)})
            task.delay(0.14, function()
                if dropdown.Parent and not opened then
                    dropdown.Visible = false
                    holder.Size = UDim2.new(1, 0, 0, searchable and 48 or 24)
                    self:Refresh()
                end
            end)
        end
    end)

    search:GetPropertyChangedSignal("Text"):Connect(function()
        if opened then
            rebuild(search.Text)
        end
    end)

    callback(true)
    self:Refresh()
    return self:_Register(api)
end

function Section:AddColorPicker(options)
    options = options or {}
    local theme = self.Window.Theme
    local flag = options.Flag
    local color = options.Default or Color3.fromRGB(255, 0, 0)
    local h, s, v = color:ToHSV()
    local opened = false
    local dragSV = false
    local dragH = false

    if flag then
        self.Window.Flags[flag] = color
    end

    local holder = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Parent = self.Content
    })

    local top = Create("TextButton", {
        BackgroundColor3 = theme.Element2,
        BorderColor3 = theme.BorderSoft,
        BorderSizePixel = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Text = "",
        AutoButtonColor = false,
        Parent = holder
    })

    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 4, 0, 0),
        Size = UDim2.new(1, -42, 1, 0),
        Text = options.Text or "ColorWheel",
        Parent = top
    })
    ApplyText(label, 18, theme.Text, false)

    local preview = Create("Frame", {
        BackgroundColor3 = color,
        BorderColor3 = theme.Border,
        BorderSizePixel = 1,
        Position = UDim2.new(1, -28, 0.5, -6),
        Size = UDim2.new(0, 12, 0, 12),
        Parent = top
    })
    Corner(preview, 12)

    local arrow = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -16, 0, 0),
        Size = UDim2.new(0, 16, 1, 0),
        Text = "^",
        Parent = top
    })
    ApplyText(arrow, 16, theme.SubText, false)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    local picker = Create("Frame", {
        BackgroundColor3 = theme.Section,
        BorderColor3 = theme.Border,
        BorderSizePixel = 1,
        Position = UDim2.new(0, 0, 0, 26),
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
        ClipsDescendants = true,
        Parent = holder
    })

    local sv = Create("ImageButton", {
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        BorderColor3 = theme.BorderSoft,
        BorderSizePixel = 1,
        Position = UDim2.new(0, 4, 0, 4),
        Size = UDim2.new(1, -16, 0, 86),
        Image = "rbxassetid://4155801252",
        ScaleType = Enum.ScaleType.Stretch,
        AutoButtonColor = false,
        Parent = picker
    })

    local svCursor = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 6, 0, 6),
        Parent = sv
    })
    Corner(svCursor, 6)

    local hue = Create("ImageButton", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderColor3 = theme.BorderSoft,
        BorderSizePixel = 1,
        Position = UDim2.new(1, -10, 0, 4),
        Size = UDim2.new(0, 6, 0, 86),
        Image = "rbxassetid://3641079629",
        ScaleType = Enum.ScaleType.Stretch,
        AutoButtonColor = false,
        Parent = picker
    })

    local hueCursor = Create("Frame", {
        BackgroundColor3 = theme.Text,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(1, 4, 0, 2),
        Parent = hue
    })

    local rgb = Create("TextBox", {
        BackgroundColor3 = theme.Element2,
        BorderColor3 = theme.BorderSoft,
        BorderSizePixel = 1,
        Position = UDim2.new(0, 4, 0, 94),
        Size = UDim2.new(1, -8, 0, 20),
        Text = "",
        PlaceholderText = "255, 0, 0",
        ClearTextOnFocus = false,
        Parent = picker
    })
    ApplyText(rgb, 16, theme.SubText, false)

    local api = {Flag = flag}

    local function apply(silent)
        color = Color3.fromHSV(h, s, v)
        preview.BackgroundColor3 = color
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
        hueCursor.Position = UDim2.new(0.5, 0, h, 0)
        rgb.Text = string.format("%d, %d, %d", color.R * 255, color.G * 255, color.B * 255)
        if flag then
            self.Window.Flags[flag] = color
        end
        if not silent and options.Callback then
            options.Callback(color)
        end
    end

    function api:Set(c, silent)
        local hh, ss, vv = c:ToHSV()
        h, s, v = hh, ss, vv
        apply(silent)
    end
    function api:Get()
        return color
    end

    local function setSV(pos)
        local x = Clamp((pos.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
        local y = Clamp((pos.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
        s = x
        v = 1 - y
        apply()
    end

    local function setH(pos)
        local y = Clamp((pos.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1)
        h = y
        apply()
    end

    sv.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragSV = true
            setSV(input.Position)
        end
    end)

    hue.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragH = true
            setH(input.Position)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if dragSV then
                setSV(input.Position)
            end
            if dragH then
                setH(input.Position)
            end
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragSV = false
            dragH = false
        end
    end)

    rgb.FocusLost:Connect(function()
        local r, g, b = rgb.Text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
        if r and g and b then
            api:Set(Color3.fromRGB(Clamp(tonumber(r), 0, 255), Clamp(tonumber(g), 0, 255), Clamp(tonumber(b), 0, 255)))
        end
    end)

    top.MouseButton1Click:Connect(function()
        opened = not opened
        picker.Visible = true
        arrow.Text = opened and "⌄" or "^"
        holder.Size = UDim2.new(1, 0, 0, opened and 148 or 24)
        Tween(picker, TweenInfo.new(0.14), {Size = UDim2.new(1, 0, 0, opened and 118 or 0)})
        if not opened then
            task.delay(0.14, function()
                if picker.Parent and not opened then
                    picker.Visible = false
                end
            end)
        end
        self:Refresh()
    end)

    apply(true)
    self:Refresh()
    return self:_Register(api)
end

function Section:AddKeybind(options)
    options = options or {}
    local theme = self.Window.Theme
    local flag = options.Flag
    local key = options.Default or Enum.KeyCode.F
    local mode = options.Mode or "Toggle"
    local waiting = false
    local state = false

    local validModes = {
        Hold = true,
        Toggle = true,
        Always = true
    }
    if not validModes[mode] then
        mode = "Toggle"
    end

    if flag then
        self.Window.Flags[flag] = key
    end

    local row = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Parent = self.Content
    })

    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.42, 0, 1, 0),
        Text = options.Text or "Keybind",
        Parent = row
    })
    ApplyText(label, 18, theme.Text, false)

    local modeBtn = Create("TextButton", {
        BackgroundColor3 = theme.Element2,
        BorderColor3 = theme.BorderSoft,
        BorderSizePixel = 1,
        Position = UDim2.new(1, -74, 0, 2),
        Size = UDim2.new(0, 48, 1, -4),
        Text = mode,
        AutoButtonColor = false,
        Parent = row
    })
    ApplyText(modeBtn, 14, theme.SubText, false)
    modeBtn.TextXAlignment = Enum.TextXAlignment.Center

    local keyBtn = Create("TextButton", {
        BackgroundColor3 = theme.Element2,
        BorderColor3 = theme.BorderSoft,
        BorderSizePixel = 1,
        Position = UDim2.new(1, -20, 0, 2),
        Size = UDim2.new(0, 20, 1, -4),
        Text = key.Name,
        AutoButtonColor = false,
        Parent = row
    })
    ApplyText(keyBtn, 14, theme.SubText, false)
    keyBtn.TextXAlignment = Enum.TextXAlignment.Center

    local modes = {"Hold", "Toggle", "Always"}

    local bindData = {
        Enabled = true,
        Key = key,
        Mode = mode,
        State = false,
        Held = false,
        Callback = function(active, pressKey)
            if options.Callback then
                options.Callback(active, pressKey, mode)
            end
        end
    }
    table.insert(self.Window.Keybinds, bindData)

    local api = {Flag = flag}

    function api:Set(v, silent)
        if typeof(v) == "EnumItem" then
            key = v
            bindData.Key = key
            keyBtn.Text = key.Name
            if flag then
                self.Window.Flags[flag] = key
            end
            if not silent and options.Changed then
                options.Changed(key, mode)
            end
        elseif type(v) == "table" then
            if v.Key then
                key = v.Key
                bindData.Key = key
                keyBtn.Text = key.Name
                if flag then
                    self.Window.Flags[flag] = key
                end
            end
            if v.Mode and validModes[v.Mode] then
                mode = v.Mode
                bindData.Mode = mode
                modeBtn.Text = mode
            end
            if not silent and options.Changed then
                options.Changed(key, mode)
            end
        end
    end

    function api:Get()
        return {
            Key = key,
            Mode = mode,
            State = bindData.State
        }
    end

    function api:SetMode(newMode)
        if validModes[newMode] then
            mode = newMode
            bindData.Mode = mode
            modeBtn.Text = mode
            if options.Changed then
                options.Changed(key, mode)
            end
        end
    end

    function api:SetState(v)
        bindData.State = not not v
    end

    keyBtn.MouseButton1Click:Connect(function()
        waiting = true
        keyBtn.Text = "..."
    end)

    modeBtn.MouseButton1Click:Connect(function()
        local currentIndex = table.find(modes, mode) or 1
        currentIndex += 1
        if currentIndex > #modes then
            currentIndex = 1
        end
        mode = modes[currentIndex]
        bindData.Mode = mode
        modeBtn.Text = mode
        if options.Changed then
            options.Changed(key, mode)
        end
    end)

    UIS.InputBegan:Connect(function(input, gp)
        if gp then
            return
        end
        if waiting and input.UserInputType == Enum.UserInputType.Keyboard then
            waiting = false
            key = input.KeyCode
            bindData.Key = key
            keyBtn.Text = key.Name
            if flag then
                self.Window.Flags[flag] = key
            end
            if options.Changed then
                options.Changed(key, mode)
            end
        end
    end)

    self:Refresh()
    return self:_Register(api)
end

return Cerberus
