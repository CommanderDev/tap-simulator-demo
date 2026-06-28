-- UIComponent
-- Author(s): Jesse Appleton
-- Date: 06/28/2026

--[[
    CONSTRUCTOR UIComponent.new() -> ( UIComponent )
    METHOD      UIComponent:_track( connection ) -> ( connection )
    METHOD      UIComponent:Destroy() -> ()
]]

---------------------------------------------------------------------

local UIComponent = {}
UIComponent.__index = UIComponent

function UIComponent.new()
    return setmetatable( {
        _connections = {};
    }, UIComponent )
end

function UIComponent:_track( connection )
    table.insert( self._connections, connection )
    return connection
end

function UIComponent:Destroy(): ()
    for _, connection in self._connections do
        connection:Disconnect()
    end
    table.clear( self._connections )
end

return UIComponent