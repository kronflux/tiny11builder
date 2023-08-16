# ************************************************************
# * Name: tiny11 builder                                     *
# * Author: Richard M (Flux)                                 *
# * Description:                                             *
# *   This Powershell script takes a standard Windows 11     *
# *   Installation image and removes a list of components    *
# *   and applies various tweaks to achieve a stripped-      *
# *   down and lower resource intensive version of Windows   *
# *   which has been nicknamed "tiny11"                      *
# * Credits:                                                 *
# *   Majority of credit goes to the original author NTDEV   *
# *   NTDEV, who created the original "tiny11" and script    *
# *   to create a similar image ourselves.                   *
# *   Secondary credit goes to ianis58 who wrote a           *
# *   Powershell version of the original script, which I     *
# *   had originally rewrote in it's entirety but ended up   *
# *   rebasing it on his original work, and modified it      *
# *   to be more customizable and to run as TrustedInstaller *
# *   as some of the components were not able to be removed  *
# *   under Administrator privileges.                        *
# ************************************************************

# Set Console Window title
$host.UI.RawUI.WindowTitle = "tiny11 builder"

# Set current directory to Script location
Set-Location $PSScriptRoot

# Suppress all error and warning messages
$WarningActionPreference = "SilentlyContinue"
$ErrorActionPreference = "SilentlyContinue"

Write-Host "=================================================="
Write-Host "         Welcome to the tiny11 builder!"
Write-Host ""
Write-Host " This tool removes various undesirable components"
Write-Host " which come pacakged in official Windows 11 ISO's"
Write-Host "=================================================="
Write-Host ""
Write-Host "Press any key to start the script."
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null

Clear-Host

# Defining preferences variables
Write-Host "Loading configuration from config.json.."
$configPath = (Join-Path -Path $PSScriptRoot -ChildPath "config\config.json")
$config = (Get-Content $configPath -Raw) | ConvertFrom-Json
$UseWindowsIsoDownloader = $config.UseWindowsIsoDownloader
$inputISOPath = $config.InputIsoPath
$workingDir = $config.WorkingDir
$extractedIsoDir = (Join-Path -Path $workingDir -ChildPath $config.ExtractedISODir)
$mountWimDir = (Join-Path -Path $workingDir -ChildPath $config.MountWIMDir)
$installMountDir = (Join-Path -Path $mountWimDir -ChildPath $config.InstallMountDir)
$bootMountDir = (Join-Path -Path $mountWimDir -ChildPath $config.BootMountDir)
$outputDir = (Join-Path -Path $workingDir -ChildPath $config.OutputDir)
$winEdition = $config.WindowsEdition
$provisionedPackagesToRemove = $config.ProvisionedPackagesToRemove
$windowsPackagesToRemove = $config.WindowsPackagesToRemove
$pathsToRemove = $config.PathsToRemove
$buildDate = (Get-Date).ToString("HH-mm_dd-MM-yy")

# Cleanup function for before and after script run to make sure we're working in a clean functional environment
Function DoCleanup {
    Write-Host "Performing Cleanup..."
    Dismount-DiskImage -ImagePath "$inputISOPath" > $null 2>&1
    reg unload HKLM\wim_COMPONENTS 2>$null
    reg unload HKLM\wim_DEFAULT 2>$null
    reg unload HKLM\wim_NTUSER 2>$null
    reg unload HKLM\wim_SOFTWARE 2>$null
    reg unload HKLM\wim_SYSTEM 2>$null
    dism /cleanup-wim > $null 2>&1
    Dismount-WindowsImage -Path "$bootMountDir" -Discard > $null 2>&1
    dism /unmount-Wim /MountDir:"$bootMountDir" /discard > $null 2>&1
    Dismount-WindowsImage -Path "$installMountDir" -Discard > $null 2>&1
    dism /unmount-Wim /MountDir:"$installMountDir" /discard > $null 2>&1
    Remove-Item -Recurse -Confirm:$false -Force "$extractedIsoDir" > $null 2>&1
    Remove-Item -Recurse -Confirm:$false -Force "$installMountDir" > $null 2>&1
    Remove-Item -Recurse -Confirm:$false -Force "$bootMountDir" > $null 2>&1
    Remove-Item -Recurse -Confirm:$false -Force "$mountWimDir" > $null 2>&1
}

# Create logs directory and start logging
Write-Host "Creating tiny11 logs directory.."
New-Item -ItemType Directory -Path "$PSScriptRoot\logs" -Force | Out-Null
Start-Transcript -Append $PSScriptRoot\logs\tiny11builder-$buildDate.log | Out-Null

# Perform cleanup before we start, in case of failed previous attempts
DoCleanup

# Download Windows 11 ISO using Windows Iso Downloader if UseWindowsIsoDownloader in config.json is true
if ($UseWindowsIsoDownloader -eq "true") {
    $windowsIsoDownloaderPath = (Join-Path -Path $PSScriptRoot -ChildPath "bin\WindowsIsoDownloader")
    if (Test-Path -Path $windowsIsoDownloaderPath -PathType Container) {
        if (Test-Path -Path $inputISOPath -PathType Leaf) {
            Write-Output "Existing windows11.iso found. Renaming file to windows11.iso.old"
            Rename-Item -Path $inputISOPath -NewName ($inputISOPath + ".old")
        }
        Write-Output "Downloading Windows 11 ISO file using WindowsIsoDownloader..."
        $isoDownloadProcess = Start-Process (Join-Path -Path $windowsIsoDownloaderPath -ChildPath "WindowsIsoDownloader.exe") -NoNewWindow -Wait -WorkingDirectory $windowsIsoDownloaderPath -PassThru
        if ($isoDownloadProcess.ExitCode -ne 0) {
            Write-Host "Error: Windows Iso Downloader was not successful. Check for errors or obtain your Windows 11 ISO manually."
            Start-Sleep -Seconds 5
            DoCleanup
            Stop-Transcript | Out-Null
            Exit
        }
    } else {
        Clear-Host
        Write-Output "Error: WindowsIsoDownloader not found. Please run the GetWindowsIsoDownloader.cmd script in the root directory OR change UseWindowsIsoDownloader in config.json to false."
        Start-Sleep -Seconds 5
        DoCleanup
        Stop-Transcript | Out-Null
        Exit
    }
}


# Check if the ISO specified exists
if (Test-Path -Path $inputISOPath -PathType Leaf) {
    # Mount the Windows 11 ISO
    Write-Host "Mounting the original Windows 11 ISO.."
    $mountIso = Mount-DiskImage -ImagePath $inputISOPath -PassThru
    Start-Sleep -Seconds 2
    $driveLetter = ($mountIso | Get-Volume).DriveLetter
    $drivePath = "$driveLetter`:"
    Write-Host "Windows 11 ISO is mounted on $drivePath"
} else {
    Clear-Host
    Write-Host "The specified ISO file does not exist: $inputISOPath"
    Write-Host ""
    Write-Host "Please ensure your Windows ISO is valid and present in the location above."
    Start-Sleep -Seconds 5
    DoCleanup
    Stop-Transcript | Out-Null
    Exit
}

# Search for boot.wim in the mounted ISO
Write-Host "Verifying mounted ISO is a valid Windows Installation Disk image.."
$bootWimPath = (Join-Path -Path $drivePath -ChildPath "sources\boot.wim")

if (Test-Path $bootWimPath) {
    Write-Host "Found boot wim image."
} else {
    Clear-Host
    Write-Host "Could not find Windows OS Boot files in the mounted ISO.." 
    Write-Host ""
    Write-Host "Please ensure this is a valid Windows 11 Installation ISO and move it to $inputISOPath"
    Start-Sleep -Seconds 5
    DoCleanup
    Stop-Transcript | Out-Null
    Exit
}

# Search for install.wim or install.esd in the mounted ISO
$installWimPath = (Join-Path -Path $drivePath -ChildPath "sources\install.wim")
$installEsdPath = (Join-Path -Path $drivePath -ChildPath "sources\install.esd")

$installImageType = switch ($true) {
    (Test-Path $installWimPath) { "wim" }
    (Test-Path $installEsdPath) { "esd" }
    default { $null }
}

if ($installImageType) {
    Write-Host "Found install $installImageType image."
} else {
    Clear-Host
    Write-Host "Count not find Windows OS Installation files in the mounted ISO.."
    Write-Host ""
    Write-Host "Please ensure this is a valid Windows 11 Installation ISO and move it to $inputISOPath"
    Start-Sleep -Seconds 5
    DoCleanup
    Stop-Transcript | Out-Null
    Exit
}

# Creating working directories
Write-Host "Creating tiny11 working directories"
$directoriesToCreate = @($workingDir, $extractedIsoDir, $mountWimDir, $installMountDir, $bootMountDir, $outputDir)

ForEach ($directoryToCreate in $directoriesToCreate) {
    Write-Host "Creating directory: $directoryToCreate"
    New-Item -ItemType Directory -Path $directoryToCreate -Force | Out-Null
}

# Copying the ISO files to the extracted ISO directory
Write-Host "Copying the content of the original ISO to the working directory.."
Copy-Item -Path "$drivePath\*" -Destination $extractedIsoDir -Recurse -Force | Out-Null

# Dismounting the original ISO since we don't need it anymore (we have a copy of the content)
Write-Host "Dismounting the original Windows 11 ISO.."
Dismount-DiskImage -ImagePath $inputISOPath | Out-Null

# Strip Read-Only permissions from extracted ISO directory (install.wim and boot.wim may have read-only permissions after extraction, which prevents mounting and committing changes)
Write-Host "Stripping Read-Only permissions from extracted ISO directory.."
Get-ChildItem $extractedIsoDir -Recurse -File | Get-ItemProperty | Set-ItemProperty -Name IsReadOnly -Value $false | Out-Null

# Get the Index of the desired Windows Edition from the extacted install image
$winEditionImage = Get-WindowsImage -ImagePath "$extractedIsoDir\sources\install.$installImageType" | Where-Object { $_.ImageName -eq $winEdition }

if ($winEditionImage) {
    $winEditionImageIndex = $winEditionImage.ImageIndex
    Write-Host "Found $winEdition edition at index $winEditionImageIndex"
} else {
    Clear-Host
    Write-Host "Error: Could not find $winEdition edition in the provided install.$installImageType..."
    Write-Host ""
    Write-Host "Please verify this is a valid Windows 11 image, and that your desired edition is configured in config.json"
    Start-Sleep -Seconds 5
    DoCleanup
    Stop-Transcript | Out-Null
    Exit
}

# Check if the install image is an ESD. If so, extract the desired edition image to install.wim and remove the ESD
if ($installImageType -eq "esd") {
    Write-Host "Extracting $winEdition from install.esd using index $winEditionImageIndex..."
    dism /Export-Image /SourceImageFile:"$extractedIsoDir\sources\install.esd" /SourceIndex:$winEditionImageIndex /DestinationImageFile:"$extractedIsoDir\sources\install.wim" /Compress:max | Out-Null
    Write-Host "Removing install.esd"
    Remove-Item -Confirm:$false -Force "$extractedIsoDir\sources\install.esd" | Out-Null
    $winEditionImageIndex = "1"
}

# Mounting the Install image
Write-Host "Mounting install.wim image.."
Mount-WindowsImage -ImagePath "$extractedIsoDir\sources\install.wim" -Path "$installMountDir" -Index $winEditionImageIndex | Out-Null

# Detecting provisionned app packages
Write-Host "Checking Provisioned app packages present in install.wim image.."
$detectedProvisionedPackages = Get-AppxProvisionedPackage -Path $installMountDir

# Removing unwanted provisionned app packages
Write-Host "Removing unwanted Provisioned app packages from install.wim image.."
Foreach ($detectedProvisionedPackage in $detectedProvisionedPackages)
{
	Foreach ($provisionedPackageToRemove in $provisionedPackagesToRemove)
	{
		If ($detectedProvisionedPackage.PackageName.Contains($provisionedPackageToRemove))
		{
			Write-Host "Removing: $($detectedProvisionedPackage.PackageName)"
			Remove-AppxProvisionedPackage -Path $installMountDir -PackageName $detectedProvisionedPackage.PackageName | Out-Null
		}
	}
}

# Detecting windows packages
Write-Host "Checking Windows packages present in install.wim image.."
$detectedWindowsPackages = Get-WindowsPackage -Path $installMountDir

# Removing unwanted windows packages
Write-Host "Removing unwanted Windows packages from install.wim image.."
Foreach ($detectedWindowsPackage in $detectedWindowsPackages)
{
    Foreach ($windowsPackageToRemove in $windowsPackagesToRemove)
    {
        If ($detectedWindowsPackage.PackageName.Contains($windowsPackageToRemove))
        {
			Write-Host "Removing: $($detectedWindowsPackage.PackageName)"
            Remove-WindowsPackage -Path $installMountDir -PackageName $detectedWindowsPackage.PackageName | Out-Null
        }
    }
}

# Removing unwanted directories
Write-Host "Removing unwanted directories from the install.wim image.."
function Set-CustomAcl {
    param (
        [string]$Path
    )

    $acl = Get-Acl $Path
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetOwner([System.Security.Principal.NTAccount]"Administrators")
    $acl.AddAccessRule($rule)
    $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Deny")
    $trustedInstallerRule = New-Object System.Security.AccessControl.FileSystemAccessRule("NT SERVICE\TrustedInstaller", "FullControl", "ContainerInherit,ObjectInherit", "None", "Deny")
    $acl.AddAccessRule($systemRule)
    $acl.AddAccessRule($trustedInstallerRule)
    Set-Acl -Path $Path -AclObject $acl
}

function Remove-ItemOrDirectory {
    param (
        [string]$Path
    )

    $item = Get-Item $Path
    if ($item -ne $null) {
        if ($item.PSIsContainer) {
            Remove-Item -Path $Path -Recurse -Confirm:$false -Force
        } else {
            Remove-Item -Path $Path -Confirm:$false -Force
        }
    }
}

foreach ($pathToRemove in $pathsToRemove) {
    $fullPathToRemove = (Join-Path -Path $installMountDir -ChildPath $pathToRemove)
    $item = Get-Item $fullPathToRemove

    if ($item -ne $null -and $pathsToRemove -contains $pathToRemove) {
        Remove-ItemOrDirectory -Path $fullPathToRemove
    }
}

# Define Registry Hive locations
$hivesToLoad = @(
    @{ Hive = "HKLM\wim_COMPONENTS"; Path = "Windows\System32\config\COMPONENTS" },
    @{ Hive = "HKLM\wim_DEFAULT"; Path = "Windows\System32\config\default" },
    @{ Hive = "HKLM\wim_NTUSER"; Path = "Users\Default\ntuser.dat" },
    @{ Hive = "HKLM\wim_SOFTWARE"; Path = "Windows\System32\config\SOFTWARE" },
    @{ Hive = "HKLM\wim_SYSTEM"; Path = "Windows\System32\config\SYSTEM" }
)

# Loading the registry from the mounted Install WIM image
Write-Host "Mounting the registry in the install.wim image.."
foreach ($hiveToLoad in $hivesToLoad) {
    $hivePath = (Join-Path -Path $installMountDir -ChildPath $hiveToLoad.Path)
    reg load $hiveToLoad.Hive $hivePath
}

# Applying registry changes to the mounted Install WIM image
$installWimRegFile = (Join-Path -Path $PSScriptRoot -ChildPath "config\install_wim_modifications.reg")
Write-Host "Applying registry changes to the mounted registry.."
regedit /s $installWimRegFile

# Unloading the registry from the mounted Install WIM image
Write-Host "Dismounting the install.wim image registry..."
foreach ($hiveToLoad in $hivesToLoad) {
    reg unload $hiveToLoad.Hive
}

# Copying the setup config file
Write-Host "Placing the autounattend.xml file in the install.wim image..."
[System.IO.File]::Copy((Get-ChildItem "$PSScriptRoot\config\autounattend.xml").FullName, ("$installMountDir\Windows\System32\Sysprep\autounattend.xml"), $true)

# Cleanup and Rebase the Install WIM image
Write-Host "Cleanup and Rebase the mounted install.wim image.."
Repair-WindowsImage -StartComponentCleanup -Path "$installMountDir" | Out-Null
Repair-WindowsImage -StartComponentCleanup -Rebase -Path "$installMountDir" | Out-Null

# Dismount the Install WIM image
Write-Host "Dismounting the install.wim image..."
Dismount-WindowsImage -Path "$installMountDir" -Save | Out-Null

# Export the modified Windows Edition to a clean WIM image
Write-Host "Creating a new clean install.wim image.."
Export-WindowsImage -SourceImagePath "$extractedIsoDir\sources\install.wim" -SourceIndex $winEditionImageIndex -DestinationImagePath "$extractedIsoDir\sources\install_modified.wim" -CompressionType max | Out-Null

# Delete the original install.wim and rename the modified one to replace it
Remove-Item -Path "$extractedIsoDir\sources\install.wim" | Out-Null
Rename-Item -Path "$extractedIsoDir\sources\install_modified.wim" -NewName "install.wim" | Out-Null

# Mounting the Boot WIM image
Write-Host "Mounting the boot.wim image.."
Mount-WindowsImage -ImagePath "$extractedIsoDir\sources\boot.wim" -Path "$bootMountDir" -Index 2 | Out-Null

# Loading the registry from the mounted Boot WIM image
Write-Host "Mounting the registry in the boot.wim image.."
foreach ($hiveToLoad in $hivesToLoad) {
    $hivePath = (Join-Path -Path $bootMountDir -ChildPath $hiveToLoad.Path)
    reg load $hiveToLoad.Hive $hivePath
}

# Applying registry changes to the mounted Boot WIM image
$bootWimRegFile = (Join-Path -Path $PSScriptRoot -ChildPath "config\boot_wim_modifications.reg")
Write-Host "Applying registry changes to the mounted registry.."
regedit /s $bootWimRegFile

# Unloading the registry from the mounted Boot WIM image
Write-Host "Dismounting the boot.wim image registry..."
foreach ($hiveToLoad in $HivesToLoad) {
    reg unload $hiveToLoad.Hive
}

# Cleanup and Rebase the Install WIM image
Write-Host "Cleanup and Rebase the mounted install.wim image.."
Repair-WindowsImage -StartComponentCleanup -Path $bootMountDir | Out-Null
Repair-WindowsImage -StartComponentCleanup -Rebase -Path $bootMountDir | Out-Null

# Dismount the Boot WIM image
Write-Host "Dismounting the boot.wim image.."
Dismount-WindowsImage -Path "$bootMountDir" -Save | Out-Null

# Exporting the modified Windows Edition to a clean WIM image
Write-Host "Creating a clean boot.wim image.."
Export-WindowsImage -SourceImagePath "$extractedIsoDir\sources\boot.wim" -SourceIndex 1 -DestinationImagePath "$extractedIsoDir\sources\boot_modified.wim" -CompressionType max | Out-Null
Export-WindowsImage -SourceImagePath "$extractedIsoDir\sources\boot.wim" -SourceIndex 2 -DestinationImagePath "$extractedIsoDir\sources\boot_modified.wim" -CompressionType max | Out-Null

# Delete the original boot.wim and rename the modified one to replace it
Remove-Item -Path "$extractedIsoDir\sources\boot.wim" | Out-Null
Rename-Item -Path "$extractedIsoDir\sources\boot_modified.wim" -NewName "boot.wim" | Out-Null

# Create datestamped directory in output directory
New-Item -ItemType Directory -Path "$outputDir\tiny11_$buildDate" -Force | Out-Null

# Copying the setup config file to the iso copy folder
[System.IO.File]::Copy((Get-ChildItem "$PSScriptRoot\config\autounattend.xml").FullName, "$outputDir\tiny11_$buildDate\autounattend.xml", $true)

# Building the new trimmed and patched iso file
Write-Host "Building the tiny11.iso file.."
& $PSScriptRoot\bin\oscdimg.exe -m -o -u2 -udfver102 -bootdata:("2#p0,e,b" + $extractedIsoDir + "\boot\etfsboot.com#pEF,e,b" + $extractedIsoDir + "\efi\microsoft\boot\efisys.bin") $extractedIsoDir "$outputDir\tiny11_$buildDate\tiny11_$buildDate.iso" | Out-Null

# Perform Cleanup
DoCleanup

# Script completed
Clear-Host
Write-Host "==============================================="
Write-Host "        tiny11 Windows Creation Tool"
Write-Host "==============================================="
Write-Host ""
Write-Host "Script completed!"
Write-Host "You can find the new tiny11 ISO in the $outputDir\tiny11_$buildDate folder"
Write-Host "filename: tiny11_$buildDate.iso"
Write-Host ""
Stop-Transcript | Out-Null
[System.IO.File]::Copy((Get-ChildItem "$PSScriptRoot\logs\tiny11builder-$buildDate.log").FullName, "$outputDir\tiny11_$buildDate\tiny11builder-$buildDate.log", $true)
Write-Host "Press any key or close this window to exit the script."
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
Exit
