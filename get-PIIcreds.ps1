
# Import Modules 
# Module ingests data from Office apps 

if ((Get-Module -ListAvailable -Name ImportExcel)){
		Write-Host -ForegroundColor Green "[+] Module is installed!"
	} else {
			Write-Host  -ForegroundColor Yellow "[-] Module is not installed, will try to install "
			Install-Module -Name ImportExcel -Scope CurrentUser -Force
				if ((Get-Module -ListAvailable -Name ImportExcel)){
				Write-Host -ForegroundColor Green "[+] Module has been installed!"					
				} else {
					Write-Host -ForegroundColor Red "[!] Unable to install module, error:"
					Write-Host -ForegroundColor Red "[!] $Error"
					Write-Host -ForegroundColor Red "[!] Correct issue and try again!"
					Exit
				}
	} 		
	

if ((Get-Module -ListAvailable -Name PSWriteOffice)) {
		Write-Host -ForegroundColor Green "[+] Module is installed!"
	} else {
			Write-Host  -ForegroundColor Yellow "[-] Module is not installed, will try to install "
			Install-Module  -Name PSWriteOffice -Scope CurrentUser -Force
			if ((Get-Module -ListAvailable -Name PSWriteOffice)){
				Write-Host -ForegroundColor Green "[+] Module has been installed!"					
				} else {
					Write-Host -ForegroundColor Red "[!] Unable to install module, error:"
					Write-Host -ForegroundColor Red "[!] $Error"
					Write-Host -ForegroundColor Red "[!] Correct issue and try again!"
					Exit
				}				
		} 		
	

# Functions 

# Creates an inventory of files by extension type passed

Function IsFolderWritable ($test_folder) {

	# Check if folder is a folder
	If (-Not (Test-Path $test_folder -pathType container)) { 		
    Return $false
	}
	
	# Create random test file name
	$test_tmp_filename = "writetest-"+[guid]::NewGuid()
	$test_filename = (Join-Path $test_folder $test_tmp_filename)
	
	Try { 
		# Try to add a new file
		[io.file]::OpenWrite($test_filename).close()
		Write-Host -ForegroundColor Green "[+] Writable:" $test_folder
		# Remove test file
		Remove-Item -ErrorAction SilentlyContinue $test_filename -Force
    Return $true
		if (Test-Path $test_filename and $verbose) { 
			Write-Host -ForegroundColor Yellow "[*] Failed to delete test file: " $test_filename
		}
	}
	Catch {
		# Report error?
    Return $false
		if ($verbose) { 
			Write-Host -ForegroundColor Red "[-] Not writable: " $test_folder
		}
	}
}
Function Search-RemoteShare
{

	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory = $false)]
		[System.String]$ShareName,
		[Parameter(Position = 1, Mandatory = $false)]
		[System.Array]$Extension,
		[Parameter(Position = 2, Mandatory = $false)]
		[System.Double]$FileSizeLimit = [double]::PositiveInfinity
	)
	Begin
	{
		Try
		{
			[System.Array]$Inventory = @()
			If ($Extension)
			{
				$Extension | ForEach-Object { $RegEx += "\.{0}+$|" -f $_ }
				[System.String]$RegEx = $RegEx.Substring(0, $RegEx.Length - 1)
			}
			Else
			{
				[System.String]$RegEx = '.*'
			}
		}
		Catch
		{
			Write-Output "[!]$(Get-Date -Format '[MM-dd-yyyy][HH:mm:ss]') - ScriptLine: $($_.InvocationInfo.ScriptLineNumber) | ExceptionType: $($_.Exception.GetType().FullName) | ExceptionMessage: $($_.Exception.Message)"
			[System.GC]::Collect()
			Break
		}
	}
	Process
	{
		Try
		{
			[System.Array]$Inventory = Get-ChildItem -Path $ShareName -Recurse -File -ErrorAction SilentlyContinue |
			Where-Object { $_.Extension -match $RegEx -and $_.Length -le $FileSizeLimit } |
			Select-Object FullName, Extension, Length, CreationTime, LastAccessTime, LastWriteTime
		}
		Catch
		{
			Write-Output "[!]$(Get-Date -Format '[MM-dd-yyyy][HH:mm:ss]') - ScriptLine: $($_.InvocationInfo.ScriptLineNumber) | ExceptionType: $($_.Exception.GetType().FullName) | ExceptionMessage: $($_.Exception.Message)"
			[System.GC]::Collect()
			Break
		}
	}
	End
	{
		Try
		{
			If ($Inventory)
			{
				Write-Output $Inventory
			}
		}
		Catch
		{
			Write-Output "[!]$(Get-Date -Format '[MM-dd-yyyy][HH:mm:ss]') - ScriptLine: $($_.InvocationInfo.ScriptLineNumber) | ExceptionType: $($_.Exception.GetType().FullName) | ExceptionMessage: $($_.Exception.Message)"
			Break
		}
		Finally
		{
			[System.GC]::Collect()
		}
	}
}


Function Get-FileContent{
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory = $false)]
		[System.Io.FileInfo]$Path
	)
	Begin
	{
    	$getFunctionName = '{0}' -f $MyInvocation.MyCommand
		Write-Host -ForegroundColor Green "[+] INFO: Function $getFunctionName started." 
 	}  
	Process {
		Try {
				
				$ext = $path.Extension
				$doc = ''
				$rstring = switch ($ext) {
					".csv" { $doc = Get-Content -Path $Path -Raw; [System.String]$rstrings = $doc;break; }
					".txt" { $doc = Get-Content -Path $Path -Raw; [System.String]$rstrings = $doc;break; }
					".docx" { $doc = Get-OfficeWord -FilePath $Path; [System.String]$rstrings = $doc.Paragraphs.Text; $doc.Dispose();break; }
					".xlsx" { $doc = Import-Excel -Path $Path -NoHeader | Out-String; [System.String]$rstrings = $doc;break; }		
					Default {[System.String]$rstrings = Get-Content -Path $Path -Raw;break;}
				}
				$rstring
		} 
		Catch {
			Write-Host -ForegroundColor Red "[?] $_.Exception"
			Break
		}	
	} 
	end {
		# Write-Host $rstrings	
		$rstrings
	}
}
# Function scans file for defined PII REGEX, creates object per file scanned
Function Write-Weight{
	param (
		[Parameter(Position = 0, Mandatory = $false)]
		[System.String]$Val
	)	
	$ret = 0.0
	switch($Val) {
		"PASS_WEAK" {$ret = 5.0; Break}
		"DOB_NUMBER" { $ret = 0.5; Break}
		"PHONE_NUMBER" {$ret = 1.5;Break}
		"EMAIL" { $ret = 2.0;Break}
		"ACH" { $ret = 5.0;Break} 
		"PRIVATE_KEYS" {$ret = 5.5; Break}
		"PASS_CMPLX" {$ret = 5.0;Break}
		"CC_MS_VISA" {$ret = 5.5; Break}
		Default {if ($Val.EndsWith("_WORD")){$ret = 0.2};Break}		
	}

	return $ret
}

Function Invoke-ContentScan
{

	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory = $false)]
		[System.String]$Path
	)
	Begin
	{
		Try
		{
			$Weight = 0.0
			[Hashtable]$ContentScans = @{
				SSN_NUMBER    = '\d{3}[-| ]\d{2}[-| ]\d{4}'
				SSN_WORD	  = '^.*(ssn|social|security).*'
				DOB_NUMBER    = '^([1][12]|[0]?[1-9])[\/-]([3][01]|[12]\d|[0]?[1-9])[\/-](\d{4}|\d{2})'
				DOB_WORD	  = '^.*(dob|birth).*'				
				AGE_WORD	  = '^.*(age).*'				
				NAME_WORD     = '^.*(name|givenname|surname|first|last).*'
				ACH           = '^[0-9]{9,18}$'
				ADDRESS_WORD  = '^.*(address).*'
				CITY_WORD     = '^.*(city).*'
				STATE_WORD    = '^.*(state).*'
				ZIP_WORD	  = '^.*(zip|zipcode).*'
				BANKING_WORD  = '^.*(bank|ach|account)'
				PHONE_NUMBER  = '^(1\s?)?(\d{3}|\(\d{3}\))[\s\-]?\d{3}[\s\-]?\d{4}$'
				EMAIL	      = '([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$'
                PASSWORD_WORD = '\b(?:password|passwd|pwd|pass)\b'
                SECRET_WORD   = '^.*(secret|secretkey|private_key|aws_access_key_id|aws_session_tokens).*'
                PRIVATE_KEYS  = '\s*(\bBEGIN\b).*(PRIVATE KEY\b)\s*'
				PASS_CMPLX  = "(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+,\-./:;<=>?@\[\]\\\{\}\|~])[^\s]{8,}$"				
                PASS_WEAK   = '(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{4,8}$'
                CC_WORD       = '^.*(cc|credit|card|ccn).*'
        		CC_MS_VISA    = '(?:\d[ -]*?){13,16}'                
			}
		}
		Catch
		{
			Write-Output "[!]$(Get-Date -Format '[MM-dd-yyyy][HH:mm:ss]') - ScriptLine: $($_.InvocationInfo.ScriptLineNumber) | ExceptionType: $($_.Exception.GetType().FullName) | ExceptionMessage: $($_.Exception.Message)"
			[System.GC]::Collect()
			Break
		}
	}
	Process
	{
		Try
		{
			[System.String]$LoadFile = Get-FileContent -Path $Path
			[System.Object]$Scan = New-Object System.Object
			$Scan | Add-Member -MemberType NoteProperty -Name 'Path' -Value $Path
			ForEach ($CS in $ContentScans.GetEnumerator())
			{
				If ($LoadFile | Select-String $CS.Value)
				{
						
					$Weight += Write-Weight -Val $CS.Key					
					[System.Boolean]$Value = $true					
				}
				Else
				{
					[System.Boolean]$Value = $false
				}
				$Scan | Add-Member -MemberType NoteProperty -Name $CS.Name -Value $Value
			}
			$Scan | Add-Member -MemberType NoteProperty -Name 'Weight' -Value $Weight
		}
		Catch
		{
			Write-Output "[!]$(Get-Date -Format '[MM-dd-yyyy][HH:mm:ss]') - ScriptLine: $($_.InvocationInfo.ScriptLineNumber) | ExceptionType: $($_.Exception.GetType().FullName) | ExceptionMessage: $($_.Exception.Message)"
			[System.GC]::Collect()
			Break
		}
	}
	End
	{
		Try
		{
			Write-Output $Scan
		}
		Catch
		{
			Write-Output "[!]$(Get-Date -Format '[MM-dd-yyyy][HH:mm:ss]') - ScriptLine: $($_.InvocationInfo.ScriptLineNumber) | ExceptionType: $($_.Exception.GetType().FullName) | ExceptionMessage: $($_.Exception.Message)"
			Break
		}
		Finally
		{
			[System.GC]::Collect()
		}
	}
}


#----------------------------------------Share or file location-------------------------------------------------
$r =  Get-Date -UFormat "%s"
$ownPath = Read-Host -Prompt "Root path for share"
$creds = Get-Credential 
$credsPs = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $creds.UserName, $creds.Password
While($true){
	try{
		Write-Host -ForegroundColor Blue "[.] Connecting to remote share `"$ownPath`""
		$driveMap = New-PSDrive -Name $r -PSProvider "FileSystem" -Root $ownPath -Credential $credsPs
		if($driveMap){		
			Write-Host -ForegroundColor Green "[+] Connected to $driveMap"
		}
		else{
			throw [System.ComponentModel.Win32Exception]::new(0x80004005)
		}
		Break
	} 
	catch{
		Write-host -ForegroundColor Red "[!] Unable to connect, error:"
		Write-Host $_
		Write-Host -ForegroundColor Red "[!] Please try new path and or credential"
		Exit
	}
}

#------------------------------------------Report Path----------------------------------------------------------
Do {
	$reportPath = Read-Host -Prompt "Please provide report output path" 
	if(IsFolderWritable($reportPath)){
	  Write-Host -ForegroundColor Green "[+] $reportPath  is valid"    
	  $pathTrue = $true
	} Else {
	  Write-Host -ForegroundColor Yellow "[-] $reportPath  is invalid, try again"
	  $pathTrue = $false
	}
  } Until($pathTrue)

#--------------------------------------------Script--------------------------------------------------------------
$s = @()
$ot = @()
$s= Search-RemoteShare -ShareName $ownPath -Extension txt,csv,docx,xlsx -FileSizeLimit 100MB #| Format-Table -AutoSize

forEach($file in $s.FullName){
    $ot+=Invoke-ContentScan -path $file 
	#$ot +=$a
}
$rfileName = "PIIResult" + '_' + $r + '.csv'
$fileName = Join-Path $reportPath  $rfileName
Write-Host -ForegroundColor Green "[+] Writing report file `"$fileName`""
$ot | Export-Csv -Path $fileName -NoTypeInformation
 Write-Host -ForegroundColor Blue "[.] Cleaning up..." 
 Remove-PSDrive -Name $driveMap.Name
 Write-Host -ForegroundColor Blue "[+] Done"