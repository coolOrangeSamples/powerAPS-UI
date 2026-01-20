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

function Get-DialogApsHubAndProject($typeFilter = $null, $selectedHub = $null, $selectedProject = $null) {

    class HubAndProjectDialogResult {
        [object] $Hub
        [object] $Project
    }

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

    $loadProject = {
        param($selection)

        $window.Cursor = [System.Windows.Input.Cursors]::Wait
        $projectsItemsSource = @()
        $projects = Get-ApsProjects $selection.Hub
        foreach ($project in $projects) {
            switch ($project.attributes.extension.type) {
                "projects:autodesk.core:Project" { 
                    $type = "Fusion"
                }
                "projects:autodesk.bim360:Project" {
                    if ($project.attributes.extension.data.projectType -eq "ACC") {
                        $type = "ACC"
                    } else {
                        $type = "BIM360"
                    }
                }
                default {
                    $type = $null
                }
            }
            $projectsItemsSource += New-Object PsObject -Property @{ Project = $project; Type = $type; Name = $project.attributes.name }
        }
        $projectsItemsSource = $projectsItemsSource | Sort-Object -Property Name
        $projectsItemsSource = $projectsItemsSource | Where-Object { -not $_.Project.attributes.name.Contains("test") -and -not $_.Project.attributes.name.Contains("Test") }
        $window.Cursor = $null
        return $projectsItemsSource
    }
  
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
    $xamlFile = [xml](Get-Content "C:\ProgramData\coolOrange\Client Customizations\powerAPS.UI.SelectHubAndProject.xaml")
    $window = [Windows.Markup.XamlReader]::Load( (New-Object System.Xml.XmlNodeReader $xamlFile) )
    $window.WindowStartupLocation = "CenterScreen"
    $window.Owner = $Host.UI.RawUI.WindowHandle
    $window.FindName("Hub").ItemsSource = $hubsItemsSource

    if ($selectedHub) {
        $window.FindName("Hub").SelectedItem = $hubsItemsSource | Where-Object { $_.Hub.Name -eq $selectedHub }
        $projectsItemsSource = @(Invoke-Command $loadProject -ArgumentList $window.FindName('Hub').SelectedItem)
        $window.FindName('Project').ItemsSource = $projectsItemsSource
        $window.FindName('Project').SelectedValue = ($projectsItemsSource | Where-Object { $_.Project.attributes.name -eq $selectedProject }).Project
    }
    
    $window.FindName('Hub').add_SelectionChanged({
        $projectsItemsSource = @(Invoke-Command $loadProject -ArgumentList $window.FindName('Hub').SelectedItem)
        $window.FindName('Project').ItemsSource = $projectsItemsSource
        $window.FindName('Project').SelectedValue = $null
    }.GetNewClosure())
            
    $window.FindName('Ok').add_Click({
        $window.DialogResult = $true
        $window.Close()
    }.GetNewClosure())

    ApplyVaultTheme $window

    if ($window.ShowDialog()) {
        $result = [HubAndProjectDialogResult]::new()
        $result.Hub = $window.FindName('Hub').SelectedItem.Hub
        $result.Project = $window.FindName('Project').SelectedValue
        return $result
    }

    return $null
}
