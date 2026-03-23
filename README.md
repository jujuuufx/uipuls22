# Pulse 3 UI Library Docs

A lightweight, clean UI library for Roblox scripts. 

## Loading the Library

First, you need to load the library in your script:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/jujuuufx/uipuls22/refs/heads/main/ui.lua"))()
```

## Creating a Window

This is the main container for your UI.

```lua
local Window = Library:Window({
    Title = "Pulse",     -- The main title
    Subtitle = ".cc",    -- The smaller text (optional)
    Size = UDim2.fromOffset(700, 450), -- Default size
    Watermark = "my custom text!" -- Either set to a string for custom text, true for default, or false to hide
})
```

## Tabs & SubTabs

Pulse 3 organizes your content into **Tabs** (sidebar icons) and **SubTabs** (horizontal buttons at the top).

```lua
-- Create a main tab on the sidebar (Uses Roblox Asset IDs for icons)
local MainTab = Window:Tab({ Name = "Main", Icon = "rbxassetid://13110298032" })

-- Add sub-tabs to the top bar
local LegitSub = MainTab:SubTab({ Name = "Legit" })
local VisualsSub = MainTab:SubTab({ Name = "Visuals" })
local MiscSub = MainTab:SubTab({ Name = "Misc" })
```

## Sections

Every SubTab needs sections to hold elements. You can put sections on the `Left` or `Right` side.

```lua
local AimbotSection = LegitSub:Section({ Name = "Aimbot Settings", Side = "Left" })
local ChamsSection = VisualsSub:Section({ Name = "Chams", Side = "Right" })
```

## Elements

Here are all the elements you can add inside a section.

### Toggles & Checkboxes
```lua
AimbotSection:Toggle({
    Name = "Enable Aimbot",
    Flag = "AimbotEnabled", -- Used for configs
    Default = false,
    Callback = function(state)
        print("Aimbot is now:", state)
    end
})

AimbotSection:Checkbox({
    Name = "Visible Check",
    Default = true,
    Callback = function(state)
        print("Visible check:", state)
    end
})
```

### Sliders
```lua
AimbotSection:Slider({
    Name = "Smoothing",
    Min = 1,
    Max = 100,
    Default = 50,
    Increment = 1,
    Suffix = "%",  -- Optional
    Callback = function(value)
        print("Smoothing set to", value)
    end
})
```

### Dropdowns
```lua
AimbotSection:Dropdown({
    Name = "Hitbox",
    Options = {"Head", "Torso", "Arms", "Legs"},
    Default = "Head",
    Callback = function(selected)
        print("Targeting:", selected)
    end
})
```

### Keybinds
```lua
AimbotSection:Keybind({
    Name = "Aimbot Key",
    Default = Enum.KeyCode.E,
    Callback = function(key)
        print("Aimbot bounds to:", key.Name)
    end
})
```

### Pickers & Textboxes
```lua
ChamsSection:Colorpicker({
    Name = "Chams Color",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        print("Color changed")
    end
})

MiscSub:Section({ Name = "Settings", Side = "Left" }):Textbox({
    Name = "Custom Walkspeed",
    Placeholder = "Enter speed...",
    Numeric = true,
    Callback = function(text)
        print("Walkspeed:", text)
    end
})
```

### Buttons & Labels
```lua
MiscSub:Section({ Name = "Actions", Side = "Left" }):Button({
    Name = "Unload Script",
    Callback = function()
        print("Unloading...")
    end
})

MiscSub:Section({ Name = "Info", Side = "Left" }):Label({
    Name = "Made by you"
})
```

## Configs & UI Control

To toggle the UI menu open and closed normally (or programmatically):

```lua
Window.ToggleMenu() -- Hides/Shows the UI
```

That's it. Keep the sections balanced between Left and Right sides so the UI looks clean.
