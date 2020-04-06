  
<#
.Synopsis
   SDK for powershell users that want to connect to Appdynamics APIs in a easy way. 
.DESCRIPTION
   SDK for Appdynamics API abstraction
.EXAMPLE
Using module './Appdynamics.psm1' 

$auth = Get-AuthorizationHeader -pair "user@account:password"

$appdy = [Appdynamics]::new("https://customer.saas.appdynamics.com",$auth)

$appID = $appdy.GetAppID("HML_XP_FIXEDINCOME")

#DEBUG#Write-Host "AppID : $appID"

$tierID = $appdy.GetTierID($appID, "XP.FixedIncome.Asset.Web")

appdy.SendEvent("New Deployment Diego", "This is a test", "INFO", "VSTS", $tierName, $appID,$tierID)

#### Rest-UI

$appdy.GetLogin()

$appName = "Diego Test 123"
$appDescription = "Test App"
$tierName = "TestDiego123"

$appID = $appdy.CreateApplication($appName,$appDescription)
$tierID = $appdy.CreateTierNET($appID,$tierName)

$appdy.GetTiers("21086")

$appdy.GetNodes($app.id)

$apps = $appdy.GetApplications()


#### Tiers per application

foreach ($tier in $tiers.tiers.tier) {
    #Write-Host "`nID: "$tier.id" `nName: "$tier.name"
}

#### Nodes per application

foreach ($app in $apps.applications.application) {
    #Write-Host "`nID: "$app.id" `nName: "$app.name" `nDescription: "$app.description
    $nodes = $appdy.GetNodes($app.id)
    foreach ($node in $nodes.nodes.node) {
        #DEBUG#Write-Host ($app.name + "," + $node.name)
    }
} 

## Import configs - Rest-ui

$appdy.GetFileToken()

$appdy.ImportHealthRules($appID,"health.json")
$appdy.ImportActions($appID,"actions.json")
$appdy.ImportPolicies($appID,"policies.json")
$appdy.UploadAppConfig("App_Template_Config.xml")
$appdy.ImportAppConfig($appID)
$appdy.ImportExitPoints($appID,@("Create-TASK.json","Create-GRPC.json")) 

## Metrics

$metrics = $appdy.GetMetricsJSON($appID,"Overall Application Performance|*|*","1600")

## Summary Metrics
$metrics = $appdy.GetAllTierPerformanceSummary("ALL","1600")

#DEBUG#Write-Host "Append Metrics"
$metrics2 = $appdy.AppendSummaryMetrics($metrics)

#Write-Host $metrics2 | Out-String

#DEBUG#Write-Host "Creating Report"
$report = $appdy.CreateTierReportCSV($metrics)

#DEBUG#Write-Host "Exporting to CSV"
$report | Export-Csv '/Users/dieperei/Documents/Development/Powershell/tiers4.csv' -delimiter "," -force -notypeinformation

.INPUTS
    import the module andCreate a new Appdynamics Class 

    Using module './Appdynamics.psm1' 

    $auth = Get-AuthorizationHeader -pair "user@account:password"

    $appdy = [Appdynamics]::new("https://customer.saas.appdynamics.com",$auth)

.OUTPUTS
   Depends what method you are running
.NOTES
   Developed by Diego P R Pereira - Appdynamics Senior Consultant - (Appdynamics - CISCO)
   This is not an official tool and its not supported by support team.
.COMPONENT
   Cisco - Appdynamics
.ROLE
   Professional Services
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>

Using namespace Microsoft.PowerShell.Commands


class AppdynamicsMetric {
    $name = @{}

    AppdynamicsMetric ([string]$name,[int]$value,[int]$sum,[int]$count,[int]$max,[int]$current,[int]$min){
        $metric = @{ value = $value; sum = $sum; count = $count; max = $max; current = $current; min = $min }
        $this.name.add($name,$metric)
    }
}

class AppdynamicsMetricGroup {
    [string]$prefixName
    $metrics = @{}

    AppdynamicsMetricGroup ([string]$prefixName) {
        $this.prefixName = $prefixName
    }
}

class AppdynamicsMetrics {
    [string]$app
    [System.Collections.ArrayList]$metrics = @()

    AppdynamicsMetrics ([string]$app) {
        $this.app = $app
    }

    AppdynamicsMetrics ([string]$app,[System.Collections.ArrayList]$metrics) {
        $this.app = $app
        foreach ($metric in $metrics) {
            $this.metrics.Add($metric)
        }
    }
    
    AddMetrics ([System.Collections.ArrayList]$metrics){
        foreach ($metric in $metrics) {
            $this.metrics.Add($metric)
        }
    }
    AddMetrics ([AppdynamicsMetrics]$metrics){
        foreach ($metric in $metrics.metrics) {
            $this.metrics.Add($metric)
        }
    }
    PrintMetrics(){


    }

}

class Appdynamics {
    
    [ValidatePattern("^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$")]
    [string]$baseurl
    [string]$fileToken
    [ValidatePattern("^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$")]
    [string]$analyticsurl
    $session
    $headers = [System.Collections.Generic.Dictionary[[String],[String]]]::new()
    $analyticsHeaders = [System.Collections.Generic.Dictionary[[String],[String]]]::new()
    $analyticsAPIKey = ""
    $accountName = ""
    [string]$Help
    #[System.Collections.Generic.Dictionary[AppdynamicsAPI, string]] $AppdynamicsAPIs
    
    Appdynamics ([String]$baseurl,[string]$auth) {
        # Seta Base URL
        $this.baseurl = $baseurl
        $this.analyticsurl = "https://analytics.api.appdynamics.com"
        # Set Default Headers
        $this.headers.Add('Content-Type','application/json;charset=UTF-8')
        $this.headers.Add('X-CSRF-TOKEN',"")
        $this.headers.Add('Authorization',$auth)
        $this.headers.Add('Accept',"application/json, text/plain, */*")
        $this.headers.Add('Accept-Encoding','gzip, deflate, br')
        $this.headers.Add('Accept-Language','en-US,en;q=0.9')
        $this.headers.Add('Sec-Fetch-Mode','cors')
        # Set Default Analytics Headers
        $this.analyticsHeaders.Add("Content-type","application/vnd.appd.events+json;v=2")
        #$this.analyticsHeaders.Add('Accept','application/vnd.appd.events+json')
        #$Header = New-Object System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/vnd.appd.events+json")
        #$this.analyticsHeaders.Add('Content-Type', $Header)
        
        $this.analyticsHeaders.Add('X-Events-API-Key',"")
        $this.analyticsHeaders.Add('X-Events-API-AccountName',"")
        #$this.analyticsHeaders.Add('Accept',"application/vnd.appd.events+json;v=2")
    }
    Appdynamics ([String]$baseurl,[string]$analyticsurl,[string]$auth) {
        # Seta Base URL
        $this.baseurl = $baseurl
        $this.analyticsurl = $analyticsurl
        # Set Default Headers
        $this.headers.Add('Content-Type','application/json;charset=UTF-8')
        $this.headers.Add('X-CSRF-TOKEN',"")
        $this.headers.Add('Authorization',"Basic ")
        $this.headers.Add('Accept',"application/json, text/plain, */*")
        $this.headers.Add('Accept-Encoding','gzip, deflate, br')
        $this.headers.Add('Accept-Language','en-US,en;q=0.9')
        $this.headers.Add('Sec-Fetch-Mode','cors')
        # Set Default Analytics Headers
        $this.analyticsHeaders.Add("Content-Type","application/vnd.appd.events+json")
        $this.analyticsHeaders.Add('X-Events-API-Key',"")
        $this.analyticsHeaders.Add('X-Events-API-AccountName',"")

        #$this.analyticsHeaders.Add('Accept',"application/vnd.appd.events+json; charset=utf-8")
        #$Header = New-Object System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/vnd.appd.events+json")
        #$this.analyticsHeaders.Accept.Add($Header);
        #$Header = New-Object System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("v=2")
        #$this.analyticsHeaders.Accept.Add($Header);

    }
    # Methods
    [bool] GetLogin (){
        $url = $this.baseurl+"/controller/auth?action=login"
        try
        {
            $this.session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -WebSession $this.session -Method GET -ContentType 'text/xml' -UseBasicParsing
            $cookies = $this.session.Cookies.GetCookies($url)
            $token = $cookies["X-CSRF-TOKEN"].value
            $this.headers['X-CSRF-TOKEN'] = $token
            $success = $TRUE

        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error get login: $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            $success = $FALSE
        }
        return $success
    }
    [System.Object[]] GetApplicationsJSON (){
        $url = $this.baseurl+"/controller/rest/applications"+"?output=JSON"

        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
            $content = $responseData.content
            $apps = ($content | ConvertFrom-Json)
            #[xml]$apps = $content
            return $apps
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return @()
        }
        return @()

    }
    [bool] SendEvent ([string]$summary, [string]$comment, [string]$severity, [string]$customeventtype, [string]$tier, [string]$appID,[string]$tierID){
        $url = $this.baseurl+"/controller/rest/applications/" + $appID + "/events"
        
        #Convert to uri enconding
        $comment = [uri]::EscapeDataString($comment)
        $summary = [uri]::EscapeDataString($summary)
        $tier = [uri]::EscapeDataString($tier)

        #Set default values and concact url
        if ($comment -eq ""){$comment="Default"}
        if ($tierID -eq "0") {
            #DEBUG#Write-Host $url+"?summary=$summary&comment=$comment&severity=$severity"
            $url = $url+"?summary=$summary&comment=$comment&severity=$severity"
        }
        else {
            $url = $url+"?summary=$summary&comment=$comment&severity=$severity&tier=$tier"
        }
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -Method Post -ContentType 'Application/Json' -UseBasicParsing
            $success = $TRUE

        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error sending event : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            $success = $FALSE
        }
        return $success
    }
    [string] GetAppsEvents ($duration){
        
        $url = $this.baseurl+"/controller/rest/applications/"
        $finalUrl = "/events"+"?output=JSON&time-range-type=BEFORE_NOW&duration-in-mins=$duration&event-types=APPLICATION_DEPLOYMENT&severities=INFO"
        
        $eventList = @()
        $apps = $this.GetApplications()
        try
        {
            foreach ($app in $apps.applications.application) { 
                try {
                    $urlFinal = $url + $app.id + $finalUrl 
                    #$urlFinal = $url + "21829" + $finalUrl 
                    #DEBUG#Write-Host $urlFinal
                    $responseData = Invoke-WebRequest -Uri $urlFinal -Headers $this.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
                    $content = $responseData.content
                    <# #DEBUG#Write-Host $content.GetType()
                    #DEBUG#Write-Host $content
                    #DEBUG#Write-Host $content.count #>
                    if ($content -ne "[]") {
                        #DEBUG#Write-Host $content
                        $eventList += $content
                    }
                    
                }
                catch {
                    $StatusCode = $_.Exception.Response.StatusCode.value__
                    #DEBUG#Write-Host $_.Exception.Response
                    #DEBUG#Write-Host $_.Exception.Message
                    #DEBUG#Write-Host "Error getting events from "+$app.name+" : $StatusCode"
                    #DEBUG#Write-Host $url
                    #DEBUG#Write-Host $this.headers["Authorization"]
                }
                
            }
            return $eventList
            
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error sending event : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return "0"
        }
    }
    [System.Object[]] GetAllApplicationsSummary ($start_time, $end_time){
        
        $apps = $this.GetApplicationsJSON()
        $filter_all = ""
        $count = 0
        foreach ($app in $apps) {
            if ($count -eq ($apps.Count -1)) {
                $filter_all += [string]$app.id
            }
            else {
                $filter_all += [string]$app.id + ","
            }
            $count += 1  
        }
        #Write-Host $filter_all
        $url = $this.baseurl+"/controller/restui/v1/app/list/ids"#+"?output=JSON"
        try
        {
            $body = '{"requestFilter":['+$filter_all+'],"timeRangeStart":'+$start_time+',"timeRangeEnd":'+$end_time+',"searchFilters":null,"columnSorts":null,"resultColumns":["APP_OVERALL_HEALTH","CALLS","CALLS_PER_MINUTE","AVERAGE_RESPONSE_TIME","ERROR_PERCENT","ERRORS","ERRORS_PER_MINUTE"],"offset":0,"limit":-1}'
            #Write-Host $body
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -WebSession $this.session -Body $body -Method Post -UseBasicParsing
            $content = $responseData.content
            #$nodes = ($content | ConvertFrom-Json)
            #DEBUG#Write-Host $responseData
            return $content 
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return @("ERROR")
        }
        

    }
    [string[]] GetAllAppsEvents ($duration){
        ### Multithread
        $MaxThreads = 16

        $apps = $this.GetApplications()
        $count = $apps.applications.application.count
        #DEBUG#Write-Host  $(Get-Date)" - Starting collecting events from "$count" applications"

        $listApps = $apps.applications.application
        #$apps = ($this.GetApplications()).applications.application

        #$listApps = @($apps[0],$apps[1])
        $stepCounter = 0

        $jobParam = @{argList = @();duration = $duration;url = $this.baseurl;headers = $this.headers;stepCounter = $stepCounter }
        $Export_Functions = [scriptblock]::Create(@"
Function Job1 { $function:Job1  } 
"@)
        $functions =  {
            function GetAppEvents {
                param ($app,$params)
                #DEBUG#Write-Host $app
                #DEBUG#Write-Host $params
                $url = $params.url+"/controller/rest/applications/"
                $finalUrl = "/events"+"?output=JSON&time-range-type=BEFORE_NOW&duration-in-mins="+$params.duration+"&event-types=APPLICATION_DEPLOYMENT&severities=INFO"
                #DEBUG#Write-Host $finalUrl
                try
                {
                    $urlFinal = $url + $app.id + $finalUrl 
                    #$urlFinal = $url + "21829" + $finalUrl 
                    #Write-Host $urlFinal
                    $responseData = Invoke-WebRequest -Uri $urlFinal -Headers $this.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
                    $content = $responseData.content
                    <# #DEBUG#Write-Host $content.GetType()
                    #DEBUG#Write-Host $content
                    #DEBUG#Write-Host $content.count #>
                    if ($content -ne "[]") {
                        #DEBUG#Write-Host $content
                        
                    }
                }
                catch
                {
                    $StatusCode = $_.Exception.Response.StatusCode.value__
                    #DEBUG#Write-Host $_.Exception.Response
                    #DEBUG#Write-Host $_.Exception.Message
                    #DEBUG#Write-Host "Error sending event : $StatusCode"
                    #DEBUG#Write-Host $url
                    #DEBUG#Write-Host $this.headers["Authorization"]
                }
            
            }
        }

        $results = Start-MultiThreadAppdyEvents -list $listApps -maxThreads $MaxThreads -params $jobParam

        #DEBUG#Write-Host (Get-Date)" - Finished collecting metrics from "$count" applications"

        return $results
    }
    GetAppEvents ($app,$params){
        
        $url = $this.baseurl+"/controller/rest/applications/"
        $finalUrl = "/events"+"?output=JSON&time-range-type=BEFORE_NOW&duration-in-mins=3000&event-types=APPLICATION_DEPLOYMENT&severities=INFO"
        
        try
        {
            $urlFinal = $url + $app.id + $finalUrl 
            #$urlFinal = $url + "21829" + $finalUrl 
            #DEBUG#Write-Host $urlFinal
            $responseData = Invoke-WebRequest -Uri $urlFinal -Headers $this.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
            $content = $responseData.content
            <# #DEBUG#Write-Host $content.GetType()
            #DEBUG#Write-Host $content
            #DEBUG#Write-Host $content.count #>
            if ($content -ne "[]") {
                #DEBUG#Write-Host $content
                
            }
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error sending event : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
        }

    }
    [string] GetAppID ([string]$appName){
        $appName = [uri]::EscapeDataString($appName)
        $url = $this.baseurl+"/controller/rest/applications/$appName"+"?output=JSON"
        
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
            $content = $responseData.content
            $appID = ($content | ConvertFrom-Json).id
            <# [xml]$apps = $content
            foreach ($app in $apps.applications.application)
            {
                if ($app.name -eq $appName){
                    return [string]$app.id}
            }
            $appID = "0"
            $comment = "" #>
            return $appID
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error sending event : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return "0"
        }
    }
    [string] GetTierID ([string]$appID,[string]$tierName){
        $tierName = [uri]::EscapeDataString($tierName)
        $url = $this.baseurl+"/controller/rest/applications/$appID/tiers/$tierName"+"?output=JSON"
        
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
            $content = $responseData.content
            $tierID = ($content | ConvertFrom-Json).id
            return $tierID
            #[xml]$tiers = $content
            #Write-Host $content
            <# foreach ($tier in $tiers.tiers.tier)
            {
                #Write-Host $tier.name
                if ($tier.name -eq $tierName){
                    #Write-Host "Tier: "$tier.id
                    return [string]$tier.id}
            } #>
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting tier : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return "0"
        }
        $tierID = "0"
        return $tierID
    }
    [System.Object[]] GetApplications (){
        $url = $this.baseurl+"/controller/rest/applications"#+"?output=JSON"

        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
            $content = $responseData.content
            #$apps = ($content | ConvertFrom-Json)
            [xml]$apps = $content
            return $apps
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return [xml]::new()
        }
        return [xml]::new()

    }
    [System.Object[]] GetTiers ($appID){
        $appID = [uri]::EscapeDataString($appID)
        $url = $this.baseurl+"/controller/rest/applications/$appID/tiers"#+"?output=JSON"

        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
            $content = $responseData.content
            #$tiers = $content | ConvertFrom-Json
            [xml]$tiers = $content
            return $tiers
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting tiers : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return [xml]::new()
        }
        return [xml]::new()

    }
    [System.Object[]] GetNodesJSON ($appID){
        $appID = [uri]::EscapeDataString($appID)
        $url = $this.baseurl+"/controller/rest/applications/$appID/nodes"+"?output=JSON"
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
            $content = $responseData.content
            #Write-Host $content
            $nodes = ($content | ConvertFrom-Json)
            #$nodes = $content
            return $nodes
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return [xml]::new()
        }
        return [xml]::new()

    }
    [System.Object[]] GetNodes ($appID){
        $appID = [uri]::EscapeDataString($appID)

        $url = $this.baseurl+"/controller/rest/applications/$appID/nodes"#+"?output=JSON"
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
            [xml]$content = $responseData.content
            #$nodes = ($content | ConvertFrom-Json)
            $nodes = $content | ConvertFrom-Json
            return $nodes
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return [System.Object]::new()
        }
        return [System.Object]::new()

    }
    [bool] DeleteNode ([string]$node){
        
        $url = $this.baseurl+"/controller/restui/nodeUiService/deleteNode/$node"#+"?output=JSON"
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -WebSession $this.session -Method Delete -UseBasicParsing
            $content = $responseData.content
            #$nodes = ($content | ConvertFrom-Json)
            #DEBUG#Write-Host $responseData
            return $true
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return $false
        }
        

    }

    [bool] DeleteApplication ([string]$appID){
        
        $url = $this.baseurl+"/controller/restui/allApplications/deleteApplication"#+"?output=JSON"
        $body =  "$appID"
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -Body ($body | ConvertTo-Json) -WebSession $this.session -Method Delete -UseBasicParsing
            $content = $responseData.content
            #$nodes = ($content | ConvertFrom-Json)
            #DEBUG#Write-Host $responseData
            return $true
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return $false
        }
        

    }
    [System.Object[]] GetNodes ($appID,$tierID){
        $appID = [uri]::EscapeDataString($appID)
        $tierID = [uri]::EscapeDataString($tierID)
        $url = $this.baseurl+"/controller/rest/applications/$appID/tiers/$tierID/nodes"#+"?output=JSON"
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
            $content = $responseData.content
            #$nodes = ($content | ConvertFrom-Json)
            [xml]$nodes = $content
            return $nodes
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return [xml]::new()
        }
        return [xml]::new()

    }
    [System.Object] GetNodeInfo ([string]$nodeID){
        
        $url = $this.baseurl+"/controller/restui/nodeUiService/node/$nodeID"#+"?output=JSON"
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -WebSession $this.session -Method Get -UseBasicParsing
            $content = $responseData.content
            $node = ($content | ConvertFrom-Json)
            #DEBUG#Write-Host $responseData
            return $node
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return [System.Object]::new()
        }
        

    }
    [System.Object] GetNodeStatus ([string]$nodeID){
        # Last 5 minutes
        $url = $this.baseurl+"/controller/restui/nodeUiService/getAgentAvailabilitySummaryForNode/"+$nodeID+"?timerange=last_5_minutes.BEFORE_NOW.-1.-1.5"#+"?output=JSON"
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -WebSession $this.session -Method Get -UseBasicParsing
            $content = $responseData.content
            $node = ($content | ConvertFrom-Json)
            #DEBUG#Write-Host $responseData
            return $node
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return [System.Object]::new()
        }
        

    }
    [bool] GetFileToken (){
        $url = $this.baseurl+"/controller/restui/fileUpload/getFileToken"
        try
        {
            #DEBUG#Write-Host "starting get file token"
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -WebSession $this.session -Method GET -ContentType 'text/xml' -UseBasicParsing
            $cookies = $this.session.Cookies.GetCookies($url)
            $token = $cookies["X-CSRF-TOKEN"].value
            $this.headers['X-CSRF-TOKEN'] = $token
            $this.fileToken = $responseData.Content
            $success = $TRUE
            #DEBUG#Write-Host "finished get file token"

        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error get file token: $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            $success = $FALSE
        }
        return $success
    }
    [bool] ImportAppConfig ([string]$appID){
        $url = $this.baseurl+"/controller/restui/configurationImportService/startImport"
        try
        {
            #DEBUG#Write-Host "Starting import App config"
            $body = '{"importIntoExistingApplication":true,"targetApplicationId":'+$appID+',"fileToken":"'+ $this.fileToken +'","importTypes":["HEALTH_RULES","AGENT_CONFIGURATIONS","MDS_CONFIG","DATA_GATHERER_CONFIGS"]}'
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -WebSession $this.session -Method Post -body $body  -UseBasicParsing
            $cookies = $this.session.Cookies.GetCookies($url)
            $token = $cookies["X-CSRF-TOKEN"].value
            $this.headers['X-CSRF-TOKEN'] = $token
            $success = $TRUE
            #DEBUG#Write-Host "Finished import App config"

        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error import App config: $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            $success = $FALSE
        }
        return $success
    }
    [bool] UploadAppConfig ([string]$filePath){
        $url = $this.baseurl+"/controller/fileUploadNoSession?token="+$this.fileToken
        # We need a boundary (something random() will do best)
        $boundary = [System.Guid]::NewGuid().ToString()
        # Linefeed character
        $LF = "`r`n"

        # CONST
        #$CODEPAGE = "iso-8859-1" # alternatives are ASCII, UTF-8
        $CODEPAGE = "UTF-8"
        #$filePath = './App_Template_Config.xml';

        try {
            # Read file byte-by-byte
            $fileBin = [System.IO.File]::ReadAllBytes($filePath)
        }
        catch {
            #DEBUG#Write-Host "Failed to read file: $filePath"
            #DEBUG#Write-Host $_.Exception.Message
            return $FALSE
        }

        # Convert byte-array to string
        $enc = [System.Text.Encoding]::GetEncoding($CODEPAGE)

        $fileEnc = $enc.GetString($fileBin)

        # Build body for our form-data manually since PS does not support multipart/form-data out of the box
        $bodyLines = (
            "--$boundary",
            "Content-Disposition: form-data; name=`"fileUpload`"; filename=`"$filePath`"",
        "Content-Type: application/xml$LF",
            $fileEnc,
            "--$boundary--$LF"
        ) -join $LF

        try
        {
            #DEBUG#Write-Host "Starting upload $filePath"
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -WebSession $this.session -Method Post -body $bodyLines -ContentType "multipart/form-data; boundary=`"$boundary`"" -UseBasicParsing
            $cookies = $this.session.Cookies.GetCookies($url)
            $token = $cookies["X-CSRF-TOKEN"].value
            $this.headers['X-CSRF-TOKEN'] = $token
            $success = $TRUE
            #DEBUG#Write-Host "Finished upload $filePath"

        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error upload file $filePath : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            $success = $FALSE
        }
        return $success
    }
    [bool] UploadDashboard ([string]$filePath){
        $url = $this.baseurl+"/controller/CustomDashboardImportExportServlet"
        # We need a boundary (something random() will do best)
        $boundary = [System.Guid]::NewGuid().ToString()
        # Linefeed character
        $LF = "`r`n"

        # CONST
        #$CODEPAGE = "iso-8859-1" # alternatives are ASCII, UTF-8
        $CODEPAGE = "UTF-8"
        #$filePath = './App_Template_Config.xml';

        try {
            # Read file byte-by-byte
            $enc = New-Object System.Text.UTF8Encoding($False)   
            $fileBin = [System.IO.File]::ReadAllBytes($filePath)
        }
        catch {
            #DEBUG#Write-Host "Failed to read file: $filePath"
            #DEBUG#Write-Host $_.Exception.Message
            return $FALSE
        }

        # Convert byte-array to string
        #$enc = [System.Text.Encoding]::GetEncoding($CODEPAGE)

        $fileEnc = $enc.GetString($fileBin)

        # Build body for our form-data manually since PS does not support multipart/form-data out of the box
        $bodyLines = (
            "--$boundary",
            "Content-Disposition: form-data; name=`"file`"; filename=`"$filePath`"",
        "Content-Type: application/json$LF",
            $fileEnc,
            "--$boundary--$LF"
        ) -join $LF

        try
        {
            $headersT = $this.headers
            $headersT['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3'

            #DEBUG#Write-Host "Starting upload $filePath"
            $responseData = Invoke-WebRequest -Uri $url -Headers $headersT -WebSession $this.session -Method Post -body $bodyLines -ContentType "multipart/form-data; boundary=`"$boundary`"" -UseBasicParsing
            #DEBUG#Write-Host $responseData
            $cookies = $this.session.Cookies.GetCookies($url)
            $token = $cookies["X-CSRF-TOKEN"].value
            $this.headers['X-CSRF-TOKEN'] = $token
            $success = $TRUE
            #DEBUG#Write-Host "Finished upload $filePath"

        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error upload file $filePath : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            $success = $FALSE
        }
        return $success
    }
    [bool] UploadDashboardFile ([String]$fileEnc){
        $url = $this.baseurl+"/controller/CustomDashboardImportExportServlet"
        # We need a boundary (something random() will do best)
        $boundary = [System.Guid]::NewGuid().ToString()
        # Linefeed character
        $LF = "`r`n"

        # Build body for our form-data manually since PS does not support multipart/form-data out of the box
        $bodyLines = (
            "--$boundary",
            "Content-Disposition: form-data; name=`"file`"; filename=`"template.json`"",
        "Content-Type: application/json$LF",
            $fileEnc,
            "--$boundary--$LF"
        ) -join $LF

        try
        {
            $headersT = $this.headers
            #$headersT['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3'

            #DEBUG#Write-Host "Starting upload Template"
            $responseData = Invoke-WebRequest -Uri $url -Headers $headersT -WebSession $this.session -Method Post -body $bodyLines -ContentType "multipart/form-data; boundary=`"$boundary`"" -UseBasicParsing
            #DEBUG#Write-Host $responseData
            $cookies = $this.session.Cookies.GetCookies($url)
            $token = $cookies["X-CSRF-TOKEN"].value
            $this.headers['X-CSRF-TOKEN'] = $token
            $success = $TRUE
            #DEBUG#Write-Host "Finished upload Template"

        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error upload file Template : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            $success = $FALSE
        }
        return $success
    }
    [bool] ReplicateDashboard ($dashName,$template,$regex){

        $apps = $this.GetApplications()

        $enc = New-Object System.Text.UTF8Encoding($False)   
        $fileBin = [System.IO.File]::ReadAllBytes($template)
        $fileEnc = $enc.GetString($fileBin)

        foreach ($app in $apps.applications.application) { 
            if ($app.name -match $regex) {
                #Write-Host $app.name
                $fileUpdated = $fileEnc
                $fileUpdated = $fileUpdated -replace "\`$APPLICATION",$app.name
                $fileUpdated = $fileUpdated -replace "\`$APPID",$app.id
                $dashNameApp = $dashName+" - "+$app.name
                $fileUpdated = $fileUpdated -replace "\`$DASHNAME",$dashNameApp
                $this.UploadDashboardFile($fileUpdated)
            }
        }
        return $TRUE
    }
    [string] CreateTierNET ([string]$appID,[string]$tierName){
        $url = $this.baseurl+"/controller/restui/components/createComponent"
        $body = '{"applicationId":'+$appID+',"name":"'+$tierName+'","componentType":{"id":7,"version":0,"name":".NET Application Server","nameUnique":true,"agentType":"DOT_NET_APP_AGENT","productType":"DOT_NET_APP_AGENT","platform":null,"language":null}}'
        try
        {
            #DEBUG#Write-Host "Creating tier $tierName"
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -WebSession $this.session -Method Post -body $body -UseBasicParsing
            $cookies = $this.session.Cookies.GetCookies($url)
            $token = $cookies["X-CSRF-TOKEN"].value
            $this.headers['X-CSRF-TOKEN'] = $token
            $tierID = ($responseData.Content | ConvertFrom-Json).id
            #DEBUG#Write-Host "Finished creating tier $tierName"
            return $tierID

        }
        catch
        {
            if ($_.Exception.Response.StatusCode.value__ -eq 500) {
                try {

                    return $this.GetTierID($appID,$tierName)
                }
                catch {
                    #DEBUG#Write-Host $_.Exception.Message
                    return "0"
                }
            }
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error creating tier $tierName : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return "0"
        }
        return "0"
    }
    [string] CreateApplication ([string]$appName,[string]$appDescription){
        $url = $this.baseurl+"/controller/restui/allApplications/createApplication?applicationType=APM"
        $body = @{
            name = $appName;
            description = $appDescription;
        }
        try
        {
            #DEBUG#Write-Host "Creating app $appName"
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -WebSession $this.session -Method Post -body ($body|ConvertTo-Json) -UseBasicParsing
            $cookies = $this.session.Cookies.GetCookies($url)
            $token = $cookies["X-CSRF-TOKEN"].value
            $this.headers['X-CSRF-TOKEN'] = $token
            $appID = ($responseData.Content | ConvertFrom-Json).id
            #DEBUG#Write-Host "Finished creating app $appName"
            return $appID

        }
        catch
        {
            #DEBUG#Write-Host "Already Exist or Permission denied"
            if ($_.Exception.Response.StatusCode.value__ -eq 500) {
                try {
                    $urlApp = $this.baseurl+"/controller/rest/applications/$appName"+"?output=JSON"
                    $responseData = Invoke-WebRequest -Uri $urlApp -Headers $this.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
                    $content = $responseData.content
                    return ($content | ConvertFrom-Json).id
                }
                catch {
                    #DEBUG#Write-Host $_.Exception.Message
                    return "0"
                }
            }
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error creating app $appName : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return "0"
        }
        return "0"
    }
    [System.Collections.Generic.Dictionary[[String],[String]]] CreateUploadBody ([string]$filePath){
        $boundary = [System.Guid]::NewGuid().ToString()
        $LF = "`r`n"
        $CODEPAGE = "UTF-8"
        try {
            # Read file byte-by-byte
            $fileBin = [System.IO.File]::ReadAllBytes($filePath)
            $success = $true
        }
        catch {
            #DEBUG#Write-Host "failed to read file "$filePath
            $_.Exception.Message
            $success = $false
            $fileBin = [System.IO.File]::new()
        }
        if ($success) {
            $enc = [System.Text.Encoding]::GetEncoding($CODEPAGE)
            $fileEnc = $enc.GetString($fileBin)
            $bodyLines = (
                "--$boundary",
                "Content-Disposition: form-data; name=`"fileUpload`"; filename=`"$filePath`"",
            "Content-Type: application/xml$LF",
                $fileEnc,
                "--$boundary--$LF"
            ) -join $LF
        }
        else {
            $bodyLines = ""
        }

        #DEBUG#Write-Host $bodyLines.GetType()
        $result = [System.Collections.Generic.Dictionary[[String],[String]]]::new()
        $result.Add("body" , $bodyLines)
        $result.Add("contentType","multipart/form-data; boundary=`"$boundary`"")
        $result.Add("success", $success)

        return $result
    }
    [bool] ImportHealthRules ([string]$appID,[string]$filePath){
        $url = $this.baseurl+"/controller/healthrules/$appID"
        $result = $this.CreateUploadBody($filePath)
        if ($result.success) {
            try
            {
                #DEBUG#Write-Host "Starting upload $filePath"
                $healthRules = Invoke-WebRequest -Uri $url -Headers $this.headers -Method Post -body $result.body -ContentType $result.contentType -UseBasicParsing
                $success = $TRUE
                #DEBUG#Write-Host "Finished upload $filePath"
            }
            catch
            {
                $StatusCode = $_.Exception.Response.StatusCode.value__
                #DEBUG#Write-Host $_.Exception.Response
                #DEBUG#Write-Host $_.Exception.Message
                #DEBUG#Write-Host "Error upload file $filePath : $StatusCode"
                #DEBUG#Write-Host $url
                #DEBUG#Write-Host $this.headers["Authorization"]
                $success = $FALSE
            }
        }
        else {
            $success = $false
        }
        
        return $success
    }
    [bool] ImportActions ([string]$appID,[string]$filePath){
        $url = $this.baseurl+"/controller/actions/$appID"
        $result = $this.CreateUploadBody($filePath)
        if ($result.success) {
            try
            {
                #DEBUG#Write-Host "Starting upload $filePath"
                $actions = Invoke-WebRequest -Uri $url -Headers $this.headers -WebSession $this.session -Method Post -body $result.body -ContentType $result.contentType -UseBasicParsing
                $cookies = $this.session.Cookies.GetCookies($url)
                $token = $cookies["X-CSRF-TOKEN"].value
                $this.headers['X-CSRF-TOKEN'] = $token
                $success = $TRUE
                #DEBUG#Write-Host "Finished upload $filePath"
            }
            catch
            {
                $StatusCode = $_.Exception.Response.StatusCode.value__
                #DEBUG#Write-Host $_.Exception.Response
                #DEBUG#Write-Host $_.Exception.Message
                #DEBUG#Write-Host "Error upload file $filePath : $StatusCode"
                #DEBUG#Write-Host $url
                #DEBUG#Write-Host $this.headers["Authorization"]
                $success = $FALSE
            }
        }
        else {
            $success = $false
        }
        
        return $success
    }
    [bool] ImportPolicies ([string]$appID,[string]$filePath){
        $url = $this.baseurl+"/controller/policies/$appID"
        $result = $this.CreateUploadBody($filePath)
        if ($result.success) {
            try
            {
                #DEBUG#Write-Host "Starting upload $filePath"
                $policies = Invoke-WebRequest -Uri $url -Headers $this.headers -Method Post -body $result.body -ContentType $result.contentType -UseBasicParsing
                $success = $TRUE
                #DEBUG#Write-Host "Finished upload $filePath"
            }
            catch
            {
                $StatusCode = $_.Exception.Response.StatusCode.value__
                #DEBUG#Write-Host $_.Exception.Response
                #DEBUG#Write-Host $_.Exception.Message
                #DEBUG#Write-Host "Error upload file $filePath : $StatusCode"
                #DEBUG#Write-Host $url
                #DEBUG#Write-Host $this.headers["Authorization"]
                $success = $FALSE
            }
        }
        else {
            $success = $false
        }
        
        return $success
    }
    [bool] ImportExitPoints ($appID,[System.Object[]]$eps){
        $url = $this.baseurl+"/controller/restui/customExitPoint/create"
        foreach ($ep in $eps) {
            try
            {
                #DEBUG#Write-Host "Starting import $ep on appID $appID"
                $content = Get-Content -Raw -Path $ep
                $body = $content -replace '"entityId": 0',('"entityId": '+$appID)
                $epsResult = Invoke-WebRequest -Uri $url -Headers $this.headers -WebSession $this.session -Method Post -body $body  -UseBasicParsing
                #Write-Host $epsResult
                $success = $TRUE
                #DEBUG#Write-Host "Finished import $ep on appID $appID"
            }
            catch
            {
                $StatusCode = $_.Exception.Response.StatusCode.value__
                #DEBUG#Write-Host $_.Exception.Response
                #DEBUG#Write-Host $_.Exception.Message
                #DEBUG#Write-Host "Error import $ep on appID $appID , httpCode: $StatusCode"
                #DEBUG#Write-Host $url
                #DEBUG#Write-Host $this.headers["Authorization"]
                $success = $FALSE
            }
        }

        return $true
    }
    [bool] ServiceManifestAppend ([string]$appName,[string]$tierName, [string]$xmlFile, $agentType){
        [xml]$xml = Get-Content $xmlFile

        $uagentType = @{}
        $uagentType.add('Framework', '
        <EnvironmentVariable Name="COR_ENABLE_PROFILING" Value="1" />
        <EnvironmentVariable Name="COR_PROFILER" Value="{39AEABC1-56A5-405F-B8E7-C3668490DB4A}" />
        <EnvironmentVariable Name="COR_PROFILER_PATH" Value="E:\appdynamics_uagent\dotNet_Framework\AppDynamics.Profiler_x64.dll" />
        <EnvironmentVariable Name="APPDYNAMICS_AGENT_APPLICATION_NAME" Value="'+$appName+'" />
        <EnvironmentVariable Name="APPDYNAMICS_AGENT_TIER_NAME" Value="'+$tierName+'" />
</EnvironmentVariables>')
        $uagentType.add('Core', '
        <EnvironmentVariable Name="CORECLR_ENABLE_PROFILING" Value="1" />
        <EnvironmentVariable Name="CORECLR_PROFILER" Value="{39AEABC1-56A5-405F-B8E7-C3668490DB4A}" />
        <EnvironmentVariable Name="CORECLR_PROFILER_PATH_32" Value="E:\appdynamics_uagent\dotNet_Core\AppDynamics.Profiler_x86.dll" />
        <EnvironmentVariable Name="CORECLR_PROFILER_PATH_64" Value="E:\appdynamics_uagent\dotNet_Core\AppDynamics.Profiler_x64.dll" />
        <EnvironmentVariable Name="APPDYNAMICS_AGENT_APPLICATION_NAME" Value="'+$appName+'" />
        <EnvironmentVariable Name="APPDYNAMICS_AGENT_TIER_NAME" Value="'+$tierName+'" />
</EnvironmentVariables>')
        
        $EnvironmentVariables = $uagentType.$agentType
        if ($xml.ServiceManifest.CodePackage.EnvironmentVariables){
            (($xml.OuterXml) `
                -replace '(</EnvironmentVariables>)', "$EnvironmentVariables" )|
                Out-File "$($xmlFile)"
        }
        else{
            (($xml.OuterXml) `
                -replace '(<\/EntryPoint>.*[\n\r]*[\s]*)(<\/CodePackage>)', "</EntryPoint>`r`n`t`t<EnvironmentVariables>`r`n`t`t</EnvironmentVariables>`r`n`t</CodePackage>") `
                -replace '(</EnvironmentVariables>)', "$EnvironmentVariables" |
                Out-File "$($xmlFile)"
        }

        #Formmating XML File
        [xml]$xml = Get-Content $xmlFile
        $xml.Save($xmlFile)
        return $true
    }
    [string] ServiceManifestGetAppVersion ([string]$xmlFile){
        [xml]$xml = Get-Content $xmlFile
        $version = $xml.ServiceManifest.CodePackage.Version
        #$version = $($version)
        return $version
    }
    [string] ServiceManifestGetTierName ([string]$xmlFile){
        [xml]$xml = Get-Content $xmlFile
        $tierName = $xml.ServiceManifest.CodePackage.EntryPoint.ExeHost.Program -replace "(.SAK.exe|.exe)",""    #$version = $($version)
        return $tierName
    }
    [string] ServiceManifestSetAppName ([string]$xmlFile,$appName,$environment){
        $tierName = $this.ServiceManifestGetTierName($xmlFile)
    
        if ($appName -eq "Default"){
            $applicationName = $environment + "_" + $tierName
        }
        else{
            $applicationName = $environment + "_" + $appName
        }

        return $applicationName
    }
    [System.Object[]] GetMetricsJSON ($appID,$metricPath,$duration){
        $metricPath = [uri]::EscapeDataString($metricPath)
        
        $url = $this.baseurl+"/controller/rest/applications/$appID/metric-data?metric-path=$metricPath&time-range-type=BEFORE_NOW&duration-in-mins=$duration"+"&output=JSON"
        #DEBUG#Write-Host $url
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
            $content = $responseData.content

            $metrics = (($content | ConvertFrom-Json) | Where-Object {$_.metricName -ne "METRIC DATA NOT FOUND"})
            #Write-Host $metrics | Format-Table
            return $metrics
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return [System.Object]::new()
        }

    }
    [System.Object[]] GetIndividualMetricsJSON ($appID,$metricPath,$duration){
        $metricPath = [uri]::EscapeDataString($metricPath)
        
        $url = $this.baseurl+"/controller/rest/applications/$appID/metric-data?rollup=false&metric-path=$metricPath&time-range-type=BEFORE_NOW&duration-in-mins=$duration"+"&output=JSON"
        #Write-Host $url
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
            $content = $responseData.content

            $metrics = (($content | ConvertFrom-Json) | Where-Object {$_.metricName -ne "METRIC DATA NOT FOUND"})
            #Write-Host $metrics | Format-Table
            return $metrics
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return [System.Object]::new()
        }

    }
    [bool] IntegrateToELK ($apps,$Config){
        #(Measure-Command {
        foreach ($app in $apps) { 
            #$metrics = $appdy.GetMetricsHierarchy($app.id,"Overall Application Performance")
        
            foreach ($metricPath in $Config.metricPaths) {
                $Appmetrics = $this.GetIndividualMetricsJSON($app.id,$metricPath,$Config.collect_metrics_last_mins)
                #DEBUG#Write-Host " N of Metricas ($metricPath) : " + $Appmetrics.Count
                if ($Appmetrics.Count -ne 0) {
                    $allMetrics = @()
                    foreach ($metrics in $Appmetrics) {
                        #DEBUG#Write-Host "Metric Values from" $metrics.metricName ":" $metrics.metricValues.Count
                        $regex = "(.*)\|(.*)$"
                        $metrics.metricPath -match $regex
                        $metricPrefix = $Matches[1]
                        $metricName = $Matches[2]
                        
                        foreach ($metric in $metrics.metricValues) {
                            $metricTemplate = [PSCustomObject]::new
                
                            $metricTemplate = [PSCustomObject] @{
                                AppName = $app.name
                                AppID = $app.id
                                Metric = $metricName
                                MetricPath = $metricPrefix
                                FullPath = ($app.name+"|"+$metrics.metricPath)
                                Value = $metric.value
                                Min = $metric.min 
                                Max = $metric.max
                                MetricTime = $metric.startTimeInMillis
                            }
                            $allMetrics += $metricTemplate
                            #$metricTemplate
                        }
                        
                    }
                    #Add-Content -Path (".\metrics_" + $app.name + ".log") -Value ($allMetrics | ConvertTo-Json) -PassThru
                    $headers_elk = [System.Collections.Generic.Dictionary[[String],[String]]]::new()
                    $headers_elk.Add('Content-type', "application/json")
                    
                    
                    $url = $Config.elk_host_port
                    #Write-Host $url
                    try
                    {
                        Invoke-WebRequest -Uri $url -Headers $headers_elk -Body ($allMetrics | ConvertTo-Json) -Method Post -UseBasicParsing
                    }
                    catch
                    {
                        $StatusCode = $_.Exception.Response.StatusCode.value__
                        #DEBUG#Write-Host $_.Exception.Response
                        #DEBUG#Write-Host $_.Exception.Message
                        #DEBUG#Write-Host "Error posting metrics to ELK : $StatusCode"
                        #DEBUG#Write-Host $url
                    }
                }
            }
            
        }#}).TotalMilliseconds
        
        
        return $TRUE
    }
    [bool] IntegrateToELKWithCustomTerm ($apps,$Config,$CustomTerm,$CustomValue){
        #(Measure-Command {
        foreach ($app in $apps) { 
            #$metrics = $appdy.GetMetricsHierarchy($app.id,"Overall Application Performance")
        
            foreach ($metricPath in $Config.metricPaths) {
                $Appmetrics = $this.GetIndividualMetricsJSON($app.id,$metricPath,$Config.collect_metrics_last_mins)
                #DEBUG#Write-Host " N of Metricas ($metricPath) : " + $Appmetrics.Count
                if ($Appmetrics.Count -ne 0) {
                    $allMetrics = @()
                    foreach ($metrics in $Appmetrics) {
                        #DEBUG#Write-Host "Metric Values from" $metrics.metricName ":" $metrics.metricValues.Count
                        $regex = "(.*)\|(.*)$"
                        $metrics.metricPath -match $regex
                        $metricPrefix = $Matches[1]
                        $metricName = $Matches[2]
                        
                        foreach ($metric in $metrics.metricValues) {
                            $metricTemplate = [PSCustomObject]::new
                
                            $metricTemplate = [PSCustomObject] @{
                                AppName = $app.name
                                AppID = $app.id
                                Metric = $metricName
                                MetricPath = $metricPrefix
                                FullPath = ($app.name+"|"+$metrics.metricPath)
                                Value = $metric.value
                                Min = $metric.min 
                                Max = $metric.max
                                MetricTime = $metric.startTimeInMillis
                                $CustomTerm = $CustomValue
                            }
                            $allMetrics += $metricTemplate
                            #$metricTemplate
                        }
                        
                    }
                    #Add-Content -Path (".\metrics_" + $app.name + ".log") -Value ($allMetrics | ConvertTo-Json) -PassThru
                    $headers_elk = [System.Collections.Generic.Dictionary[[String],[String]]]::new()
                    $headers_elk.Add('Content-type', "application/json")
                    
                    
                    $url = $Config.elk_host_port
                    #Write-Host $url
                    try
                    {
                        Invoke-WebRequest -Uri $url -Headers $headers_elk -Body ($allMetrics | ConvertTo-Json) -Method Post -UseBasicParsing
                    }
                    catch
                    {
                        $StatusCode = $_.Exception.Response.StatusCode.value__
                        #DEBUG#Write-Host $_.Exception.Response
                        #DEBUG#Write-Host $_.Exception.Message
                        #DEBUG#Write-Host "Error posting metrics to ELK : $StatusCode"
                        #DEBUG#Write-Host $url
                    }
                }
            }
            
        }#}).TotalMilliseconds
        
        
        return $TRUE
    }
    [bool] IntegrateOneAPPToELK ([string]$app,$Config){
        $appID = $this.GetAppID($app)
        foreach ($metricPath in $Config.metricPaths) {
            $Appmetrics = $this.GetIndividualMetricsJSON($appID,$metricPath,$Config.collect_metrics_last_mins)
            #DEBUG#Write-Host " N of Metricas ($metricPath) : " + $Appmetrics.Count
            if ($Appmetrics.Count -ne 0) {
                $allMetrics = @()
                foreach ($metrics in $Appmetrics) {
                    #DEBUG#Write-Host "Metric Values from" $metrics.metricName ":" $metrics.metricValues.Count
                    $regex = "(.*)\|(.*)$"
                    $metrics.metricPath -match $regex
                    #DEBUG#Write-Host "Metric Path: "$metrics.metricPath
                    $metricPrefix = $Matches[1]
                    $metricName = $Matches[2]
                    
                    foreach ($metric in $metrics.metricValues) {
                        $metricTemplate = [PSCustomObject]::new
            
                        $metricTemplate = [PSCustomObject] @{
                            AppName = $app
                            AppID = $appID
                            Metric = $metricName
                            MetricPath = $metricPrefix
                            FullPath = ($app+"|"+$metrics.metricPath)
                            Value = $metric.value
                            Min = $metric.min 
                            Max = $metric.max
                            MetricTime = $metric.startTimeInMillis
                        }
                        $allMetrics += $metricTemplate
                        #$metricTemplate
                    }
                    
                }
                #Add-Content -Path (".\metrics_" + $app.name + ".log") -Value ($allMetrics | ConvertTo-Json) -PassThru
                $headers_elk = [System.Collections.Generic.Dictionary[[String],[String]]]::new()
                $headers_elk.Add('Content-type', "application/json")
                
                
                $url = $Config.elk_host_port
                #Write-Host $url
                try
                {
                    Invoke-WebRequest -Uri $url -Headers $headers_elk -Body ($allMetrics | ConvertTo-Json) -Method Post -UseBasicParsing
                }
                catch
                {
                    $StatusCode = $_.Exception.Response.StatusCode.value__
                    #DEBUG#Write-Host $_.Exception.Response
                    #DEBUG#Write-Host $_.Exception.Message
                    #DEBUG#Write-Host "Error posting metrics to ELK : $StatusCode"
                    #DEBUG#Write-Host $url
                }
            }
        }
        
        
        return $TRUE
    }
    [bool] IntegrateOneAPPToELKWithCustomTerm ([string]$app,$Config,$CustomTerm,$CustomValue){
        $appID = $this.GetAppID($app)
        foreach ($metricPath in $Config.metricPaths) {
            $Appmetrics = $this.GetIndividualMetricsJSON($appID,$metricPath,$Config.collect_metrics_last_mins)
            #DEBUG#Write-Host " N of Metricas ($metricPath) : " + $Appmetrics.Count
            if ($Appmetrics.Count -ne 0) {
                $allMetrics = @()
                foreach ($metrics in $Appmetrics) {
                    #DEBUG#Write-Host "Metric Values from" $metrics.metricName ":" $metrics.metricValues.Count
                    $regex = "(.*)\|(.*)$"
                    $metrics.metricPath -match $regex
                    $metricPrefix = $Matches[1]
                    $metricName = $Matches[2]
                    
                    foreach ($metric in $metrics.metricValues) {
                        $metricTemplate = [PSCustomObject]::new
            
                        $metricTemplate = [PSCustomObject] @{
                            AppName = $app
                            AppID = $appID
                            Metric = $metricName
                            MetricPath = $metricPrefix
                            FullPath = ($app+"|"+$metrics.metricPath)
                            Value = $metric.value
                            Min = $metric.min 
                            Max = $metric.max
                            MetricTime = $metric.startTimeInMillis
                            $CustomTerm = $CustomValue
                        }
                        $allMetrics += $metricTemplate
                        #$metricTemplate
                    }
                    
                }
                #Add-Content -Path (".\metrics_" + $app.name + ".log") -Value ($allMetrics | ConvertTo-Json) -PassThru
                $headers_elk = [System.Collections.Generic.Dictionary[[String],[String]]]::new()
                $headers_elk.Add('Content-type', "application/json")
                
                
                $url = $Config.elk_host_port
                #Write-Host $url
                try
                {
                    Invoke-WebRequest -Uri $url -Headers $headers_elk -Body ($allMetrics | ConvertTo-Json) -Method Post -UseBasicParsing
                }
                catch
                {
                    $StatusCode = $_.Exception.Response.StatusCode.value__
                    #DEBUG#Write-Host $_.Exception.Response
                    #DEBUG#Write-Host $_.Exception.Message
                    #DEBUG#Write-Host "Error posting metrics to ELK : $StatusCode"
                    #DEBUG#Write-Host $url
                }
            }
        }
        
        
        return $TRUE
    }
    [System.Object[]] GetMetricsHierarchy ($appID,$metricPath){
        $metricPath = [uri]::EscapeDataString($metricPath)
        
        $url = $this.baseurl+"/controller/rest/applications/$appID/metrics?metric-path=$metricPath&output=JSON"
        #DEBUG#Write-Host $url
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
            $content = $responseData.content

            $metrics = (($content | ConvertFrom-Json) | Where-Object {$_.metricName -ne "METRIC DATA NOT FOUND"})
            #Write-Host $metrics | Format-Table
            return $metrics
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return [System.Object]::new()
        }

    }
    [pscustomobject] GetMetricsJSON2 ($appID,$metricPath,$params){
        $metricPath = [uri]::EscapeDataString($metricPath)
        $params = [uri]::EscapeDataString($params)
        $url = $this.baseurl+"/controller/rest/applications/$appID/metric-data?metric-path=$metricPath&$params"+"&output=JSON"
        #Write-Host $url
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
            $content = $responseData.content

            $metrics = (($content | ConvertFrom-Json) | Where-Object {$_.metricName -ne "METRIC DATA NOT FOUND"})
            #Write-Host $metrics | Format-Table
            return $metrics
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return [System.Object]::new()
        }

    }
    [xml] GetMetrics ($appID,$metricPath,$duration){
        $metricPath = [uri]::EscapeDataString($metricPath)
        
        $url = $this.baseurl+"/controller/rest/applications/$appID/metric-data?metric-path=$metricPath&time-range-type=BEFORE_NOW&duration-in-mins=$duration"#+"&output=JSON"
        #DEBUG#Write-Host $url
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
            $content = $responseData.content

            $metrics = [xml]$content
            #$metrics = $responseData.content | ConvertFrom-Json

            
            <# foreach ($item in $metrics.'metric-datas'.'metric-data') {
                if ($item.metricValues.count -gt 0) {
                    #DEBUG#Write-Host $item.metricValues.count

                }
                
                
            } #>
            #Write-Host $metrics | Get-Member
            #Write-Host $metrics | Out-String
            return $metrics
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.headers["Authorization"]
            return [xml]::new()
        }

    }
    [AppdynamicsMetrics] ParseMetrics($app,[xml]$metrics){
        #Write-Host $metrics | Out-String
        [AppdynamicsMetrics]$appMetrics = [AppdynamicsMetrics]::new($app,@())
        try {
            #Write-Host $metrics | Out-String
            #$metrics2 = $metrics.'metric-datas'.'metric-data'
            $metrics2 = $metrics.SelectNodes('descendant::metric-datas/metric-data')
            #DEBUG#Write-Host $metrics2.count
            #$metrics.metricPath -match '(.*)\|(.*)'
            #$Matches[0]
            #Write-Host $Matches[1]

            #Write-Host $metrics2.count
            #Write-Host "Teste " $metrics2.metricName
            if ($metrics2.count -gt 1) {
                #DEBUG#Write-Host "GT 1"
                foreach ($appMetric in $metrics2) {  
                    $metricName = $appMetric.metricPath

                    #DEBUG#Write-Host $metricName

                    if (-not ($null -eq $metrics2.metricValues.'metric-value') -and (-not ($appMetric.metricName -eq "METRIC DATA NOT FOUND"))) {
                        $appMetric.metricPath -match '(.*)\|(.*)'
                        $Matches[0]
                        #DEBUG#Write-Host $Matches[2]
                        $metricName = $appMetric.metricPath
                        $metricValues = $metrics2.SelectNodes('descendant::metricValues/metric-value')

                        #DEBUG#Write-Host "Type: "$metricValues.GetType()

                        #DEBUG#Write-Host "MetricName: $metricName metrics count: "+ $metricValues.count
                        if ($metricValues.count -gt 0) {
                            #foreach ($metricValue in $metricValues) {
                                #Write-Host $metricValue
                                #Write-Host $metricName+$metricValue.value+$metricValue.sum+$metricValue.count+$metricValue.max+$metricValue.current+$metricValue.standardDeviation
                                $appMetrics.metrics.Add([AppdynamicsMetric]::new($metricName,$metricValues.LastChild.value,$metricValues.LastChild.sum,$metricValues.LastChild.count,$metricValues.LastChild.max,$metricValues.LastChild.current,$metricValues.LastChild.standardDeviation))                       
                            #}
                        }
                        
                        
                    }
                }
            }
            elseif ([int]$metrics.count -eq 1 ) {
                if (-not ($null -eq $metrics.metricValues)) {

                    $metricName = $metrics.metricPath
                    #DEBUG#Write-Host $metricName
                    $metric = $metrics.'metricValues'.'metric-value'
                    $appMetrics.metrics.Add([AppdynamicsMetric]::new($metricName,$metric.value,$metric.sum,$metric.count,$metric.max,$metric.current,$metric.standardDeviation))
                    
                    #DEBUG#Write-Host $metric.'metricValues'.'metric-value'.count
                }
            }
            else {
                #DEBUG#Write-Host "eq 0"
            }
        }
        catch {
            #DEBUG#Write-Host $_.Exception.Message
        }
        
        
        return $appMetrics
    }
    [AppdynamicsMetrics] ParseMetricsJSON($app,[System.Object[]]$metrics,[string]$prefixRegex){
        #Write-Host $metrics | Out-String
        [AppdynamicsMetrics]$appdynamicsMetrics = [AppdynamicsMetrics]::new($app,@())

        $Data = @()
        
        foreach ($metric in $metrics) {
            try {
                [System.Object[]] $appMetrics = $metric.metricValues

                #DEBUG#Write-Host $appMetrics.count
                $regex = $prefixRegex + "\|(.*)$"
                $metrics.metricPath -match $regex
                $metricPrefix = $Matches[1]
                $metricName = $Matches[2]

                [AppdynamicsMetricGroup]$appdynamicsMetricGroup = [AppdynamicsMetricGroup]::new($metricPrefix,@())

                if ($appMetrics.count -gt 1 ) {

                    #DEBUG#Write-Host $metricPrefix
                    
                    #Write-Host $metric.metricValues | Format-Table -a
                    
                    #Write-Host $appMetrics.count
                    foreach ($appMetric in $appMetrics) {                    
                        if (-not ($null -eq $metrics.sum)) {
                            $Data.Add([PSCustomObject]@{App=$app;Name=$metricPrefix;$metricName=$appMetric.value})
                            $appdynamicsMetricGroup.metrics.Add([AppdynamicsMetric]::new($metricName,$appMetric.value,$appMetric.sum,$appMetric.count,$appMetric.max,$appMetric.current,$appMetric.standardDeviation))
                            
                            #DEBUG#Write-Host $appdynamicsMetricGroup | Format-Table
                            
                        }
                    }
                }
                elseif ($appMetrics.count -eq 1) {

                    $regex = $prefixRegex + "\|(.*)$"
                    $metrics.metricPath -match $regex
                    $metricPrefix = $Matches[1]
                    $metricName = $Matches[2]
                    #DEBUG#Write-Host $metricPrefix

                    $appdynamicsMetricGroup.metrics.Add([AppdynamicsMetric]::new($metricName,$appMetrics.value,$appMetrics.sum,$appMetrics.count,$appMetrics.max,$appMetrics.current,$appMetrics.standardDeviation))
                    

                }
                else {
                    #DEBUG#Write-Host "eq 0"
                }
            }
            catch {
                #DEBUG#Write-Host $_.Exception.Message
            }

            
        }
        $Obj = @{}
        #DEBUG#Write-Host "Teste"
        foreach ($Group in ($Data | Group-Object Name)) {
            #DEBUG#Write-Host $Group
            #$Obj[$Group.Name] = ($Group.Group | Select-Object -Expand Type)
        }

        #$Obj | ConvertTo-Json

        #Write-Host $Obj | Format-Table
        return $appdynamicsMetrics
    }
    [AppdynamicsMetrics] CreateAppMetrics ($app,[array]$metrics){
        [AppdynamicsMetrics]$appMetrics = [AppdynamicsMetrics]::new($app)
        foreach ($metric in $metrics) {

            [AppdynamicsMetric]::new()
        }

        return [AppdynamicsMetric]::new()
    }
    [PSCustomObject] GetTierPerformanceSummary ($app,$duration){
        #$metricBasePath = [uri]::EscapeDataString($app)
        
        #$metricBasePath = [uri]::EscapeDataString("Overall Application Performance|*|")
        $metricBasePath = "Overall Application Performance|*|"
        $metricsToCollect = ("Calls per Minute","Average Response Time (ms)","Errors per Minute","Number of Slow Calls","Number of Very Slow Calls","Stall Count","Exceptions per Minute") 


        [array]$allMetrics = @()
        
        foreach ($metricToCollect in $metricsToCollect) {
            $test = $metricBasePath+$metricToCollect
            $result = ($this.GetMetricsJSON($app,$metricBasePath+$metricToCollect,$duration))
            $allMetrics+=$result
        }
        
        ## Begin PArse

        [PSCustomObject]$appdynamicsMetricGroup = New-Object -TypeName PSObject -Property @{
            metrics = @{}
        }

        #Write-Host $allMetrics | Format-Table
        foreach ($metrics in $allMetrics) {
            foreach ($metric in $metrics) {
                try {
                    [psobject]$appMetrics = $metric.metricValues

                    $prefixRegex = "\|(.*)"
                    $regex = $prefixRegex + "\|(.*)$"
                    $metrics.metricPath -match $regex
                    $metricPrefix = $Matches[1]
                    $metricName = $Matches[2]

                    if ($appMetrics.count -gt 0) {

                        $regex = $prefixRegex + "\|(.*)$"
                        $metrics.metricPath -match $regex
                        $metricPrefix = $Matches[1]
                        $metricName = $Matches[2]

                        foreach ($appMetric in $appMetrics) {
                            $metricValues = New-Object -TypeName PSObject -Property @{$metricName = @{value = ($appMetric.value);sum = $appMetric.sum; count = $appMetric.count;max = $appMetric.max;current = $appMetric.current;min = $appMetric.min}} 
                            try {
                                # Append
                                if ($null = $appdynamicsMetricGroup.metrics[$metricPrefix]) {
                                    $appdynamicsMetricGroup.metrics.$metricPrefix | Add-Member -MemberType NoteProperty -Name $metricName -Value @{value = ($appMetric.value);sum = $appMetric.sum; count = $appMetric.count;max = $appMetric.max;current = $appMetric.current;min = $appMetric.min}
                                }
                                # Create
                                else {
                                    $appdynamicsMetricGroup.metrics[$metricPrefix] += $metricValues
                                }
                            }
                            catch {
                                #DEBUG#Write-Host $_.Exception.Message
                            }
                        }
                    }
                    else {
                        #DEBUG#Write-Host "metrics eq 0"
                    }
                }
                catch {
                    #DEBUG#Write-Host $_.Exception.Message
                }

                
            }
        }

        #Write-Host ($appdynamicsMetricGroup | ConvertTo-Json)
        #Write-Host ($appdynamicsMetricGroup.GetType())

        ##### Final parse
        $result = ''
        return $appdynamicsMetricGroup

    }
    [PSCustomObject] GetAllTierPerformanceSummary ($app,$duration){

        #$metricBasePath = [uri]::EscapeDataString($app)     
        #$metricBasePath = [uri]::EscapeDataString("Overall Application Performance|*|")
        $metricBasePath = "Overall Application Performance|*|"
        $metricsToCollect = ("Calls per Minute","Average Response Time (ms)","Errors per Minute","Number of Slow Calls","Number of Very Slow Calls","Stall Count","Exceptions per Minute") 
        $metricALL = "Overall Application Performance|*|*"

        [array]$allMetrics = @()
        
        if ($app -eq "ALL") {

            ### Multithread
            $MaxThreads = 16

            #Remove all jobs
            Get-Job | Remove-Job
            
            $apps = $this.GetApplications()
            $count = $apps.applications.application.count
            #DEBUG#Write-Host  $(Get-Date)" - Starting collecting metrics from "$count" applications"

            $listApps = $apps.applications.application
            
            #$script:steps = $listApps.count + 2
            $stepCounter = 0
            #Write-ProgressHelper -Message 'Starting Multithread Collector' -StepNumber ($stepCounter++)

            $jobParam = @{metricALL = ($metricALL);duration = $duration;url = $this.baseurl;headers = $this.headers; stepCounter = $stepCounter }
            
            #$listApps = @(
            #    @{name = "HML_CORPORATE_MANAGEDPORTFOLIO"},
            #    @{name = "PRD_XP_EBIX"})

            $results = Start-MultiThreadAppdyJobs -list $listApps -script './AppdyMultiMetrics.ps1' -maxThreads $MaxThreads -params $jobParam
            #Write-Host "Results: "$results.count
            $allMetrics += $results
            <# foreach ($result in $results) {
                $allMetrics += $result
            } #>
            #DEBUG#Write-Host (Get-Date)" - Finished collecting metrics from "$count" applications"
            
        }
        else{
            foreach ($metricToCollect in $metricsToCollect) {
                $test = $metricBasePath+$metricToCollect
                $result = ($this.GetMetricsJSON($app,$metricBasePath+$metricToCollect,$duration))
                $allMetrics+=$result
            }
        }
        
        ## Begin PArse

        [PSCustomObject]$appdynamicsMetricGroup = New-Object -TypeName PSObject -Property @{
            metrics = @{}
        }

        #DEBUG#Write-Host "AllMetrics count: "$allMetrics.Count
        $count = 0
        foreach ($allMetric in $allMetrics) {
            #Write-Progress -Id 1 -Activity "Total metrics to parse: $($allMetrics.Count)" -PercentComplete (($count/$allMetrics.Count)*100) -Status 'Parsing Metrics.'
            #Write-Host "Metrics count: "$metrics.Count
            $metrics = $allMetric | ConvertFrom-Json
            foreach ($metric in $metrics) {
                try {
                    [string]$tempMetrics = $metric.metricValues
                    $tempMetrics = (((($tempMetrics -replace "@","[") -replace "=",":") -replace ";",",") -replace "([a-z]+)",'"$1"') + "]"

                    try {
                        $appMetrics = ($tempMetrics | ConvertFrom-Json)
                    }
                    catch {
                        $_.Exception.Message
                        $_.Exception.Data
                        #DEBUG#Write-Host $tempMetrics
                        $appMetrics = $tempMetrics
                    }
                    
                    $appName = $metric.AppName

                    $prefixRegex = "\|(.*)"
                    $regex = $prefixRegex + "\|(.*)$"
                    $metric.metricPath -match $regex
                    $metricPrefix = $Matches[1]
                    $metricName = $Matches[2]

                    #Write-Host $metricPrefix " - " $metricName
                    #Write-Host "Metrics count " $appMetrics.count
                    if ($appMetrics.count -gt 0) {

                        $regex = $prefixRegex + "\|(.*)$"
                        $metrics.metricPath -match $regex
                        #$metricPrefix = $Matches[1]
                        $metricPrefix = $appName + "@" + $Matches[1]
                        $metricName = $Matches[2]

                        
                        #Write-Host $appMetrics.GetType()

                        #foreach ($appMetric in $appMetrics) {
                            $metricValues = New-Object -TypeName PSObject -Property @{$metricName = @{value = ($appMetrics.value);sum = $appMetrics.sum; count = $appMetrics.count;max = $appMetrics.max;current = $appMetrics.current;min = $appMetrics.min}} 
                            try {
                                # Append
                                if ($null = $appdynamicsMetricGroup.metrics[$metricPrefix]) {
                                    <# if ($metricPrefix -eq "Corporate.FixedIncome.Order.Registration.Api") {
                                        #DEBUG#Write-Host $metricPrefix $metricName $appMetrics.sum
                                    } #>

                                    if ($null -eq $appdynamicsMetricGroup.metrics.$metricPrefix.$metricName ) {
                                        $appdynamicsMetricGroup.metrics.$metricPrefix | Add-Member -MemberType NoteProperty -Name $metricName -Value @{value = ($appMetrics.value);sum = $appMetrics.sum; count = $appMetrics.count;max = $appMetrics.max;current = $appMetrics.current;min = $appMetrics.min}
                                    }
                                    else {
                                        #Write-Host $metricPrefix $metricName $appMetrics.sum $appdynamicsMetricGroup.metrics.$metricPrefix.$metricName.sum
                                        $appdynamicsMetricGroup.metrics.$metricPrefix.$metricName.value += $appMetrics.value
                                        $appdynamicsMetricGroup.metrics.$metricPrefix.$metricName.sum += $appMetrics.value
                                        $appdynamicsMetricGroup.metrics.$metricPrefix.$metricName.max += $appMetrics.max
                                        $appdynamicsMetricGroup.metrics.$metricPrefix.$metricName.sum += $appMetrics.sum
                                        $appdynamicsMetricGroup.metrics.$metricPrefix.$metricName.count += $appMetrics.count
                                        $appdynamicsMetricGroup.metrics.$metricPrefix.$metricName.min += $appMetrics.min
                                        $appdynamicsMetricGroup.metrics.$metricPrefix.$metricName.current += $appMetrics.current
                                        #Write-Host $metricPrefix $metricName $appMetrics.sum $appdynamicsMetricGroup.metrics.$metricPrefix.$metricName.sum
                                    }
                                    
                                }
                                # Create
                                else {
                                    $appdynamicsMetricGroup.metrics[$metricPrefix] += $metricValues
                                }
                            }
                            catch {
                                #DEBUG#Write-Host $_.Exception.Message
                                #DEBUG#Write-Host $_.Exception.Data
                                #DEBUG#Write-Host $metricName $metricPrefix
                            }
                        #}
                    }
                    else {
                        #DEBUG#Write-Host "metrics eq 0"
                    }
                }
                catch {
                    #DEBUG#Write-Host $_.Exception.Message
                    #DEBUG#Write-Host $_.Exception.Data
                    #Write-Host $metric | Out-String
                    #Write-Host $metric.metricValues.keys
                }

                
            }
            $count += 1
        }

        #Write-Host ($appdynamicsMetricGroup | ConvertTo-Json)
        #Write-Host ($appdynamicsMetricGroup.GetType())

        ##### Final parse
        $result = ''
        return $appdynamicsMetricGroup

    }
    [PSCustomObject] AppendSummaryMetrics ($metrics){
        foreach ($metric in $metrics.metrics.keys) {

            $errors = $metrics.metrics[$metric].'Errors per Minute'.sum
            $calls = $metrics.metrics[$metric].'Calls per Minute'.sum
            $slows = $metrics.metrics[$metric].'Number of Slow Calls'.sum
            $verySlows = $metrics.metrics[$metric].'Number of Very Slow Calls'.sum
            $stalls = $metrics.metrics[$metric].'Stall Count'.sum
            #Write-Host $metric
            #Write-Host $metrics.metrics[$metric].keys
            if ($calls -gt 0) {
                ## Errors %
                try {
                    $errorsPercent = [math]::Round((($errors*100)/$calls),2)
                    if ($errorsPercent -gt 100) {
                        $errorsPercent = 100
                    }
                }
                catch {
                    $errorsPercent = 0
                }
                $metrics.metrics.$metric | Add-Member -MemberType NoteProperty -Name 'Errors %' -Value @{value = $errorsPercent}

                ## Score Card
                try {
                    $scoreCard = [math]::Round(((($calls - $errors - $verySlows - $slows - $stalls)*100)/$calls),2)
                    if ($scoreCard -lt 0) {
                        $scoreCard = 0
                    }
                }
                catch {
                    $scoreCard = 0
                }
                

                $metrics.metrics.$metric | Add-Member -MemberType NoteProperty -Name 'Score Card' -Value @{value = $scoreCard}
            }
            else{
                $metrics.metrics.$metric | Add-Member -MemberType NoteProperty -Name 'Errors %' -Value @{value = 0}
                $metrics.metrics.$metric | Add-Member -MemberType NoteProperty -Name 'Score Card' -Value @{value = 0}
            }
             
        }
        #Write-Host $metrics.metrics.GetType()
        return $metrics
    }
    [PSCustomObject] CreateTierReport ($metrics){
        $report = @()
        foreach ($metric in $metrics.metrics.keys) {
            $errors = $metrics.metrics[$metric].'Errors %'.value
            $calls = $metrics.metrics[$metric].'Calls per Minute'.sum
            $scoreCard = $metrics.metrics[$metric].'Score Card'.value
            $errorrnumber = $metrics.metrics[$metric].'Errors per Minute'.sum
            $slows = $metrics.metrics[$metric].'Number of Slow Calls'.sum
            $verySlows = $metrics.metrics[$metric].'Number of Very Slow Calls'.sum
            $stalls = $metrics.metrics[$metric].'Stall Count'.sum
            
            $avgRT = $metrics.metrics[$metric].'Average Response Time (ms)'.value

            #$report += @{Tier = $metric; Calls = $calls; 'Avg RT (ms)' = $avgRT; 'Errors %' = $errors; 'Score Card' = $scoreCard}
            $report += @{Tier = $metric; Calls = $calls; 'Avg_RT' = $avgRT; 'Errors_Perc' = $errors; 'Score_Card' = $scoreCard; 'Errors' = $errorrnumber; 'Slows' = $slows; 'Very_Slow' = $verySlows; 'Stalls' = $stalls  }
        }

        return $report
    }
    [PSCustomObject] CreateTierReportCSV ($metrics){
        $report = @()
        $countElement = 0
        $columns = ""
        foreach ($metric in $metrics.metrics.keys) {
            if ($countElement -eq 0) {
                
                $columns = "Tier,"
                ($metrics.metrics.$metric.PSObject.Properties.Name | ForEach-Object{ $columns += $_ +','})
                #$report += ($columns + "`n")
                $countElement = 1
            }
            $errors = 0
            $errors = $errors + [float]($metrics.metrics[$metric].'Errors %'.value)
            $calls = 0
            $calls = $calls + [int]$metrics.metrics[$metric].'Calls per Minute'.sum
            $scoreCard = 0
            $scoreCard = $scoreCard + [float]$metrics.metrics[$metric].'Score Card'.value
            $errorrnumber = 0
            $errorrnumber = $errorrnumber + [int]$metrics.metrics[$metric].'Errors per Minute'.sum
            $slows = 0
            $slows = $slows + [int]$metrics.metrics[$metric].'Number of Slow Calls'.sum
            $verySlows = 0
            $verySlows = $verySlows + [int]$metrics.metrics[$metric].'Number of Very Slow Calls'.sum
            $stalls = 0
            $verySlows = $verySlows + [int]$metrics.metrics[$metric].'Stall Count'.sum
            
            $avgRT = $metrics.metrics[$metric].'Average Response Time (ms)'.value
            
            $metric -match "(.*)@(.*)"
            $app = $Matches[1]
            $tier =$Matches[2]

            $report += [PSCustomObject]@{AppTier = "$app-$tier";Application = $app;Tier = $tier; Calls = $calls; 'Avg_RT' = $avgRT; 'Errors_Perc' = $errors; 'Score_Card' = $scoreCard; 'Errors' = $errorrnumber; 'Slows' = $slows; 'Very_Slows' = $verySlows; 'Stalls' = $stalls}
            #$report += ($metric+","+$calls+","+$avgRT+","+$errors+","+$scoreCard+"`r`n")
        }
        #Write-Host $metrics.metrics | ConvertTo-Csv
        #Write-Host $report | 
        <# $teste2 = $report | ForEach-Object {
            [PSCustomObject]@{
            Tier = $_.Tier
            Calls = $_.Calls
            'Avg RT (ms)' = $_.'Avg RT (ms)'
            'Errors %' = $_.'Errors %'
            'Score Card' = $_.'Score Card'
            }
        } #>
        #Write-Host ($teste2)
        #$teste2 | Export-Csv '/Users/dieperei/Documents/Development/Powershell/tiers.csv' -delimiter "," -force -notypeinformation
        #$report | Export-Csv '/Users/dieperei/Documents/Development/Powershell/tiers2.csv' -delimiter "," -force -notypeinformation
        #Write-Host $teste
        return $report
    }
    [bool] SetAnalytics ($APPDApiKey, $accountName) {
        #DEBUG#Write-Host "$APPDApiKey - $accountName"
        $this.analyticsAPIKey = $APPDApiKey
        $this.accountName = $accountName
        return $TRUE
    }
    [pscustomobject] GetAnalyticsSavedSearchs ($id){
        
        #Write-Host $this.analyticsAPIKey"-"$this.accountName
        $this.analyticsHeaders.'X-Events-API-Key' = $this.analyticsAPIKey
        $this.analyticsHeaders.'X-Events-API-AccountName' = $this.accountName


        $url = $this.baseurl +"/analyticsSavedSearches/getAnalyticsSavedSearchById/$id"
        #Write-Host $url
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.analyticsHeaders  -Method Get -UseBasicParsing
            #[pscustomobject] $metrics = ($responseData | ConvertFrom-Json) 
            #Write-Host $responseData | Format-Table
            #return $metrics
            return $responseData
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.analyticsHeaders["X-Events-API-Key"]
            #DEBUG#Write-Host $this.analyticsHeaders["X-Events-API-AccountName"]
            return [pscustomobject]::new()
        }

    }
    [pscustomobject] GetAnalyticsEvents ($query,$param){
        
        #Write-Host $this.analyticsAPIKey"-"$this.accountName
        $this.analyticsHeaders.'X-Events-API-Key' = $this.analyticsAPIKey
        $this.analyticsHeaders.'X-Events-API-AccountName' = $this.accountName

        $body = $query
        $url = $this.analyticsurl+"/events/query?$param"
        #Write-Host $url
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.analyticsHeaders -Body $body -Method Post -UseBasicParsing
            [pscustomobject] $metrics = ($responseData | ConvertFrom-Json) 
            #Write-Host $responseData | Format-Table
            return $metrics
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.analyticsHeaders["X-Events-API-Key"]
            #DEBUG#Write-Host $this.analyticsHeaders["X-Events-API-AccountName"]
            return [pscustomobject]::new()
        }

    }
    [string] CreateAnalyticsSchema ($index,$schema){
        
        #Write-Host $this.analyticsAPIKey"-"$this.accountName
        $this.analyticsHeaders.'X-Events-API-Key' = $this.analyticsAPIKey
        $this.analyticsHeaders.'X-Events-API-AccountName' = $this.accountName
        
        $url = $this.analyticsurl+"/events/schema/$index"
        #Write-Host $url
        try
        {
            Invoke-RestMethod -Uri $url -Headers $this.analyticsHeaders -Body $schema -Method Post -ContentType 'application/vnd.appd.events+json'  -UseBasicParsing
             
            #Write-Host $responseData | Format-Table
            return $index
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $schema
            #DEBUG#Write-Host $this.analyticsHeaders["Content-Encoding"]
            #DEBUG#Write-Host $this.analyticsHeaders["X-Events-API-Key"]
            #DEBUG#Write-Host $this.analyticsHeaders["X-Events-API-AccountName"]
            if ($StatusCode -eq 409) {
                return "$index Already Exist"
            }
            else {
                return "Error: "+$_.Exception.Message
            }
        }

    }
    [bool] PublishAnalyticsEvents ($index,$data){
        $data2 = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($data))
        #Write-Host $this.analyticsAPIKey"-"$this.accountName
        $this.analyticsHeaders.'X-Events-API-Key' = $this.analyticsAPIKey
        $this.analyticsHeaders.'X-Events-API-AccountName' = $this.accountName
        
        $url = $this.analyticsurl+"/events/publish/"+$index
        #DEBUG#Write-Host $url
        

        #DEBUG#$metricsCount = ($data | ConvertFrom-Json).count
        $bucketList = @()
        $bucket = @()
        $bucketCount = 0
        #DEBUG#Write-Host "Metricas : $metricsCount"

        $json = @()
        try {
            $json = ($data2 | ConvertFrom-Json)
        }
        catch {
            $data2 | Out-File -Path "DebugPublishEvents.log"
            return $false
        }
        if ($json.count -gt 1) {
            foreach ($metricData in $json) {
            
            
                if ($bucketCount -gt 998) {
                    #$bucket | ConvertTo-Json | Out-File -FilePath ('./json' + $bucketList.count + '.json')
                    $body = ($bucket | ConvertTo-Json)
                    #$body  | Out-File -FilePath ('./jsonDiego123.json')
                    #Write-Host $body
                    #Write-Host ($this.analyticsHeaders | ConvertTo-Json)
                    #Write-Host $url
                    #Write-Host $bucket.count
                    
                    #Write-Host (Invoke-RestMethod -Uri $url -Headers $this.analyticsHeaders -Body $bucket -ContentType "application/vnd.appd.events+json" -Method Post  -UseBasicParsing)
                    #$bucketList += $bucket
                    
                    #Write-Host "Rodei post"
                    try
                    {
                        $responseData = Invoke-WebRequest -Uri $url -Headers $this.analyticsHeaders -Body ($bucket | ConvertTo-Json) -Method Post  -UseBasicParsing 
                        #$responseData = @{result = "OK"}
                        
                        Write-Host $responseData.Response 
                        #Write-Host $responseData.StatusCode
                        Write-Host $responseData
                    }
                    catch
                    {
                        $StatusCode = $_.Exception.Response.StatusCode.value__
                        #DEBUG#Write-Host $_.Exception.Response
                        #DEBUG#Write-Host $_.Exception.Message
                        #DEBUG#Write-Host $_.Exception
                        
                        #DEBUG#Write-Host "Error getting apps : $StatusCode"
                        #DEBUG#Write-Host $url
                        #Write-Host $data
                        #DEBUG#Write-Host $this.analyticsHeaders["Content-Type"]
                        #DEBUG#Write-Host $this.analyticsHeaders["X-Events-API-Key"]
                        #DEBUG#Write-Host $this.analyticsHeaders["X-Events-API-AccountName"]
                        #return ""
                    }
                    #DEBUG#Write-Host "Enviado Bucket - 1000"
                    $bucket = @()
                    $bucketCount = 0
                } 

                $bucket += $metricData

                $bucketCount++
                #Write-Host $bucketCount
            }
            $response = Invoke-WebRequest -Uri $url -Headers $this.analyticsHeaders -Body ($bucket | ConvertTo-Json) -Method Post  -UseBasicParsing 
            Write-Host $response
            #Write-Host $responseData
            $bucketList += $bucket
        }
        else {
            $response = Invoke-WebRequest -Uri $url -Headers $this.analyticsHeaders -Body ($json | ConvertTo-Json -AsArray) -Method Post  -UseBasicParsing 
        }
        
        #Write-Host $this.analyticsHeaders | ConvertTo-Json

        #Invoke-RestMethod -Uri $url -Headers $this.analyticsHeaders -Body $bucket -Method Post -UseBasicParsing
        
        #$bucket | ConvertTo-Json | Out-File -FilePath ('./json' + $bucketList.count + '.json')
        #Write-Host "Buckets : "$bucketList.Count
        #Write-Host $bucketList.GetType()
        #foreach ($bucketData in $bucketList) {
            #$bucketData | ConvertFrom-Json | Out-File -FilePath ('./jsonTestDiego' + $bucketList.count + '.json')
            #Write-Host "Conteudo TIPO :" ($bucketData.GetType())
            
        #}
        return $TRUE
        

    }
    [pscustomobject] GetAnalyticsSchema ($index){
        
        #Write-Host $this.analyticsAPIKey"-"$this.accountName
        $this.analyticsHeaders.'X-Events-API-Key' = $this.analyticsAPIKey
        $this.analyticsHeaders.'X-Events-API-AccountName' = $this.accountName


        $url = $this.analyticsurl+"/events/schema/$index"
        #Write-Host $url
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.analyticsHeaders -Method Get -UseBasicParsing
            [pscustomobject] $metrics = ($responseData | ConvertFrom-Json) 
            #Write-Host $responseData | Format-Table
            return $metrics
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.analyticsHeaders["X-Events-API-Key"]
            #DEBUG#Write-Host $this.analyticsHeaders["X-Events-API-AccountName"]
            return [pscustomobject]::new()
        }

    }
    [pscustomobject] DeleteAnalyticsSchema ($index){
        
        #Write-Host $this.analyticsAPIKey"-"$this.accountName
        $this.analyticsHeaders.'X-Events-API-Key' = $this.analyticsAPIKey
        $this.analyticsHeaders.'X-Events-API-AccountName' = $this.accountName


        $url = $this.analyticsurl+"/events/schema/$index"
        #Write-Host $url
        try
        {
            $responseData = Invoke-WebRequest -Uri $url -Headers $this.analyticsHeaders -Method Delete -UseBasicParsing
            #[pscustomobject] $metrics = ($responseData | ConvertFrom-Json) 
            #Write-Host $responseData | Format-Table
            return $responseData
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            #DEBUG#Write-Host $_.Exception.Response
            #DEBUG#Write-Host $_.Exception.Message
            #DEBUG#Write-Host "Error getting apps : $StatusCode"
            #DEBUG#Write-Host $url
            #DEBUG#Write-Host $this.analyticsHeaders["X-Events-API-Key"]
            #DEBUG#Write-Host $this.analyticsHeaders["X-Events-API-AccountName"]
            return [pscustomobject]::new()
        }

    }

}

Function GetAppEvents {
    param ($app,$params)
    #DEBUG#Write-Host $app.name
    #DEBUG#Write-Host $params
    $url = $params.url+"/controller/rest/applications/"
    $finalUrl = "/events"+"?output=JSON&time-range-type=BEFORE_NOW&duration-in-mins="+$params.duration+"&event-types=APPLICATION_DEPLOYMENT&severities=INFO"
    #DEBUG#Write-Host $finalUrl
    try
    {
        $urlFinal = $url + $app.id + $finalUrl 
        #$urlFinal = $url + "21829" + $finalUrl 
        #Write-Host $urlFinal
        $responseData = Invoke-WebRequest -Uri $urlFinal -Headers $params.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
        $content = $responseData.content
        <# #DEBUG#Write-Host $content.GetType()
        #DEBUG#Write-Host $content
        #DEBUG#Write-Host $content.count #>
        if ($content -ne "[]") {
            #DEBUG#Write-Host $content
            
        }
    }
    catch
    {
        $StatusCode = $_.Exception.Response.StatusCode.value__
        #DEBUG#Write-Host $_.Exception.Response
        #DEBUG#Write-Host $_.Exception.Message
        #DEBUG#Write-Host "Error sending event : $StatusCode"
        #DEBUG#Write-Host $url
        #DEBUG#Write-Host $this.headers["Authorization"]
    }

}

function Start-MultiThreadAppdyJobs {
    param (
        $list,$params,$script,$maxThreads
    )
    $results = @()

    #DEBUG#Write-Host  $(Get-Date)" - Started Multithread"
    #Write-ProgressHelper -Message 'Starting Multithread Collector' -StepNumber ($params.stepCounter++)

    $block = {
        Param([string] $app)
        #Write-Host "MultiThread app "$app
    }
    #Remove all jobs
    Get-Job | Remove-Job | Out-Null
    #$MaxThreads = 40

    $count = $list.count
    $count2 = 0
    $jobs = @()
    foreach($app in $list){
        #Write-Progress -Id 1 -Activity "Total Jobs to send: $($list.Count)" -PercentComplete (($count2/$list.Count)*100) -Status 'Starting multithread for data extraction.'
        While ($(Get-Job -state running).count -ge $maxThreads){
            Start-Sleep -Milliseconds 3
        }
        #Start-Job -Scriptblock $Block -ArgumentList $app.name
        #Write-Host "Job "$app.name 
        #Write-Host $params.keys
        $jobs += Start-Job -FilePath $script -ArgumentList $app.name, $params
        $count = $count -1
        $count2 += 1
        #Write-Host "Count = "$count
    }

    #DEBUG#Write-Host  $(Get-Date)" - Finished Multithread"
    #Wait for all jobs to finish.
    $countRemaining = 0
    While ($(Get-Job -State Running).count -gt 0){
        $count = $(Get-Job -State Running).count
        #DEBUG#Write-Host $count
        start-sleep 1
        $countRemaining += 1
    }
    #Get information from each job.

    #DEBUG#Write-Host "Jobs "$jobs.count
    $count = 0
    foreach($job in $jobs){
        #Write-Progress -Id 1 -Activity "Total Jobs to collect: $($jobs.count)" -PercentComplete (($count/$jobs.count)*100) -Status 'Collecting Data from Jobs.'
        #Write-Host $job | Format-Table
        #$results += Receive-Job -Id ($job.Id) | out-file ./jobs.log -append
        Receive-Job -Id ($job.Id) -ErrorVariable remoteErr -OutVariable output | Out-Null
        $results += $output #| ConvertFrom-Json
        $count += 1
        #Write-Host $output
    }
    #Write-Host $results
    return $results
}

function Start-MultiThreadAppdyEvents {
    param (
        $list,$params,$maxThreads
    )
    $results = @()

    #DEBUG#Write-Host  $(Get-Date)" - Started Multithread"
    #Write-Host $params.headers
    #Write-Host $params.url
    #Write-ProgressHelper -Message 'Starting Multithread Collector' -StepNumber ($params.stepCounter++)

    $block = {
        Param([string] $app)
        #Write-Host "MultiThread app "$app
    }
    #Remove all jobs
    Get-Job | Remove-Job | Out-Null
    #$MaxThreads = 40

    $count = $list.count
    $count2 = 0
    $jobs = @()
    foreach($app in $list){
        #Write-Progress -Id 1 -Activity "Total Jobs to send: $($list.Count)" -PercentComplete (($count2/$list.Count)*100) -Status 'Starting multithread for data extraction.'
        While ($(Get-Job -state running).count -ge $maxThreads){
            Start-Sleep -Milliseconds 3
        }
        #Start-Job -Scriptblock $Block -ArgumentList $app.name
        #Write-Host "Job "$app.name 
        #Write-Host $params.keys
        #$jobs += Start-Job -InitializationScript $functions -ScriptBlock $script -ArgumentList $app, $params
        $script = './AppdyMultiEvents.ps1'

        $jobs += Start-Job -FilePath $script -ArgumentList $app.id, $params
        $count = $count -1
        $count2 += 1
        #Write-Host "Count = "$count
    }

    #DEBUG#Write-Host  $(Get-Date)" - Finished Multithread"
    #Wait for all jobs to finish.
    While ($(Get-Job -State Running).count -gt 0){
        $count = $(Get-Job -State Running).count
        #DEBUG#Write-Host $count
        start-sleep 1
    }
    #Get information from each job.

    #DEBUG#Write-Host $(Get-Date)" - Jobs: "$jobs.count
    $count = 0
    foreach($job in $jobs){
        #Write-Progress -Id 1 -Activity "Total Jobs to collect: $($jobs.count)" -PercentComplete (($count/$jobs.count)*100) -Status 'Collecting Data from Jobs.'
        #Write-Host $job | Format-Table
        #$results += Receive-Job -Id ($job.Id) | out-file ./jobs.log -append
        Receive-Job -Id ($job.Id) -ErrorVariable remoteErr -OutVariable output | Out-Null
        #Write-Host $remoteErr
        if ($output -ne "" ) {
            $results += $output #| ConvertFrom-Json
        }
        
        $count += 1
        #Write-Host $output
    }
    #Write-Host $results
    return $results
}

function Get-AuthorizationHeader{
    param (
        $pair
    )
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $basicAuthValue = "Basic $base64"
    return $basicAuthValue
}

function GetMetricsJSON($baseurl,$headers,[string]$app,$metricPath,$duration) {
    
    $metricPath = [uri]::EscapeDataString($metricPath)
    $app2 = [uri]::EscapeDataString($app)    
    $url = $baseurl+"/controller/rest/applications/$app2/metric-data?metric-path=$metricPath&time-range-type=BEFORE_NOW&duration-in-mins=$duration"+"&output=JSON"
    #Write-Host $url
    #$url | Out-File -Path ("Appdy_test"+$app2+".log") -Append
    try
    {
        $responseData = Invoke-WebRequest -Uri $url -Headers $headers -Method Get -ContentType 'text/xml' -UseBasicParsing
        $content = $responseData.content
        #$content | Out-File -Path ("Appdy_test"+$app2+".log") -Append
        [pscustomobject]$metrics = ([pscustomobject]($content | ConvertFrom-Json) | Where-Object {$_.metricName -ne "METRIC DATA NOT FOUND"})
        #$metrics | ConvertTo-Json | Out-File -Path ("Appdy_test"+$app2+".log") -Append
        if ($metrics -ne $NULL) {
            $metrics | Add-Member -MemberType NoteProperty -Name 'AppName' -Value $app
            $metrics | Add-Member -MemberType NoteProperty -Name 'Error' -Value $FALSE
        }
        else {
            #$app + " - Nulo" | Out-File -Path ("Appdy_test"+$app2+".log") -Append
            #$url | Out-File -Path ("Appdy_test"+$app2+".log") -Append
            $metrics = [pscustomobject]::new()
            $metrics | Add-Member -MemberType NoteProperty -Name 'AppName' -Value $app
            $metrics | Add-Member -MemberType NoteProperty -Name 'Error' -Value $FALSE
            return $metrics
        }
        
        #Write-Host $metrics | ConvertTo-Json
        return $metrics
    }
    catch
    {
        $status_code = $_.Exception.Response.StatusCode.value__
        #Write-Host $_.Exception.Response
        $error_message = $_.Exception.Message
        #Write-Host "Error getting metrics : $StatusCode"
        #Write-Host $url
        #Write-Host $this.headers["Authorization"]
        $metrics = [pscustomobject]::new()
        $metrics | Add-Member -MemberType NoteProperty -Name 'AppName' -Value $app
        $metrics | Add-Member -MemberType NoteProperty -Name 'Error' -Value $TRUE
        $metrics | Add-Member -MemberType NoteProperty -Name 'Error Message' -Value "$status_code - $error_message"
        return $metrics
    }
    
}
function ConvertTo-UnixTimestamp {
	$epoch = Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0	
 	$input | ForEach-Object {		
		$milliSeconds = [math]::truncate($_.ToUniversalTime().Subtract($epoch).TotalMilliSeconds)
		Write-Output $milliSeconds
	}	
}