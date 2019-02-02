Function Get-LastError {
    Param (

    )
    $result = $error[0].Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($result)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $reader.ReadToEnd()
}