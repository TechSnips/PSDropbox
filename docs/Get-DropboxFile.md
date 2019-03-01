---
external help file: PSDropbox-help.xml
Module Name: PSDropbox
online version:
schema: 2.0.0
---

# Get-DropboxFile

## SYNOPSIS
Downloads a file from DropBox via the API.

## SYNTAX

### ByPath (Default)
```
Get-DropboxFile [-Path <String>] [-Destination <String>] [<CommonParameters>]
```

### ById
```
Get-DropboxFile [-Id <String>] [-Destination <String>] [<CommonParameters>]
```

## DESCRIPTION
{{Fill in the Description}}

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-DropboxFile -Path '\Test\image.jpg' -Destination 'C:\path\to\image.jpg'
```

Downloads image.jpg to image.jpg.

## PARAMETERS

### -Destination
{{Fill Destination Description}}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
{{Fill Id Description}}

```yaml
Type: String
Parameter Sets: ById
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Path
{{Fill Path Description}}

```yaml
Type: String
Parameter Sets: ByPath
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
