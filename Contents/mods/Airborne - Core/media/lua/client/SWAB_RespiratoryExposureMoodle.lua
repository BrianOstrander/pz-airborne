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

SWAB_RespiratoryExposureMoodle = {}
SWAB_RespiratoryExposureMoodle.isInitialized = false

function SWAB_RespiratoryExposureMoodle.Initialize()
    if not SWAB_RespiratoryExposureMoodle.isInitialized then
        MF.createMoodle("swab_respiratory_exposure")
        local moodle = MF.getMoodle("swab_respiratory_exposure")

        if moodle then
            -- MF.getMoodle(*):setThresholds(bad4, bad3, bad2, bad1,   good1, good2, good3, good4)
            moodle:setThresholds(0.1, 0.2, 0.3, 0.4,  nil, nil, nil, nil)
            moodle:setValue(1.0)

            moodle:setPicture(2, 1, getTexture("media/ui/swab_moodles_respiratory_exposure_bad_1.png"))
            moodle:setPicture(2, 2, getTexture("media/ui/swab_moodles_respiratory_exposure_bad_2.png"))
            moodle:setPicture(2, 3, getTexture("media/ui/swab_moodles_respiratory_exposure_bad_3.png"))
            moodle:setPicture(2, 4, getTexture("media/ui/swab_moodles_respiratory_exposure_bad_4.png"))

            SWAB_RespiratoryExposureMoodle.isInitialized = true
        end
    end
    return SWAB_RespiratoryExposureMoodle.isInitialized
end
Events.OnCreatePlayer.Add(SWAB_RespiratoryExposureMoodle.Initialize)

function SWAB_RespiratoryExposureMoodle.EveryOneMinute()
    if SWAB_RespiratoryExposureMoodle.Initialize() then
        local moodle = MF.getMoodle("swab_respiratory_exposure")
        if moodle then
            local modData = getPlayer():getModData().swab_player
            if modData and modData.respiratoryExposureLevel then
                -- We use respiratoryExposureLevel instead of respiratoryAbsorptionLevel so that there 
                -- is no confusion between players with different traits and professions. The moodle
                -- should always indicate exposure to a typical player, with gear taken into account.
                -- TODO: Find a way to illustrate when a player has trait or profession bonuses that
                -- are protecting them more than the average player.
                moodle:setValue(SWAB_Config.GetRespiratoryExposureEffects(modData.respiratoryExposureLevel).moodle)
            end
        end
    end
end
Events.EveryOneMinute.Add(SWAB_RespiratoryExposureMoodle.EveryOneMinute)