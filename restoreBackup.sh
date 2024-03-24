#!/bin/bash
savefile="$HOME/Library/Tabletop Simulator/Saves/TS_Save_54.json"
backupfile="./savefile_backup.json"

cp -v "$backupfile" "$savefile" 
