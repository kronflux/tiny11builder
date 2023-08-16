# tiny11 Windows Builder

Script to build a trimmed-down Windows 11 image. (Should also work on Windows 10 with some tweaks to config.json)

This is a script to automate the build of a streamlined Windows 11 image, similar to NTDEV's tiny11.

The main goal is to primarily use Microsoft utilities in order to create this image.
No Microsoft or Third-Party executables have been included with this script. Instead, I have provided a script called "GetBins.cmd" which downloads them from official sources.
The binaries downloaded are as follows:
- oscdimg.exe - which is provided in the Windows ADK (<https://learn.microsoft.com/en-US/windows-hardware/get-started/adk-install>)
and is used to create bootable ISO images
- nsudo.exe - which is provided by the M2Team (<https://github.com/M2TeamArchived/NSudo>)
and is used to elevate the script to run as TrustedInstaller in order to modify or remove protected components in the Windows 11 image.

Also included is an unattended answer file, which is used to bypass the MS account on OOBE and to deploy the image with the /compact flag.

It's open-source, so feel free to add or remove anything you want! Feedback is also much appreciated.

Current and new Windows 11 builds are supported, but may need some small adjustments. Please report issue or create pull requests if you're able to patch some issues.

Instructions:

1. Download latest Windows 11. You can get this from any of the following sources:
- Microsoft website (<https://www.microsoft.com/software-download/windows11>)
- UUP dump (<https://uupdump.net>)
- Windows Iso Downloader (<https://github.com/ianis58/WindowsIsoDownloader>) - You can use the "GetWindowsIsoDownloader.cmd" script to download it, and change "UseWindowsIsoDownloader" in config.json to "true".
2. Place the downloaded file in C:\windows11.iso (be sure to rename it so that it match that filename. This can be modified in the config\config.json file if you wish).
3. Run the included Start_tiny11builder.cmd script to launch the Powershell script as TrustedInstaller via NSudo.
Note, you may have to set your Execution Policy to Bypass in order to run this script. You can do so by the following steps:
- Open a Powershell terminal with admin rights and run the following command:
```
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```
3. Sit back and relax :)
4. When the image is completed, you will find it in the output directory (by default, this is set to C:\tiny11\output)

What is currently removed:
Clipchamp,
Cortana,
News,
Weather,
Xbox (although Xbox Identity provider has not been removed here, so it should be possible to be reinstalled with no issues),
GetHelp,
GetStarted,
3D Viewer,
Office Hub,
Solitaire,
Mixed Reality Portal,
PeopleApp,
PowerAutomate,
Skype,
ToDo,
Alarms,
Feedback Hub,
Maps,
Sound Recorder,
Your Phone,
Media Player,
Family,
QuickAssist,
Teams,
Mail and Calendar,
Internet Explorer,
LA57 support,
OCR for en-us,
Speech support,
TTS for en-us,
Media Player Legacy,
Tablet PC Math,
Wallpapers,
Edge,
OneDrive

I have also included a script called ConvertReg.cmd which you can drag a standard(live windows environment locations such as HKEY_CURRENT_USER, HKEY_LOCAL_MACHINE, etc) REG file onto, and it will produce a modified REG file who's values are compatible with this script. You can then use these values in install_wim_modifications.reg and boot_wim_modifications.reg

Known issues:

1. Although Edge is removed, the icon and a ghost of its taskbar pin are still available. Also, there are some remnants in the Settings. But the app in itself is deleted.
2. Some of the registry tweaks included with this script seem to be overwritten when the user account is created. I'm not sure why this is, but if anyone can provide some insight into this, it would be greatly appreciated.
3. The removal of certain files and folders causes SFC /SCANNOW to fail and re-acquire them. There doesn't seem to be any way around this, however there is no harm in either having or not having these files present. If you wish to avoid SFC finding issues, simply remove all of the current entries under PathsToRemove from config.json.