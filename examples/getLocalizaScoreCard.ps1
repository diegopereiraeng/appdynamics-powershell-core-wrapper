Using module './Appdynamics.psm1' 

$auth = "Basic "

$auth = Get-AuthorizationHeader -pair "user@account:password"

$appdy = [Appdynamics]::new("https://customer.saas.appdynamics.com",$auth)

$result = $appdy.GetLogin()

$apiKey = ""

$accountName = ""

$result = $appdy.SetAnalytics($apiKey,$accountName)

#Write-Host "Collecting metrics"
$metrics = $appdy.GetAllTierPerformanceSummary("ALL","60")

#Write-Host "Append Metrics"
$metrics2 = $appdy.AppendSummaryMetrics($metrics)

#Write-Host "Creating Report"
$report = [string]($appdy.CreateTierReportCSV($metrics) | ConvertTo-Json) -replace 'null',0

$index = "localiza_score_card_v1"


$schema = '{ "schema" : { "AppTier": "string", "Application": "string", "Tier": "string", "Calls": "integer", "Avg_RT": "integer", "Errors_Perc": "float", "Score_Card": "float", "Errors": "integer", "Slows": "integer","Very_Slows":
 "integer", "Stalls": "integer" } }'


$resultSchema = $appdy.DeleteAnalyticsSchema($index)

$resultSchema = $appdy.CreateAnalyticsSchema($index,$schema)


$result = $appdy.PublishAnalyticsEvents($index,$report)