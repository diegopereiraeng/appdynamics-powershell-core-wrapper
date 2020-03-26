Using module './Appdynamics.psm1'



$appdy = [Appdynamics]::new("https://customer.saas.appdynamics.com")

Write-Host  $(Get-Date)" - Started Script"
$apps = $appdy.GetApplications()

$start = Get-Date

$list = @(
    @{name = "HML_CORPORATE_MANAGEDPORTFOLIO"},
    @{name = "PRD_XP_EBIX"},
    @{name = "XP_Institution"},
    @{name = "PRD_CLEAR.FEEDS"},
    @{name = "HML_XP_PORTFOLIO"},
    @{name = "PRD_RICO.HB"},
    @{name = "Corporate_B2B"},
    @{name = "PRD_RICO.UMDF"},
    @{name = "PRD_XP.CLIENT_INFORMATION"},
    @{name = "HML_XP_CUSTOMERSERVICE"})

    $list = @(
    @{name = "HML_CORPORATE_MANAGEDPORTFOLIO"},
    @{name = "PRD_XP_EBIX"})


$metricALL = @{metricALL = "Overall Application Performance|*|*"; duration = "1600"}

#$results2 = Start-MultiThreadAppdyJobs -list $apps.applications.application -script './test-script-multithread.ps1' -maxThreads 40
#$results2 = Start-MultiThreadAppdyJobs -list $list -script './test-script-multithread.ps1' -maxThreads 40 -params $metricALL

$results2 = $appdy.GetAllTierPerformanceSummary("ALL","1600")

Write-Host  $(Get-Date)" - Finished Script"

$diff = New-TimeSpan -Start $start -End $(Get-Date)

Write-Output "Time difference is: $diff"
#Remove all jobs created.
Get-Job | Remove-Job


Write-Host "Results "$results2.count
foreach ($result in $results2) {
    $teste = [PSCustomObject]$result
    Write-Host $teste.metrics.keys
    foreach ($key in $teste.metrics.keys) {
        #Write-Host $teste.metrics[$key]
        Write-Host $key
    }
}

 