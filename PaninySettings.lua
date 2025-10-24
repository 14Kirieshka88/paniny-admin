-- PaninySettings (ModuleScript в ReplicatedStorage)
local Settings = {}

Settings.RAW_BASE = "https://raw.githubusercontent.com/14Kirieshka88/paniny-admin/"
-- Ветка и папка в репозитории (конец со слэшем) — Loader подставит file, например "start.lua"
Settings.DEFAULT_FILE = "start.lua"

-- Стартовые ключи
Settings.VALID_KEYS = {
    ["1"] = true,
    -- добавь свои ключи
}

-- Админы (копируется в PaninyCommands, но можно хранить централизованно)
Settings.Admins = {
    [12345678] = true,
}

-- UI prefs
Settings.Theme = "dark" -- "light" или "dark"

return Settings
