################################################################################################
#
# This Azure Automation Runbook is based on the work done by Christer Ljung and Tom Hollander
# https://blogs.msdn.microsoft.com/tomholl/2016/03/08/analysing-enterprise-azure-spend-by-tags/
#
################################################################################################
Param(
   [string]$StorageAccountName = "SomeAccount",
   [string]$StorageContainerName = "SomeContainer",
   [string]$StorageAccountKey = "qmSRU1iaiuF9O9hXWmdN2vqxW30aTdRMD6gQZqYBoFJSruHWSrwJQYRUv9t8xYRqmDSR8+uabfBQx9iOydCEcQ==",
   [string]$EnrollmentNbr = "SomeEnrollmentNumber",
   [string]$Key = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IlE5WVpaUnA1UVRpMGVPMmNoV19aYmh1QlBpWSJ9.eyJFbnJvbGxtZW50TnVtYmVyIjoiNTI0OTQ2MjkiLCJJZCI6IjcwNmVmZjg0LTU1YjctNDZmOC05M2M3LTIxZTBmMTlmOGI2YiIsIlJlcG9ydFZpZXciOiJFbnRlcnByaXNlIiwiUGFydG5lcklkIjoiIiwiRGVwYXJ0bWVudElkIjoiIiwiQWNjb3VudElkIjoiIiwiaXNzIjoiZWEubWljcm9zb2Z0YXp1cmUuY29--- Secret Key ------ 4cCI6MTUwMzMwMjc3OSwibmJmIjoxNDg3NjY0Mzc5fQ.fuqd7CQxGCkkyibLn8MY3bcldLNBTnXAGHyqg_7_gy-JVYFl-vm8Uu_G13nfOm8co9CSeTzYOFZEAsMgIhpuNxL5o91JFJTZM1ExthPgqaw-tbpjJ9H3-F_tdI0DdwNQGK-QiFpGOpnNTfjW9CalefjNJaiuVKoXKcpJ7hRehC50RuIESvFud3eMn64FCi4U3fDJyUSohzs990pDOEyytGa44wwczm8Bqi9ZBi08j7aurrAd8v3ocLrLxix7lfY3SyVFMS6PTRY_ooZj22HzNlnOwIarhLu1s__1QbKkMVSx7tCanYMC-mRWSO2VHSkRH51QMc3K14mxDIb9KA246w",
   [string]$Month = "6"
)
# access token is "bearer " and the the long string of garbage
$AccessToken = "Bearer $Key"
$urlbase = 'https://ea.azure.com'
$csvAll = @()

Write-Verbose "$(Get-Date -format 's'): Azure Enrollment $EnrollmentNbr"

# function to invoke the api, download the data, import it, and merge it to the global array
Function DownloadUsageReport( [string]$LinkToDownloadDetailReport, $csvAll )
{
		Write-Verbose "$(Get-Date -format 's'): $urlbase/$LinkToDownloadDetailReport)"
		$webClient = New-Object System.Net.WebClient
		$webClient.Headers.add('api-version','1.0')
		$webClient.Headers.add('Authorization', "$AccessToken")
		$data = $webClient.DownloadString("$urlbase/$LinkToDownloadDetailReport")
		# remove the funky stuff in the leading rows - skip to the first header column value
		$pos = $data.IndexOf("AccountOwnerId")
		$data = $data.Substring($pos-1)
		# convert from CSV into an ps variable
		$csvM = ($data | ConvertFrom-CSV)
		# merge with previous
		$csvAll = $csvAll + $csvM
		Write-Verbose "Rows = $($csvM.length)"
		return $csvAll
}

if ( $Month -eq "" )
{
	# if no month specified, invoke the API to get all available months
	Write-Verbose "$(Get-Date -format 's'): Downloading available months list"
	$webClient = New-Object System.Net.WebClient
	$webClient.Headers.add('api-version','1.0')
	$webClient.Headers.add('Authorization', "$AccessToken")
	$months = ($webClient.DownloadString("$urlbase/rest/$EnrollmentNbr/usage-reports") | ConvertFrom-Json)

	# loop through the available months and download data. 
	# List is sorted in most recent month first, so start at end to get oldest month first 
	# and avoid sorting in Excel
	for ($i=$months.AvailableMonths.length-1; $i -ge 0; $i--) {
		$csvAll = DownloadUsageReport $($months.AvailableMonths.LinkToDownloadDetailReport[$i]) $csvAll
	}
}
else
{
	# Month was specified as a parameter, so go ahead and just download that month
	$csvAll = DownloadUsageReport "rest/$EnrollmentNbr/usage-report?month=$Month&type=detail" $csvAll
}
Write-Host "Total Rows = $($csvAll.length)"

# data is in US format wrt Date (MM/DD/YYYY) and decimal values (3.14)
# so loop through and convert columns to local format so that Excel can be happy
Write-verbose "$(Get-Date -format 's'): Fixing datatypes..."
for ($i=0; $i -lt $csvAll.length; $i++) {
	$csvAll[$i].Date = [datetime]::ParseExact( $csvAll[$i].Date, 'dd/mm/yyyy', $null).ToString("d")
	$csvAll[$i].ExtendedCost = [float]$csvAll[$i].ExtendedCost
	$csvAll[$i].ResourceRate = [float]$csvAll[$i].ResourceRate
	$csvAll[$i].'Consumed Quantity' = [float]$csvAll[$i].'Consumed Quantity'

    # Expand tags
    $tags = $csvAll[$i].Tags | ConvertFrom-Json
    if ($tags -ne $null) {
         $tags.psobject.properties | ForEach { 
            $tagName = "Tag-$($_.Name)" 
            Add-Member -InputObject $csvAll[$i] $tagName $_.Value 
            # Add to first row, as that's what is used to format the CSV
            if ($csvAll[0].psobject.Properties[$tagName] -eq $null) {
                Add-Member -InputObject $csvAll[0] $tagName $null -Force
            }
        }
    }

}

# save the data to a CSV file
$filename = ".\$($EnrollmentNbr)_UsageDetail$($Month)_$(Get-Date -format 'yyyyMMdd').csv"
Write-Host "$(Get-Date -format 's'): Saving to file $filename"
$csvAll | Export-Csv $filename -NoTypeInformation -Delimiter ","

write-output "Backup Done: Location: $filename"

#import the Azure Module
Import-Module Azure

#write-output $csvAll

$ctx = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
Set-AzureStorageBlobContent -File $filename -Container $StorageContainerName -Blob "Billing.csv" -Context $ctx -Force


