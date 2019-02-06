Function Save-DropboxUserToken {
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
}