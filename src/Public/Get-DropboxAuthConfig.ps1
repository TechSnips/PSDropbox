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
            $AuthConfig | Add-Member -MemberType NoteProperty -Name "$($property.name)" -Value [pscredential]::New('user',(ConvertTo-SecureString $property.value)).GetNetworkCredential().password
        }
        If(-not ($Silent.IsPresent)){
            $AuthConfig
        }
    }
}