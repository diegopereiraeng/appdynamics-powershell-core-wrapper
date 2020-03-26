Using module './Appdynamics.psm1' 

#$auth = Get-AuthorizationHeader -pair "user@account:password"

$auth = "Basic "

$appdy = [Appdynamics]::new("https://customer.saas.appdynamics.com",$auth)

$appdy.GetLogin()



$events = $appdy.GetAllAppsEvents(60)
$report = @()

#$events | Add-Content -Path ./events.json
#$events | ConvertTo-JSON -Compress | Out-File events.json -Encoding utf8

#$events = Get-Content -Path ./events.json | ConvertFrom-Json

foreach ($eventsJSON in $events) {
    $appEvents = $eventsJSON | ConvertFrom-Json
    foreach ($appEvent in $appEvents) {

        $appName = ""
        $tierName = ""
        $event = $appEvent

        if ($event.affectedEntities[0].entityType -eq "APPLICATION_COMPONENT") {
            $tierName = $event.affectedEntities[0].name
            $appName = $event.affectedEntities[1].name
        }
        else {
            $tierName = $event.affectedEntities[1].name
            $appName = $event.affectedEntities[0].name
        }
        $report += [PSCustomObject]@{AppTier = "$appName-$tierName";Application = $appName;Tier = $tierName;Summary = $event.summary; EventTime = $event.eventTime}
    }
}

#$report | Add-Content -Path ./report_events.json

$index = "xp_deployment_v1"

$apiKey = ""

$accountName = ""

$schema = '{ 
    "schema" : 
    { 
        "AppTier": "string", 
        "Application": "string", 
        "Tier": "string", 
        "Summary": "string",
        "EventTime" "date"
    } 
}'

$schema = '{ "schema" : { "AppTier": "string", "Application": "string", "Tier": "string", "Summary": "string", "EventTime": "date" } }'


$appdy.SetAnalytics($apiKey,$accountName)

$appdy.CreateAnalyticsSchema($index,$schema)

$appdy.PublishAnalyticsEvents($index,($report | ConvertTo-Json ))


