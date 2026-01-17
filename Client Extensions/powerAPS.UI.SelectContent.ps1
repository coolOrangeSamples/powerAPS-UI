#==============================================================================#
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER    #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES  #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.   #
#                                                                              #
# Copyright (C) 2026 COOLORANGE S.r.l.                                         #
#==============================================================================#

foreach ($module in Get-Childitem "C:\ProgramData\coolOrange\powerAPS" -Name -Filter "*.psm1") {
    Import-Module "C:\ProgramData\coolOrange\powerAPS\$module" -Force -Global
}

function Get-DialogApsContent($hub, $project, $showFiles = $false) {

    class ContentDialogResult {
        [string] $Path
        [object] $Object
    }

    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
    $xamlFile = [xml](Get-Content "C:\ProgramData\coolOrange\Client Customizations\powerAPS.UI.SelectContent.xaml")
    $window = [Windows.Markup.XamlReader]::Load( (New-Object System.Xml.XmlNodeReader $xamlFile) )
    $window.WindowStartupLocation = "CenterScreen"
    $window.Owner = $Host.UI.RawUI.WindowHandle
    $window.FindName("Label").Content = "Select Content from '$($project.attributes.name.Replace("_", "__"))' ($($hub.Name.Replace("_", "__")))"

    function LoadChildren($node) {
        $window.Cursor = [System.Windows.Input.Cursors]::Wait
        $children = Get-ApsFolderContents $project $node.Object
        foreach ($child in $children) {
            if ($child.type -eq "folders") {    
                $folderNode = [powerAPS.Utils.TreeViewNode]::new($node, ($child.attributes.objectCount -eq 0))
                $folderNode.Name = $child.attributes.displayName
                $folderNode.Type = "Folder"
                $folderNode.Object = $child
                $folderNode.add_LoadChildren({ LoadChildren($args[0]) })
                $node.Children.Add($folderNode)      
            }
            elseif ($child.type -eq "items") {
                if (-not $showFiles){
                    continue
                }
                $itemNode = [powerAPS.Utils.TreeViewNode]::new($node, $true)
                $itemNode.Name = $child.attributes.displayName
                $itemNode.Type = "File"
                $itemNode.Object = $child
                $node.Children.Add($itemNode)
            }
        }
        $window.Cursor = $null
    }
    
    $topFolders = Get-ApsTopFolders $hub $project
    $nodes = New-Object System.Collections.ObjectModel.ObservableCollection[[powerAPS.Utils.TreeViewNode]]
    foreach ($folder in $topFolders) {
        if ($folder.attributes.hidden) {
            #continue
        }

        if ($folder.attributes.extension.data.folderType -ne "normal") {
            #continue
        }

        $rootNode = [powerAPS.Utils.TreeViewNode]::new($null)
        $rootNode.Name = $folder.attributes.displayName

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

        $rootNode.Type = $type
        $rootNode.Object = $folder
        $rootNode.add_LoadChildren({ LoadChildren($args[0]) })
        #$rootNode.IsExpanded = $true
        $nodes.Add($rootNode)
    }        

    $treeView = $window.FindName('TreeView')
    $treeView.ItemsSource = $nodes

    $result = [ContentDialogResult]::new()
    
    $window.FindName('Ok').add_Click({
        $currentObject = $treeView.SelectedItem
        $path = $currentObject.Name
        while ($null -ne $currentObject.Parent) {
            $currentObject = $currentObject.Parent
            $path = $currentObject.Name + "/" + $path
        }

        $result.Object = $treeView.SelectedItem.Object
        $result.Path = $path

        $window.DialogResult = $true
        $window.Close()
    }.GetNewClosure())

    ApplyVaultTheme $window

    if ($window.ShowDialog()) {
        return $result
    }
    
    return $null
}