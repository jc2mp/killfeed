class 'Killfeed'

function Killfeed:__init()
    Events:Subscribe( "PlayerDeath", self, self.PlayerDeath )
end

function Killfeed:PlayerDeath( args )
    t = {   ["player"]      = args.player,
            ["reason"]      = args.reason }

    if args.killer and args.killer:GetName() ~= args.player:GetName() then
        t.killer            = args.killer

        args.killer:SetMoney( args.killer:GetMoney() + 100 )
    end

    t.id = math.floor( math.random( 1, 3 ) + 0.5 )

    Network:Broadcast( "PlayerDeath", t )
end

local killfeed = Killfeed()