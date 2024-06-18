function Install-ANWS {
    <#
        .SYNOPSIS
            This function installs the ActiveNet Workstation Service (ANWS) from a specified source or by downloading it.
            Previous installations will be overwritten and a transcript log will be saved on the system drive.

        .PARAMETER Source
            Specifies the ANWS zip file to be used as the installer source. This parameter is mandatory if the 'Download' parameter is NOT used.

        .PARAMETER Download
            If this switch is used, the function will download the ANWS zip file from the ActiveNet website.

        .PARAMETER Destination
            This parameter is mandatory. It specifies a temporary working directory. This destination is where the ANWS zip file
            will be saved and extracted. Files will be removed upon completion.

        .EXAMPLE
            PS> Install-ANWS -Download -Destination 'C:\Temp'

            This example downloads the ANWS zip file from the ActiveNet website and installs it.
            The zip file is saved and extracted in the 'C:\Temp' directory.

        .EXAMPLE
            PS> Install-ANWS -Source "\\Server\ANWS Downloads\activenetworkstationservice.zip" -Destination 'C:\Temp'

            This example uses the specified ANWS zip file as the installer source.
            The zip file is saved and extracted in the 'C:\Temp' directory.
    #>

    [CmdletBinding(DefaultParameterSetName='Source')]
    param (      
        [Parameter(ParameterSetName='Source', Mandatory=$true)]
        [string]$Source, 

        [Parameter(ParameterSetName='Download')]
        [switch]$Download,
        
        [Parameter(Mandatory=$true)]
        [string]$Destination
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
    
    # Cleanup
    Remove-Item -Path $zip -Force
    Remove-Item -Path $extract -Recurse -Force

    # Stop transcript
    Write-Verbose -Message "ActiveNet Workstation Service v$version installed" -Verbose
    Stop-Transcript
}

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

function Uninstall-ANWS {
    <#
        .SYNOPSIS
            This function is used to uninstall ActiveNet Workstation Service. PowerShell 5 is started to ensure functionality.
            If an installation is detected it will check to make sure the service exists and that Java is stopped before uninstallation.
            After uninstallation it will verify the service has been removed as well as anything left behind in Program Files.
            
        .EXAMPLE
            PS> Uninstall-ActiveNet
    #>
            
    function Uninstall-ActiveNet () {
        # Variables
        $activeNet = 'ActiveNet Workstation Service'
        $installPath = $installPath = "$env:ProgramFiles(x86)\$ActiveNet"
        $logFile = "$((Get-CimInstance -ClassName CIM_OperatingSystem).SystemDrive)\ANWS_UnInstall_Log_$(Get-Date -Format MMddHHmm).txt"

        # Start Transcript
        Start-Transcript -Append $logFile

        try {
            # Check for ANWS and Uninstall if Found
            $installCheck = Get-Package -Name $activeNet -ErrorAction Stop

            if ($installCheck) {
                # Installation w/ missing service indicates a previous corrupt uninstall attempt and package uninstallation will fail
                Write-Verbose -Message "Found $activeNet" -Verbose
                if (!(Get-Service -DisplayName $activeNet -ErrorAction SilentlyContinue)) {
                    New-Service -Name 'ActiveNetWorkstationService' -BinaryPathName 'C:\Program Files (x86)\ActiveNet Workstation Service\ActiveNet.ServiceContainer.exe'
                }
            
                # Newer ANWS versions include a java folder
                if (Get-Process -Name java -ErrorAction SilentlyContinue) {
                    Stop-Process -Name java -Force
                }
            
                # Uninstall 
                Stop-Service -DisplayName $activeNet -Force
                Uninstall-Package -Name 'ActiveNet Workstation Service' -Force
                Write-Verbose -Message 'Uninstalled' -Verbose
            }
        }
        catch {
            Write-Verbose -Message 'Not Found' -Verbose
            Write-Verbose -Message "Error: $($_.Exception.Message)" -Verbose
        }
        finally {
            # Service Removal Double Check
            if (Get-Service -DisplayName $activeNet -ErrorAction SilentlyContinue) {
                cmd /c sc delete activenetworkstationservice
            }
        
            # Orphaned Files Check
            if (Test-Path $installPath) {
                Remove-Item $installPath -Recurse -Force -ErrorAction Stop
            }
            
            Stop-Transcript
        }
    }

    $major = $PSVersionTable.PSVersion.Major

    if ($major -eq 5) {
        Uninstall-ActiveNet
    } else {
        powershell -command ${Function:Uninstall-ActiveNet}
    }
}
