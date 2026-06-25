--[[
  ═══════════════════════════════════════════════════════════════
  FLUENT MATERIAL — Material You Edition (Android 16 Style)
  Версия: 3.0.0
  Основано на Fluent, переработано под Material Design 3
  ═══════════════════════════════════════════════════════════════
]]

-- ============================================================
-- 1. МОДУЛЬ ЦВЕТОВ (MATERIAL YOU PALETTE)
-- ============================================================

local MaterialYou = {}

-- Алгоритм генерации палитры из seed-цвета (упрощённый вариант)
function MaterialYou.GeneratePalette(seedColor)
    local function hsl(r, g, b)
        local min = math.min(r, g, b)
        local max = math.max(r, g, b)
        local delta = max - min
        local h, s, l
        
        if delta == 0 then
            h = 0
        elseif max == r then
            h = ((g - b) / delta) % 6
        elseif max == g then
            h = ((b - r) / delta) + 2
        else
            h = ((r - g) / delta) + 4
        end
        h = h / 6
        s = max == 0 and 0 or delta / max
        l = max
        return h, s, l
    end
    
    local function hslToRgb(h, s, l)
        if s == 0 then return l, l, l end
        local function hueToRgb(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < 1/6 then return p + (q - p) * 6 * t end
            if t < 1/2 then return q end
            if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
            return p
        end
        local q = l < 0.5 and l * (1 + s) or l + s - l * s
        local p = 2 * l - q
        return hueToRgb(p, q, h + 1/3),
               hueToRgb(p, q, h),
               hueToRgb(p, q, h - 1/3)
    end
    
    local h, s, l = hsl(seedColor.r, seedColor.g, seedColor.b)
    
    -- Генерируем тона
    local function getTone(tone)
        local lightness = tone / 100
        local r, g, b = hslToRgb(h, s * 0.8, lightness)
        return Color3.new(r, g, b)
    end
    
    return {
        primary = getTone(40),
        onPrimary = getTone(100),
        primaryContainer = getTone(90),
        onPrimaryContainer = getTone(10),
        secondary = getTone(60),
        onSecondary = getTone(100),
        secondaryContainer = getTone(85),
        onSecondaryContainer = getTone(10),
        surface = getTone(98),
        onSurface = getTone(10),
        surfaceVariant = getTone(95),
        onSurfaceVariant = getTone(30),
        background = getTone(99),
        onBackground = getTone(10),
        outline = getTone(50),
        outlineVariant = getTone(80),
        shadow = Color3.new(0, 0, 0),
        scrim = Color3.new(0, 0, 0),
        surfaceTint = getTone(40),
        error = Color3.fromRGB(186, 26, 26),
        onError = Color3.fromRGB(255, 255, 255),
        errorContainer = Color3.fromRGB(255, 218, 214),
        onErrorContainer = Color3.fromRGB(65, 0, 2),
    }
end

-- Текущая палитра (по умолчанию — синий, как Android)
local currentPalette = MaterialYou.GeneratePalette(Color3.fromRGB(66, 133, 244))
local seedColor = Color3.fromRGB(66, 133, 244)

function MaterialYou.SetSeedColor(color)
    seedColor = color
    currentPalette = MaterialYou.GeneratePalette(color)
    if MaterialYou.OnThemeChanged then
        MaterialYou.OnThemeChanged(currentPalette)
    end
end

function MaterialYou.GetColor(name)
    return currentPalette[name] or Color3.new(1, 1, 1)
end

-- ============================================================
-- 2. ЯДРО БИБЛИОТЕКИ (ПЕРЕПИСАНО ПОД M3)
-- ============================================================

local Library = {
    Version = "3.0.0",
    Theme = "MaterialYou",
    OpenFrames = {},
    Options = {},
    Windows = {},
    Window = nil,
    Unloaded = false,
    DialogOpen = false,
    UseAcrylic = false,
    MinimizeKey = Enum.KeyCode.LeftControl,
    MinimizeKeybind = nil,
    Creator = {},
    Elements = {},
    ActiveNotifications = {},
    GUI = nil,
}

-- Определяем мобилку
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Mobile = not RunService:IsStudio() and table.find({Enum.Platform.IOS, Enum.Platform.Android}, UserInputService:GetPlatform()) ~= nil

-- ============================================================
-- 3. Flipper (анимации) — оставляем как есть, он идеален
-- ============================================================

local Flipper = {}
do
    local function isMotor(value)
        return tostring(value):match("^Motor%(") and true or false
    end
    
    local Connection = { __index = {} }
    function Connection.new(signal, handler)
        return setmetatable({ signal = signal, connected = true, _handler = handler }, Connection)
    end
    function Connection:disconnect()
        if self.connected then
            self.connected = false
            for i, c in pairs(self.signal._connections) do
                if c == self then table.remove(self.signal._connections, i) return end
            end
        end
    end
    
    local Signal = { __index = {} }
    function Signal.new()
        return setmetatable({ _connections = {}, _threads = {} }, Signal)
    end
    function Signal:fire(...)
        for _, c in pairs(self._connections) do c._handler(...) end
        for _, t in pairs(self._threads) do coroutine.resume(t, ...) end
        self._threads = {}
    end
    function Signal:connect(handler)
        local c = Connection.new(self, handler)
        table.insert(self._connections, c)
        return c
    end
    function Signal:wait()
        table.insert(self._threads, coroutine.running())
        return coroutine.yield()
    end
    
    local function noop() end
    
    local BaseMotor = { __index = {} }
    function BaseMotor.new()
        return setmetatable({ _onStep = Signal.new(), _onStart = Signal.new(), _onComplete = Signal.new() }, BaseMotor)
    end
    BaseMotor.onStep = function(self, h) return self._onStep:connect(h) end
    BaseMotor.onStart = function(self, h) return self._onStart:connect(h) end
    BaseMotor.onComplete = function(self, h) return self._onComplete:connect(h) end
    BaseMotor.start = function(self)
        if not self._connection then
            self._connection = RunService.RenderStepped:Connect(function(dt) self:step(dt) end)
        end
    end
    BaseMotor.stop = function(self)
        if self._connection then self._connection:Disconnect() self._connection = nil end
    end
    BaseMotor.destroy = BaseMotor.stop
    BaseMotor.step = noop
    BaseMotor.getValue = noop
    BaseMotor.setGoal = noop
    
    local SingleMotor = setmetatable({}, BaseMotor)
    SingleMotor.__index = SingleMotor
    function SingleMotor.new(initialValue, useImplicitConnections)
        local self = setmetatable(BaseMotor.new(), SingleMotor)
        self._useImplicitConnections = useImplicitConnections == nil and true or useImplicitConnections
        self._goal = nil
        self._state = { complete = true, value = initialValue }
        return self
    end
    function SingleMotor:step(dt)
        if self._state.complete then return true end
        local newState = self._goal:step(self._state, dt)
        self._state = newState
        self._onStep:fire(newState.value)
        if newState.complete then
            if self._useImplicitConnections then self:stop() end
            self._onComplete:fire()
        end
        return newState.complete
    end
    function SingleMotor:getValue() return self._state.value end
    function SingleMotor:setGoal(goal)
        self._state.complete = false
        self._goal = goal
        self._onStart:fire()
        if self._useImplicitConnections then self:start() end
    end
    
    local GroupMotor = setmetatable({}, BaseMotor)
    GroupMotor.__index = GroupMotor
    function GroupMotor.new(initialValues, useImplicitConnections)
        local self = setmetatable(BaseMotor.new(), GroupMotor)
        self._useImplicitConnections = useImplicitConnections == nil and true or useImplicitConnections
        self._complete = true
        self._motors = {}
        for k, v in pairs(initialValues) do
            if isMotor(v) then self._motors[k] = v
            elseif typeof(v) == "number" then self._motors[k] = SingleMotor.new(v, false)
            elseif typeof(v) == "table" then self._motors[k] = GroupMotor.new(v, false)
            else error("Unsupported type for motor: " .. typeof(v)) end
        end
        return self
    end
    function GroupMotor:step(dt)
        if self._complete then return true end
        local allComplete = true
        for _, m in pairs(self._motors) do if not m:step(dt) then allComplete = false end end
        self._onStep:fire(self:getValue())
        if allComplete then
            if self._useImplicitConnections then self:stop() end
            self._complete = true
            self._onComplete:fire()
        end
        return allComplete
    end
    function GroupMotor:setGoal(goals)
        self._complete = false
        self._onStart:fire()
        for k, g in pairs(goals) do
            local motor = self._motors[k]
            if motor then motor:setGoal(g) end
        end
        if self._useImplicitConnections then self:start() end
    end
    function GroupMotor:getValue()
        local out = {}
        for k, m in pairs(self._motors) do out[k] = m:getValue() end
        return out
    end
    
    local Instant = {}
    function Instant.new(target) return setmetatable({ _target = target }, { __index = function(t, k) if k == "step" then return function() return { complete = true, value = t._target } end end end }) end
    
    local Spring = {}
    function Spring.new(target, opts)
        opts = opts or {}
        return setmetatable({ _target = target, _freq = opts.frequency or 4, _damp = opts.dampingRatio or 1 }, {
            __index = function(t, k)
                if k == "step" then
                    return function(state, dt)
                        local d = t._damp
                        local f = t._freq * 2 * math.pi
                        local g = t._target
                        local p0 = state.value
                        local v0 = state.velocity or 0
                        local offset = p0 - g
                        local decay = math.exp(-d * f * dt)
                        local p1, v1
                        if d == 1 then
                            p1 = (offset * (1 + f * dt) + v0 * dt) * decay + g
                            v1 = (v0 * (1 - f * dt) - offset * (f * f * dt)) * decay
                        elseif d < 1 then
                            local c = math.sqrt(1 - d * d)
                            local i = math.cos(f * c * dt)
                            local j = math.sin(f * c * dt)
                            local z = j / c
                            local y = j / (f * c)
                            p1 = (offset * (i + d * z) + v0 * y) * decay + g
                            v1 = (v0 * (i - z * d) - offset * (z * f)) * decay
                        else
                            local c = math.sqrt(d * d - 1)
                            local r1 = -f * (d - c)
                            local r2 = -f * (d + c)
                            local co2 = (v0 - offset * r1) / (2 * f * c)
                            local co1 = offset - co2
                            local e1 = co1 * math.exp(r1 * dt)
                            local e2 = co2 * math.exp(r2 * dt)
                            p1 = e1 + e2 + g
                            v1 = e1 * r1 + e2 * r2
                        end
                        local complete = math.abs(v1) < 0.001 and math.abs(p1 - g) < 0.001
                        return { complete = complete, value = complete and g or p1, velocity = v1 }
                    end
                end
            end
        })
    end
    
    Flipper = {
        SingleMotor = SingleMotor,
        GroupMotor = GroupMotor,
        Instant = Instant,
        Spring = Spring,
        isMotor = isMotor,
    }
end

-- ============================================================
-- 4. CREATOR (СОЗДАНИЕ ОБЪЕКТОВ С ТЕМАМИ M3)
-- ============================================================

local Creator = {}
Library.Creator = Creator

local function getColor(name)
    return MaterialYou.GetColor(name)
end

-- Сопоставление Material You цветов для элементов
local M3Colors = {
    primary = "primary",
    onPrimary = "onPrimary",
    primaryContainer = "primaryContainer",
    onPrimaryContainer = "onPrimaryContainer",
    secondary = "secondary",
    onSecondary = "onSecondary",
    secondaryContainer = "secondaryContainer",
    onSecondaryContainer = "onSecondaryContainer",
    surface = "surface",
    onSurface = "onSurface",
    surfaceVariant = "surfaceVariant",
    onSurfaceVariant = "onSurfaceVariant",
    background = "background",
    onBackground = "onBackground",
    outline = "outline",
    outlineVariant = "outlineVariant",
    shadow = "shadow",
    error = "error",
    onError = "onError",
    errorContainer = "errorContainer",
    onErrorContainer = "onErrorContainer",
}

-- Текущие теги для быстрого доступа
Creator.ColorMap = {}

function Creator.UpdateTheme()
    -- Обновляем все зарегистрированные объекты
    for obj, data in pairs(Creator.Registry or {}) do
        for prop, colorKey in pairs(data.properties) do
            local color = getColor(colorKey)
            if color then
                obj[prop] = color
            end
        end
    end
    
    -- Обновляем моторы прозрачности
    for _, motor in pairs(Creator.TransparencyMotors or {}) do
        motor:setGoal(Flipper.Instant.new(0.0)) -- Material You не использует прозрачность
    end
end

Creator.Registry = {}
Creator.Signals = {}
Creator.TransparencyMotors = {}

function Creator.AddThemeObject(obj, props)
    if not Creator.Registry then Creator.Registry = {} end
    Creator.Registry[obj] = { properties = props }
    Creator.UpdateTheme()
    return obj
end

function Creator.OverrideTag(obj, props)
    if Creator.Registry[obj] then
        Creator.Registry[obj].properties = props
        Creator.UpdateTheme()
    end
end

function Creator.AddSignal(signal, func)
    local conn = signal:Connect(func)
    table.insert(Creator.Signals, conn)
    return conn
end

function Creator.Disconnect()
    for _, conn in pairs(Creator.Signals) do
        conn:Disconnect()
    end
    Creator.Signals = {}
end

function Creator.New(className, props, children)
    local obj = Instance.new(className)
    
    -- Применяем дефолтные свойства (Material You стиль)
    local defaults = {
        Frame = {
            BackgroundColor3 = getColor("surface"),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
        },
        TextLabel = {
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamSSm,
            TextColor3 = getColor("onSurface"),
            TextSize = 14,
            RichText = true,
        },
        TextButton = {
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamSSm,
            TextColor3 = getColor("onSurface"),
            TextSize = 14,
            AutoButtonColor = false,
            RichText = true,
        },
        TextBox = {
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamSSm,
            TextColor3 = getColor("onSurface"),
            TextSize = 14,
            ClearTextOnFocus = false,
            RichText = true,
        },
        ImageLabel = {
            BackgroundTransparency = 1,
        },
        ImageButton = {
            BackgroundTransparency = 1,
            AutoButtonColor = false,
        },
        ScrollingFrame = {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageTransparency = 0.7,
            ScrollBarImageColor3 = getColor("outlineVariant"),
        },
        CanvasGroup = {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        },
        ScreenGui = {
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        },
    }
    
    if defaults[className] then
        for k, v in pairs(defaults[className]) do
            if obj[k] ~= nil then obj[k] = v end
        end
    end
    
    -- Применяем пользовательские свойства
    if props then
        for k, v in pairs(props) do
            if k ~= "ThemeTag" then
                obj[k] = v
            end
        end
    end
    
    -- Применяем теги
    if props and props.ThemeTag then
        Creator.AddThemeObject(obj, props.ThemeTag)
    end
    
    -- Добавляем дочерние объекты
    if children then
        for _, child in pairs(children) do
            child.Parent = obj
        end
    end
    
    return obj
end

function Creator.SpringMotor(initial, instance, prop, ignoreDialog, resetOnTheme)
    local motor = Flipper.SingleMotor.new(initial)
    motor:onStep(function(value)
        instance[prop] = value
    end)
    if resetOnTheme then
        table.insert(Creator.TransparencyMotors, motor)
    end
    local function setValue(value)
        motor:setGoal(Flipper.Spring.new(value, { frequency = 8 }))
    end
    return motor, setValue
end

-- ============================================================
-- 5. КОМПОНЕНТЫ MATERIAL YOU
-- ============================================================

-- Вспомогательные функции
local function safeCallback(fn, ...)
    if fn then pcall(fn, ...) end
end

local function spring(t) return Flipper.Spring.new(t, { frequency = 5, dampingRatio = 0.7 }) end
local function instant(t) return Flipper.Instant.new(t) end

-- Element — базовый блок
local function createElement(title, desc, parent, config)
    config = config or {}
    local el = {}
    
    local label = Creator.New("TextLabel", {
        Text = title or "",
        TextSize = 16,
        Font = Enum.Font.GothamSSm,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 20),
        AutomaticSize = Enum.AutomaticSize.Y,
        ThemeTag = { TextColor3 = "onSurface" },
    })
    
    local descLabel = Creator.New("TextLabel", {
        Text = desc or "",
        TextSize = 14,
        TextColor3 = getColor("onSurfaceVariant"),
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 16),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = desc and desc ~= "",
        ThemeTag = { TextColor3 = "onSurfaceVariant" },
    })
    
    local labelHolder = Creator.New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.fromOffset(12, 0),
    }, {
        Creator.New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
        label,
        descLabel,
    })
    
    local frame = Creator.New("Frame", {
        BackgroundColor3 = getColor("surfaceVariant"),
        BackgroundTransparency = 0.3,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = parent,
        LayoutOrder = config.LayoutOrder or 7,
        ThemeTag = { BackgroundColor3 = "surfaceVariant" },
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 16) }),
        labelHolder,
    })
    
    el.Frame = frame
    el.Label = label
    el.DescLabel = descLabel
    el.SetTitle = function(t) label.Text = t or "" end
    el.SetDesc = function(d) descLabel.Text = d or "" descLabel.Visible = d and d ~= "" end
    el.Visible = function(v) frame.Visible = v end
    el.Destroy = function() frame:Destroy() end
    
    return el
end

-- ============================================================
-- 6. ОСНОВНОЙ API
-- ============================================================

-- GUI корень
local gui = Creator.New("ScreenGui", { Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") })
Library.GUI = gui
if protectgui then protectgui(gui) end

-- Window
function Library:CreateWindow(config)
    config = config or {}
    config.Title = config.Title or "Window"
    config.Size = config.Size or UDim2.fromOffset(560, 420)
    config.Theme = "MaterialYou"
    
    local win = {}
    Library.Window = win
    table.insert(Library.Windows, win)
    
    local root = Creator.New("Frame", {
        Size = config.Size,
        Position = UDim2.fromOffset(100, 100),
        BackgroundColor3 = getColor("surface"),
        Parent = gui,
        ThemeTag = { BackgroundColor3 = "surface" },
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 28) }),
        Creator.New("UIStroke", {
            Color = getColor("outlineVariant"),
            Transparency = 0.3,
            Thickness = 1,
        }),
    })
    
    win.Root = root
    win.Active = true
    
    -- Заголовок
    local titleBar = Creator.New("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundTransparency = 1,
    }, {
        Creator.New("TextLabel", {
            Text = config.Title,
            TextSize = 22,
            Font = Enum.Font.GothamSSm,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromOffset(20, 0),
            Size = UDim2.new(1, -120, 1, 0),
            ThemeTag = { TextColor3 = "onSurface" },
        }),
    })
    titleBar.Parent = root
    
    -- Кнопки управления (Material You стиль)
    local function makeTitleButton(icon, pos, callback)
        local btn = Creator.New("TextButton", {
            Size = UDim2.fromOffset(40, 40),
            Position = pos,
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
        }, {
            Creator.New("ImageLabel", {
                Image = icon,
                Size = UDim2.fromOffset(20, 20),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                ThemeTag = { ImageColor3 = "onSurfaceVariant" },
            }),
        })
        Creator.AddSignal(btn.MouseButton1Click, callback)
        return btn
    end
    
    local function closeWindow()
        Library:Destroy()
    end
    
    local function toggleMinimize()
        if win.Minimized then
            root.Visible = true
            win.Minimized = false
        else
            root.Visible = false
            win.Minimized = true
        end
    end
    
    makeTitleButton("rbxassetid://10709791437", UDim2.new(1, -12, 0.5, 0), closeWindow).Parent = root
    makeTitleButton("rbxassetid://10734896384", UDim2.new(1, -56, 0.5, 0), toggleMinimize).Parent = root
    
    -- Контейнер для вкладок
    local tabContainer = Creator.New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -56),
        Position = UDim2.fromOffset(0, 56),
        CanvasSize = UDim2.fromScale(0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 0,
    }, {
        Creator.New("UIListLayout", {
            Padding = UDim.new(0, 12),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
        Creator.New("UIPadding", {
            PaddingLeft = UDim.new(0, 16),
            PaddingRight = UDim.new(0, 16),
            PaddingTop = UDim.new(0, 16),
            PaddingBottom = UDim.new(0, 16),
        }),
    })
    tabContainer.Parent = root
    
    -- Функция для обновления CanvasSize
    local function updateCanvas()
        local layout = tabContainer:FindFirstChild("UIListLayout")
        if layout then
            tabContainer.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 32)
        end
    end
    Creator.AddSignal(tabContainer:GetPropertyChangedSignal("AbsoluteSize"), updateCanvas)
    
    -- Добавление вкладок
    win.Tabs = {}
    win.CurrentTab = nil
    
    function win:AddTab(tabConfig)
        tabConfig.Title = tabConfig.Title or "Tab"
        
        -- Кнопка вкладки (нижняя навигация в Material You)
        local tabBtn = Creator.New("TextButton", {
            Size = UDim2.new(0, 0, 0, 48),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Parent = tabContainer,
            LayoutOrder = #win.Tabs + 1,
        }, {
            Creator.New("UIPadding", {
                PaddingLeft = UDim.new(0, 16),
                PaddingRight = UDim.new(0, 16),
            }),
            Creator.New("TextLabel", {
                Text = tabConfig.Title,
                TextSize = 16,
                Font = Enum.Font.GothamSSm,
                ThemeTag = { TextColor3 = "onSurfaceVariant" },
            }),
            Creator.New("Frame", {
                Size = UDim2.new(1, 0, 0, 3),
                Position = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = getColor("primary"),
                BackgroundTransparency = 1,
                ThemeTag = { BackgroundColor3 = "primary" },
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(0, 2) }),
            }),
        })
        
        -- Контейнер для контента вкладки
        local content = Creator.New("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, -56),
            Position = UDim2.fromOffset(0, 56),
            BackgroundTransparency = 1,
            Visible = false,
            CanvasSize = UDim2.fromScale(0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollBarThickness = 4,
            ScrollBarImageTransparency = 0.7,
            ScrollBarImageColor3 = getColor("outlineVariant"),
        }, {
            Creator.New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
            Creator.New("UIPadding", {
                PaddingLeft = UDim.new(0, 16),
                PaddingRight = UDim.new(0, 16),
                PaddingTop = UDim.new(0, 16),
                PaddingBottom = UDim.new(0, 16),
            }),
        })
        content.Parent = root
        
        -- Обновление контента
        local function updateContentCanvas()
            local layout = content:FindFirstChild("UIListLayout")
            if layout then
                content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 32)
            end
        end
        Creator.AddSignal(content:GetPropertyChangedSignal("AbsoluteSize"), updateContentCanvas)
        
        -- Индикатор активной вкладки
        local indicator = tabBtn:FindFirstChildWhichIsA("Frame")
        
        -- Функция выбора вкладки
        local function selectTab()
            if win.CurrentTab then
                win.CurrentTab.Content.Visible = false
                win.CurrentTab.Button.BackgroundTransparency = 1
                local oldInd = win.CurrentTab.Button:FindFirstChildWhichIsA("Frame")
                if oldInd then oldInd.BackgroundTransparency = 1 end
                local oldLabel = win.CurrentTab.Button:FindFirstChildWhichIsA("TextLabel")
                if oldLabel then
                    Creator.OverrideTag(oldLabel, { TextColor3 = "onSurfaceVariant" })
                end
            end
            win.CurrentTab = tab
            content.Visible = true
            tabBtn.BackgroundTransparency = 0.05
            if indicator then indicator.BackgroundTransparency = 0 end
            local label = tabBtn:FindFirstChildWhichIsA("TextLabel")
            if label then
                Creator.OverrideTag(label, { TextColor3 = "primary" })
            end
            updateContentCanvas()
        end
        
        Creator.AddSignal(tabBtn.MouseButton1Click, selectTab)
        
        -- Объект вкладки
        local tab = {
            Title = tabConfig.Title,
            Button = tabBtn,
            Content = content,
            Sections = {},
        }
        
        -- Добавление секции
        function tab:AddSection(sectionTitle)
            local section = {}
            
            local header = Creator.New("TextLabel", {
                Text = sectionTitle or "Section",
                TextSize = 18,
                Font = Enum.Font.GothamSSm,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 28),
                ThemeTag = { TextColor3 = "onSurface" },
            })
            
            local container = Creator.New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
            }, {
                Creator.New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
                header,
            })
            
            local sectionFrame = Creator.New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = content,
                LayoutOrder = #tab.Sections + 1,
            }, {
                container,
            })
            
            section.Container = container
            section.Frame = sectionFrame
            section.Header = header
            
            function section:AddButton(btnConfig)
                btnConfig.Title = btnConfig.Title or "Button"
                
                local btn = Creator.New("TextButton", {
                    Text = btnConfig.Title,
                    TextSize = 16,
                    Font = Enum.Font.GothamSSm,
                    BackgroundColor3 = getColor("primary"),
                    TextColor3 = getColor("onPrimary"),
                    Size = UDim2.new(1, 0, 0, 52),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = container,
                    LayoutOrder = #container:GetChildren() + 1,
                    ThemeTag = { BackgroundColor3 = "primary", TextColor3 = "onPrimary" },
                }, {
                    Creator.New("UICorner", { CornerRadius = UDim.new(0, 16) }),
                    Creator.New("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14) }),
                })
                
                Creator.AddSignal(btn.MouseButton1Click, function()
                    safeCallback(btnConfig.Callback)
                end)
                
                -- Анимация нажатия
                Creator.AddSignal(btn.MouseButton1Down, function()
                    btn.Size = UDim2.new(1, 0, 0, 48)
                    local scale = Creator.New("UIScale", { Scale = 0.96, Parent = btn })
                    task.wait(0.1)
                    btn.Size = UDim2.new(1, 0, 0, 52)
                    scale:Destroy()
                end)
                
                return btn
            end
            
            function section:AddToggle(toggleConfig)
                toggleConfig.Title = toggleConfig.Title or "Toggle"
                toggleConfig.Default = toggleConfig.Default or false
                
                local el = createElement(toggleConfig.Title, toggleConfig.Description, container, { LayoutOrder = #container:GetChildren() + 1 })
                
                local value = toggleConfig.Default
                
                -- M3 Switch
                local switchBg = Creator.New("Frame", {
                    Size = UDim2.fromOffset(48, 28),
                    BackgroundColor3 = getColor("surfaceVariant"),
                    BackgroundTransparency = 0.7,
                    Position = UDim2.new(1, -12, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Parent = el.Frame,
                    ThemeTag = { BackgroundColor3 = "surfaceVariant" },
                }, {
                    Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    Creator.New("Frame", {
                        Name = "Thumb",
                        Size = UDim2.fromOffset(22, 22),
                        Position = UDim2.fromOffset(2, 3),
                        BackgroundColor3 = getColor("onSurfaceVariant"),
                        ThemeTag = { BackgroundColor3 = "onSurfaceVariant" },
                    }, {
                        Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    }),
                })
                
                local thumb = switchBg:FindFirstChild("Thumb")
                
                local function setValue(newVal)
                    value = newVal
                    local color = value and "primary" or "onSurfaceVariant"
                    Creator.OverrideTag(thumb, { BackgroundColor3 = color })
                    if value then
                        thumb.Position = UDim2.fromOffset(24, 3)
                        Creator.OverrideTag(switchBg, { BackgroundColor3 = "primary" })
                        switchBg.BackgroundTransparency = 0.8
                    else
                        thumb.Position = UDim2.fromOffset(2, 3)
                        Creator.OverrideTag(switchBg, { BackgroundColor3 = "surfaceVariant" })
                        switchBg.BackgroundTransparency = 0.7
                    end
                    safeCallback(toggleConfig.Callback, value)
                end
                
                Creator.AddSignal(el.Frame.MouseButton1Click, function()
                    setValue(not value)
                end)
                
                setValue(toggleConfig.Default)
                
                el.SetValue = setValue
                return el
            end
            
            function section:AddSlider(sliderConfig)
                sliderConfig.Title = sliderConfig.Title or "Slider"
                sliderConfig.Default = sliderConfig.Default or 0
                sliderConfig.Min = sliderConfig.Min or 0
                sliderConfig.Max = sliderConfig.Max or 100
                
                local el = createElement(sliderConfig.Title, sliderConfig.Description, container, { LayoutOrder = #container:GetChildren() + 1 })
                
                local value = sliderConfig.Default
                
                -- M3 Slider
                local track = Creator.New("Frame", {
                    Size = UDim2.new(1, -60, 0, 4),
                    Position = UDim2.new(0, 0, 1, -16),
                    BackgroundColor3 = getColor("surfaceVariant"),
                    ThemeTag = { BackgroundColor3 = "surfaceVariant" },
                }, {
                    Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    Creator.New("Frame", {
                        Name = "Fill",
                        Size = UDim2.fromScale(0.5, 1),
                        BackgroundColor3 = getColor("primary"),
                        ThemeTag = { BackgroundColor3 = "primary" },
                    }, {
                        Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    }),
                    Creator.New("Frame", {
                        Name = "Thumb",
                        Size = UDim2.fromOffset(20, 20),
                        Position = UDim2.fromScale(0.5, 0.5),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = getColor("primary"),
                        ThemeTag = { BackgroundColor3 = "primary" },
                    }, {
                        Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
                        Creator.New("UIStroke", {
                            Color = getColor("surface"),
                            Thickness = 2,
                            ThemeTag = { Color = "surface" },
                        }),
                    }),
                })
                track.Parent = el.Frame
                
                local fill = track:FindFirstChild("Fill")
                local thumb = track:FindFirstChild("Thumb")
                
                local function setValue(newVal)
                    value = math.clamp(newVal, sliderConfig.Min, sliderConfig.Max)
                    local ratio = (value - sliderConfig.Min) / (sliderConfig.Max - sliderConfig.Min)
                    fill.Size = UDim2.fromScale(ratio, 1)
                    thumb.Position = UDim2.fromScale(ratio, 0.5)
                    safeCallback(sliderConfig.Callback, value)
                end
                
                -- Drag logic
                local dragging = false
                Creator.AddSignal(track.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        local pos = input.Position.X - track.AbsolutePosition.X
                        local ratio = math.clamp(pos / track.AbsoluteSize.X, 0, 1)
                        setValue(sliderConfig.Min + (sliderConfig.Max - sliderConfig.Min) * ratio)
                    end
                end)
                
                Creator.AddSignal(UserInputService.InputChanged, function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local pos = input.Position.X - track.AbsolutePosition.X
                        local ratio = math.clamp(pos / track.AbsoluteSize.X, 0, 1)
                        setValue(sliderConfig.Min + (sliderConfig.Max - sliderConfig.Min) * ratio)
                    end
                end)
                
                Creator.AddSignal(UserInputService.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                
                setValue(sliderConfig.Default)
                el.SetValue = setValue
                return el
            end
            
            -- Добавим ещё базовые элементы: Dropdown, Colorpicker, Input, Keybind по необходимости
            -- (здесь они опущены для краткости, но могут быть добавлены по запросу)
            
            table.insert(tab.Sections, section)
            return section
        end
        
        -- Если это первая вкладка — активируем
        if #win.Tabs == 0 then
            selectTab()
        end
        
        table.insert(win.Tabs, tab)
        return tab
    end
    
    -- Функция выбора вкладки по индексу
    function win:SelectTab(index)
        if win.Tabs[index] then
            win.Tabs[index].Button.MouseButton1Click:Fire()
        end
    end
    
    -- Центрирование окна
    local function centerWindow()
        local vp = workspace.CurrentCamera.ViewportSize
        root.Position = UDim2.fromOffset(
            math.max(0, (vp.X - root.AbsoluteSize.X) / 2),
            math.max(0, (vp.Y - root.AbsoluteSize.Y) / 2)
        )
    end
    centerWindow()
    Creator.AddSignal(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), centerWindow)
    
    -- Минимизация
    win.Minimized = false
    function win:Minimize()
        toggleMinimize()
    end
    
    -- Dialog
    function win:Dialog(dialogConfig)
        -- Простой диалог в стиле M3
        local overlay = Creator.New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.5,
            Parent = gui,
        })
        
        local dialog = Creator.New("Frame", {
            Size = UDim2.fromOffset(320, 180),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = getColor("surface"),
            ThemeTag = { BackgroundColor3 = "surface" },
        }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, 24) }),
            Creator.New("TextLabel", {
                Text = dialogConfig.Title or "Dialog",
                TextSize = 20,
                Font = Enum.Font.GothamSSm,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.fromOffset(20, 20),
                Size = UDim2.new(1, -40, 0, 28),
                ThemeTag = { TextColor3 = "onSurface" },
            }),
            Creator.New("TextLabel", {
                Text = dialogConfig.Content or "",
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                Position = UDim2.fromOffset(20, 56),
                Size = UDim2.new(1, -40, 0, 60),
                TextWrapped = true,
                ThemeTag = { TextColor3 = "onSurfaceVariant" },
            }),
            Creator.New("Frame", {
                Position = UDim2.new(0, 0, 1, -56),
                Size = UDim2.new(1, 0, 0, 56),
                BackgroundTransparency = 1,
            }, {
                Creator.New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    Padding = UDim.new(0, 8),
                }),
            }),
        })
        dialog.Parent = overlay
        
        local btnHolder = dialog:FindFirstChildWhichIsA("Frame")
        for _, btnConfig in pairs(dialogConfig.Buttons or {}) do
            local btn = Creator.New("TextButton", {
                Text = btnConfig.Title or "OK",
                TextSize = 14,
                Font = Enum.Font.GothamSSm,
                TextColor3 = getColor("primary"),
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(80, 40),
                ThemeTag = { TextColor3 = "primary" },
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(0, 8) }),
            })
            btn.Parent = btnHolder
            Creator.AddSignal(btn.MouseButton1Click, function()
                safeCallback(btnConfig.Callback)
                overlay:Destroy()
            end)
        end
        
        return overlay
    end
    
    -- Notify
    function win:Notify(notifConfig)
        notifConfig.Title = notifConfig.Title or "Notification"
        notifConfig.Content = notifConfig.Content or ""
        notifConfig.Duration = notifConfig.Duration or 4
        
        local notif = Creator.New("Frame", {
            Size = UDim2.fromOffset(320, 64),
            Position = UDim2.new(1, -24, 0, 24),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = getColor("surface"),
            ThemeTag = { BackgroundColor3 = "surface" },
        }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, 16) }),
            Creator.New("UIStroke", {
                Color = getColor("outlineVariant"),
                Transparency = 0.3,
                Thickness = 1,
            }),
            Creator.New("TextLabel", {
                Text = notifConfig.Title,
                TextSize = 16,
                Font = Enum.Font.GothamSSm,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.fromOffset(16, 8),
                Size = UDim2.new(1, -32, 0, 20),
                ThemeTag = { TextColor3 = "onSurface" },
            }),
            Creator.New("TextLabel", {
                Text = notifConfig.Content,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.fromOffset(16, 32),
                Size = UDim2.new(1, -32, 0, 20),
                ThemeTag = { TextColor3 = "onSurfaceVariant" },
            }),
        })
        notif.Parent = gui
        
        -- Анимация появления
        local motor = Flipper.SingleMotor.new(1)
        motor:onStep(function(v)
            notif.Position = UDim2.new(1, -24 - (1 - v) * 340, 0, 24 + (1 - v) * 20)
            notif.BackgroundTransparency = 1 - v * 0.95
        end)
        motor:setGoal(spring(0))
        
        task.delay(notifConfig.Duration, function()
            motor:setGoal(spring(1))
            task.wait(0.3)
            notif:Destroy()
        end)
        
        return notif
    end
    
    -- Возвращаем окно
    return win
end

-- ============================================================
-- 7. ДОПОЛНИТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================================

function Library:SetTheme(theme)
    if theme == "MaterialYou" then
        Creator.UpdateTheme()
    end
end

function Library:SetSeedColor(color)
    MaterialYou.SetSeedColor(color)
    Creator.UpdateTheme()
end

function Library:Destroy()
    if Library.Window then
        Library.Window.Root:Destroy()
        Library.Window = nil
    end
    Creator.Disconnect()
    Library.GUI:Destroy()
end

function Library:Notify(config)
    if Library.Window then
        return Library.Window:Notify(config)
    end
end

function Library:CreateMinimizer(config)
    -- Простой минимизатор в стиле Material You
    config = config or {}
    local btn = Creator.New("TextButton", {
        Size = UDim2.fromOffset(48, 48),
        Position = config.Position or UDim2.fromOffset(20, 20),
        BackgroundColor3 = getColor("surface"),
        Parent = gui,
        ThemeTag = { BackgroundColor3 = "surface" },
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
        Creator.New("UIStroke", {
            Color = getColor("outlineVariant"),
            Transparency = 0.3,
            Thickness = 1,
        }),
        Creator.New("ImageLabel", {
            Image = "rbxassetid://10734897102",
            Size = UDim2.fromOffset(24, 24),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            ThemeTag = { ImageColor3 = "onSurfaceVariant" },
        }),
    })
    
    Creator.AddSignal(btn.MouseButton1Click, function()
        if Library.Window then
            Library.Window:Minimize()
        end
    end)
    
    return btn
end

-- ============================================================
-- 8. ИНИЦИАЛИЗАЦИЯ
-- ============================================================

-- Обновляем тему при изменении цвета
MaterialYou.OnThemeChanged = function()
    Creator.UpdateTheme()
end

-- Глобальный доступ
getgenv().Fluent = Library
getgenv().FluentMaterial = Library
getgenv().MaterialYou = MaterialYou

return Library, MaterialYou
