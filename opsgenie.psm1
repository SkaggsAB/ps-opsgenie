<#Validation functions

TODO: Timezone and Locale validation.  Medium effort, low reward.


#>
Function Test-Guid
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

function Test-Email ([string]$Email)
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
    Add-OGUser    - Create User
    Set-OGUser    - Update User
    Remove-OGUser - Remove User
    Get-OGUser    - Get User(s)
    Copy-OGNotificationRules - Copy Notification Rules from one user to other users/groups
#>

Function Add-OGUser
{

<#
  .Synopsis
    Creates a new user in OpsGenie
  .Description
    The Add-OGUser cmdlet is used to create a new user in OpsGenie.
  .Example
    Add-OGUser -apiKey api-key -username "bob@example.com" -fullname "Bob Ross"
      This creates a new user "bob@example.com" with the name "Bob Ross", with a role of User (the default)
  .Parameter apiKey
    The api key with permissions to modify users.
  .Parameter userName
    The username for the new user.  Must be in user@domain.tld format.
  .Parameter fullName
    The user's full name.
  .Parameter Role
    The role of the new user, can be any of the built in roles or any custom role.
    Default role type is 'User'
  .Parameter TimeZone
    The timezone of the new user, in the format listed here: https://www.opsgenie.com/docs/miscellaneous/supported-timezone-ids
    Default timezone is set to the main account time zone.
  .Parameter Locale
    The locale of the new user, in the format listed here: https://www.opsgenie.com/docs/miscellaneous/supported-locales
    Default locale is set to the main account locale.

  .Notes
    NAME:  Add-OGUser
    AUTHOR: Patrick Forristal
    LASTEDIT: 12/4/2015
    KEYWORDS: OpsGenie
 #Requires -Version 3.0
 #>

    Param(
        [Parameter(Mandatory)][ValidateScript({Test-Guid ($_)})][string] $apiKey,
        [string] $apiURI = 'https://api.opsgenie.com/v1/json/user',
        [Parameter(Mandatory)][ValidateScript({Test-Email ($_)})][string] $UserName,
        [Parameter(Mandatory)][ValidateLength(2,512)][string] $FullName,
        [ValidateLength(1,512)][string] $Role = "User",
        [ValidateLength(2,512)][string] $TimeZone,
        [ValidateLength(2,512)][string] $Locale
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

<#
  .Synopsis
    Gets a specific user or users in OpsGenie
  .Description
    The Get-OGUser cmdlet is used to get a specific user or users in OpsGenie.
  .Example
    Get-OGUser -apiKey "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -username "bob@example.com"
      This pulls the record for the user Bob.
  .Example
    Get-OGUser -apiKey "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -username "bob@example.com","alices@example.com"
      This pulls the records for the users Bob and Alice.
  .Example
    Get-OGUser -apiKey "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -id "00000000-0000-0000-0000-000000000000"
      This pulls the record for the user who's id is 00000000-0000-0000-0000-000000000000
  .Parameter apiKey
    The api key with permissions to modify users.
  .Parameter userName
    The username(s) of the user(s) to be searched.  Must be in user@domain.tld format.
  .Parameter id
    The id(s) for the user(s) to be searched.  Must be a valid GUID.
  .Notes
    NAME:  Get-OGUser
    AUTHOR: Patrick Forristal
    LASTEDIT: 12/4/2015
    KEYWORDS: OpsGenie
 #Requires -Version 3.0
 #>

    Param(
        [Parameter(Mandatory)][ValidateScript({Test-Guid ($_)})][string] $apiKey,
        [string] $apiURI = 'https://api.opsgenie.com/v1/json/user',
        [ValidateScript({Test-Email ($_)})][string[]] $UserName,
        [ValidateScript({Test-Guid ($_)})][string[]] $id
        )

    if (($id.Length -gt 0 -and $UserName.Length -gt 0)) {
        Write-Error "You must specify either username(s) or id(s)."
        return 1
    }

    if ($UserName.Length -eq 0 -and $id.Length -eq 0) {
          $apiURI2 = $apiURI + "?apiKey=$apiKey"
          Write-Verbose "Sending request to OpsGenie to get all users"
          $output = (Invoke-RestMethod -Method Get -Uri $apiURI2).users
    } elseif ($id.Length -gt 0) {
         $output = @()
        foreach ($user in $id){
            $apiURI2 = $apiURI + "?apiKey=$apiKey&id=$id"
            Write-Verbose "Sending request to OpsGenie to get the user, $id"
            $output += Invoke-RestMethod -Method Get -Uri $apiURI2
        }
    } else {
        $output = @()
        foreach ($user in $UserName){
            $apiURI2 = $apiURI + "?apiKey=$apiKey&username=$User"
            Write-Verbose "Sending request to OpsGenie to get the user, $UserName"
            $output += Invoke-RestMethod -Method Get -Uri $apiURI2
        }
        
    }
    return $output
}


Function Set-OGUser
{
<#
  .Synopsis
    Updates a user or users in OpsGenie
  .Description
    The Set-OGUser cmdlet is used to change a user or users in OpsGenie.
  .Example
    Set-OGUser -apiKey api-key -username "bob@example.com" -fullname "Bob Ross"
      This changes the name of user "bob@example.com" to "Bob Ross"
  .Example
    Set-OGUser -apiKey api-key -username "bob@example.com" -fullname "Bob Ross"
      This changes the name of user "bob@example.com" to "Bob Ross"
  .Parameter apiKey
    The api key with permissions to modify users.
  .Parameter userName
    The username of the user(s) to modify with this cmdlet.
  .Parameter id
    The id of the user(s) to modify with this cmdlet.
  .Parameter fullName
    The full name to set for the user(s).
  .Parameter Role
    The role to set for the user(s), can be any of the built in roles or any custom role.
  .Parameter TimeZone
    The timezone to set for the user(s), in the format listed here: https://www.opsgenie.com/docs/miscellaneous/supported-timezone-ids
  .Parameter Locale
    The locale to set for the user(s), in the format listed here: https://www.opsgenie.com/docs/miscellaneous/supported-locales

  .Notes
    NAME:  Set-OGUser
    AUTHOR: Patrick Forristal
    LASTEDIT: 12/4/2015
    KEYWORDS: OpsGenie
 #Requires -Version 3.0
 #>
    Param(
        [Parameter(Mandatory)][ValidateScript({Test-Guid ($_)})][string] $apiKey,
        [string] $apiURI = 'https://api.opsgenie.com/v1/json/user',
        [ValidateScript({Test-Email ($_)})][string[]] $UserName,
        [ValidateScript({Test-Guid ($_)})][string[]] $id,
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


Function Remove-OGUser
{

<#
  .Synopsis
    Removes a specific user or users in OpsGenie
  .Description
    The Remove-OGUser cmdlet is used to remove a specific user or users in OpsGenie.
  .Example
    Remove-OGUser -apiKey "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -username "bob@example.com"
      This removes account for the user Bob.
  .Example
    Remove-OGUser -apiKey "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -username "bob@example.com","alices@example.com"
      This removes the account for users Bob and Alice.
  .Example
    Remove-OGUser -apiKey "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -id "00000000-0000-0000-0000-000000000000"
      This removes the account for the user who's id is 00000000-0000-0000-0000-000000000000
  .Parameter apiKey
    The api key with permissions to modify users.
  .Parameter userName
    The username(s) of the user(s) to be removed.  Must be in user@domain.tld format.
  .Parameter id
    The id(s) for the user(s) to be removed.  Must be a valid GUID.
  .Notes
    NAME:  Get-OGUser
    AUTHOR: Patrick Forristal
    LASTEDIT: 12/4/2015
    KEYWORDS: OpsGenie
 #Requires -Version 3.0
 #>

    Param(
        [Parameter(Mandatory)][ValidateScript({Test-Guid ($_)})][string] $apiKey,
        [string] $apiURI = 'https://api.opsgenie.com/v1/json/user',
        [ValidateScript({Test-Email ($_)})][string[]] $UserName,
        [ValidateScript({Test-Guid ($_)})][string[]] $id,
        [switch] $Force
        )

    if (($id.Length -gt 0 -and $UserName.Length -gt 0) -or ($UserName.Length -eq 0 -and $id.Length -eq 0)) {
        Write-Error "You must specify either username(s) or id(s)."
    }

    if (!$Force) {
      $PromptTitle = "Remove user(s)"
      $PromptMessage = "Do you really want to delete the specified user(s)?"
      $PromptYes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Deletes the specified user(s)."
      $PromptNo = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Cancels the delete operation."
      $PromptOptions = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no)
      $PromptResponse = $host.ui.PromptForChoice($PromptTitle,$PromptMessage,$PromptOptions,1)
      if ($PromptResponse -ne 0) {
        Write-Verbose "Remove-OGUser cancelled by user."
        return
      }
    }

    if ($UserName.Count -gt 0) {
        foreach ($user in $UserName) {
            $NewID = (get-OGUser -apiKey $apiKey -UserName $User).id
            if ($NewID.length -gt 0 ) {
                $id += $NewID
            } else {
                Write-Error "$User is not a valid user."    
            }
        }
    }

    foreach ($UserId in $ID) {
            $user = get-OGUser -apiKey $apiKey -id $UserId
            if ($user.id.length -gt 0){

                $Properties = @{'apiKey'=$apiKey;'id'=$UserId}

                $RequestParams = New-Object -TypeName psobject -Property $Properties
                $JSONbody = ConvertTo-Json -InputObject $RequestParams

                Write-Verbose "Sending request to OpsGenie to delete user, $($User.username)"
                $output += Invoke-RestMethod -Method Post -Uri $apiURI -Body $JSONbody
            } else {
             Write-Error "$id is not a valid user id."
            }
    }
        return $output
    
}


Function Copy-OGNotificationRules
{
<#
  .Synopsis
    Copies notification rules from one user to multiple users or groups.
  .Description
    The Copy-OGNotificationRules cmdlet is useful for templating users from a golden user.
  .Example
    Copy-OGNotificationRules -apiKey aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa -fromuser 'bob@example.net'
      This copies the notification preferences for "New Alert" (the default) from Bob to all users (the default).
  .Example
    Copy-OGNotificationRules -apiKey aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa -fromuser 'bob@example.net' -tousers 'alice@example.net','charlie@example.net'
      This copies the notification preferences for "New Alert" (the default) from Bob to Alice and Charlie.
  .Example
    Copy-OGNotificationRules -apiKey aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa -fromuser 'bob@example.net' -tousers 'example_group' -ruletypes 'all'
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
        [Parameter(Mandatory)][ValidateScript({Test-Guid ($_)})][string] $apiKey,
        [string] $apiURI = 'https://api.opsgenie.com/v1/json/copyNotificationRules',
        [Parameter(Mandatory)][ValidateScript({Test-Email ($_)})][string] $fromUser,
        [string[]] $toUsers = @("all"),
        [string[]] $ruleTypes = @("New Alert")

    )

    $Properties = @{'apiKey'=$apiKey;'fromUser'=$fromUser;'toUsers'=$toUsers;'ruleTypes'=$ruleTypes}

    $RequestParams = New-Object -TypeName psobject -Property $Properties

    $JSONbody = ConvertTo-Json -InputObject $RequestParams

    Write-Verbose "Sending request to OpsGenie to copy notification rules from $fromUser to $toUsers"
    Invoke-RestMethod -Method Post -Uri $apiURI -Body $JSONbody
}
