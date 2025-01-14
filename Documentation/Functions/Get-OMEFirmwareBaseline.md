---
external help file: DellOpenManage-help.xml
Module Name: DellOpenManage
online version:
schema: 2.0.0
---

# Get-OMEFirmwareBaseline

## SYNOPSIS
Get firmware baseline from OpenManage Enterprise

## SYNTAX

```
Get-OMEFirmwareBaseline [[-Value] <String[]>] [[-FilterBy] <String>] [<CommonParameters>]
```

## DESCRIPTION
Returns all baselines if no input received

## EXAMPLES

### EXAMPLE 1
```
Get-OMEFirmwareBaseline | Format-Table
```

Get all baselines

### EXAMPLE 2
```
"AllLatest" | Get-OMEFirmwareBaseline | Format-Table
```

Get baseline by name

## PARAMETERS

### -Value
String containing search value.
Use with -FilterBy parameter

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -FilterBy
Filter the results by (Default="Name", "Id")

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Name
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String[]
## OUTPUTS

## NOTES

## RELATED LINKS
