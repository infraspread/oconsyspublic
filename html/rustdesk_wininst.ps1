$DownloadControl = @{
    Owner   = 'rustdesk'
    Project = 'rustdesk'
    Tag     = 'nightly'
}

$StandardFilter = 'x86_64.exe'
$ScriptPath = $($PSCommandPath)
$CurDir=$(get-location)

$string="{\"host\":\"${wanip}\",\"key\":\"${keyreg}\",\"api\":\"https://${wanip}\"}"
$string64=$(echo -n "$string" | base64 -w 0 | tr -d '=')
$RUSTDESK_CONFIG=$(echo -n "$string64" | rev)
write-host $RUSTDESK_CONFIG

$global:RustdeskConfig = @'
rendezvous_server = 'wanipreg:21116'
nat_type = 1
serial = 0

[options]
api-server = "https://wanipreg"
custom-rendezvous-server = "wanipreg"
relay-server = "wanipreg"
direct-server = 'Y'
enable-audio = 'N'
key = "keyreg"
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
    $ScriptPath = $($PSCommandPath)
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        # Relaunch as an elevated process:
        Start-Process pwsh.exe "-File", ('"{0}"' -f $ScriptPath) -Verb RunAs
        exit
    }
}
    
function RustdeskWaitService {
    Do {
        $RustdeskInstalled = Test-Path "C:\Program Files\RustDesk\rustdesk.exe"
        Start-Sleep 1
    } Until ($RustdeskInstalled)
    
    
    if ($null -eq $(Get-Service -Name "Rustdesk" -ErrorAction SilentlyContinue)) {
        Write-Host "service not installed"
        Start-Process -FilePath "$env:ProgramFiles\RustDesk\rustdesk.exe" -ArgumentList "--install-service" -Verb RunAs -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 6
    }
    Start-Sleep -Seconds 6
    if ($(Get-Service -Name "Rustdesk" -ErrorAction SilentlyContinue).Status -ne 'Running') {
        Write-Host "service not running"
        Start-Service RustDesk -ErrorAction SilentlyContinue
    }
    return
}

function DownloadLegacy {
    param (
        [string]$url,
        [string]$targetFile
    )
    Write-Verbose "Legacy Downloading: $url to $targetFile"
    $progressPreference = 'silentlyContinue'
    Invoke-WebRequest -Uri $url -OutFile $targetFile
    $progressPreference = 'Continue'
    return $targetFile
}

function get-DownloadSize {
    param (
        [string]$URL
    )
    $DownloadSizeByte = [int]::Parse(((Invoke-WebRequest $URL -Method Head).Headers.'Content-Length'))
    $DownloadSizeMB = [math]::Round($DownloadSizeByte / 1MB, 2)
    Write-Verbose "URL: $URL Size: $DownloadSizeMB MB"
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
    Write-Verbose "get-GithubRelease Time: $(Get-Date)"
    $Releases = @()
    $DownloadList = @()
        
    if ($Tag -eq "latest") {
        $URL = "https://api.github.com/repos/$Owner/$Project/releases/$Tag"
    }
    else {
        $URL = "https://api.github.com/repos/$Owner/$Project/releases/tags/$Tag"
    }
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
     
    
    $DownloadList | Out-GridView -Title "Select file to download" -OutputMode Single -OutVariable DownloadSelection
    if ($null -eq $DownloadSelection) {
        Write-Host "No file selected, exiting" -ForegroundColor Red
        exit
    }
    $DownloadList | Where-Object -Property File -eq $($DownloadSelection.File) | Select-Object -Property File, URL, Destination | ForEach-Object {
        Write-Verbose "Downloading $($_.File) from $($_.URL) to $($_.Destination)"
        DownloadLegacy -url $($_.URL) -targetFile $($_.Destination)
        $global:RustdeskUpdateExe = $($_.Destination)
    }
}

function RustdeskMenu {
    param (
        [string]$RustdeskPath = "C:\Program Files\RustDesk"
    )

    $RustdeskMenu = @{
        'AiO'        = 'Install or Upgrade RustDesk and Configure with your Rendezvous server'
        'Upgrade'    = 'upgrade or install RustDesk, leave configuration as is'
        'Configure'  = 'only configure installed RustDesk to use your own Rustdesk server'
        'Chocolatey' = 'Install Chocolatey'
    }
    $RustdeskMenu | Out-GridView -Title "Select RustDesk action" -OutputMode Single -OutVariable RustdeskAction
    Write-Verbose "RustdeskAction: $($RustdeskAction.Key)"
        "AiO" {
            Write-Verbose "Installing RustDesk and configuring with your Rendezvous server"
            get-GithubRelease @DownloadControl -Destination $targetdir
            Get-Service -Name RustDesk -ErrorAction SilentlyContinue | Stop-Service -ErrorAction SilentlyContinue -Force
            Start-Process -FilePath $global:RustdeskUpdateExe -ArgumentList "--silent-install" -Verb RunAs
            #$global:RustdeskConfig | Out-File -FilePath "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml" -ErrorAction SilentlyContinue -Force
            #$global:RustdeskConfig | Out-File -FilePath "$env:USERPROFILE\AppData\Roaming\RustDesk\config\RustDesk2.toml" -ErrorAction SilentlyContinue -Force
            #$global:RustdeskDefault | Out-File -FilePath "$env:USERPROFILE\AppData\Roaming\RustDesk\config\RustDesk_default.toml" -ErrorAction SilentlyContinue -Force
            RustdeskWaitService
            Set-Location $env:ProgramFiles\RustDesk
            #Get-Process -Name "Rust*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Process -WorkingDirectory "$env:ProgramFiles\RustDesk\" -FilePath "$env:ProgramFiles\RustDesk\rustdesk.exe" -ArgumentList "--config $RUSTDESK_CONFIG" -Verb RunAs -ErrorAction SilentlyContinue
            
            .\rustdesk.exe --get-id | Write-Output -OutVariable RustdeskID
            $rustdeskResult = "Successfully Installed Rustdesk, your ID is $RustdeskID"
            write-host $rustdeskResult -ForegroundColor Green
            
        }
        "Upgrade" {
            Write-Verbose "Upgrading RustDesk"
            get-GithubRelease @DownloadControl -Destination $targetdir
            Get-Service -Name RustDesk | Stop-Service -ErrorAction SilentlyContinue
            Start-Process -FilePath $global:RustdeskUpdateExe -ArgumentList "--silent-install" -Verb RunAs
            Get-Service -Name RustDesk | Start-Service -ErrorAction SilentlyContinue
        }
        "Configure" {
            Get-Service -Name RustDesk -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
            Get-Process -Name "Rust*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Process -FilePath "$env:ProgramFiles\RustDesk\rustdesk.exe" -ArgumentList "--config $RUSTDESK_CONFIG" -Verb RunAs -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
            Get-Service -Name RustDesk -ErrorAction SilentlyContinue | Start-Service -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
            Start-Process -FilePath "$env:ProgramFiles\RustDesk\rustdesk.exe" -WorkingDirectory "$env:ProgramFiles\RustDesk\"
        }
        "Chocolatey" {
            Write-Verbose "Install Chocolatey"
            Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
    }
}

Set-Location ~
RustdeskMenu
cd $CurDir
