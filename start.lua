-- Start (LocalScript в StarterPlayerScripts)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local loaderRemote = ReplicatedStorage:WaitForChild("PaninyLoaderRemote") -- создан Loader'ом

-- Минимальный стартовый UI
local screenGui = Instance.new("ScreenGui", PlayerGui)
screenGui.Name = "PaninyStartGUI"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0,380,0,200)
frame.Position = UDim2.new(0.5,-190,0.5,-100)
frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
frame.BorderSizePixel = 0
local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,10)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,40)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundTransparency = 1
title.Text = "Paniny Console — Start"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255,255,255)

local info = Instance.new("TextLabel", frame)
info.Size = UDim2.new(1,-20,0,50)
info.Position = UDim2.new(0,10,0,44)
info.BackgroundTransparency = 1
info.Text = "Введите стартовый код. Код по умолчанию: 1"
info.Font = Enum.Font.Gotham
info.TextSize = 14
info.TextColor3 = Color3.fromRGB(200,200,200)

local codeBox = Instance.new("TextBox", frame)
codeBox.Size = UDim2.new(1,-20,0,34)
codeBox.Position = UDim2.new(0,10,0,100)
codeBox.PlaceholderText = "code"
codeBox.Font = Enum.Font.Gotham
codeBox.TextSize = 18
codeBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
local cbCorner = Instance.new("UICorner", codeBox); cbCorner.CornerRadius = UDim.new(0,8)

local checkBtn = Instance.new("TextButton", frame)
checkBtn.Size = UDim2.new(0,160,0,36)
checkBtn.Position = UDim2.new(0,10,0,144)
checkBtn.Text = "Проверить код"

local getBtn = Instance.new("TextButton", frame)
getBtn.Size = UDim2.new(0,160,0,36)
getBtn.Position = UDim2.new(1,-170,0,144)
getBtn.AnchorPoint = Vector2.new(1,0)
getBtn.Text = "Получить код"

-- копирование в буфер (pcall)
getBtn.MouseButton1Click:Connect(function()
    local ok = pcall(function() setclipboard("test") end)
    if ok then
        -- локальное оповещение
        local s = Instance.new("TextLabel", frame)
        s.Size = UDim2.new(1,-20,0,20)
        s.Position = UDim2.new(0,10,0,176)
        s.BackgroundTransparency = 1
        s.Text = "Код скопирован в буфер: test"
        s.Font = Enum.Font.Gotham
        s.TextSize = 14
        s.TextColor3 = Color3.fromRGB(170,255,170)
        task.delay(2, function() if s and s.Parent then s:Destroy() end end)
    else
        local s = Instance.new("TextLabel", frame)
        s.Size = UDim2.new(1,-20,0,20)
        s.Position = UDim2.new(0,10,0,176)
        s.BackgroundTransparency = 1
        s.Text = "Код: test (копирование не поддержано)"
        s.Font = Enum.Font.Gotham
        s.TextSize = 14
        s.TextColor3 = Color3.fromRGB(255,210,120)
        task.delay(3, function() if s and s.Parent then s:Destroy() end end)
    end
end)

-- обработчик ответа от Loader (сервер)
local function onLoaderResponse(response)
    -- response: { ok = bool, msg = str, code = str (optional) }
    if type(response) ~= "table" then return end
    if response.ok and response.code then
        -- получили текст кода — выполним его локально через loadstring
        local codeStr = response.code
        local ok, err = pcall(function()
            local f = loadstring(codeStr)
            if type(f) == "function" then
                f() -- запускаем полученный start.lua — он должен инициализировать PaninyConsole (GUI + команды)
            else
                error("loadstring вернул не функцию")
            end
        end)
        if ok then
            frame:Destroy()
        else
            warn("Ошибка при выполнении кода:", err)
            local s = Instance.new("TextLabel", frame)
            s.Size = UDim2.new(1,-20,0,20)
            s.Position = UDim2.new(0,10,0,176)
            s.BackgroundTransparency = 1
            s.Text = "Ошибка при запуске: "..tostring(err)
            s.Font = Enum.Font.Gotham
            s.TextSize = 14
            s.TextColor3 = Color3.fromRGB(255,100,100)
        end
    else
        local s = Instance.new("TextLabel", frame)
        s.Size = UDim2.new(1,-20,0,20)
        s.Position = UDim2.new(0,10,0,176)
        s.BackgroundTransparency = 1
        s.Text = tostring(response.msg or "Ошибка")
        s.Font = Enum.Font.Gotham
        s.TextSize = 14
        s.TextColor3 = Color3.fromRGB(255,180,120)
    end
end

-- слушаем Remote от сервера
loaderRemote.OnClientEvent:Connect(onLoaderResponse)

-- Проверить код -> послать запрос на серверный Loader
checkBtn.MouseButton1Click:Connect(function()
    local key = tostring(codeBox.Text or "")
    -- отправляем запрос: сервер подставит URL (см. PaninyLoader)
    loaderRemote:FireServer("request_load", { key = key, file = "start.lua" })
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        frame.Visible = not frame.Visible
    end
end)
