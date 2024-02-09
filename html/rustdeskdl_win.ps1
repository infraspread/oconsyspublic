function ModulePrerequisites {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'List of modules to install')]
        [Alias('Module', 'Modules', 'ModuleName', 'ModuleNames')]
        [string[]]$Name,
        [switch]$AllUsers,
        [switch]$Force,
        [switch]$install,
        [switch]$update
    )
    $ModulesListStart = @()
    # region Parameter Validation
    if ($null -eq $Name -and $null -eq $Modules) {
        Write-Error "Either the Name or ModulesList parameter is required"
        exit
    }
    if ($Name -and $Modules) {
        Write-Information "Both Name and ModulesList parameters are provided, combining them"
        if ($Name -notin $Modules) {
            $Modules += $Name
        }
    }
    if (!$Modules) {
        $Modules = @($Name)
    }
    # endregion

    # region ModulesListStart
      $Modules | ForEach-Object {
        $ModulesListStart += @(
            [PSCustomObject]@{
                Name        = $_
                Installed   = $null -ne (Get-Module -Name $_ -ListAvailable -ErrorAction SilentlyContinue)
                Installable = $null -ne ($Repository = Find-Module -Name $_ -ErrorAction SilentlyContinue)
                Repository  = if ($Repository.RepositorySourceLocation) { $Repository.RepositorySourceLocation } else { $null }
            }
        ) 
    }
    # endregion
    write-verbose "$($ModulesListStart | Format-Table -AutoSize)"
    # region Install Parameters
    $params = @{}
    if ($allusers) {
        # check if current user is in SID of Administrators, 'S-1-5-32-544', if not, give notice do a current user install instead
        if (([System.Security.Principal.WindowsIdentity]::GetCurrent()).Groups -contains 'S-1-5-32-544') {
            $params.Scope = 'AllUsers'
            if ($force) {
                $params.Force = $true
            }
        }
        else {
            Write-Warning "You need to run this script as an administrator to install modules for all users."
            Write-Warning "Switching to current user install"
            $params.Scope = 'CurrentUser'
        }
    }
    if (!($install)) {
        write-Verbose "Running in dry-run mode, just checking your modules and their availability"
        Write-Verbose "To install the modules, run the script with the -install switch"
    }
    if ($update) {
        $params.Update = $true
    }
    # endregion

    # endregion
    try {
        $ModulesList | Where-Object { ($_.Installed -eq $false) -and ($_.Installable -eq $true) } | ForEach-Object {
            Write-Host "Trying to install Module $($_.Name)"
            $params.Name = $_.Name
            Install-Module @params
        }
    }
    catch {
        Write-Error $_
    }
    finally {        
        $Modules | ForEach-Object {
            $ModulesListEnd += @(
                [PSCustomObject]@{
                    Name        = $_
                    Installed   = $null -ne (Get-Module -Name $_ -ListAvailable -ErrorAction SilentlyContinue)
                    Installable = $null -ne ($Repository = Find-Module -Name $_ -ErrorAction SilentlyContinue)
                    Repository  = if ($Repository.RepositorySourceLocation) { $Repository.RepositorySourceLocation } else { $null }
                }
            )
        }
        $ModulesListCompare = Compare-Object -ReferenceObject $ModulesListStart -DifferenceObject $ModulesListEnd -Property Name -PassThru
        if ($ModulesListCompare) {
            Write-Host "Modules that were installed or updated"
            $ModulesListCompare | Format-Table -AutoSize
        }
        else {
            Write-Verbose "No modules were installed or updated"
        }
    }
}

function DownloadGithubRelease($url, $targetFile) {

    $uri = New-Object "System.Uri" "$url"
    $request = [System.Net.HttpWebRequest]::Create($uri)
    $request.set_Timeout(15000) #15 second timeout
    $response = $request.GetResponse()
    $totalLength = [System.Math]::Floor($response.get_ContentLength() / 1024)
    $responseStream = $response.GetResponseStream()
    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
    $buffer = new-object byte[] 10KB
    $count = $responseStream.Read($buffer, 0, $buffer.length)
    $downloadedBytes = $count
    while ($count -gt 0) {
        $targetStream.Write($buffer, 0, $count)
        $count = $responseStream.Read($buffer, 0, $buffer.length)
        $downloadedBytes = $downloadedBytes + $count
        Write-Progress -activity "Downloading file '$($url.split('/') | Select-Object -Last 1)'" -status "Downloaded ($([System.Math]::Floor($downloadedBytes/1024))K of $($totalLength)K): " -PercentComplete ((([System.Math]::Floor($downloadedBytes / 1024)) / $totalLength) * 100)
    }
    Write-Progress -activity "Finished downloading file '$($url.split('/') | Select-Object -Last 1)'"
    $targetStream.Flush()
    $targetStream.Close()
    $targetStream.Dispose()
    $responseStream.Dispose()
}

function get-GithubRelease {
    param(
        [Parameter(Mandatory = $true, HelpMessage = 'Github Repo Owner')]
        [string]$Owner,
        [Parameter(Mandatory = $true, HelpMessage = 'Github Repo Project Name to')]
        [string]$Project,
        [Parameter(HelpMessage = 'Github Repo Tag to download, defaults to latest')]
        [string]$Tag = "latest",
        [Parameter(HelpMessage = 'Path to download to, defaults to current directory')]
        [string]$Destination = $PWD,
        [Parameter(HelpMessage = 'No filter')]
        [switch]$NoFilter,
        [Parameter(HelpMessage = 'no GUI')]
        [switch]$NoGui
    )
    $Releases = @()
    $DownloadList = @()
    
    if ($Tag -eq "latest") {
        $URL = "https://api.github.com/repos/$Owner/$Project/releases/$Tag"
    }
    else {
        $URL = "https://api.github.com/repos/$Owner/$Project/releases/tags/$Tag"
    }

    $Releases = (Invoke-RestMethod $URL).assets.browser_download_url

    $i = 0
    
    $Releases | ForEach-Object {
        $i++
        $DownloadList += @(
            [PSCustomObject]@{
                Id   = $i
                File = $($_.split('/') | Select-Object -Last 1)
                URL  = $_
            }
        ) 
    }
 
 $DownloadSelection = @{}
 $DownloadList.File | Out-GridView -Title "Select the file to download" -OutputMode Single -OutVariable DownloadSelection
    
}
$DownloadList 
| Where-Object -Property File -eq $DownloadSelection
| Select-Object -Property File, URL | ForEach-Object {
    Write-host "Downloading $($_.File) from $($_.URL) to $Destination\$($_.File)"
    DownloadGithubRelease -url $($_.URL) -targetFile $Destination\$($_.File)
}

get-GithubRelease -Owner 'rustdesk' -Project 'rustdesk' -Tag 'nightly' -Destination $PWD
