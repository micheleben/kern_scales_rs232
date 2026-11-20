<#
.SYNOPSIS
  Run Python from the virtual environment named by VIRTUAL_ENV in .env.

.EXAMPLE
  .\run.ps1 setup                          # create the venv (if missing) and install requirements.txt
  .\run.ps1 src_python\core.py COM3 w      # run a script with the venv's python
  .\run.ps1 -m pip list                    # any python arguments work

  If script execution is blocked:
  powershell -ExecutionPolicy Bypass -File .\run.ps1 setup
#>
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$envFile = Join-Path $root '.env'

# --- read VIRTUAL_ENV from .env (accepts "KEY=value", "KEY = value", quotes, comments)
if (-not (Test-Path $envFile)) {
    Write-Error ".env not found. Copy .env-example to .env and set VIRTUAL_ENV."
}
$venv = $null
foreach ($line in Get-Content $envFile) {
    if ($line -match '^\s*(?:export\s+)?VIRTUAL_ENV\s*=\s*(.*?)\s*$') {
        $venv = $Matches[1].Trim('"', "'")
    }
}
if (-not $venv) { Write-Error "VIRTUAL_ENV is not set in .env" }
if (-not [System.IO.Path]::IsPathRooted($venv)) { $venv = Join-Path $root $venv }

$python = Join-Path $venv 'Scripts\python.exe'
if (-not (Test-Path $python)) { $python = Join-Path $venv 'bin/python' }  # non-Windows layout

if ($args.Count -gt 0 -and $args[0] -eq 'setup') {
    if (-not (Test-Path $python)) {
        Write-Host "Creating virtual environment at $venv"
        if (Get-Command py -ErrorAction SilentlyContinue) { & py -3 -m venv $venv }
        else { & python -m venv $venv }
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        $python = Join-Path $venv 'Scripts\python.exe'
    }
    & $python -m pip install --upgrade pip
    & $python -m pip install -r (Join-Path $root 'requirements.txt')
    exit $LASTEXITCODE
}

if (-not (Test-Path $python)) {
    Write-Error "No python found in '$venv'. Run '.\run.ps1 setup' first."
}
if ($args.Count -eq 0) {
    Write-Host "Using $python"
    & $python --version
    exit $LASTEXITCODE
}
& $python @args
exit $LASTEXITCODE
