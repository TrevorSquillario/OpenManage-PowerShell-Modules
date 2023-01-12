using module ..\..\Classes\AccountProvider.psm1
using module ..\..\Classes\DirectoryGroup.psm1
using module ..\..\Classes\Role.psm1

function Invoke-OMEDirectoryServiceImportGroup {
<#
Copyright (c) 2021 Dell EMC Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

<#
 .SYNOPSIS
   Get list of networks (VLAN) from OME

 .DESCRIPTION
   This script uses the OME REST API.
   Note that the credentials entered are not stored to disk.
.PARAMETER Value
    String containing search value. Use with -FilterBy parameter. Supports regex based matching.
.PARAMETER FilterBy
    Filter the results by (Default="Name", "Id", "VlanMaximum", "VlanMinimum", "Type")
 .EXAMPLE
   Invoke-OMEDirectoryServiceImportGroup | Format-Table
#>   

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [AccountProvider]$DirectoryService,

    [Parameter(Mandatory)]
    [DirectoryGroup[]]$DirectoryGroups,

    [Parameter(Mandatory)]
    [Role]$Role
)

Begin {}
Process {
    if (!$(Confirm-IsAuthenticated)){
        Return
    }
    Try {
        if ($SessionAuth.IgnoreCertificateWarning) { Set-CertPolicy }
        $BaseUri = "https://$($SessionAuth.Host)"
        $Headers = @{}
        $ContentType = "application/json"
        $Headers."X-Auth-Token" = $SessionAuth.Token

        $AccountProviderImportUrl = $BaseUri  + "/api/AccountService/Actions/AccountService.ImportExternalAccountProvider"
        $GroupsPayload = @()
        $GroupPayload ='{
            "UserTypeId": 2,
            "DirectoryServiceId": 0,
            "Description": "",
            "Name": "OME-ModularMegatronTeam",
            "Password": "",
            "UserName": "OME-ModularMegatronTeam",
            "RoleId": "10",
            "Locked": false,
            "Enabled": true,
            "ObjectGuid": "d22005b6-0ce5-40ed-88d0-7f7759b52f25"
            }' | ConvertFrom-Json
        
        foreach ($DirectoryGroup in $DirectoryGroups) {
            $GroupPayload.DirectoryServiceId = $DirectoryService.Id
            $GroupPayload.Name = $DirectoryGroup.CommonName
            $GroupPayload.UserName = $DirectoryGroup.CommonName
            $GroupPayload.ObjectGuid = $DirectoryGroup.ObjectGuid
            $GroupPayload.RoleId = $Role.Id
            $GroupsPayload += $GroupPayload
        }
        $GroupsPayload = ,$GroupsPayload | ConvertTo-Json -Depth 6
        Write-Verbose $GroupsPayload
        Write-Verbose $AccountProviderImportUrl

        $AccountProviderImportResponse = Invoke-WebRequest -Uri $AccountProviderImportUrl -UseBasicParsing -Headers $Headers -ContentType $ContentType -Method POST -Body $GroupsPayload
        if ($AccountProviderImportResponse.StatusCode -in 200, 201) {
            $AccountProviderImportData = $AccountProviderImportResponse.Content | ConvertFrom-Json
            Write-Verbose $AccountProviderImportData   
        } else {
            Write-Error "Directory Service import failed..."
        }
    }
    Catch {
        Resolve-Error $_
    }

}

End {}

}