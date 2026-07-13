fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

author 'xT Development'
description 'Rob NPCs | xT Development'
version '1.1.0'
repository 'https://github.com/xT-Development/xt-robnpcs'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    'configs/shared.lua',
}

client_scripts {
    'configs/client.lua',
    'client/utils.lua',
    'client/cl_main.lua',
}

server_scripts {
    'configs/server.lua',
    'server/sv_main.lua',
}

files {
    'locales/*.json',
}

dependencies {
    'ox_lib',
    'Renewed-Lib',
}
