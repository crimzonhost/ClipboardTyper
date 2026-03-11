# Create GitHub Release v1.0.0 and upload portable zip + MSIX installer.
# No GitHub CLI required. Uses GitHub REST API.
#
# Prereq: Set your GitHub Personal Access Token (repo scope):
#   $env:GH_TOKEN = "ghp_xxxxxxxxxxxx"
# Create one at: https://github.com/settings/tokens (classic, scope: repo)
#
# Run from repo root: powershell -ExecutionPolicy Bypass -File .\scripts\create-release.ps1

$ErrorActionPreference = "Stop"
$owner = "crimzonhost"
$repo = "ClipboardTyper"
$tag = "v1.0.0"
$zip = "ClipboardTyper-1.0.0-windows-x64-portable.zip"
$msix = "build\windows\x64\runner\Release\clipboard_typer.msix"

if (-not $env:GH_TOKEN) {
    Write-Host "ERROR: Set GH_TOKEN first. Example:" -ForegroundColor Red
    Write-Host '  $env:GH_TOKEN = "ghp_your_token_here"' -ForegroundColor Yellow
    Write-Host "Create a token at: https://github.com/settings/tokens (classic, scope: repo)" -ForegroundColor Gray
    exit 1
}

if (-not (Test-Path $zip)) { Write-Error "Missing: $zip (build and zip the Release folder first)" }
if (-not (Test-Path $msix)) { Write-Error "Missing: $msix (run: echo N | dart run msix:create)" }

$headers = @{
    "Authorization" = "Bearer $env:GH_TOKEN"
    "Accept"        = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

$body = @{
    tag_name         = $tag
    name             = "Release 1.0.0"
    body             = @"
First release of ClipboardTyper.

- **Portable:** Download the zip, extract, and run ``clipboard_typer.exe``.
- **Installer:** Download the MSIX and double-click to install (Settings → Apps to uninstall).

See the [README](https://github.com/crimzonhost/ClipboardTyper#download--install-windows) for install steps.
"@
} | ConvertTo-Json

Write-Host "Creating release $tag..."
try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/releases" -Method Post -Headers $headers -Body $body -ContentType "application/json"
} catch {
    if ($_.Exception.Response.StatusCode -eq 422) {
        Write-Host "Release $tag may already exist. Fetching existing release..." -ForegroundColor Yellow
        $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/releases" -Headers $headers
        $release = $releases | Where-Object { $_.tag_name -eq $tag } | Select-Object -First 1
        if (-not $release) { throw $_ }
    } else { throw $_ }
}

$uploadUrl = $release.upload_url -replace "\{.*\}", "?name={name}"
$assetHeaders = @{
    "Authorization" = "Bearer $env:GH_TOKEN"
    "Accept"        = "application/vnd.github+json"
    "Content-Type"  = "application/octet-stream"
}

foreach ($file in @($zip, $msix)) {
    $name = [System.IO.Path]::GetFileName($file)
    Write-Host "Uploading $name..."
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $file))
    $url = $uploadUrl.Replace("{?name}", "?name=$name")
    Invoke-RestMethod -Uri $url -Method Post -Headers $assetHeaders -Body $bytes | Out-Null
}

Write-Host ""
Write-Host "Done. Release: https://github.com/$owner/$repo/releases/tag/$tag" -ForegroundColor Green
