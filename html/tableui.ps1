Install-Module -Name TableUI -Repository PSGallery
Install-Module -Name TextTable -Repository PSGallery
Import-Module TableUI
Import-Module TextTable

function New-SplitPane { 
    [CmdletBinding()]
    [CmdletBinding(DefaultParameterSetName = 'Process')]
    Param(
        [Parameter(Position = 0, ParameterSetName = 'Process')]
        [ScriptBlock]$Begin,
        [Parameter(Mandatory, Position = 1, ParameterSetName = 'Process')]
        [ScriptBlock]$Process,
        [Parameter(Mandatory, ParameterSetName = 'Process')]
        [TimeSpan]$Interval,
        [Parameter(ParameterSetName = 'Static')]
        $ScriptBlock,
        [ValidateRange(0.0, 1.0)]
        [float]$Size,
        $ProfileName = 'NoProfile',
        [ValidateSet('Vertical', 'Horizontal')]
        $Orientation
    )
    #keep track of the powershell process id's prior to invoking the new panel process
    $before = Get-Process pwsh
    $command = ' sp'
    if ($ProfileName) { $command += " -p ""$ProfileName""" }
    if ($Orientation) { $command += " --$($Orientation.ToLower())" }
    if ($PSCmdlet.ParameterSetName -eq 'Process') {
        $scriptText = "{`n"
        if ($Begin) { 
            $scriptText += $Begin.ToString() 
        } 
        #wrap the process block into an endless loop and the specified sleep interval
        $scriptText += 'while($true){' + $Process.ToString()
        $scriptText += 'sleep -Seconds ' + $Interval.TotalSeconds + '}}'
    }
    else {
        $scriptText = $ScriptBlock
    }
    $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($scriptText))
    $command += ' pwsh -nop -noexit -encodedCommand ' + $encodedCommand
    Start-Process  wt $command -Wait
    #retrieve the new process id and return it
    (Get-Process pwsh).Where{ $_.id -notin $before.Id }
}



$selections = @()
#$tableData = get-content C:\Share\oconsysFn\oconsysActionMenu.csv | ConvertFrom-Csv
#$tableData | Show-TableUI -DefaultMemberToShow Text,ID -SelectedItemMembersToShow Name,Action,URL -Selections ([ref]$selections) -Title 'Actions' -SelectionFormat 'Selected: {0}'
$tableData = @(
    [PSCustomObject]@{Name = 'Input Action'; Action = 'read-host "Enter a value" -OutVariable global:input' },
    [PSCustomObject]@{Name = 'Disable CPU Handbrake'; Action = 'importCPURegistry' },
    #[PSCustomObject]@{Name = 'Test Action'; Action = 'write-host "Test Action $global:input" -ForegroundColor Green' },
    #[PSCustomObject]@{Name = 'Enter the Massgrave'; Action = 'irm https://massgrave.dev/get | iex' },
    [PSCustomObject]@{Name = 'Quit'; Action = 'exit' }
)

function importCPURegistry{
$regdata=
@'
    Windows Registry Editor Version 5.00
    
    [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager]
    "FeatureSettingsOverride"=dword:02000003
'@

$regdata | Out-File -FilePath $HOME\Downloads\CPUMitigations.reg -Encoding ascii
reg import $HOME\Downloads\CPUMitigations.reg
}


$ScriptBlock = {
    param($currentSelections, $selectedIndex)
    Write-Output  "The current selected Action is: $($tabledata[$selectedIndex].Action)"
    Invoke-Expression -Command $($tabledata[$selectedIndex].Action)
    #Write-Output "`n[Press ENTER to return.]"
    [Console]::CursorVisible = $false
    $cursorPos = $host.UI.RawUI.CursorPosition
    while ($host.ui.RawUI.ReadKey().VirtualKeyCode -ne [ConsoleKey]::Enter) {
        $host.UI.RawUI.CursorPosition = $cursorPos
        [Console]::CursorVisible = $false
    }
}

$tableData | Show-TableUI -DefaultMemberToShow Name -SelectedItemMembersToShow Action -Selections ([ref]$selections) -Title 'Action' -SelectionFormat 'Selected: {0}' -EnterKeyScript $ScriptBlock

#$tableData = winget update | ConvertFrom-TextTable
#$tableData | Show-TableUI -DefaultMemberToShow Name,Available -Selections ([ref]$selections) -Title 'Available Updates'

<# $handle2 = New-SplitPane -ScriptBlock {
    $symbols = 'EURUSD=X,GC=F,^GDAXI,^DJI,^IXIC'
    ticker.exe -w $symbols  --show-summary --show-fundamentals
} -Size 1 -Orientation Horizontal

$handle3 = New-SplitPane -ScriptBlock {
    cls
    ntop
} -Size 1
 #>
