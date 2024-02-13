Install-Module -Name TableUI -Repository PSGallery
Install-Module -Name TextTable -Repository PSGallery
Import-Module TableUI
Import-Module TextTable

$selections = @()
$tableData = @(
    [PSCustomObject]@{Name = 'Input Action'; Action = 'read-host "Enter a value" -OutVariable global:input' },
    [PSCustomObject]@{Name = 'Test Action'; Action = 'write-host "Test Action $global:input" -ForegroundColor Green' },
    [PSCustomObject]@{Name = 'Enter the Massgrave'; Action = 'irm https://massgrave.dev/get | iex' },
    [PSCustomObject]@{Name = 'Quit'; Action = 'exit' }
)

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
