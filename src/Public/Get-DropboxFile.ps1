Function Get-DropboxFile {
    [cmdletbinding(
        DefaultParameterSetName = 'ByPath'
    )]
    Param (
        [Parameter(
            ParameterSetName = 'ByPath'
        )]
        [string]$Path,
        [Parameter(
            ParameterSetName = 'ById',
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$Id,
        [string]$Destination
    )
    Begin{
        $resource = 'files/download'
    }
    Process{
        If($PSCmdlet.ParameterSetName -eq 'ByPath'){
            $header = @{
                'Dropbox-API-Arg' = @{
                    path = $Path
                } | ConvertTo-Json -Compress
            }
        }ElseIf($PSCmdlet.ParameterSetName -eq 'ById'){
            $header = @{
                'Dropbox-API-Arg' = @{
                    path = $Id
                } | ConvertTo-Json -Compress
            }
        }

        If(Test-Path $Destination -PathType Leaf){
            Invoke-DropboxAPICall -Resource $resource -Method Post -Header $header -subDomain content -ContentType 'application/octet-stream' -FilePath $Destination
        }Else{
            If($PSCmdlet.ParameterSetName -eq 'ByPath'){
                $item = Split-Path $Path -Leaf
            }ElseIf($PSCmdlet.ParameterSetName -eq 'ById'){
                $item = (Get-DropboxItemMetadata -Id $Id).Name
            }
            Invoke-DropboxAPICall -Resource $resource -Method Post -Header $header -subDomain content -ContentType 'application/octet-stream' -FilePath "$Destination\$item"
        }
    }
    End{}
}