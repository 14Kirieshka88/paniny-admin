-- PaninyGUI (LocalScript в StarterPlayerScripts)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Remote для результатов/команд (сервер шлёт ответы сюда)
local PANINY_REMOTE = ReplicatedStorage:WaitForChild("PaninyRemote") -- создаётся Loader'ом/Server'ом

-- UI
local screenGui = Instance.new("ScreenGui", PlayerGui)
screenGui.Name = "PaninyConsoleGUI"
screenGui.ResetOnSpawn = false

local main = Instance.new("Frame", screenGui)
main.Name = "Main"
main.Size = UDim2.new(0,600,0,400)
main.Position = UDim2.new(0.5,-300,0.12,0)
main.BackgroundColor3 = Color3.fromRGB(24,24,24)
main.BorderSizePixel = 0
main.AnchorPoint = Vector2.new(0.5,0)

-- скругление
local corner = Instance.new("UICorner", main)
corner.CornerRadius = UDim.new(0,12)

-- header
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,44)
header.BackgroundTransparency = 1

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1,-50,1,0)
title.Position = UDim2.new(0,10,0,0)
title.BackgroundTransparency = 1
title.Text = "Paniny Console"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextXAlignment = Enum.TextXAlignment.Left

local settingsBtn = Instance.new("TextButton", header)
settingsBtn.Size = UDim2.new(0,36,0,36)
settingsBtn.Position = UDim2.new(1,-46,0,4)
settingsBtn.Text = "⚙"
settingsBtn.Font = Enum.Font.Gotham
settingsBtn.TextSize = 18
settingsBtn.BackgroundTransparency = 0.6
settingsBtn.AutoButtonColor = true
local settingsCorner = Instance.new("UICorner", settingsBtn); settingsCorner.CornerRadius = UDim.new(0,8)

-- output
local output = Instance.new("ScrollingFrame", main)
output.Size = UDim2.new(1,-20,1,-140)
output.Position = UDim2.new(0,10,0,54)
output.CanvasSize = UDim2.new(0,0)
output.AutomaticCanvasSize = Enum.AutomaticSize.Y
output.ScrollBarThickness = 6
output.BackgroundTransparency = 1

local uiList = Instance.new("UIListLayout", output)
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding = UDim.new(0,6)

-- input
local inputBox = Instance.new("TextBox", main)
inputBox.Size = UDim2.new(1,-120,0,36)
inputBox.Position = UDim2.new(0,10,1,-70)
inputBox.PlaceholderText = "Введите команду..."
inputBox.Font = Enum.Font.Gotham
inputBox.TextSize = 18
inputBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
local inCorner = Instance.new("UICorner", inputBox); inCorner.CornerRadius = UDim.new(0,8)

local enterBtn = Instance.new("TextButton", main)
enterBtn.Size = UDim2.new(0,90,0,36)
enterBtn.Position = UDim2.new(1,-100,1,-70)
enterBtn.Text = "Enter"
enterBtn.Font = Enum.Font.GothamBold
enterBtn.TextSize = 18
enterBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
local enterCorner = Instance.new("UICorner", enterBtn); enterCorner.CornerRadius = UDim.new(0,8)

-- profile area (иконка)
local profile = Instance.new("Frame", main)
profile.Size = UDim2.new(0,100,0,36)
profile.Position = UDim2.new(0,10,1,-120)
profile.BackgroundTransparency = 1
local profLbl = Instance.new("TextLabel", profile)
profLbl.Size = UDim2.new(1,0,1,0)
profLbl.BackgroundTransparency = 1
profLbl.Text = "Profile: "..LocalPlayer.Name
profLbl.Font = Enum.Font.Gotham
profLbl.TextSize = 14
profLbl.TextColor3 = Color3.fromRGB(200,200,200)

-- functions
local function writeLine(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,18)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(220,220,220)
    lbl.Text = text
    lbl.Parent = output
    output.CanvasSize = UDim2.new(0,0,0,uiList.AbsoluteContentSize.Y + 10)
end

-- hide/show with RightControl
local hidden = false
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        hidden = not hidden
        main.Visible = not hidden
        if hidden then writeLine("Console hidden (RightCtrl to show)") else writeLine("Console shown") end
    end
end)

-- settings open (пока что простое сообщение; файл настроек подключается отдельно)
settingsBtn.MouseButton1Click:Connect(function()
    writeLine("Открыл настройки (см. PaninySettings ModuleScript)")
end)

-- обработка нажатия Enter
local function sendInput(txt)
    if not txt or txt:match("^%s*$") then return end
    writeLine("> "..txt)
    -- отправляем команду серверу через PaninyRemote (либо Start будет парсером)
    -- Подразумеваем, что Start.lua парсит команды и отправляет на PaninyRemote
    -- Здесь просто триггерим событие на репозитории, Start(LocalScript) должен слушать
    local ev = ReplicatedStorage:FindFirstChild("PaninyConsoleCommand")
    if ev and ev:IsA("RemoteEvent") then
        ev:FireServer(txt)
    else
        writeLine("[ЛОКАЛ] Нет RemoteEvent PaninyConsoleCommand — локальная отработка")
    end
    inputBox.Text = ""
end

enterBtn.MouseButton1Click:Connect(function()
    sendInput(inputBox.Text)
end)

inputBox.FocusLost:Connect(function(entered)
    if entered then
        sendInput(inputBox.Text)
    end
end)

-- ловим ответы от серверного Remote, выводим
PANINY_REMOTE.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    if data.ok then
        writeLine("[OK] "..tostring(data.msg or "OK"))
    else
        writeLine("[ERR] "..tostring(data.msg or "Ошибка"))
    end
end)

-- слушаем атрибут Paniny_Fly для локального включения полёта
LocalPlayer:GetAttributeChangedSignal("Paniny_Fly"):Connect(function()
    local val = LocalPlayer:GetAttribute("Paniny_Fly")
    if val then
        writeLine("Fly включён (локальный эффект)")
        -- Простой пример: добавить BodyVelocity на HumanoidRootPart
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and not hrp:FindFirstChild("PaninyBV") then
                local bv = Instance.new("BodyVelocity")
                bv.Name = "PaninyBV"
                bv.MaxForce = Vector3.new(1e5,1e5,1e5)
                bv.Velocity = Vector3.new(0,0,0)
                bv.Parent = hrp
            end
        end
    else
        writeLine("Fly выключён")
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local bv = hrp:FindFirstChild("PaninyBV")
                if bv then bv:Destroy() end
            end
        end
    end
end)

-- аналогично можно слушать Paniny_Invis и проч.

-- Изначально скрываем GUI — Start скрипт откроет его после загрузки
main.Visible = false
writeLine("PaninyGUI инициализирован (ожидание запуска через Start).")
