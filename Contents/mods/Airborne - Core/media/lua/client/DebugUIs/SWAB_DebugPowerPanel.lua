require "SWAB_Config"
require "SWAB_Utilities"

SWAB_DebugPowerPanel = ISPanel:derive("SWAB_DebugPowerPanel")
SWAB_DebugPowerPanel.instance = nil

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function SWAB_DebugPowerPanel.OnOpenPanel()
    if SWAB_DebugPowerPanel.instance == nil then
        SWAB_DebugPowerPanel.instance = SWAB_DebugPowerPanel:new (50, 200, 250, 250, getPlayer())
        SWAB_DebugPowerPanel.instance:initialise()
    end

    SWAB_DebugPowerPanel.instance:addToUIManager()
    SWAB_DebugPowerPanel.instance:setVisible(true)

    return SWAB_DebugPowerPanel.instance
end

function SWAB_DebugPowerPanel:initialise()
    ISPanel.initialise(self)
    -- Button initializations
    local btnWid = 100
    local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
    local padBottom = 10

    -- Close Button
    self.closeButton = ISButton:new(10, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, "Close", self, SWAB_DebugPowerPanel.onClickCloseButton)
    self.closeButton.internal = "CLOSE"
    self.closeButton.anchorTop = false
    self.closeButton.anchorBottom = true
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self.closeButton.borderColor = {r=1, g=1, b=1, a=0.1}
    self:addChild(self.closeButton)

end

function SWAB_DebugPowerPanel:prerender()
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    
    local z = 10
    local x = 10
    self:drawText("Power Debug", x, z, 1,1,1,1, UIFont.Medium)

    z = z + 20

    z = self:drawField("Position", string.format("%d, %d, %d", getPlayer():getX(), getPlayer():getY(), getPlayer():getZ()), x, z)

    if getPlayer():getSquare() then
        local square = getPlayer():getSquare()
        z = self:drawField("haveElectricity", square:haveElectricity(), x, z)
        z = self:drawField("Generator", SWAB_Utilities.GetGenerator(square), x, z)
    end
end

function SWAB_DebugPowerPanel:drawFloat(_name, _value, _x, _z)
    if _value and type(_value) == "number" then
        _value = string.format("%.2f", _value)
    else
        _value = tostring(_value)
    end
    return self:drawField(_name, _value, _x, _z)
end

function SWAB_DebugPowerPanel:drawField(_name, _value, _x, _z)
    self:drawText(_name, _x, _z, 1,1,1,1, UIFont.Small)
    self:drawText(tostring(_value), _x + 135, _z, 1,1,1,1, UIFont.Small)
    return _z + 16
end

function SWAB_DebugPowerPanel:onClickCloseButton(_button)
    self:setVisible(false)
    self:removeFromUIManager()
end

--************************************************************************--
--** SWAB_DebugPowerPanel:new
--**
--************************************************************************--
function SWAB_DebugPowerPanel:new(_x, _y, _width, _height, _player)
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
    SWAB_DebugPowerPanel.instance = o
    return o
end

function SWAB_DebugPowerPanel.openPanel(_player, _context, _worldObjects, _test)
	_context:addOption("Debug Power", _player, SWAB_DebugPowerPanel.OnOpenPanel)
end
Events.OnPreFillWorldObjectContextMenu.Add(SWAB_DebugPowerPanel.openPanel)