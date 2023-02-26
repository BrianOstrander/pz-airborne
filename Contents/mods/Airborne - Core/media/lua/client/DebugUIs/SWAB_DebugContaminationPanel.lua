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