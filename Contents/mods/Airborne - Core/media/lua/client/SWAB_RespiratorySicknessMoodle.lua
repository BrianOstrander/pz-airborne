require "SWAB_Config"
require "MF_ISMoodle"

-- By default values are:
-- bad4     0.1
-- bad3     0.2
-- bad2     0.3
-- bad1     0.4
-- good1    0.6
-- good2    0.7
-- good3    0.8
-- good4    0.9
-- Bad thresholds are upper thresholds while good thresholds are lower thresholds.
-- The moodle is hidden strictly between bad1 and good1.
-- You can deactivate a level by setting its threshold to nil.

SWAB_RespiratorySicknessMoodle = {}
SWAB_RespiratorySicknessMoodle.isInitialized = false

function SWAB_RespiratorySicknessMoodle.Initialize()
    if not SWAB_RespiratorySicknessMoodle.isInitialized then
        MF.createMoodle("swab_respiratory_sickness")
        local moodle = MF.getMoodle("swab_respiratory_sickness")

        if moodle then
            -- MF.getMoodle(*):setThresholds(bad4, bad3, bad2, bad1,   good1, good2, good3, good4)
            moodle:setThresholds(0.1, 0.2, 0.3, 0.4,  nil, nil, nil, nil)
            moodle:setValue(1.0)

            moodle:setPicture(2, 1, getTexture("media/ui/swab_moodles_respiratory_sickness_bad_1.png"))
            moodle:setPicture(2, 2, getTexture("media/ui/swab_moodles_respiratory_sickness_bad_2.png"))
            moodle:setPicture(2, 3, getTexture("media/ui/swab_moodles_respiratory_sickness_bad_3.png"))
            moodle:setPicture(2, 4, getTexture("media/ui/swab_moodles_respiratory_sickness_bad_4.png"))

            SWAB_RespiratorySicknessMoodle.isInitialized = true
        end
    end
    return SWAB_RespiratorySicknessMoodle.isInitialized
end
Events.OnCreatePlayer.Add(SWAB_RespiratorySicknessMoodle.Initialize)

function SWAB_RespiratorySicknessMoodle.EveryOneMinute()
    if SWAB_RespiratorySicknessMoodle.Initialize() then
        local moodle = MF.getMoodle("swab_respiratory_sickness")
        if moodle then
            local modData = getPlayer():getModData()["swab_player"]
            if modData and modData.respiratorySicknessLevel then
                moodle:setValue(SWAB_Config.GetRespiratorySicknessEffects(modData.respiratorySicknessLevel).moodle)
            end
        end
    end
end
Events.EveryOneMinute.Add(SWAB_RespiratorySicknessMoodle.EveryOneMinute)