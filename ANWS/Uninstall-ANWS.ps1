function Uninstall-Activenet {
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