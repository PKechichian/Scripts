# Add and Import Organisational Units

```
Import-Module ActiveDirectory
Import-Module ImportExcel

$domain = "DC=pharmgreen,DC=com"
$excel = "C:\Users\Administrator\Desktop\ListEmployees_Pharmgreen1.xlsx"
$OU1s = @("PG_Users", "PG_Computers", "PG_Groups")
$data = Import-Excel -Path $excel
$units = $data.Unit | Sort-Object -Unique
$groups = $data.Groupe |Sort-Object -Unique

foreach ($ou1 in $OU1s) {
    New-ADOrganizationalUnit -Name $ou1 -Path $domain -ProtectedFromAccidentalDeletion $false
}

foreach ($unit in $units) {
    foreach ($ou1 in $OU1s) {
    New-ADOrganizationalUnit -Name $unit -Path "OU=$ou1, $domain" -ProtectedFromAccidentalDeletion $false
    }
}
```

----------------------------

# Add Security Group

```
Import-Module ActiveDirectory
Import-Module ImportExcel

$domain = "DC=pharmgreen,DC=com"
$excel = "C:\Users\Administrator\Desktop\Scripts\OU_Groups_Pharmgreen.xlsx"
$data = Import-Excel -Path $excel 

foreach ($row in $data) {
    New-ADGroup -Name "GRP-$($row.Unit)-$($row.Groupe)" -GroupCategory Security -GroupScope Global -Path "ou=$($row.Unit),ou=PG_Groups,$domain" -ErrorAction Stop
}
```

------------------------------

# Import Users

```
Import-Module ActiveDirectory
Import-Module ImportExcel

$domain = "DC=pharmgreen,DC=com"
$excel = "C:\Users\Administrator\Desktop\Scripts\ListEmployees_Pharmgreen1.xlsx"
$data = Import-Excel -Path $excel
$defaultPassword = "Banane123*"


foreach ($row in $data) {
    $username = $row.Userlogonname

    $userProps = @{
        SamAccountName = $username
        UserPrincipalName = "$username@$domain"
        Name = "$($row.Firstname) $($row.Lastname)"
        GivenName = $row.Firstname
        Surname = $row.Lastname
        DisplayName = "$($row.Firstname) $($row.Lastname)"
        Department = $row.Department
        Title = $row.'Job Title'
        City = $row.City
        Company = $row.Company
        Office = $row.City
        EmailAddress = $row.Email
        OfficePhone = $row.'Telephone number'
        MobilePhone = $row.Mobile
        Path = "OU=$($row.Unit),OU=PG_Users,$domain"
        AccountPassword = ConvertTo-SecureString $defaultPassword -AsPlainText -Force
        Enabled = $true
        ChangePasswordAtLogon = $true
    }
   
    New-ADUser @userProps

}
```
