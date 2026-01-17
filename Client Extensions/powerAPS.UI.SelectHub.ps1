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

function Get-DialogApsHub($typeFilter = $null, $selectedHub = $null) {
    $hubsItemsSource = @()

    $hubs = $global:APSConnection.Hubs
    foreach ($hub in $hubs) {
        switch ($hub.Response.attributes.extension.type) {
            "hubs:autodesk.core:Hub" { 
                $type = "Fusion"
                #$hubsItemsSource += New-Object PsObject -Property @{ Hub = $hub; Type = $type }
            }
            "hubs:autodesk.a360:PersonalHub" {
                $type = "Fusion"
                #$hubsItemsSource += New-Object PsObject -Property @{ Hub = $hub; Type = $type }
            }
            "hubs:autodesk.bim360:Account" {
                $type = "ACC"
                $hubsItemsSource += New-Object PsObject -Property @{ Hub = $hub; Type = $type }
            }
            default {
                $type = $null
            }
        }
    }
  
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
    $xamlFile = [xml](Get-Content "C:\ProgramData\coolOrange\Client Customizations\powerAPS.UI.SelectHub.xaml")
    $window = [Windows.Markup.XamlReader]::Load( (New-Object System.Xml.XmlNodeReader $xamlFile) )
    $window.WindowStartupLocation = "CenterScreen"
    $window.Owner = $Host.UI.RawUI.WindowHandle
    $window.FindName("Hub").ItemsSource = $hubsItemsSource
    $window.FindName("Hub").SelectedItem = $hubsItemsSource | Where-Object { $_.Hub.Name -eq $selectedHub }

    $window.FindName('Ok').add_Click({
        $window.DialogResult = $true
        $window.Close()
    }.GetNewClosure())

    ApplyVaultTheme $window

    if ($window.ShowDialog()) {
        return $window.FindName("Hub").SelectedItem.Hub
    }

    return $null
}