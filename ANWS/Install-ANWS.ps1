function Install-ANWS {
    <#
        .SYNOPSIS
            This function installs the ActiveNet Workstation Service (ANWS) from a specified source or by downloading it.
            It provides and option for creating a shortcut to restart the service.
            Previous installations will be overwritten.

        .PARAMETER Source
            Specifies the ANWS zip file to be used as the installer source. This parameter is mandatory if the 'Download' parameter is NOT used.

        .PARAMETER Download
            If this switch is used, the function will download the ANWS zip file from the ActiveNet website.

        .PARAMETER Destination
            Specifies the destination where the ANWS zip file will be saved and extracted. This parameter is mandatory. Files will be removed upon completion.

        .PARAMETER Shortcut
            If this switch is used, the function will create a shortcut to restart the ANWS.

        .PARAMETER ShortcutLocation
            Specifies the location where the shortcut to restart the ANWS will be created. The default location is the public desktop.
        
        .EXAMPLE
            PS> Install-ANWS -Download -Destination 'C:\Temp'

        .EXAMPLE
            PS> Install-ANWS -Download -Destination 'C:\Temp' -Shorcut -ShortcutLocation 'C:\Users\ActiveNetUser\Desktop'

        .EXAMPLE
            PS> Install-ANWS -Source "\\Server\ANWS Downloads\activenetworkstationservice.zip" -Destination 'C:\Temp'

        .EXAMPLE
            PS> Install-ANWS -Source "\\Server\ANWS Downloads\activenetworkstationservice.zip" -Destination 'C:\Temp' -Shortcut
    #>

    [CmdletBinding(DefaultParameterSetName='Source')]
    param (      
        [Parameter(ParameterSetName='Source', Mandatory=$true)]
        [string]$Source, 

        [Parameter(ParameterSetName='Download')]
        [switch]$Download,
        
        [Parameter(Mandatory=$true)]
        [string]$Destination,

        [Parameter()]
        [switch]$Shortcut,

        [Parameter()]
        [string]$ShortcutLocation = "$env:PUBLIC\desktop"
    )

    # Variables
    $logFile = "$((Get-CimInstance -ClassName CIM_OperatingSystem).SystemDrive)\ANWS_Log_$(Get-Date -Format MMddHHmm).txt"
    $anws = 'activenetworkstationservice'
    $extract = Join-Path -Path $destination -ChildPath 'Extract'
    $msi = "{0}\{1}Installer.msi" -f $extract, $anws
    $aN = 'ActiveNet Workstation Service'

    # Start transcript
    Start-Transcript -Append $logFile

    # Check path
    if (!(Test-Path -Path $destination)) {
        Write-Verbose "Creating directory $destination" -Verbose
        New-Item -ItemType Directory -Path $destination | Out-Null
    }

    # Download from ActiveNet if parameter was used
    if ($download) {
        $url = "https://activenetmaint.active.com/upgrade/$anws.zip"
        $zip = "{0}\{1}.zip" -f $destination, $anws
        $maxRetries = 5
        
        # Check connection to URL
        if (([System.Net.WebRequest]::Create($url)).GetResponse().StatusCode -eq 'OK') {
            $retryCount = 0
            $downloadComplete = $false

            # Retry download until it's successful or max retries reached
            while (-not $downloadComplete -and $retryCount -lt $maxRetries) {
                # Download latest ANWS
                # Start-BitsTransfer -Source $url -Destination $zip -DisplayName "Downloading File" -Priority High     # Not using because issues with BITS
                # Invoke-WebRequest -Uri $url -OutFile $destination     # Use if you need a progress bar
                (New-Object Net.WebClient).DownloadFile($url,$zip)
                
                # Verify download
                if (Test-Path $zip) {
                    Write-Verbose -Message 'Download complete' -Verbose
                    $downloadComplete = $true
                } else {
                    Write-Verbose -Message 'Download failed, retrying...' -Verbose
                    $retryCount++
                }
            }
            
            if (-not $downloadComplete) {
                Write-Verbose -Message 'Download failed after maximum retries' -Verbose
            }
        } else {
            # URL connection failed test
            Write-Verbose -Message "Could not reach $url" -Verbose
            return
        }
    } else {
        # Copy zip from specified source 
        if ($source -like "*.zip*") {
            Copy-Item -Path $source -Destination $destination
            $fileName = Split-Path $source -Leaf
            $zip = Join-Path -Path $destination -ChildPath $fileName
        } else {
            Write-Verbose -Message 'Source must be zip extension' -Verbose
            return
        }
    }

    if (Test-Path $zip) {
        # Extract
        try {
            New-Item -ItemType Directory -Path $extract | Out-Null
            Expand-Archive -Path $zip -DestinationPath $extract -Force -ErrorAction Stop
            Write-Verbose -Message 'Extraction complete' -Verbose
        } catch {
            Write-Verbose -Message "Error: $($_.Exception.Message)" -Verbose
        }

        # Install
        $msiArgs = @(
            '/i'
            ('"{0}"' -f "$msi")
            '/qn'
        ) 
        Start-Process msiexec.exe -ArgumentList $msiArgs -Wait -NoNewWindow

        # Set automatic service restart upon failure
        cmd /c sc failure $anws reset= 0 actions= restart/0 | Out-Null
    } else {
        Write-Verbose -Message "$zip not found" -Verbose
        return
    }

    # Verify installation
    $anPkg = Get-Package "$aN" -ErrorAction Ignore
    if ($anPkg) {
        $version = $anPkg.version
    } else {
        Write-Verbose "problem with $aN installation"
        return
    }
    
    # Set shortcuts
    if ($shortcut) {
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
    }

    # Cleanup
    Remove-Item -Path $zip -Force
    Remove-Item -Path $extract -Recurse -Force

    # Stop transcript
    Write-Verbose -Message "ActiveNet Workstation Service v$version installed" -Verbose
    Stop-Transcript
}