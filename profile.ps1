﻿# profile.ps1

# Load SCM Prompt
. "$(Get-Content ENV:USERPROFILE)\Documents\WindowsPowershell\psScmPrompt.ps1"

# Aliases / Functions
function ll { Get-ChildItem -Force }

# Initial Directory
cd "C:\Development\Projects"

# $theHost.ForegroundColor = "DarkYellow"
# $theHost.BackgroundColor = "DarkMagenta"