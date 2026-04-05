local Cerberus = {}
Cerberus.__index = Cerberus

local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
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

local function Create(class, props)
	local obj = Instance.new(class)
	for k, v in pairs(props or {}) do
		obj[k] = v
	end
	return obj
end

local function Copy(tbl)
	local t = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			t[k] = Copy(v)
		else
			t[k] = v
		end
	end
	return t
end

local function Clamp(x, a, b)
	return math.max(a, math.min(b, x))
end

local function Round(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = obj
	return c
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

local function Tween(obj, info, props)
	local tw = TweenService:Create(obj, info, props)
	tw:Play()
	return tw
end

local function ApplyText(obj, size, color, bold)
	obj.Font = bold and Enum.Font.SourceSansSemibold or Enum.Font.SourceSans
	obj.TextSize = size
	obj.TextColor3 = color
	obj.TextXAlignment = Enum.TextXAlignment.Left
	obj.TextYAlignment = Enum.TextYAlignment.Center
end

local function BindCanvas(scroll, layout, extra)
	local function update()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + (extra or 0))
	end
	update()
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
	return update
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
	Background = Color3.fromRGB(24, 24, 31),
	Topbar = Color3.fromRGB(30, 30, 38),
	Sidebar = Color3.fromRGB(28, 28, 36),
	Section = Color3.fromRGB(30, 30, 39),
	Element = Color3.fromRGB(38, 38, 49),
	Element2 = Color3.fromRGB(27, 27, 35),
	Border = Color3.fromRGB(60, 60, 74),
	BorderSoft = Color3.fromRGB(48, 48, 60),
	Text = Color3.fromRGB(240, 240, 245),
	SubText = Color3.fromRGB(170, 170, 180),
	Accent = Color3.fromRGB(232, 40, 40),
	AccentDark = Color3.fromRGB(140, 20, 20),
	Success = Color3.fromRGB(80, 220, 120),
	Danger = Color3.fromRGB(255, 80, 90),
	Warning = Color3.fromRGB(225, 190, 60),
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
	if options.Theme then
		for k, v in pairs(options.Theme) do
			selfWindow.Theme[k] = v
		end
	end

	selfWindow.Flags = options.Flags or {}
	selfWindow.Tabs = {}
	selfWindow.Keybinds = {}
	selfWindow.Name = options.Name or "Cerberus"
	selfWindow.Width = options.Width or 860
	selfWindow.Height = options.Height or 540
	selfWindow.ToggleKey = options.ToggleKey or Enum.KeyCode.RightShift
	selfWindow.ConfigFolder = options.ConfigFolder or "CerberusUI"
	selfWindow.ConfigName = options.ConfigName or "default"
	selfWindow.UIVisible = true
	selfWindow.Minimized = false
	selfWindow._themeRefs = {}

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

	local topInset = GuiService:GetGuiInset().Y + 12

	local root = Create("Frame", {
		Name = "Root",
		Size = UDim2.new(0, selfWindow.Width, 0, selfWindow.Height),
		Position = UDim2.new(0.5, -selfWindow.Width / 2, 0.5, -selfWindow.Height / 2 + 8),
		BackgroundColor3 = selfWindow.Theme.Background,
		BorderColor3 = selfWindow.Theme.Border,
		BorderSizePixel = 1,
		Parent = gui,
		ClipsDescendants = true
	})
	Round(root, 8)

	local topbar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = selfWindow.Theme.Topbar,
		BorderSizePixel = 0,
		Parent = root
	})
	Round(topbar, 8)

	local topbarFix = Create("Frame", {
		BackgroundColor3 = selfWindow.Theme.Topbar,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -8),
		Size = UDim2.new(1, 0, 0, 8),
		Parent = topbar
	})

	local title = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -80, 1, 0),
		Text = selfWindow.Name,
		Parent = topbar
	})
	ApplyText(title, 21, selfWindow.Theme.Text, true)

	local minimize = Create("TextButton", {
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -50, 0, 0),
		Size = UDim2.new(0, 22, 1, 0),
		Text = "—",
		Parent = topbar
	})
	ApplyText(minimize, 18, selfWindow.Theme.SubText, false)
	minimize.TextXAlignment = Enum.TextXAlignment.Center

	local close = Create("TextButton", {
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -26, 0, 0),
		Size = UDim2.new(0, 22, 1, 0),
		Text = "×",
		Parent = topbar
	})
	ApplyText(close, 20, selfWindow.Theme.SubText, false)
	close.TextXAlignment = Enum.TextXAlignment.Center

	local sidebar = Create("Frame", {
		Position = UDim2.new(0, 0, 0, 30),
		Size = UDim2.new(0, 200, 1, -30),
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
	Padding(tabScroll, 0, 0, 8, 8)
	local tabLayout = List(tabScroll, 2)
	BindCanvas(tabScroll, tabLayout, 8)

	local main = Create("Frame", {
		Position = UDim2.new(0, 200, 0, 30),
		Size = UDim2.new(1, -200, 1, -30),
		BackgroundTransparency = 1,
		Parent = root
	})

	local pages = Create("Frame", {
		Position = UDim2.new(0, 6, 0, 6),
		Size = UDim2.new(1, -12, 1, -12),
		BackgroundTransparency = 1,
		Parent = main
	})

	local notifHolder = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 310, 1, -20),
		Position = UDim2.new(1, -320, 0, 10),
		Parent = gui
	})
	local notifLayout = List(notifHolder, 6)
	notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

	local watermark = Create("Frame", {
		BackgroundColor3 = selfWindow.Theme.Topbar,
		BorderColor3 = selfWindow.Theme.Border,
		BorderSizePixel = 1,
		Position = UDim2.new(0, 12, 0, topInset + 10),
		Size = UDim2.new(0, 180, 0, 24),
		Parent = gui
	})
	Round(watermark, 7)

	local watermarkAccent = Create("Frame", {
		BackgroundColor3 = selfWindow.Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 1, 0),
		Parent = watermark
	})
	Round(watermarkAccent, 7)

	local watermarkText = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(1, -10, 1, 0),
		Text = selfWindow.Name .. " | Ready",
		Parent = watermark
	})
	ApplyText(watermarkText, 16, selfWindow.Theme.Text, true)

	selfWindow.Gui = gui
	selfWindow.Root = root
	selfWindow.Topbar = topbar
	selfWindow.Sidebar = sidebar
	selfWindow.TabScroll = tabScroll
	selfWindow.Pages = pages
	selfWindow.NotificationHolder = notifHolder
	selfWindow.Watermark = watermark
	selfWindow.WatermarkText = watermarkText
	selfWindow.WatermarkAccent = watermarkAccent

	MakeDraggable(topbar, root)

	function selfWindow:SetVisible(state)
		self.UIVisible = state
		self.Root.Visible = state
		self.Watermark.Visible = state
	end

	function selfWindow:SetMinimized(state)
		self.Minimized = state
		if state then
			self.Sidebar.Visible = false
			self.Pages.Visible = false
			Tween(self.Root, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, self.Width, 0, 30)
			})
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
		local size = TextService:GetTextSize(self.WatermarkText.Text, self.WatermarkText.TextSize, self.WatermarkText.Font, Vector2.new(1000, 24))
		self.Watermark.Size = UDim2.new(0, size.X + 18, 0, 24)
	end

	function selfWindow:Notify(data)
		data = data or {}
		local titleText = data.Title or "Notification"
		local contentText = data.Content or ""
		local duration = data.Duration or 4
		local color = data.Color or self.Theme.Accent

		local card = Create("Frame", {
			BackgroundColor3 = self.Theme.Section,
			BorderColor3 = self.Theme.Border,
			BorderSizePixel = 1,
			Size = UDim2.new(1, 0, 0, 54),
			Parent = self.NotificationHolder,
			BackgroundTransparency = 1
		})
		Round(card, 7)

		local left = Create("Frame", {
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 3, 1, 0),
			Parent = card
		})
		Round(left, 7)

		local titleLabel = Create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 4),
			Size = UDim2.new(1, -16, 0, 18),
			Text = titleText,
			TextTransparency = 1,
			Parent = card
		})
		ApplyText(titleLabel, 17, self.Theme.Text, true)

		local contentLabel = Create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 22),
			Size = UDim2.new(1, -16, 0, 16),
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = contentText,
			TextTransparency = 1,
			Parent = card
		})
		ApplyText(contentLabel, 15, self.Theme.SubText, false)

		local textSize = TextService:GetTextSize(contentText, 15, contentLabel.Font, Vector2.new(280, 1000))
		local height = math.max(50, 28 + textSize.Y + 8)
		card.Size = UDim2.new(1, 0, 0, height)
		card.Position = UDim2.new(1, 20, 0, 0)

		Tween(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0,
			Position = UDim2.new(0, 0, 0, 0)
		})
		Tween(titleLabel, TweenInfo.new(0.18), {TextTransparency = 0})
		Tween(contentLabel, TweenInfo.new(0.18), {TextTransparency = 0})

		task.delay(duration, function()
			if not card.Parent then
				return
			end
			Tween(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 1,
				Position = UDim2.new(1, 20, 0, 0)
			})
			Tween(titleLabel, TweenInfo.new(0.14), {TextTransparency = 1})
			Tween(contentLabel, TweenInfo.new(0.14), {TextTransparency = 1})
			task.delay(0.2, function()
				if card.Parent then
					card:Destroy()
				end
			end)
		end)

		return card
	end

	function selfWindow:SetTheme(patch)
		for k, v in pairs(patch) do
			self.Theme[k] = v
		end
	end

	function selfWindow:GetTheme()
		return Copy(self.Theme)
	end

	function selfWindow:SaveConfig(name)
		local payload = {Flags = {}, Theme = {}}

		for k, v in pairs(self.Flags) do
			if typeof(v) == "Color3" then
				payload.Flags[k] = {__type = "Color3", R = v.R, G = v.G, B = v.B}
			elseif typeof(v) == "EnumItem" and v.EnumType == Enum.KeyCode then
				payload.Flags[k] = {__type = "KeyCode", Value = v.Name}
			else
				payload.Flags[k] = v
			end
		end

		for k, v in pairs(self.Theme) do
			if typeof(v) == "Color3" then
				payload.Theme[k] = {R = v.R, G = v.G, B = v.B}
			end
		end

		if not writefile then
			return false
		end

		if makefolder and not isfolder(self.ConfigFolder) then
			makefolder(self.ConfigFolder)
		end

		writefile(self.ConfigFolder .. "/" .. (name or self.ConfigName) .. ".json", HttpService:JSONEncode(payload))
		return true
	end

	function selfWindow:LoadConfig(name)
		local path = self.ConfigFolder .. "/" .. (name or self.ConfigName) .. ".json"
		if not (readfile and isfile and isfile(path)) then
			return false
		end

		local decoded = HttpService:JSONDecode(readfile(path))

		if decoded.Theme then
			local patch = {}
			for k, v in pairs(decoded.Theme) do
				patch[k] = Color3.new(v.R, v.G, v.B)
			end
			self:SetTheme(patch)
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

	minimize.MouseButton1Click:Connect(function()
		selfWindow:SetMinimized(not selfWindow.Minimized)
	end)

	close.MouseButton1Click:Connect(function()
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
						bind.Callback(true, bind.Key, bind.Mode)
					elseif bind.Mode == "Toggle" then
						bind.State = not bind.State
						bind.Callback(bind.State, bind.Key, bind.Mode)
					elseif bind.Mode == "Always" then
						bind.Callback(true, bind.Key, bind.Mode)
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
				if bind.Enabled and bind.Mode == "Hold" and input.KeyCode == bind.Key then
					bind.Held = false
					bind.Callback(false, bind.Key, bind.Mode)
				end
			end
		end
	end)

	return selfWindow
end

function Window:CreateTab(options)
	options = options or {}

	local tab = setmetatable({}, Tab)
	tab.Window = self
	tab.Name = options.Name or "Tab"
	tab.Icon = options.Icon
	tab.Sections = {}

	local button = Create("TextButton", {
		BackgroundColor3 = self.Theme.Sidebar,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 32),
		Text = "",
		AutoButtonColor = false,
		Parent = self.TabScroll
	})
	Round(button, 6)

	local activeBar = Create("Frame", {
		BackgroundColor3 = self.Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 4, 1, 0),
		Visible = false,
		Parent = button
	})
	Round(activeBar, 6)

	if tab.Icon then
		local icon = Create("ImageLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 14, 0.5, -9),
			Size = UDim2.new(0, 18, 0, 18),
			Image = tab.Icon,
			ImageColor3 = self.Theme.Text,
			Parent = button
		})
		tab.IconObject = icon
	else
		local box = Create("Frame", {
			BackgroundColor3 = self.Theme.Text,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 16, 0.5, -5),
			Size = UDim2.new(0, 10, 0, 10),
			Parent = button
		})
		Round(box, 4)
		tab.IconObject = box
	end

	local label = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 40, 0, 0),
		Size = UDim2.new(1, -48, 1, 0),
		Text = tab.Name,
		Parent = button
	})
	ApplyText(label, 18, self.Theme.SubText, false)

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
		Size = UDim2.new(0.5, -4, 1, -2),
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = self.Theme.Border,
		Parent = page
	})

	local right = Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 4, 0, 0),
		Size = UDim2.new(0.5, -4, 1, -2),
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = self.Theme.Border,
		Parent = page
	})

	local leftLayout = List(left, 6)
	local rightLayout = List(right, 6)
	BindCanvas(left, leftLayout, 10)
	BindCanvas(right, rightLayout, 10)

	tab.Button = button
	tab.ActiveBar = activeBar
	tab.Label = label
	tab.Page = page
	tab.Left = left
	tab.Right = right

	function tab:Select()
		for _, t in ipairs(self.Window.Tabs) do
			t.Page.Visible = false
			t.ActiveBar.Visible = false
			Tween(t.Button, TweenInfo.new(0.12), {BackgroundColor3 = self.Window.Theme.Sidebar})
			t.Label.TextColor3 = self.Window.Theme.SubText
		end

		self.Page.Visible = true
		self.ActiveBar.Visible = true
		Tween(self.Button, TweenInfo.new(0.12), {BackgroundColor3 = self.Window.Theme.Section})
		self.Label.TextColor3 = self.Window.Theme.Text
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

	local section = setmetatable({}, Section)
	section.Window = self.Window
	section.Tab = self
	section.Title = options.Name or "Section"
	section.Side = (options.Side or "Left"):lower()
	section.Elements = {}
	section.Collapsed = false

	local parentColumn = section.Side == "right" and self.Right or self.Left

	local holder = Create("Frame", {
		BackgroundColor3 = self.Window.Theme.Section,
		BorderColor3 = self.Window.Theme.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(1, 0, 0, 32),
		Parent = parentColumn,
		ClipsDescendants = true
	})
	Round(holder, 7)

	Padding(holder, 5, 5, 5, 5)
	List(holder, 4)

	local header = Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Text = "",
		AutoButtonColor = false,
		Parent = holder
	})

	local title = Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -22, 1, 0),
		Text = section.Title,
		Parent = header
	})
	ApplyText(title, 18, self.Window.Theme.Text, false)

	local arrow = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -18, 0, 0),
		Size = UDim2.new(0, 18, 1, 0),
		Text = "⌄",
		Parent = header
	})
	ApplyText(arrow, 14, self.Window.Theme.SubText, false)
	arrow.TextXAlignment = Enum.TextXAlignment.Center

	local line = Create("Frame", {
		BackgroundColor3 = self.Window.Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 2),
		Parent = holder
	})

	local content = Create("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = holder
	})
	local contentLayout = List(content, 4)

	function section:Refresh()
		local contentHeight = contentLayout.AbsoluteContentSize.Y
		local base = 5 + 18 + 4 + 2 + 5
		content.Visible = not section.Collapsed
		arrow.Text = section.Collapsed and ">" or "⌄"
		Tween(holder, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, section.Collapsed and base or (base + contentHeight))
		})
	end

	contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		section:Refresh()
	end)

	header.MouseButton1Click:Connect(function()
		section.Collapsed = not section.Collapsed
		section:Refresh()
	end)

	section.Holder = holder
	section.Content = content
	section.ContentLayout = contentLayout

	table.insert(self.Sections, section)
	section:Refresh()

	return section
end

function Section:_Push(api)
	table.insert(self.Elements, api)
	self:Refresh()
	return api
end

function Section:AddLabel(options)
	options = options or {}
	local window = self.Window

	local frame = Create("Frame", {
		BackgroundColor3 = window.Theme.Element2,
		BorderColor3 = window.Theme.BorderSoft,
		BorderSizePixel = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Parent = self.Content,
		ClipsDescendants = true
	})
	Round(frame, 6)

	local text = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 6, 0, 0),
		Size = UDim2.new(1, -12, 1, 0),
		Text = options.Text or "Label",
		Parent = frame
	})
	ApplyText(text, 17, window.Theme.Text, false)

	local api = {}
	function api:Set(v)
		text.Text = tostring(v)
	end

	return self:_Push(api)
end

function Section:AddParagraph(options)
	options = options or {}
	local window = self.Window

	local frame = Create("Frame", {
		BackgroundColor3 = window.Theme.Element2,
		BorderColor3 = window.Theme.BorderSoft,
		BorderSizePixel = 1,
		Size = UDim2.new(1, 0, 0, 38),
		Parent = self.Content,
		ClipsDescendants = true
	})
	Round(frame, 6)

	local title = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 6, 0, 2),
		Size = UDim2.new(1, -12, 0, 16),
		Text = options.Title or "Paragraph",
		Parent = frame
	})
	ApplyText(title, 17, window.Theme.Text, true)

	local body = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 6, 0, 18),
		Size = UDim2.new(1, -12, 0, 16),
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = options.Content or "",
		Parent = frame
	})
	ApplyText(body, 15, window.Theme.SubText, false)

	local function resize()
		local width = math.max(frame.AbsoluteSize.X - 12, 50)
		local bound = TextService:GetTextSize(body.Text, 15, body.Font, Vector2.new(width, 9999))
		frame.Size = UDim2.new(1, 0, 0, 22 + bound.Y + 4)
		body.Size = UDim2.new(1, -12, 0, bound.Y)
		self:Refresh()
	end

	task.defer(resize)

	local api = {}
	function api:SetTitle(v)
		title.Text = tostring(v)
		resize()
	end
	function api:SetContent(v)
		body.Text = tostring(v)
		resize()
	end

	return self:_Push(api)
end

function Section:AddButton(options)
	options = options or {}
	local window = self.Window

	local button = Create("TextButton", {
		BackgroundColor3 = window.Theme.Element2,
		BorderColor3 = window.Theme.BorderSoft,
		BorderSizePixel = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Text = "",
		AutoButtonColor = false,
		Parent = self.Content
	})
	Round(button, 6)

	local text = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 6, 0, 0),
		Size = UDim2.new(1, -12, 1, 0),
		Text = options.Text or "Button",
		Parent = button
	})
	ApplyText(text, 17, window.Theme.Text, false)

	button.MouseEnter:Connect(function()
		Tween(button, TweenInfo.new(0.1), {BackgroundColor3 = window.Theme.Element})
	end)

	button.MouseLeave:Connect(function()
		Tween(button, TweenInfo.new(0.1), {BackgroundColor3 = window.Theme.Element2})
	end)

	button.MouseButton1Click:Connect(function()
		Tween(button, TweenInfo.new(0.06), {BackgroundColor3 = window.Theme.AccentDark})
		task.delay(0.06, function()
			if button.Parent then
				Tween(button, TweenInfo.new(0.08), {BackgroundColor3 = window.Theme.Element})
				task.delay(0.08, function()
					if button.Parent then
						Tween(button, TweenInfo.new(0.08), {BackgroundColor3 = window.Theme.Element2})
					end
				end)
			end
		end)
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

	return self:_Push(api)
end

function Section:AddToggle(options)
	options = options or {}
	local window = self.Window
	local flag = options.Flag
	local state = options.Default or false

	if flag then
		window.Flags[flag] = state
	end

	local row = Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Text = "",
		AutoButtonColor = false,
		Parent = self.Content
	})

	local box = Create("Frame", {
		BackgroundColor3 = window.Theme.Element2,
		BorderColor3 = window.Theme.Border,
		BorderSizePixel = 1,
		Position = UDim2.new(0, 0, 0.5, -5),
		Size = UDim2.new(0, 10, 0, 10),
		Parent = row
	})
	Round(box, 3)

	local fill = Create("Frame", {
		BackgroundColor3 = window.Theme.Accent,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundTransparency = state and 0 or 1,
		Parent = box
	})
	Round(fill, 2)

	local text = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 0),
		Size = UDim2.new(1, -16, 1, 0),
		Text = options.Text or "Toggle",
		Parent = row
	})
	ApplyText(text, 17, window.Theme.Text, false)

	local api = {Flag = flag}
	function api:Set(v, silent)
		state = not not v
		Tween(fill, TweenInfo.new(0.1), {
			BackgroundTransparency = state and 0 or 1
		})
		if flag then
			window.Flags[flag] = state
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

	return self:_Push(api)
end

function Section:AddTextbox(options)
	options = options or {}
	local window = self.Window
	local flag = options.Flag
	local value = options.Default or ""
	local maxLength = options.MaxLength or 18

	if flag then
		window.Flags[flag] = value
	end

	local row = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Parent = self.Content
	})

	local label = Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.48, 0, 1, 0),
		Text = options.Text or "Textbox",
		Parent = row
	})
	ApplyText(label, 17, window.Theme.Text, false)

	local box = Create("TextBox", {
		BackgroundColor3 = window.Theme.Element2,
		BorderColor3 = window.Theme.BorderSoft,
		BorderSizePixel = 1,
		Position = UDim2.new(1, -86, 0, 1),
		Size = UDim2.new(0, 86, 1, -2),
		Text = value,
		PlaceholderText = options.Placeholder or "Type here...",
		ClearTextOnFocus = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ClipsDescendants = true,
		Parent = row
	})
	Round(box, 5)
	ApplyText(box, 15, window.Theme.SubText, false)

	box:GetPropertyChangedSignal("Text"):Connect(function()
		if #box.Text > maxLength then
			box.Text = string.sub(box.Text, 1, maxLength)
			box.CursorPosition = #box.Text + 1
		end
	end)

	box.Focused:Connect(function()
		Tween(box, TweenInfo.new(0.1), {BorderColor3 = window.Theme.Accent})
	end)

	local api = {Flag = flag}
	function api:Set(v, silent)
		value = tostring(v)
		if #value > maxLength then
			value = string.sub(value, 1, maxLength)
		end
		box.Text = value
		if flag then
			window.Flags[flag] = value
		end
		if not silent and options.Callback then
			options.Callback(value, false)
		end
	end
	function api:Get()
		return value
	end

	box.FocusLost:Connect(function(enterPressed)
		Tween(box, TweenInfo.new(0.1), {BorderColor3 = window.Theme.BorderSoft})
		value = box.Text
		if flag then
			window.Flags[flag] = value
		end
		if options.Callback then
			options.Callback(value, enterPressed)
		end
	end)

	return self:_Push(api)
end

function Section:AddSlider(options)
	options = options or {}
	local window = self.Window
	local min = options.Min or 0
	local max = options.Max or 100
	local decimals = options.Decimals or 0
	local value = options.Default or min
	local flag = options.Flag
	local dragging = false

	if flag then
		window.Flags[flag] = value
	end

	local row = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		Parent = self.Content
	})

	local label = Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.7, 0, 0, 14),
		Text = options.Text or "Slider",
		Parent = row
	})
	ApplyText(label, 17, window.Theme.Text, false)

	local number = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -40, 0, 0),
		Size = UDim2.new(0, 40, 0, 14),
		Text = tostring(value),
		Parent = row
	})
	ApplyText(number, 17, window.Theme.SubText, false)
	number.TextXAlignment = Enum.TextXAlignment.Right

	local bar = Create("Frame", {
		BackgroundColor3 = window.Theme.Element2,
		BorderColor3 = window.Theme.Border,
		BorderSizePixel = 1,
		Position = UDim2.new(0, 0, 0, 18),
		Size = UDim2.new(1, 0, 0, 10),
		Parent = row
	})
	Round(bar, 5)

	local fill = Create("Frame", {
		BackgroundColor3 = window.Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
		Parent = bar
	})
	Round(fill, 5)

	local knob = Create("Frame", {
		BackgroundColor3 = window.Theme.Text,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 4, 0, 4),
		Parent = fill
	})
	Round(knob, 4)

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
		Tween(fill, TweenInfo.new(dragging and 0.03 or 0.08), {
			Size = UDim2.new(pct, 0, 1, 0)
		})
		number.Text = tostring(value)

		if flag then
			window.Flags[flag] = value
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

	return self:_Push(api)
end

function Section:AddDropdown(options)
	options = options or {}
	local window = self.Window
	local flag = options.Flag
	local searchable = if options.Searchable == nil then true else options.Searchable
	local multi = options.Multi or false
	local values = options.Values or {}
	local selected = multi and (options.Default or {}) or options.Default
	local opened = false

	if flag then
		window.Flags[flag] = selected
	end

	local holder = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, searchable and 46 or 22),
		Parent = self.Content
	})

	local button = Create("TextButton", {
		BackgroundColor3 = window.Theme.Element2,
		BorderColor3 = window.Theme.BorderSoft,
		BorderSizePixel = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Text = "",
		AutoButtonColor = false,
		Parent = holder
	})
	Round(button, 6)

	local label = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 6, 0, 0),
		Size = UDim2.new(1, -22, 1, 0),
		Text = options.Text or "Dropdown",
		Parent = button
	})
	ApplyText(label, 17, window.Theme.Text, false)
	label.TextTruncate = Enum.TextTruncate.AtEnd

	local arrow = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -16, 0, 0),
		Size = UDim2.new(0, 16, 1, 0),
		Text = "^",
		Parent = button
	})
	ApplyText(arrow, 14, window.Theme.SubText, false)
	arrow.TextXAlignment = Enum.TextXAlignment.Center

	local search = Create("TextBox", {
		Visible = searchable,
		BackgroundColor3 = window.Theme.Element2,
		BorderColor3 = window.Theme.BorderSoft,
		BorderSizePixel = 1,
		Position = UDim2.new(0, 0, 0, 24),
		Size = UDim2.new(1, 0, 0, 18),
		Text = "",
		PlaceholderText = options.Placeholder or "Search...",
		ClearTextOnFocus = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = holder
	})
	Round(search, 6)
	ApplyText(search, 14, window.Theme.SubText, false)

	local dropFrame = Create("Frame", {
		BackgroundColor3 = window.Theme.Section,
		BorderColor3 = window.Theme.Border,
		BorderSizePixel = 1,
		Position = UDim2.new(0, 0, 0, searchable and 46 or 22),
		Size = UDim2.new(1, 0, 0, 0),
		Visible = false,
		ClipsDescendants = true,
		Parent = holder
	})
	Round(dropFrame, 6)

	local scroll = Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = window.Theme.Border,
		Parent = dropFrame
	})
	Padding(scroll, 2, 2, 2, 2)
	local scrollLayout = List(scroll, 2)
	BindCanvas(scroll, scrollLayout, 4)

	local buttons = {}

	local function contains(tbl, value)
		for i, v in ipairs(tbl) do
			if v == value then
				return i
			end
		end
	end

	local function updateLabel()
		if multi then
			if #selected == 0 then
				label.Text = options.Text or "Dropdown"
			else
				local out = {}
				for _, v in ipairs(selected) do
					table.insert(out, tostring(v))
				end
				label.Text = table.concat(out, ", ")
			end
		else
			label.Text = selected and tostring(selected) or (options.Text or "Dropdown")
		end
	end

	local function fire(silent)
		if flag then
			window.Flags[flag] = selected
		end
		updateLabel()
		if not silent and options.Callback then
			options.Callback(selected)
		end
	end

	local function clearItems()
		for _, obj in ipairs(buttons) do
			obj:Destroy()
		end
		buttons = {}
	end

	local function rebuild(filter)
		clearItems()
		local count = 0

		for _, item in ipairs(values) do
			local textValue = tostring(item)
			local allowed = true

			if filter and filter ~= "" then
				allowed = textValue:lower():find(filter:lower(), 1, true) ~= nil
			end

			if allowed then
				count += 1
				local itemButton = Create("TextButton", {
					BackgroundColor3 = window.Theme.Element2,
					BorderColor3 = window.Theme.BorderSoft,
					BorderSizePixel = 1,
					Size = UDim2.new(1, 0, 0, 18),
					Text = textValue,
					AutoButtonColor = false,
					Parent = scroll
				})
				Round(itemButton, 5)
				ApplyText(itemButton, 15, window.Theme.Text, false)

				itemButton.MouseEnter:Connect(function()
					Tween(itemButton, TweenInfo.new(0.08), {BackgroundColor3 = window.Theme.Element})
				end)

				itemButton.MouseLeave:Connect(function()
					Tween(itemButton, TweenInfo.new(0.08), {BackgroundColor3 = window.Theme.Element2})
				end)

				itemButton.MouseButton1Click:Connect(function()
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
					end
					rebuild(searchable and search.Text or nil)
					fire()
				end)

				table.insert(buttons, itemButton)
			end
		end

		local height = math.min(count * 20 + 4, 120)
		holder.Size = UDim2.new(1, 0, 0, (searchable and 46 or 22) + (opened and height + 4 or 0))
		dropFrame.Visible = true
		arrow.Text = opened and "⌄" or "^"
		Tween(dropFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, opened and height or 0)
		})
		task.delay(0.12, function()
			if dropFrame.Parent and not opened then
				dropFrame.Visible = false
			end
		end)
		self:Refresh()
	end

	local api = {Flag = flag}
	function api:Set(v, silent)
		selected = v
		fire(silent)
		rebuild(searchable and search.Text or nil)
	end
	function api:Get()
		return selected
	end
	function api:Refresh(newValues, keepSelection)
		values = newValues or {}
		if not keepSelection then
			selected = multi and {} or nil
		end
		rebuild(searchable and search.Text or nil)
		fire(true)
	end
	function api:Add(value)
		table.insert(values, value)
		rebuild(searchable and search.Text or nil)
	end
	function api:Remove(value)
		for i, v in ipairs(values) do
			if v == value then
				table.remove(values, i)
				break
			end
		end
		rebuild(searchable and search.Text or nil)
	end

	button.MouseButton1Click:Connect(function()
		opened = not opened
		rebuild(searchable and search.Text or nil)
	end)

	if searchable then
		search:GetPropertyChangedSignal("Text"):Connect(function()
			if opened then
				rebuild(search.Text)
			end
		end)
	end

	updateLabel()
	rebuild(nil)

	return self:_Push(api)
end

function Section:AddColorPicker(options)
	options = options or {}
	local window = self.Window
	local flag = options.Flag
	local color = options.Default or Color3.fromRGB(255, 0, 0)
	local h, s, v = color:ToHSV()
	local opened = false
	local svDrag = false
	local hueDrag = false
	local suppressCallback = false

	if flag then
		window.Flags[flag] = color
	end

	local holder = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Parent = self.Content
	})

	local button = Create("TextButton", {
		BackgroundColor3 = window.Theme.Element2,
		BorderColor3 = window.Theme.BorderSoft,
		BorderSizePixel = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Text = "",
		AutoButtonColor = false,
		Parent = holder
	})
	Round(button, 6)

	local label = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 6, 0, 0),
		Size = UDim2.new(1, -42, 1, 0),
		Text = options.Text or "ColorWheel",
		Parent = button
	})
	ApplyText(label, 17, window.Theme.Text, false)

	local preview = Create("Frame", {
		BackgroundColor3 = color,
		BorderColor3 = window.Theme.Border,
		BorderSizePixel = 1,
		Position = UDim2.new(1, -28, 0.5, -5),
		Size = UDim2.new(0, 10, 0, 10),
		Parent = button
	})
	Round(preview, 10)

	local arrow = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -16, 0, 0),
		Size = UDim2.new(0, 16, 1, 0),
		Text = "^",
		Parent = button
	})
	ApplyText(arrow, 14, window.Theme.SubText, false)
	arrow.TextXAlignment = Enum.TextXAlignment.Center

	local picker = Create("Frame", {
		BackgroundColor3 = window.Theme.Section,
		BorderColor3 = window.Theme.Border,
		BorderSizePixel = 1,
		Position = UDim2.new(0, 0, 0, 24),
		Size = UDim2.new(1, 0, 0, 0),
		Visible = false,
		ClipsDescendants = true,
		Parent = holder
	})
	Round(picker, 6)

	local sv = Create("ImageButton", {
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		BorderColor3 = window.Theme.BorderSoft,
		BorderSizePixel = 1,
		Position = UDim2.new(0, 4, 0, 4),
		Size = UDim2.new(1, -16, 0, 82),
		Image = "rbxassetid://4155801252",
		ScaleType = Enum.ScaleType.Stretch,
		AutoButtonColor = false,
		Parent = picker
	})
	Round(sv, 5)

	local svCursor = Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 6, 0, 6),
		Parent = sv
	})
	Round(svCursor, 6)

	local hue = Create("ImageButton", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderColor3 = window.Theme.BorderSoft,
		BorderSizePixel = 1,
		Position = UDim2.new(1, -10, 0, 4),
		Size = UDim2.new(0, 6, 0, 82),
		Image = "rbxassetid://3641079629",
		ScaleType = Enum.ScaleType.Stretch,
		AutoButtonColor = false,
		Parent = picker
	})
	Round(hue, 4)

	local hueCursor = Create("Frame", {
		BackgroundColor3 = window.Theme.Text,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(1, 4, 0, 2),
		Parent = hue
	})

	local rgb = Create("TextBox", {
		BackgroundColor3 = window.Theme.Element2,
		BorderColor3 = window.Theme.BorderSoft,
		BorderSizePixel = 1,
		Position = UDim2.new(0, 4, 0, 90),
		Size = UDim2.new(1, -8, 0, 18),
		Text = "",
		PlaceholderText = "255, 0, 0",
		ClearTextOnFocus = false,
		Parent = picker
	})
	Round(rgb, 5)
	ApplyText(rgb, 14, window.Theme.SubText, false)

	local function apply(silent)
		color = Color3.fromHSV(h, s, v)
		preview.BackgroundColor3 = color
		sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
		hueCursor.Position = UDim2.new(0.5, 0, h, 0)
		rgb.Text = string.format("%d, %d, %d", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
		if flag then
			window.Flags[flag] = color
		end
		if not silent and not suppressCallback and options.Callback then
			options.Callback(color)
		end
	end

	local function updateSV(pos)
		local x = Clamp((pos.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
		local y = Clamp((pos.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
		s = x
		v = 1 - y
		apply(true)
	end

	local function updateHue(pos)
		local y = Clamp((pos.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1)
		h = y
		apply(true)
	end

	sv.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			svDrag = true
			suppressCallback = true
			updateSV(input.Position)
		end
	end)

	hue.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			hueDrag = true
			suppressCallback = true
			updateHue(input.Position)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if svDrag then
				updateSV(input.Position)
			end
			if hueDrag then
				updateHue(input.Position)
			end
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local changed = svDrag or hueDrag
			svDrag = false
			hueDrag = false
			if changed then
				suppressCallback = false
				if options.Callback then
					options.Callback(color)
				end
			end
		end
	end)

	rgb.FocusLost:Connect(function()
		local r, g, b = rgb.Text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
		if r and g and b then
			r = Clamp(tonumber(r) or 0, 0, 255)
			g = Clamp(tonumber(g) or 0, 0, 255)
			b = Clamp(tonumber(b) or 0, 0, 255)
			local c = Color3.fromRGB(r, g, b)
			h, s, v = c:ToHSV()
			apply(false)
		end
	end)

	button.MouseButton1Click:Connect(function()
		opened = not opened
		picker.Visible = true
		arrow.Text = opened and "⌄" or "^"
		holder.Size = UDim2.new(1, 0, 0, opened and 136 or 22)
		Tween(picker, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, opened and 112 or 0)
		})
		task.delay(0.12, function()
			if picker.Parent and not opened then
				picker.Visible = false
			end
		end)
		self:Refresh()
	end)

	local api = {Flag = flag}
	function api:Set(c, silent)
		local hh, ss, vv = c:ToHSV()
		h, s, v = hh, ss, vv
		apply(silent)
	end
	function api:Get()
		return color
	end

	apply(true)

	return self:_Push(api)
end

function Section:AddKeybind(options)
	options = options or {}
	local window = self.Window
	local flag = options.Flag
	local key = options.Default or Enum.KeyCode.F
	local mode = options.Mode or "Toggle"
	local waiting = false

	local validModes = {
		Hold = true,
		Toggle = true,
		Always = true
	}
	if not validModes[mode] then
		mode = "Toggle"
	end

	if flag then
		window.Flags[flag] = key
	end

	local row = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Parent = self.Content
	})

	local label = Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.42, 0, 1, 0),
		Text = options.Text or "Keybind",
		Parent = row
	})
	ApplyText(label, 17, window.Theme.Text, false)

	local modeButton = Create("TextButton", {
		BackgroundColor3 = window.Theme.Element2,
		BorderColor3 = window.Theme.BorderSoft,
		BorderSizePixel = 1,
		Position = UDim2.new(1, -76, 0, 1),
		Size = UDim2.new(0, 52, 1, -2),
		Text = mode,
		AutoButtonColor = false,
		Parent = row
	})
	Round(modeButton, 5)
	ApplyText(modeButton, 13, window.Theme.SubText, false)
	modeButton.TextXAlignment = Enum.TextXAlignment.Center

	local keyButton = Create("TextButton", {
		BackgroundColor3 = window.Theme.Element2,
		BorderColor3 = window.Theme.BorderSoft,
		BorderSizePixel = 1,
		Position = UDim2.new(1, -20, 0, 1),
		Size = UDim2.new(0, 20, 1, -2),
		Text = key.Name,
		AutoButtonColor = false,
		Parent = row
	})
	Round(keyButton, 5)
	ApplyText(keyButton, 13, window.Theme.SubText, false)
	keyButton.TextXAlignment = Enum.TextXAlignment.Center

	local modes = {"Hold", "Toggle", "Always"}

	local bindData = {
		Enabled = true,
		Key = key,
		Mode = mode,
		State = false,
		Held = false,
		Callback = function(active, pressKey, bindMode)
			if options.Callback then
				options.Callback(active, pressKey, bindMode)
			end
		end
	}

	table.insert(window.Keybinds, bindData)

	local api = {Flag = flag}
	function api:Set(v, silent)
		if typeof(v) == "EnumItem" then
			key = v
			bindData.Key = key
			keyButton.Text = key.Name
			if flag then
				window.Flags[flag] = key
			end
			if not silent and options.Changed then
				options.Changed(key, mode)
			end
		elseif type(v) == "table" then
			if v.Key then
				key = v.Key
				bindData.Key = key
				keyButton.Text = key.Name
				if flag then
					window.Flags[flag] = key
				end
			end
			if v.Mode and validModes[v.Mode] then
				mode = v.Mode
				bindData.Mode = mode
				modeButton.Text = mode
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
			bindData.Mode = newMode
			modeButton.Text = newMode
			if options.Changed then
				options.Changed(key, mode)
			end
		end
	end
	function api:SetState(v)
		bindData.State = not not v
	end

	keyButton.MouseButton1Click:Connect(function()
		waiting = true
		keyButton.Text = "..."
	end)

	modeButton.MouseButton1Click:Connect(function()
		local index = table.find(modes, mode) or 1
		index += 1
		if index > #modes then
			index = 1
		end
		mode = modes[index]
		bindData.Mode = mode
		modeButton.Text = mode
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
			keyButton.Text = key.Name
			if flag then
				window.Flags[flag] = key
			end
			if options.Changed then
				options.Changed(key, mode)
			end
		end
	end)

	return self:_Push(api)
end

return Cerberus
