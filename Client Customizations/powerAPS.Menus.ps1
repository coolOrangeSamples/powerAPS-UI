#==============================================================================#
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER    #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES  #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.   #
#                                                                              #
# Copyright (C) 2026 COOLORANGE S.r.l.                                         #
#==============================================================================#

# How to fix DPI display issues in Vault:
# https://www.autodesk.com/support/technical/article/caas/tsarticles/ts/gyzDnXXycpDjsEGyzJ7TY.html

if ($processName -notin @('Connectivity.VaultPro')) {
	return
}

#region Tools Menu
Add-VaultMenuItem -Location ToolsMenu -Name "Authentication Settings..." -Submenu "<b>Autodesk Cloud</b> Settings" -Action {
    $missingRoles = GetMissingRoles @(77, 76)
    if ($missingRoles) {
        $message = "The current user does not have the required permissions: $missingRoles!"
        $title = "Permission Error"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($message, $title)
        return
    }

    try {
        $settings = GetVaultApsAuthenticationSettings $true
    }
    catch {
        $settings = @{}
        $settings["Pkce"] = $false
        $settings["ClientId"] = ""
        $settings["ClientSecret"] = ""
        $settings["Scope"] = "account:read account:write data:read data:write"
        $settings["CallbackUrl"] = "http://localhost:8080/"
    }

    $settings = Get-DialogApsAuthentication $settings
    if ($settings) {
        SetVaultApsAuthenticationSettings $settings
    }
}

Add-VaultMenuItem -Location ToolsMenu -Name "Vault Folder Settings..." -Submenu "<b>Autodesk Cloud</b> Settings" -Action {
    $missingRoles = GetMissingRoles @(77, 76)
    if ($missingRoles) {
        $message = "The current user does not have the required permissions: $missingRoles!"
        $title = "Permission Error"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($message, $title)
        return
    }

    try {
        $behaviors = GetVaultAccFolderBehaviors $true
    }
    catch {
        $behaviors = @{}
        $behaviors["Category"] = ""
        $behaviors["Hub"] = ""
        $behaviors["Project"] = ""
        $behaviors["Folder"] = ""
    }
    
    $behaviors = Get-DialogApsProjectSettings $behaviors
    if ($behaviors) {
        SetVaultAccFolderBehaviors $behaviors
    }
}

Add-VaultMenuItem -Location ToolsMenu -Name "Default Account..." -Submenu "<b>Autodesk Cloud</b> Settings" -Action {
    $missingRoles = GetMissingRoles @(77, 76)
    if ($missingRoles) {
        $message = "The current user does not have the required permissions: $missingRoles!"
        $title = "Permission Error"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($message, $title)
        return
    }

    if (-not (ApsTokenIsValid)) {
        return
    }

    $hubName = GetVaultAccDefaultAccount
    $hub = Get-DialogApsHub "ACC" $hubName
    if (-not $hub) {
        return
    }
    
    SetVaultAccDefaultAccount $hub.Name
}
#endregion

#region Folder Context Menu
Add-VaultMenuItem -Location FolderContextMenu -Name "Assign ACC Project to Folder..." -Submenu "<b>ACC</b>" -Action {
    param($entities)
    $folder = $entities[0]
    if (-not (ApsTokenIsValid)) {
        return
    }

    $missingRoles = GetMissingRoles @(77, 216, 217, 218)
    if ($missingRoles) {
        $message = "The current user does not have the required permissions: $missingRoles!"
        $title = "Permission Error"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($message, $title)
        return
    }

    try {
        $behaviors = GetVaultAccFolderBehaviors
    }
    catch {
        $title = "Configuration Error"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($_, $title)
        return
    }
    
    $hubName = GetVaultAccDefaultAccount
    $result = Get-DialogApsHubAndProject "ACC" $hubName
    $hub = $result.Hub
    $project = $result.Project
    if (-not $hub -or -not $project) {
        return
    }

    if ($project.attributes.extension.data.projectType -ne "ACC") {
        $message = "Currently only ACC projects are supported. Please select another project!"
        $title = "Project Type Mismatch"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($message, $title)
        return
    }

    $accFolder = Get-DialogApsContent $hub $project $false
    if (-not $accFolder) {
        return
    }

    $cats = $vault.CategoryService.GetCategoriesByEntityClassId("FLDR", $true)
    $cat = $cats | Where-Object { $_.Name -eq $behaviors["Category"] }
  
    $properties = @{
        $behaviors["Hub"] = $hub.Name
        $behaviors["Project"] = $project.attributes.name
        $behaviors["Folder"]  = $accFolder.Path
    }

    $propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FLDR")
    $propInstParamArray = New-Object Autodesk.Connectivity.WebServices.PropInstParamArray
    $propInstParams = @()
    foreach ($prop in $properties.GetEnumerator()) {
        $propDef = $propDefs | Where-Object { $_.DispName -eq $prop.Name }
        $propInstParam = New-Object Autodesk.Connectivity.WebServices.PropInstParam
        $propInstParam.PropDefId = $propDef.Id
        $propInstParam.Val = $prop.Value
        $propInstParams += $propInstParam
    }
    $propInstParamArray.Items = $propInstParams
    
    $vault.DocumentServiceExtensions.UpdateFolderProperties(@($folder.Id), @($propInstParamArray))
    $vault.DocumentServiceExtensions.UpdateFolderCategories(@($folder.Id), @($cat.Id))
    
    [System.Windows.Forms.SendKeys]::SendWait('{F5}')
}

Add-VaultMenuItem -Location FolderContextMenu -Name "Edit Attribute Mappings..." -Submenu "<b>ACC</b>" -Action {
    param($entities)
    $folder = $entities[0]
    if (-not (ApsTokenIsValid)) {
        return
    }

    $missingRoles = GetMissingRoles @(77, 253, 254)
    if ($missingRoles) {
        $message = "The current user does not have the required permissions: $missingRoles!"
        $title = "Permission Error"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($message, $title)
        return
    }

    try {
        $existingMapping = GetVaultAccAttributeMapping $folder._FullPath
    }
    catch {
        $title = "Configuration Error"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($_, $title)
        return
    }

    try {
        $newMapping = Get-DialogApsAttributeMapping $folder._FullPath $existingMapping
    }
    catch {
        $title = "Configuration Error"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($_, $title)
        return
    }

    if ($null -ne $newMapping) {
        SetVaultAccAttributeMapping $folder._FullPath $newMapping
    }
}

Add-VaultMenuItem -Location FolderContextMenu -Name "Go To ACC Docs Project..." -Submenu "<b>ACC</b>" -Action {
    param($entities)
    $folder = $entities[0]
    if (-not (ApsTokenIsValid)) {
        return
    }

    try {
        $projectProperties = GetVaultAccProjectProperties $folder._FullPath
    }
    catch {
        $title = "Configuration Error"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($_, $title)
        return
    }

    $hubName = $projectProperties["Hub"]
    $hub = $ApsConnection.Hubs[$hubName].Response
    if (-not $hub) {
        return
    }

    $project = Get-ApsProject $hub $projectProperties["Project"]
    if (-not $project) {
        return
    }

    $baseUrl = GetAccBaseUrlByRegion $hub.attributes.region
    Start-Process "$baseUrl/docs/files/projects/$(($project.id -replace '^b\.', ''))"
}

Add-VaultMenuItem -Location FolderContextMenu -Name "Go To ACC Build Project..." -Submenu "<b>ACC</b>" -Action {
    param($entities)
    $folder = $entities[0]
    if (-not (ApsTokenIsValid)) {
        return
    }

    try {
        $projectProperties = GetVaultAccProjectProperties $folder._FullPath
    }
    catch {
        $title = "Configuration Error"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($_, $title)
        return
    }

    $hubName = $projectProperties["Hub"]
    $hub = $ApsConnection.Hubs[$hubName].Response
    if (-not $hub) {
        return
    }

    $project = Get-ApsProject $hub $projectProperties["Project"]
    if (-not $project) {
        return
    }

    $baseUrl = GetAccBaseUrlByRegion $hub.attributes.region
    Start-Process "$baseUrl/build/files/projects/$(($project.id -replace '^b\.', ''))"
}
#endregion
