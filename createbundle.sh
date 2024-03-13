#!/bin/bash
cd ..
luabundler bundle Kdm/Global.ttslua \
-p "?.ttslua" \
-o bundle.lua
