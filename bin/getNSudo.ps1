$host.UI.RawUI.WindowTitle = "tiny11 builder NSudo Downloader"
$parentDirectory = Split-Path -Path $PSScriptRoot -Parent
Set-Location $parentDirectory

# Get the URL for NSudo from config.json
$config = (Get-Content "$parentDirectory\config\config.json" -Raw) | ConvertFrom-Json
$nsudoURL = $config.NSudoURL

# Create a temporary working directory within the script root directory
New-Item -ItemType Directory -Path "$parentDirectory\temp" -Force | Out-Null

# Download the NSudo zip from Github
Write-Output "Downloading NSudo..."
Invoke-WebRequest -Uri $nsudoURL -OutFile "$parentDirectory\temp\nsudo.zip"

# Extract the NSudo zip
Write-Output "Extracting NSudo..."
Expand-Archive -Path "$parentDirectory\temp\nsudo.zip" -DestinationPath "$parentDirectory\temp"

# Copy the x64 NSudo exe to the root bin directory
Write-Output "Copying NSudo.exe to bin directory..."
Copy-Item -Path "$parentDirectory\temp\x64\NSudoLC.exe" -Destination "$parentDirectory\bin\nsudo.exe"

# Delete the downloaded and extracted files
Write-Output "Removing downloaded and extracted files..."
Remove-Item -Path "$parentDirectory\temp" -Recurse
