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

function Get-DialogApsAttributeMapping($vaultFolderPath, [Hashtable]$mapping) {
    class DataContext {
        [System.Collections.ObjectModel.ObservableCollection[object]] $Mapping
        [System.Collections.ObjectModel.ObservableCollection[object]] $AccAttributes
        [System.Collections.ObjectModel.ObservableCollection[object]] $VaultProperties
    
        DataContext() {
            $this.Mapping = New-Object System.Collections.ObjectModel.ObservableCollection[object]
            $this.AccAttributes = New-Object System.Collections.ObjectModel.ObservableCollection[object]
            $this.VaultProperties = New-Object System.Collections.ObjectModel.ObservableCollection[object]
        }
    }

    $projectProperties = GetVaultAccProjectProperties $vaultFolderPath
    if (-not $projectProperties) {
        throw "ACC Project folder properties cannot be found!"
    }
    
    $hubName = $projectProperties["Hub"]
    $hub = $ApsConnection.Hubs[$hubName].Response
    $project = Get-ApsProject -hub $hub -projectName $projectProperties["Project"]

    $projectFilesFolder = Get-ApsProjectFilesFolder $hub $project
    $customAttributes = Get-ApsAccCustomAttributeDefinitions $project $projectFilesFolder

    $dataContext = [DataContext]::new()
    $dataContext.AccAttributes.Add("Description")
    $customAttributes | Sort-Object -Property name | ForEach-Object {
        $dataContext.AccAttributes.Add($_.name)
    }
    $file = GetVaultSingleFile
    $file | Get-Member -MemberType Properties | Sort-Object -Property Name | ForEach-Object {
        $dataContext.VaultProperties.Add($_.Name)
    }

    if ($mapping) {
        $mapping.GetEnumerator() | ForEach-Object {
            $dataContext.Mapping.Add((New-Object powerAPS.Utils.MappingItem -Property @{ Acc = $_.Key; Vault = $_.Value }))
        }
    }
    
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
    $xamlFile = [xml](Get-Content "C:\ProgramData\coolOrange\Client Customizations\powerAPS.UI.AttributeMapping.xaml")
    $window = [Windows.Markup.XamlReader]::Load( (New-Object System.Xml.XmlNodeReader $xamlFile) )
    $window.WindowStartupLocation = "CenterScreen"
    $window.Owner = $Host.UI.RawUI.WindowHandle
    $window.DataContext = $dataContext
    
    $window.FindName('AddRow').add_Click({
        $dataGrid = $window.FindName('MappingGrid')
        $newItem = (New-Object powerAPS.Utils.MappingItem -Property @{ Acc = ""; Vault = "" })
        $dataContext.Mapping.Add($newItem)

        # Select & start editing the new row
        $dataGrid.SelectedItem = $newItem
        $dataGrid.ScrollIntoView($newItem)
        $dataGrid.Dispatcher.Invoke([action]{
            $dataGrid.CurrentCell = (New-Object System.Windows.Controls.DataGridCellInfo($newItem, $dataGrid.Columns[0]))
            $dataGrid.BeginEdit() | Out-Null
        })
    }.GetNewClosure())
        
    $window.FindName('RemoveRow').add_Click({
        $dataGrid = $window.FindName('MappingGrid')
        $toRemove = @($dataGrid.SelectedItems)

        foreach ($item in $toRemove) {
            if ($null -ne $item) {
                [void]$dataContext.Mapping.Remove($item)
            }
        }
    }.GetNewClosure())
        
    $window.FindName('Ok').add_Click({
        $dataGrid = $window.FindName("MappingGrid")

        # Force commit of pending edits (ComboBox edits often only commit on focus change)
        $dataGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true) | Out-Null
        $dataGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Row,  $true) | Out-Null

        $lcv = [System.Windows.Data.CollectionViewSource]::GetDefaultView($dataGrid.ItemsSource)
        if ($lcv.IsAddingNew) {
            $lcv.CommitNew()
        }
        if ($lcv.IsEditingItem) {
            $lcv.CommitEdit()
        }

        $window.DialogResult = $true
        $window.Close()
    }.GetNewClosure())
    
    ApplyVaultTheme $window

    if ($window.ShowDialog()) {
        $result = @{}
        $dataContext.Mapping | ForEach-Object {
            if ($_.Acc -and $_.Vault) {
                $result[$_.Acc] = $_.Vault
            }
        }
        return $result
    }

    return $null
}
