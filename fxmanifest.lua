fx_version 'adamant'
version '1.0'
game 'gta5'
author 'CodeStudio'
description 'Code Studio Fingerprint Scanner'

ui_page 'ui/index.html'

server_scripts {'@oxmysql/lib/MySQL.lua', 'main/server.lua'}
client_scripts {'main/client.lua'}

shared_scripts {'@ox_lib/init.lua', 'config.lua'}

files {'ui/**'}

lua54 'yes'