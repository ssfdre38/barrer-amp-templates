param(
    [Parameter(Mandatory=$true)]
    [string]$Model,
    [string]$OutputDir = "./models",
    [string]$OutputFile = ""
)

$ErrorActionPreference = "Stop"

if ($Model -match "^([^/:]+)/([^:]+)(:(.+))?$") {
    $namespace = $Matches[1]
    $repo = $Matches[2]
    $tag = if ($Matches[4]) { $Matches[4] } else { "latest" }
} elseif ($Model -match "^([^:]+)(:(.+))?$") {
    $namespace = "library"
    $repo = $Matches[1]
    $tag = if ($Matches[3]) { $Matches[3] } else { "latest" }
} else {
    Write-Error "Invalid Ollama model format: $Model (expected: [namespace/]model[:tag])"
    exit 1
}

Write-Host "=========================================="
Write-Host "  Ollama Direct Registry GGUF Downloader  "
Write-Host "=========================================="
Write-Host "Target: $namespace/$repo:$tag"

$manifestUrl = "https://registry.ollama.ai/v2/$namespace/$repo/manifests/$tag"
Write-Host "Fetching manifest from $manifestUrl..."

try {
    $manifestJson = Invoke-RestMethod -Uri $manifestUrl -Method Get -Headers @{ "Accept" = "application/vnd.docker.distribution.manifest.v2+json" }
} catch {
    Write-Error "Failed to fetch manifest from Ollama registry: $_"
    exit 1
}

$modelLayer = $manifestJson.layers | Where-Object { $_.mediaType -like "*model*" } | Select-Object -First 1

if (-not $modelLayer) {
    Write-Error "No model GGUF layer found in manifest for $Model!"
    exit 1
}

$digest = $modelLayer.digest
$sizeBytes = $modelLayer.size
$sizeGB = [Math]::Round($sizeBytes / 1GB, 2)
Write-Host "Found model layer: $digest ($sizeGB GB)"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

if (-not $OutputFile) {
    $safeRepoName = $repo -replace '[^\w\-_\.]', '_'
    $OutputFile = Join-Path $OutputDir "$safeRepoName-$tag.gguf"
} else {
    $OutputFile = Join-Path $OutputDir $OutputFile
}

$defaultModelLink = Join-Path $OutputDir "model.gguf"

if (Test-Path $OutputFile) {
    $existingSize = (Get-Item $OutputFile).Length
    if ($existingSize -eq $sizeBytes) {
        Write-Host "Model file already exists with matching size ($sizeGB GB). Skipping download."
        if ($OutputFile -ne $defaultModelLink) {
            Copy-Item $OutputFile -Destination $defaultModelLink -Force
        }
        exit 0
    }
}

$blobUrl = "https://registry.ollama.ai/v2/$namespace/$repo/blobs/$digest"
Write-Host "Streaming GGUF directly from: $blobUrl"
Write-Host "Saving to: $OutputFile"

$tempFile = "$OutputFile.downloading"

try {
    $handler = New-Object System.Net.Http.HttpClientHandler
    $handler.AllowAutoRedirect = $true
    $client = New-Object System.Net.Http.HttpClient($handler)
    $client.Timeout = [TimeSpan]::FromHours(2)

    $response = $client.GetAsync($blobUrl, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
    if (-not $response.IsSuccessStatusCode) {
        Write-Error "HTTP error downloading blob: $($response.StatusCode)"
        exit 1
    }

    $stream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
    $fileStream = [System.IO.File]::Create($tempFile)

    $buffer = New-Object byte[] 1048576
    $totalRead = 0
    $lastReport = [DateTime]::UtcNow

    while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $fileStream.Write($buffer, 0, $bytesRead)
        $totalRead += $bytesRead
        if (([DateTime]::UtcNow - $lastReport).TotalSeconds -ge 2) {
            $lastReport = [DateTime]::UtcNow
            $pct = if ($sizeBytes -gt 0) { [Math]::Round(($totalRead / $sizeBytes) * 100, 1) } else { 0 }
            $currGB = [Math]::Round($totalRead / 1GB, 2)
            Write-Host "Downloading: $currGB / $sizeGB GB ($pct%)"
        }
    }

    $fileStream.Flush()
    $fileStream.Close()
    $stream.Close()
    $client.Dispose()

    Move-Item $tempFile -Destination $OutputFile -Force
    Write-Host "Download complete: $OutputFile ($sizeGB GB)"

    Copy-Item $OutputFile -Destination $defaultModelLink -Force
    Write-Host "Updated default active model: $defaultModelLink"
} catch {
    if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
    Write-Error "Download failed: $_"
    exit 1
}
