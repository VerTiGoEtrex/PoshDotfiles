# Env vars
$env:DOTFILES = "${home}\.dotfiles"
$env:POSHPROFILEPATH = Split-Path -Parent $profile
$env:DEBUGPOSHDOTFILES = $TRUE # EZ debugging

# Include utility functions
. $env:POSHPROFILEPATH\PrintUtils.ps1

# Ensure we're on Win 10+ and have PSGet
if (-not (Get-Module -ListAvailable -Name PowerShellGet)) {
    error "Couldn't find the ``PowerShellGet`` module. Are you running Windows 10 or above? You can try to workaround this restriction by running ``(new-object Net.WebClient).DownloadString(`"http://psget.net/GetPsGet.ps1`") | iex``"
}

# -----
# Load configuration files
# -----

# Get all powershell files one level deep
$local:psgetFiles   = Get-ChildItem -Path $env:DOTFILES\*\*.psget
$local:configFiles  = Get-ChildItem -Path $env:DOTFILES\*\*.ps1
$psgetModules = @()

# Load PSGet module install files
foreach ($local:file in ($local:psgetFiles | Where-Object {$_.FullName -match ".*\.psget$"})) {
    debug "PSGet file: $local:file"
    foreach ($local:line in Get-Content $local:file) {
        $local:pkg = $local:line      
        debug "Checking for pkg [$local:pkg]"
        if (Get-Module -ListAvailable -Name $local:pkg) {
            debug "Already installed!"
        } else {
            info "Installing psget pkg [$local:pkg]"
            Install-Module $local:pkg -Scope CurrentUser
        }
        $psgetModules += $local:pkg
    }
}

# Load path files
foreach ($local:file in ($local:configFiles | Where-Object {$_.FullName -match ".*\.path\.ps1$"})) {
    debug "Path file: $local:file"
    . $local:file.FullName
}

# Load config files
foreach ($local:file in ($local:configFiles | Where-Object {$_.FullName -match ".*\.config\.ps1$"})) {
    debug "Config file: $local:file"
    . $local:file.FullName
}



# TODO -- probably never. It's not that useful.

# Load host-specific config files (BlahBlah
#foreach ($local:file in ($local:configFiles | Where-Object {$_.FullName -match ".*\host\.*\.ps1$"})) {
#    debug "Host file: $local:file"
#    $local:hostTarget = ([regex]"\\(.*)\.ps1$").Match($local:file.Name).Captures[0].Value
#    debug "  targeted to host $local:hostTarget"
#    if ($local:hostTarget -eq $env:COMPUTERNAME) {
#        debug "  target matches, loading file"
#        #. $local:file.FullName
#    }
#}

# -----
# Update function
# -----

# User can call this to update installed profile modules
function PSProf-UpdateModules {
    foreach ($local:pkg in $psgetModules) {
        Update-Module $local:pkg
    }
}

# -----
# DONE!
# -----