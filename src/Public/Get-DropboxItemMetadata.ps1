Function Get-DropboxItemMetadata {
    [cmdletbinding()]
    Param(
        [Parameter(
            ParameterSetName = 'ByPath'
        )]
        [string]$Path,
        [Parameter(
            ParameterSetName = 'ById'
        )]
        [string]$Id
    )
    $Resource = 'files/get_metadata'
    Switch($PSCmdlet.ParameterSetName){
        'ByPath' {$data = $path}
        'ById' {$data = $Id}
    }
    $Body = @{
        path = $data
    } | ConvertTo-Json
    Invoke-DropboxAPICall -Method Post -Resource $Resource -Body $body
}