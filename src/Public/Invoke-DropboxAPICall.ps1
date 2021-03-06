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