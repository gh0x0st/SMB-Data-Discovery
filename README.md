# SMB-Data-Discovery
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/gh0x0st/SMB-Data-Discovery/graphs/commit-activity)
[![GitHub license](https://img.shields.io/github/license/gh0x0st/SMB-Data-Discovery)](https://github.com/gh0x0st/SMB-Data-Discovery/blob/master/LICENSE)
[![GitHub forks](https://img.shields.io/github/forks/gh0x0st/SMB-Data-Discovery)](https://github.com/gh0x0st/SMB-Data-Discovery/network)
[![GitHub issues](https://img.shields.io/github/issues/gh0x0st/SMB-Data-Discovery)](https://github.com/gh0x0st/SMB-Data-Discovery/issues)

In order to protect the data you store on information systems, you must know where it resides, whether it's protected health information (PHI), personally identifiable information (PII) or even passwords. In the case for Healthcare, at a minimum, you should have an inventory of what environments house PHI, allowing you identify your high risk environment(s) and implement appropriate safeguards.

**_Outside of a manual inventory, how do you know sensitive data doesn't exist elsewhere and that it's not exposed?_**

You could have holes in your inventory, incomplete data or other scenarios that turn up after the fact, such as new SMB shares being created on your network exposing data that you were not aware of. You need to have a workflow in place that will help you discover exposed data, before someone malicious discovers it first.

In this scenario, we're addressing SMB shares that exist on your network and whether or not they contain human-readable files with potential PHI. It's unrealistic to have this become a manual process, however, with little bit of PowerShell at your fingertips, you can add a significant level of automation at your disposal to focus your efforts on remediation while your system does the hard discovery work.

Let's get our boots on the ground and jump right in!

## Disclaimer

This repository and the data provided has been created purely for the purposes of academic research and for the development of effective security techniques and is not intended to be used to attack systems except where explicitly authorized. It is your responsibility to obey all applicable local, state and federal laws. 

Project maintainers assume no liability and are not responsible for any misuse or damage caused by the data therein.

## Stage 1 - Identify Shares:
The first step we're going to take is to scan our network and list any visible shares. To accomplish this, we're going to use a native windows command to view shares that are on a target machine. This is a powerful native tool and doesn't require any admin access to run, but the output is messy, but with some PowerShell-Fu we'll convert the output into a workable object or into a format we can export.

At this stage, the permissions are redundant; but if you want to set the pace of potential impact across this entire initiative, scan with a service account that has your default groups for an employee account such as 'Domain Users'. During this stage and the next, it will give us an idea of what could be seen if a regular account is compromised or is used maliciously.

#### Generalized Snippet
```PowerShell
$ComputerName = 'SERVER1'
$Resources = net view \\$ComputerName 2>&1

($Resources | Select-Object -Skip 7 | Select-Object -SkipLast 2) -replace '\s\s+', ',' | ForEach-Object {
	[System.Array]$Line = (($_) -split ',')
	If ($Line[1] -eq 'Disk')
	{
		[System.String]$Share = "{0}$ComputerName\{1}" -f '\\', $Line[0]
		[PSCustomObject]@{ 'ComputerName' = $ComputerName; 'Results' = $Share }
	}
}
```

#### Sample Output
```PowerShell
PS C:\> Get-RemoteShare -ComputerName server1

ComputerName Results            
------------ -------            
server1      \\server1\backups                          
server1      \\server1\temp_c 
```

## Stage 2 - Test Share Permissions:
The second step is where we're going to take the list of shares from the first stage and run a couple of tests to determine if we can read the contents of the share and/or if we can write to that share.

**_Permissions are going to matter here_**

If you run this test under the context of an account with expected access, well, then you're likely going to have the rights under both conditions. At this step, consider the worst case scenario first but running under the context of your standard employee. This will be some of if not you're highest risk share scenarios because if for example a 'Domain User' is able to write to a share, then there is a likely a major problem, such as an admin opting for the 'Everyone' at 'Full Access' default approach.

The results of this stage alone could be its own remediation project, however, be prepared to not only advise on the risk, but provide education opportunities or generate a procedure on how to create a share with secure permissions.

Now back to the code: we'll try to read the contents of the directory and if it returns True, then at a minimum we have read rights and if it's False then we have no ability to read.

#### Generalized Snippet
```PowerShell
PS C:\> Test-Path '\\server1\temp_c'
test-path : Access is denied
At line:1 char:1
+ test-path '\\server1\backups'
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : PermissionDenied: (\\server1\backups:String) [Test-Path], UnauthorizedAccessException
    + FullyQualifiedErrorId : ItemExistsUnauthorizedAccessError,Microsoft.PowerShell.Commands.TestPathCommand

PS C:\> Test-Path '\\server1\backups'
True
```

#### Sample Output
```PowerShell
PS C:\> Test-RemoteShare -ShareName '\\server1\backups' -CanRead

ShareName           CanRead CanWrite
---------           ------- --------
\\server1\backups   True    Not Tested 
```

Next we will see if we can write a blank file into the share. With a little bit of error handling we can easily determine if we successfully wrote a file based on whether or not it throws a terminating error. If it's true, we created a file and if it's false, we were denied.

#### Generalized Snippet
```PowerShell
$ShareName = "\\server1\backups"
Try
{
	$Path = Join-Path $ShareName -ChildPath '\testcanwrite.txt'
	New-Item -Path $Path -ItemType File -Force -ErrorAction Stop | Out-Null
	Remove-Item $Path
	$true
}
Catch [System.UnauthorizedAccessException]
{
    $false
}
```

#### Sample Output
```PowerShell
PS C:\> Test-RemoteShare -ShareName '\\server1\backups' -CanRead -CanWrite

ShareName           CanRead CanWrite
---------           ------- --------
\\server1\backups   True    False
```

## Stage 3 - Inventory Files:
At stage three with have a list of shares with notes on whether or not we can read or write within them. When it comes to exposed data, we only care about the ability to read. With this information in mind, we're going to inventory exactly what exists in those shares and their sub folders.

#### Generalized Snippet

All Files
```PowerShell
$Path = '\\server1\backups'
Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue -Filter * | Select-Object FullName, Extension, Length, CreationTime, LastAccessTime, LastWriteTime
```

#### Sample Output
```PowerShell
PS C:\> Search-RemoteShare -ShareName \\server1\backups

FullName       : \\server1\backups\export.txt
Extension      : .txt
Length         : 64
CreationTime   : 1/7/2020 9:19:43 AM
LastAccessTime : 1/9/2020 5:05:20 AM
LastWriteTime  : 1/7/2020 9:19:43 AM

FullName       : \\server1\backups\application.exe
Extension      : .txt
Length         : 1458900
CreationTime   : 1/7/2020 9:19:43 AM
LastAccessTime : 1/9/2020 5:05:20 AM
LastWriteTime  : 1/7/2020 9:19:43 AM
If you want the full picture of what could be exposed, you're going to want to inventory all visible files, but we can dial this down to specific file extensions and set a max file size. If we only care about human readable files, such as txt and csv as a quick example, we can.
```

#### Generalized Output
```PowerShell
$Path = '\\server1\backups'
$FileSizeLimit = 100MB
$Extension = 'txt', 'csv'
$Extension | ForEach-Object { $RegEx += "\.{0}+$|" -f $_ }
$RegEx = $RegEx.Substring(0, $RegEx.Length - 1)

Get-ChildItem -Path $ShareName -Recurse -File -ErrorAction SilentlyContinue |
Where-Object { $_.Extension -match $RegEx -and $_.Length -le $FileSizeLimit } |
Select-Object FullName, Extension, Length, CreationTime, LastAccessTime, LastWriteTime
```

#### Sample Output
```PowerShell
PS C:\> Search-RemoteShare -ShareName '\\server1\share\' -Extension txt, csv -FileSizeLimit 100MB

FullName       : \\server1\backups\export.txt
Extension      : .txt
Length         : 64
CreationTime   : 1/7/2020 9:19:43 AM
LastAccessTime : 1/9/2020 5:05:20 AM
LastWriteTime  : 1/7/2020 9:19:43 AM
```

## Stage 4 - Scan Content:
The fourth step in this process, now that we have a list of files, is to scan them and flag whether or not they contain human readable sensitive data. We're going to accomplish this by using regular expressions. Within this function I've included a subset of expressions based on category and it could easily be expanded on to meet your needs.

To make this a speedy process, we're going to take advantage of the '-Raw' option of Get-Content, which reads in a file as a single line string, then we'll hit it with our regular expressions.

As a performance reference, on a generic virtual machine, I was able to scan a 69 MB file that contained over 400,000 rows in ~14 seconds. 

#### Generalized Snippet
```PowerShell
$Path = '\\server1\backups\export.txt'

$ContentScans = @{
SSN_NUMBER       = '\d{3}[-| ]\d{2}[-| ]\d{4}'
SSN_WORD	 = '^.*(ssn|social|security).*'
MRN_WORD	 = '^.*(mrn).*'
ID_WORD	         = '^.*(id).*'
DOB_NUMBER       = '^([1][12]|[0]?[1-9])[\/-]([3][01]|[12]\d|[0]?[1-9])[\/-](\d{4}|\d{2})'
DOB_WORD	 = '^.*(dob|birth).*'
PATIENT_WORD     = '^.*(patient).*'
AGE_WORD	 = '^.*(age).*'
RACE_WORD	 = '^.*(race).*'
GENDER_WORD      = '^.*(female|male).*'
VISIT_WORD       = '^.*(visit|admit|admission|discharge).*'
NAME_WORD        = '^.*(name|givenname|surname|first|last).*'
ADDRESS_WORD     = '^.*(address).*'
CITY_WORD        = '^.*(city).*'
STATE_WORD       = '^.*(state).*'
ZIP_WORD	 = '^.*(zip|zipcode).*'
COUNTRY_WORD     = '^.*(country).*'
EMAIL            = '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b'
}

$LoadFile = Get-Content -Path $Path -Raw
$Scan = New-Object System.Object
$Scan | Add-Member -MemberType NoteProperty -Name 'Path' -Value $Path
ForEach ($CS in $ContentScans.GetEnumerator())
{
	If ($LoadFile | Select-String $CS.Value)
	{
		$Flagged = $true
		$Value = $true
	}
	Else
	{
		$Value = $false
	}
    $Scan | Add-Member -MemberType NoteProperty -Name $CS.Name -Value $Value
}

$Scan | Add-Member -MemberType NoteProperty -Name 'Flagged' -Value $Flagged
Write-Output $Scan
```

#### Sample Output
```PowerShell
PS C:\> Invoke-ContentScan -path '\\server1\share\export.txt'

Path         : \\server1\share\export.txt
STATE_WORD   : True
DOB_WORD     : True
PATIENT_WORD : True
GENDER_WORD  : False
PASSWORD     : False
COUNTRY_WORD : False
MRN_WORD     : False
EMAIL        : True
DOB_NUMBER   : False
NAME_WORD    : True
SSN_WORD     : False
SSN_NUMBER   : False
VISIT_WORD   : True
ADDRESS_WORD : True
CITY_WORD    : True
ID_WORD      : True
ZIP_WORD     : False
Flagged      : True
```

## Usage Example
This is just a rough example using all four scripts to actively recon our network. When it comes to timing, this is going to vary depending on the device you're running this from, number of shares, visible shares and accessible files.

The first two scripts running against 100 servers completed in ~1.2 minutes. The third script you should plan on kicking this off overnight if you are expecting a significantly large number of files like 250k+. Finally, the fourth script was able to scan a 69MB file that had nearly 500,000 rows in 14 seconds. 

```Powershell
# Load Scripts
. .\Get-RemoteShare.ps1
. .\Test-RemoteShare.ps1
. .\Search-RemoteShare.ps1
. .\Invoke-ContentScan.ps1

## Inventory Visible Shares
$Threshold = [DateTime]::Today.AddDays(-14)
$Servers = Get-ADComputer -Filter {LastLogonDate -gt $Threshold -and OperatingSystem -like "*server*"} | Select-Object -ExpandProperty Name | Sort-Object

ForEach ($S in $Servers)
{
    Get-RemoteShare -ComputerName $S | Export-Csv ~/Desktop/VisibleShares.csv -NoTypeInformation -Append
}

## Test Share Permissions
$Shares = Import-CSV ~/Desktop/VisibleShares.csv | ? {$_.Results -like "\\*"} | Select -ExpandProperty Results

ForEach ($S in $Shares)
{
    Test-RemoteShare -ShareName $S -CanRead -CanWrite | Export-Csv ~/Desktop/ShareAccessRights.csv -NoTypeInformation -Append
}

## Inventory Accessible Files
$ReadableShares = Import-CSV ~/Desktop/ShareAccessRights.csv | ? {$_.CanRead -eq $true} | Select -ExpandProperty ShareName

ForEach ($R in $ReadableShares)
{
    Search-RemoteShare -ShareName $R | Export-Csv ~/Desktop/AccessibleFiles.csv -NoTypeInformation -Append
}

## Discover Sensitive Files
$AccessibleFiles = Import-CSV ~/Desktop/AccessibleFiles.csv | ? {$_.Extension -eq '.txt'} | Select -ExpandProperty FullName

ForEach ($A in $AccessibleFiles)
{
    Invoke-ContentScan -Path $A | Export-Csv ~/Desktop/SensitiveFiles.csv -NoTypeInformation -Append
}
```

# Wrapping it all up
What we were able to accomplish here was demonstrate how we can use PowerShell to create our own data discovery tool to help us locate where we might have exposures to sensitive data.

These advanced functions are built in a way where you could run them on demand or even better, set them up as a scheduled job that runs overnight. When it comes to SMB shares, they can be extremely useful when they're created appropriately, but can be very harmful if they're configured with open permissions.

Take your current strategy and look to see if there's any way for you to improve it, or even better, add levels of automation. Keep an eye out for the next commit where we expand the raw content scanning and add support for word documents and more. 

Be informed, be secure!
