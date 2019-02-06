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