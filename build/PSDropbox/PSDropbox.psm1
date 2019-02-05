Function Get-LastError {
    Param (

    )
    $result = $error[0].Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($result)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $reader.ReadToEnd()
}
# https://www.dropbox.com/developers/documentation/http/documentation#files-list_folder
Function Get-DropboxChildItem {
    [cmdletbinding()]
    Param (
        [string]$Path,
        [switch]$Recurse,
        [switch]$IncludeMediaInfo,
        [switch]$IncludeDeleted,
        [switch]$IncludeHasExplicitSharedMembers,
        [switch]$ExcludeMountedFolders

    )
    $FolderChildrenParams = @{
        Recurse = 'recursive'
        IncludeMediaInfo = 'include_media_info'
        IncludeDeleted = 'include_deleted'
        IncludeHasExplicitShareMembers = 'include_has_explicit_shared_members'
        ExcludeMountedFolders = 'include_mounted_folders'
    }
    If($Path -eq '/'){
        $Path = ''
    }
    $body = [pscustomobject]@{
        path = $Path
    }
    ForEach($param in $PSBoundParameters.GetEnumerator() | Where-Object {$_.key -match '^Recurse|^Include'}){
        $body | Add-Member -MemberType NoteProperty -Name $folderChildrenParams[$param.key].ToString().ToLower() -Value $true
    }
    ForEach($param in $PSBoundParameters.GetEnumerator() | Where-Object {$_.key -match '^Exclude'}){
        $body | Add-Member -MemberType NoteProperty -Name $folderChildrenParams[$param.key].ToString().ToLower() -Value $false
    }
    (Invoke-DropBoxAPICall -Resource 'files/list_folder' -Method Post -Body ($body | ConvertTo-Json)).entries
}
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
Function Invoke-DropboxAPICall {
    [cmdletbinding()]
    Param (
        [string]$AccessToken = $AuthConfig.AccessToken,
        [string]$Resource,
        [ValidateSet('Get','Post')]
        [string]$Method = 'Get',
        [string]$Body,
        [hashtable]$Header,
        [string]$subDomain = 'api',
        [ValidateSet('application/json','text/plain','application/octet-stream','application/octet-stream; charset=utf-8')]
        [string]$ContentType = 'application/json',
        [string]$FilePath
    )
    $BaseURI = "https://$subDomain.dropboxapi.com/2"

    $baseHeaders = @{
        'Authorization' = "Bearer $AccessToken"
        'Accept' = 'application/json'
        'Content-Type' = $ContentType
    }

    If($Header){
        ForEach($h in $header.GetEnumerator()){
            $baseHeaders[$h.key] = $h.value
        }
    }

    If($subDomain -eq 'content'){
        Invoke-WebRequest -Uri "$BaseURI/$Resource" -Method $Method -Headers $baseheaders -Body $body -OutFile $FilePath
    }Else{
        Invoke-RestMethod -Uri "$BaseURI/$Resource" -Method $Method -Headers $baseheaders -Body $body
    }
}
Function Request-DropboxAccessToken {
    Param (
        [string]$AuthCode
    )
    <#
        Will get an auth code
    #>
}
Function Request-DropboxAuthorizationCode {
    Param (
        [string]$AppKey,
        [string]$AppSecret
    )
    <#
        Will get an authorization code
    #>
}
Function Save-DropboxUserToken {
    Param(
        [string]$AcessToken = $AuthConfig.AccessToken
    )
    If($AccessToken){

    }
}
