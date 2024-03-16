#!/bin/bash
savefile="/Users/ilja/Library/Tabletop Simulator/Saves/TS_Save_54.json"
backupfile="./savefile_backup.json"
templatefile="./template_workshop.json"
luascript_start='"LuaScript":'
cp "$savefile" "$backupfile"
# Check if there are changes in the backup file compared to the git repository
if [[ $(git diff --quiet "$backupfile") ]]; then
    # Push the backup file to the git repository
    git add "$backupfile"
    git commit -m "Update backup file"
    git push origin master
fi
# Replace the value of "LuaScript" in the backup file with the Placeholder
jq '.LuaScript = "Lua Script gets inserted here"' "$backupfile" > "$templatefile"
cd ..
rm -f bundle.*
luabundler bundle kdm/Global.ttslua \
-p "?.ttslua" \
-o bundle.lua

# JSON-encode bundle.lua
jq -Rs . bundle.lua > bundle.json

jq --slurpfile luascript bundle.json '.LuaScript = $luascript[0]' "kdm/$templatefile" > "$savefile"