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

function debug {
    if ($env:DEBUGPOSHDOTFILES) {
        Write-Host "  [ .. ] " -ForegroundColor Gray -NoNewline
        Write-Host $args
    }
}