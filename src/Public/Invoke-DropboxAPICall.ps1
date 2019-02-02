Function Invoke-DropboxAPICall {
    Param (
        [string]$AccessToken = $AuthConfig.AccessToken,
        [string]$Resource,
        [ValidateSet('Get','Post')]
        [string]$Method = 'Get',
        [string]$body,
        [hashtable]$Header,
        [string]$subDomain = 'api',
        [ValidateSet('application/json','text/plain','application/octet-stream','application/octet-stream; charset=utf-8')]
        [string]$ContentType = 'application/json'
    )
    $BaseURI = "https://$subDomain.dropboxapi.com/2"

    $baseHeaders = @{
        'Authorization' = "Bearer $AccessToken"
        'Accept' = 'application/json'
        'Content-Type' = $ContentType
    }

    ForEach($h in $header.GetEnumerator()){
        $baseHeaders[$h.key] = $h.value
    }

    If($subDomain -eq 'content'){
        Invoke-WebRequest -Uri "$BaseURI/$Resource" -Method $Method -Headers $baseheaders -Body $body -OutFile C:\tmp\image.jpg
    }Else{
        Invoke-RestMethod -Uri "$BaseURI/$Resource" -Method $Method -Headers $baseheaders -Body $body -Verbose
    }
}