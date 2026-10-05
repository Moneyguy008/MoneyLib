--[[
    $ MoneyLib v1.0.0
    Sharp & flat UI library. Linoria-style API.

    local Library = loadstring(game:HttpGet("<raw url>"))()   -- or require(ModuleScript) in Studio
    local Toggles, Options = Library.Toggles, Library.Options

    local Window = Library:CreateWindow({ Title = "MoneyLib", Game = "Universal" })
    local Tab    = Window:AddTab("Combat", "sword")
    local Sub    = Tab:AddSubTab("Aim Assist")
    local Box    = Sub:AddLeftGroupbox("Main")
    Box:AddToggle("AimEnabled", { Text = "Enabled", Default = false }):AddKeyPicker("AimKey", { Default = "MB2", Mode = "Hold", Text = "Aim" })
    Toggles.AimEnabled:OnChanged(function(v) print(v) end)
    Library.SaveManager:LoadAutoloadConfig()
]]

local cloneref = (typeof(cloneref) == "function" and cloneref) or function(o) return o end
local function Service(n) return cloneref(game:GetService(n)) end

local Players          = Service("Players")
local RunService       = Service("RunService")
local UserInputService = Service("UserInputService")
local TweenService     = Service("TweenService")
local TextService      = Service("TextService")
local HttpService      = Service("HttpService")
local Stats            = Service("Stats")
local CoreGui          = Service("CoreGui")

local LocalPlayer = Players.LocalPlayer
local genv = (typeof(getgenv) == "function" and getgenv()) or nil

if genv and genv.MoneyLib and genv.MoneyLib.Unload then
    pcall(function() genv.MoneyLib:Unload() end)
end

--------------------------------------------------------------------------------
-- Library table / theme
--------------------------------------------------------------------------------
local Library = {
    Name = "MoneyLib",
    Version = "1.0.0",
    Toggles = {},
    Options = {},
    Registry = {},
    Connections = {},
    UnloadCallbacks = {},
    Popups = {},
    KeyPickers = {},
    Unloaded = false,
    Open = true,
    Folder = "MoneyLib",
    SubFolder = "Universal",
    TextSize = 13,
    Font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
    FontBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
    DefaultAccent = Color3.fromRGB(61, 214, 140),
    Theme = {
        Background  = Color3.fromRGB(11, 11, 11),
        Main        = Color3.fromRGB(16, 16, 16),
        Header      = Color3.fromRGB(13, 13, 13),
        Element     = Color3.fromRGB(21, 21, 21),
        Hover       = Color3.fromRGB(28, 28, 28),
        Outline     = Color3.fromRGB(34, 34, 34),
        OutlineDark = Color3.fromRGB(4, 4, 4),
        Text        = Color3.fromRGB(228, 228, 228),
        SubText     = Color3.fromRGB(128, 128, 128),
        Accent      = Color3.fromRGB(61, 214, 140),
        Risky       = Color3.fromRGB(235, 87, 87),
    },
    Icons = {
        settings = 10734950309, user = 10747373176, users = 10747373426, folder = 10723387563,
        eye = 10723346959, ["eye-off"] = 10723346871, keyboard = 10723416765, crosshair = 10709818534,
        sword = 10734975486, home = 10723407389, search = 10734943674, ["chevron-down"] = 10709790948,
        gamepad = 10723395457, palette = 10734910430, x = 10747384394, check = 10709790644,
        shield = 10734951847, target = 10734977012, box = 10709782497, layers = 10723424505,
    },
    Statuses = { "Neutral", "Friendly", "Priority" },
    PlayerStatus = {},
}
local Toggles, Options, Theme = Library.Toggles, Library.Options, Library.Theme

local function Icon(name)
    if name == nil then return "" end
    if typeof(name) == "number" then return "rbxassetid://" .. name end
    if Library.Icons[name] then return "rbxassetid://" .. Library.Icons[name] end
    if tostring(name):match("^%d+$") then return "rbxassetid://" .. name end
    return tostring(name)
end
Library.GetIcon = Icon

--------------------------------------------------------------------------------
-- Utility
--------------------------------------------------------------------------------
local function Connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Library.Connections, c)
    return c
end
Library.Connect = function(_, s, f) return Connect(s, f) end

local function Resolve(v)
    if typeof(v) == "string" and Theme[v] then return Theme[v] end
    if typeof(v) == "function" then return v() end
    return v
end

-- New(class, props) ; color props may be theme keys ("Accent") or functions -> registered for live recolor
local ColorProps = { BackgroundColor3 = true, TextColor3 = true, ImageColor3 = true, Color = true, BorderColor3 = true, PlaceholderColor3 = true, ScrollBarImageColor3 = true }
local function New(class, props)
    local inst = Instance.new(class)
    local themed
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            if ColorProps[k] and (typeof(v) == "string" or typeof(v) == "function") then
                themed = themed or {}
                themed[k] = v
                inst[k] = Resolve(v)
            else
                inst[k] = v
            end
        end
    end
    if class:find("Text") then
        if props.FontFace == nil then inst.FontFace = Library.Font end
        if props.TextSize == nil then inst.TextSize = Library.TextSize end
        if props.BackgroundTransparency == nil and class ~= "TextBox" and class ~= "TextButton" then inst.BackgroundTransparency = 1 end
    end
    if (class == "Frame" or class == "TextButton" or class == "ImageLabel" or class == "ImageButton" or class == "ScrollingFrame" or class == "TextLabel" or class == "TextBox" or class == "ViewportFrame") and props.BorderSizePixel == nil then
        inst.BorderSizePixel = 0
    end
    if class == "TextButton" or class == "ImageButton" then inst.AutoButtonColor = props.AutoButtonColor or false end
    if themed then
        table.insert(Library.Registry, { Instance = inst, Props = themed })
    end
    if props.Parent then inst.Parent = props.Parent end
    return inst
end
Library.Create = function(_, c, p) return New(c, p) end

local function Stroke(parent, color, thickness)
    return New("UIStroke", { Parent = parent, Color = color or "Outline", Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter })
end

local function Padding(parent, t, r, b, l)
    return New("UIPadding", { Parent = parent, PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r or t), PaddingBottom = UDim.new(0, b or t), PaddingLeft = UDim.new(0, l or r or t) })
end

local function List(parent, pad, dir, halign, valign)
    return New("UIListLayout", { Parent = parent, Padding = UDim.new(0, pad or 0), FillDirection = dir or Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = halign or Enum.HorizontalAlignment.Left, VerticalAlignment = valign or Enum.VerticalAlignment.Top })
end

local function Tween(inst, t, props, style)
    local tw = TweenService:Create(inst, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function TextWidth(text, size, font)
    local params = Instance.new("GetTextBoundsParams")
    params.Text = tostring(text)
    params.Size = size or Library.TextSize
    params.Font = font or Library.Font
    params.Width = 10000
    local ok, v = pcall(TextService.GetTextBoundsAsync, TextService, params)
    if ok then return v.X end
    return #tostring(text) * (size or Library.TextSize) * 0.55
end

local function Round(n, dec)
    local m = 10 ^ (dec or 0)
    return math.floor(n * m + 0.5) / m
end

local function ToHex(c)
    return string.format("%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function FromHex(s)
    s = tostring(s):gsub("#", "")
    if #s ~= 6 then return nil end
    local ok, c = pcall(Color3.fromHex, s)
    return ok and c or nil
end

local function SafeCall(fn, ...)
    if typeof(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then warn("[MoneyLib] callback error: " .. tostring(err)) end
end

local function MouseIn(gui, pad)
    if not gui or not gui.Parent or not gui.Visible then return false end
    pad = pad or 0
    local m = UserInputService:GetMouseLocation()
    local p, s = gui.AbsolutePosition, gui.AbsoluteSize
    return m.X >= p.X - pad and m.X <= p.X + s.X + pad and m.Y >= p.Y - pad and m.Y <= p.Y + s.Y + pad
end

local function IsVisibleDeep(gui)
    while gui and gui:IsA("GuiObject") do
        if not gui.Visible then return false end
        gui = gui.Parent
    end
    return gui ~= nil
end

function Library:UpdateColors()
    for i = #self.Registry, 1, -1 do
        local e = self.Registry[i]
        if e.Instance.Parent == nil and not e.Keep then
            table.remove(self.Registry, i)
        else
            for prop, v in pairs(e.Props) do
                e.Instance[prop] = Resolve(v)
            end
        end
    end
end

function Library:SetAccent(color)
    Theme.Accent = color
    self:UpdateColors()
    -- re-apply state-dependent colors
    for _, o in pairs(self.Toggles) do if o.Display then o:Display() end end
    for _, o in pairs(self.Options) do if o.Display then o:Display() end end
    local W = self.Window
    if W and W.ActiveTab then
        W.ActiveTab:Show()
        if W.ActiveTab.ActiveSub then W.ActiveTab.ActiveSub:Show() end
    end
    if self._UpdateKeybindList then self:_UpdateKeybindList() end
end

--------------------------------------------------------------------------------
-- Filesystem (executor workspace folder, memory fallback in Studio)
--------------------------------------------------------------------------------
local FS = {}
FS.Native = typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
    and typeof(isfolder) == "function" and typeof(makefolder) == "function" and typeof(listfiles) == "function"
FS.Memory = {}

function FS.Normalize(p) return (tostring(p):gsub("\\", "/")) end
function FS.MakeFolder(path)
    local built = ""
    for part in FS.Normalize(path):gmatch("[^/]+") do
        built = built == "" and part or (built .. "/" .. part)
        if FS.Native then
            if not isfolder(built) then makefolder(built) end
        end
    end
end
function FS.Write(path, data)
    if FS.Native then
        local ok, err = pcall(writefile, path, data)
        return ok, err
    end
    FS.Memory[path] = data
    return true
end
function FS.Read(path)
    if FS.Native then
        if not isfile(path) then return nil end
        local ok, d = pcall(readfile, path)
        return ok and d or nil
    end
    return FS.Memory[path]
end
function FS.Exists(path)
    if FS.Native then return isfile(path) end
    return FS.Memory[path] ~= nil
end
function FS.Delete(path)
    if FS.Native then
        if typeof(delfile) == "function" and isfile(path) then pcall(delfile, path) end
        return
    end
    FS.Memory[path] = nil
end
function FS.List(folder, ext)
    local out = {}
    folder = FS.Normalize(folder)
    local files = {}
    if FS.Native then
        if isfolder(folder) then
            local ok, l = pcall(listfiles, folder)
            if ok then files = l end
        end
    else
        for p in pairs(FS.Memory) do
            if p:sub(1, #folder + 1) == folder .. "/" then table.insert(files, p) end
        end
    end
    for _, f in ipairs(files) do
        local name = FS.Normalize(f):match("([^/]+)$")
        if name and (not ext or name:sub(-#ext) == ext) then
            table.insert(out, ext and name:sub(1, -#ext - 1) or name)
        end
    end
    table.sort(out)
    return out
end
Library.FS = FS

--------------------------------------------------------------------------------
-- ScreenGui
--------------------------------------------------------------------------------
local ScreenGui = New("ScreenGui", {
    Name = HttpService:GenerateGUID(false):sub(1, 8),
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
})
do
    local parented = false
    if typeof(gethui) == "function" then
        parented = pcall(function() ScreenGui.Parent = gethui() end)
    end
    if not parented then
        if typeof(protectgui) == "function" then pcall(protectgui, ScreenGui)
        elseif typeof(syn) == "table" and syn.protect_gui then pcall(syn.protect_gui, ScreenGui) end
        parented = pcall(function() ScreenGui.Parent = CoreGui end) and ScreenGui.Parent == CoreGui
    end
    if not parented then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end
Library.ScreenGui = ScreenGui

-- Layers: windows < overlay (popups/tooltip/notifications)
local WindowLayer = New("Frame", { Parent = ScreenGui, Name = "Windows", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 1 })
local HudLayer    = New("Frame", { Parent = ScreenGui, Name = "Hud", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2 })
local PopupLayer  = New("Frame", { Parent = ScreenGui, Name = "Popups", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3 })
local TopLayer    = New("Frame", { Parent = ScreenGui, Name = "Top", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 4 })

-- unlocks the mouse in first-person games while the menu is open
local ModalButton = New("TextButton", { Parent = WindowLayer, Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, Text = "", Modal = true })

--------------------------------------------------------------------------------
-- Dragging / focus
--------------------------------------------------------------------------------
local ZCounter = 1
local function BringToFront(frame)
    ZCounter += 1
    frame.ZIndex = ZCounter
end

local function ClampToScreen(frame)
    local vp = ScreenGui.AbsoluteSize
    local s = frame.AbsoluteSize
    local x = math.clamp(frame.Position.X.Offset, 0, math.max(0, vp.X - s.X))
    local y = math.clamp(frame.Position.Y.Offset, 0, math.max(0, vp.Y - s.Y))
    frame.Position = UDim2.fromOffset(x, y)
end

local function MakeDraggable(frame, handle)
    local dragging, startMouse, startPos
    Connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            BringToFront(frame)
            dragging = true
            startMouse = UserInputService:GetMouseLocation()
            startPos = frame.AbsolutePosition
        end
    end)
    Connect(UserInputService.InputChanged, function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = UserInputService:GetMouseLocation() - startMouse
            local anchorOff = frame.AnchorPoint * frame.AbsoluteSize
            frame.Position = UDim2.fromOffset(startPos.X + d.X + anchorOff.X, startPos.Y + d.Y + anchorOff.Y)
        end
    end)
    Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

--------------------------------------------------------------------------------
-- Tooltip
--------------------------------------------------------------------------------
local Tooltip = New("TextLabel", {
    Parent = TopLayer, Visible = false, BackgroundColor3 = "Background", BackgroundTransparency = 0,
    TextColor3 = "Text", TextSize = 12, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0),
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 50,
})
Padding(Tooltip, 4, 6)
Stroke(Tooltip, "Outline")
local TooltipOwner
local function AddTooltip(gui, text)
    if not text or text == "" then return end
    Connect(gui.MouseEnter, function()
        TooltipOwner = gui
        Tooltip.Text = text
        Tooltip.Visible = true
    end)
    Connect(gui.MouseLeave, function()
        if TooltipOwner == gui then TooltipOwner = nil; Tooltip.Visible = false end
    end)
end
Connect(RunService.RenderStepped, function()
    if Tooltip.Visible then
        if not TooltipOwner or not IsVisibleDeep(TooltipOwner) then Tooltip.Visible = false return end
        local m = UserInputService:GetMouseLocation()
        Tooltip.Position = UDim2.fromOffset(m.X + 14, m.Y + 8)
    end
end)

--------------------------------------------------------------------------------
-- Popups (dropdown lists, color pickers, keybind menus, settings panels)
--------------------------------------------------------------------------------
function Library:OpenPopup(frame, anchor, opts)
    opts = opts or {}
    -- close siblings that are not ancestors of this popup's anchor
    for i = #self.Popups, 1, -1 do
        local p = self.Popups[i]
        if not anchor:IsDescendantOf(p.Frame) then self:ClosePopup(p.Frame) end
    end
    frame.Parent = PopupLayer
    frame.Visible = true
    ZCounter += 1
    frame.ZIndex = ZCounter
    table.insert(self.Popups, { Frame = frame, Anchor = anchor, OnClose = opts.OnClose, Side = opts.Side, Offset = opts.Offset or Vector2.zero, MatchWidth = opts.MatchWidth })
end

function Library:ClosePopup(frame)
    for i = #self.Popups, 1, -1 do
        local p = self.Popups[i]
        if p.Frame == frame then
            table.remove(self.Popups, i)
            -- close children popups opened from inside this one
            for j = #self.Popups, 1, -1 do
                local c = self.Popups[j]
                if c and c.Anchor:IsDescendantOf(frame) then self:ClosePopup(c.Frame) end
            end
            frame.Visible = false
            SafeCall(p.OnClose)
            return
        end
    end
end

function Library:IsPopupOpen(frame)
    for _, p in ipairs(self.Popups) do if p.Frame == frame then return true end end
    return false
end

function Library:TogglePopup(frame, anchor, opts)
    if self:IsPopupOpen(frame) then self:ClosePopup(frame) else self:OpenPopup(frame, anchor, opts) end
end

Connect(RunService.RenderStepped, function()
    local vp = ScreenGui.AbsoluteSize
    for i = #Library.Popups, 1, -1 do
        local p = Library.Popups[i]
        if p and p.Frame then
            if not IsVisibleDeep(p.Anchor) then
                Library:ClosePopup(p.Frame)
            else
                local ap, as = p.Anchor.AbsolutePosition, p.Anchor.AbsoluteSize
                if p.MatchWidth then p.Frame.Size = UDim2.fromOffset(as.X, p.Frame.Size.Y.Offset) end
                local fs = p.Frame.AbsoluteSize
                local x, y
                if p.Side == "Right" then
                    x, y = ap.X + as.X + 6, ap.Y
                else
                    x, y = ap.X, ap.Y + as.Y + 2
                end
                x += p.Offset.X; y += p.Offset.Y
                if y + fs.Y > vp.Y - 4 then y = math.max(4, ap.Y - fs.Y - 2) end
                if x + fs.X > vp.X - 4 then x = math.max(4, vp.X - fs.X - 4) end
                p.Frame.Position = UDim2.fromOffset(x, y)
            end
        end
    end
end)

Connect(UserInputService.InputBegan, function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
    for i = #Library.Popups, 1, -1 do
        local p = Library.Popups[i]
        if not p then continue end
        if MouseIn(p.Frame) or MouseIn(p.Anchor) then break end
        Library:ClosePopup(p.Frame)
    end
end)

local function PopupFrame(width, height)
    local f = New("Frame", { Visible = false, BackgroundColor3 = "Background", Size = UDim2.fromOffset(width, height or 0), AutomaticSize = height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y })
    Stroke(f, "Outline")
    return f
end

--------------------------------------------------------------------------------
-- Notifications
--------------------------------------------------------------------------------
local NotifyHolder = New("Frame", { Parent = TopLayer, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(280, 400), BackgroundTransparency = 1 })
List(NotifyHolder, 6, nil, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)

function Library:Notify(info, duration)
    if typeof(info) ~= "table" then info = { Description = tostring(info), Time = duration } end
    local time = info.Time or duration or 4
    local holder = New("Frame", { Parent = NotifyHolder, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
    local card = New("Frame", { Parent = holder, BackgroundColor3 = "Background", AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.fromOffset(272, 0), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 320, 0, 0) })
    Stroke(card, "Outline")
    New("Frame", { Parent = card, BackgroundColor3 = "Accent", Size = UDim2.new(0, 2, 1, 0) })
    local inner = New("Frame", { Parent = card, BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0) })
    Padding(inner, 7, 10, 9, 12)
    List(inner, 2)
    if info.Title then
        New("TextLabel", { Parent = inner, Text = info.Title, TextColor3 = "Text", FontFace = Library.FontBold, Size = UDim2.fromOffset(250, 16), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 })
    end
    New("TextLabel", { Parent = inner, Text = info.Description or info.Text or "", TextColor3 = info.Title and "SubText" or "Text", TextSize = 12, AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, Size = UDim2.fromOffset(250, 0), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2 })
    local bar = New("Frame", { Parent = card, BackgroundColor3 = "Accent", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1) })
    task.spawn(function()
        Tween(card, 0.25, { Position = UDim2.new(1, 0, 0, 0) })
        Tween(bar, time, { Size = UDim2.new(0, 0, 0, 1) }, Enum.EasingStyle.Linear)
        task.wait(time)
        Tween(card, 0.25, { Position = UDim2.new(1, 320, 0, 0) })
        task.wait(0.25)
        holder:Destroy()
    end)
end

--------------------------------------------------------------------------------
-- Key helpers
--------------------------------------------------------------------------------
local MouseKeys = { MB1 = Enum.UserInputType.MouseButton1, MB2 = Enum.UserInputType.MouseButton2, MB3 = Enum.UserInputType.MouseButton3 }
local ShortNames = { LeftShift = "LShift", RightShift = "RShift", LeftControl = "LCtrl", RightControl = "RCtrl", LeftAlt = "LAlt", RightAlt = "RAlt", Backspace = "Back", Return = "Enter", CapsLock = "Caps", Insert = "Ins", Delete = "Del", PageUp = "PgUp", PageDown = "PgDn" }
local function InputToKey(input)
    for name, t in pairs(MouseKeys) do if input.UserInputType == t then return name end end
    if input.UserInputType == Enum.UserInputType.Keyboard then return input.KeyCode.Name end
    return nil
end
local function KeyDisplay(key)
    if not key or key == "None" then return "None" end
    return ShortNames[key] or key
end
local function KeyMatches(input, key)
    if not key or key == "None" then return false end
    if MouseKeys[key] then return input.UserInputType == MouseKeys[key] end
    return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == key
end

--------------------------------------------------------------------------------
-- Base element mixin
--------------------------------------------------------------------------------
local function MakeSignalHolder(obj)
    obj.Changed = {}
    function obj:OnChanged(fn) table.insert(self.Changed, fn); SafeCall(fn, self.Value); return self end
    function obj:_Fire(...)
        SafeCall(self.Callback, ...)
        for _, fn in ipairs(self.Changed) do SafeCall(fn, ...) end
    end
    function obj:SetVisible(v)
        self.Visible = v
        if self.Holder then self.Holder.Visible = v end
        if self.Groupbox then self.Groupbox:_Refilter() end
    end
end

--------------------------------------------------------------------------------
-- Groupbox
--------------------------------------------------------------------------------
local Groupbox = {}
Groupbox.__index = Groupbox

local function NewGroupbox(parent, title, opts)
    opts = opts or {}
    local self = setmetatable({}, Groupbox)
    self.Order = 0
    self.Entries = {}
    self.Root = self

    local frame = New("Frame", { Parent = parent, BackgroundColor3 = "Main", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = opts.LayoutOrder or 0 })
    Stroke(frame, "Outline")
    List(frame, 0)
    if title then
        local header = New("Frame", { Parent = frame, BackgroundColor3 = "Header", Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 0 })
        New("Frame", { Parent = header, BackgroundColor3 = "Outline", Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1) })
        New("TextLabel", { Parent = header, Text = title, TextColor3 = "Text", Position = UDim2.fromOffset(7, 0), Size = UDim2.new(1, -14, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
        self.Header = header
    end
    local container = New("Frame", { Parent = frame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1 })
    Padding(container, 6, 7, 7, 7)
    List(container, 5)
    self.Frame = frame
    self.Container = container
    self.Title = title or ""
    return self
end

function Groupbox:_Row(height, elem, searchText)
    self.Order += 1
    local row = New("Frame", { Parent = self.Container, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height or 16), LayoutOrder = self.Order })
    if elem then
        elem.Holder = row
        elem.Groupbox = self.Root
        elem.Visible = true
        table.insert(self.Root.Entries, { Row = row, Text = (searchText or ""):lower(), Elem = elem })
    end
    return row
end

function Groupbox:_Refilter()
    local q = self.Query or ""
    local any = q == "" or self.Title:lower():find(q, 1, true) ~= nil
    for _, e in ipairs(self.Entries) do
        local match = q == "" or e.Text:find(q, 1, true) ~= nil or self.Title:lower():find(q, 1, true) ~= nil
        e.Row.Visible = (e.Elem.Visible ~= false) and match
        if match then any = true end
    end
    self.Frame.Visible = any
end

function Groupbox:Resize() end -- Linoria compat (sizes are automatic)

-- Addon holder on the right of a row (keybinds, colorpickers, settings gear)
local function AddonHolder(row)
    local h = row:FindFirstChild("Addons")
    if h then return h end
    h = New("Frame", { Parent = row, Name = "Addons", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X })
    List(h, 5, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
    return h
end

---------------------------------------------------------------- KeyPicker
local function CreateKeyPicker(parentObj, row, idx, info)
    info = info or {}
    local KP = { Type = "KeyPicker", Value = info.Default or "None", Mode = info.Mode or "Toggle", Text = info.Text or idx, Toggled = false, Callback = info.Callback, ChangedCallback = info.ChangedCallback, NoUI = info.NoUI, Clicked = {} }
    MakeSignalHolder(KP)
    KP.Value = KP.Value or "None"

    local holder = AddonHolder(row)
    local chip = New("TextButton", { Parent = holder, BackgroundColor3 = "Element", Size = UDim2.fromOffset(0, 16), AutomaticSize = Enum.AutomaticSize.X, Text = "", LayoutOrder = 1 })
    Stroke(chip, "Outline")
    Padding(chip, 0, 5)
    List(chip, 4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    New("ImageLabel", { Parent = chip, BackgroundTransparency = 1, Image = Icon("keyboard"), ImageColor3 = "SubText", Size = UDim2.fromOffset(11, 11), LayoutOrder = 1 })
    local label = New("TextLabel", { Parent = chip, Text = KeyDisplay(KP.Value), TextColor3 = "SubText", TextSize = 12, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 16), LayoutOrder = 2 })

    -- mode menu (right click)
    local modeMenu = PopupFrame(80)
    Padding(modeMenu, 3)
    List(modeMenu, 0)
    local modeButtons = {}
    for i, mode in ipairs({ "Always", "Toggle", "Hold" }) do
        local b = New("TextButton", { Parent = modeMenu, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Text = mode, TextColor3 = function() return KP.Mode == mode and Theme.Accent or Theme.SubText end, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = i })
        Padding(b, 0, 5)
        modeButtons[mode] = b
        Connect(b.MouseButton1Click, function()
            KP.Mode = mode
            KP:_Update()
            Library:ClosePopup(modeMenu)
        end)
    end

    function KP:_Update()
        label.Text = self.Picking and "..." or KeyDisplay(self.Value)
        label.TextColor3 = self.Picking and Theme.Accent or (self:GetState() and Theme.Text or Theme.SubText)
        for mode, b in pairs(modeButtons) do b.TextColor3 = (self.Mode == mode) and Theme.Accent or Theme.SubText end
        Library:_UpdateKeybindList()
    end
    table.insert(Library.Registry, { Instance = label, Props = { TextColor3 = function() return KP.Picking and Theme.Accent or (KP:GetState() and Theme.Text or Theme.SubText) end } })

    function KP:GetState()
        if self.Mode == "Always" then return true end
        if self.Mode == "Hold" then
            if self.Value == "None" then return false end
            if MouseKeys[self.Value] then return UserInputService:IsMouseButtonPressed(MouseKeys[self.Value]) end
            local ok, kc = pcall(function() return Enum.KeyCode[self.Value] end)
            return ok and kc and UserInputService:IsKeyDown(kc) or false
        end
        return self.Toggled
    end
    function KP:SetValue(data)
        local key, mode = data, nil
        if typeof(data) == "table" then key, mode = data[1], data[2] end
        self.Value = key or "None"
        if mode then self.Mode = mode end
        self:_Update()
        SafeCall(self.ChangedCallback, self.Value)
        for _, fn in ipairs(self.Changed) do SafeCall(fn, self.Value) end
    end
    function KP:OnClick(fn) table.insert(self.Clicked, fn) end
    function KP:DoClick()
        if parentObj and parentObj.Type == "Toggle" and info.SyncToggleState then
            parentObj:SetValue(not parentObj.Value)
        end
        SafeCall(self.Callback, self:GetState())
        for _, fn in ipairs(self.Clicked) do SafeCall(fn, self:GetState()) end
    end

    Connect(chip.MouseButton1Click, function()
        if KP.Picking then return end
        KP.Picking = true
        KP:_Update()
        task.wait(0.1)
        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            local key
            if input.UserInputType == Enum.UserInputType.Keyboard then
                key = (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace) and "None" or input.KeyCode.Name
            else
                key = InputToKey(input)
            end
            if key then
                conn:Disconnect()
                task.defer(function()
                    KP.Picking = false
                    KP:SetValue(key)
                end)
            end
        end)
    end)
    Connect(chip.MouseButton2Click, function() Library:TogglePopup(modeMenu, chip) end)

    if parentObj and parentObj.Type == "Toggle" and info.SyncToggleState then
        KP.Toggled = parentObj.Value
        parentObj:OnChanged(function(v) KP.Toggled = v; KP:_Update() end)
    end

    if info.NoUIChip then chip.Visible = false end
    KP:_Update()
    Options[idx] = KP
    table.insert(Library.KeyPickers, KP)
    return KP
end

Connect(UserInputService.InputBegan, function(input, gpe)
    if UserInputService:GetFocusedTextBox() then return end
    for _, kp in ipairs(Library.KeyPickers) do
        if not kp.Picking and KeyMatches(input, kp.Value) then
            if kp.Mode == "Toggle" then kp.Toggled = not kp.Toggled end
            kp:DoClick()
            kp:_Update()
        end
    end
end)
Connect(UserInputService.InputEnded, function(input)
    for _, kp in ipairs(Library.KeyPickers) do
        if kp.Mode == "Hold" and KeyMatches(input, kp.Value) then
            SafeCall(kp.Callback, false)
            kp:_Update()
        end
    end
end)

---------------------------------------------------------------- ColorPicker
local function CreateColorPicker(row, idx, info)
    info = info or {}
    local CP = { Type = "ColorPicker", Value = info.Default or Color3.new(1, 1, 1), Transparency = info.Transparency or 0, Callback = info.Callback, Title = info.Title or idx }
    MakeSignalHolder(CP)
    local h, s, v = CP.Value:ToHSV()
    CP.Hue, CP.Sat, CP.Vib = h, s, v

    local holder = AddonHolder(row)
    local swatch = New("TextButton", { Parent = holder, BackgroundColor3 = CP.Value, Size = UDim2.fromOffset(22, 12), Text = "", LayoutOrder = 2 })
    Stroke(swatch, "OutlineDark")

    local useAlpha = info.Transparency ~= nil
    local pop = PopupFrame(212)
    Padding(pop, 7)
    List(pop, 6)
    New("TextLabel", { Parent = pop, Text = CP.Title, TextColor3 = "Text", Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0 })

    local pickArea = New("Frame", { Parent = pop, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 160), LayoutOrder = 1 })
    local sv = New("TextButton", { Parent = pickArea, Text = "", BackgroundColor3 = Color3.fromHSV(CP.Hue, 1, 1), Size = UDim2.fromOffset(160, 160) })
    Stroke(sv, "OutlineDark")
    local white = New("Frame", { Parent = sv, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1) })
    New("UIGradient", { Parent = white, Transparency = NumberSequence.new(0, 1) })
    local black = New("Frame", { Parent = sv, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0) })
    New("UIGradient", { Parent = black, Rotation = 90, Transparency = NumberSequence.new(1, 0) })
    local cursor = New("Frame", { Parent = sv, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3 })
    Stroke(cursor, "OutlineDark")

    local hueBar = New("TextButton", { Parent = pickArea, Text = "", Position = UDim2.fromOffset(168, 0), Size = UDim2.fromOffset(12, 160), BackgroundColor3 = Color3.new(1, 1, 1) })
    Stroke(hueBar, "OutlineDark")
    local hueKeys = {}
    for i = 0, 6 do table.insert(hueKeys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1))) end
    New("UIGradient", { Parent = hueBar, Rotation = 90, Color = ColorSequence.new(hueKeys) })
    local hueCursor = New("Frame", { Parent = hueBar, AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1) })
    Stroke(hueCursor, "OutlineDark")

    local alphaBar, alphaCursor, alphaGrad
    if useAlpha then
        alphaBar = New("TextButton", { Parent = pickArea, Text = "", Position = UDim2.fromOffset(186, 0), Size = UDim2.fromOffset(12, 160), BackgroundColor3 = CP.Value })
        Stroke(alphaBar, "OutlineDark")
        alphaGrad = New("UIGradient", { Parent = alphaBar, Rotation = 90, Transparency = NumberSequence.new(0, 1) })
        alphaCursor = New("Frame", { Parent = alphaBar, AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1) })
        Stroke(alphaCursor, "OutlineDark")
    end

    local inputRow = New("Frame", { Parent = pop, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 2 })
    local hexBox = New("TextBox", { Parent = inputRow, BackgroundColor3 = "Element", Size = UDim2.new(0.5, -3, 1, 0), Text = "#" .. ToHex(CP.Value), TextColor3 = "Text", TextSize = 12, ClearTextOnFocus = false })
    Stroke(hexBox, "Outline")
    local rgbBox = New("TextBox", { Parent = inputRow, BackgroundColor3 = "Element", Position = UDim2.new(0.5, 3, 0, 0), Size = UDim2.new(0.5, -3, 1, 0), Text = "", TextColor3 = "Text", TextSize = 12, ClearTextOnFocus = false })
    Stroke(rgbBox, "Outline")

    local btnRow = New("Frame", { Parent = pop, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 3 })
    local copyB = New("TextButton", { Parent = btnRow, BackgroundColor3 = "Element", Size = UDim2.new(0.5, -3, 1, 0), Text = "Copy", TextColor3 = "SubText", TextSize = 12 })
    Stroke(copyB, "Outline")
    local pasteB = New("TextButton", { Parent = btnRow, BackgroundColor3 = "Element", Position = UDim2.new(0.5, 3, 0, 0), Size = UDim2.new(0.5, -3, 1, 0), Text = "Paste", TextColor3 = "SubText", TextSize = 12 })
    Stroke(pasteB, "Outline")

    function CP:Display()
        self.Value = Color3.fromHSV(self.Hue, self.Sat, self.Vib)
        swatch.BackgroundColor3 = self.Value
        swatch.BackgroundTransparency = self.Transparency
        sv.BackgroundColor3 = Color3.fromHSV(self.Hue, 1, 1)
        cursor.Position = UDim2.fromScale(self.Sat, 1 - self.Vib)
        hueCursor.Position = UDim2.fromScale(0, self.Hue)
        if alphaBar then
            alphaBar.BackgroundColor3 = self.Value
            alphaCursor.Position = UDim2.fromScale(0, self.Transparency)
        end
        if not hexBox:IsFocused() then hexBox.Text = "#" .. ToHex(self.Value) end
        if not rgbBox:IsFocused() then
            rgbBox.Text = string.format("%d, %d, %d", math.floor(self.Value.R * 255 + 0.5), math.floor(self.Value.G * 255 + 0.5), math.floor(self.Value.B * 255 + 0.5))
        end
    end
    function CP:SetHSVFromRGB(c)
        self.Hue, self.Sat, self.Vib = c:ToHSV()
    end
    function CP:SetValueRGB(c, transparency)
        self:SetHSVFromRGB(c)
        if transparency then self.Transparency = transparency end
        self:Display()
        self:_Fire(self.Value, self.Transparency)
    end
    function CP:SetValue(hsv, transparency)
        if typeof(hsv) == "Color3" then return self:SetValueRGB(hsv, transparency) end
        self.Hue, self.Sat, self.Vib = hsv[1], hsv[2], hsv[3]
        if transparency then self.Transparency = transparency end
        self:Display()
        self:_Fire(self.Value, self.Transparency)
    end

    local dragging
    local function update()
        local m = UserInputService:GetMouseLocation()
        if dragging == "sv" then
            CP.Sat = math.clamp((m.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
            CP.Vib = 1 - math.clamp((m.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
        elseif dragging == "hue" then
            CP.Hue = math.clamp((m.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
        elseif dragging == "alpha" then
            CP.Transparency = math.clamp((m.Y - alphaBar.AbsolutePosition.Y) / alphaBar.AbsoluteSize.Y, 0, 1)
        end
        CP:Display()
        CP:_Fire(CP.Value, CP.Transparency)
    end
    Connect(sv.MouseButton1Down, function() dragging = "sv"; update() end)
    Connect(hueBar.MouseButton1Down, function() dragging = "hue"; update() end)
    if alphaBar then Connect(alphaBar.MouseButton1Down, function() dragging = "alpha"; update() end) end
    Connect(UserInputService.InputChanged, function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update() end end)
    Connect(UserInputService.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = nil end end)

    Connect(hexBox.FocusLost, function()
        local c = FromHex(hexBox.Text)
        if c then CP:SetValueRGB(c) else CP:Display() end
    end)
    Connect(rgbBox.FocusLost, function()
        local r, g, b = rgbBox.Text:match("(%d+)%D+(%d+)%D+(%d+)")
        if r then CP:SetValueRGB(Color3.fromRGB(math.clamp(tonumber(r), 0, 255), math.clamp(tonumber(g), 0, 255), math.clamp(tonumber(b), 0, 255))) else CP:Display() end
    end)
    Connect(copyB.MouseButton1Click, function()
        Library.ColorClipboard = { CP.Value, CP.Transparency }
        if typeof(setclipboard) == "function" then pcall(setclipboard, "#" .. ToHex(CP.Value)) end
    end)
    Connect(pasteB.MouseButton1Click, function()
        if Library.ColorClipboard then CP:SetValueRGB(Library.ColorClipboard[1], useAlpha and Library.ColorClipboard[2] or nil) end
    end)
    Connect(swatch.MouseButton1Click, function() Library:TogglePopup(pop, swatch, { Side = "Right" }) end)

    CP:Display()
    Options[idx] = CP
    return CP
end

---------------------------------------------------------------- Toggle
local ToggleMethods = {}
function Groupbox:AddToggle(idx, info)
    info = info or {}
    local T = { Type = "Toggle", Value = info.Default == true, Text = info.Text or idx, Callback = info.Callback, Risky = info.Risky, Disabled = info.Disabled }
    MakeSignalHolder(T)
    local row = self:_Row(16, T, T.Text)
    local btn = New("TextButton", { Parent = row, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "" })
    local box = New("Frame", { Parent = btn, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = function() return T.Value and Theme.Accent or Theme.Element end })
    local boxStroke = Stroke(box, function() return T.Value and Theme.Accent or Theme.Outline end)
    local label = New("TextLabel", { Parent = btn, Text = T.Text, Position = UDim2.fromOffset(19, 0), Size = UDim2.new(1, -19, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = function()
            if T.Risky then return Theme.Risky end
            return T.Value and Theme.Text or Theme.SubText
        end })
    T.Label = label

    function T:Display()
        local on = self.Value
        Tween(box, 0.12, { BackgroundColor3 = on and Theme.Accent or Theme.Element })
        boxStroke.Color = on and Theme.Accent or Theme.Outline
        label.TextColor3 = self.Risky and Theme.Risky or (on and Theme.Text or Theme.SubText)
    end
    function T:SetValue(v)
        v = v == true
        if self.Value == v then return end
        self.Value = v
        self:Display()
        self:_Fire(v)
        Library:_UpdateKeybindList()
    end
    function T:SetText(t) self.Text = t; label.Text = t end
    function T:SetDisabled(d) self.Disabled = d; btn.Active = not d; label.TextTransparency = d and 0.5 or 0 end
    function T:AddKeyPicker(i, inf) CreateKeyPicker(self, row, i, inf); return self end
    function T:AddColorPicker(i, inf) CreateColorPicker(row, i, inf); return self end
    function T:AddSettings(title)
        local gear = New("ImageButton", { Parent = AddonHolder(row), BackgroundTransparency = 1, Image = Icon("settings"), ImageColor3 = "SubText", Size = UDim2.fromOffset(12, 12), LayoutOrder = 0 })
        Connect(gear.MouseEnter, function() gear.ImageColor3 = Theme.Accent end)
        Connect(gear.MouseLeave, function() gear.ImageColor3 = Theme.SubText end)
        local pop = PopupFrame(200)
        local gb = NewGroupbox(pop, title or (T.Text .. " Settings"))
        gb.Frame.BackgroundColor3 = Theme.Background
        Connect(gear.MouseButton1Click, function() Library:TogglePopup(pop, gear, { Side = "Right", Offset = Vector2.new(0, -4) }) end)
        return gb
    end
    for k, f in pairs(ToggleMethods) do T[k] = f end

    Connect(btn.MouseButton1Click, function()
        if T.Disabled then return end
        T:SetValue(not T.Value)
    end)
    Connect(btn.MouseEnter, function() if not T.Value then boxStroke.Color = Theme.SubText end end)
    Connect(btn.MouseLeave, function() boxStroke.Color = T.Value and Theme.Accent or Theme.Outline end)
    AddTooltip(btn, info.Tooltip)

    T:Display()
    Toggles[idx] = T
    return T
end
Groupbox.AddCheckbox = Groupbox.AddToggle

---------------------------------------------------------------- Label
function Groupbox:AddLabel(text, wrap, idx)
    local info = typeof(text) == "table" and text or { Text = text, DoesWrap = wrap }
    local L = { Type = "Label", Text = info.Text or "" }
    MakeSignalHolder(L)
    local row = self:_Row(16, L, L.Text)
    local label = New("TextLabel", { Parent = row, Text = L.Text, TextColor3 = "Text", Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = info.DoesWrap or false, RichText = true })
    if info.DoesWrap then
        row.AutomaticSize = Enum.AutomaticSize.Y
        row.Size = UDim2.new(1, 0, 0, 0)
        label.AutomaticSize = Enum.AutomaticSize.Y
        label.Size = UDim2.new(1, 0, 0, 0)
        label.TextColor3 = Theme.SubText
    end
    function L:SetText(t) self.Text = t; label.Text = t end
    function L:AddKeyPicker(i, inf) CreateKeyPicker(self, row, i, inf); return self end
    function L:AddColorPicker(i, inf) CreateColorPicker(row, i, inf); return self end
    if idx then Options[idx] = L end
    return L
end

---------------------------------------------------------------- Divider
function Groupbox:AddDivider()
    local row = self:_Row(5)
    New("Frame", { Parent = row, BackgroundColor3 = "Outline", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 1) })
end

---------------------------------------------------------------- Button
local function StyleButton(b)
    local st = Stroke(b, "Outline")
    Connect(b.MouseEnter, function() Tween(b, 0.1, { BackgroundColor3 = Theme.Hover }); b.TextColor3 = Theme.Text end)
    Connect(b.MouseLeave, function() Tween(b, 0.1, { BackgroundColor3 = Theme.Element }); b.TextColor3 = Theme.SubText end)
    Connect(b.MouseButton1Down, function() st.Color = Theme.Accent end)
    Connect(b.MouseButton1Up, function() st.Color = Theme.Outline end)
    Connect(b.MouseLeave, function() st.Color = Theme.Outline end)
    return st
end

function Groupbox:AddButton(text, func)
    local info = typeof(text) == "table" and text or { Text = text, Func = func }
    local B = { Type = "Button", Text = info.Text or "Button", Func = info.Func or info.Callback, DoubleClick = info.DoubleClick }
    MakeSignalHolder(B)
    local row = self:_Row(20, B, B.Text)
    local buttons = {}

    local function make(binfo)
        local b = New("TextButton", { Parent = row, BackgroundColor3 = "Element", Text = binfo.Text, TextColor3 = "SubText", Size = UDim2.fromScale(1, 1) })
        StyleButton(b)
        AddTooltip(b, binfo.Tooltip)
        local armed = false
        Connect(b.MouseButton1Click, function()
            if binfo.DoubleClick then
                if not armed then
                    armed = true
                    b.Text = "Are you sure?"
                    b.TextColor3 = Theme.Accent
                    task.delay(2, function() if armed then armed = false; b.Text = binfo.Text; b.TextColor3 = Theme.SubText end end)
                    return
                end
                armed = false
                b.Text = binfo.Text
            end
            SafeCall(binfo.Func or binfo.Callback)
        end)
        table.insert(buttons, b)
        local n = #buttons
        for i, bt in ipairs(buttons) do
            bt.Size = UDim2.new(1 / n, (i == n) and 0 or -4, 1, 0)
            bt.Position = UDim2.new((i - 1) / n, (i == 1) and 0 or 2, 0, 0)
        end
        return b
    end
    B.Instance = make({ Text = B.Text, Func = B.Func, DoubleClick = B.DoubleClick, Tooltip = info.Tooltip })
    function B:AddButton(t, f)
        local bi = typeof(t) == "table" and t or { Text = t, Func = f }
        make(bi)
        return self
    end
    function B:SetText(t) self.Text = t; self.Instance.Text = t end
    return B
end

---------------------------------------------------------------- Slider
function Groupbox:AddSlider(idx, info)
    info = info or {}
    local S = { Type = "Slider", Min = info.Min or 0, Max = info.Max or 100, Rounding = info.Rounding or 0, Suffix = info.Suffix or "", Text = info.Text or idx, Callback = info.Callback }
    S.Value = math.clamp(info.Default or S.Min, S.Min, S.Max)
    MakeSignalHolder(S)
    local row = self:_Row(info.Compact and 18 or 30, S, S.Text)

    local label = New("TextLabel", { Parent = row, Text = "", TextColor3 = "Text", Size = UDim2.new(1, -30, 0, 14), TextXAlignment = Enum.TextXAlignment.Left })
    local minus = New("TextButton", { Parent = row, BackgroundTransparency = 1, Text = "-", TextColor3 = "SubText", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 0), Size = UDim2.fromOffset(12, 14) })
    local plus  = New("TextButton", { Parent = row, BackgroundTransparency = 1, Text = "+", TextColor3 = "SubText", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(12, 14) })
    local barY = info.Compact and 0 or 21
    if info.Compact then label.Visible = false; minus.Visible = false; plus.Visible = false end
    local bar = New("TextButton", { Parent = row, Text = "", BackgroundColor3 = "Element", Position = UDim2.fromOffset(0, barY), Size = UDim2.new(1, -4, 0, info.Compact and 14 or 4) })
    Stroke(bar, "Outline")
    local fill = New("Frame", { Parent = bar, BackgroundColor3 = "Accent", Size = UDim2.fromScale(0, 1) })
    local knob = New("Frame", { Parent = bar, BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(8, 8), Visible = not info.Compact })
    New("UICorner", { Parent = knob, CornerRadius = UDim.new(1, 0) })
    local compactText = New("TextLabel", { Parent = bar, Text = "", TextColor3 = "Text", TextSize = 12, Size = UDim2.fromScale(1, 1), Visible = info.Compact == true, ZIndex = 2 })

    function S:Display()
        local alpha = (self.Max == self.Min) and 0 or (self.Value - self.Min) / (self.Max - self.Min)
        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.fromScale(alpha, 0.5)
        local valueText = tostring(self.Value) .. self.Suffix
        if not info.HideMax and info.ShowMax then valueText = valueText .. "/" .. self.Max .. self.Suffix end
        label.Text = self.Text .. ": " .. valueText
        compactText.Text = self.Text .. ": " .. valueText
    end
    function S:SetValue(v)
        v = tonumber(v)
        if not v then return end
        v = math.clamp(Round(v, self.Rounding), self.Min, self.Max)
        if v == self.Value then self:Display() return end
        self.Value = v
        self:Display()
        self:_Fire(v)
    end
    function S:SetMin(v) self.Min = v; self:SetValue(math.max(self.Value, v)); self:Display() end
    function S:SetMax(v) self.Max = v; self:SetValue(math.min(self.Value, v)); self:Display() end
    function S:SetText(t) self.Text = t; self:Display() end

    local step = 10 ^ -S.Rounding
    Connect(minus.MouseButton1Click, function() S:SetValue(S.Value - step) end)
    Connect(plus.MouseButton1Click, function() S:SetValue(S.Value + step) end)
    for _, b in ipairs({ minus, plus }) do
        Connect(b.MouseEnter, function() b.TextColor3 = Theme.Accent end)
        Connect(b.MouseLeave, function() b.TextColor3 = Theme.SubText end)
    end

    local dragging = false
    local function update()
        local m = UserInputService:GetMouseLocation()
        local a = math.clamp((m.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        S:SetValue(S.Min + (S.Max - S.Min) * a)
    end
    Connect(bar.MouseButton1Down, function() dragging = true; update() end)
    Connect(UserInputService.InputChanged, function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update() end end)
    Connect(UserInputService.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    AddTooltip(bar, info.Tooltip)

    S:Display()
    Options[idx] = S
    return S
end

---------------------------------------------------------------- Input
function Groupbox:AddInput(idx, info)
    info = info or {}
    local I = { Type = "Input", Value = info.Default or "", Text = info.Text or idx, Numeric = info.Numeric, Finished = info.Finished, Callback = info.Callback }
    MakeSignalHolder(I)
    local hasLabel = info.Text ~= nil and info.Text ~= ""
    local row = self:_Row(hasLabel and 38 or 20, I, I.Text)
    if hasLabel then
        New("TextLabel", { Parent = row, Text = I.Text, TextColor3 = "Text", Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Left })
    end
    local box = New("TextBox", { Parent = row, BackgroundColor3 = "Element", Position = UDim2.fromOffset(0, hasLabel and 18 or 0), Size = UDim2.new(1, 0, 0, 20),
        Text = I.Value, PlaceholderText = info.Placeholder or "...", PlaceholderColor3 = "SubText", TextColor3 = "Text", TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = info.ClearTextOnFocus or false, ClipsDescendants = true })
    Padding(box, 0, 6)
    local st = Stroke(box, "Outline")
    Connect(box.Focused, function() st.Color = Theme.Accent end)

    function I:SetValue(v)
        v = tostring(v or "")
        if info.MaxLength and #v > info.MaxLength then v = v:sub(1, info.MaxLength) end
        if self.Numeric and v ~= "" and not tonumber(v) then v = self.Value end
        box.Text = v
        if self.Value == v then return end
        self.Value = v
        self:_Fire(v)
    end
    Connect(box.FocusLost, function(enter)
        st.Color = Theme.Outline
        if I.Finished then I:SetValue(box.Text) end
    end)
    Connect(box:GetPropertyChangedSignal("Text"), function()
        if not I.Finished and box:IsFocused() then I:SetValue(box.Text) end
    end)
    AddTooltip(box, info.Tooltip)
    I.Box = box
    Options[idx] = I
    return I
end
Groupbox.AddTextbox = Groupbox.AddInput

---------------------------------------------------------------- Dropdown
local function GetPlayerNames(excludeLocal)
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if not (excludeLocal and p == LocalPlayer) then table.insert(t, p.Name) end
    end
    table.sort(t)
    return t
end

function Groupbox:AddDropdown(idx, info)
    info = info or {}
    local D = { Type = "Dropdown", Values = info.Values or {}, Multi = info.Multi, AllowNull = info.AllowNull, Text = info.Text or idx, Callback = info.Callback, SpecialType = info.SpecialType }
    MakeSignalHolder(D)
    if D.SpecialType == "Player" then D.Values = GetPlayerNames(info.ExcludeLocal) end
    D.Value = D.Multi and {} or nil

    local hasLabel = info.Text ~= nil and info.Text ~= ""
    local row = self:_Row(hasLabel and 38 or 20, D, D.Text)
    if hasLabel then
        New("TextLabel", { Parent = row, Text = D.Text, TextColor3 = "Text", Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Left })
    end
    local box = New("TextButton", { Parent = row, BackgroundColor3 = "Element", Position = UDim2.fromOffset(0, hasLabel and 18 or 0), Size = UDim2.new(1, 0, 0, 20), Text = "" })
    local boxStroke = Stroke(box, "Outline")
    local valueLabel = New("TextLabel", { Parent = box, Text = "--", TextColor3 = "SubText", Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -26, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
    local arrow = New("ImageLabel", { Parent = box, BackgroundTransparency = 1, Image = Icon("chevron-down"), ImageColor3 = "SubText", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -5, 0.5, 0), Size = UDim2.fromOffset(12, 12) })
    Connect(box.MouseEnter, function() boxStroke.Color = Theme.SubText end)
    Connect(box.MouseLeave, function() boxStroke.Color = Theme.Outline end)

    local pop = PopupFrame(100)
    local searchBox
    local searchable = info.Searchable or D.SpecialType == "Player"
    if searchable then
        searchBox = New("TextBox", { Parent = pop, BackgroundColor3 = "Element", Size = UDim2.new(1, 0, 0, 20), PlaceholderText = "Search...", PlaceholderColor3 = "SubText", Text = "", TextColor3 = "Text", TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, TextSize = 12 })
        Padding(searchBox, 0, 6)
        New("Frame", { Parent = searchBox, BackgroundColor3 = "Outline", Position = UDim2.new(0, -6, 1, -1), Size = UDim2.new(1, 12, 0, 1) })
    end
    local scroll = New("ScrollingFrame", { Parent = pop, BackgroundTransparency = 1, Position = UDim2.fromOffset(0, searchBox and 20 or 0), Size = UDim2.new(1, 0, 0, 0), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollBarImageColor3 = "Accent", BorderSizePixel = 0 })
    Padding(scroll, 2)
    List(scroll, 0)
    pop.AutomaticSize = Enum.AutomaticSize.None

    function D:GetActiveValues()
        if self.Multi then
            local n = 0
            for _ in pairs(self.Value) do n += 1 end
            return n
        end
        return self.Value and 1 or 0
    end
    function D:Display()
        local text
        if self.Multi then
            local t = {}
            for _, v in ipairs(self.Values) do if self.Value[v] then table.insert(t, tostring(v)) end end
            text = table.concat(t, ", ")
        else
            text = self.Value and tostring(self.Value) or ""
        end
        valueLabel.Text = text == "" and "--" or text
        valueLabel.TextColor3 = text == "" and Theme.SubText or Theme.Text
    end
    local optionButtons = {}
    function D:BuildList()
        for _, b in ipairs(optionButtons) do b:Destroy() end
        table.clear(optionButtons)
        local q = searchBox and searchBox.Text:lower() or ""
        local count = 0
        for i, v in ipairs(self.Values) do
            if q == "" or tostring(v):lower():find(q, 1, true) then
                count += 1
                local selected = self.Multi and self.Value[v] or (not self.Multi and self.Value == v)
                local b = New("TextButton", { Parent = scroll, BackgroundColor3 = "Element", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Text = tostring(v), TextSize = 12,
                    TextColor3 = selected and Theme.Accent or Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = i })
                Padding(b, 0, 6)
                Connect(b.MouseEnter, function() b.BackgroundTransparency = 0 end)
                Connect(b.MouseLeave, function() b.BackgroundTransparency = 1 end)
                Connect(b.MouseButton1Click, function()
                    if self.Multi then
                        if self.Value[v] then self.Value[v] = nil else self.Value[v] = true end
                    else
                        if self.Value == v then
                            if self.AllowNull then self.Value = nil end
                        else
                            self.Value = v
                        end
                        Library:ClosePopup(pop)
                    end
                    self:Display()
                    self:BuildList()
                    self:_Fire(self.Value)
                end)
                table.insert(optionButtons, b)
            end
        end
        local h = math.min(count, 8) * 18 + 4
        scroll.Size = UDim2.new(1, 0, 0, h)
        pop.Size = UDim2.new(0, pop.Size.X.Offset, 0, h + (searchBox and 20 or 0))
    end
    function D:SetValues(values)
        self.Values = values or {}
        if self.Multi then
            for k in pairs(self.Value) do if not table.find(self.Values, k) then self.Value[k] = nil end end
        elseif self.Value ~= nil and not table.find(self.Values, self.Value) then
            self.Value = nil
        end
        self:Display()
        self:BuildList()
    end
    function D:AddValues(values)
        for _, v in ipairs(typeof(values) == "table" and values or { values }) do table.insert(self.Values, v) end
        self:BuildList()
    end
    function D:SetValue(v)
        if self.Multi then
            local nt = {}
            if typeof(v) == "table" then
                for k, val in pairs(v) do
                    if typeof(k) == "number" then k = val; val = true end
                    if val and table.find(self.Values, k) then nt[k] = true end
                end
            end
            self.Value = nt
        else
            if v == nil or table.find(self.Values, v) then self.Value = v end
        end
        self:Display()
        self:BuildList()
        self:_Fire(self.Value)
    end

    if searchBox then Connect(searchBox:GetPropertyChangedSignal("Text"), function() D:BuildList() end) end
    Connect(box.MouseButton1Click, function()
        if searchBox then searchBox.Text = "" end
        D:BuildList()
        Library:TogglePopup(pop, box, { MatchWidth = true })
        arrow.Rotation = Library:IsPopupOpen(pop) and 180 or 0
    end)
    pop:GetPropertyChangedSignal("Visible"):Connect(function() arrow.Rotation = pop.Visible and 180 or 0 end)

    if D.SpecialType == "Player" then
        local function refresh() D:SetValues(GetPlayerNames(info.ExcludeLocal)) end
        Connect(Players.PlayerAdded, refresh)
        Connect(Players.PlayerRemoving, function() task.defer(refresh) end)
    end

    -- defaults
    local def = info.Default
    if D.Multi then
        if typeof(def) == "table" then D:SetValue(def) end
    elseif def ~= nil then
        if typeof(def) == "number" and not table.find(D.Values, def) then def = D.Values[def] end
        if table.find(D.Values, def) then D.Value = def end
    end
    AddTooltip(box, info.Tooltip)
    D:Display()
    D:BuildList()
    Options[idx] = D
    return D
end

---------------------------------------------------------------- Dependency box
function Groupbox:AddDependencyBox()
    self.Order += 1
    local frame = New("Frame", { Parent = self.Container, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = self.Order })
    List(frame, 5)
    local dep = setmetatable({ Container = frame, Frame = frame, Order = 0, Root = self.Root, Dependencies = {} }, Groupbox)
    function dep:SetupDependencies(deps)
        self.Dependencies = deps
        for _, d in ipairs(deps) do
            if d[1] and d[1].OnChanged then
                table.insert(d[1].Changed, function() self:Update() end)
            end
        end
        self:Update()
    end
    function dep:Update()
        local ok = true
        for _, d in ipairs(self.Dependencies) do
            local elem, want = d[1], d[2]
            if elem.Type == "Dropdown" and elem.Multi then
                if not elem.Value[want] then ok = false end
            elseif elem.Value ~= want then
                ok = false
            end
        end
        frame.Visible = ok
    end
    return dep
end

--------------------------------------------------------------------------------
-- Frame windows (main + aux)
--------------------------------------------------------------------------------
local function CreateFrameWindow(title, size, position, icon)
    local frame = New("Frame", { Parent = WindowLayer, BackgroundColor3 = "Background", Size = size, Position = position, Visible = false })
    Stroke(frame, "Outline")
    local titleBar = New("TextButton", { Parent = frame, BackgroundColor3 = "Header", Size = UDim2.new(1, 0, 0, 24), Text = "" })
    New("Frame", { Parent = titleBar, BackgroundColor3 = "Outline", Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1) })
    New("Frame", { Parent = titleBar, BackgroundColor3 = "Accent", Size = UDim2.new(0, 2, 1, -1) })
    if icon then
        New("ImageLabel", { Parent = titleBar, BackgroundTransparency = 1, Image = Icon(icon), ImageColor3 = "Accent", Position = UDim2.fromOffset(9, 6), Size = UDim2.fromOffset(12, 12) })
    end
    New("TextLabel", { Parent = titleBar, Text = title, TextColor3 = "Text", Position = UDim2.fromOffset(icon and 27 or 9, 0), Size = UDim2.new(1, -36, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
    local content = New("ScrollingFrame", { Parent = frame, BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 1, -24), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollBarImageColor3 = "Accent", BorderSizePixel = 0 })
    Padding(content, 6)
    List(content, 6)
    MakeDraggable(frame, titleBar)
    Connect(frame.InputBegan, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then BringToFront(frame) end end)
    return { Frame = frame, Content = content, TitleBar = titleBar }
end

--------------------------------------------------------------------------------
-- Keybind list / watermark
--------------------------------------------------------------------------------
local Hud = {}
do
    Hud.Watermark = New("Frame", { Parent = HudLayer, BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 66), Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X })
    List(Hud.Watermark, 4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    local function chip(icon, text, order, accentText)
        local c = New("TextButton", { Parent = Hud.Watermark, BackgroundColor3 = "Background", Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, Text = "", LayoutOrder = order })
        Stroke(c, "Outline")
        Padding(c, 0, 8)
        List(c, 6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
        if icon == "$" then
            New("TextLabel", { Parent = c, Text = "$", FontFace = Library.FontBold, TextSize = 15, TextColor3 = "Accent", Size = UDim2.fromOffset(8, 24), LayoutOrder = 1 })
        elseif icon then
            New("ImageLabel", { Parent = c, BackgroundTransparency = 1, Image = Icon(icon), ImageColor3 = "Accent", Size = UDim2.fromOffset(13, 13), LayoutOrder = 1 })
        end
        local l = New("TextLabel", { Parent = c, Text = text, TextColor3 = "Text", TextSize = 12, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 24), LayoutOrder = 2, RichText = true })
        MakeDraggable(Hud.Watermark, c)
        return l
    end
    Hud.Chips = {}
    Hud.Chips.Name = chip("$", "", 1)
    Hud.Chips.User = chip("user", LocalPlayer.Name, 2)
    Hud.Chips.Game = chip("gamepad", "Universal", 3)
    Hud.Chips.Perf = chip(nil, "", 4)
    Hud.SetName = function(name)
        Hud.Chips.Name.Text = string.format('%s <font color="#808080">v%s</font>', name, Library.Version)
    end
    Hud.SetName(Library.Name)

    local frames, last, fps = 0, os.clock(), 60
    Connect(RunService.RenderStepped, function()
        frames += 1
        local now = os.clock()
        if now - last >= 0.5 then
            fps = math.floor(frames / (now - last) + 0.5)
            frames, last = 0, now
            local ping = 0
            pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5) end)
            Hud.Chips.Perf.Text = string.format('%d <font color="#808080">fps</font>  %d <font color="#808080">ms</font>', fps, ping)
        end
    end)

    -- keybind list
    Hud.Keybinds = New("Frame", { Parent = HudLayer, BackgroundColor3 = "Background", Position = UDim2.fromOffset(20, 98), Size = UDim2.fromOffset(170, 0), AutomaticSize = Enum.AutomaticSize.Y })
    Stroke(Hud.Keybinds, "Outline")
    List(Hud.Keybinds, 0)
    local kh = New("TextButton", { Parent = Hud.Keybinds, BackgroundColor3 = "Header", Size = UDim2.new(1, 0, 0, 24), Text = "", LayoutOrder = 0 })
    New("Frame", { Parent = kh, BackgroundColor3 = "Accent", Size = UDim2.new(1, 0, 0, 1) })
    New("ImageLabel", { Parent = kh, BackgroundTransparency = 1, Image = Icon("keyboard"), ImageColor3 = "Accent", Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(13, 13) })
    New("TextLabel", { Parent = kh, Text = "Keybinds", TextColor3 = "Text", Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -28, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
    MakeDraggable(Hud.Keybinds, kh)
    Hud.KeybindList = New("Frame", { Parent = Hud.Keybinds, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1 })
    Padding(Hud.KeybindList, 2, 8, 4, 8)
    List(Hud.KeybindList, 0)
end
Library.Hud = Hud

function Library:_UpdateKeybindList()
    if not Hud.KeybindList then return end
    for _, c in ipairs(Hud.KeybindList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    local i = 0
    for _, kp in ipairs(self.KeyPickers) do
        if not kp.NoUI and kp.Value ~= "None" then
            i += 1
            local active = kp:GetState()
            local r = New("Frame", { Parent = Hud.KeybindList, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = i })
            New("TextLabel", { Parent = r, Text = kp.Text, TextColor3 = active and Theme.Accent or Theme.SubText, TextSize = 12, Size = UDim2.new(1, -60, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
            New("TextLabel", { Parent = r, Text = "[" .. KeyDisplay(kp.Value) .. "] " .. kp.Mode:sub(1, 1), TextColor3 = active and Theme.Text or Theme.SubText, TextSize = 12, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 60, 1, 0), TextXAlignment = Enum.TextXAlignment.Right })
        end
    end
    if i == 0 then
        New("Frame", { Parent = Hud.KeybindList, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 2) })
    end
end
-- hold-mode states change without events firing, refresh a few times a second
task.spawn(function()
    while not Library.Unloaded do
        task.wait(0.15)
        local anyHold = false
        for _, kp in ipairs(Library.KeyPickers) do if kp.Mode == "Hold" and kp.Value ~= "None" then anyHold = true break end end
        if anyHold then Library:_UpdateKeybindList() end
    end
end)

function Library:SetWatermarkVisibility(v) Hud.Watermark.Visible = v end
function Library:SetWatermark(text) Hud.Chips.Name.Text = text end

--------------------------------------------------------------------------------
-- Save manager
--------------------------------------------------------------------------------
local SaveManager = { Ignore = { ML_ConfigName = true, ML_ConfigList = true, ML_PlayerSearch = true } }
Library.SaveManager = SaveManager

function SaveManager:Root() return Library.Folder .. "/" .. Library.SubFolder end
function SaveManager:ConfigFolder() return self:Root() .. "/configs" end
function SaveManager:BuildFolders() FS.MakeFolder(self:ConfigFolder()) end
function SaveManager:SetFolder(sub) Library.SubFolder = sub; self:BuildFolders() end
function SaveManager:SetIgnoreIndexes(list) for _, i in ipairs(list) do self.Ignore[i] = true end end

function SaveManager:Serialize()
    local data = { objects = {} }
    for idx, t in pairs(Toggles) do
        if not self.Ignore[idx] then table.insert(data.objects, { type = "Toggle", idx = idx, value = t.Value }) end
    end
    for idx, o in pairs(Options) do
        if not self.Ignore[idx] then
            if o.Type == "Slider" or o.Type == "Input" then
                table.insert(data.objects, { type = o.Type, idx = idx, value = o.Value })
            elseif o.Type == "Dropdown" then
                table.insert(data.objects, { type = "Dropdown", idx = idx, value = o.Value, multi = o.Multi })
            elseif o.Type == "KeyPicker" then
                table.insert(data.objects, { type = "KeyPicker", idx = idx, key = o.Value, mode = o.Mode })
            elseif o.Type == "ColorPicker" then
                table.insert(data.objects, { type = "ColorPicker", idx = idx, value = ToHex(o.Value), transparency = o.Transparency })
            end
        end
    end
    return HttpService:JSONEncode(data)
end

function SaveManager:Apply(json)
    local ok, data = pcall(HttpService.JSONDecode, HttpService, json)
    if not ok or typeof(data) ~= "table" then return false, "invalid config data" end
    for _, o in ipairs(data.objects or {}) do
        pcall(function()
            if o.type == "Toggle" and Toggles[o.idx] then
                Toggles[o.idx]:SetValue(o.value)
            elseif Options[o.idx] then
                local opt = Options[o.idx]
                if o.type == "KeyPicker" then opt:SetValue({ o.key, o.mode })
                elseif o.type == "ColorPicker" then opt:SetValueRGB(Color3.fromHex(o.value), o.transparency)
                else opt:SetValue(o.value) end
            end
        end)
    end
    return true
end

function SaveManager:Save(name)
    if not name or name:gsub("%s", "") == "" then return false, "no config name" end
    self:BuildFolders()
    return FS.Write(self:ConfigFolder() .. "/" .. name .. ".json", self:Serialize())
end
function SaveManager:Load(name)
    if not name then return false, "no config selected" end
    local data = FS.Read(self:ConfigFolder() .. "/" .. name .. ".json")
    if not data then return false, "config does not exist" end
    return self:Apply(data)
end
function SaveManager:Delete(name)
    if not name then return false, "no config selected" end
    FS.Delete(self:ConfigFolder() .. "/" .. name .. ".json")
    if self:GetAutoload() == name then FS.Delete(self:ConfigFolder() .. "/autoload.txt") end
    return true
end
function SaveManager:List() return FS.List(self:ConfigFolder(), ".json") end
function SaveManager:SetAutoload(name) FS.Write(self:ConfigFolder() .. "/autoload.txt", name or "") end
function SaveManager:GetAutoload()
    local n = FS.Read(self:ConfigFolder() .. "/autoload.txt")
    if n and n ~= "" then return n end
    return nil
end
function SaveManager:LoadAutoloadConfig()
    local n = self:GetAutoload()
    if n then
        local ok, err = self:Load(n)
        if ok then Library:Notify({ Title = "Configs", Description = "Autoloaded config " .. n }) else Library:Notify({ Title = "Configs", Description = "Autoload failed: " .. tostring(err) }) end
    end
end

--------------------------------------------------------------------------------
-- Player status helpers
--------------------------------------------------------------------------------
Library.StatusChanged = {}
function Library:GetPlayerStatus(plr) return self.PlayerStatus[plr] or "Neutral" end
function Library:SetPlayerStatus(plr, status)
    self.PlayerStatus[plr] = (status ~= "Neutral") and status or nil
    for _, fn in ipairs(self.StatusChanged) do SafeCall(fn, plr, status) end
    if self._RefreshPlayerList then self._RefreshPlayerList() end
end
function Library:OnStatusChanged(fn) table.insert(self.StatusChanged, fn) end
function Library:GetStatusColor(status)
    if status == "Friendly" and Options.ML_FriendlyColor then return Options.ML_FriendlyColor.Value end
    if status == "Priority" and Options.ML_PriorityColor then return Options.ML_PriorityColor.Value end
    return Theme.Text
end
Connect(Players.PlayerRemoving, function(p) Library.PlayerStatus[p] = nil end)

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local SubTab = {}
SubTab.__index = SubTab

function Library:CreateWindow(info)
    info = info or {}
    Library.Name = info.Title or Library.Name
    if info.ConfigFolder then Library.SubFolder = info.ConfigFolder end
    if info.Folder then Library.Folder = info.Folder end
    Hud.SetName(Library.Name)
    Hud.Chips.Game.Text = info.Game or "Universal"
    if info.Accent then Library.DefaultAccent = info.Accent; Library:SetAccent(info.Accent) end
    SaveManager:BuildFolders()

    local self = setmetatable({ Tabs = {}, Aux = {}, DockButtons = {} }, Window)
    local vp = ScreenGui.AbsoluteSize
    if vp.X < 200 then vp = workspace.CurrentCamera.ViewportSize end
    local size = info.Size or UDim2.fromOffset(560, 440)

    --------------------------------------------------- main frame
    local main = New("Frame", { Parent = WindowLayer, BackgroundColor3 = "Background", Size = size,
        Position = UDim2.fromOffset(math.floor(vp.X / 2 - size.X.Offset / 2), math.floor(vp.Y / 2 - size.Y.Offset / 2 + 20)) })
    Stroke(main, "Outline")
    New("Frame", { Parent = main, BackgroundColor3 = "Accent", Size = UDim2.new(1, 0, 0, 1), ZIndex = 5 })
    self.Frame = main

    -- sidebar
    local sidebar = New("Frame", { Parent = main, BackgroundColor3 = "Header", Size = UDim2.new(0, 48, 1, 0) })
    New("Frame", { Parent = sidebar, BackgroundColor3 = "Outline", Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0) })
    local logo = New("TextButton", { Parent = sidebar, Text = "$", FontFace = Library.FontBold, TextSize = 26, TextColor3 = "Accent", BackgroundTransparency = 1, Size = UDim2.fromOffset(48, 48) })
    MakeDraggable(main, logo)
    local tabHolder = New("Frame", { Parent = sidebar, BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 52), Size = UDim2.new(1, 0, 1, -52) })
    List(tabHolder, 2)
    self.TabHolder = tabHolder

    -- header (subtabs + search)
    local header = New("TextButton", { Parent = main, BackgroundColor3 = "Background", Text = "", Position = UDim2.fromOffset(48, 1), Size = UDim2.new(1, -48, 0, 40) })
    New("Frame", { Parent = header, BackgroundColor3 = "Outline", Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1) })
    MakeDraggable(main, header)
    self.SubTabHolder = New("Frame", { Parent = header, BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -170, 1, 0) })

    local search = New("Frame", { Parent = header, BackgroundColor3 = "Element", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(150, 22) })
    local searchStroke = Stroke(search, "Outline")
    New("ImageLabel", { Parent = search, BackgroundTransparency = 1, Image = Icon("search"), ImageColor3 = "SubText", Position = UDim2.fromOffset(6, 5), Size = UDim2.fromOffset(12, 12) })
    local searchBox = New("TextBox", { Parent = search, BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -28, 1, 0), Text = "", PlaceholderText = "Search...", PlaceholderColor3 = "SubText", TextColor3 = "Text", TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false })
    Connect(searchBox.Focused, function() searchStroke.Color = Theme.Accent end)
    Connect(searchBox.FocusLost, function() searchStroke.Color = Theme.Outline end)
    Connect(searchBox:GetPropertyChangedSignal("Text"), function() self:_ApplySearch() end)
    self.SearchBox = searchBox

    self.Body = New("Frame", { Parent = main, BackgroundTransparency = 1, Position = UDim2.fromOffset(48, 41), Size = UDim2.new(1, -48, 1, -41) })

    -- resize grip
    local grip = New("TextButton", { Parent = main, Text = "", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(14, 14), ZIndex = 5 })
    New("Frame", { Parent = grip, BackgroundColor3 = "Outline", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -2, 1, -2), Size = UDim2.fromOffset(8, 1) })
    New("Frame", { Parent = grip, BackgroundColor3 = "Outline", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -2, 1, -2), Size = UDim2.fromOffset(1, 8) })
    do
        local resizing, startM, startS
        Connect(grip.InputBegan, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then resizing = true; startM = UserInputService:GetMouseLocation(); startS = main.AbsoluteSize end end)
        Connect(UserInputService.InputChanged, function(i)
            if resizing and i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = UserInputService:GetMouseLocation() - startM
                main.Size = UDim2.fromOffset(math.max(460, startS.X + d.X), math.max(320, startS.Y + d.Y))
            end
        end)
        Connect(UserInputService.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end end)
    end
    Connect(main.InputBegan, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then BringToFront(main) end end)

    --------------------------------------------------- aux windows
    local px, py = main.Position.X.Offset, main.Position.Y.Offset
    self.Aux.Configs  = CreateFrameWindow("Configs",  UDim2.fromOffset(240, 330), UDim2.fromOffset(math.max(10, px - 250), py), "folder")
    self.Aux.Settings = CreateFrameWindow("Settings", UDim2.fromOffset(240, 330), UDim2.fromOffset(math.max(10, px - 250), py + 110), "settings")
    self.Aux.Players  = CreateFrameWindow("Playerlist", UDim2.fromOffset(300, 360), UDim2.fromOffset(math.max(10, px - 310), py), "users")
    self.Aux.Preview  = CreateFrameWindow("ESP Preview", UDim2.fromOffset(230, 440), UDim2.fromOffset(math.min(vp.X - 240, px + size.X.Offset + 10), py), "eye")

    self:_BuildConfigs()
    self:_BuildSettings()
    self:_BuildPlayers()
    self:_BuildPreview()
    self:_BuildDock()

    Library.Window = self
    Library:SetOpen(info.AutoShow ~= false)
    return self
end

--------------------------------------------------- tabs
function Window:AddTab(name, icon)
    local T = setmetatable({ Name = name, Window = self, SubTabs = {} }, Tab)
    local btn = New("TextButton", { Parent = self.TabHolder, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Text = "", LayoutOrder = #self.Tabs + 1 })
    local bar = New("Frame", { Parent = btn, BackgroundColor3 = "Accent", Size = UDim2.new(0, 2, 0, 20), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Visible = false })
    local img = New("ImageLabel", { Parent = btn, BackgroundTransparency = 1, Image = Icon(icon or "box"), ImageColor3 = "SubText", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(20, 20) })
    AddTooltip(btn, name)
    T.Button, T.Bar, T.Icon = btn, bar, img

    T.SubButtons = New("Frame", { Parent = self.SubTabHolder, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false })
    List(T.SubButtons, 4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    T.Page = New("Frame", { Parent = self.Body, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false })

    Connect(btn.MouseEnter, function() if self.ActiveTab ~= T then img.ImageColor3 = Theme.Text end end)
    Connect(btn.MouseLeave, function() if self.ActiveTab ~= T then img.ImageColor3 = Theme.SubText end end)
    Connect(btn.MouseButton1Click, function() T:Show() end)
    table.insert(self.Tabs, T)
    if #self.Tabs == 1 then T:Show() end
    return T
end

function Tab:Show()
    local W = self.Window
    for _, t in ipairs(W.Tabs) do
        local on = t == self
        t.Bar.Visible = on
        t.Icon.ImageColor3 = on and Theme.Accent or Theme.SubText
        t.SubButtons.Visible = on
        t.Page.Visible = on
    end
    W.ActiveTab = self
    if not self.ActiveSub and self.SubTabs[1] then self.SubTabs[1]:Show() end
    W:_ApplySearch()
end

function Tab:AddSubTab(name)
    local S = setmetatable({ Name = name, Tab = self, Groupboxes = {} }, SubTab)
    local w = TextWidth(name, 12) + 18
    local btn = New("TextButton", { Parent = self.SubButtons, BackgroundColor3 = "Background", Size = UDim2.fromOffset(w, 24), Text = name, TextSize = 12, TextColor3 = "SubText", LayoutOrder = #self.SubTabs + 1 })
    local st = Stroke(btn, "Background")
    local line = New("Frame", { Parent = btn, BackgroundColor3 = "Accent", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), Visible = false })
    S.Button, S.Stroke, S.Line = btn, st, line

    S.Page = New("Frame", { Parent = self.Page, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false })
    local function column(x)
        local col = New("ScrollingFrame", { Parent = S.Page, BackgroundTransparency = 1, Position = UDim2.new(x, x == 0 and 8 or 4, 0, 8), Size = UDim2.new(0.5, -12, 1, -16), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 0, BorderSizePixel = 0 })
        Padding(col, 1)
        List(col, 8)
        return col
    end
    S.Left, S.Right = column(0), column(0.5)

    Connect(btn.MouseEnter, function() if self.ActiveSub ~= S then btn.TextColor3 = Theme.Text end end)
    Connect(btn.MouseLeave, function() if self.ActiveSub ~= S then btn.TextColor3 = Theme.SubText end end)
    Connect(btn.MouseButton1Click, function() S:Show() end)
    table.insert(self.SubTabs, S)
    if #self.SubTabs == 1 then S:Show() end
    return S
end

function SubTab:Show()
    local T = self.Tab
    for _, s in ipairs(T.SubTabs) do
        local on = s == self
        s.Page.Visible = on
        s.Button.BackgroundColor3 = on and Theme.Element or Theme.Background
        s.Button.TextColor3 = on and Theme.Text or Theme.SubText
        s.Stroke.Color = on and Theme.Outline or Theme.Background
        s.Line.Visible = on
    end
    T.ActiveSub = self
    T.Window:_ApplySearch()
end

function SubTab:AddLeftGroupbox(name)
    local g = NewGroupbox(self.Left, name, { LayoutOrder = #self.Groupboxes + 1 })
    table.insert(self.Groupboxes, g)
    return g
end
function SubTab:AddRightGroupbox(name)
    local g = NewGroupbox(self.Right, name, { LayoutOrder = #self.Groupboxes + 1 })
    table.insert(self.Groupboxes, g)
    return g
end

-- Tab:AddLeftGroupbox works without explicit subtabs (uses a default "Main" subtab)
function Tab:_Default()
    if not self.DefaultSub then self.DefaultSub = self:AddSubTab(self.Name) end
    return self.DefaultSub
end
function Tab:AddLeftGroupbox(name) return self:_Default():AddLeftGroupbox(name) end
function Tab:AddRightGroupbox(name) return self:_Default():AddRightGroupbox(name) end

function Window:_ApplySearch()
    local q = (self.SearchBox and self.SearchBox.Text or ""):lower()
    local tab = self.ActiveTab
    if not tab or not tab.ActiveSub then return end
    for _, g in ipairs(tab.ActiveSub.Groupboxes) do
        g.Query = q
        g:_Refilter()
    end
end

--------------------------------------------------- dock
function Window:_BuildDock()
    local dock = New("Frame", { Parent = HudLayer, BackgroundColor3 = "Background", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 66), Size = UDim2.fromOffset(0, 32), AutomaticSize = Enum.AutomaticSize.X })
    Stroke(dock, "Outline")
    Padding(dock, 0, 4)
    List(dock, 2, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    self.Dock = dock

    local entries = {
        { "Main", "home", function() return self.Frame end },
        { "Configs", "folder", function() return self.Aux.Configs.Frame end },
        { "Playerlist", "users", function() return self.Aux.Players.Frame end },
        { "ESP Preview", "eye", function() return self.Aux.Preview.Frame end },
        { "Settings", "settings", function() return self.Aux.Settings.Frame end },
    }
    for i, e in ipairs(entries) do
        local b = New("TextButton", { Parent = dock, BackgroundTransparency = 1, Size = UDim2.fromOffset(30, 30), Text = "", LayoutOrder = i })
        local img = New("ImageLabel", { Parent = b, BackgroundTransparency = 1, Image = Icon(e[2]), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(16, 16),
            ImageColor3 = function() return e[3]().Visible and Theme.Accent or Theme.SubText end })
        local line = New("Frame", { Parent = b, BackgroundColor3 = "Accent", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(14, 2) })
        AddTooltip(b, e[1])
        local function refresh()
            local open = e[3]().Visible
            img.ImageColor3 = open and Theme.Accent or Theme.SubText
            line.Visible = open
        end
        Connect(e[3]():GetPropertyChangedSignal("Visible"), refresh)
        Connect(b.MouseButton1Click, function()
            local f = e[3]()
            f.Visible = not f.Visible
            if f.Visible then BringToFront(f) end
            if f == self.Frame then self.MainHidden = not f.Visible end
        end)
        Connect(b.MouseEnter, function() if not e[3]().Visible then img.ImageColor3 = Theme.Text end end)
        Connect(b.MouseLeave, refresh)
        refresh()
    end
end

--------------------------------------------------- configs window
function Window:_BuildConfigs()
    local c = self.Aux.Configs.Content
    local create = NewGroupbox(c, "Creation", { LayoutOrder = 1 })
    local nameInput = create:AddInput("ML_ConfigName", { Text = "Config Name", Placeholder = "..." })
    local sel = NewGroupbox(c, "Selection", { LayoutOrder = 2 })
    local list = sel:AddDropdown("ML_ConfigList", { Text = "Configs", Values = SaveManager:List(), AllowNull = true, Searchable = true })
    local autoLabel

    local function refresh()
        list:SetValues(SaveManager:List())
        local a = SaveManager:GetAutoload()
        autoLabel:SetText("Autoload: " .. (a and ('<font color="#' .. ToHex(Theme.Accent) .. '">' .. a .. "</font>") or "none"))
    end

    create:AddButton({ Text = "Create", Func = function()
        local name = nameInput.Value:gsub("^%s+", ""):gsub("%s+$", "")
        if name == "" then return Library:Notify({ Title = "Configs", Description = "Enter a config name first" }) end
        if name:find("[/\\:%*%?\"<>|]") then return Library:Notify({ Title = "Configs", Description = "Invalid characters in name" }) end
        local ok, err = SaveManager:Save(name)
        Library:Notify({ Title = "Configs", Description = ok and ("Created " .. name) or ("Save failed: " .. tostring(err)) })
        refresh()
        list:SetValue(name)
    end })

    sel:AddButton({ Text = "Load", Func = function()
        local ok, err = SaveManager:Load(list.Value)
        Library:Notify({ Title = "Configs", Description = ok and ("Loaded " .. list.Value) or ("Load failed: " .. tostring(err)) })
    end })
    sel:AddButton({ Text = "Overwrite", Func = function()
        if not list.Value then return Library:Notify({ Title = "Configs", Description = "Select a config first" }) end
        local ok, err = SaveManager:Save(list.Value)
        Library:Notify({ Title = "Configs", Description = ok and ("Overwrote " .. list.Value) or ("Save failed: " .. tostring(err)) })
    end })
    sel:AddButton({ Text = "Delete", DoubleClick = true, Func = function()
        if not list.Value then return Library:Notify({ Title = "Configs", Description = "Select a config first" }) end
        local n = list.Value
        SaveManager:Delete(n)
        Library:Notify({ Title = "Configs", Description = "Deleted " .. n })
        refresh()
    end })
    sel:AddButton({ Text = "Set Autoload", Func = function()
        if not list.Value then return Library:Notify({ Title = "Configs", Description = "Select a config first" }) end
        SaveManager:SetAutoload(list.Value)
        refresh()
    end }):AddButton({ Text = "Clear", Func = function()
        SaveManager:SetAutoload("")
        refresh()
    end })
    sel:AddButton({ Text = "Refresh", Func = refresh })
    autoLabel = sel:AddLabel("Autoload: none")
    local pathLabel = sel:AddLabel({ Text = "", DoesWrap = true })
    pathLabel:SetText((FS.Native and "workspace/" or "memory (no file api): ") .. SaveManager:ConfigFolder())
    self.RefreshConfigs = refresh
    refresh()
end

--------------------------------------------------- settings window
function Window:_BuildSettings()
    local c = self.Aux.Settings.Content
    local menu = NewGroupbox(c, "Main", { LayoutOrder = 1 })
    menu:AddLabel("Menu Keybind"):AddKeyPicker("ML_MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu" })
    menu:AddLabel("Dock Keybind"):AddKeyPicker("ML_DockKeybind", { Default = "None", NoUI = true, Text = "Dock" })
    menu:AddToggle("ML_ShowWatermark", { Text = "Show Watermark", Default = true, Callback = function(v) Hud.Watermark.Visible = v end })
    menu:AddToggle("ML_ShowKeybinds", { Text = "Show Keybind List", Default = true, Callback = function(v) Hud.Keybinds.Visible = v end })
    Library.ToggleKeybind = Options.ML_MenuKeybind
    Options.ML_MenuKeybind:OnClick(function() Library:Toggle() end)
    Options.ML_DockKeybind:OnClick(function() if self.Dock then self.Dock.Visible = not self.Dock.Visible end end)

    local theme = NewGroupbox(c, "Theme", { LayoutOrder = 2 })
    theme:AddLabel("Accent"):AddColorPicker("ML_Accent", { Default = Theme.Accent, Title = "Accent", Callback = function(col) Library:SetAccent(col) end })
    theme:AddButton({ Text = "Reset Accent", Func = function() Options.ML_Accent:SetValueRGB(Library.DefaultAccent) end })

    local misc = NewGroupbox(c, "Misc", { LayoutOrder = 3 })
    misc:AddButton({ Text = "Unload", DoubleClick = true, Func = function() Library:Unload() end })
end

--------------------------------------------------- playerlist window
function Window:_BuildPlayers()
    local c = self.Aux.Players.Content
    local box = NewGroupbox(c, "Selection", { LayoutOrder = 1 })
    local search = box:AddInput("ML_PlayerSearch", { Placeholder = "Search players..." })

    local headerRow = box:_Row(16)
    New("TextLabel", { Parent = headerRow, Text = "Profile", TextColor3 = "SubText", TextSize = 12, Size = UDim2.fromOffset(40, 16), TextXAlignment = Enum.TextXAlignment.Left })
    New("TextLabel", { Parent = headerRow, Text = "Name", TextColor3 = "SubText", TextSize = 12, Position = UDim2.fromOffset(46, 0), Size = UDim2.fromOffset(100, 16), TextXAlignment = Enum.TextXAlignment.Left })
    New("TextLabel", { Parent = headerRow, Text = "Options", TextColor3 = "SubText", TextSize = 12, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(80, 16), TextXAlignment = Enum.TextXAlignment.Left })

    local listRow = box:_Row(200)
    local scroll = New("ScrollingFrame", { Parent = listRow, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollBarImageColor3 = "Accent", BorderSizePixel = 0 })
    List(scroll, 0)

    local colors = NewGroupbox(c, "Colors", { LayoutOrder = 2 })
    colors:AddLabel("Friendly"):AddColorPicker("ML_FriendlyColor", { Default = Color3.fromRGB(80, 220, 130), Title = "Friendly" })
    colors:AddLabel("Priority"):AddColorPicker("ML_PriorityColor", { Default = Color3.fromRGB(255, 150, 60), Title = "Priority" })

    local thumbs = {}
    local statusPop = PopupFrame(90)
    Padding(statusPop, 3)
    List(statusPop, 0)
    local popTarget
    for i, st in ipairs(Library.Statuses) do
        local b = New("TextButton", { Parent = statusPop, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Text = st, TextSize = 12, TextColor3 = "SubText", TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = i })
        Padding(b, 0, 5)
        Connect(b.MouseEnter, function() b.TextColor3 = Theme.Text end)
        Connect(b.MouseLeave, function() b.TextColor3 = Theme.SubText end)
        Connect(b.MouseButton1Click, function()
            Library:ClosePopup(statusPop)
            if popTarget and popTarget.Parent then Library:SetPlayerStatus(popTarget, st) end
        end)
    end

    local function rebuild()
        for _, ch in ipairs(scroll:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
        local q = (search.Value or ""):lower()
        local plist = Players:GetPlayers()
        table.sort(plist, function(a, b)
            if a == LocalPlayer then return true elseif b == LocalPlayer then return false end
            return a.Name:lower() < b.Name:lower()
        end)
        for i, plr in ipairs(plist) do
            if q == "" or plr.Name:lower():find(q, 1, true) or plr.DisplayName:lower():find(q, 1, true) then
                local status = Library:GetPlayerStatus(plr)
                local r = New("Frame", { Parent = scroll, BackgroundColor3 = "Element", BackgroundTransparency = (i % 2 == 0) and 0 or 1, Size = UDim2.new(1, -4, 0, 28), LayoutOrder = i })
                local av = New("ImageLabel", { Parent = r, BackgroundColor3 = "Hover", Position = UDim2.fromOffset(6, 3), Size = UDim2.fromOffset(22, 22), Image = thumbs[plr.UserId] or "" })
                New("UICorner", { Parent = av, CornerRadius = UDim.new(1, 0) })
                if not thumbs[plr.UserId] then
                    task.spawn(function()
                        local ok, img = pcall(Players.GetUserThumbnailAsync, Players, plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                        if ok then thumbs[plr.UserId] = img; if av.Parent then av.Image = img end end
                    end)
                end
                New("TextLabel", { Parent = r, Text = plr.Name, TextSize = 12, TextColor3 = Library:GetStatusColor(status), Position = UDim2.fromOffset(46, 0), Size = UDim2.new(1, -140, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
                local chip = New("TextButton", { Parent = r, BackgroundColor3 = "Element", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(80, 18), Text = "" })
                Stroke(chip, "Outline")
                New("TextLabel", { Parent = chip, Text = plr == LocalPlayer and "You" or status, TextSize = 12, TextColor3 = plr == LocalPlayer and Theme.Accent or Library:GetStatusColor(status) == Theme.Text and Theme.SubText or Library:GetStatusColor(status), Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -20, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
                if plr ~= LocalPlayer then
                    New("ImageLabel", { Parent = chip, BackgroundTransparency = 1, Image = Icon("chevron-down"), ImageColor3 = "SubText", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(10, 10) })
                    Connect(chip.MouseButton1Click, function()
                        popTarget = plr
                        Library:TogglePopup(statusPop, chip, { MatchWidth = true })
                    end)
                end
            end
        end
    end
    Library._RefreshPlayerList = rebuild
    search:OnChanged(rebuild)
    Options.ML_FriendlyColor:OnChanged(rebuild)
    Options.ML_PriorityColor:OnChanged(rebuild)
    Connect(Players.PlayerAdded, rebuild)
    Connect(Players.PlayerRemoving, function() task.defer(rebuild) end)
    rebuild()
end

--------------------------------------------------- ESP preview window
local Preview = { Settings = { Box = true, Name = true, HealthBar = true, Distance = true, Chams = false, BoxColor = nil, ChamsColor = Color3.fromRGB(255, 80, 80) } }
Library.Preview = Preview

local function BuildDummy()
    local model = Instance.new("Model")
    model.Name = "Dummy"
    local function part(name, size, cf, color)
        local p = Instance.new("Part")
        p.Name, p.Size, p.CFrame, p.Anchored = name, size, cf, true
        p.Color = color or Color3.fromRGB(150, 150, 150)
        p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
        p.Parent = model
        return p
    end
    local root = part("HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(0, 3, 0))
    root.Transparency = 1
    part("Head", Vector3.new(2, 1, 1), CFrame.new(0, 4.5, 0), Color3.fromRGB(240, 200, 160))
    part("Torso", Vector3.new(2, 2, 1), CFrame.new(0, 3, 0), Color3.fromRGB(40, 45, 50))
    part("Left Arm", Vector3.new(1, 2, 1), CFrame.new(-1.5, 3, 0), Color3.fromRGB(240, 200, 160))
    part("Right Arm", Vector3.new(1, 2, 1), CFrame.new(1.5, 3, 0), Color3.fromRGB(240, 200, 160))
    part("Left Leg", Vector3.new(1, 2, 1), CFrame.new(-0.5, 1, 0), Color3.fromRGB(30, 30, 35))
    part("Right Leg", Vector3.new(1, 2, 1), CFrame.new(0.5, 1, 0), Color3.fromRGB(30, 30, 35))
    model.PrimaryPart = root
    return model
end

local function CloneCharacter()
    local char = LocalPlayer.Character
    if not char then return nil end
    local old = char.Archivable
    char.Archivable = true
    local ok, clone = pcall(function() return char:Clone() end)
    char.Archivable = old
    if not ok or not clone then return nil end
    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Sound") or d:IsA("ForceField") then d:Destroy()
        elseif d:IsA("BasePart") then d.Anchored = true end
    end
    local hum = clone:FindFirstChildOfClass("Humanoid")
    if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
    return clone
end

function Window:_BuildPreview()
    local c = self.Aux.Preview.Content
    local holder = NewGroupbox(c, "Preview", { LayoutOrder = 1 })
    local row = holder:_Row(260)
    local vpf = New("ViewportFrame", { Parent = row, BackgroundColor3 = "Background", Size = UDim2.fromScale(1, 1), Ambient = Color3.fromRGB(170, 170, 170), LightColor = Color3.fromRGB(255, 255, 255), LightDirection = Vector3.new(-1, -1, -1) })
    Stroke(vpf, "Outline")
    local cam = Instance.new("Camera")
    cam.FieldOfView = 70
    cam.Parent = vpf
    vpf.CurrentCamera = cam
    local world = Instance.new("WorldModel")
    world.Parent = vpf
    local dragArea = New("TextButton", { Parent = vpf, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "", ZIndex = 2 })

    -- overlay
    local overlay = New("Frame", { Parent = vpf, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3 })
    local box = New("Frame", { Parent = overlay, BackgroundTransparency = 1, ZIndex = 3 })
    local boxStroke = Stroke(box, "Accent")
    local boxOuter = New("Frame", { Parent = box, BackgroundTransparency = 1, Position = UDim2.fromOffset(-1, -1), Size = UDim2.new(1, 2, 1, 2), ZIndex = 3 })
    Stroke(boxOuter, "OutlineDark")
    local nameL = New("TextLabel", { Parent = overlay, Text = LocalPlayer.Name, TextColor3 = "Text", TextSize = 12, AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(200, 14), TextStrokeTransparency = 0.5, ZIndex = 3 })
    local distL = New("TextLabel", { Parent = overlay, Text = "24m", TextColor3 = "SubText", TextSize = 11, AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(200, 14), TextStrokeTransparency = 0.5, ZIndex = 3 })
    local hpBg = New("Frame", { Parent = overlay, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 3 })
    local hpFill = New("Frame", { Parent = hpBg, BackgroundColor3 = Color3.fromRGB(80, 230, 120), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 1, 1, -1), Size = UDim2.new(1, -2, 0.82, -2), ZIndex = 3 })

    local opts = NewGroupbox(c, "Settings", { LayoutOrder = 2 })
    local modelDD = opts:AddDropdown("ML_PreviewModel", { Text = "Model", Values = { "Self", "Dummy" }, Default = "Dummy" })
    local fov = opts:AddSlider("ML_PreviewFOV", { Text = "Field Of View", Min = 30, Max = 110, Default = 70, Rounding = 0 })
    SaveManager.Ignore.ML_PreviewModel = true

    local yaw = math.rad(160)
    local model, origColors = nil, {}

    local function fitCamera()
        if not model then return end
        local cf, size = model:GetBoundingBox()
        local dist = (size.Y * 0.5) / math.tan(math.rad(cam.FieldOfView / 2)) * 1.35
        cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, 0, dist), cf.Position)
    end
    local function applyChams()
        if not model then return end
        for _, p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") then
                if not origColors[p] then origColors[p] = { p.Color, p.Material } end
                if Preview.Settings.Chams then
                    p.Color = Preview.Settings.ChamsColor
                    p.Material = Enum.Material.SmoothPlastic
                else
                    p.Color, p.Material = origColors[p][1], origColors[p][2]
                end
            end
        end
    end
    local function loadModel()
        if model then model:Destroy() end
        table.clear(origColors)
        model = (modelDD.Value == "Self" and CloneCharacter()) or BuildDummy()
        model.Parent = world
        if not model.PrimaryPart then model.PrimaryPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart") end
        local cf = model:GetBoundingBox()
        model:PivotTo(CFrame.Angles(0, yaw, 0) * (CFrame.new(-cf.Position) * model:GetPivot()))
        nameL.Text = (modelDD.Value == "Self") and LocalPlayer.Name or "Dummy"
        fitCamera()
        applyChams()
    end
    modelDD:OnChanged(loadModel)
    fov:OnChanged(function(v) cam.FieldOfView = v; fitCamera() end)

    local dragging, lastX
    Connect(dragArea.MouseButton1Down, function() dragging = true; lastX = UserInputService:GetMouseLocation().X end)
    Connect(UserInputService.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    Connect(UserInputService.InputChanged, function(i)
        if dragging and model and i.UserInputType == Enum.UserInputType.MouseMovement then
            local x = UserInputService:GetMouseLocation().X
            local d = (x - lastX) * 0.012
            lastX = x
            yaw += d
            model:PivotTo(CFrame.Angles(0, d, 0) * model:GetPivot())
        end
    end)

    local function project(world3)
        local p = cam.CFrame:PointToObjectSpace(world3)
        local size = vpf.AbsoluteSize
        local t = math.tan(math.rad(cam.FieldOfView / 2))
        local aspect = size.X / math.max(size.Y, 1)
        local nx = (p.X / -p.Z) / (t * aspect)
        local ny = (p.Y / -p.Z) / t
        return Vector2.new((nx + 1) / 2 * size.X, (1 - ny) / 2 * size.Y)
    end

    Connect(RunService.RenderStepped, function()
        if not self.Aux.Preview.Frame.Visible or not model then return end
        local s = Preview.Settings
        local cf, size = model:GetBoundingBox()
        local minV, maxV = Vector2.new(math.huge, math.huge), Vector2.new(-math.huge, -math.huge)
        for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
            local v = project((cf * CFrame.new(size.X / 2 * x, size.Y / 2 * y, size.Z / 2 * z)).Position)
            minV = Vector2.new(math.min(minV.X, v.X), math.min(minV.Y, v.Y))
            maxV = Vector2.new(math.max(maxV.X, v.X), math.max(maxV.Y, v.Y))
        end end end
        local w, h = maxV.X - minV.X, maxV.Y - minV.Y
        box.Visible = s.Box
        box.Position = UDim2.fromOffset(minV.X, minV.Y)
        box.Size = UDim2.fromOffset(w, h)
        boxStroke.Color = s.BoxColor or Theme.Accent
        nameL.Visible = s.Name
        nameL.Position = UDim2.fromOffset(minV.X + w / 2, minV.Y - 2)
        distL.Visible = s.Distance
        distL.Position = UDim2.fromOffset(minV.X + w / 2, maxV.Y + 2)
        hpBg.Visible = s.HealthBar
        hpBg.Position = UDim2.fromOffset(minV.X - 6, minV.Y - 1)
        hpBg.Size = UDim2.fromOffset(4, h + 2)
    end)

    function Preview:Set(key, value)
        self.Settings[key] = value
        if key == "Chams" or key == "ChamsColor" then applyChams() end
    end
    -- bind preview settings to your own Toggles/Options: Library.Preview:Bind({ Box = "EspBox", BoxColor = "EspBoxColor" })
    function Preview:Bind(map)
        for key, idx in pairs(map) do
            local obj = Toggles[idx] or Options[idx]
            if obj then
                obj:OnChanged(function(v) Preview:Set(key, v) end)
            else
                warn("[MoneyLib] Preview:Bind - no element with index " .. tostring(idx))
            end
        end
    end
    Library:OnUnload(function() if model then model:Destroy() end end)
    self.LoadPreviewModel = loadModel
    loadModel()
end

--------------------------------------------------------------------------------
-- Open / close / unload
--------------------------------------------------------------------------------
function Library:SetOpen(open)
    self.Open = open
    local W = self.Window
    if not W then return end
    if open then
        W.Frame.Visible = not W.MainHidden
        for name, aux in pairs(W.Aux) do
            if W.AuxState and W.AuxState[name] then aux.Frame.Visible = true end
        end
        W.Dock.Visible = true
    else
        W.AuxState = {}
        for name, aux in pairs(W.Aux) do
            W.AuxState[name] = aux.Frame.Visible
            aux.Frame.Visible = false
        end
        W.Frame.Visible = false
        W.Dock.Visible = false
        for i = #self.Popups, 1, -1 do self:ClosePopup(self.Popups[i].Frame) end
    end
    ModalButton.Visible = open
    WindowLayer.Visible = true
end

function Library:Toggle() self:SetOpen(not self.Open) end

function Library:OnUnload(fn) table.insert(self.UnloadCallbacks, fn) end

function Library:Unload()
    if self.Unloaded then return end
    self.Unloaded = true
    for _, fn in ipairs(self.UnloadCallbacks) do SafeCall(fn) end
    for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
    ScreenGui:Destroy()
    if genv and genv.MoneyLib == self then genv.MoneyLib = nil end
end

if genv then
    genv.MoneyLib = Library
    genv.Toggles = Toggles
    genv.Options = Options
end

return Library
