-- PaninyLoader (Script в ServerScriptService)
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Settings = require(ReplicatedStorage:WaitForChild("PaninySettings"))
local Players = game:GetService("Players")

-- RemoteEvent: PaninyLoaderRemote (server <-> client for loader)
local loaderName = "PaninyLoaderRemote"
local loaderRemote = ReplicatedStorage:FindFirstChild(loaderName)
if not loaderRemote then
    loaderRemote = Instance.new("RemoteEvent")
    loaderRemote.Name = loaderName
    loaderRemote.Parent = ReplicatedStorage
end

-- RemoteEvent: PaninyRemote (используется для ответов/уведомлений)
local paninyRemote = ReplicatedStorage:FindFirstChild("PaninyRemote")
if not paninyRemote then
    paninyRemote = Instance.new("RemoteEvent")
    paninyRemote.Name = "PaninyRemote"
    paninyRemote.Parent = ReplicatedStorage
end

-- RemoteEvent: PaninyConsoleCommand (клиент -> сервер: посылает текст команды)
local cmdEv = ReplicatedStorage:FindFirstChild("PaninyConsoleCommand")
if not cmdEv then
    cmdEv = Instance.new("RemoteEvent")
    cmdEv.Name = "PaninyConsoleCommand"
    cmdEv.Parent = ReplicatedStorage
end

-- Простейшая защита: cooldown на запросы
local requestCooldown = {}
local COOLDOWN = 2

loaderRemote.OnServerEvent:Connect(function(player, action, payload)
    if action ~= "request_load" then
        loaderRemote:FireClient(player, { ok = false, msg = "Unknown action" })
        return
    end

    local now = tick()
    local last = requestCooldown[player.UserId] or 0
    if now - last < COOLDOWN then
        loaderRemote:FireClient(player, { ok = false, msg = "Too many requests, подожди" })
        return
    end
    requestCooldown[player.UserId] = now

    local key = (payload and payload.key) and tostring(payload.key) or ""
    local file = (payload and payload.file) and tostring(payload.file) or Settings.DEFAULT_FILE

    if not Settings.VALID_KEYS[key] then
        loaderRemote:FireClient(player, { ok = false, msg = "Неверный код" })
        return
    end

    -- Собираем URL (raw GitHub). Пользуемся RAW_BASE из настроек; если в RAW_BASE нет "raw.githubusercontent.com",
    -- предполагаем что Settings.RAW_BASE уже корректен.
    -- Пример: если RAW_BASE = "https://raw.githubusercontent.com/14Kirieshka88/paniny-admin/main/"
    local url = Settings.RAW_BASE
    if url:sub(-1) ~= "/" then url = url .. "/" end
    url = url .. file

    -- Запрос
    local ok, result = pcall(function() return HttpService:GetAsync(url) end)
    if not ok then
        loaderRemote:FireClient(player, { ok = false, msg = "HTTP ошибка: "..tostring(result) })
        return
    end

    -- Отправляем код клиенту (он выполнит через loadstring)
    loaderRemote:FireClient(player, { ok = true, msg = "Код получен", code = result })
end)

-- Обработчик команд, посылаемых клиентом
local CommandsModule
-- Попробуем require PaninyCommands (если доступен)
local m = ReplicatedStorage:FindFirstChild("PaninyCommands")
if m and m:IsA("ModuleScript") then
    CommandsModule = require(m)
end

cmdEv.OnServerEvent:Connect(function(player, text)
    -- Парсинг строки простейший: команда и аргументы
    if type(text) ~= "string" then
        paninyRemote:FireClient(player, { ok=false, msg="Неверный формат команды" })
        return
    end
    local parts = {}
    for part in text:gmatch("%S+") do table.insert(parts, part) end
    local cmd = parts[1] and parts[1]:lower()
    if not cmd then paninyRemote:FireClient(player, { ok=false, msg="Пустая команда" }); return end

    -- Если есть CommandsModule, пытаемся вызвать серверную команду
    if CommandsModule and CommandsModule.commands and CommandsModule.commands[cmd] then
        -- собираем args
        local args = {}
        for i=2,#parts do
            table.insert(args, parts[i])
        end
        local ok, res1, res2 = pcall(function()
            return CommandsModule.commands[cmd](player, table.unpack(args))
        end)
        if ok then
            if type(res1) == "boolean" then
                paninyRemote:FireClient(player, { ok = res1, msg = tostring(res2 or "OK") })
            else
                paninyRemote:FireClient(player, { ok = true, msg = tostring(res1 or "OK") })
            end
        else
            paninyRemote:FireClient(player, { ok = false, msg = "Ошибка при выполнении команды: "..tostring(res1) })
        end
    else
        paninyRemote:FireClient(player, { ok = false, msg = "Серверная команда не найдена: "..tostring(cmd) })
    end
end)

print("PaninyLoader инициализирован")
