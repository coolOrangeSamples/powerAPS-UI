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

function Get-DialogApsAuthentication([Hashtable]$settings) {
    class DataContext {
        [bool] $Pkce
        [string] $ClientId
        [string] $ClientSecret
        [string] $CallbackUrl
        [System.Collections.ObjectModel.ObservableCollection[PsObject]] $Scope
        DataContext() {
            $this.Scope = New-Object System.Collections.ObjectModel.ObservableCollection[PsObject]
        }
    }

    $dataContext = [DataContext]::new()
    $dataContext.Pkce = $settings["Pkce"]
    $dataContext.ClientId = $settings["ClientId"]
    $dataContext.ClientSecret = $settings["ClientSecret"]
    $dataContext.CallbackUrl = $settings["CallbackUrl"]

    foreach ($value in @(
        "data:read", "data:write", "data:create", "data:search", 
        "viewables:read", 
        "bucket:create", "bucket:read", "bucket:update", "bucket:delete", 
        "user-profile:read", 
        "user:read", "user:write", 
        "account:read", "account:write",
        "code:all",
        "openid")) {
        $dataContext.Scope.Add((New-Object PsObject -Property @{ Name=$value; Checked=$true }))
    }

    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
    $xamlFile = [xml](Get-Content "C:\ProgramData\coolOrange\Client Customizations\powerAPS.UI.Authentication.xaml")
    $window = [Windows.Markup.XamlReader]::Load( (New-Object System.Xml.XmlNodeReader $xamlFile) )
    $window.WindowStartupLocation = "CenterScreen"
    $window.Owner = $Host.UI.RawUI.WindowHandle
    $window.DataContext = $dataContext
    $window.FindName('ClientSecret').Password = $window.DataContext.ClientSecret

    $window.FindName('Ok').add_Click({
        if ($window.DataContext.Pkce) {
            $window.DataContext.ClientSecret = ""
        } else {
            $window.DataContext.ClientSecret = $window.FindName('ClientSecret').Password
        }

        $window.DialogResult = $true
        $window.Close()
    }.GetNewClosure())

    $window.FindName('Test').add_Click({
        $window.DataContext.ClientSecret = $window.FindName('ClientSecret').Password

        $arguments = @{
            ClientId = $window.DataContext.ClientId
            CallbackUrl = $window.DataContext.CallbackUrl
        }

        if ($arguments.ClientId -eq "" -or $arguments.CallbackUrl -eq "") {
            [System.Windows.MessageBox]::Show("Please fill in all fields", "APS Connection Test", "OK", "Error")
            return
        }

        $vaultLogin = [Autodesk.Connectivity.WebServicesTools.AutodeskAccount]::Login([IntPtr]::Zero)
        if ($vaultLogin -and $vaultLogin.AccountEmail) {
            $arguments.User = $vaultLogin.AccountEmail
        }

        if ($window.DataContext.Pkce) {
            $arguments.ClientSecret = ""
        } else {
            $arguments.ClientSecret = $window.DataContext.ClientSecret
        }

        $connected = Connect-APS @arguments

        if ($connected) {
            $message = "Autodesk Platform Services (APS) Connection successful"
            $title = "powerAPS Connection Test"
            $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowMessage($message, $title, [Autodesk.DataManagement.Client.Framework.Forms.Currency.ButtonConfiguration]::Ok)
        } else {
            $message = "Autodesk Platform Services (APS) Connection failed: $($connected.Error.Message)"
            $title = "powerAPS Connection Test"
            $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($message, $title)
        }
    }.GetNewClosure())

    $window.FindName('GoToMyApps').add_Click({
        Start-Process "https://aps.autodesk.com/myapps/"
    }.GetNewClosure())

    $window.FindName('GoToDocs').add_Click({
        Start-Process "https://doc.coolorange.com/projects/poweraps/en/stable/code_reference/commandlets/connect-aps/"
    }.GetNewClosure())

    ApplyVaultTheme $window

    if ($window.ShowDialog()) {
        $settings["Pkce"] = $window.DataContext.Pkce
        $settings["ClientId"] = $dataContext.ClientId
        $settings["ClientSecret"] = $dataContext.ClientSecret
        $settings["CallbackUrl"] = $dataContext.CallbackUrl
        return $settings
    }
    return $null
}
