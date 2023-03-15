require "ISUI/ISToolTipInv"

SWAB_ISToolTipInv = {}
SWAB_ISToolTipInv.BaseRender = ISToolTipInv.render

function ISToolTipInv:render()
    -- we render the tool tip for inventory item only if there's no context menu showed
    if not ISContextMenu.instance or not ISContextMenu.instance.visibleCheck then

        local itemModData = self.item:getModData() -- TODO: Do this check earlier
        if not itemModData or not itemModData["SwabRespiratoryItem"] then
            -- Bail out early if it's not a respiratory item.
            SWAB_ISToolTipInv.BaseRender(self)
            return
        end

        local mx = getMouseX() + 24;
        local my = getMouseY() + 24;
        if not self.followMouse then
            mx = self:getX()
            my = self:getY()
            if self.anchorBottomLeft then
                mx = self.anchorBottomLeft.x
                my = self.anchorBottomLeft.y
            end
        end

        self.tooltip:setX(mx+11);
        self.tooltip:setY(my);

        self.tooltip:setWidth(50)
        self.tooltip:setMeasureOnly(true)
        self.item:DoTooltip(self.tooltip);
        
        SWAB_ISToolTipInv.RenderConsumption(self, self.tooltip, itemModData)

        self.tooltip:setMeasureOnly(false)

        -- clampy x, y

        local myCore = getCore();
        local maxX = myCore:getScreenWidth();
        local maxY = myCore:getScreenHeight();

        local tw = self.tooltip:getWidth();
        local th = self.tooltip:getHeight();

        self.tooltip:setX(math.max(0, math.min(mx + 11, maxX - tw - 1)));
        if not self.followMouse and self.anchorBottomLeft then
            self.tooltip:setY(math.max(0, math.min(my - th, maxY - th - 1)));
        else
            self.tooltip:setY(math.max(0, math.min(my, maxY - th - 1)));
        end 

        self:setX(self.tooltip:getX() - 11);
        self:setY(self.tooltip:getY());
        self:setWidth(tw + 11);
        self:setHeight(th);
        
        if self.followMouse then
            self:adjustPositionToAvoidOverlap({ x = mx - 24 * 2, y = my - 24 * 2, width = 24 * 2, height = 24 * 2 })
        end

        self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
        self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

        -- local itemModData = self.item:getModData() -- TODO: Do this check earlier
        
        -- if itemModData["SwabRespiratoryItem"] then
        --     self:drawText(self.item:getFullType(), 16, th-32, 1, 1, 1, 1, UIFont.Small)
        -- end

        SWAB_ISToolTipInv.RenderConsumption(self, self.tooltip, itemModData)

        self.item:DoTooltip(self.tooltip);
    end
end

function SWAB_ISToolTipInv:RenderConsumption(_tooltip, _modData)
    local x = 5
    local y = _tooltip:getHeight() - 20

    _tooltip:DrawText(UIFont.Small, getText("ContextMenu_SWAB_Tooltip_Contamination")..":", x, y, 1, 1, 0.8, 1)
    local value = 1 - _modData["SwabRespiratoryExposure_ProtectionRemaining"]
    local color = ColorInfo.new(0, 0, 0, 1)
    getCore():getBadHighlitedColor():interp(getCore():getGoodHighlitedColor(), 1 - value, color)
    -- Getting the X value here is not ideal
    _tooltip:DrawProgressBar(_tooltip:getWidth() - (self:getWidth() / 2) - ((self:getWidth() - _tooltip:getWidth()) / 2), y + 5, 80, 2, value, color:getR(), color:getG(), color:getB(), color:getA())

    _tooltip:setHeight(_tooltip:getHeight() + 16)
end