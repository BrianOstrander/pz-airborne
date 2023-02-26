require "SWAB_Config"
require "SWAB_Utilities"

SWAB_Data = {}

function SWAB_Data.Save()
	if SWAB_Config.debug.logging then
        print("SWAB: SWAB_Data.Save")
    end

    GameTime:getInstance():getModData()["swab_saveData"] = SWAB_Data.saveData

    if not SWAB_Utilities.IsSinglePlayer() then
        if SWAB_Config.debug.logging then
            print("SWAB: ModData.add & ModData.transmit")
        end
        ModData.add("swab_saveData", SWAB_Data.saveData)
        ModData.transmit("swab_saveData")
    end
end

function SWAB_Data.Load()
	if SWAB_Utilities.IsSinglePlayer() then
        -- Singleplayer
        if SWAB_Config.debug.logging then
            print("SWAB: SWAB_Data.Load as Singleplayer")
        end
        SWAB_Data.saveData = GameTime:getInstance():getModData()["swab_saveData"]
    elseif isServer() then        
        -- Dedicated Server
        if SWAB_Config.debug.logging then
            print("SWAB: SWAB_Data.Load as Dedicated Server")
        end
        ModData.add("swab_saveData", GameTime:getInstance():getModData()["swab_saveData"])
        SWAB_Data.saveData = ModData.get("swab_saveData")
    else
        -- Client
        if SWAB_Config.debug.logging then
            print("SWAB: SWAB_Data.Load as Client")
        end
        SWAB_Data.saveData = ModData.get("swab_saveData")
    end
end

function SWAB_Data.OnReceiveGlobalModData(key, modData)
    if key == "swab_saveData" and modData then
        if isServer() then
            -- if SWAB_Data.saveData and modData and SWAB_Data.saveData.systemRepairComplete ~= modData.systemRepairComplete then
            --     if not SWAB_Data.saveData.systemRepairComplete then
            --         if SWAB_Config.debug.logging then
            --             print("SWAB: Server recieved client transmission setting systemRepairComplete to true")
            --         end
            --         SWAB_Data.saveData.systemRepairComplete = true
            --         SWAB_Data.Save()
            --     end
            -- elseif SWAB_Config.debug.logging then
            --     print("SWAB: Server recieved client transmission, but value from client ignored")
            -- end
        elseif isClient() then
            if SWAB_Config.debug.logging then
                print("SWAB: Client recieved server transmission")
            end
            ModData.add(key, modData)
        end 
    end
end
Events.OnReceiveGlobalModData.Add(SWAB_Data.OnReceiveGlobalModData)