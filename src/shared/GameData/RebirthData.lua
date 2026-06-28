-- RebirthData
-- Author(s): Jesse Appleton
-- Date: 06/28/2026

--[[
    MEMBER      RebirthData.BaseCost: number
    MEMBER      RebirthData.MaxRebirths: number
    FUNCTION    RebirthData.GetCost( rebirths: number ) -> ( number )
    FUNCTION    RebirthData.CanRebirth( clicks: number, rebirths: number ) -> ( boolean )
]]

---------------------------------------------------------------------

local RebirthData = {}

RebirthData.BaseCost = 100
RebirthData.MaxRebirths = 40

function RebirthData.GetCost( rebirths: number ): ( number )
    return RebirthData.BaseCost * 2 ^ rebirths
end

function RebirthData.CanRebirth( clicks: number, rebirths: number ): ( boolean )
    return ( rebirths < RebirthData.MaxRebirths ) and ( clicks >= RebirthData.GetCost(rebirths) )
end

return RebirthData