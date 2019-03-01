Function Get-DropboxAuthConfig {
    Param(
        [switch]$Silent
    )
    If($AuthConfig){
        If(-not ($Silent.IsPresent)){
            $AuthConfig
        }
    }Else{
        $dir = Get-DropboxCredentialSavePath
        If(Test-Path $dir\credentials.json){
            $encryptedAuth = Get-Content $dir\credentials.json | ConvertFrom-Json
        }
        $script:AuthConfig = [pscustomobject]@{}
        ForEach($property in $encryptedAuth.psobject.Properties){
            $AuthConfig | Add-Member -MemberType NoteProperty -Name $property.name -Value ([pscredential]::New('user',(ConvertTo-SecureString $property.value)).GetNetworkCredential().password)
        }
        If(-not ($Silent.IsPresent)){
            $AuthConfig
        }
    }
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
Function Invoke-DropboxAuthentication {
    [cmdletbinding()]
    Param (
        [Parameter(
            ParameterSetName = 'App'
        )]
        [string]$AppKey,
        [Parameter(
            ParameterSetName = 'App'
        )]
        [string]$AppSecret,
        [Parameter(
            ParameterSetName = 'App'
        )]
        [string]$RedirectURI,
        [Parameter(
            ParameterSetName = 'Token'
        )]
        [string]$AccessToken,
        [switch]$Passthru
    )
    If($PSCmdlet.ParameterSetName -eq 'App'){
        $authcode = Request-DropboxAuthorizationCode -AppKey $AppKey -AppSecret $AppSecret -RedirectURI $RedirectURI
        If($authcode.ContainsKey('code')){
            $AccessToken = Request-DropboxAccessToken -AuthorizationCode $authcode['code'] -AppKey $AppKey -AppSecret $AppSecret -RedirectURI $RedirectURI
        }
    }
    $Script:AuthConfig = [pscustomobject]@{
        AccessToken = $AccessToken
    }
    Save-DropboxAuthConfig
    If($Passthru.IsPresent){
        $AuthConfig
    }
}
Function Get-DropboxCredentialSavePath {
    Param (

    )
    If($PSVersionTable.PSVersion.Major -ge 6){
        # PS Core
        If($IsLinux){
            $saveDir = $env:HOME
        }ElseIf($IsWindows){
            $saveDir = $env:USERPROFILE
        }
    }Else{
        # Windows PS
        $saveDir = $env:USERPROFILE
    }
    "$saveDir\.psdropbox"
}
Function Get-LastError {
    Param (

    )
    $result = $error[0].Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($result)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $reader.ReadToEnd()
}
Function Request-DropboxAccessToken {
    Param(
        [ValidateNotNullOrEmpty()]
        [string]$AuthorizationCode = $AuthConfig.AuthCode,
        [string]$AppKey,
        [string]$AppSecret,
        [string]$RedirectURI
    )
    $baseuri = 'https://api.dropboxapi.com/oauth2/token'

    $encodedRedirect = [System.Web.HttpUtility]::UrlEncode($RedirectURI)

    $encodedAuth = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$AppKey`:$AppSecret"))

    $headers = @{
        'Content-Type' = 'application/x-www-form-urlencoded'
        Authorization = "Basic $encodedAuth"
    }

    $body = @(
        "code=$AuthorizationCode"
        "grant_type=authorization_code"
        "redirect_uri=$encodedRedirect"
    ) -join '&'

    $resp = Invoke-RestMethod -Uri $baseuri -Method Post -Headers $headers -Body $body

    $resp.access_token
}
Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Windows.Forms
Function Request-DropboxAuthorizationCode {
    Param (
        [string]$AppKey,
        [string]$AppSecret,
        [string]$RedirectURI
    )
    $encodedRedirect = [System.Web.HttpUtility]::UrlEncode($RedirectURI)
    $encodedKey = [System.Web.HttpUtility]::UrlEncode($AppKey)
    $baseUri = 'https://www.dropbox.com/oauth2/authorize'
    $parameters = "client_id=$encodedKey&redirect_uri=$encodedRedirect&response_type=code"
    $uri = "$baseUri`?$parameters"

    # Build a form to use with our web object
    $Form = New-Object -TypeName 'System.Windows.Forms.Form' -Property @{
        Width = 680
        Height = 640
    }

    # Build the web object to brows to the logon uri
    $Web = New-Object -TypeName 'System.Windows.Forms.WebBrowser' -Property @{
        Width = 680
        Height = 640
        Url = $uri
    }

    # Add the document completed script to detect when the code is in the uri
    $DocumentCompleted_Script = {
        if ($web.Url.AbsoluteUri -match "error=[^&]*|code=[^&]*") {
            $form.Close()
        }
    }

    # Add controls to the form
    $web.ScriptErrorsSuppressed = $true
    $web.Add_DocumentCompleted($DocumentCompleted_Script)
    $form.Controls.Add($web)
    $form.Add_Shown({ $form.Activate() })

    # Run the form
    [void]$form.ShowDialog()

    # Parse the output
    $QueryOutput = [System.Web.HttpUtility]::ParseQueryString($web.Url.Query)
    $Response = @{ }
    foreach ($key in $queryOutput.Keys) {
        $Response["$key"] = $QueryOutput[$key]
    }

    $Response
}
Function Save-DropboxAuthConfig {
    Param(

    )
    $dir = Get-DropboxCredentialSavePath
    If(-not(Test-Path $dir -PathType Container)){
        New-Item $dir -ItemType Directory | Out-Null
    }
    If(-not(Test-Path $dir\credentials.json -PathType Leaf)){
        New-Item $dir\credentials.json -ItemType File | Out-Null
    }
    $encryptedAuth = @{}
    ForEach($property in $AuthConfig.PSobject.Properties){
        $encryptedAuth."$($property.Name)" = (ConvertFrom-SecureString (ConvertTo-SecureString $property.Value -AsPlainText -Force))
    }
    $encryptedAuth | ConvertTo-Json | Set-Content $dir\credentials.json
}
