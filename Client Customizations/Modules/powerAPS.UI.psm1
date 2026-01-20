<#
Apply the current Vault theme to a WPF control. This function assumes that the control's resources
contain two merged resource dictionaries: the first one is replaced with the current theme,
and the second one contains custom image resources and types for the WPF dialogs.

<wpf:ThemedWPFWindow.Resources>
    <ResourceDictionary>
        <ResourceDictionary.MergedDictionaries>
            <ResourceDictionary Source="pack://application:,,,/Autodesk.DataManagement.Client.Framework.Forms;component/Controls/WPF/ControlTemplates/MergedResources.xaml" />
            <ResourceDictionary Source="pack://application:,,,/powerAPS.Utils;component/Controls/WPF/ImageResources.xaml" />
        </ResourceDictionary.MergedDictionaries>
    </ResourceDictionary>
</wpf:ThemedWPFWindow.Resources>
#>
function ApplyVaultTheme($control) {
    $currentTheme = [Autodesk.DataManagement.Client.Framework.Forms.SkinUtils.WinFormsTheme]::Instance.CurrentTheme
    $md = $control.Resources.MergedDictionaries[0]
    $pd = $control.Resources.MergedDictionaries[1]
    if (-not $md) { return }

    # Add the current theme to the resource dictionary
    $td = [System.Management.Automation.PSSerializer]::Deserialize([System.Management.Automation.PSSerializer]::Serialize($md, 20))
    $td.Source = New-Object Uri("pack://application:,,,/Autodesk.DataManagement.Client.Framework.Forms;component/SkinUtils/WPF/Themes/$($currentTheme)Theme.xaml", [System.UriKind]::Absolute)
    $control.Resources.MergedDictionaries.Clear()
    $control.Resources.MergedDictionaries.Add($td);
    $control.Resources.MergedDictionaries.Add($md);
    $control.Resources.MergedDictionaries.Add($pd);

    if ($control -is [Autodesk.DataManagement.Client.Framework.Forms.Controls.WPF.ThemedWPFWindow]) {
        # Set Vault to be the owner of the window
        $interopHelper = New-Object System.Windows.Interop.WindowInteropHelper($control)
        $interopHelper.Owner = (Get-Process -Id $PID).MainWindowHandle

        # Set the window style, depending on the current theme
        $styleKey = if ($currentTheme -eq "Default") { "DefaultThemedWindowStyle" } else { "DarkLightThemedWindowStyle" }
        $control.Style = $control.Resources.MergedDictionaries[0][$styleKey]    
    }
    elseif ($control -is [System.Windows.Controls.ContentControl]) {
        # powerEvents to reload the tab?!
    }
    else {
        return
    }

    <#
    # Workaround to fix the DataGrid colors in light theme
    if ($currentTheme -eq "Light") {
        $dataGrids = FindLogicalChildren -Parent $control -Type ([System.Windows.Controls.DataGrid])
        foreach ($dataGrid in $dataGrids) {
            $cellStyle = $dataGrid.CellStyle
            $trigger = New-Object Windows.Trigger
            $trigger.Property = [Windows.Controls.DataGridCell]::IsSelectedProperty
            $trigger.Value = $true
            $color = [System.Windows.Media.ColorConverter]::ConvertFromString("#e1f2fa")
            $brush = New-Object System.Windows.Media.SolidColorBrush $color
            $brush.Freeze()
            $trigger.Setters.Add((New-Object Windows.Setter([Windows.Controls.Control]::BackgroundProperty, $brush)))
            $trigger.Setters.Add((New-Object Windows.Setter([Windows.Controls.Control]::ForegroundProperty, [Windows.Media.Brushes]::Black)))
            $cellStyle.Triggers.Add($trigger)
            $dataGrid.CellStyle = $cellStyle            
        }
    }
    #>
}

function FindVisualChildren([System.Windows.DependencyObject] $parent, [Type] $type) {
    $results = @()
    for ($i = 0; $i -lt [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Parent); $i++) {
        $child = [System.Windows.Media.VisualTreeHelper]::GetChild($Parent, $i)
        if ($child -is $Type) {
            $results += $child
        }
        $results += FindVisualChildren -Parent $child -Type $Type
    }
    return $results
}

function FindLogicalChildren([System.Windows.DependencyObject] $parent, [Type] $type) {
    $results = @()
    foreach ($child in [System.Windows.LogicalTreeHelper]::GetChildren($Parent)) {
        if ($child -is [System.Windows.DependencyObject]) {
            if ($child -is $Type) {
                $results += $child
            }
            $results += FindLogicalChildren -Parent $child -Type $Type
        }
    }
    return $results
}
