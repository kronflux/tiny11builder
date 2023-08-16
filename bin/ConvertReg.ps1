[hashtable]$equivalents = @{
   "HKEY_CLASSES_ROOT"                                 = "HKEY_LOCAL_MACHINE\wim_SOFTWARE\Classes"
   "HKEY_LOCAL_MACHINE\\SOFTWARE"                      = "HKEY_LOCAL_MACHINE\wim_SOFTWARE"
   "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet"     = "HKEY_LOCAL_MACHINE\wim_SYSTEM\ControlSet001"
   "HKEY_LOCAL_MACHINE\\SYSTEM\\ControlSet001"         = "HKEY_LOCAL_MACHINE\wim_SYSTEM\ControlSet001"
   "HKEY_LOCAL_MACHINE\\SYSTEM"                        = "HKEY_LOCAL_MACHINE\wim_SYSTEM"
   "HKEY_USERS\\\.DEFAULT"                             = "HKEY_LOCAL_MACHINE\wim_DEFAULT"
   "HKEY_CURRENT_USER"                                 = "HKEY_LOCAL_MACHINE\wim_NTUSER"
}

if($Args.length -ne 1){
        Write-Host "Too Many or Not Enough Arguments" -ForegroundColor Red
        Exit 1
}

$RegInput = [System.IO.Path]::GetFullPath($Args[0]);
$RegInputDir = [System.IO.Path]::GetDirectoryName($Args[0]);
$RegFileName = [System.IO.Path]::GetFileNameWithoutExtension($RegInput);

$TargetRegFile = Join-Path -Path $RegInputDir -ChildPath ($RegFileName + "_modified.reg")


try {
	Write-Output "Converting REG file..."
    $SourceTXT = Get-Content $RegInput -Raw
    foreach ($Key in $equivalents.Keys | Sort-Object -Descending) {
        $SourceTXT = ([regex]::Replace($SourceTXT, "(?mi)" + $Key, $equivalents[$Key]))
    }

    $SourceTXT = ([regex]::Replace($SourceTXT, "(?m)(^\s{2,}$)", "`n"))                 # Multi White-Space Line  > Newline
    $SourceTXT = ([regex]::Replace($SourceTXT, "(?m)^(;.*)$", "`n"))                    # Comment Line > Newline
    $SourceTXT = ([regex]::Replace($SourceTXT, "(?m)(\r\n)", "`n"))                     # CarriageReturn + NewLine > NewLine

    $SourceTXT = ([regex]::Replace($SourceTXT, "(?m)(\n{2,})", "`n"))                   # Multi Newline > Newline
    $SourceTXT = ([regex]::Replace($SourceTXT, "(?m)(^\[)", "`n["))                     # [ > Newline + [
    $SourceTXT = ([regex]::Replace($SourceTXT, "(?m)(\n)", "`r`n"))                     # NewLine > CarriageReturn + NewLine

    Set-Content -Path $TargetRegFile -Value $SourceTXT -Encoding Unicode
} catch {
    Write-Host "ERROR PROCESSING:" """$RegInput""" -ForegroundColor Red
}

exit 0