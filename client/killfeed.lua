class 'Killfeed'

function Killfeed:__init()
    self.active = true
    self.list = {}
    self.removal_time = 10

    self:CreateKillStrings()

    Network:Subscribe( "PlayerDeath", self, self.PlayerDeath )
    Events:Subscribe( "Render", self, self.Render )
    Events:Subscribe( "LocalPlayerChat", self, self.LocalPlayerChat )

    Events:Subscribe( "ModuleLoad", self, self.ModulesLoad )
    Events:Subscribe( "ModulesLoad", self, self.ModulesLoad )
    Events:Subscribe( "ModuleUnload", self, self.ModuleUnload )
end

function Killfeed:PlayerDeath( args )
    if not IsValid( args.player ) then return end

    if args.killer ~= nil then
        args.message = string.format( 
            self.killer_msg[args.reason][args.id], 
            args.player:GetName(), 
            args.killer:GetName() )

        args.killer_name   = args.killer:GetName()
        args.killer_colour = args.killer:GetColor()
    else
        args.message = string.format( 
            self.no_killer_msg[args.reason][args.id], 
            args.player:GetName() )
    end

    args.player_name   = args.player:GetName()
    args.player_colour = args.player:GetColor()

    args.time = os.clock()

    table.insert( self.list, args )
end

function Killfeed:CreateKillStrings()
    self.no_killer_msg = {
        [DamageEntity.None] = { 
            "%s died of an unknown cause!",
            "%s had a heart-attack!",
            "%s passed away of natural causes!"
        },

        [DamageEntity.Physics] = { 
            "%s was killed by the awesome power of physics!",
            "%s hit something - fatally!",
            "%s learnt that the laws of physics hate them!"
        },

        [DamageEntity.Bullet] = { 
            "%s was gunned down!",
            "%s was fatally shot!",
            "%s died of lead poisoning!"
        },

        [DamageEntity.Explosion] = { 
            "%s couldn't withstand the power of EXPLOSIONS!",
            "%s was explosively fragmented!",
            "%s will have to be glued back together. IN HELL!"
        },
		[DamageEntity.Vehicle] = {
			"%s forgot to put their seatbelt on!",
			"%s got hit by a vehicle!",
			"%s faked their driver's license!"
		}
    }

    self.killer_msg = {
        [DamageEntity.None] = { 
            "%s was somehow killed by %s!",
            "%s was touched by the magic of %s!",
            "%s felt the power of the impossible from %s!"
        },

        [DamageEntity.Physics] = { 
            "%s couldn't handle the physical power of %s!",
            "%s suffered massive physical trauma at the hands of %s!",
            "%s met physics, and its messenger was %s!"
        },

        [DamageEntity.Bullet] = { 
            "%s was mowed down by %s!",
            "%s was shredded by %s!",
            "%s was peppered with bullets by %s!",
        },

        [DamageEntity.Explosion] = { 
            "%s was blown into a million pieces by %s!",
            "%s: now powered by explosions, courtesy of %s!",
            "%s's love of exploding was fed by %s!"
        },
		[DamageEntity.Vehicle] = {
			"%s was run over by %s!",
			"%s got caught in a roadrage by %s!",
			"%s was killed in a carmageddon by %s!"
		}
    }
end

function Killfeed:CalculateAlpha( time )
    local difftime = os.clock() - time
    local removal_time_gap = self.removal_time - 1

    if difftime < removal_time_gap then
        return 255
    elseif difftime >= removal_time_gap and difftime < self.removal_time then
        local interval = difftime - removal_time_gap
        return 255 * (1 - interval)
    else
        return 0
    end
end

function Killfeed:LocalPlayerChat( args )
    if args.text == "/killfeed" then
        self.active = not self.active

        if self.active then
            Chat:Print( "Killfeed now on!", Color( 255, 255, 255 ) )
        else
            Chat:Print( "Killfeed now off!", Color( 255, 255, 255 ) )
        end
    end
end

function Killfeed:ModulesLoad()
    Events:Fire( "HelpAddItem",
        {
            name = "Killfeed",
            text = 
                "The killfeed is the scrolling list of deaths on the right of " ..
                "the screen. It only shows deaths near you.\n \n" ..
                "To toggle it, type /killfeed in chat and hit enter."
        } )
end

function Killfeed:ModuleUnload()
    Events:Fire( "HelpRemoveItem",
        {
            name = "Killfeed"
        } )
end

function Killfeed:Render( args )
    if Game:GetState() ~= GUIState.Game then return end
    if not self.active then return end

    local center_hint = Vector2( Render.Width - 5, Render.Height / 2 )
    local height_offset = 0

    for i,v in ipairs(self.list) do
        if os.clock() - v.time < self.removal_time then
            local text_width = Render:GetTextWidth( v.message )
            local text_height = Render:GetTextHeight( v.message )

            local pos = center_hint + Vector2( -text_width, height_offset )
            local alpha = self:CalculateAlpha( v.time )

            local shadow_colour = 
                Color( 20, 20, 20, alpha * 0.5 )

            Render:DrawText( pos + Vector2( 1, 1 ), v.message, shadow_colour )
            Render:DrawText( pos, v.message, 
                Color( 255, 255, 255, alpha ) )

            local player_colour = v.player_colour
            player_colour.a = alpha

            Render:DrawText( 
                pos, 
                v.player_name, 
                player_colour )

            if v.killer_name ~= nil then
                local killer_colour = v.killer_colour
                killer_colour.a = alpha
                local name_text = v.killer_name .. "!"
                local name_width = Render:GetTextWidth( name_text )

                Render:DrawText( 
                    center_hint + Vector2( -name_width, height_offset ), 
                    v.killer_name, 
                    killer_colour )
            end

            height_offset = height_offset + text_height
        else
            table.remove( self.list, i )
        end
    end
end

local killfeed = Killfeed()