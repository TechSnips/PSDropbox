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