function Set-ANWSRestart {
    <#
    .SYNOPSIS
        The function will grant permissions to authenticated users to restart restart the ActiveNet Workstation Service service and
        create a shortcut to do so.
    
    .PARAMETER Destination
        The path where the shortcut should be created. If not specified, the function will default to the Public Desktop.

    .EXAMPLE
        PS> Set-ANWSRestart
    #>

    param(
        [string]$ShortcutLocation = "$env:PUBLIC\desktop"
    )

    # Variables
    $anws = 'activenetworkstationservice'

    try {
        # Permission to let authenticated users restart ANWS
        cmd /c sc sdset $anws "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)(A;;RPWPCR;;;AU)S:(AU;FA;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;WD)" 
        
        # Create bat
        New-Item -Path $shortcutLocation -Name 'restartanws.bat' -Value "net stop $anws `nnet start $anws" -force -ErrorAction SilentlyContinue | Out-Null
        [System.IO.File]::SetAttributes("$shortcutlocation\restartanws.bat", 'Hidden')

        # Create shortcut
        $wshshell = New-Object -ComObject ("WScript.Shell")
        $shortcut = $wshShell.CreateShortcut((Join-Path $shortcutLocation "Restart ActiveNet.lnk"))
        $shortcut.TargetPath = "$shortcutLocation\restartanws.bat"
        $shortcut.IconLocation = 'C:\Windows\System32\shell32.dll,238'
        $shortcut.Save()
    } catch {
        Write-Verbose -Message "An error occurred: $($_.Exception.Message)" -Verbose
    }
}