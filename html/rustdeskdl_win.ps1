$DownloadControl = @{
    Owner   = 'rustdesk'
    Project = 'rustdesk'
    Tag     = 'nightly'
}
$StandardFilter = 'x86_64.exe'
write-host "My Command TopPath: $PSCommandPath"
$ScriptPath = $($PSCommandPath)

$global:RustdeskConfig = @'
rendezvous_server = 'rustdesk.infraspread.net:21116'
nat_type = 1
serial = 0

[options]
api-server = 'https://rustdesk.infraspread.net'
custom-rendezvous-server = 'rustdesk.infraspread.net'
relay-server = 'rustdesk.infraspread.net'
direct-server = 'Y'
enable-audio = 'N'
key = 'U6UP6RRmolDUo72ysJ11B5UGKKku9wox5ZwLFSpFw0g='
allow-remove-wallpaper = 'Y'
stop-service = 'N'
'@

$global:RustdeskDefault = @'
[options]
disable_audio = 'Y'
show_remote_cursor = 'Y'
collapse_toolbar = 'Y'
view_style = 'adaptive'
image_quality = 'low'
enable_file_transfer = 'Y'
'@

Function test-RunAsAdministrator() {
    <#
    #Get current user context
    $CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
  
    #Check user is running the script is member of Administrator Group
    if ($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        Write-host "Script is running with Administrator privileges!"
    }
    else {
        #Create a new Elevated process to Start PowerShell
        $ElevatedProcess = New-Object System.Diagnostics.ProcessStartInfo "pwsh";
        # Specify the current script path and name as a parameter
        #write-host "& '" + $script:MyInvocation.MyCommand.Path + "'"
        write-host "& '" + $PSCommandPath + "'"
        
        $ElevatedProcess.Arguments = "& '" + $PSScriptRoot + "'"
        #Set the Process to elevated
        $ElevatedProcess.Verb = "runas"
        #Start the new elevated process
        [System.Diagnostics.Process]::Start($ElevatedProcess)
        #Exit from the current, unelevated, process
        Exit
    }
#>
    write-host "My Command 666Path: $PSCommandPath"
    $ScriptPath = $($PSCommandPath)
    pause
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        # Relaunch as an elevated process:
        Start-Process pwsh.exe "-File", ('"{0}"' -f $ScriptPath) -Verb RunAs
        exit
    }
}
    
write-host "Main Time: $(Get-Date)" -ForegroundColor Yellow

function RustdeskWaitService {
    $global:ServiceName = 'Rustdesk'
    $global:arrService = Get-Service -Name $($global:ServiceName) -ErrorAction SilentlyContinue
    if ($null -eq $($global:arrService)) {
        Set-Location $env:ProgramFiles\RustDesk
        Start-Process .\rustdesk.exe --install-service
        Start-Sleep -seconds 20
    }
    while ($($global:arrService).Status -ne 'Running') {
        Start-Service $ServiceName -ErrorAction SilentlyContinue
        Start-Sleep -seconds 8
        $global:arrService.Refresh()
    }
}

function RustdeskMenu {
    param (
        [string]$RustdeskPath = "C:\Program Files\RustDesk",
        [string]$RustdeskUpdateExe
    )
    write-host "RustdeskMenu Time: $(Get-Date)" -ForegroundColor Yellow

    $RustdeskMenu = @{
        'AiO'        = 'Install or Upgrade RustDesk and Configure with Infraspread Rendezvous server'
        'Upgrade'    = 'just upgrade or install RustDesk, leave configuration as is'
        'Configure'  = 'just configure RustDesk to use free Infraspread Rustdesk server'
        'Chocolatey' = 'Install Chocolatey'
    }
    $RustdeskMenu | Out-GridView -Title "Select RustDesk action" -OutputMode Single -OutVariable RustdeskAction
    Write-Host "RustdeskAction: $($RustdeskAction.Key)" -ForegroundColor Yellow
    switch ($($RustdeskAction.Key)) {
        "AiO" {
            write-host "Installing RustDesk and configuring with Infraspread Rendezvous server" -ForegroundColor Yellow
            Get-Service -Name RustDesk | Stop-Service -ErrorAction SilentlyContinue
            Start-Process -FilePath $RustdeskUpdateExe -ArgumentList "--silent-install"
            $global:RustdeskConfig | Out-File -FilePath "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml" -ErrorAction SilentlyContinue -Force
            $global:RustdeskConfig | Out-File -FilePath "$env:USERPROFILE\AppData\Roaming\RustDesk\config\RustDesk2.toml" -ErrorAction SilentlyContinue -Force
            $global:RustdeskDefault | Out-File -FilePath "$env:USERPROFILE\AppData\Roaming\RustDesk\config\RustDesk_default.toml" -ErrorAction SilentlyContinue -Force
            RustdeskWaitService
        }
        "Upgrade" {
            write-host "Upgrading RustDesk" -ForegroundColor Yellow
            Get-Service -Name RustDesk | Stop-Service -ErrorAction SilentlyContinue
            Start-Process -FilePath $RustdeskUpdateExe -ArgumentList "--silent-install"
            Get-Service -Name RustDesk | Start-Service -ErrorAction SilentlyContinue
        }
        "Configure" { 
            Get-Service -Name RustDesk | Stop-Service -Force -ErrorAction SilentlyContinue
            $RustdeskConfig | Out-File -FilePath "$env:USERPROFILE\AppData\Roaming\RustDesk\config\RustDesk2.toml" -ErrorAction SilentlyContinue
            $RustdeskDefault | Out-File -FilePath "$env:USERPROFILE\AppData\Roaming\RustDesk\config\RustDesk_default.toml" -ErrorAction SilentlyContinue -Force
            $RustdeskConfig | Out-File -FilePath "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml" -ErrorAction SilentlyContinue
            Get-Service -Name RustDesk | Start-Service -ErrorAction SilentlyContinue
        }
        "Chocolatey" {
            write-host "Install Chocolatey" -ForegroundColor Yellow
            Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
    }
    Set-Location $env:ProgramFiles\RustDesk
    .\rustdesk.exe --get-id | Write-Output -OutVariable RustdeskID
    write-host "Successfully Installed Rustdesk, your ID is $RustdeskID" -ForegroundColor Green
}

function DownloadLegacy {
    param (
        [string]$url,
        [string]$targetFile
    )
    write-host "DownloadLegacy Time: $(Get-Date)" -ForegroundColor Yellow
    write-host "Legacy Downloading: $url to $targetFile" -foregroundcolor Green
    Invoke-WebRequest -Uri  $url -OutFile $targetFile
    return $targetFile
}

function get-DownloadSize {
    param (
        [string]$URL
    )
    $DownloadSizeByte = [int]::Parse(((Invoke-WebRequest $URL -Method Head).Headers.'Content-Length'))
    $DownloadSizeMB = [math]::Round($DownloadSizeByte / 1MB, 2)
    write-host "URL: $URL Size: $DownloadSizeMB MB" -foregroundcolor yellow
    return $DownloadSizeMB
}
    
function DownloadFn($url, $targetFile) {
    write-host "DownloadFn Time: $(Get-Date)" -ForegroundColor Yellow
    write-host "Downloading: $url" -foregroundcolor yellow
    write-host "To: $targetFile" -foregroundcolor cyan
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
    Set-Location ~
    write-host "get-GithubRelease Time: $(Get-Date)" -ForegroundColor Yellow
    $Releases = @()
    $DownloadList = @()
        
    if ($Tag -eq "latest") {
        $URL = "https://api.github.com/repos/$Owner/$Project/releases/$Tag"
    }
    else {
        $URL = "https://api.github.com/repos/$Owner/$Project/releases/tags/$Tag"
    }
    $GITHUB_TOKEN = "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"
    $base64AuthInfo = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($GITHUB_TOKEN)"))
    
    #$Releases = (Invoke-RestMethod -Uri $URL -Headers @{authorization = "Basic $base64AuthInfo" }).assets.browser_download_url | Where-Object { $_ -like "*$($StandardFilter)" } 
    $Releases = (Invoke-RestMethod -Uri $URL).assets.browser_download_url | Where-Object { $_ -like "*$($StandardFilter)" }
    $i = 0
        
    $Releases | ForEach-Object {
        $i++
        $DownloadList += @(
            [PSCustomObject]@{
                Id   = $i
                File = ($Filepart=$($_.split('/') | Select-Object -Last 1))
                URL  = $_
                Destination = "$($PWD)\$($Filepart)"
                Size = $(get-DownloadSize -URL $($_))
            }
        ) 
    }
     
    $DownloadSelection = @{}
    $DownloadList | Out-GridView -Title "Select the file to download" -OutputMode Single -OutVariable DownloadSelection
    $DownloadList | Where-Object -Property File -eq $($DownloadSelection.File) | Select-Object -Property File, URL, Destination | ForEach-Object {
        #write-host "Downloading $($_.File) from $($_.URL) to .\$Destination\$($_.File)" -ForegroundColor Yellow
        write-host "Downloading $($_.File) from $($_.URL) to $($_.Destination)" -ForegroundColor Yellow
        DownloadLegacy -url $($_.URL) -targetFile $($_.Destination)
        $global:RustdeskUpdateExe = $($_.Destination)
        #        irm -Uri $($_.URL) -OutFile .\$Destination\$($_.File)
    }
}

Set-Location ~
#Check Script is running with Elevated Privileges
test-RunAsAdministrator

get-GithubRelease @DownloadControl -Destination $targetdir
RustdeskMenu -RustdeskUpdateExe $RustdeskUpdateExe -InstallOrUpgrade -Configure
