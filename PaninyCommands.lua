-- PaninyCommands (ModuleScript в ReplicatedStorage)
local Modules = {}
local Players = game:GetService("Players")

-- Список админов по UserId — замените на свои id
local Admins = {
    [12345678] = true,
    -- [11111111] = true,
}

local function isAdmin(player)
    return player and Admins[player.UserId]
end

local function findPlayerByName(name)
    if not name then return nil end
    name = string.lower(name)
    for _,p in pairs(Players:GetPlayers()) do
        if string.sub(string.lower(p.Name),1,#name) == name or (p.DisplayName and string.sub(string.lower(p.DisplayName),1,#name) == name) then
            return p
        end
    end
    return nil
end

Modules.commands = {}

-- fly: ставим атрибут, клиент слушает изменения
Modules.commands["fly"] = function(invoker, targetName, off)
    if not isAdmin(invoker) then return false, "Нет прав" end
    local target = (targetName == "me" and invoker) or findPlayerByName(targetName)
    if not target then return false, "Игрок не найден" end
    target:SetAttribute("Paniny_Fly", not off)
    return true, "fly -> "..target.Name
end

Modules.commands["bring"] = function(invoker, targetName)
    if not isAdmin(invoker) then return false, "Нет прав" end
    local target = findPlayerByName(targetName)
    if not target or not target.Character or not invoker.Character then return false, "Игрок/персонаж не найден" end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    local myHrp = invoker.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not myHrp then return false, "HumanoidRootPart не найден" end
    hrp.CFrame = myHrp.CFrame + Vector3.new(0,0,3)
    return true, "bring -> "..target.Name
end

Modules.commands["heal"] = function(invoker, targetName)
    if not isAdmin(invoker) then return false, "Нет прав" end
    local target = (targetName == "me" and invoker) or findPlayerByName(targetName)
    if not target or not target.Character then return false, "Игрок не найден" end
    local humanoid = target.Character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then humanoid.Health = humanoid.MaxHealth end
    return true, "heal -> "..target.Name
end

Modules.commands["tp"] = function(invoker, targetName, x,y,z)
    if not isAdmin(invoker) then return false, "Нет прав" end
    local target = (targetName == "me" and invoker) or findPlayerByName(targetName)
    if not target or not target.Character then return false, "Игрок не найден" end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, "HumanoidRootPart не найден" end
    hrp.CFrame = CFrame.new(tonumber(x) or 0, tonumber(y) or 5, tonumber(z) or 0)
    return true, "tp -> "..target.Name
end

Modules.commands["kill"] = function(invoker, targetName)
    if not isAdmin(invoker) then return false, "Нет прав" end
    local target = (targetName == "me" and invoker) or findPlayerByName(targetName)
    if not target or not target.Character then return false, "Игрок не найден" end
    local humanoid = target.Character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then humanoid.Health = 0 end
    return true, "kill -> "..target.Name
end

-- speed (меняем WalkSpeed)
Modules.commands["speed"] = function(invoker, targetName, speed, off)
    if not isAdmin(invoker) then return false, "Нет прав" end
    local target = (targetName == "me" and invoker) or findPlayerByName(targetName)
    if not target or not target.Character then return false, "Игрок не найден" end
    local humanoid = target.Character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return false, "Humanoid не найден" end
    if off then
        humanoid.WalkSpeed = 16
    else
        humanoid.WalkSpeed = tonumber(speed) or 50
    end
    return true, "speed -> "..target.Name
end

-- invis: сервер ставит атрибут, клиент делает визуал локально
Modules.commands["invis"] = function(invoker, targetName, off)
    if not isAdmin(invoker) then return false, "Нет прав" end
    local target = (targetName == "me" and invoker) or findPlayerByName(targetName)
    if not target then return false, "Игрок не найден" end
    target:SetAttribute("Paniny_Invis", not off)
    return true, "invis -> "..target.Name
end

-- sit/god можно добавить аналогично; для краткости здесь базовый набор

return Modules
