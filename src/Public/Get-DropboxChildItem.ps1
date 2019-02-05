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