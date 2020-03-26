Using module './Appdynamics.psm1' 

#$auth = Get-AuthorizationHeader -pair "user@account:password"

$auth = "Basic "

$appdy = [Appdynamics]::new("https://customer.saas.appdynamics.com",$auth)

$appdy.GetLogin()

$apiKey = ""

$accountName = ""

$appdy.SetAnalytics($apiKey,$accountName)



Write-Host "Collecting metrics"
$metrics = $appdy.GetAllTierPerformanceSummary("ALL","60")
#$metrics = $appdy.GetTierPerformanceSummary("HML_CORPORATE_INVESTMENTFUNDS","1440")

Write-Host "Append Metrics"
$metrics2 = $appdy.AppendSummaryMetrics($metrics)

#Write-Host $metrics2 | Out-String

Write-Host "Creating Report"
$report = [string]($appdy.CreateTierReportCSV($metrics) | ConvertTo-Json) -replace 'null',0


$index = "test_xp_score_card"


#$schema = '{ "schema" : { "AppTier": "string", "Application": "string", "Tier": "string", "Calls": "integer", "Avg_RT": "integer", "Errors_Perc": "float", "Score_Card": "float", "Errors": "integer", "Slows": "integer","Very_Slows": "integer", "Stalls": "integer" } }'


#$resultSchema = $appdy.DeleteAnalyticsSchema($index)
#$resultSchema = $appdy.CreateAnalyticsSchema($index,$schema)


$appdy.PublishAnalyticsEvents($index,$report)


$report | Add-Content -Path ./test.json


