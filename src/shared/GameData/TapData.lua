-- TapData
-- Author(s): Jesse Appleton
-- Date: 06/28/2026

--[[
    MEMBER      TapData.BaseClicksPerTap: number
    MEMBER      TapData.MinTapInterval: number
    FUNCTION    TapData.GetClicksPerTap( rebirths: number ) -> ( number )
]]

---------------------------------------------------------------------

local TapData = {}

TapData.BaseClicksPerTap = 1
TapData.MinTapInterval = 0.04

function TapData.GetClicksPerTap( rebirths: number ): ( number )
    return TapData.BaseClicksPerTap * 2 ^ rebirths
end

return TapData