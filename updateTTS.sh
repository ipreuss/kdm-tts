#!/bin/bash
savefile="$HOME/Library/Tabletop Simulator/Saves/TS_Save_54.json"
backupfile="./savefile_backup.json"
templatefile="./template_workshop.json"
luascript_start='"LuaScript":'

echo "Backing up..."
cp "$savefile" "$backupfile"

# Push the backup file to the git repository
git add "$backupfile"
git commit -q -m "Update backup file"
git push -q origin master
# Replace the value of "LuaScript" in the backup file with the Placeholder
echo "creating template..."
jq '.LuaScript = "Lua Script gets inserted here"' "$backupfile" > "$templatefile"
cd ..
rm -f bundle.*
echo "Bundling..."
luabundler bundle kdm/Global.ttslua \
-p "?.ttslua" \
-o bundle.lua

# JSON-encode bundle.lua
echo "JSON-encoding..."
jq -Rs . bundle.lua > bundle.json

echo "Inserting LuaScript..."
jq --slurpfile luascript bundle.json '.LuaScript = $luascript[0]' "kdm/$templatefile" > "$savefile"

# Compare savefile to backupfile
echo "Checking..."
if cmp -s "$savefile" "$backupfile"; then
    echo "Error: savefile and backupfile are the same. Forgot to save your changes?"
fi
