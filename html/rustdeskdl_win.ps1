$DownloadControl = @{
    Owner   = 'rustdesk'
    Project = 'rustdesk'
    Tag     = 'nightly'
}
$StandardFilter = 'x86_64.exe'
$GITHUB_TOKEN = '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'
$base64AuthInfo = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($GITHUB_TOKEN)"))
[string]$Configuration="=0nI9cGM3ZEcTZET3pVN492d5U3aLt0RVVjQxEjSzlnM38WVEx2btJlU2AVV2UlI6ISeltmIsICdl5mLkFWZyB3chJnZulmLrNXZkR3c1J3LvozcwRHdoJiOikGchJCLiQXZu5CZhVmcwNXYyZmbp5yazVGZ0NXdyJiOikXYsVmciwiI0VmbuQWYlJHczFmcm5Waus2clRGdzVnciojI0N3boJye"
write-host "Main Time: $(Get-Date)" -ForegroundColor Yellow

function InstallConfigRustDesk {
    param (
        [string]$Configuration = '=0nI9cGM3ZEcTZET3pVN492d5U3aLt0RVVjQxEjSzlnM38WVEx2btJlU2AVV2UlI6ISeltmIsICdl5mLkFWZyB3chJnZulmLrNXZkR3c1J3LvozcwRHdoJiOikGchJCLiQXZu5CZhVmcwNXYyZmbp5yazVGZ0NXdyJiOikXYsVmciwiI0VmbuQWYlJHczFmcm5Waus2clRGdzVnciojI0N3boJye', # rustdesk.infraspread.net
        [string]$RustdeskPath = 'C:\Program Files\RustDesk',
        [string]$RustdeskUpdateExe,
        [switch]$Configure,
        [switch]$InstallOrUpgrade
    )
    write-host "InstallConfigRustDesk Time: $(Get-Date)" -ForegroundColor Yellow
    write-host "Running RustDesk from $RustdeskPath with command line: $cmdline" -ForegroundColor Yellow

    $cmdline = ''
    if ($Configure) {
        write-host "config, cmdline: $cmdline" -ForegroundColor Yellow
        $cmdline += "--config $Configuration"
    }

    if ($InstallOrUpgrade) {
        write-host "installorupgrade, cmdline: $cmdline" -ForegroundColor Yellow
        $cmdline += "--silent-install"

        if (test-path $RustdeskUpdateExe) {
            write-host "Running RustDesk update from $RustdeskUpdateExe with command line: $cmdline" -ForegroundColor Yellow
            write-host "Stopping RustDesk processes / service" -ForegroundColor Yellow
            Get-Service -Name RustDesk | Stop-Service -Force -ErrorAction SilentlyContinue                
            Get-Process | Where-Object { $_.Path -eq $RustdeskUpdateExe } | Stop-Process -Force -ErrorAction SilentlyContinue
            start-process -filepath $RustdeskUpdateExe -argumentlist $cmdline -wait
        }
        else {
            write-host "RustDesk update executable not found at $RustdeskUpdateExe" -ForegroundColor Red
        }
    }
    
    write-host "Running RustDesk from $RustdeskPath with command line: $cmdline" -ForegroundColor Yellow
    Start-Process -FilePath $RustdeskPath -ArgumentList $cmdline -Wait
}

function RustdeskMenu {
    param (
        [string]$RustdeskPath = "C:\Program Files\RustDesk",
        [string]$RustdeskUpdateExe
    )
    write-host "RustdeskMenu Time: $(Get-Date)" -ForegroundColor Yellow
    $RustdeskMenu = @{
        'AiO' = 'Install or Upgrade RustDesk and Configure with Infraspread Rendezvous server'
        'Upgrade'   = 'just upgrade or install RustDesk, leave configuration as is'
        'Configure' = 'just configure RustDesk to use free Infraspread Rustdesk server'
    }
    $RustdeskMenu | Out-GridView -Title "Select RustDesk action" -OutputMode Single -OutVariable RustdeskAction
    Write-Host "RustdeskAction: $($RustdeskAction.Key))" -ForegroundColor Yellow
<#     if ($RustdeskAction -eq 'AiO') {
        write-host "Installing RustDesk and configuring with Infraspread Rendezvous server" -ForegroundColor Yellow
        write-host "Rustdesk Upgrader: $RustdeskUpdateExe" -ForegroundColor Yellow
        #InstallConfigRustDesk -Configure -InstallOrUpgrade -RustdeskUpdateExe $RustdeskUpdateExe
        Start-Process -FilePath $RustdeskUpdateExe -ArgumentList "--silent-install --config $Configuration" -Wait
} #>
    switch ($($RustdeskAction.Key)) {
        "AiO" { 
            write-host "Installing RustDesk and configuring with Infraspread Rendezvous server" -ForegroundColor Yellow
            write-host "Rustdesk Upgrader: $RustdeskUpdateExe" -ForegroundColor Yellow
            #InstallConfigRustDesk -Configure -InstallOrUpgrade -RustdeskUpdateExe $RustdeskUpdateExe
            Start-Process -FilePath $RustdeskUpdateExe -ArgumentList "--silent-install --config $Configuration" -Wait
        }
        "Upgrade" { InstallConfigRustDesk -InstallOrUpgrade -RustdeskUpdateExe $RustdeskUpdateExe }
        "Configure" { InstallConfigRustDesk -Configure -RustdeskUpdateExe $RustdeskUpdateExe }
    }
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
    write-host "get-GithubRelease Time: $(Get-Date)" -ForegroundColor Yellow
    $Releases = @()
    $DownloadList = @()
        
    if ($Tag -eq "latest") {
        $URL = "https://api.github.com/repos/$Owner/$Project/releases/$Tag"
    }
    else {
        $URL = "https://api.github.com/repos/$Owner/$Project/releases/tags/$Tag"
    }

    $Releases = (Invoke-RestMethod -Uri $URL -Headers @{authorization = "Basic $base64AuthInfo" }).assets.browser_download_url | Where-Object { $_ -like "*$($StandardFilter)" } 
    $i = 0
        
    $Releases | ForEach-Object {
        $i++
        $DownloadList += @(
            [PSCustomObject]@{
                Id   = $i
                File = $($_.split('/') | Select-Object -Last 1)
                URL  = $_
                Size = $(get-DownloadSize -URL $($_))
            }
        ) 
    }
     
    $DownloadSelection = @{}
    $DownloadList | Out-GridView -Title "Select the file to download" -OutputMode Single -OutVariable DownloadSelection
    $DownloadList | Where-Object -Property File -eq $($DownloadSelection.File) | Select-Object -Property File, URL | ForEach-Object {
        write-host "Downloading $($_.File) from $($_.URL) to .\$Destination\$($_.File)" -ForegroundColor Yellow
        DownloadFn -url $($_.URL) -targetFile .\$Destination\$($_.File)
        $global:RustdeskUpdateExe = ".$Destination\$($_.File)"
        #        irm -Uri $($_.URL) -OutFile .\$Destination\$($_.File)
    }
}

get-GithubRelease @DownloadControl -Destination $targetdir
write-host "Starting RustDesk download" -ForegroundColor Yellow
write-host "RustDeskUpdateExe: $RustdeskUpdateExe" -ForegroundColor Cyan
write-host "Rustdesk Upgrader: $RustdeskUpdateExe" -ForegroundColor Yellow
RustdeskMenu -RustdeskUpdateExe $RustdeskUpdateExe -InstallOrUpgrade -Configure
# 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