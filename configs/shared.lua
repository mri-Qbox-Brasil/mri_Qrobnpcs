return {
    -- Cops required ON DUTY before locals can be robbed (0 = no requirement). The count comes
    -- from Renewed-Lib's GlobalState.copCount. Which jobs count as police is Renewed's call:
    -- it reads the `inventory:police` convar (default: ["police", "sheriff"]), not a list here.
    requiredCops = 0,
    blacklistedJobs = {     -- Jobs / gangs not allowed to rob locals (checked on the server too)
        'police',
        'ambulance'
    },
}
