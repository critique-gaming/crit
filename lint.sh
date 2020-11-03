#!/bin/bash

find . \( -name "*.lua" -or -name "*.script" -or -name "*.gui_script" -or -name "*.render_script" \) | xargs luacheck $@
