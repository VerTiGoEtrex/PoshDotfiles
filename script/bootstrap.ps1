# Magic :)
# Links all of the dotfiles to your documents directory

$ErrorActionPreference = "Stop"



function info {
    Write-Host "  [ .. ] " -ForegroundColor Cyan -NoNewline
    Write-Host $args
}

function user {
    Write-Host "`r  [ ?? ] " -ForegroundColor Yellow -NoNewline
    Write-Host "$args " -NoNewline
}

function success {
    Write-Host "`r  [ OK ] " -ForegroundColor Green -NoNewline
    Write-Host $args
}

function error {
    Write-Host "`r  [FAIL] " -ForegroundColor Red -NoNewline
    Write-Host $args
    exit
}

function setup_gitconfig {
    if (!(Test-Path git/.gitconfig.symlink)) {
        info 'setup gitconfig'
        user ' - What is your github author name?'
        $local:git_authorname = Read-Host
        user ' - What is your github author email?'
        $local:git_authoremail = Read-Host

        cat git/.gitconfig.symlink.example | %{$_ -replace "AUTHORNAME", $local:git_authorname} | %{$_ -replace "AUTHOREMAIL", $local:git_authoremail} > git/.gitconfig.symlink

        success 'gitconfig'
    }
}

function link_file {
    $local:src = $($args[0])
    $local:dst = $($args[1])
    $local:overwrite = $FALSE
    $local:backup = $FALSE
    $local:skip = $FALSE
    
    # check if the expected destination path already exists in some form
    if (Test-Path($local:dst)) {
        # already exists, let's see if it's a link from a previous run and decide what to do
        if (!($overwrite_all -or $backup_all -or $skip_all)) {
            $local:currentSrc=Get-Item($local:dst)
            if ($local:currentSrc.LinkType) {
                # Follow symlinks TODO: hardlink support, etc.
                $local:currentSrc=($local:currentSrc).Target
            }
            if ($local:currentSrc -eq ($local:src).FullName) {
                # Already linked
                $local:skip = $TRUE
            } else {
                user ("File already exists: " + $local:dst + " (linked to) "+ $local:currentSrc + ", what do you want to do?
                [s]kip, [S]kip all, [o]verwrite, [O]verwriteall, [b]ackup, [B]ackup all?")
                $local:ans = Read-Host
                switch ($local:ans) {
                    "s" {$local:skip = $TRUE}
                    "S" {$skip_all = $TRUE}
                    "o" {$local:overwrite = $TRUE}
                    "O" {$overwrite_all = $TRUE}
                    "b" {$local:backup = $TRUE}
                    "B" {$backup_all = $TRUE}
                }
            }
        }

        # let's resolve the conflict
        $local:overwrite = $local:overwrite -or $overwrite_all
        $local:backup = $local:backup -or $backup_all
        $local:skip = $local:skip -or $skip_all

        if ($local:overwrite) {
            remove-item $local:dst -Recurse -Force
            success ("removed " + $local:dst)
        }
        if ($local:backup) {
            Move-Item -Path $local:dst -Destination ($local:dst + ".backup") -Force
            success ("moved " + $local:dst + " to " + $local:dst + ".backup")
        }
        if ($local:skip) {
            success ("skipped " + $local:src)
        }
    }
    if (!($local:skip)) {
        New-Item -ItemType SymbolicLink -Path $local:dst -Target $local:src | out-null
        success ("linked " + $local:src + " to " + $local:dst)
    }
}

function install_dotfiles {
    info 'installing dotfiles'

    $overwrite_all = $FALSE
    $backup_all = $FALSE
    $skip_all = $FALSE

    foreach ($local:src in Get-ChildItem -Depth 2 -Include *.symlink -Recurse) {
        $local:prefixFilePath = $local:src.parent.fullname + "\#ROOT"
        $local:dst = "$home\test_dotfiles\" #Debugging purposes
        #$local:dst = "$home\"
        if (Test-Path $local:prefixFilePath -PathType leaf) {
            # This folder wants to be symlinked somewhere else. Symlink it into the prefix stored in #ROOT, creating if necessary.
            $local:dst += Get-Content $local:prefixFilePath
            New-Item -path $local:dst -type directory -Force | out-null
        }
        $local:dst += ($src.Name -replace (".{" + ".symlink".Length + "}$"))
        link_file $local:src $local:dst $overwrite_all $:backup_all $skip_all
    }
}

# Main

if (-not (Get-Module -ListAvailable -Name PowerShellGet)) {
    error "Couldn't find the ``PowerShellGet`` module. Are you running Windows 10 or above?"
}

# Check for and install chocolatey
$ChocoInstallPath = "C:\ProgramData\Chocolatey\bin"

if (!(Test-Path $ChocoInstallPath)) {
    info "Chocolatey not installed. Installing."
    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
}

cd $PSScriptRoot/..
$local:DOTFILES_ROOT=(Get-Location)

setup_gitconfig
install_dotfiles

Write-Host "`n  Installed!"