<#Validation functions

TODO: Timezone and Locale validation.  Medium effort, low reward.
#>
Function Validate-GUID
{
    Param(
        [Parameter(Mandatory)][string[]] $GUID
    )
    try {
        [System.Guid]::Parse($GUID) | Out-Null
        Write-Debug "$GUID is valid"
        Return $true
    } catch {
        Write-Error "This is not a valid GUID"
        Return $false
    }

}

function Validate-Email ([string]$Email) 
{ 
  if ($Email.Length -gt 100) {
    Write-Error "Max length (100) exceeded."
    return $false
  }
  $valid = $Email -match "^(?("")("".+?""@)|(([0-9a-zA-Z]((\.(?!\.))|[-!#\$%&'\*\+/=\?\^`\{\}\|~\w])*)(?<=[0-9a-zA-Z])@))(?(\[)(\[(\d{1,3}\.){3}\d{1,3}\])|(([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,6}))$" 
  if ($valid) {
    Write-Debug "$Email is a valid email address"
    return $true
  } else {
    Write-Error "$Email is not a valid email address"
    return $false
  }
}  

<#
    User Functions:
    New-OGUser    - Create User
    Set-OGUser    - Update User
    Remove-OGUser - Remove User
    Get-OGUser    - Get User(s)
    Copy-OGNotificationRules - Copy Notification Rules from one user to other users/groups
#>

Function New-OGUser
{

<#
  .Synopsis
    Creates new users in OpsGenie
  .Description
    The New-OGUser cmdlet is used to create new users.
  .Example
    New-OGUser -apiKey api-key -fromuser 'bob@example.net'
      This copies the notification preferences for "New Alert" (the default) from Bob to all users (the default).
  .Example
    New-OGUser -apiKey api-key -fromuser 'bob@example.net' -tousers 'alice@example.net','charlie@example.net'
      This copies the notification preferences for "New Alert" (the default) from Bob to Alice and Charlie.
  .Example
    New-OGUser -apiKey api-key -fromuser 'bob@example.net' -tousers 'example_group' -ruletypes 'all'
      This copies the notification preferences for all alert rules from Bob to all members of the example_group.
  .Parameter apiKey
    The api key with permissions to modify users.
  .Parameter fromUser
    The user to copy notification rules from.
  .Parameter toUsers
    The users or groups to apply the new notification preferences to.
    Default users is 'all'
  .Parameter ruleTypes
    The rule types to copy from the fromUser to the toUsers.
    Default rule type is 'New Alert'
  .Notes
    NAME:  New-OGUser
    AUTHOR: Patrick Forristal
    LASTEDIT: 12/4/2015
    KEYWORDS: OpsGenie
 #Requires -Version 3.0
 #>

    Param(
        [Parameter(Mandatory)][ValidateScript({Validate-GUID ($_)})][string] $apiKey,
        [string] $apiURI = 'https://api.opsgenie.com/v1/json/user',
        [Parameter(Mandatory)][ValidateScript({Validate-Email ($_)})][string] $UserName,
        [Parameter(Mandatory)][ValidateLength(2,512)][string] $FullName,
        [ValidateLength(1,512)][string] $Role = "User"
        )

    $Properties = @{'apiKey'=$apiKey;'username'=$UserName;'fullname'=$fullname;'role'=$role}
    if ($timezone.Length -gt 0) {$Properties += @{'timezone'=$timezone}}
    if ($locale.Length -gt 0) {$Properties += @{'locale'=$locale}}

    $RequestParams = New-Object -TypeName psobject -Property $Properties
    $JSONbody = ConvertTo-Json -InputObject $RequestParams
    Write-Verbose "Sending request to OpsGenie to create new user, $UserName"
    Invoke-RestMethod -Method Post -Uri $apiURI -Body $JSONbody
}


Function Get-OGUser
{
    Param(
        [Parameter(Mandatory)][ValidateScript({Validate-GUID ($_)})][string] $apiKey,
        [string] $apiURI = 'https://api.opsgenie.com/v1/json/user',
        [ValidateScript({Validate-Email ($_)})][string[]] $UserName,
        [ValidateScript({Validate-GUID ($_)})][string[]] $id
        )

    if (($id.Length -gt 0 -and $UserName.Length -gt 0) -or ($UserName.Length -eq 0 -and $id.Length -eq 0)) {
        Write-Error "You must specify either username(s) or id(s)."
    }
    if ($id.Length -gt 0) {
         $output = @()
        foreach ($user in $id){
            $apiURI2 = $apiURI + "?apiKey=$apiKey&id=$id"
            Write-Verbose "Sending request to OpsGenie to get the user, $id"
            $output += Invoke-RestMethod -Method Get -Uri $apiURI2
        }
        return $output     
    } else {
        $output = @()
        foreach ($user in $UserName){
            $apiURI2 = $apiURI + "?apiKey=$apiKey&username=$User"
            Write-Verbose "Sending request to OpsGenie to get the user, $UserName"
            $output += Invoke-RestMethod -Method Get -Uri $apiURI2
        }
        return $output
    }
}


Function Set-OGUser
{
    Param(
        [Parameter(Mandatory)][ValidateScript({Validate-GUID ($_)})][string] $apiKey,
        [string] $apiURI = 'https://api.opsgenie.com/v1/json/user',
        [ValidateScript({Validate-Email ($_)})][string[]] $UserName,
        [ValidateScript({Validate-GUID ($_)})][string[]] $id,
        [ValidateLength(2,512)][string] $FullName,
        [ValidateLength(2,512)][string] $TimeZone,
        [ValidateLength(2,512)][string] $Locale,
        [ValidateLength(1,512)][string] $Role
        )

    if (($id.Length -gt 0 -and $UserName.Length -gt 0) -or ($UserName.Length -eq 0 -and $id.Length -eq 0)) {
        Write-Error "You must specify either a username or id."
    }

    $output = @()
    $Properties = @{'apiKey'=$apiKey}

    if ($UserName.Count -gt 0) {
        foreach ($user in $UserName) {
            $id += (get-OGUser -apiKey $apiKey -UserName $User).id
        }
    }

    foreach ($userid in $id) {
            $Properties = @{'apiKey'=$apiKey;'id'=$userid}
            
            if ($FullName.Length -gt 0) {$Properties += @{'fullname'=$fullname}}
            if ($timezone.Length -gt 0) {$Properties += @{'timezone'=$timezone}}
            if ($locale.Length -gt 0) {$Properties += @{'locale'=$locale}}
            if ($role.Length -gt 0) {$Properties += @{'role'=$role}}
    
            $RequestParams = New-Object -TypeName psobject -Property $Properties
            $JSONbody = ConvertTo-Json -InputObject $RequestParams

            Write-Verbose "Sending request to OpsGenie to modify user, $UserName"
            $output += Invoke-RestMethod -Method Post -Uri $apiURI -Body $JSONbody
     
    }
    
}


Function Copy-OGNotificationRules
{
<#
  .Synopsis
    Copies notification rules from one user to multiple users or groups.
  .Description
    The Copy-OGNotificationRules cmdlet is useful for templating users from a golden user.
  .Example
    Copy-OGNotificationRules -apiKey api-key -fromuser 'bob@example.net'
      This copies the notification preferences for "New Alert" (the default) from Bob to all users (the default).
  .Example
    Copy-OGNotificationRules -apiKey api-key -fromuser 'bob@example.net' -tousers 'alice@example.net','charlie@example.net'
      This copies the notification preferences for "New Alert" (the default) from Bob to Alice and Charlie.
  .Example
    Copy-OGNotificationRules -apiKey api-key -fromuser 'bob@example.net' -tousers 'example_group' -ruletypes 'all'
      This copies the notification preferences for all alert rules from Bob to all members of the example_group.
  .Parameter apiKey
    The api key with permissions to modify users.
  .Parameter fromUser
    The user to copy notification rules from.
  .Parameter toUsers
    The users or groups to apply the new notification preferences to.
    Default users is 'all'
  .Parameter ruleTypes
    The rule types to copy from the fromUser to the toUsers.
    Default rule type is 'New Alert'
  .Notes
    NAME:  Copy-OGNotificationRules
    AUTHOR: Patrick Forristal
    LASTEDIT: 12/4/2015
    KEYWORDS: OpsGenie
 #Requires -Version 3.0
 #>
    Param(
        [Parameter(Mandatory)][ValidateScript({Validate-GUID ($_)})][string] $apiKey,
        [string] $apiURI = 'https://api.opsgenie.com/v1/json/copyNotificationRules',
        [Parameter(Mandatory)][ValidateScript({Validate-Email ($_)})][string] $fromUser,
        [string[]] $toUsers = @("all"),
        [string[]] $ruleTypes = @("New Alert")

    )

    $Properties = @{'apiKey'=$apiKey;'fromUser'=$fromUser;'toUsers'=$toUsers;'ruleTypes'=$ruleTypes}
    
    $RequestParams = New-Object -TypeName psobject -Property $Properties
    
    $JSONbody = ConvertTo-Json -InputObject $RequestParams

    Write-Verbose "Sending request to OpsGenie to copy notification rules from $fromUser to $toUsers"
    Invoke-RestMethod -Method Post -Uri $apiURI -Body $JSONbody
}