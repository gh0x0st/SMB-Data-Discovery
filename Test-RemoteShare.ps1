Function Test-RemoteShare
{
<#
	.SYNOPSIS
		Tests whether you're able to read the contents of or write to a share.

	.DESCRIPTION
		This function will attempt to read into a share as well as write a temp file that
	    will be deleted on successful runs, enabling you to discover misconfigured shares natively.

	.PARAMETER  ShareName
		The share name to run the tests against.
	
	.EXAMPLE
		PS C:\> Test-RemoteShare -ShareName \\server1\backups -CanWrite -CanRead

		ShareName              CanRead CanWrite
		---------              ------- --------
		\\server1\backups      True    True   
	
	.EXAMPLE
		PS C:\> Test-RemoteShare -ShareName \\server1\backups -CanRead

		ShareName              CanRead CanWrite
		---------              ------- --------
		\\server1\backups      True    Not Tested   	

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
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'default')]
		[System.String]$ShareName,
		[Parameter(Position = 1, Mandatory = $false, ParameterSetName = 'default')]
		[switch]$CanRead,
		[Parameter(Position = 2, Mandatory = $false, ParameterSetName = 'default')]
		[switch]$CanWrite
	)
	Begin
	{
		Try
		{
			[System.Array]$Results = @()
			[System.String]$TestCanRead = 'Not Tested'
			[System.String]$TestCanWrite = 'Not Tested'
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
			Switch ($PSBoundParameters.Keys | Where-Object { $_ -ne 'ShareName' })
			{
				'CanRead'
				{
					Try
					{
						If (Test-Path -Path $ShareName -ErrorAction Stop)
						{
							Get-ChildItem -Path $ShareName -ErrorAction Stop | Out-Null
							[System.String]$TestCanRead = $true
						}
						Else
						{
							[System.String]$TestCanRead = $false
						}
					}
					Catch [System.UnauthorizedAccessException]
					{
						[System.String]$TestCanRead = $False
					}
					Catch [System.IO.IOException]
					{
						[System.String]$TestCanRead = $False
					}
				}
				'CanWrite'
				{
					Try
					{
						[System.String]$Path = Join-Path $ShareName -ChildPath '\testcanwrite.txt'
						New-Item -Path $Path -ItemType File -Force -ErrorAction Stop | Out-Null
						Remove-Item $Path
						[System.String]$TestCanWrite = $True
					}
					Catch [System.ArgumentException]
					{
						If ($($_.Exception.Message) -eq 'The path is not of a legal form.')
						{
							[System.String]$TestCanWrite = $False
						}
					}
					Catch [System.UnauthorizedAccessException]
					{
						[System.String]$TestCanWrite = $False
					}
					Catch [System.IO.IOException]
					{
						[System.String]$TestCanWrite = $($_.Exception.Message)
					}
				}
			}
			$Results += [PSCustomObject]@{ 'ShareName' = $ShareName; 'CanRead' = $TestCanRead; 'CanWrite' = $TestCanWrite }
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
			Write-Output $Results
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
