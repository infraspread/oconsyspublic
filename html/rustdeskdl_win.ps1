$DownloadControl = @{
    Owner   = 'rustdesk'
    Project = 'rustdesk'
    Tag     = 'nightly'
    }
$StandardFilter = '64.exe' # '64.deb'

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
    $Releases = @()
    $DownloadList = @()
        
    if ($Tag -eq "latest") {
        $URL = "https://api.github.com/repos/$Owner/$Project/releases/$Tag"
    }
    else {
        $URL = "https://api.github.com/repos/$Owner/$Project/releases/tags/$Tag"
    }
    
    $Releases = (Invoke-RestMethod $URL).assets.browser_download_url | Where-Object {$_ -like "*$StandardFilter"} 
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
    
    $DownloadList 
    | Where-Object -Property File -eq $DownloadSelection
    | Select-Object -Property File, URL | ForEach-Object {
        DownloadFn -url $($_.URL) -targetFile $Destination\$($_.File)
    }
}
    
get-GithubRelease @DownloadControl -Destination $PWD