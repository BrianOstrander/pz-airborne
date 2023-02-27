require "SWAB_Config"

SWAB_DebugContaminationPanel = ISPanel:derive("SWAB_DebugContaminationPanel")
SWAB_DebugContaminationPanel.instance = nil

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function SWAB_DebugContaminationPanel.OnOpenPanel()
    if SWAB_DebugContaminationPanel.instance == nil then
        SWAB_DebugContaminationPanel.instance = SWAB_DebugContaminationPanel:new (50, 200, 250, 250, getPlayer())
        SWAB_DebugContaminationPanel.instance:initialise()
    end

    SWAB_DebugContaminationPanel.instance:addToUIManager()
    SWAB_DebugContaminationPanel.instance:setVisible(true)

    return SWAB_DebugContaminationPanel.instance
end

function SWAB_DebugContaminationPanel:initialise()
    ISPanel.initialise(self)
    -- Ok Button Init
    local btnWid = 100
    local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
    local padBottom = 10

    self.ok = ISButton:new(10, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, "Close", self, SWAB_DebugContaminationPanel.onClick)
    self.ok.internal = "CLOSE"
    self.ok.anchorTop = false
    self.ok.anchorBottom = true
    self.ok:initialise()
    self.ok:instantiate()
    self.ok.borderColor = {r=1, g=1, b=1, a=0.1}
    self:addChild(self.ok)

end

function SWAB_DebugContaminationPanel:prerender()
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    
    local z = 10
    local x = 10
    --self:drawText("Contamination Debug", self.width/2 - (getTextManager():MeasureStringX(UIFont.Medium, "Contamination Debug") / 2), z, 1,1,1,1, UIFont.Medium)
    self:drawText("Contamination Debug", x, z, 1,1,1,1, UIFont.Medium)

    z = z + 20

    local buildingModDataId = "< Outside >"
    local roomModDataId = "< Outside >"

    if getPlayer():getSquare():getRoom() then
        --print("uhh? "..tostring(getPlayer():getSquare():getRoom()))
        buildingModDataId = SWAB_Config.getBuildingModDataId(getPlayer():getSquare():getBuilding():getDef())
        roomModDataId = SWAB_Config.getRoomModDataId(getPlayer():getSquare():getRoom():getRoomDef())
    end

    local modData = getPlayer():getModData()[SWAB_Config.playerModDataId]
    
    z = self:drawField("Position", string.format("%d, %d, %d", getPlayer():getX(), getPlayer():getY(), getPlayer():getZ()), x, z)
    z = self:drawField("Building ModData ID", buildingModDataId, x, z)
    z = self:drawField("Room ModData ID", roomModDataId, x, z)

    local respiratoryExposure = modData.respiratoryExposure
    if respiratoryExposure then
        respiratoryExposure = string.format("%.2f", modData.respiratoryExposure)
    end
    z = self:drawField("Respiratory Exposure", respiratoryExposure, x, z)

    local getPlayerSquareProperties = function()
        square = getCell():getGridSquare(getPlayer():getX(), getPlayer():getY(), getPlayer():getZ())
        if square then
            local properties = square:getProperties()
            if properties then
                local propertiesResult = "propertylist:"
                local propertyList = properties:getPropertyNames()
                for i = 0, propertyList:size() -1 do
                    propertiesResult = propertiesResult..tostring(propertyList:get(i))..":"..tostring(properties:Val(propertyList:get(i))).."\n"
                end
                return propertiesResult
            end    
        end
    end

    local getNeighboringSquare = function(_origin, _direction)
        local SWAB_Building = {}

        SWAB_Building.porousWallsNorth = {}
        SWAB_Building.porousWallsNorth["walls_exterior_wooden_01_41"] = true
        SWAB_Building.porousWallsNorth["walls_exterior_wooden_01_45"] = true
        SWAB_Building.porousWallsNorth["walls_exterior_wooden_01_49"] = true
        SWAB_Building.porousWallsNorth["walls_exterior_wooden_01_53"] = true
        SWAB_Building.porousWallsNorth["constructedobjects_01_65"] = true
        SWAB_Building.porousWallsNorth["constructedobjects_01_73"] = true

        SWAB_Building.porousWallsWest = {}
        SWAB_Building.porousWallsWest["walls_exterior_wooden_01_40"] = true
        SWAB_Building.porousWallsWest["walls_exterior_wooden_01_44"] = true
        SWAB_Building.porousWallsWest["walls_exterior_wooden_01_52"] = true
        SWAB_Building.porousWallsWest["walls_exterior_wooden_01_48"] = true
        SWAB_Building.porousWallsWest["constructedobjects_01_64"] = true
        SWAB_Building.porousWallsWest["constructedobjects_01_72"] = true
        -- ---- Begin copy ---
        local target = nil
        local neighbor = nil
        
        if _direction == IsoDirections.N then
            target = _origin
            neighbor = getCell():getGridSquare(_origin:getX(), _origin:getY() - 1, _origin:getZ())
        elseif _direction == IsoDirections.E then
            target = getCell():getGridSquare(_origin:getX() + 1, _origin:getY(), _origin:getZ())
            neighbor = target
        elseif _direction == IsoDirections.S then
            target = getCell():getGridSquare(_origin:getX(), _origin:getY() + 1, _origin:getZ())
            neighbor = target
        elseif _direction == IsoDirections.W then
            target = _origin
            neighbor = getCell():getGridSquare(_origin:getX() - 1, _origin:getY(), _origin:getZ())
        end
        
        if not target or not neighbor then
            -- print("SWAB: Error, "..tostring(_direction).." neighbor of (".._origin:getX()..",".._origin:getY()..") is nil")
            -- I think this can happen if we're requesting a square very far away from the player.
            return nil
        end

        local targetProperties = target:getProperties()

        if targetProperties:Is("WallNW") then
            -- This is a wall corner
            return nil
        end

        if _direction == IsoDirections.N or _direction == IsoDirections.S then
            -- North or South

            if targetProperties:Is("WallN") and not SWAB_Building.porousWallsNorth[target:getWall(true):getTextureName()] then
                -- This is a wall, and it's not a porous material
                return nil
            end

            if targetProperties:Is("WindowN") and targetProperties:Val("WindowN") == "WindowN" then
                -- This is a window frame and it hase a closed window in it
                local windowNorth = target:getWall(true)
                -- It's possible for getWall to return nil if this is a wall-type window, like the floor to ceiling ones.
                if windowNorth then
                    -- We are a wall that a window can be placed into.
                    if not SWAB_Building.porousWallsNorth[windowNorth:getTextureName()] then
                        -- It's not a porous material
                        return nil
                    end
                end
            end
        else
            -- East or West

            if targetProperties:Is("WallW") and not SWAB_Building.porousWallsWest[target:getWall(false):getTextureName()] then
                -- This is a wall, and it's not a porous material
                return nil
            end

            if targetProperties:Is("WindowW") and targetProperties:Val("WindowW") == "WindowW" then
                -- This is a window frame and it hase a closed window in it
                local windowWest = target:getWall(false)
                -- It's possible for getWall to return nil if this is a wall-type window, like the floor to ceiling ones.
                if windowWest then
                    -- We are a wall that a window can be placed into.
                    if not SWAB_Building.porousWallsWest[target:getWall(false):getTextureName()] then
                        -- It's not a porous material
                        return nil
                    end
                end
            end
        end

        -- No obstructions so far

        local door = _origin:getDoorTo(neighbor)

        if door and not door:IsOpen() and not door:isDestroyed() then
            return nil
        end

        return neighbor
    end
    
    -- if getPlayer() and getPlayer():getSquare() then
    --     z = self:drawField("Neighbor North", tostring(getNeighboringSquare(getPlayer():getSquare(), IsoDirections.N)), x, z)
    --     z = self:drawField("Neighbor East", tostring(getNeighboringSquare(getPlayer():getSquare(), IsoDirections.E)), x, z)
    --     z = self:drawField("Neighbor South", tostring(getNeighboringSquare(getPlayer():getSquare(), IsoDirections.S)), x, z)
    --     z = self:drawField("Neighbor West", tostring(getNeighboringSquare(getPlayer():getSquare(), IsoDirections.W)), x, z)
        
    --     local objects = getPlayer():getSquare():getObjects()
    --     if objects and 0 < objects:size() then
    --         local objectsResult = ""
    --         for i = 0, objects:size() - 1 do
    --             local object = objects:get(i)
    --             objectsResult = objectsResult..tostring(object:getType())..":"..tostring(object:getTextureName()).."\n"
    --         end
    --         z = self:drawField("objs", objectsResult, x, z)
    --     end
    --     z = z + 60
    --     z = self:drawField("curr", getPlayerSquareProperties(), x, z)
    -- end
end

function SWAB_DebugContaminationPanel:drawField(_name, _value, _x, _z)
    self:drawText(_name, _x, _z, 1,1,1,1, UIFont.Small)
    self:drawText(tostring(_value), _x + 120, _z, 1,1,1,1, UIFont.Small)
    --self:drawText(string.format("%.2f", _value), _x + 150, _z, 1,1,1,1, UIFont.Small)
    return _z + 16
end

function SWAB_DebugContaminationPanel:onClick(_button)
    if _button.internal == "CLOSE" then
        
        self:setVisible(false)
        self:removeFromUIManager()
    end
end

--************************************************************************--
--** SWAB_DebugContaminationPanel:new
--**
--************************************************************************--
function SWAB_DebugContaminationPanel:new(_x, _y, _width, _height, _player)
    local o = {}
    _x = getCore():getScreenWidth() / 2 - (_width / 2)
    _y = getCore():getScreenHeight() / 2 - (_height / 2)
    o = ISPanel:new(_x, _y, _width, _height)
    setmetatable(o, self)
    self.__index = self
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    o.width = _width
    o.height = _height
    o.player = _player
    o.moveWithMouse = true
    SWAB_DebugContaminationPanel.instance = o
    return o
end

function SWAB_DebugContaminationPanel.openPanel(_player, _context, _worldObjects, _test)
	_context:addOption("Debug Contamination", _player, SWAB_DebugContaminationPanel.OnOpenPanel)
end
Events.OnPreFillWorldObjectContextMenu.Add(SWAB_DebugContaminationPanel.openPanel)