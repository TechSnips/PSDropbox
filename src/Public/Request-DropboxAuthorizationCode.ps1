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