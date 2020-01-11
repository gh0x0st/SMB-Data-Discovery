Function Search-RemoteShare
{
<#
	.SYNOPSIS
		Scans a target share and outputs the files that are accessible.

	.DESCRIPTION
		This function scans a target directory for all files or a subset of files that match given 
	    extensions and file size limits. The output contains the meta data for the location, extension
	    creation and acccess timestamps as well as the size of the file.

	.PARAMETER  Path
		Designates the path to scan against.

	.PARAMETER  Extension
		Designates the extension(s) you want to scan against.
	
	.PARAMETER FileSizeLimit
		Designates the max file size that either mode is allowed to report on. 	
	
	.PARAMETER Mode
		Designates whether the function's scanning mode will be content scanner or an inventory scan.
	
	.EXAMPLE
		PS U:\> Search-RemoteShare -ShareName '\\server1\share\' | Format-Table -AutoSize

		FullName                                    Extension Length CreationTime        LastAccessTime      LastWriteTime      
		--------                                    --------- ------ ------------        --------------      -------------      
		\\server1\share\export.txt                  .txt          64 1/7/2020 9:19:43 AM 1/9/2020 5:05:20 AM 1/7/2020 9:19:43 AM
		\\server1\share\application.exe             .exe       14589 1/7/2020 9:19:43 AM 1/9/2020 5:05:20 AM 1/7/2020 9:19:43 AM
	
	.EXAMPLE
		PS U:\> Search-RemoteShare -ShareName '\\server1\share\' -Extension txt -FileSizeLimit 100MB | Format-Table -AutoSize

		FullName                                    Extension Length CreationTime        LastAccessTime      LastWriteTime      
		--------                                    --------- ------ ------------        --------------      -------------      
		\\server1\share\export.txt                  .txt          64 1/7/2020 9:19:43 AM 1/9/2020 5:05:20 AM 1/7/2020 9:19:43 AM
	
	.INPUTS
		System.String

	.OUTPUTS
		System.Output

	.NOTES
		Last Edit: 01/11/2020 @ 1330

	.LINK
		https://github.com/gh0x0st
#>
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