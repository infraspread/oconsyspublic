#Install-Module -Name TableUI -Repository PSGallery
#Install-Module -Name TextTable -Repository PSGallery
#Import-Module TableUI
#Import-Module TextTable

# The overall width of the UI.
[int]$UIWidth = 80
[int]$UIWidthMin = 54

# Frame buffer to mitigate re-draw flicker.
[string[]]$FrameBuffer = @('')

# Example of a custom script block
$DummyScriptBlock = {
    param($currentSelections, $selectedIndex)

    Clear-Host
    Write-Output  "The currently selected index is: $selectedIndex"
    Write-Output "`n[Press ENTER to return.]"
    [Console]::CursorVisible = $false
    $cursorPos = $host.UI.RawUI.CursorPosition
    while ($host.ui.RawUI.ReadKey().VirtualKeyCode -ne [ConsoleKey]::Enter) {
        $host.UI.RawUI.CursorPosition = $cursorPos
        [Console]::CursorVisible = $false
    }
}

<#
.DESCRIPTION
    Clears the frame buffer.
#>
function Clear-Frame
{
    $script:FrameBuffer = @('')
}

<#
.DESCRIPTION
    Writes the frame buffer to output.
#>
function Show-Frame
{
    $host.UI.RawUI.CursorPosition = @{ X = 0; Y = 0 }
    $script:FrameBuffer | ForEach-Object {
        Write-Output $_
    }

    $endPosition = $host.UI.RawUI.CursorPosition

    # Clean up re-rendering artifacts cause by window resizing.
    Write-Host -NoNewline (' ' * $UIWidth)
    $host.UI.RawUI.CursorPosition = @{ X = 0; Y = 0 }
    Write-Output (' ' * $UIWidth)
    $host.UI.RawUI.CursorPosition = $endPosition
}


<#
.DESCRIPTION
    Writes a top-bar to the frame buffer.
#>
function Write-FrameTopBar
{
    param (
        # The width of the overall UI. The content will take up $Width - 4.
        [int]$Width = $UIWidth,

        # Set to indicate that columns have been dropped from the UI.
        [switch]$Truncated
    )

    if ($Truncated) {
        $script:FrameBuffer += "┌$('─' * ($Width - 2))╖"
    } else {
        $script:FrameBuffer += "┌$('─' * ($Width - 2))┐"
    }
}

<#
.DESCRIPTION
    Writes a middle-bar to the frame buffer.
#>
function Write-FrameMiddleBar
{
    param (
        # The width of the overall UI. The content will take up $Width - 4.
        [int]$Width = $UIWidth,

        # Set to indicate that columns have been dropped from the UI.
        [switch]$Truncated
    )

    if ($Truncated) {
        $script:FrameBuffer += "├$('─' * ($Width - 2))╢"
    } else {
        $script:FrameBuffer += "├$('─' * ($Width - 2))┤"
    }
}

<#
.DESCRIPTION
    Writes a bottom-bar to the frame buffer.
#>
function Write-FrameBottomBar
{
    param (
        # The width of the overall UI. The content will take up $Width - 4.
        [int]$Width = $UIWidth,

        # Set to indicate that columns have been dropped from the UI.
        [switch]$Truncated
    )

    if ($Truncated) {
        $script:FrameBuffer += "└$('─' * ($Width - 2))╜"
    } else {
        $script:FrameBuffer += "└$('─' * ($Width - 2))┘"
    }
}

<#
.DESCRIPTION
    Writes the top-bar used for column separation to the frame buffer.
#>
function Write-FrameColumnTopBar
{
    param (
        # The width of each column's content
        [int[]]$ColumnWidth,

        # Set to indicate that columns have been dropped from the UI.
        [switch]$Truncated
    )

    $line = '├'  + ('─' * ($ColumnWidth[0] + 6))
    $ColumnWidth | Select-Object -Skip 1| ForEach-Object {
        $line += '┬'  + ('─' * ($_ + 2))
    }

    if ($Truncated) {
        $line += '╢'
    } else {
        $line += '┤'
    }

    $script:FrameBuffer += $line
}

<#
.DESCRIPTION
    Writes the middle-bar used for column separation to the frame buffer.
#>
function Write-FrameColumnMiddleBar
{
    param (
        # The width of each column's content
        [int[]]$ColumnWidth,

        # Set to indicate that columns have been dropped from the UI.
        [switch]$Truncated
    )

    $line = '├'  + ('─' * ($ColumnWidth[0] + 6))
    $ColumnWidth | Select-Object -Skip 1| ForEach-Object {
        $line += '┼'  + ('─' * ($_ + 2))
    }

    if ($Truncated) {
        $line += '╢'
    } else {
        $line += '┤'
    }

    $script:FrameBuffer += $line
}

<#
.DESCRIPTION
    Writes the bottom-bar used for column separation to the frame buffer.
#>
function Write-FrameColumnBottomBar
{
    param (
        # The width of each column's content
        [int[]]$ColumnWidth,

        # Set to indicate that columns have been dropped from the UI.
        [switch]$Truncated
    )

    $line = '├'  + ('─' * ($ColumnWidth[0] + 6))
    $ColumnWidth | Select-Object -Skip 1| ForEach-Object {
        $line += '┴'  + ('─' * ($_ + 2))
    }

    if ($Truncated) {
        $line += '╢'
    } else {
        $line += '┤'
    }

    $script:FrameBuffer += $line
}

<#
.DESCRIPTION
    Writes content to the frame buffer.
#>
function Write-FrameContent
{
    param (
        # The width of the overall UI. The content will take up $Width - 4.
        [int]$Width = $UIWidth,

        # The data to write to the current line.
        [string]$Content,

        # ANSI string that is responsible for setting the text styling for
        # the content. The frame/bars are not affected by this setting.
        [string]$AnsiiFormat = '',

        # Set to indicate that columns have been dropped from the UI.
        [switch]$Truncated
    )

    # Account for 4-characters consisting of leading and trailing pipe + space characters
    if ($Content.Length -gt ($Width - 4)) {
        # Truncate to fit width (account for additional ellipsis)
        $Content = "$($Content.Substring(0, $Width - 4 - 1))…"
    } else {
        # Pad the tail to fit $Width
        $Content = $Content + (' ' * (($Width - 4) - $Content.Length))
    }

    if ($Truncated) {
        $endBar = '║'
    } else {
        $endBar = '│'
    }

    if ([string]::IsNullOrWhiteSpace($AnsiiFormat)) {
        $script:FrameBuffer += "│ $Content $endBar"
    } else {
        $script:FrameBuffer += "│$AnsiiFormat $Content $($PSStyle.Reset)$endBar"
    }
}

<#
.DESCRIPTION
    Write the frame data for the UI title bar.
#>
function Write-FrameTitle
{
    param (
        # The message to show. WIll be automatically truncated if it does
        # not fit within the contrains set by $UIWidth.
        [string]$Content,

        # ANSI string that is responsible for setting the text styling for
        # the content. The frame/bars are not affected by this setting.
        [string]$AnsiiFormat = '',

        # Set to indicate that columns have been dropped from the UI.
        [switch]$Truncated
    )

    Write-FrameTopBar -Truncated:$Truncated
    if ([string]::IsNullOrWhiteSpace($AnsiiFormat)) {
        Write-FrameContent -Truncated:$Truncated -Content $Content
    } else {
        Write-FrameContent -Truncated:$Truncated -Content "$AnsiFormat$Content$($PSStyle.Reset)"
    }
}

<#
.DESCRIPTION
    Write the frame data for the UI column header(s).
#>
function Write-ColumnHeader
{
    param (
        # The widths of each column
        [int[]]$ColumnWidth,

        # The members to show in the UI.
        [string[]]$MemberToShow,

        # Set to indicate that columns have been dropped from the UI.
        [switch]$Truncated,

        # When set, the column header names will be drawn.
        [switch]$ShowColumnHeader
    )

    Write-FrameColumnTopBar -Truncated:$Truncated -ColumnWidth $ColumnWidth

    if (-not($ShowColumnHeader)) {
        return
    }

    $line = '│     ' + $MemberToShow[0] + (' ' * ($ColumnWidth[0] - $MemberToShow[0].Length + 1))

    for ($i = 1; $i -lt $ColumnWidth.Count; $i++)
    {
        $line += '│ ' + $MemberToShow[$i] + (' ' * ($ColumnWidth[$i] - $MemberToShow[$i].Length + 1))
    }

    if ($Truncated) {
        $line += '║'
    } else {
        $line += '│'
    }

    $script:FrameBuffer += $line

    Write-FrameColumnMiddleBar -Truncated:$Truncated -ColumnWidth $ColumnWidth
}

<#
.DESCRIPTION
    Write the frame data for the title of the selected item section.
#>
function Write-FrameSelectedItemTitle
{
    param (
        # The message to show. WIll be automatically truncated if it does
        # not fit within the contrains set by $Width.
        [string]$Content,

        # ANSI string that is responsible for setting the text styling for
        # the content. The frame/bars are not affected by this setting.
        [string]$AnsiiFormat = '',

        # Set to indicate that columns have been dropped from the UI.
        [switch]$Truncated
    )

    Write-FrameMiddleBar -Truncated:$Truncated
    Write-FrameContent -Truncated:$Truncated -Content $Content -AnsiiFormat $AnsiiFormat
    Write-FrameMiddleBar -Truncated:$Truncated
}

<#
.DESCRIPTION
    Converts a selection item into the content that is to be shown on a single line in the UI's windowed selection.
    This function factors in the UI width to determine what items in the object to draw.
#>
function Get-SelectionItemLineContent
{
    param (
        # The object to render the line content for.
        [object]$SelectionItem,

        # The member(s) to show in the UI.
        [string[]]$MemberToShow,

        # The width of each column to show.
        [int[]]$ColumnWidth,

        # The 3-character string to indicate if the item is the currently focused/highlighted item and whether the item has been selected.
        [string]$SelectionHeader
    )

    $columnContent = [string]($SelectionItem.($MemberToShow[0]))
    $colWidth = $ColumnWidth[0]

    if ($columnContent.Length -gt $colWidth) {
        # Truncate to fit width (account for additional ellipsis)
        $columnContent = "$($columnContent.Substring(0, $colWidth - 1))…"
    } else {
        # Pad the tail to fit $colWidth
        $columnContent = $columnContent + (' ' * ($colWidth - $columnContent.Length))
    }

    $lineContent = "$SelectionHeader $columnContent"

    for ($i = 1; $i -lt $ColumnWidth.Count; $i++)
    {
        $columnContent = [string]($SelectionItem.($MemberToShow[$i]))
        $colWidth = $ColumnWidth[$i]

        if ($columnContent.Length -gt $colWidth) {
            # Truncate to fit width (account for additional ellipsis)
            $columnContent = "$($columnContent.Substring(0, $colWidth - 1))…"
        } else {
            # Pad the tail to fit $colWidth
            $columnContent = $columnContent + (' ' * ($colWidth - $columnContent.Length))
        }

        $lineContent += " │ $columnContent"
    }

    return $lineContent
}

<#
.DESCRIPTION
    Write the frame data for the selectable items.
#>
function Write-FrameSelectionItems
{
    param (
        # The title to display.
        [string]$Title,

        # An array of objects containing one of more string members to be displayed in the selection region of the UI.
        [object[]]$SelectionItems,

        # The member(s) to show in the UI. Members are arranged from left to right in the UI.
        [string[]]$MemberToShow,

        # The index of the currently highlighted item in the list of selectable items.
        [int]$SelectionIndex,

        # The state of the selections made by the user.
        [bool[]]$Selections,

        # The vertical span (text rows) of the windowed view of the UI.
        [int]$WindowedSpan,

        # The widths to constrain each column in the UI to. The right most column(s) will be dropped from the display
        # when it is determined that the contents do not fit. The first column will always be drawn and will be
        # truncated accordingly. If the first column's width is set to less than the width of the actual content the UI
        # will permit truncation down to this point before the right most column(s) are dropped from the display.
        [int[]]$ColumnWidth,

        # Set to indicate that columns have been dropped from the UI.
        [switch]$Truncated,

        # When set, the column header names will be drawn.
        [switch]$ShowColumnHeader
    )

    Write-FrameTitle -Truncated:$Truncated -Content $Title
    Write-ColumnHeader -Truncated:$Truncated -ColumnWidth $widths -MemberToShow $MemberToShow -ShowColumnHeader:$ShowColumnHeader

    for ($i = 0; $i -lt $SelectionItems.Count; $i++) {
        $selectedChar = " "
        if ($Selections[$i]) { $selectedChar = '•' }

        $lineContentArgs = @{
            SelectionItem = $SelectionItems[$i]
            SelectionHeader = "    "
            MemberToShow = $MemberToShow
            ColumnWidth = $widths
        }

        if ($i -eq $SelectionIndex) {
            $lineContentArgs.SelectionHeader = "[$selectedChar]"
            $lineContent = Get-SelectionItemLineContent @lineContentArgs
            Write-FrameContent -Truncated:$Truncated -Content $lineContent -AnsiiFormat "$($PSStyle.Background.BrightBlue)$($PSStyle.Foreground.BrightWhite)"
        } else {
            $lineContentArgs.SelectionHeader = " $selectedChar "
            $lineContent = Get-SelectionItemLineContent @lineContentArgs
            Write-FrameContent -Truncated:$Truncated -Content $lineContent
        }
    }

    if ($UIFit -eq 'Fill') {
        $padRows = $WindowedSpan - $SelectionItems.Count
        $emptyItem = @{}
        $MemberToShow | ForEach-Object {
            $emptyItem | Add-Member -MemberType NoteProperty -Name $_ -Value ''
        }
        $lineContentArgs = @{
            SelectionItem = $emptyItem
            SelectionHeader = "   "
            MemberToShow = $MemberToShow
            ColumnWidth = $widths
        }
        $lineContent = Get-SelectionItemLineContent @lineContentArgs
        while ($padRows -gt 0) {
            Write-FrameContent -Truncated:$Truncated -Content $lineContent
            $padRows--
        }
    }

    Write-FrameColumnBottomBar -Truncated:$Truncated -ColumnWidth $widths
}

<#
.DESCRIPTION
    Write the frame data for the currently selected item.
#>
function Write-FrameSelectedItem
{
    param (
        # An array of objects containing the selectable items.
        [object[]]$SelectionItems,

        # The index of the currently highlighted item in the list of selectable items.
        [int]$SelectionIndex,

        # An array of strings representing the members to show for the currently selected/highlighted item.
        [string[]]$MembersToShow,

        # Set to indicate that columns have been dropped from the UI.
        [switch]$Truncated
    )

    Write-FrameSelectedItemTitle -Truncated:$Truncated -Content "Current Selection ($($selectionIndex+1) of $($SelectionItems.Count))"

    $maxMemberName = ($MembersToShow | Measure-Object -Property Length -Maximum).Maximum + 1
    # The special formatting characters result in additional non-printable characters that need to be accounted for.
    $ansiFormat = $PSStyle.Foreground.Green
    $ansiFormatAlt = $PSStyle.Foreground.BrightBlack
    $widthCorrection = $ansiFormat.Length + $PSStyle.Reset.Length
    $MembersToShow | ForEach-Object {
        if (-not([string]::IsNullOrWhiteSpace(($SelectionItems[$SelectionIndex].$_)))) {
            $content = "$ansiFormat$_$(' ' * ($maxMemberName - $_.Length)): $($PSStyle.Reset)$($SelectionItems[$SelectionIndex].$_ -join ', ')"
        } else {
            $content = "$ansiFormatAlt$_$(' ' * ($maxMemberName - $_.Length)): $($PSStyle.Reset)"
        }

        Write-FrameContent -Truncated:$Truncated -Width ($UIWidth + $widthCorrection) -Content $content
    }

    Write-FrameBottomBar -Truncated:$Truncated
}

<#
.DESCRIPTION
    Gets the start index for the windows list view.
#>
function Get-WindowStartIndex {
    param (
        # The vertical span (text rows) of the windowed view of the UI.
        [int]$WindowSpan,

        # The index of the currently highlighted item in the list of selectable items.
        [int]$SelectionIndex,

        # The total number of items in the selection list.
        [int]$SelectionCount
    )

    # Calculate the ideal start index to center the selection.
    $windowStartIndex = $SelectionIndex - [Math]::Floor($WindowSpan / 2)

    # Adjust the start index if it's near the start or end of the list.
    if ($windowStartIndex -lt 0) {
        $windowStartIndex = 0
    } elseif ($windowStartIndex + $WindowSpan -gt $SelectionCount) {
        $windowStartIndex = $SelectionCount - $WindowSpan

        if ($windowStartIndex -lt 0) {
            $windowStartIndex = 0
        }
    }

    return $windowStartIndex
}

<#
.DESCRIPTION
    Wrapper to handle setting buffer width depending on OS.

.OUTPUTS
    $True if the requested width failed, and should be rehandled in another
    call.
#>
function Set-BufferWidth
{
    param (
        # The width to set the buffer to (in characters).
        [int]$Width
    )

    $redraw = $false

    if ($IsWindows) {
        $ErrorActionPreferenceBackup = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'

        try {
            # This may fail if window is widened right before this statement
            # executes as the buffer width must always be at least the
            # window width.
            [Console]::BufferWidth = $Width
        } catch [System.Management.Automation.SetValueInvocationException] {
            # Ignore the error and tell the caller to retry after determining
            # whether the buffer width is still valid for the current window
            # width.
            $redraw = $true
        } finally {
            $ErrorActionPreference = $ErrorActionPreferenceBackup
        }

    } else {
        # While this is not equivalent to setting the buffer width,
        # it still appears to help eliminate unwanted flickering
        # when the width is smaller than the minimum width.
        stty cols $Width
    }

    return $redraw
}

<#
.DESCRIPTION
    Write the frame data for the user controls.
#>
function Write-FrameControls
{
    param (
        # Decription should be filled to 60-characters.
        [string]$EnterKeyDescription,

        # When set, only the help key is shown
        [switch]$Minimize,

        # Set to indicate that columns have been dropped from the UI.
        [switch]$Truncated
    )

    if ($Minimize) {
        Write-FrameContent -Truncated:$Truncated -AnsiiFormat "$($PSStyle.Background.BrightBlack)" -Content "Press '?' to show the controls menu."
    } else {
        Write-FrameContent -Truncated:$Truncated -AnsiiFormat "$($PSStyle.Background.BrightBlack)" -Content 'Press (PAGE) UP or (PAGE) DOWN to navigate selection.'
        Write-FrameContent -Truncated:$Truncated -AnsiiFormat "$($PSStyle.Background.BrightBlack)" -Content $EnterKeyDescription
        Write-FrameContent -Truncated:$Truncated -AnsiiFormat "$($PSStyle.Background.BrightBlack)" -Content 'Press SPACE to toggle selection.'
        Write-FrameContent -Truncated:$Truncated -AnsiiFormat "$($PSStyle.Background.BrightBlack)" -Content "Press 'A' to select all, 'N' to select none."
        Write-FrameContent -Truncated:$Truncated -AnsiiFormat "$($PSStyle.Background.BrightBlack)" -Content "Press 'C' to finish selections and continue operation."
        Write-FrameContent -Truncated:$Truncated -AnsiiFormat "$($PSStyle.Background.BrightBlack)" -Content "Press '?' to minimize the controls menu."
        Write-FrameContent -Truncated:$Truncated -AnsiiFormat "$($PSStyle.Background.BrightBlack)" -Content "Press ESC or 'Q' to quit now and cancel operation."
    }
}

<#
.DESCRIPTION
    Gets the maximum length of each member to be shown in the windowed view.
#>
function Get-ItemMaxLength
{
    param (
        # The item(s) to compute the maximum length for the specified members.
        [object[]]$Item,

        # The name(s) of the member to compute the maximum for.
        [string[]]$MemberName
    )

    $columnWidths = @()
    $MemberName | ForEach-Object {
        $columnWidths += ([string[]]@($Item.$_) | Measure-Object -Property Length -Maximum).Maximum
    }

    # Ensure that the column headers (member names) will also fit in this space.
    for ($i = 0; $i -lt $columnWidths.Count; $i++)
    {
        if ($columnWidths[$i] -lt $MemberName[$i].Length) {
            $columnWidths[$i] = $MemberName[$i].Length
        }
    }

    return $columnWidths
}

<#
.DESCRIPTION
    Gets the column width(s) to be used for the windowed selection list. The
    result depends on -TotalWidth and the values specified in -ColumnWidth.
    This application will always give display priority to the first column. If
    subsequent columns do not fit (without truncation), they will be dropped
    (starting from the tailing column. Truncation on the first column is only
    enabled when it is determined that other columns will not fit within the
    width constraint. If all members with within the width constraint and there
    are additional characters left over, this additional space is to be applied
    to the first column's width.

.OUTPUTS
    A list of column widths that each column of data is to be constraind to.
    The number of elements in this output will always be at least one element
    and at most "@($MemberToShow).Length" elements.
#>
function Get-SelectionListColumnWidth
{
    param (
        # One or more column widths to be used in the windowed list view.
        [int[]]$ColumnWidth,

        # The total width that the columns are to be constrained to.
        [int]$TotalWidth
    )

    $outputColumnWidths = @($ColumnWidth[0])
    $numAlignChars = 8
    # Account for the 8 additional characters for spacing (i.e. characters in this string not including CONTENT: "| [*] CONTENT |")
    $spaceAvailable = $TotalWidth - $numAlignChars
    if ($ColumnWidth[0] -gt $spaceAvailable) {
        $outputColumnWidths[0] = $spaceAvailable
        return $outputColumnWidths
    }

    $spaceAvailable -= $ColumnWidth[0]
    $noSpaceRemainding = $false
    $numAlignChars = 3
    $ColumnWidth | Select-Object -Last ($ColumnWidth.Count - 1) | ForEach-Object {
        # Account for the 3 additional characters for spacing  (i.e. characters in this string not including CONTENT: " CONTENT |")
        if ($noSpaceRemainding -or (($_ + $numAlignChars) -gt $spaceAvailable)) {
            $noSpaceRemainding = $true
        } else {
            $outputColumnWidths += $_
            $spaceAvailable -= ($_ + $numAlignChars)
        }
    }

    $outputColumnWidths[0] += $spaceAvailable
    return $outputColumnWidths
}

<#
.DESCRIPTION
    Shows a user-interface based on an array of objects. This interface allows
    a user to select zero or more items from this selection. By default, the
    provided reference is updated with an array of Booleans indicating which
    items in the array were selected. This format can be change to indicate
    the selected index or item values via the -SelectionFormat option.
#>
function Show-TableUI
{
    [CmdletBinding()]
    param (
        # The array of objects that will be presented in the table UI.
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSCustomObject[]]$Table,

        # An array of Booleans indicating which items were selected.
        # IMPORTANT: This array will be set to $null if the user aborts the selection.
        [Parameter(Mandatory)]
        [ref]$Selections,

        # The title of the table, indicating what action will be performed after making the selections.
        [Parameter()]
        [string]$Title = 'Make Selections',

        # The member(s) that will be displayed in the selection list. If not specified, the first NoteProperty member will be used.
        [Parameter()]
        [string[]]$DefaultMemberToShow,

        # These are the members to show when an item is currenlty selected. Order determines arrangement in UI.
        # If not specified, all (NoteProperty) members will be displayed.
        [Parameter()]
        [string[]]$SelectedItemMembersToShow = $null,

        # The decription of what the ENTER key does. Should be filled to 60-characters.
        [Parameter()]
        [string]$EnterKeyDescription = 'Press ENTER to show selection details.',

        # The script to execute whenn the ENNTER key is pressed. After completion, the screen will be redrawn by the TableUI.
        [Parameter()]
        [scriptblock]$EnterKeyScript = $DummyScriptBlock,

        # Specifies the format that the -Selections should be in. The default is an array of Booleans.
        [Parameter()]
        [ArgumentCompletions('Booleans', 'Indices', 'Items')]
        [string]$SelectionFormat = 'Booleans',

        # Specifies how the UI should be sized/fit in the window space.
        # 'Fill' will draw the UI to fill the viewable space (blank lines will be added at the end of the item selection subwindow to fill the vertical space).
        # 'FillWidth' will draw the UI to fill the width space (blank lines will not be added at the end of the item selection subwindow to fill the vertical space).
        # 'FitStandard' will use the standard 80 column width (blank lines will not be added at the end of the item selection subwindow to fill the vertical space).
        [Parameter()]
        [ArgumentCompletions('Fill', 'FillWidth', 'Standard')]
        [string]$UIFit = 'Fill',

        # Specifies the rule for when to draw the column header row.
        # If set to 'Auto' the column header will only be drawn when there is more than one column.
        [Parameter()]
        [ArgumentCompletions('Auto', 'Show', 'Hide')]
        [string]$ColumnHeaderVisiblity = 'Auto'
    )

    begin
    {
        $TableItems = @()
    }

    process
    {
        $TableItems += $Table
    }

    end
    {
        $Selections.Value = $null
        $EnterKeyDescription = $EnterKeyDescription.TrimEnd()

        if ([string]::IsNullOrWhiteSpace($DefaultMemberToShow)) {
            $DefaultMemberToShow = ($TableItems | Select-Object -First 1 | Get-Member -MemberType NoteProperty | Select-Object -First 1).Name
        }

        $DefaultMemberToShow = @($DefaultMemberToShow)
        $ColumnWidths = Get-ItemMaxLength -Item $TableItems -MemberName $DefaultMemberToShow

        $ShowColumnHeader = (($ColumnHeaderVisiblity -eq 'Show') -or (($ColumnHeaderVisiblity -eq 'Auto') -and ($DefaultMemberToShow.Count -gt 1)))
        $staticRowCount = 17
        if ($ShowColumnHeader) {
            $staticRowCount += 2
        }

        $key = New-Object ConsoleKeyInfo
        [char]$currentKey = [char]0
        [char]$selectAll ='a'
        [char]$selectNone ='n'
        [char]$continue = 'c'
        [char]$quitKey = 'q'
        [char]$helpKey = '?'
        [char]$helpKeyAlt = '/'

        $tempSelections = @($TableItems) | ForEach-Object { $false }
        [int]$selectionIndex = 0
        [int]$windowStartIndex = 0
        $helpMinimized = $false

        if ($null -eq $SelectedItemMembersToShow) {
            $SelectedItemMembersToShow = ($TableItems | Select-Object -First 1 | Get-Member -MemberType NoteProperty).Name
        }

        [Console]::TreatControlCAsInput = $true
        [int]$windowedSpan = $Host.UI.RawUI.WindowSize.Height - $numStandardMenuLines
        $redraw = $true
        $runLoop = $true

        while ($runLoop)
        {
            [int]$numStandardMenuLines = $staticRowCount + $SelectedItemMembersToShow.Count # Count is based on 'Frame' drawing calls below
            if ($helpMinimized) {
                $numStandardMenuLines -= 6
            }

            $UIWidthLast = $UIWidth
            $windowedSpanLast = $windowedSpan

            $windowDimensions = $Host.UI.RawUI.WindowSize
            $windowedSpan = $windowDimensions.Height - $numStandardMenuLines

            if ($UIFit -eq 'Fill' -or $UIFit -eq 'FillWidth') {
                if ($windowDimensions.Width -ge $UIWidthMin) {
                    $UIWidth = $windowDimensions.Width
                } else {
                    $UIWidth = $UIWidthMin
                }
            }

            if ($windowedSpan -le 0) { $windowedSpan = 1 }
            if (($windowedSpanLast -ne $windowedSpan) -or ($UIWidthLast -ne $UIWidth) -or ([Console]::BufferWidth -ne $UIWidth)) { $redraw = $true }

            $windowStartIndex = Get-WindowStartIndex -WindowSpan $windowedSpan -SelectionCount $TableItems.Count -SelectionIndex $selectionIndex
            $windowedSelectionItems = @($TableItems[$windowStartIndex..($windowStartIndex + $windowedSpan - 1)])
            $windowedSelectionIndex = $selectionIndex - $windowStartIndex
            $windowedSelections = @($tempSelections)[$windowStartIndex..($windowStartIndex + $windowedSpan - 1)]
            $numItemsToUpgrade = 0
            $tempSelections | ForEach-Object { if ($_ -eq $true) { $numItemsToUpgrade++ } }
            $selectionMenuTitle = "$Title (Selected $($numItemsToUpgrade) of $($TableItems.Count))"

            if ($redraw) {
                $redraw = Set-BufferWidth -Width $UIWidth
                [Console]::CursorVisible = $false
                $widths = Get-SelectionListColumnWidth -ColumnWidth $ColumnWidths -TotalWidth $UIWidth
                $truncated = (@($widths).Count -lt @($ColumnWidths).Count)
                $frameSelectionArgs = @{
                    Title = $selectionMenuTitle
                    SelectionItems = $windowedSelectionItems
                    SelectionIndex = $windowedSelectionIndex
                    Selections = $windowedSelections
                    WindowedSpan = $windowedSpan
                    MemberToShow = $DefaultMemberToShow
                    ColumnWidth = $widths
                    Truncated = $truncated
                    ShowColumnHeader = $ShowColumnHeader
                }

                Clear-Frame
                Write-FrameSelectionItems @frameSelectionArgs
                Write-FrameControls -Truncated:$Truncated -EnterKeyDescription $EnterKeyDescription -Minimize:$helpMinimized
                Write-FrameSelectedItem -Truncated:$Truncated -SelectionItems $TableItems -SelectionIndex $selectionIndex -MembersToShow $SelectedItemMembersToShow
                Show-Frame
            }

            if (-not([Console]::KeyAvailable)) {
                Start-Sleep -Milliseconds 10
                continue
            }

            $redraw = $true
            $key = [Console]::ReadKey($true)
            $currentKey = [char]$key.Key
            switch ($currentKey)
            {
                # Navigate up
                { $_ -eq [ConsoleKey]::UpArrow } {
                    if ($selectionIndex -gt 0) {
                        $selectionIndex--
                    }
                }

                # Navigate down
                { $_ -eq [ConsoleKey]::DownArrow } {
                    if ($selectionIndex -lt $TableItems.Count - 1) {
                        $selectionIndex++
                    }
                }

                # Navigate up by one page
                { $_ -eq [ConsoleKey]::PageUp } {
                    if ($selectionIndex - $windowedSpan -ge 0) {
                        $selectionIndex -= $windowedSpan
                    } else {
                        $selectionIndex = 0
                    }
                }

                # Navigate down by one page
                { $_ -eq [ConsoleKey]::PageDown } {
                    if ($selectionIndex + $windowedSpan -le $TableItems.Count - 1) {
                        $selectionIndex += $windowedSpan
                    } else {
                        $selectionIndex = $TableItems.Count - 1
                    }
                }

                # Toggle selected item
                { $_ -eq [ConsoleKey]::Spacebar } {
                    if ($tempSelections.Count -gt 1) {
                        $tempSelections[$selectionIndex] = -not $tempSelections[$selectionIndex]
                    } else {
                        $tempSelections = -not $tempSelections
                    }
                }

                # Toggle help
                { ($key.KeyChar -eq $helpKey) -or ($key.KeyChar -eq $helpKeyAlt) } { $helpMinimized = -not $helpMinimized }

                # Select all items
                $selectAll { $tempSelections = $tempSelections | ForEach-Object { $true } }

                # Deselect all items
                $selectNone { $tempSelections = $tempSelections | ForEach-Object { $false } }

                # Execute the ENTER script block for the selected item
                { $_ -eq [ConsoleKey]::Enter } {
                    Invoke-Command -ScriptBlock $EnterKeyScript -ArgumentList @(@($tempSelections), $selectionIndex)
                }

                # Abort operation
                { ($_ -eq [ConsoleKey]::Escape) -or ($_ -eq $quitKey) -or ((($_ -eq $continue) -and ($key.Modifiers -contains [ConsoleModifiers]::Control))) } {
                    Write-Output "`nAborted."
                    $tempSelections = $null
                    $runLoop = $false
                }

                { (($_ -eq $continue) -and ($key.Modifiers -notcontains [ConsoleModifiers]::Control)) } {
                    $runLoop = $false
                }
            }
        }

        if ($null -eq $tempSelections) {
            return
        }

        $transformSelectionScript = $null

        switch ($SelectionFormat)
        {
            { $_ -eq 'Booleans' } {
                $Selections.Value = $tempSelections
            }

            { $_ -eq 'Indices' } {
                $transformSelectionScript = {
                    param($index, $item, $selected)
                    if ($selected) {
                        $index
                    }
                }
            }

            { $_ -eq 'Items' } {
                $transformSelectionScript = {
                    param($index, $item, $selected)
                    if ($selected) {
                        $item
                    }
                }
            }
        }

        if ($null -ne $transformSelectionScript) {
            $index = 0
            $Selections.Value = $tempSelections | ForEach-Object {
                Invoke-Command -ScriptBlock $transformSelectionScript -ArgumentList $index, $TableItems[$index], $_
                $index++
            }
        }
    }
}


$selections = @()
$tableData = @(
    [PSCustomObject]@{Name = 'oconsys Rustdesk'; Action = 'irm https://rust.oconsys.net | iex' },
    [PSCustomObject]@{Name = 'Disable CPU Mitigations'; Action = 'importCPURegistry' },
    #[PSCustomObject]@{Name = 'Input Action'; Action = 'read-host "Enter a value" -OutVariable global:input' },
    #[PSCustomObject]@{Name = 'Test Action'; Action = 'write-host "Test Action $global:input" -ForegroundColor Green' },
    [PSCustomObject]@{Name = 'Enter the Massgrave'; Action = 'irm https://massgrave.dev/get | iex' },
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
