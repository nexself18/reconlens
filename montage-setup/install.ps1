# Montage toolkit installer for Windows 10/11 (NVIDIA GPU).
# Run via install.bat (it handles the execution policy), or:
#   powershell -ExecutionPolicy Bypass -File install.ps1
# Safe to re-run: already installed pieces are skipped or upgraded.

$ErrorActionPreference = 'Stop'
$Root = Join-Path $env:USERPROFILE 'montage'
$PyVer = '3.11'
$TorchIndex = 'https://download.pytorch.org/whl/cu128'   # CUDA 12.8: RTX 20xx..50xx
$Failed = @()

function Step($name, [scriptblock]$body) {
    Write-Host "`n=== $name ===" -ForegroundColor Cyan
    try { & $body; Write-Host "OK: $name" -ForegroundColor Green }
    catch { Write-Host "FAIL: $name -> $_" -ForegroundColor Red; $script:Failed += $name }
}

function Refresh-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Winget($id) {
    winget install --id $id -e --accept-source-agreements --accept-package-agreements --silent
    # winget returns non-zero when the package is already installed; that is fine
    Refresh-Path
}

function Py { & py "-$PyVer" @args; if ($LASTEXITCODE) { throw "python $args failed ($LASTEXITCODE)" } }

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget not found. Install "App Installer" from Microsoft Store and re-run.'
}
New-Item -ItemType Directory -Force -Path $Root, "$Root\clipfinder" | Out-Null

Step 'NVIDIA driver check' {
    $smi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    if ($smi) { nvidia-smi --query-gpu=name,driver_version --format=csv,noheader }
    else { Write-Warning 'nvidia-smi not found: install the latest NVIDIA driver, otherwise CUDA/NVENC will not work.' }
}

Step 'ffmpeg (full build, NVENC)' { Winget 'Gyan.FFmpeg' }
Step 'Python'                     { Winget "Python.Python.$PyVer" }
Step 'Node.js LTS'                { Winget 'OpenJS.NodeJS.LTS' }
Step 'Git'                        { Winget 'Git.Git' }

Step 'pip upgrade' { Py -m pip install --upgrade pip wheel setuptools }

Step 'PyTorch (CUDA)' {
    Py -m pip install --upgrade torch torchvision torchaudio --index-url $TorchIndex
    Py -c "import torch; print('torch', torch.__version__, 'cuda:', torch.cuda.is_available())"
}

Step 'Python tools (whisper, faster-whisper, demucs, yt-dlp, scenedetect, mediapipe)' {
    Py -m pip install --upgrade openai-whisper faster-whisper demucs yt-dlp "scenedetect[opencv]" mediapipe `
        nvidia-cublas-cu12 "nvidia-cudnn-cu12==9.*"
}

Step 'cuBLAS/cuDNN on PATH (for faster-whisper GPU)' {
    $site = (& py "-$PyVer" -c "import site; print(site.getsitepackages()[-1])").Trim()
    $dirs = @("$site\nvidia\cublas\bin", "$site\nvidia\cudnn\bin") | Where-Object { Test-Path $_ }
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    foreach ($d in $dirs) { if ($userPath -notlike "*$d*") { $userPath = "$userPath;$d" } }
    [Environment]::SetEnvironmentVariable('Path', $userPath, 'User')
    Refresh-Path
}

Step 'faster-whisper models: large-v3, large-v3-turbo (~4.5 GB)' {
    Py -c "from faster_whisper import download_model as d; [print(m, '->', d(m)) for m in ('large-v3','large-v3-turbo')]"
}

Step 'Demucs model htdemucs' {
    Py -c "from demucs.pretrained import get_model; get_model('htdemucs'); print('htdemucs ready')"
}

Step 'HyperFrames CLI' {
    npm install -g hyperframes
    if ($LASTEXITCODE) { throw "npm install failed ($LASTEXITCODE)" }
    Refresh-Path
    hyperframes --version
}

Step 'TikTok Sans font' {
    $name = 'TikTokSans[opsz,slnt,wdth,wght].ttf'
    $url  = 'https://raw.githubusercontent.com/google/fonts/main/ofl/tiktoksans/TikTokSans%5Bopsz%2Cslnt%2Cwdth%2Cwght%5D.ttf'
    $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    New-Item -ItemType Directory -Force -Path $fontDir | Out-Null
    $dest = Join-Path $fontDir $name
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    Copy-Item $dest (Join-Path $Root $name) -Force   # handy copy for ffmpeg/HyperFrames
    New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' `
        -Name 'TikTok Sans (TrueType)' -Value $dest -PropertyType String -Force | Out-Null
}

Step 'Self-check' {
    ffmpeg -hide_banner -encoders | Select-String 'nvenc'
    Py -c "import whisper, faster_whisper, demucs, scenedetect, mediapipe, yt_dlp; print('python libs OK')"
    yt-dlp --version
    node --version
}

Write-Host "`nToolkit folder: $Root  (put clipfinder scripts into $Root\clipfinder)"
if ($Failed.Count) {
    Write-Host "Failed steps: $($Failed -join ', ')" -ForegroundColor Red
    Write-Host 'Open a NEW terminal and run install.bat again; it only redoes what is missing.'
    exit 1
}
Write-Host 'All done. Open a new terminal so PATH changes take effect.' -ForegroundColor Green
