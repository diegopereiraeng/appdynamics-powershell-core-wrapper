Using module './Appdynamics.psm1' 

$auth = Get-AuthorizationHeader -pair "user@account:password"

$appdy = [Appdynamics]::new("https://customer.saas.appdynamics.com",$auth)

$appdy.GetLogin()

$apiKey = ""

$accountName = ""

$appdy.SetAnalytics($apiKey,$accountName)

$startTime = (([int](Get-Date -UFormat "%s")) * 1000) + 60000
$startTime

$results = $appdy.GetAnalyticsEvents('SELECT series(eventTimestamp, "1m") AS Time, substring(browserRecords.pagename, 19) AS "Page Name", distinctcount(sessionguid) AS "Active Sessions" FROM web_session_records WHERE browserRecords.pagename REGEXP "portal.*"',"start=$startTime")

foreach ($result in $results.results) {
    Write-Host ($result | ConvertTo-Json)
} 

$result2 = ($results | ConvertTo-Json)

$result2

$schema = '{ 
            "schema" : 
            { 
                "Application": "string", 
                "Tier": "string", 
                "Calls": "integer", 
                "Avg_RT": "integer", 
                "Errors_Perc": "float", 
                "Score_Card": "float", 
                "Errors": "integer", 
                "Slows": "integer",
                "Very_Slows": "integer", 
                "Stalls": "integer" 
            } 
}'

#$schema = '{"schema" : { "id": "string", "productBrand": "string", "userRating": "integer", "price": "float", "productName": "string", "description": "string" } }'
$schema
#$result3 = $appdy.CreateAnalyticsSchema("teste_score_card2",$schema)

#$appdy.GetAnalyticsSchema($result3) | ConvertTo-Json

#$appdy.DeleteAnalyticsSchema($result3)

#$appdy.DeleteAnalyticsSchema("teste_score_card")


<# $report = (Import-Csv ./tiers4.csv | ConvertTo-Json)

$report #>

$report = Get-Content ./test.json

<# Write-Host "Collecting metrics"
$metrics = $appdy.GetAllTierPerformanceSummary("ALL","1440")
#$metrics = $appdy.GetTierPerformanceSummary("HML_CORPORATE_INVESTMENTFUNDS","1440")

Write-Host "Append Metrics"
$metrics2 = $appdy.AppendSummaryMetrics($metrics)

#Write-Host $metrics2 | Out-String

Write-Host "Creating Report"
$report = [string]($appdy.CreateTierReportCSV($metrics) | ConvertTo-Json) -replace 'null',0

$report | Add-Content -Path ./test.json #>

$data1 = '[
    {
      "Application": "XPVP_PensionFunds",
      "Tier": "XPVP.PensionFunds.Core",
      "Calls": 114668,
      "Avg_RT": 0,
      "Errors_Perc": 0.0,
      "Score_Card": 100.0,
      "Errors": 0,
      "Slows": 1,
      "Very_Slows": 1,
      "Stalls": 0
    },
    {
      "Application": "PRD_XP.HomeBroker",
      "Tier": "Mídia/portal",
      "Calls": 6,
      "Avg_RT": 37,
      "Errors_Perc": 0.0,
      "Score_Card": 100.0,
      "Errors": 0,
      "Slows": 0,
      "Very_Slows": 0,
      "Stalls": 0
    }
  ]'

$data =  '[{"Application": "XPVP_PensionFunds","Tier": "XPVP.PensionFunds.Core","Calls": 114668,"Avg_RT": 0,"Errors_Perc": 0.0,"Score_Card": 100.0,"Errors": 0,"Slows": 1,"Very_Slows": 1,"Stalls": 0}]'

$data3 = '[{"Application":"XPVP_PensionFunds","Tier":"XPVP.PensionFunds.Core","Calls":114668,"Avg_RT":0,"Errors_Perc":0.0,"Score_Card":100.0,"Errors":0,"Slows":1,"Very_Slows":1,"Stalls":0},{"Application":"PRD_XP.HomeBroker","Tier":"Mídia/portal","Calls":6,"Avg_RT":37,"Errors_Perc":0.0,"Score_Card":100.0,"Errors":0,"Slows":0,"Very_Slows":0,"Stalls":0}]'
$data3 = '[{"Application":"XPVP_PensionFunds","Tier":"XPVP/PensionFunds.Core","Calls":114668,"Avg_RT":0,"Errors_Perc":0.0,"Score_Card":100.0,"Errors":0,"Slows":1,"Very_Slows":1,"Stalls":0},{"Application":"PRD_XP.HomeBroker","Tier":"Mídia/portal","Calls":6,"Avg_RT":37,"Errors_Perc":0.0,"Score_Card":100.0,"Errors":0,"Slows":0,"Very_Slows":0,"Stalls":0}]'

$data3 = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($data3))

$result3 = "teste_score_card2"


$appdy.PublishAnalyticsEvents($result3,$report)

$url = "https://analytics.api.appdynamics.com/events/publish/teste_score_card2"

$header = [System.Collections.Generic.Dictionary[[String],[String]]]::new()
#$header.Add("Content-type","application/vnd.appd.events+json")
#$header.Add("Accept","application/vnd.appd.events+json")
$header.Add('X-Events-API-Key', "30f385e9-5e82-49ec-8df2-bdab656b4f46")
$header.Add('X-Events-API-AccountName',"xp-beta_4a51785d-469a-431c-8b52-933d7149a844")

$teste = ($data1 | ConvertFrom-Json) | ConvertTo-Json -Compress
$metricsCount = ($data | ConvertFrom-Json).count
        $bucketList = @()
        $bucket = @()
        $bucketCount = 0
        Write-Host "Metricas : $metricsCount"
        foreach ($metricData in ($data | ConvertFrom-Json)) {

                if ($bucketCount -gt 999) {
                    $bucket | ConvertTo-Json | Out-File -FilePath ('./json' + $bucketList.count + '.json')
                    $body = ($bucket | ConvertTo-Json)
                    $body  | Out-File -FilePath ('./jsonDiego123.json')
                    Write-Host $body
                    Write-Host ($header | ConvertTo-Json)
                    Write-Host $url
                    Write-Host $bucket.count
                    
                    #Write-Host (Invoke-RestMethod -Uri $url -Headers $this.analyticsHeaders -Body $bucket -ContentType "application/vnd.appd.events+json" -Method Post  -UseBasicParsing)
                    #$bucketList += $bucket
                    Invoke-WebRequest -Uri $url -Headers $header  -Body ($bucket | ConvertTo-Json) -Method Post  -UseBasicParsing 
                    Write-Host "Rodei post"
                    try
                    {

                        $responseData = @{result = "OK"}
                        
                        Write-Host $responseData.Response 
                        Write-Host $responseData.StatusCode
                        Write-Host $responseData
                    }
                    catch
                    {
                        $StatusCode = $_.Exception.Response.StatusCode.value__
                        Write-Host $_.Exception.Response
                        Write-Host $_.Exception.Message
                        Write-Host $_.Exception
                        
                        Write-Host "Error getting apps : $StatusCode"
                        Write-Host $url
                        #Write-Host $data
                        Write-Host $header["Content-Type"]
                        Write-Host $header["X-Events-API-Key"]
                        Write-Host $header["X-Events-API-AccountName"]
                        #return ""
                    }
                    $bucket = @()
                    $bucketCount = 0
                } 

                $bucket += $metricData

                $bucketCount++
                Write-Host $bucketCount
        }
        Write-Host $header | ConvertTo-Json

        #Invoke-RestMethod -Uri $url -Headers $this.analyticsHeaders -Body $bucket -Method Post -UseBasicParsing
        $sessioWeb = $appdy.session

        #$sessioWeb.Headers."Content-type" = 'application/vnd.appd.events+json'
        $sessioWeb.Headers.Add('X-Events-API-Key', "30f385e9-5e82-49ec-8df2-bdab656b4f46")
        $sessioWeb.Headers.Add('X-Events-API-AccountName',"xp-beta_4a51785d-469a-431c-8b52-933d7149a844")
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add("X-Events-API-AccountName",'xp-beta_4a51785d-469a-431c-8b52-933d7149a844')
        $headers.Add("X-Events-API-Key", '30f385e9-5e82-49ec-8df2-bdab656b4f46')
        $headers.Add("Accept", 'application/vnd.appd.events+json;v=2')
        $headers.Add("Content-type", 'application/vnd.appd.events+json;v=2')
        Invoke-RestMethod -Uri $url -Headers $headers -Body $data3 -Method Post
        
        Write-Host "Passei depois do 2 post"
        Write-Host $teste
        $bucketList += $bucket
        $bucket | ConvertTo-Json | Out-File -FilePath ('./json' + $bucketList.count + '.json')
        Write-Host "Buckets : "$bucketList.Count
        Write-Host $bucketList.GetType()
        foreach ($bucketData in $bucketList) {
            #$bucketData | ConvertFrom-Json | Out-File -FilePath ('./jsonTestDiego' + $bucketList.count + '.json')
            #Write-Host "Conteudo TIPO :" ($bucketData.GetType())
            
        }


<# Write-Host "Exporting to CSV"
$report = $report | ConvertFrom-Json
$report  | Export-Csv '/Users/dieperei/Documents/Development/Powershell/tiers5.csv' -delimiter "," -force -notypeinformation
 #>



#$appdy.GetFileToken()

<# $appID = $appdy.GetAppID("HML_XP_FIXEDINCOME")
Write-Host "AppID : $appID"

$tierID = $appdy.GetTierID($appID, "XP.FixedIncome.Asset.Web")

Write-Host "tierID : $tierID"
 #>



<# $appName = "Teste Diego 123"
$appDescription = "Test App"
$tierName = "TesteDiego123"

$appID = $appdy.CreateApplication($appName,$appDescription)
$tierID = $appdy.CreateTierNET($appID,$tierName)
 #>
<# # Result

Write-Host "$appID and $tierID"
$appID = $appdy.GetAppID($appName)
Write-Host "AppID : $appID"
$tierID = $appdy.GetTierID($appID, $tierName)
Write-Host "tierID : $tierID"

$appdy.SendEvent("New Deployment Diego", "This is a test", "INFO", "VSTS", $tierName, $appID,$tierID)

$appdy.ImportHealthRules($appID,"health.json")
$appdy.ImportActions($appID,"actions.json")
$appdy.ImportPolicies($appID,"policies.json")
$appdy.UploadAppConfig("App_Template_Config.xml")
$appdy.ImportAppConfig($appID)
$appdy.GetType()

$appdy.ImportExitPoints($appID,@("Create-TASK.json","Create-GRPC.json")) 

 #>
###########################################################
#$appdy.CreateTierNET("21086","lalala")
#$appdy.CreateTierNET("21086","oioioi")
#$appdy.GetTiers("21086")

#$apps = $appdy.GetApplications()

#$appdy.GetType($apps)

#Write-Host $apps


#### Nodes per application

<# foreach ($app in $apps.applications.application) {
    #Write-Host "`nID: "$app.id" `nName: "$app.name" `nDescription: "$app.description
    $nodes = $appdy.GetNodes($app.id)
    foreach ($node in $nodes.nodes.node) {
        Write-Host ($app.name + "," + $node.name)
    }
}  #>


#nodes per application-tier

<# foreach ($app in $apps.applications.application) {
    #Write-Host "`nID: "$app.id" `nName: "$app.name" `nDescription: "$app.description
    $tiers = $appdy.GetTiers($app.id)
    foreach ($tier in $tiers.tiers.tier) {
        $nodes = $appdy.GetNodes($app.id,$tier.id)
        foreach ($node in $nodes.nodes.node) {
            #Write-Host ($app.name + "," + $tier.name + "," + $node.name)
        }
        
    }
}  #>


$appID = "17609"

#$apps = $appdy.GetApplications()

#$metrics = @()
Write-Host "Collecting metrics"
#Write-Host "Apps: "($apps.applications.application.count)

<# $MaxThreads = 20
#Remove all jobs
Get-Job | Remove-Job

$block = {
    Param([string] $app)
    $metrics += [PSCustomObject]$appdy.GetTierPerformanceSummary($app.name,"1600")
}

$apps.applications.application | ForEach-Object {
    Write-Host $_.name
    While ($(Get-Job -state running).count -ge $MaxThreads){
        Start-Sleep -Milliseconds 3
    }
    Start-Job -Scriptblock $block -ArgumentList $$_.name
}
#Wait for all jobs to finish.
While ($(Get-Job -State Running).count -gt 0){
    start-sleep 1
} 



#Get information from each job.
#foreach($job in Get-Job){
#    $info= Receive-Job -Id ($job.Id)
#}
#Remove all jobs created.
Get-Job | Remove-Job #>

<# ForEach ($app in $apps.applications.application) {
    Write-Host $app.name
    $metrics += [PSCustomObject]$appdy.GetTierPerformanceSummary($app.name,"1600")
} #>

#$metrics = $appdy.GetMetricsJSON($appID,"Overall Application Performance|*|*","1600")


#$metrics.GetType()
<# $lista = @()
$metrics = [PSCustomObject]$appdy.GetTierPerformanceSummary($appID,"1600")
$lista.Add($metrics)
$metrics.GetType()

#$appID = "19745"

$metrics = [PSCustomObject]$appdy.GetTierPerformanceSummary($appID,"1600")

$lista.Add($metrics) #>


<# $metrics = $appdy.GetAllTierPerformanceSummary("ALL","1600")

#$metrics.GetType()
#$metrics | Out-String

Write-Host "Append Metrics"
$metrics2 = $appdy.AppendSummaryMetrics($metrics)

#Write-Host $metrics2 | Out-String

Write-Host "Creating Report"
$report = $appdy.CreateTierReportCSV($metrics)

Write-Host "Exporting to CSV"
$report | Export-Csv '/Users/dieperei/Documents/Development/Powershell/tiers4.csv' -delimiter "," -force -notypeinformation
 #>
#ConvertTo-Csv -Header $report.keys -input $report.values

<# foreach ($reportLine in $report) {
    foreach ($metric in $reportLine.keys) {
        $reportLine[$metric] -join ',' | ConvertFrom-Csv -Header $reportLine.keys | Out-String
    }
    
    
} #>

#$report2 = $report | ConvertTo-Json -Depth 3

#($report2 | ConvertFrom-Json).results | ConvertTo-Csv -NoTypeInformation



#$metrics | Format-Table


#$metrics | Where-Object { $_.metricPath -eq "Overall Application Performance|Corporate.Finance.Monitor.Service|Errors per Minute"}


#$metrics | ConvertTo-Json | Out-File -FilePath "/Users/dieperei/Documents/Development/Powershell/metrics.json"
#$metrics2 = $appdy.ParseMetricsJSON($appID,$metrics,"|(.*)")

#$metrics2.metrics | Format-Table



#$appID = "19745"

#$metrics = $appdy.GetMetrics($appID,"Overall Application Performance|*|Calls per Minute","1600")

#Write-Host $metrics | Out-String
#Write-Host "Metricas fora de contexto"
#$metrics

#foreach ($item in $metrics) {
#    Write-Host $item    
#}

<# foreach ($item in $metrics.'metric-datas'.'metric-data') {
    $item | Out-String

} #>


#[AppdynamicsMetrics]$AppMetrics = $appdy.ParseMetrics($appID,$metrics)

#$AppMetrics

<# $teste = $AppMetrics.metrics
Write-Host $teste.count
foreach ($metric in $AppMetrics.metrics) {
    Write-Host $metric.GetType()
    [AppdynamicsMetric]$test = $metric
    Write-Host $test.name
    Write-Host $test.value
}


$AppMetrics #>

<#
$metricas = New-Object System.Collections.ArrayList

$metricas.add($metrics) > $null
Write-Host $metrics.'metric-datas'.'metric-data'.count

$metrics = $appdy.GetMetrics("20439","Overall Application Performance|*|Calls per Minute","1600")
$metricas.add($metrics) > $null
Write-Host $metrics.'metric-datas'.'metric-data'.count

$metrics = $appdy.GetMetrics("20940","Overall Application Performance|*|Calls per Minute","1600")
$metricas.add($metrics) > $null
Write-Host $metrics.'metric-datas'.'metric-data'.count


Write-Host "Foreach"
foreach ($metrica in $metricas) {
    $count = $metrica.'metric-datas'.'metric-data'.count

    if ([int]$count -gt 1) {
        Write-Host "gt 1"
        $teste = $metrica.'metric-datas'.'metric-data'

        foreach ($metric in $teste) {
            #Write-Host $metric#.'metric-data'.count;
            $metric.metricName
            $metric.'metricValues'.'metric-value'.value
            if (-not ($null -eq $metric.'metricValues'.'metric-value')) {
                Write-Host "Tem Metrica"
            }
        }
    }
    elseif ([int]$count -eq 1) {
        Write-Host "eq 1"
        $metrica.'metric-datas'.'metric-data'.'metricValues'.'metric-value'.count
    }
    else {
        Write-Host "eq 0"
    }
} #>

##### Import - App Xp Template
<# $appID = "20623"
$appdy.ImportHealthRules($appID,"health.json")
$appdy.ImportActions($appID,"actions.json")
$appdy.ImportPolicies($appID,"policies.json")
$appdy.UploadAppConfig("App_Template_Config.xml")
$appdy.ImportAppConfig($appID) #>


#Write-Host $appdy.fileToken
#Write-Host $appdy.headers | Out-String


