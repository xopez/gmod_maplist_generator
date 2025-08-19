if SERVER then
    -- Base paths
    local dataFolder = "maplist-generator"
    local configFile = dataFolder .. "/config.json"

    -- Default configuration
    local defaultConfig = {
        fileName = "maps.txt", -- Output file name in data/maplist-generator
        prefixes = { "gm_", "cs_" }, -- Prefix filter (empty = all maps)
    }

    -- Ensure the data folder exists
    local function EnsureDataFolder()
        if not file.IsDir(dataFolder, "DATA") then
            file.CreateDir(dataFolder)
        end
    end

    -- Load config or create default
    local function LoadOrCreateConfig()
        EnsureDataFolder()
        if not file.Exists(configFile, "DATA") then
            local json = util.TableToJSON(defaultConfig, false)
            file.Write(configFile, json)
            print("[MapList Generator] Config created: " .. configFile)
            return table.Copy(defaultConfig)
        else
            local raw = file.Read(configFile, "DATA")
            local cfg = util.JSONToTable(raw)
            if not cfg then
                print("[MapList Generator] Error: Config invalid, using defaults.")
                return table.Copy(defaultConfig)
            end
            -- Add missing fields
            for k, v in pairs(defaultConfig) do
                if cfg[k] == nil then
                    cfg[k] = v
                end
            end
            return cfg
        end
    end

    -- Get all maps from all mount paths
    local function GetAllMaps(prefixes)
        local allMaps = {}
        local foundMaps = file.Find("maps/*.bsp", "GAME")
        for _, map in ipairs(foundMaps) do
            local name = string.StripExtension(map)
            if not prefixes or #prefixes == 0 then
                table.insert(allMaps, name)
            else
                for _, prefix in ipairs(prefixes) do
                    if string.StartWith(name:lower(), prefix:lower()) then
                        table.insert(allMaps, name)
                        break
                    end
                end
            end
        end
        table.sort(allMaps)
        return allMaps
    end

    -- Save map list
    local function SaveMapList(maps, fileName)
        local filePath = dataFolder .. "/" .. fileName
        file.Write(filePath, table.concat(maps, "\n"))
        print(string.format("[MapList Generator] %d maps saved to: data/%s", #maps, filePath))
    end

    -- Main function
    local function GenerateMapList()
        local cfg = LoadOrCreateConfig()
        local maps = GetAllMaps(cfg.prefixes or {})
        SaveMapList(maps, cfg.fileName)
    end

    -- Run on server start and with delay
    -- Note: GenerateMapList is called twice (immediately and after 10 seconds)
    -- to ensure all maps are detected correctly after server start.
    -- Some mounts/files may only become available after a short delay.
    hook.Add("Initialize", "MapListGenerator_Init", function()
        timer.Simple(10, function()
            GenerateMapList()
        end)
    end)
end
