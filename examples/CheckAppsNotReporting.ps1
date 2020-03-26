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
$total_apps = $apps.applications.application.Count

Write-Host "Total Apps $total_apps"
foreach ($app in $apps.applications.application)
{
    Write-Progress -Id 1 -Activity "Collecting Metric from All application $total_apps from last $metricTime minutes" -Status "Checking for Apps not reporting metrics" -PercentComplete (($stepCounter / $total_apps) * 100)
    $metrics = $appdy.GetMetrics($app.id, $metric, $metricTime)
    
    if (-not ($null -eq $metrics.'metric-datas'.'metric-data'.metricValues.'metric-value')) {
        $sum = $metrics.'metric-datas'.'metric-data'.metricValues.'metric-Value'.sum
        #DEBUG#Write-Host $app.name",Calls per minute,"$sum        

        if ($mode -eq "Discovery") {
            $app.name | Out-File -Path "Reporting.log" -Append 
        }
        else {
            if ($app.name -notin $reporting) {
                #$app.name | Out-File -Path "New.log" -Append 
                $app.name | Out-File -Path "Reporting.log" -Append
            }
        }
        $count_reporting += 1
    }
    else {
        #DEBUG#Write-Host $app.name",No Calls,0"

        if ($mode -eq "Discovery") {
            $app.name | Out-File -Path "NotReporting.log" -Append 
        }
        else {
            if ($app.name -in $reporting) {
                (Get-Date -Format "dd/MM/yyyy,")+$app.name | Out-File -Path "Alarms.log" -Append 
                [PSCustomObject]$alarm = New-Object -TypeName PSObject -Property @{
                    Application = $app.name
                }
                $alarms += $alarm
            }
        }
        $count_not_reporting += 1
    }
    $stepCounter++
}

if ($mode -eq "FindNotReporting") {
    Write-Host "Historico Ultima verificacao:"
    Write-Host "Apps Reporting before: "$reporting.Count
    Write-Host "Apps Not Reporting before: "$not_reporting.Count
}
Write-Host (Get-Date -Format "dd/MM/yyyy HH:mm")
Write-Host "Apps Reporting: $count_reporting"
Write-Host "Apps Not Reporting: $count_not_reporting"
Write-Host "Apps alarming: " $alarms.Count

(Get-Date -Format "dd/MM/yyyy HH:mm") | Out-File -Append -Path "Summary.log"
"Apps Reporting: $count_reporting" | Out-File -Append -Path "Summary.log"
"Apps Not Reporting: $count_not_reporting" | Out-File -Append -Path "Summary.log"
"Apps alarming: "+$alarms.Count | Out-File -Append -Path "Summary.log"
$index = "localiza_not_reporting_apps_v1"


$schema = '{ "schema" : { "Application": "string" } }'

$alarms | ConvertTo-Json | Out-File -Path "Alarms.json"
$resultSchema = $appdy.DeleteAnalyticsSchema($index)
$resultSchema = $appdy.CreateAnalyticsSchema($index,$schema)
if ($mode -eq "Discovery") {
    $resultSchema = $appdy.CreateAnalyticsSchema($index,$schema)
}
else {
    Write-Host "Publishing alarms"
    $appdy.PublishAnalyticsEvents($index,($alarms | ConvertTo-Json))    
}




