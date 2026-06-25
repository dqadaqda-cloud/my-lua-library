--[[
    Hyperion UI Library
    Version: 1.0.0
    Inspired by Material You & FluentPlus
]]

local Hyperion = {}
Hyperion.__index = Hyperion

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local isMobile = table.find({Enum.Platform.IOS, Enum.Platform.Android}, UserInputService:GetPlatform()) ~= nil

local function hexToRgb(hex)
    local r = tonumber(hex:sub(2,3), 16) or 255
    local g = tonumber(hex:sub(4,5), 16) or 255
    local b = tonumber(hex:sub(6,7), 16) or 255
    return Color3.fromRGB(r, g, b)
end

local function rgbToHex(c)
    return string.format("#%02X%02X%02X", c.R*255, c.G*255, c.B*255)
end

local function getContrastColor(c)
    local lum = (0.299 * c.R + 0.587 * c.G + 0.114 * c.B) / 255
    return lum > 0.5 and Color3.fromRGB(0,0,0) or Color3.fromRGB(255,255,255)
end

local function adjustBrightness(c, percent)
    local factor = 1 + percent / 100
    return Color3.new(
        math.clamp(c.R * factor, 0, 1),
        math.clamp(c.G * factor, 0, 1),
        math.clamp(c.B * factor, 0, 1)
    )
end

local function createMotor(initial)
    local state = { value = initial, velocity = 0 }
    local goal = initial
    local frequency = 6
    local damping = 1
    
    local function step(dt)
        if math.abs(state.value - goal) < 0.001 and math.abs(state.velocity) < 0.001 then
            state.value = goal
            state.velocity = 0
            return true
        end
        
        local d = damping
        local f = frequency * 2 * math.pi
        local g = goal
        local p0 = state.value
        local v0 = state.velocity
        
        local offset = p0 - g
        local decay = math.exp(-d * f * dt)
        
        if d == 1 then
            state.value = (offset * (1 + f * dt) + v0 * dt) * decay + g
            state.velocity = (v0 * (1 - f * dt) - offset * (f * f * dt)) * decay
        else
            local c = math.sqrt(1 - d * d)
            local i = math.cos(f * c * dt)
            local j = math.sin(f * c * dt)
            local z = j / c
            local y = j / (f * c)
            state.value = (offset * (i + d * z) + v0 * y) * decay + g
            state.velocity = (v0 * (i - z * d) - offset * (z * f)) * decay
        end
        
        return math.abs(state.value - goal) < 0.001 and math.abs(state.velocity) < 0.001
    end
    
    local function setGoal(newGoal)
        goal = newGoal
    end
    
    return {
        step = step,
        getValue = function() return state.value end,
        setGoal = setGoal,
        getState = function() return state end,
    }
end

local Themes = {
    Default = {
        name = "Default",
        primary = Color3.fromRGB(187, 134, 252),
        surface = Color3.fromRGB(30, 30, 30),
        surfaceContainer = Color3.fromRGB(43, 43, 43),
        surfaceVariant = Color3.fromRGB(58, 58, 58),
        onSurface = Color3.fromRGB(227, 227, 227),
        onSurfaceVariant = Color3.fromRGB(160, 160, 160),
        outline = Color3.fromRGB(94, 94, 94),
        outlineVariant = Color3.fromRGB(58, 58, 58),
    },
    Red = {
        name = "Red",
        primary = Color3.fromRGB(244, 67, 54),
        surface = Color3.fromRGB(30, 30, 30),
        surfaceContainer = Color3.fromRGB(43, 43, 43),
        surfaceVariant = Color3.fromRGB(58, 58, 58),
        onSurface = Color3.fromRGB(227, 227, 227),
        onSurfaceVariant = Color3.fromRGB(160, 160, 160),
        outline = Color3.fromRGB(94, 94, 94),
        outlineVariant = Color3.fromRGB(58, 58, 58),
    },
    Orange = {
        name = "Orange",
        primary = Color3.fromRGB(255, 152, 0),
        surface = Color3.fromRGB(30, 30, 30),
        surfaceContainer = Color3.fromRGB(43, 43, 43),
        surfaceVariant = Color3.fromRGB(58, 58, 58),
        onSurface = Color3.fromRGB(227, 227, 227),
        onSurfaceVariant = Color3.fromRGB(160, 160, 160),
        outline = Color3.fromRGB(94, 94, 94),
        outlineVariant = Color3.fromRGB(58, 58, 58),
    },
    Yellow = {
        name = "Yellow",
        primary = Color3.fromRGB(255, 235, 59),
        surface = Color3.fromRGB(30, 30, 30),
        surfaceContainer = Color3.fromRGB(43, 43, 43),
        surfaceVariant = Color3.fromRGB(58, 58, 58),
        onSurface = Color3.fromRGB(227, 227, 227),
        onSurfaceVariant = Color3.fromRGB(160, 160, 160),
        outline = Color3.fromRGB(94, 94, 94),
        outlineVariant = Color3.fromRGB(58, 58, 58),
    },
    Green = {
        name = "Green",
        primary = Color3.fromRGB(76, 175, 80),
        surface = Color3.fromRGB(30, 30, 30),
        surfaceContainer = Color3.fromRGB(43, 43, 43),
        surfaceVariant = Color3.fromRGB(58, 58, 58),
        onSurface = Color3.fromRGB(227, 227, 227),
        onSurfaceVariant = Color3.fromRGB(160, 160, 160),
        outline = Color3.fromRGB(94, 94, 94),
        outlineVariant = Color3.fromRGB(58, 58, 58),
    },
    Teal = {
        name = "Teal",
        primary = Color3.fromRGB(0, 150, 136),
        surface = Color3.fromRGB(30, 30, 30),
        surfaceContainer = Color3.fromRGB(43, 43, 43),
        surfaceVariant = Color3.fromRGB(58, 58, 58),
        onSurface = Color3.fromRGB(227, 227, 227),
        onSurfaceVariant = Color3.fromRGB(160, 160, 160),
        outline = Color3.fromRGB(94, 94, 94),
        outlineVariant = Color3.fromRGB(58, 58, 58),
    },
    Blue = {
        name = "Blue",
        primary = Color3.fromRGB(33, 150, 243),
        surface = Color3.fromRGB(30, 30, 30),
        surfaceContainer = Color3.fromRGB(43, 43, 43),
        surfaceVariant = Color3.fromRGB(58, 58, 58),
        onSurface = Color3.fromRGB(227, 227, 227),
        onSurfaceVariant = Color3.fromRGB(160, 160, 160),
        outline = Color3.fromRGB(94, 94, 94),
        outlineVariant = Color3.fromRGB(58, 58, 58),
    },
    Pink = {
        name = "Pink",
        primary = Color3.fromRGB(233, 30, 99),
        surface = Color3.fromRGB(30, 30, 30),
        surfaceContainer = Color3.fromRGB(43, 43, 43),
        surfaceVariant = Color3.fromRGB(58, 58, 58),
        onSurface = Color3.fromRGB(227, 227, 227),
        onSurfaceVariant = Color3.fromRGB(160, 160, 160),
        outline = Color3.fromRGB(94, 94, 94),
        outlineVariant = Color3.fromRGB(58, 58, 58),
    },
}

local function createUIElement(className, properties, children)
    local obj = Instance.new(className)
    for k, v in pairs(properties or {}) do
        obj[k] = v
    end
    for _, child in pairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

local function createRipple(parent, color)
    local ripple = createUIElement("Frame", {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = color or Color3.fromRGB(255,255,255),
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        ZIndex = 999,
    }, {
        createUIElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
    })
    ripple.Parent = parent
    return ripple
end

local function animateRipple(ripple, size)
    local tween = TweenService:Create(ripple, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, size, 0, size),
        BackgroundTransparency = 1,
    })
    tween:Play()
    tween.Completed:Connect(function()
        ripple:Destroy()
    end)
end

local HyperionWindow = {}
HyperionWindow.__index = HyperionWindow

function HyperionWindow.new(config)
    local self = setmetatable({}, HyperionWindow)
    
    self.title = config.Title or "Hyperion"
    self.size = config.Size or UDim2.new(0, 600, 0, 450)
    self.theme = Themes[config.Theme] or Themes.Default
    self.acrylic = config.Acrylic or false
    self.minimized = false
    self.tabs = {}
    self.activeTab = nil
    self.elements = {}
    self.log = {}
    
    self.gui = createUIElement("ScreenGui", {
        Parent = LocalPlayer:WaitForChild("PlayerGui"),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    if syn and syn.protect_gui then syn.protect_gui(self.gui) end
    
    self.root = createUIElement("Frame", {
        Parent = self.gui,
        Size = self.size,
        Position = UDim2.new(0.5, -self.size.X.Offset/2, 0.5, -self.size.Y.Offset/2),
        BackgroundColor3 = self.theme.surface,
        BackgroundTransparency = self.acrylic and 0.15 or 0,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, {
        createUIElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
        createUIElement("UIStroke", {
            Color = self.theme.outlineVariant,
            Transparency = 0.5,
            Thickness = 1,
        }),
    })
    
    if self.acrylic then
        local blur = createUIElement("Frame", {
            Parent = self.root,
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(255,255,255),
            BackgroundTransparency = 0.98,
            BorderSizePixel = 0,
        }, {
            createUIElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
        })
        self.blur = blur
    end
    
    self.titleBar = createUIElement("Frame", {
        Parent = self.root,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
    }, {
        createUIElement("TextLabel", {
            Text = self.title,
            TextColor3 = self.theme.onSurface,
            TextSize = 16,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -100, 1, 0),
        }),
        createUIElement("TextButton", {
            Text = "✕",
            TextColor3 = self.theme.onSurfaceVariant,
            TextSize = 16,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -36, 0, 4),
            Size = UDim2.new(0, 28, 0, 32),
            Font = Enum.Font.Gotham,
            ZIndex = 2,
        }, {
            createUIElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
        }),
        createUIElement("TextButton", {
            Text = "—",
            TextColor3 = self.theme.onSurfaceVariant,
            TextSize = 20,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -68, 0, 4),
            Size = UDim2.new(0, 28, 0, 32),
            Font = Enum.Font.Gotham,
            ZIndex = 2,
        }, {
            createUIElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
        }),
        createUIElement("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = self.theme.outlineVariant,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
        }),
    })
    
    self.tabContainer = createUIElement("Frame", {
        Parent = self.root,
        Size = UDim2.new(0, 160, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, {
        createUIElement("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
        createUIElement("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
        }),
    })
    
    self.contentContainer = createUIElement("Frame", {
        Parent = self.root,
        Size = UDim2.new(1, -180, 1, -60),
        Position = UDim2.new(0, 172, 0, 52),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    })
    
    self.content = createUIElement("ScrollingFrame", {
        Parent = self.contentContainer,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.theme.outline,
        ScrollBarImageTransparency = 0.5,
    }, {
        createUIElement("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
        createUIElement("UIPadding", {
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
        }),
    })
    
    self.logger = createUIElement("Frame", {
        Parent = self.root,
        Size = UDim2.new(0, 400, 0, 200),
        Position = UDim2.new(0.5, -200, 0.5, -100),
        BackgroundColor3 = self.theme.surfaceContainer,
        BackgroundTransparency = 0.05,
        Visible = false,
        ZIndex = 100,
    }, {
        createUIElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
        createUIElement("UIStroke", {
            Color = self.theme.outlineVariant,
            Transparency = 0.5,
            Thickness = 1,
        }),
        createUIElement("TextLabel", {
            Text = "📋 Log",
            TextColor3 = self.theme.onSurface,
            TextSize = 16,
            Font = Enum.Font.Gotham,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 8),
            Size = UDim2.new(1, -24, 0, 24),
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
        createUIElement("TextButton", {
            Text = "✕",
            TextColor3 = self.theme.onSurfaceVariant,
            TextSize = 16,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -36, 0, 4),
            Size = UDim2.new(0, 28, 0, 32),
            Font = Enum.Font.Gotham,
            ZIndex = 2,
        }),
        createUIElement("ScrollingFrame", {
            Parent = self.root,
            Size = UDim2.new(1, -24, 1, -60),
            Position = UDim2.new(0, 12, 0, 40),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = self.theme.outline,
            ScrollBarImageTransparency = 0.5,
        }, {
            createUIElement("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        }),
        createUIElement("TextButton", {
            Text = "Copy",
            TextColor3 = self.theme.onPrimary,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            BackgroundColor3 = self.theme.primary,
            Position = UDim2.new(1, -80, 1, -36),
            Size = UDim2.new(0, 64, 0, 28),
        }, {
            createUIElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
        }),
        createUIElement("TextButton", {
            Text = "Clear",
            TextColor3 = self.theme.onSurface,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            BackgroundColor3 = self.theme.surfaceVariant,
            Position = UDim2.new(1, -152, 1, -36),
            Size = UDim2.new(0, 64, 0, 28),
        }, {
            createUIElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
        }),
    })
    
    self.dragging = false
    self.dragStart = nil
    self.dragOffset = nil
    
    self.titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.dragging = true
            self.dragStart = input.Position
            self.dragOffset = self.root.Position
        end
    end)
    
    self.titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.dragging = false
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if self.dragging and self.dragStart and self.dragOffset then
            local delta = Mouse.X - self.dragStart.X, Mouse.Y - self.dragStart.Y
            self.root.Position = UDim2.new(0, self.dragOffset.X.Offset + delta, 0, self.dragOffset.Y.Offset + delta)
        end
    end)
    
    local closeBtn = self.titleBar:FindFirstChildOfClass("TextButton")
    if closeBtn then
        closeBtn.MouseButton1Click:Connect(function()
            self:destroy()
        end)
    end
    
    local minBtn = self.titleBar:FindLastChild("TextButton")
    if minBtn then
        minBtn.MouseButton1Click:Connect(function()
            self.minimized = not self.minimized
            self.root.Visible = not self.minimized
        end)
    end
    
    self:addLog("Window created: " .. self.title)
    
    return self
end

function HyperionWindow:setTheme(themeName)
    local theme = Themes[themeName]
    if not theme then return end
    self.theme = theme
    self.root.BackgroundColor3 = theme.surface
    for _, child in pairs(self.root:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            if child.Name ~= "Title" and child.Name ~= "Desc" then
                if child.TextColor3 == self.theme.onSurface then
                    child.TextColor3 = theme.onSurface
                elseif child.TextColor3 == self.theme.onSurfaceVariant then
                    child.TextColor3 = theme.onSurfaceVariant
                end
            end
        end
        if child:IsA("Frame") and child.BackgroundColor3 == self.theme.surfaceContainer then
            child.BackgroundColor3 = theme.surfaceContainer
        end
        if child:IsA("UIStroke") then
            child.Color = theme.outlineVariant
        end
    end
    self:addLog("Theme changed to: " .. theme.name)
end

function HyperionWindow:addTab(name, icon)
    local tab = {}
    tab.name = name
    tab.icon = icon
    tab.elements = {}
    tab.sections = {}
    
    local btn = createUIElement("TextButton", {
        Parent = self.tabContainer,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = self.theme.surfaceContainer,
        BackgroundTransparency = 0.9,
        Text = "",
        ZIndex = 2,
    }, {
        createUIElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
        createUIElement("TextLabel", {
            Text = name,
            TextColor3 = self.theme.onSurfaceVariant,
            TextSize = 13,
            Font = Enum.Font.Gotham,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -24, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            Name = "Title",
        }),
        createUIElement("Frame", {
            Size = UDim2.new(0, 3, 0, 20),
            Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = self.theme.primary,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Name = "Indicator",
        }, {
            createUIElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
        }),
    })
    
    local container = createUIElement("ScrollingFrame", {
        Parent = self.content,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.theme.outline,
        ScrollBarImageTransparency = 0.5,
        Visible = false,
    }, {
        createUIElement("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
        createUIElement("UIPadding", {
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
        }),
    })
    
    tab.btn = btn
    tab.container = container
    
    btn.MouseButton1Click:Connect(function()
        self:selectTab(tab)
    end)
    
    if #self.tabs == 0 then
        self:selectTab(tab)
    end
    
    table.insert(self.tabs, tab)
    self:addLog("Tab added: " .. name)
    
    local tabApi = {}
    
    function tabApi:addSection(title)
        local section = {}
        section.title = title
        section.elements = {}
        
        local header = createUIElement("TextLabel", {
            Parent = container,
            Text = title,
            TextColor3 = self.theme.onSurface,
            TextSize = 18,
            Font = Enum.Font.GothamBold,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 28),
            TextXAlignment = Enum.TextXAlignment.Left,
            Name = "SectionHeader",
        })
        
        local frame = createUIElement("Frame", {
            Parent = container,
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
        }, {
            createUIElement("UIListLayout", {
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        
        section.frame = frame
        section.header = header
        
        local function addElement(elementType, config)
            local element = {}
            
            local bg = createUIElement("Frame", {
                Parent = frame,
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = self.theme.surfaceContainer,
                BackgroundTransparency = 0.9,
                AutomaticSize = Enum.AutomaticSize.Y,
                BorderSizePixel = 0,
            }, {
                createUIElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
                createUIElement("UIStroke", {
                    Color = self.theme.outlineVariant,
                    Transparency = 0.5,
                    Thickness = 1,
                }),
                createUIElement("UIPadding", {
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                    PaddingTop = UDim.new(0, 10),
                    PaddingBottom = UDim.new(0, 10),
                }),
            })
            
            local headerFrame = createUIElement("Frame", {
                Parent = bg,
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
            }, {
                createUIElement("UIListLayout", {
                    Padding = UDim.new(0, 8),
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                }),
            })
            
            if config.Icon then
                local iconLabel = createUIElement("TextLabel", {
                    Parent = headerFrame,
                    Text = config.Icon,
                    TextColor3 = self.theme.primary,
                    TextSize = 18,
                    Font = Enum.Font.Gotham,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 24, 0, 24),
                    TextXAlignment = Enum.TextXAlignment.Center,
                })
                element.icon = iconLabel
            end
            
            local titleLabel = createUIElement("TextLabel", {
                Parent = headerFrame,
                Text = config.Title or "Element",
                TextColor3 = self.theme.onSurface,
                TextSize = 14,
                Font = Enum.Font.Gotham,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 0, 24),
                AutomaticSize = Enum.AutomaticSize.X,
                TextXAlignment = Enum.TextXAlignment.Left,
                Name = "Title",
            })
            element.titleLabel = titleLabel
            
            if config.Description then
                local descLabel = createUIElement("TextLabel", {
                    Parent = bg,
                    Text = config.Description,
                    TextColor3 = self.theme.onSurfaceVariant,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Name = "Desc",
                })
                element.descLabel = descLabel
            end
            
            local controlFrame = createUIElement("Frame", {
                Parent = bg,
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(1, 0, 0, 0),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.XY,
            })
            element.control = controlFrame
            
            local function updateLayout()
                local totalHeight = 24
                if config.Description then totalHeight = totalHeight + 18 end
                local controlHeight = 24
                if controlFrame.Size.Y.Offset > 24 then controlHeight = controlFrame.Size.Y.Offset end
                if controlHeight > totalHeight then totalHeight = controlHeight end
                bg.Size = UDim2.new(1, 0, 0, totalHeight + 20)
            end
            
            bg:GetPropertyChangedSignal("Size"):Connect(updateLayout)
            task.wait()
            updateLayout()
            
            local elementApi = {}
            
            elementApi.setTitle = function(text)
                titleLabel.Text = text
            end
            
            elementApi.setDesc = function(text)
                if descLabel then
                    descLabel.Text = text
                end
            end
            
            elementApi.setVisible = function(visible)
                bg.Visible = visible
            end
            
            elementApi.destroy = function()
                bg:Destroy()
            end
            
            table.insert(section.elements, elementApi)
            self:addLog("Element added: " .. config.Title)
            
            return elementApi
        end
        
        function section:addButton(config)
            local btn = addElement("Button", config)
            
            local button = createUIElement("TextButton", {
                Parent = btn.control,
                Text = config.Text or "Click",
                TextColor3 = self.theme.onPrimary,
                TextSize = 13,
                Font = Enum.Font.Gotham,
                BackgroundColor3 = self.theme.primary,
                Size = UDim2.new(0, 80, 0, 28),
                Position = UDim2.new(0, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                AutomaticSize = Enum.AutomaticSize.X,
            }, {
                createUIElement("UIPadding", {
                    PaddingLeft = UDim.new(0, 16),
                    PaddingRight = UDim.new(0, 16),
                }),
                createUIElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
            })
            
            btn.control.Size = UDim2.new(0, 0, 0, 28)
            
            button.MouseButton1Click:Connect(function()
                if config.Callback then
                    config.Callback()
                end
                local ripple = createRipple(button, self.theme.primary)
                local size = button.AbsoluteSize.X * 1.5
                animateRipple(ripple, size)
                self:addLog("Button clicked: " .. config.Title)
            end)
            
            return btn
        end
        
        function section:addToggle(config)
            local toggle = addElement("Toggle", config)
            toggle.value = config.Default or false
            
            local frame = createUIElement("Frame", {
                Parent = toggle.control,
                Size = UDim2.new(0, 44, 0, 22),
                Position = UDim2.new(0, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = self.theme.outlineVariant,
                BackgroundTransparency = 0.3,
            }, {
                createUIElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
                createUIElement("Frame", {
                    Name = "Thumb",
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = UDim2.new(0, 2, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = self.theme.onSurface,
                    BackgroundTransparency = 0.8,
                }, {
                    createUIElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
                }),
            })
            
            toggle.control.Size = UDim2.new(0, 44, 0, 22)
            
            local thumb = frame:FindFirstChild("Thumb")
            
            function toggle:setValue(value)
                self.value = value
                local targetPos = value and UDim2.new(0, 24, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                local targetColor = value and self.theme.primary or self.theme.outlineVariant
                TweenService:Create(thumb, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = targetPos,
                }):Play()
                TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = targetColor,
                }):Play()
                if config.Callback then
                    config.Callback(value)
                end
                self:addLog("Toggle changed: " .. config.Title .. " = " .. tostring(value))
            end
            
            frame.MouseButton1Click:Connect(function()
                toggle:setValue(not toggle.value)
            end)
            
            toggle:setValue(toggle.value)
            
            return toggle
        end
        
        function section:addSlider(config)
            local slider = addElement("Slider", config)
            slider.value = config.Default or 0
            slider.min = config.Min or 0
            slider.max = config.Max or 100
            slider.rounding = config.Rounding or 0
            
            local frame = createUIElement("Frame", {
                Parent = slider.control,
                Size = UDim2.new(0, 120, 0, 28),
                Position = UDim2.new(0, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
            }, {
                createUIElement("Frame", {
                    Name = "Rail",
                    Size = UDim2.new(1, 0, 0, 4),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = self.theme.outlineVariant,
                    BackgroundTransparency = 0.3,
                }, {
                    createUIElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    createUIElement("Frame", {
                        Name = "Fill",
                        Size = UDim2.new(0, 0, 1, 0),
                        BackgroundColor3 = self.theme.primary,
                        BorderSizePixel = 0,
                    }, {
                        createUIElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    }),
                }),
                createUIElement("TextButton", {
                    Name = "Thumb",
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = self.theme.primary,
                    BackgroundTransparency = 0.2,
                    ZIndex = 2,
                    AutoButtonColor = false,
                }, {
                    createUIElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    createUIElement("UIStroke", {
                        Color = self.theme.primary,
                        Transparency = 0.5,
                        Thickness = 2,
                    }),
                }),
                createUIElement("TextLabel", {
                    Name = "ValueLabel",
                    Text = tostring(slider.value),
                    TextColor3 = self.theme.onSurfaceVariant,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, 8, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0, 40, 0, 20),
                    TextXAlignment = Enum.TextXAlignment.Left,
                }),
            })
            
            slider.control.Size = UDim2.new(0, 120, 0, 28)
            
            local rail = frame:FindFirstChild("Rail")
            local fill = rail and rail:FindFirstChild("Fill")
            local thumb = frame:FindFirstChild("Thumb")
            local valueLabel = frame:FindFirstChild("ValueLabel")
            
            local function updateSlider(value)
                local clamped = math.clamp(value, slider.min, slider.max)
                local rounded = math.round(clamped * 10 ^ slider.rounding) / 10 ^ slider.rounding
                slider.value = rounded
                local t = (rounded - slider.min) / (slider.max - slider.min)
                if fill then
                    fill.Size = UDim2.new(t, 0, 1, 0)
                end
                if thumb then
                    thumb.Position = UDim2.new(t, -8, 0.5, 0)
                end
                if valueLabel then
                    valueLabel.Text = tostring(rounded)
                end
                if config.Callback then
                    config.Callback(rounded)
                end
                self:addLog("Slider changed: " .. config.Title .. " = " .. tostring(rounded))
            end
            
            local dragging = false
            
            thumb.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                end
            end)
            
            thumb.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            
            frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    local pos = input.Position.X - rail.AbsolutePosition.X
                    local t = math.clamp(pos / rail.AbsoluteSize.X, 0, 1)
                    local val = slider.min + (slider.max - slider.min) * t
                    updateSlider(val)
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local pos = input.Position.X - rail.AbsolutePosition.X
                    local t = math.clamp(pos / rail.AbsoluteSize.X, 0, 1)
                    local val = slider.min + (slider.max - slider.min) * t
                    updateSlider(val)
                end
            end)
            
            updateSlider(slider.value)
            
            function slider:setValue(value)
                updateSlider(value)
            end
            
            return slider
        end
        
        function section:addDropdown(config)
            local dropdown = addElement("Dropdown", config)
            dropdown.values = config.Values or {}
            dropdown.value = config.Default or nil
            
            local frame = createUIElement("Frame", {
                Parent = dropdown.control,
                Size = UDim2.new(0, 140, 0, 28),
                Position = UDim2.new(0, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
            })
            
            dropdown.control.Size = UDim2.new(0, 140, 0, 28)
            
            local btn = createUIElement("TextButton", {
                Parent = frame,
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = self.theme.surfaceVariant,
                BackgroundTransparency = 0.8,
                Text = "",
                AutoButtonColor = false,
            }, {
                createUIElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
                createUIElement("UIStroke", {
                    Color = self.theme.outlineVariant,
                    Transparency = 0.5,
                    Thickness = 1,
                }),
                createUIElement("TextLabel", {
                    Name = "Display",
                    Text = config.Default or "Select...",
                    TextColor3 = self.theme.onSurface,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 8, 0, 0),
                    Size = UDim2.new(1, -32, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                }),
                createUIElement("TextLabel", {
                    Text = "▼",
                    TextColor3 = self.theme.onSurfaceVariant,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -20, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0, 16, 0, 16),
                    TextXAlignment = Enum.TextXAlignment.Center,
                }),
            })
            
            local dropdownFrame = createUIElement("Frame", {
                Parent = self.root,
                Size = UDim2.new(0, 140, 0, 0),
                BackgroundColor3 = self.theme.surface,
                BackgroundTransparency = 0.05,
                Visible = false,
                ZIndex = 50,
                ClipsDescendants = true,
            }, {
                createUIElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
                createUIElement("UIStroke", {
                    Color = self.theme.outlineVariant,
                    Transparency = 0.5,
                    Thickness = 1,
                }),
                createUIElement("ScrollingFrame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 0,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                }, {
                    createUIElement("UIListLayout", {
                        Padding = UDim.new(0, 2),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    }),
                    createUIElement("UIPadding", {
                        PaddingLeft = UDim.new(0, 4),
                        PaddingRight = UDim.new(0, 4),
                        PaddingTop = UDim.new(0, 4),
                        PaddingBottom = UDim.new(0, 4),
                    }),
                }),
            })
            
            local display = btn:FindFirstChild("Display")
            
            local function updateDropdown(value)
                dropdown.value = value
                if display then
                    display.Text = value or "Select..."
                end
                if config.Callback then
                    config.Callback(value)
                end
                self:addLog("Dropdown changed: " .. config.Title .. " = " .. tostring(value))
            end
            
            local function buildOptions()
                local scroll = dropdownFrame:FindFirstChildOfClass("ScrollingFrame")
                if scroll then
                    for _, child in pairs(scroll:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end
                    for _, value in pairs(dropdown.values) do
                        local opt = createUIElement("TextButton", {
                            Parent = scroll,
                            Size = UDim2.new(1, 0, 0, 28),
                            BackgroundColor3 = self.theme.surfaceContainer,
                            BackgroundTransparency = 0.9,
                            Text = value,
                            TextColor3 = self.theme.onSurface,
                            TextSize = 12,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                        }, {
                            createUIElement("UIPadding", {
                                PaddingLeft = UDim.new(0, 8),
                            }),
                            createUIElement("UICorner", { CornerRadius = UDim.new(0, 4) }),
                        })
                        opt.MouseButton1Click:Connect(function()
                            updateDropdown(value)
                            dropdownFrame.Visible = false
                        end)
                    end
                end
            end
            
            btn.MouseButton1Click:Connect(function()
                dropdownFrame.Visible = not dropdownFrame.Visible
                if dropdownFrame.Visible then
                    local pos = btn.AbsolutePosition
                    local size = btn.AbsoluteSize
                    local maxHeight = 200
                    local totalHeight = #dropdown.values * 30 + 8
                    local height = math.min(totalHeight, maxHeight)
                    dropdownFrame.Position = UDim2.new(0, pos.X, 0, pos.Y + size.Y + 2)
                    dropdownFrame.Size = UDim2.new(0, size.X, 0, height)
                    buildOptions()
                    self:addLog("Dropdown opened: " .. config.Title)
                else
                    self:addLog("Dropdown closed: " .. config.Title)
                end
            end)
            
            updateDropdown(dropdown.value)
            
            function dropdown:setValue(value)
                updateDropdown(value)
            end
            
            return dropdown
        end
        
        function section:addKeybind(config)
            local keybind = addElement("Keybind", config)
            keybind.value = config.Default or "None"
            
            local btn = createUIElement("TextButton", {
                Parent = keybind.control,
                Size = UDim2.new(0, 80, 0, 28),
                Position = UDim2.new(0, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = self.theme.surfaceVariant,
                BackgroundTransparency = 0.8,
                Text = keybind.value,
                TextColor3 = self.theme.onSurface,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                AutoButtonColor = false,
            }, {
                createUIElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
                createUIElement("UIStroke", {
                    Color = self.theme.outlineVariant,
                    Transparency = 0.5,
                    Thickness = 1,
                }),
                createUIElement("UIPadding", {
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                }),
            })
            
            keybind.control.Size = UDim2.new(0, 0, 0, 28)
            
            local picking = false
            
            btn.MouseButton1Click:Connect(function()
                picking = true
                btn.Text = "..."
                self:addLog("Keybind picking: " .. config.Title)
            end)
            
            UserInputService.InputBegan:Connect(function(input)
                if picking then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local key = input.KeyCode.Name
                        keybind.value = key
                        btn.Text = key
                        picking = false
                        if config.Callback then
                            config.Callback(key)
                        end
                        self:addLog("Keybind set: " .. config.Title .. " = " .. key)
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        keybind.value = "MouseLeft"
                        btn.Text = "MouseLeft"
                        picking = false
                        if config.Callback then
                            config.Callback("MouseLeft")
                        end
                        self:addLog("Keybind set: " .. config.Title .. " = MouseLeft")
                    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                        keybind.value = "MouseRight"
                        btn.Text = "MouseRight"
                        picking = false
                        if config.Callback then
                            config.Callback("MouseRight")
                        end
                        self:addLog("Keybind set: " .. config.Title .. " = MouseRight")
                    end
                end
            end)
            
            function keybind:setValue(value)
                keybind.value = value
                btn.Text = value
            end
            
            return keybind
        end
        
        function section:addColorpicker(config)
            local colorpicker = addElement("Colorpicker", config)
            colorpicker.value = config.Default or Color3.fromRGB(255,255,255)
            colorpicker.transparency = config.Transparency or 0
            
            local frame = createUIElement("Frame", {
                Parent = colorpicker.control,
                Size = UDim2.new(0, 28, 0, 28),
                Position = UDim2.new(0, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                ZIndex = 2,
            })
            
            colorpicker.control.Size = UDim2.new(0, 28, 0, 28)
            
            local preview = createUIElement("Frame", {
                Parent = frame,
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = colorpicker.value,
                BackgroundTransparency = colorpicker.transparency,
                ZIndex = 2,
            }, {
                createUIElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
                createUIElement("UIStroke", {
                    Color = self.theme.outlineVariant,
                    Transparency = 0.5,
                    Thickness = 1,
                }),
            })
            
            local function openPicker()
                local dialog = self:createDialog("Color Picker")
                local hue = 0
                local sat = 1
                local val = 1
                local trans = colorpicker.transparency
                
                local function updatePreview()
                    local c = Color3.fromHSV(hue, sat, val)
                    preview.BackgroundColor3 = c
                    preview.BackgroundTransparency = trans
                end
                
                local function createSlider(label, min, max, callback)
                    local frame = createUIElement("Frame", {
                        Parent = dialog.content,
                        Size = UDim2.new(1, 0, 0, 40),
                        BackgroundTransparency = 1,
                    })
                    
                    local labelObj = createUIElement("TextLabel", {
                        Parent = frame,
                        Text = label,
                        TextColor3 = self.theme.onSurface,
                        TextSize = 12,
                        Font = Enum.Font.Gotham,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 60, 0, 20),
                        TextXAlignment = Enum.TextXAlignment.Right,
                    })
                    
                    local sliderFrame = createUIElement("Frame", {
                        Parent = frame,
                        Size = UDim2.new(1, -70, 0, 20),
                        Position = UDim2.new(0, 64, 0, 10),
                        BackgroundTransparency = 1,
                    })
                    
                    local rail = createUIElement("Frame", {
                        Parent = sliderFrame,
                        Size = UDim2.new(1, 0, 0, 4),
                        Position = UDim2.new(0, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = self.theme.outlineVariant,
                        BackgroundTransparency = 0.3,
                    }, {
                        createUIElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
                        createUIElement("Frame", {
                            Name = "Fill",
                            Size = UDim2.new(0, 0, 1, 0),
                            BackgroundColor3 = self.theme.primary,
                            BorderSizePixel = 0,
                        }, {
                            createUIElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
                        }),
                    })
                    
                    local thumb = createUIElement("TextButton", {
                        Parent = sliderFrame,
                        Size = UDim2.new(0, 12, 0, 12),
                        Position = UDim2.new(0, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = self.theme.primary,
                        BackgroundTransparency = 0.2,
                        AutoButtonColor = false,
                        ZIndex = 2,
                    }, {
                        createUIElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
                        createUIElement("UIStroke", {
                            Color = self.theme.primary,
                            Transparency = 0.5,
                            Thickness = 2,
                        }),
                    })
                    
                    local valueLabel = createUIElement("TextLabel", {
                        Parent = sliderFrame,
                        Text = "",
                        TextColor3 = self.theme.onSurfaceVariant,
                        TextSize = 12,
                        Font = Enum.Font.Gotham,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, 4, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        Size = UDim2.new(0, 40, 0, 20),
                        TextXAlignment = Enum.TextXAlignment.Left,
                    })
                    
                    local function updateValue(value)
                        local t = (value - min) / (max - min)
                        local fill = rail:FindFirstChild("Fill")
                        if fill then
                            fill.Size = UDim2.new(t, 0, 1, 0)
                        end
                        thumb.Position = UDim2.new(t, -6, 0.5, 0)
                        valueLabel.Text = tostring(math.round(value * 100) / 100)
                        callback(value)
                    end
                    
                    local dragging = false
                    
                    thumb.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = true
                        end
                    end)
                    
                    thumb.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = false
                        end
                    end)
                    
                    sliderFrame.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            local pos = input.Position.X - rail.AbsolutePosition.X
                            local t = math.clamp(pos / rail.AbsoluteSize.X, 0, 1)
                            updateValue(min + (max - min) * t)
                        end
                    end)
                    
                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                            local pos = input.Position.X - rail.AbsolutePosition.X
                            local t = math.clamp(pos / rail.AbsoluteSize.X, 0, 1)
                            updateValue(min + (max - min) * t)
                        end
                    end)
                    
                    return {
                        setValue = updateValue,
                        frame = sliderFrame,
                    }
                end
                
                local hueSlider = createSlider("Hue", 0, 1, function(v)
                    hue = v
                    updatePreview()
                end)
                
                local satSlider = createSlider("Sat", 0, 1, function(v)
                    sat = v
                    updatePreview()
                end)
                
                local valSlider = createSlider("Val", 0, 1, function(v)
                    val = v
                    updatePreview()
                end)
                
                local transSlider = createSlider("Trans", 0, 1, function(v)
                    trans = v
                    updatePreview()
                end)
                
                local h, s, v = Color3.toHSV(colorpicker.value)
                hueSlider.setValue(h)
                satSlider.setValue(s)
                valSlider.setValue(v)
                transSlider.setValue(colorpicker.transparency)
                
                dialog:addButton("Done", function()
                    colorpicker.value = Color3.fromHSV(hue, sat, val)
                    colorpicker.transparency = trans
                    preview.BackgroundColor3 = colorpicker.value
                    preview.BackgroundTransparency = trans
                    if config.Callback then
                        config.Callback(colorpicker.value)
                    end
                    self:addLog("Colorpicker changed: " .. config.Title)
                end)
                
                dialog:addButton("Cancel", function() end)
                
                dialog:open()
            end
            
            frame.MouseButton1Click:Connect(openPicker)
            
            function colorpicker:setValue(color, transparency)
                self.value = color or self.value
                self.transparency = transparency or self.transparency
                preview.BackgroundColor3 = self.value
                preview.BackgroundTransparency = self.transparency
            end
            
            return colorpicker
        end
        
        function section:addLabel(config)
            local label = addElement("Label", config)
            
            local labelObj = createUIElement("TextLabel", {
                Parent = label.control,
                Text = config.Text or "",
                TextColor3 = self.theme.onSurfaceVariant,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 0, 20),
                AutomaticSize = Enum.AutomaticSize.X,
                TextXAlignment = Enum.TextXAlignment.Right,
            })
            
            label.control.Size = UDim2.new(0, 0, 0, 20)
            
            function label:setText(text)
                labelObj.Text = text
            end
            
            return label
        end
        
        table.insert(self.elements, section)
        self:addLog("Section added: " .. title)
        
        return section
    end
    
    return tabApi
end

function HyperionWindow:selectTab(tab)
    if self.activeTab == tab then return end
    for _, t in pairs(self.tabs) do
        t.container.Visible = (t == tab)
        local indicator = t.btn:FindFirstChild("Indicator")
        local title = t.btn:FindFirstChild("Title")
        if indicator then
            indicator.BackgroundTransparency = (t == tab) and 0 or 1
        end
        if title then
            title.TextColor3 = (t == tab) and self.theme.primary or self.theme.onSurfaceVariant
        end
        if t.btn then
            t.btn.BackgroundTransparency = (t == tab) and 0.7 or 0.9
        end
    end
    self.activeTab = tab
    self:addLog("Tab selected: " .. tab.name)
end

function HyperionWindow:createDialog(title)
    local dialog = {}
    dialog.visible = false
    
    local overlay = createUIElement("Frame", {
        Parent = self.root,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 0.5,
        Visible = false,
        ZIndex = 100,
    })
    
    local frame = createUIElement("Frame", {
        Parent = overlay,
        Size = UDim2.new(0, 360, 0, 240),
        Position = UDim2.new(0.5, -180, 0.5, -120),
        BackgroundColor3 = self.theme.surface,
        BackgroundTransparency = 0.05,
        ZIndex = 101,
    }, {
        createUIElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
        createUIElement("UIStroke", {
            Color = self.theme.outlineVariant,
            Transparency = 0.5,
            Thickness = 1,
        }),
        createUIElement("TextLabel", {
            Text = title or "Dialog",
            TextColor3 = self.theme.onSurface,
            TextSize = 18,
            Font = Enum.Font.GothamBold,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 12),
            Size = UDim2.new(1, -32, 0, 28),
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
        createUIElement("TextButton", {
            Text = "✕",
            TextColor3 = self.theme.onSurfaceVariant,
            TextSize = 16,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -36, 0, 4),
            Size = UDim2.new(0, 28, 0, 32),
            Font = Enum.Font.Gotham,
            ZIndex = 2,
        }),
    })
    
    local content = createUIElement("Frame", {
        Parent = frame,
        Size = UDim2.new(1, -32, 1, -80),
        Position = UDim2.new(0, 16, 0, 48),
        BackgroundTransparency = 1,
    }, {
        createUIElement("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })
    
    local buttonBar = createUIElement("Frame", {
        Parent = frame,
        Size = UDim2.new(1, -32, 0, 36),
        Position = UDim2.new(0, 16, 1, -44),
        BackgroundTransparency = 1,
    }, {
        createUIElement("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })
    
    dialog.content = content
    dialog.buttonBar = buttonBar
    dialog.overlay = overlay
    dialog.frame = frame
    
    function dialog:addButton(text, callback)
        local btn = createUIElement("TextButton", {
            Parent = self.buttonBar,
            Text = text,
            TextColor3 = self.theme.onPrimary,
            TextSize = 13,
            Font = Enum.Font.Gotham,
            BackgroundColor3 = self.theme.primary,
            Size = UDim2.new(0, 0, 0, 32),
            AutomaticSize = Enum.AutomaticSize.X,
        }, {
            createUIElement("UIPadding", {
                PaddingLeft = UDim.new(0, 16),
                PaddingRight = UDim.new(0, 16),
            }),
            createUIElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
        })
        btn.MouseButton1Click:Connect(function()
            if callback then callback() end
            self:close()
        end)
    end
    
    function dialog:open()
        self.overlay.Visible = true
        self.visible = true
    end
    
    function dialog:close()
        self.overlay.Visible = false
        self.visible = false
    end
    
    local closeBtn = frame:FindFirstChildOfClass("TextButton")
    if closeBtn then
        closeBtn.MouseButton1Click:Connect(function()
            dialog:close()
        end)
    end
    
    overlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not frame.AbsolutePosition or not frame.AbsoluteSize then return end
            local pos = input.Position
            local x = pos.X - frame.AbsolutePosition.X
            local y = pos.Y - frame.AbsolutePosition.Y
            if x < 0 or x > frame.AbsoluteSize.X or y < 0 or y > frame.AbsoluteSize.Y then
                dialog:close()
            end
        end
    end)
    
    return dialog
end

function HyperionWindow:addLog(message)
    local time = os.date("%H:%M:%S")
    table.insert(self.log, "[" .. time .. "] " .. message)
    if #self.log > 100 then
        table.remove(self.log, 1)
    end
    local logScroll = self.logger and self.logger:FindFirstChildOfClass("ScrollingFrame")
    if logScroll then
        local label = createUIElement("TextLabel", {
            Parent = logScroll,
            Text = "[" .. time .. "] " .. message,
            TextColor3 = self.theme.onSurfaceVariant,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
        })
        task.wait()
        logScroll.CanvasPosition = Vector2.new(0, logScroll.CanvasSize.Y.Offset)
    end
end

function HyperionWindow:toggleLog()
    if self.logger then
        self.logger.Visible = not self.logger.Visible
        self:addLog("Log toggled: " .. tostring(self.logger.Visible))
    end
end

function HyperionWindow:destroy()
    self:addLog("Window destroyed")
    self.gui:Destroy()
end

function HyperionWindow:minimize()
    self.minimized = not self.minimized
    self.root.Visible = not self.minimized
    self:addLog("Minimized: " .. tostring(self.minimized))
end

Hyperion.Window = HyperionWindow
Hyperion.Themes = Themes

return Hyperion