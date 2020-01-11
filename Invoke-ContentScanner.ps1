Function Invoke-ContentScan
{
<#
	.SYNOPSIS
		Scans a target file for sensitive data.

	.DESCRIPTION
		This function will scan a target file for PHI/PII keywords using regex. If any are found
	    it will label the scan that passed to identify the content that was found.

	.PARAMETER  Path
		Designates the path of the file to scan.

	.EXAMPLE
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
	
	.EXAMPLE
        PS C:\> Invoke-ContentScan -path '\\server1\share\export.txt' | Export-CSV E:\Content-Scan.csv -Append
	
	.INPUTS
		System.String

	.OUTPUTS
		System.Object

	.NOTES
		Last Edit: 01/11/2020 @ 1330

	.LINK
		https://github.com/gh0x0st
#>
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory = $false)]
		[System.String]$Path
	)
	Begin
	{
		Try
		{
			[System.Boolean]$Flagged = $false
			[Hashtable]$ContentScans = @{
				SSN_NUMBER   = '\d{3}[-| ]\d{2}[-| ]\d{4}'
				SSN_WORD	 = '^.*(ssn|social|security).*'
				MRN_WORD	 = '^.*(mrn).*'
				ID_WORD	     = '^.*(id).*'
				DOB_NUMBER   = '^([1][12]|[0]?[1-9])[\/-]([3][01]|[12]\d|[0]?[1-9])[\/-](\d{4}|\d{2})'
				DOB_WORD	 = '^.*(dob|birth).*'
				PATIENT_WORD = '^.*(patient).*'
				AGE_WORD	 = '^.*(age).*'
				RACE_WORD	 = '^.*(race).*'
				GENDER_WORD  = '^.*(female|male).*'
				VISIT_WORD   = '^.*(visit|admit|admission|discharge).*'
				NAME_WORD    = '^.*(name|givenname|surname|first|last).*'
				ADDRESS_WORD = '^.*(address).*'
				CITY_WORD    = '^.*(city).*'
				STATE_WORD   = '^.*(state).*'
				ZIP_WORD	 = '^.*(zip|zipcode).*'
				COUNTRY_WORD = '^.*(country).*'
				EMAIL	     = '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b'
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
			[System.String]$LoadFile = Get-Content -Path $Path -Raw
			[System.Object]$Scan = New-Object System.Object
			$Scan | Add-Member -MemberType NoteProperty -Name 'Path' -Value $Path
			ForEach ($CS in $ContentScans.GetEnumerator())
			{
				If ($LoadFile | Select-String $CS.Value)
				{
					[System.Boolean]$Flagged = $true
					[System.Boolean]$Value = $true
				}
				Else
				{
					[System.Boolean]$Value = $false
				}
				$Scan | Add-Member -MemberType NoteProperty -Name $CS.Name -Value $Value
			}
			$Scan | Add-Member -MemberType NoteProperty -Name 'Flagged' -Value $Flagged
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