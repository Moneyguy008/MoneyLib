-- MoneyLib example
-- Executor: local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/<you>/MoneyLib/main/MoneyLib.lua"))()
-- Studio:   local Library = require(game.ReplicatedStorage.MoneyLib)
local Studio = game:GetService("ReplicatedStorage"):FindFirstChild("MoneyLib")
local Library = Studio and require(Studio)
    or loadstring(game:HttpGet("https://raw.githubusercontent.com/<you>/MoneyLib/main/MoneyLib.lua"))()

local Toggles, Options = Library.Toggles, Library.Options

local Window = Library:CreateWindow({
    Title = "MoneyLib",
    Game = "Universal",        -- shown in the watermark
    ConfigFolder = "Universal" -- workspace/MoneyLib/Universal/configs
})

----------------------------------------------------------------- Combat tab
local Combat = Window:AddTab("Combat", "crosshair")
local Aim = Combat:AddSubTab("Aim Assist")
Combat:AddSubTab("Recoil Control"):AddLeftGroupbox("Recoil"):AddSlider("RecoilStrength", { Text = "Strength", Min = 0, Max = 100, Default = 40, Suffix = "%" })
local ExampleSub = Combat:AddSubTab("Example")

local Main = Aim:AddLeftGroupbox("Main")
Main:AddToggle("AimEnabled", { Text = "Enabled", Tooltip = "Master switch" })
    :AddKeyPicker("AimKey", { Default = "MB2", Mode = "Hold", Text = "Aim Assist" })
Main:AddToggle("ClosestPart", { Text = "Use Closest Part" })
Main:AddToggle("VisCheck", { Text = "Visibility Check" })
Main:AddToggle("MovePred", { Text = "Movement Prediction" })
Main:AddToggle("TrajComp", { Text = "Trajectory Compensation" })
Main:AddDropdown("VisMode", { Text = "Visible Check Mode", Values = { "Target-Part Only", "Any Part", "All Parts" }, Default = 1 })
Main:AddSlider("HitChance", { Text = "Hit Chance", Min = 0, Max = 100, Default = 50, Suffix = "%" })

local panel = Main:AddToggle("PanelTest", { Text = "Panel Test" }):AddSettings("Panel Test")
panel:AddSlider("PanelSmooth", { Text = "Smoothing", Min = 1, Max = 20, Default = 5 })
panel:AddDropdown("PanelPart", { Text = "Part", Values = { "Head", "Torso", "Random" }, Default = "Head" })
panel:AddToggle("PanelSticky", { Text = "Sticky Target" })

Main:AddLabel("Test Label bla"):AddKeyPicker("TestKey", { Default = "None", Text = "Test Label" })
Main:AddToggle("ColorTest", { Text = "Colorpicker test" }):AddColorPicker("ColorTestColor", { Default = Color3.fromRGB(235, 40, 40), Title = "Colorpicker test" })

local Dep = Main:AddDependencyBox()
Dep:AddSlider("FOVRadius", { Text = "FOV Radius", Min = 10, Max = 500, Default = 120, Suffix = "px" })
Dep:SetupDependencies({ { Toggles.AimEnabled, true } })

local Visuals = Aim:AddRightGroupbox("Visuals")
Visuals:AddToggle("EspBox", { Text = "Box", Default = true }):AddColorPicker("EspBoxColor", { Default = Color3.fromRGB(61, 214, 140), Title = "Box Color" })
Visuals:AddToggle("EspName", { Text = "Name", Default = true })
Visuals:AddToggle("EspHealth", { Text = "Health Bar", Default = true })
Visuals:AddToggle("EspDistance", { Text = "Distance", Default = true })
Visuals:AddToggle("EspChams", { Text = "Chams" }):AddColorPicker("EspChamsColor", { Default = Color3.fromRGB(255, 80, 80), Title = "Chams Color" })
Visuals:AddButton("Example Button", function() Library:Notify({ Title = "MoneyLib", Description = "Example button pressed" }) end)
Visuals:AddInput("Testing", { Text = "Testing", Placeholder = "Enter..." })
Visuals:AddDropdown("Targets", { Text = "Player Target", SpecialType = "Player" })
Visuals:AddDropdown("Multi", { Text = "Multi Select", Values = { "Head", "Torso", "Arms", "Legs" }, Multi = true, Default = { "Head" } })

-- live ESP preview reflects these toggles
Library.Preview:Bind({ Box = "EspBox", BoxColor = "EspBoxColor", Name = "EspName", HealthBar = "EspHealth", Distance = "EspDistance", Chams = "EspChams", ChamsColor = "EspChamsColor" })

local Ex = ExampleSub:AddLeftGroupbox("Elements")
Ex:AddLabel("This is a wrapping label that explains something longer than a single line.", true)
Ex:AddDivider()
Ex:AddButton({ Text = "Left", Func = function() print("left") end }):AddButton({ Text = "Right", Func = function() print("right") end })
Ex:AddButton({ Text = "Risky (double click)", DoubleClick = true, Func = function() Library:Notify("Confirmed!") end })
Ex:AddToggle("RiskyToggle", { Text = "Risky Feature", Risky = true })
Ex:AddSlider("Compact", { Text = "Compact", Min = 0, Max = 10, Default = 3, Rounding = 1, Compact = true })

----------------------------------------------------------------- Misc tab
local Misc = Window:AddTab("Misc", "layers")
local Movement = Misc:AddLeftGroupbox("Movement")
Movement:AddToggle("SpeedToggle", { Text = "Walkspeed" }):AddKeyPicker("SpeedKey", { Default = "X", Mode = "Toggle", Text = "Walkspeed", SyncToggleState = true })
Movement:AddSlider("SpeedValue", { Text = "Speed", Min = 16, Max = 100, Default = 24 })

-- reading values
Toggles.AimEnabled:OnChanged(function(v) print("Aim enabled:", v) end)
Options.HitChance:OnChanged(function(v) print("Hit chance:", v) end)

Library:Notify({ Title = "MoneyLib", Description = "Loaded. Press RightShift to toggle the menu." })
Library.SaveManager:LoadAutoloadConfig()
