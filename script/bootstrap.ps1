# Magic :)
# Links all of the dotfiles to your documents directory

$ErrorActionPreference = "Stop"

cd $PSScriptRoot/..
$local:DOTFILES_ROOT=(Get-Location)

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
    
    if (Test-Path($local:dst)) {
        info ("File exists!")
        $local:currentSrc=Get-Item($local:dst)
        while ($local:currentSrc.LinkType) {
            info "link detected!"
            $local:currentSrc=(Get-Item($local:currentSrc)).Target
            info ($local:currentSrc)
        }
        if ($overwrite_all -or $backup_all -or $skip_all) {
            $local:currentSrc = 0;
        }
    }
}

function install_dotfiles {
    info 'installing dotfiles'

    $overwrite_all = $TRUE
    $backup_all = $FALSE
    $skip_all = $FALSE

    foreach ($local:src in Get-ChildItem -Depth 2 -Include *.symlink -Recurse) {
        $local:dst = "$home\\test_dotfiles\\" + $src.basename
        info($local:dst)
        #$local:dst = "$home\\" + $src.basename
        link_file $local:src $local:dst $overwrite_all $:backup_all $skip_all
    }
}

setup_gitconfig
install_dotfiles

Write-Host "`n  Installed!"