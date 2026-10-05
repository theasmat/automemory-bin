# ==============================================================================
# AutoMemory Universal Windows Installer (PowerShell)
# https://github.com/theasmat/automemory-bin
#
# Usage (run in PowerShell):
#   irm https://raw.githubusercontent.com/theasmat/automemory-bin/main/install.ps1 | iex
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================================" -ForegroundColor Yellow
Write-Host "       AutoMemory Universal Windows Installer           " -ForegroundColor Yellow
Write-Host "  Persistent Intelligence & Guardrails for AI Agents    "
Write-Host "========================================================" -ForegroundColor Yellow
Write-Host ""

$distRepo = "theasmat/automemory-bin"
$binaryName = "automemory.exe"

# Target installation directory
$installDir = "$env:USERPROFILE\.cargo\bin"
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# Detect CPU Architecture
$arch = $env:PROCESSOR_ARCHITECTURE
switch ($arch) {
    "AMD64" { $targetTriple = "x86_64-pc-windows-msvc" }
    "ARM64" { $targetTriple = "aarch64-pc-windows-msvc" }
    default {
        Write-Warning "Unsupported Windows architecture: $arch. Defaulting to x86_64."
        $targetTriple = "x86_64-pc-windows-msvc"
    }
}

Write-Host "==> Detected Platform: Windows ($arch) -> Target: $targetTriple" -ForegroundColor Cyan

$installed = $false

# 1. Download pre-built release binary from public GitHub release
$zipUrl = "https://github.com/$distRepo/releases/latest/download/automemory-$targetTriple.zip"
$tempZip = [System.IO.Path]::GetTempFileName() + ".zip"
$tempExtract = Join-Path ([System.IO.Path]::GetTempPath()) "automemory_install_$(Get-Random)"

Write-Host "==> Downloading official pre-built release from GitHub..." -ForegroundColor Cyan
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip -UseBasicParsing -TimeoutSec 30
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force
    if (Test-Path "$tempExtract\$binaryName") {
        Copy-Item "$tempExtract\$binaryName" "$installDir\$binaryName" -Force
        $installed = $true
        Write-Host "✓ Downloaded pre-built binary for $targetTriple" -ForegroundColor Green
    }
} catch {
    Write-Warning "Could not download pre-built release: $($_.Exception.Message)"
} finally {
    if (Test-Path $tempZip) { Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue }
    if (Test-Path $tempExtract) { Remove-Item -Path $tempExtract -Recurse -Force -ErrorAction SilentlyContinue }
}

# 2. Fallback: cargo install
if (-not $installed) {
    if (Get-Command cargo -ErrorAction SilentlyContinue) {
        Write-Host "==> Building from source via cargo install..." -ForegroundColor Cyan
        cargo install --git "https://github.com/theasmat/automemory.git" --bin automemory
        $installed = $true
    } else {
        Write-Error "Pre-built binary download was unavailable and Rust/Cargo is not installed. Please install Rust from https://rustup.rs"
        exit 1
    }
}

$exePath = Join-Path $installDir $binaryName
Write-Host "✓ Binary installed to: $exePath" -ForegroundColor Green

# 3. Check PATH environment variable
$userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
if ($userPath -notlike "*$installDir*") {
    Write-Warning "$installDir is not in your User PATH environment variable."
    Write-Host "==> Adding $installDir to User PATH..." -ForegroundColor Cyan
    [Environment]::SetEnvironmentVariable("Path", "$installDir;$userPath", [EnvironmentVariableTarget]::User)
    $env:Path = "$installDir;$env:Path"
}

# 4. Run health diagnostics
Write-Host ""
Write-Host "==> Verifying AutoMemory health diagnostics..." -ForegroundColor Cyan
try {
    & $exePath doctor
} catch {
    Write-Warning "Doctor check encountered a warning: $($_.Exception.Message)"
}

# 5. Configure agents globally
Write-Host ""
Write-Host "==> Configuring universal coding agent connectors on Windows..." -ForegroundColor Cyan
try {
    & $exePath connect all -g
    Write-Host "✓ Configured universal coding agents globally!" -ForegroundColor Green
} catch {
    Write-Warning "Could not connect all agents automatically: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "  AutoMemory was successfully installed!                " -ForegroundColor Green
try {
    $ver = & $exePath --version
    Write-Host "  Version: $ver" -ForegroundColor Green
} catch {}
Write-Host "========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Quick commands to get started in PowerShell:"
Write-Host "  automemory serve        Launch local web dashboard at http://127.0.0.1:4545" -ForegroundColor Cyan
Write-Host "  automemory doctor       Run system health checks" -ForegroundColor Cyan
Write-Host "  automemory connect all  Connect all 20 agents in your current workspace" -ForegroundColor Cyan
Write-Host "  automemory proposal summary View review proposal metrics" -ForegroundColor Cyan
Write-Host ""
