Function Get-DropboxFolderZip {
    [cmdletbinding()]
    Param(
        [Parameter(
            ParameterSetName = 'ByPath'
        )]
        [string]$Path,
        [Parameter(
            ParameterSetName = 'ById'
        )]
        [string]$Id,
        [string]$Destination
    )
    $resource = 'files/download_zip'

    Switch($PSCmdlet.ParameterSetName){
        'ByPath' {$data = $Path}
        'ById' {$data = $Id}
    }

    $header = @{
        'Dropbox-API-Arg' = @{
            path = $data
        } | ConvertTo-Json -Compress
    }

    If(Test-Path $Destination -PathType Leaf){
        Invoke-DropboxAPICall -Resource $resource -Method Post -Header $header -subDomain content -ContentType 'application/octet-stream' -FilePath $Destination
    }Else{
        If($PSCmdlet.ParameterSetName -eq 'ByPath'){
            $item = Split-Path $Path -Leaf
        }ElseIf($PSCmdlet.ParameterSetName -eq 'ById'){
            $item = (Get-DropboxItemMetadata -Id $Id).Name
        }
        Invoke-DropboxAPICall -Resource $resource -Method Post -Header $header -subDomain content -ContentType 'application/octet-stream' -FilePath "$Destination\$item.zip"
    }
}