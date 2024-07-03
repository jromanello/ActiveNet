## ActiveNet Workstation Service (ANWS) PowerShell Module

This PowerShell module provides three main functions for managing the ActiveNet Workstation Service (ANWS):

### 1. Install-ANWS
Installs ANWS from a specified source or by downloading it from the ActiveNet website. Previous installations will be overwritten.

### 2. Set-ANWSRestart
Grants permissions to authenticated users to restart the ANWS service and creates a shortcut for this purpose.

### 3. Uninstall-ANWS
Uninstalls ANWS, ensuring that Java is stopped before uninstallation and verifying the removal of the service and any remaining files in Program Files.

#### Key Actions
- **Install-ANWS**:
  - Checks if the destination path exists and creates it if not.
  - Downloads the ANWS zip file from the ActiveNet website if the `Download` switch is used.
  - Extracts the downloaded or specified zip file to the destination.
  - Installs ANWS using the extracted MSI installer.
  - Sets the service to automatically restart upon failure.
  - Cleans up by removing the zip file and extracted contents.
  - Logs the installation process and results.

- **Set-ANWSRestart**:
  - Sets permissions for authenticated users to restart ANWS.
  - Creates a batch file and a shortcut to restart ANWS.

- **Uninstall-ANWS**:
  - Checks for an existing ANWS installation and uninstalls it if found.
  - Stops the Java process if it's running.
  - Removes the ANWS service and any orphaned files.
  - Logs the uninstallation process and results.

Each function includes parameters for specifying the source, destination, and shortcut location, and uses verbose logging to provide detailed information about the actions performed. The module is designed to streamline the installation, management, and removal of ANWS on a workstation.
