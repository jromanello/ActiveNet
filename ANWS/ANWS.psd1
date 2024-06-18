@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'ANWS.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.1' 
    
    <#  
        1.0 4-APR-2024
            Created module with functions Install-ANWS, Set-ANWSRestart, Uninstall-ANWS
        
        1.0.1 18-JUN-2024
            Fixed error with Install-ANWS
            Updated code / cleaned up function help 
    #>

    # ID used to uniquely identify this module
    GUID = '2e352d18-c34f-4e5b-8e2b-f246b4da5785'

    # Author of this module
    Author = 'Justin Romanello'

    # Company or vendor of this module
    CompanyName = 'No Company'

    # Copyright statement for this module
    Copyright = '(c) Justin Romanello. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'This module provides functions for the ActiveNet Workstation Service (ANWS).'

    # Minimum version of the PowerShell engine required by this module. This module is compatible with PowerShell 5.
    PowerShellVersion = '5.0'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = 'Install-ANWS', 'Set-ANWSRestart', 'Uninstall-ANWS'

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = 'ActiveNet', 'ActiveNetWorkstation', 'ActiveNetWorkstationService', 'ANWS'

            # A URL to the license for this module.
            LicenseUri = 'http://opensource.org/licenses/MIT'

            # A URL to the main website for this project.
            ProjectUri = ''

            # A URL to an icon representing this module.
            IconUri = ''
        } # End of PSData hashtable
    } # End of PrivateData hashtable
} # End of manifest hashtable