$host.UI.RawUI.WindowTitle = "tiny11 builder WindowsIsoDownloader Downloader"
$parentDirectory = Split-Path -Path $PSScriptRoot -Parent
Set-Location $parentDirectory

# Get the URL for WindowsIsoDownloader from config.json
$config = (Get-Content "$parentDirectory\config\config.json" -Raw) | ConvertFrom-Json
$WindowsIsoDownloaderURL = $config.WindowsIsoDownloaderURL

# Create a temporary working directory within the script root directory
New-Item -ItemType Directory -Path "$parentDirectory\temp" -Force | Out-Null

# Download the WindowsIsoDownloader zip from Github
Invoke-WebRequest -Uri $WindowsIsoDownloaderURL -OutFile "$parentDirectory\temp\WindowsIsoDownloader.zip"

# Extract the WindowsIsoDownloader zip
Expand-Archive -Path "$parentDirectory\temp\WindowsIsoDownloader.zip" -DestinationPath "$parentDirectory\bin\WindowsIsoDownloader"

# Delete the downloaded and extracted files
Remove-Item -Path "$parentDirectory\temp" -Recurse
