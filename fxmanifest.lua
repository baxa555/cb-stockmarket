fx_version "adamant"
version '1.0.0'
author "C-Byte Development"
description "Default"
game "gta5"

client_script "main/client.lua"
server_script "main/server.lua"
shared_script "main/config.lua"

ui_page "index.html"

files {
    'index.html',
    'vue.js',
    'assets/**/*.*',
}

escrow_ignore { 'main/config.lua' }
escrow_ignore { 'main/server.lua' }
escrow_ignore { 'main/client.lua' }

lua54 'yes'