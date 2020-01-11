Function Get-RemoteShare
{
<#
	.SYNOPSIS
		Scans a server for a list of visible shares.

	.DESCRIPTION
		This function is a wrapper around the windows native net command to list visible shares in
	    a format that is easy to read and to implement in other scripted workflows without the
	    need for admin access.
	
	.PARAMETER  ComputerName
		The remote device to query against.
	
	.EXAMPLE
		PS C:\> Get-RemoteShare -ComputerName server1

		ComputerName Results                                  
		------------ -------                                  
		server1      \\server1\temp
		server1      \\server1\backups

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
		[System.String]$ComputerName
	)
	Begin
	{
		Try
		{
			[System.Array]$Results = @()
			[System.Array]$Resources = net view \\$ComputerName 2>&1
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
			If (($Resources | Select-Object -First 1) -eq 'There are no entries in the list.')
			{
				[System.Array]$Results += [PSCustomObject]@{ 'ComputerName' = $ComputerName; 'Results' = 'There are no entries in the list.' }
			}
			ElseIf (($Resources -replace '\r' | Select-Object -Last 1) -like "*The network path was not found*")
			{
				[System.Array]$Results += [PSCustomObject]@{ 'ComputerName' = $ComputerName; 'Results' = 'The network path was not found.' }
			}
			Else
			{
				($Resources | Select-Object -Skip 7 | Select-Object -SkipLast 2) -replace '\s\s+', ',' | ForEach-Object {
					[System.Array]$Line = (($_) -split ',')
					If ($Line[1] -eq 'Disk')
					{
						[System.String]$Share = "{0}$ComputerName\{1}" -f '\\', $Line[0]
						[System.Array]$Results += [PSCustomObject]@{ 'ComputerName' = $ComputerName; 'Results' = $Share }
					}
				}
			}
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