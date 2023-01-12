﻿
function New-OMEDirectoryService {
<#
Copyright (c) 2022 Dell EMC Corporation

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
    Create new static group in OpenManage Enterprise
.DESCRIPTION
    Only static groups are supported currently. Raise an issue on Github for query group support.
.PARAMETER Name
    Name of group
.PARAMETER Description
    Description of group
.INPUTS
    None
.EXAMPLE
    New-OMEDirectoryService -Name "LAB.LOCAL" -DirectoryType "AD" -DirectoryServerLookup "DNS" -DirectoryServers @("lab.local") -ADGroupDomain "lab.local"

    Create AD Directory Service using Global Catalog Lookup
.EXAMPLE
    New-OMEDirectoryService -Name "LAB.LOCAL" -DirectoryType "AD" -DirectoryServerLookup "MANUAL" -DirectoryServers @("ad1.lab.local", "ad2.lab.local") -ADGroupDomain "lab.local"
    
    Create AD Directory Service manually specifing Domain Controllers
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [String]$Name,

    [Parameter(Mandatory=$false)]
	[ValidateSet("AD", "LDAP")]
    [String] $DirectoryType = "AD",

    [Parameter(Mandatory=$false)]
	[ValidateSet("DNS", "MANUAL")]
    [String] $DirectoryServerLookup = "DNS",

    [Parameter(Mandatory=$true)]
    [String[]]$DirectoryServers,

    [Parameter(Mandatory=$false)]
    [String]$ADGroupDomain,

    [Parameter(Mandatory=$false)]
    [int]$ServerPort,

    [Parameter(Mandatory=$false)]
    [int]$NetworkTimeOut = 120,

    [Parameter(Mandatory=$false)]
    [int]$SearchTimeOut = 120,

    [Parameter(Mandatory=$false)]
    [Switch]$CertificateValidation,

    [Parameter(Mandatory=$false)]
    [String]$LDAPBindUserName,

    [Parameter(Mandatory=$false)]
    [SecureString]$LDAPBindPassword,

    [Parameter(Mandatory=$false)]
    [String]$LDAPBaseDistinguishedName,

    [Parameter(Mandatory=$false)]
    [String]$LDAPAttributeUserLogin,

    [Parameter(Mandatory=$false)]
    [String]$LDAPAttributeGroupMembership,

    [Parameter(Mandatory=$false)]
    [String]$LDAPSearchFilter,

    [Parameter(Mandatory=$false)]
    [Switch]$TestConnection,

    [Parameter(Mandatory=$false)]
    [String]$TestUserName,

    [Parameter(Mandatory=$false)]
    [SecureString]$TestPassword
)

Begin {}
Process {
    if (!$(Confirm-IsAuthenticated)){
        Return
    }
    Try {
        if ($SessionAuth.IgnoreCertificateWarning) { Set-CertPolicy }
        $BaseUri = "https://$($SessionAuth.Host)"
        $AccountProviderURL = ""
        $ADAccountProviderURL = $BaseUri + "/api/AccountService/ExternalAccountProvider/ADAccountProvider"
        $ADAccountProviderTestURL = $BaseUri + "/api/AccountService/ExternalAccountProvider/Actions/ExternalAccountProvider.TestADConnection"
        $LDAPAccountProviderURL = $BaseUri + "/api/AccountService/ExternalAccountProvider/LDAPAccountProvider"
        $LDAPAccountProviderTestURL = $BaseUri + "/api/AccountService/ExternalAccountProvider/Actions/ExternalAccountProvider.TestLDAPConnection"
        $Type = "application/json"
        $Headers = @{}
        $Headers."X-Auth-Token" = $SessionAuth.Token

        <#
            $LDAPAccountProviderPayload = '{
            "Name": "seaquest",
            "ServerType": "DNS",
            "ServerName": ["10.35.195.1"],
            "UserName": "Admin",
            "Password": "XXXXX",
            "ServerPort": 636,
            "BaseDistinguishedName" : "dc=dell,dc=com",
            "AttributeUserLogin": null,
            "AttributeGroupMembership": null,
            "SearchFilter": null,
            "NetworkTimeOut": 300,
            "SearchTimeOut": 300,
            "CertificateValidation": false,
            "CertificateFile": ""
            }' | ConvertFrom-Json

        #>

        $AccountProviderPayload = '{
            "Name": "Starship",
            "ServerType": "DNS",
            "ServerPort": 3269,
            "NetworkTimeOut": 120,
            "SearchTimeOut": 120,
            "CertificateValidation": false,
            "CertificateFile": ""
           }' | ConvertFrom-Json

        $AccountProviderPayload.Name = $Name
        $AccountProviderPayload.ServerType = $DirectoryServerLookup
        $AccountProviderPayload.NetworkTimeOut = $NetworkTimeOut
        $AccountProviderPayload.SearchTimeOut = $SearchTimeOut
        $AccountProviderPayload.CertificateValidation = $CertificateValidation.IsPresent
        
        if ($DirectoryServerLookup -eq "DNS") {
            if ($DirectoryServers.Count -gt 1) { throw [System.Exception] "For DNS Lookup DirectoryServers must contain only 1 entry Example: lab.local" }
            $AccountProviderPayload | Add-Member -NotePropertyName "DnsServer" -NotePropertyValue $DirectoryServers
        } else {
            $AccountProviderPayload | Add-Member -NotePropertyName "ServerName" -NotePropertyValue $DirectoryServers
        }

        if ($DirectoryType -eq "AD") {
            if ($null -eq $ADGroupDomain) { throw [System.ArgumentNullException] "ADGroupDomain" }

            if ($TestConnection) {
                $AccountProviderURL = $ADAccountProviderTestURL
            } else {
                $AccountProviderURL = $ADAccountProviderURL
            }
            if ($ServerPort) {
                $AccountProviderPayload.ServerPort = $ServerPort
            } else {
                $AccountProviderPayload.ServerPort = 3269
            }
            $AccountProviderPayload | Add-Member -NotePropertyName "GroupDomain" -NotePropertyValue $ADGroupDomain
        }

        if ($DirectoryType -eq "LDAP") {
            #if ($null -eq $LDAPBindUserName) { throw [System.ArgumentNullException] "LDAPBindUserName" }
            #if ($null -eq $LDAPBindPassword) { throw [System.ArgumentNullException] "LDAPBindPassword" }
            if ($null -eq $LDAPBaseDistinguishedName) { throw [System.ArgumentNullException] "LDAPBaseDistinguishedName" }

            if ($TestConnection) {
                $AccountProviderURL = $LDAPAccountProviderTestURL
            } else {
                $AccountProviderURL = $LDAPAccountProviderURL
            }
            if ($ServerPort) {
                $AccountProviderPayload.ServerPort = $ServerPort
            } else {
                $AccountProviderPayload.ServerPort = 636
            }
            $AccountProviderPayload | Add-Member -NotePropertyName "BindDN" -NotePropertyValue $LDAPBindUserName
            if ($LDAPBindPassword) {
                $LDAPBindPasswordText = (New-Object PSCredential "user", $LDAPBindPassword).GetNetworkCredential().Password
            } else {
                $LDAPBindPasswordText = ""
            }
            $AccountProviderPayload | Add-Member -NotePropertyName "BindPassword" -NotePropertyValue  $LDAPBindPasswordText
            $AccountProviderPayload | Add-Member -NotePropertyName "BaseDistinguishedName" -NotePropertyValue $LDAPBaseDistinguishedName
            $AccountProviderPayload | Add-Member -NotePropertyName "AttributeUserLogin" -NotePropertyValue $LDAPAttributeUserLogin
            $AccountProviderPayload | Add-Member -NotePropertyName "AttributeGroupMembership" -NotePropertyValue $LDAPAttributeGroupMembership
            $AccountProviderPayload | Add-Member -NotePropertyName "SearchFilter" -NotePropertyValue $LDAPSearchFilter
        }

        if ($TestConnection) {
            if ($null -eq $TestUserName) { throw [System.ArgumentNullException] "TestUserName" }
            if ($null -eq $TestPassword) { throw [System.ArgumentNullException] "TestPassword" }

            $AccountProviderPayload | Add-Member -NotePropertyName "UserName" -NotePropertyValue $TestUserName
            $TestPasswordText = (New-Object PSCredential "user", $TestPassword).GetNetworkCredential().Password
            $AccountProviderPayload | Add-Member -NotePropertyName "Password" -NotePropertyValue  $TestPasswordText
        }

        $AccountProviderPayload = $AccountProviderPayload | ConvertTo-Json -Depth 6
        Write-Verbose $AccountProviderPayload
        Write-Verbose $AccountProviderURL

        $AccountProviderResponse = Invoke-WebRequest -Uri $AccountProviderURL -UseBasicParsing -Headers $Headers -ContentType $Type -Method POST -Body $AccountProviderPayload
        Write-Verbose "Creating Group..."
        if ($AccountProviderResponse.StatusCode -in 200, 201) {
            return $AccountProviderResponse.Content | ConvertFrom-Json
        } elseif ($AccountProviderResponse.StatusCode -eq 204) {
            Write-Verbose "Test Successful"
        }
        else {
            Write-Error "Directory Service creation failed..."
        }
    }
    Catch {
        Resolve-Error $_
    }
}

End {}

}

