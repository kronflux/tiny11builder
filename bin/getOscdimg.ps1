$host.UI.RawUI.WindowTitle = "tiny11 builder Oscdimg Downloader"
$parentDirectory = Split-Path -Path $PSScriptRoot -Parent
Set-Location $parentDirectory

# Get the URL for Windows ADK from config.json
$config = (Get-Content "$parentDirectory\config\config.json" -Raw) | ConvertFrom-Json
$adkLinkURL = $config.WinADKURL

# Create a temporary working directory within the script root directory
New-Item -ItemType Directory -Path "$parentDirectory\temp" -Force | Out-Null

# This function returns the true URL of a redirect link
Function Get-RedirectedUrl {
    Param (
        [Parameter(Mandatory=$true)]
        [String]$URL
    )
    $request = [System.Net.HttpWebRequest]::Create($URL)
    $request.AllowAutoRedirect = $false
    $response = $request.GetResponse()
    if ($response.StatusCode -eq [System.Net.HttpStatusCode]::Found) {
        $response.Headers["Location"]
    }
    $response.Close()
}

# List of packages used to install/extract oscdimg.exe
$oscdimgPackages = @(
    "Oscdimg (DesktopEditions)-x86_en-us.msi",
    "5d984200acbde182fd99cbfbe9bad133.cab",
    "9d2b092478d6cca70d5ac957368c00ba.cab",
    "bbf55224a0290f00676ddc410f004498.cab"
)

# Use the Get-RedirectedURL function to find the current true URL of ADK via the URL stored in $adkLinkURL
Write-Output "Resolving URL of ADK link..."
$adkFullURL = Get-RedirectedUrl -URL $adkLinkURL

# Check that the true URL was resolved and stored.
if ($adkFullURL -eq $null) {
    Write-Output "Error: \$adkFullURL is null."
    Exit
} else {
	# Split the ADK URL to remove the ADK setup filename, add the "/Installers/" subdirectory, which is the Base URL for the files we will download
    $adkBaseURL = ([System.Uri]$adkFullURL).GetLeftPart([System.UriPartial]::Authority) + (([System.Uri]$adkFullURL).LocalPath -replace '/[^/]*$') + "/Installers/"
}

# Download the files listed in $oscdimgPackages using the Base URL stored in $adkBaseURL
Write-Output "Downloading oscdimg packages..."
foreach ($oscdimgPackage in $oscdimgPackages) {
    Invoke-WebRequest -Uri ($adkBaseURL + $oscdimgPackage) -OutFile ("$parentDirectory\temp\" + $oscdimgPackage)
}

# Extract the Oscdimg MSI using msiexec
Write-Output "Extracting oscdimg from MSI..."
Start-Process -NoNewWindow msiexec.exe -ArgumentList "/a `"$parentDirectory\temp\Oscdimg (DesktopEditions)-x86_en-us.msi`" /qb TARGETDIR=`"$parentDirectory\temp\extracted`"" -Wait

# Copy the extracted oscdimg.exe to the root bin directory
Write-Output "Copying oscdimg.exe to bin directory..."
Copy-Item -Path "$parentDirectory\temp\extracted\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe" -Destination "$parentDirectory\bin\oscdimg.exe"

# Delete the downloaded and extracted files
Write-Output "Removing downloaded and extracted files..."
Remove-Item -Path "$parentDirectory\temp" -Recurse
