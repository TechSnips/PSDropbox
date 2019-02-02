Function Invoke-DropboxAPICall {
    Param (
        [string]$AccessToken = $AuthConfig.AccessToken,
        [string]$Resource,
        [ValidateSet('Get','Post')]
        [string]$Method = 'Get',
        [string]$body
    )
    $BaseURI = 'https://api.dropboxapi.com/2'

    $headers = @{
        'Authorization' = "Bearer $AccessToken"
        'Content-Type' = 'application/json'
        'Accept' = 'application/json'
    }
    $body
    Invoke-RestMethod -Uri "$BaseURI/$Resource" -Method $Method -Headers $headers -Body $body -Verbose
}