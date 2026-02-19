#==============================================================================#
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER    #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES  #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.   #
#                                                                              #
# Copyright (C) 2026 COOLORANGE S.r.l.                                         #
#==============================================================================#

if ($processName -notin @('Connectivity.VaultPro')) {
	return
}

# Import all modules located in the powerAPS folder
Import-Module C:\ProgramData\coolOrange\powerAPS\powerAPS.Modules.psd1 -Force

function ApsTokenIsValid() {
    $missingRoles = GetMissingRoles @(77, 76)
    if ($missingRoles) {
        $message = "The current user does not have the required permissions: $missingRoles!"
        $title = "Permission Error"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($message, $title)
        return $false
    }

    # Get the APS authentication settings from Vault options
    try {
        $settings = GetVaultApsAuthenticationSettings
    }
    catch {
        $title = "Configuration Error"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($_, $title)
        return $false
    }

    $arguments = @{
        ClientId = $settings.ClientId
        CallbackUrl = $settings.CallbackUrl
    }

    # Get the users Autodesk ID from Vault
    $vaultLogin = [Autodesk.Connectivity.WebServicesTools.AutodeskAccount]::Login([IntPtr]::Zero)
    if ($vaultLogin -and $vaultLogin.AccountEmail) {
        $arguments.User = $vaultLogin.AccountEmail
    }

    if (-not $settings.Pkce) {
        $arguments.ClientSecret = $settings.ClientSecret
    }

    # Connect to APS
    # https://doc.coolorange.com/projects/poweraps/en/stable/code_reference/commandlets/connect-aps/
    $result = Connect-APS @arguments
    if (-not $result) {
        $title = "Connection Error"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($result.Error, $title)
        return $false
    }
    return $true
}

# Load the powerAPS.Utils.dll according to the PowerShell edition. 
# The classes in this dll are used in the Attribute Mapping dialog and in the Content Selection dialog.
# These classes are derived from INotifyPropertyChanged, which is not natively supported in PowerShell.
# The image resources in this dll are used in the XAML dialogs.
$dll = if ($PSVersionTable.PSEdition -eq 'Core') {
    "C:\ProgramData\coolOrange\Client Customizations\Modules\powerAPS.Utils\net8.0-windows\powerAPS.Utils.dll"
} else {
    "C:\ProgramData\coolOrange\Client Customizations\Modules\powerAPS.Utils\net48\powerAPS.Utils.dll"
}
Add-Type -Path $dll -ErrorAction Stop
