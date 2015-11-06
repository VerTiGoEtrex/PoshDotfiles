# Env vars
$env:DOTFILES = "${home}\.dotfiles"
$env:DEBUGPOSHDOTFILES = $TRUE # EZ debugging

# Include utility functions
. .\PrintUtils.ps1

# Ensure we're on Win 10+ and have PSGet
if (-not (Get-Module -ListAvailable -Name PowerShellGet)) {
    error "Couldn't find the ``PowerShellGet`` module. Are you running Windows 10 or above? You can try to workaround this restriction by running ``(new-object Net.WebClient).DownloadString(`"http://psget.net/GetPsGet.ps1`") | iex``"
}

# -----
# Load configuration files
# -----

$local:configFiles = Get-ChildItem -Path $env:DOTFILES -Depth 2 -Include *.ps1 -Recurse

# Load PSGet module install files
foreach ($local:file in ($local:configFiles | Where-Object {$_.FullName -like "*.psget.ps1$"})) {
    debug "PSGet file: $local:file"
    foreach ($local:line in Get-Content $local:file) {
        $local:pkg = $local:line.Split(" ")[0]
        $local:installArgs = $local:line.SubString($local:line.FirstIndexOf(' '));
        if ($local:installArgs -eq "") {
            $local:installArgs = $local:pkg
        }
        debug "Checking for pkg [$local:line]"
        if (Get-Module -ListAvailable -Name $local:line) {
            debug "Already installed!"
        } else {
            info "Installing psget pkg [$local:pkg] using args [$local:installArgs]"
            #Install-Module $local:installArgs
        }
    }
}

# Load path files
foreach ($local:file in ($local:configFiles | Where-Object {$_.FullName -like "*.path.ps1$"})) {
    debug "Path file: $local:file"
    #. $local:file
}

# Load everything other than path config and host-specific files
foreach ($local:file in ($local:configFiles | Where-Object {$_.FullName -notlike "*(.path|host\*).ps1$"})) {
    debug "Config file: $local:file"
    #. $local:file
}

# Load host-specific config files
foreach ($local:file in ($local:configFiles | Where-Object {$_.FullName -like "*host\*.ps1$"})) {
    debug "Host file: $local:file"
    $local:hostTarget = ([regex]"\\(.*)\.ps1$").Match($local:file.Name).Captures[0].Value
    debug "  targeted to host $local:hostTarget"
    if ($local:hostTarget -eq $env:COMPUTERNAME) {
        debug "  target matches, loading file"
        #. $local:file
    }
}

# -----
# DONE!
# -----