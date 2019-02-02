Function Get-DropboxFile {
    Param (
        [string]$Path
    )
    $resource = 'files/download'

    $header = @{
        'Dropbox-API-Arg' = @{
            path = $Path
        } | ConvertTo-Json -Compress
    }

    Invoke-DropboxAPICall -Resource $resource -Method Post -Header $header -subDomain content -ContentType 'application/octet-stream'
}