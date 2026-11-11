param (
    [string]$TargetDir = ".",
    [string]$Tag = ""
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

Set-Location -Path $TargetDir

if (-not $Tag) {
    try {
        $Tag = (Invoke-RestMethod -Uri "https://github.com/ggml-org/llama.cpp/releases/download/v0.9.0/nightly-tag.txt" -ErrorAction SilentlyContinue).Trim()
    } catch {
        $Tag = ""
    }
}

if (-not $Tag -or $Tag.Length -lt 2) {
    $Tag = "b12277"
}

Write-Host "Installing llama.cpp release $Tag..."
$ZipFile = "llama-$Tag-bin-win-cpu-x64.zip"
$DownloadUrl = "https://github.com/ggml-org/llama.cpp/releases/download/$Tag/$ZipFile"

Write-Host "Downloading $DownloadUrl..."
Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFile

Write-Host "Extracting $ZipFile..."
Expand-Archive -Path $ZipFile -DestinationPath . -Force
Remove-Item -Path $ZipFile -Force

Write-Host "llama.cpp $Tag installed successfully in $TargetDir"
