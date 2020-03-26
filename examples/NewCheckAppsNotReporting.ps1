Using module './Appdynamics.psm1' 

$mode = "FindNotReporting"

#$mode = "Discovery"

$auth = "Basic "

$auth = Get-AuthorizationHeader -pair "user@account:password

$appdy = [Appdynamics]::new("https://customer.saas.appdynamics.com",$auth)

# Analytics
$apiKey = ""

$accountName = ""

$result = $appdy.SetAnalytics($apiKey,$accountName)

# Login
$result = $appdy.GetLogin()

Write-Host "Login="$result

#Code
$apps = $appdy.GetApplications()

$metricTime = "1440" # 1 dia

$metric = "Overall Application Performance|Calls per Minute"

$reporting = @()
$not_reporting = @()
$alarms = @()

$count_reporting = 0
$count_not_reporting = 0

if ($mode -eq "FindNotReporting") {
    if ([System.IO.File]::Exists("Reporting.log") -And [System.IO.File]::Exists("NotReporting.log") ) {
        [string[]]$reporting = Get-Content -Path "Reporting.log"
        [string[]]$not_reporting = Get-Content -Path "NotReporting.log"
    }
    else {
        Write-Host "No Discovery Files, please run in Discovery mode first"
        Pause
        Exit-PSHostProcess
    }
}
$stepCounter = 0

$app_metrics = $apps.applications.application | ForEach-Object -ThrottleLimit 8 -Parallel {
    $test = $using:appdy
    $metrics = ($test.GetMetrics($_.id, $using:metric, $using:metricTime))
    Write-Host "Metric: "$using:metric" , App: "($_.name)
    
    if (-not ($null -eq $metrics.'metric-datas'.'metric-data'.metricValues.'metric-value')) {
        $sum = $metrics.'metric-datas'.'metric-data'.metricValues.'metric-Value'.sum
        #DEBUG#Write-Host $app.name",Calls per minute,"$sum        
        $_.name+",Calls per minute,"+$sum | Out-File -Path "test2.log" -Append

        if ($using:mode -eq "Discovery") {
            $_.name | Out-File -Path "test.log" -Append 
        }
        else {
            if ($_.name -notin $reporting) {
                #$app.name | Out-File -Path "New.log" -Append 
                $_.name | Out-File -Path "test.log" -Append
            }
        }
    }

    #$appdy.GetMetrics($_.id, $metric, $metricTime)
}

Write-Host $app_metrics.Count




