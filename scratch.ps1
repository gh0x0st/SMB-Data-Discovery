Function Write-Weight{
	param (
		[Parameter(Position = 0, Mandatory = $false)]
		[System.String]$Val
	)	
	$ret = 0.0
	switch($Val) {
		"PASS_7_WEAK" {$ret = 5.0; Break}
		"DOB_NUMBER" { $ret = 0.5; Break}
		"PHONE_NUMBER" {$ret = 1.5;Break}
		"EMAIL" { $ret = 2.0;Break}
		"ACH" { $ret = 5.0;Break} 
		"PRIVATE_KEYS" {$ret = 5.5; Break}
		"PASS_8_CMPLX" {$ret = 5.0;Break}
		"CC_MS_VISA" {$ret = 5.5; Break}
		Default {if ($Val.EndsWith("_WORD")){$ret = 0.2};Break}		
	}

	return $ret
}

Write-Weight -Val "PRIVATE_KEYS"