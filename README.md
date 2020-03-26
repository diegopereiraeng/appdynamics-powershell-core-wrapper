# appdynamics-powershell-core-wrapper

I started developing this wrapper to help our customer to use public and internal Appdynamics APIs with Powershell, so everyone can get appdynamics information with no Appdynamics API knowledge.

This Wrapper could help our customers to automate their pipelines, improve integrations, data extraction and others.

I have created some scripts using this wrapper for different proposes, and I'm sharing with all of you, so you can have some ideas how to use it.

# Installation

Note that you only need to put the file **Appdynamics.psm1** inside your script folder to use the Module.

# USAGE Examples

## Simple Rest

	Using module './Appdynamics.psm1'

	$auth = Get-AuthorizationHeader -pair "user@account:password"

	$appdy = [Appdynamics]::new("https://customer.saas.appdynamics.com",$auth)

	$appID = $appdy.GetAppID("APP_NAME")

	Write-Host "AppID : $appID"

	$tierID = $appdy.GetTierID($appID, "XP.FixedIncome.Asset.Web")

	appdy.SendEvent("New Deployment Diego", "This is a test", "INFO", "VSTS", $tierName, $appID,$tierID)


## Simple Rest-UI

	Using module './Appdynamics.psm1'

	$auth = Get-AuthorizationHeader -pair "user@account:password"

	$appdy = [Appdynamics]::new("https://customer.saas.appdynamics.com",$auth)

	$appdy.GetLogin()

	$appName = "Diego Test 123"

	$appDescription = "Test App"

	$tierName = "TestDiego123"

	$appID = $appdy.CreateApplication($appName,$appDescription)

	$tierID = $appdy.CreateTierNET($appID,$tierName)

	$appdy.GetTiers("21086")

	$appdy.GetNodes($app.id)

	$apps = $appdy.GetApplications()

## Tiers per application

	foreach ($tier in $tiers.tiers.tier) {

		Write-Host "`nID: "$tier.id" `nName: "$tier.name"

	}

## Nodes per application

  	foreach ($app in $apps.applications.application) {

		Write-Host "`nID: "$app.id" `nName: "$app.name" `nDescription: "$app.description

		$nodes = $appdy.GetNodes($app.id)

		foreach ($node in $nodes.nodes.node) {

			Write-Host ($app.name + "," + $node.name)
		
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

	Write-Host "Append Metrics"

	$metrics2 = $appdy.AppendSummaryMetrics($metrics)

	Write-Host $metrics2 | Out-String

	Write-Host "Creating Report"

	$report = $appdy.CreateTierReportCSV($metrics)

	Write-Host "Exporting to CSV"

	$report | Export-Csv '/Users/dieperei/Documents/Development/Powershell/tiers4.csv' -delimiter "," -force -notypeinformation

# ALL Methods


## AppendSummaryMetrics - Arguments: \$metrics - Return: [PSCustomObject]

## CreateAnalyticsSchema - Arguments: \$index,\$schema - Return: [string]

## CreateApplication - Arguments: [string]\$appName,[string]\$appDescription - Return: [string]

## CreateAppMetrics - Arguments: \$app,[array]\$metrics - Return: [AppdynamicsMetrics]

## CreateTierNET - Arguments: [string]\$appID,[string]\$tierName - Return: [string]

## CreateTierReport - Arguments: \$metrics - Return: [PSCustomObject]

## CreateTierReportCSV - Arguments: \$metrics - Return: [PSCustomObject]

## CreateUploadBody - Arguments: [string]\$filePath - Return: [String]]]

## DeleteAnalyticsSchema - Arguments: \$index - Return: [pscustomobject]

## DeleteApplication - Arguments: [string]\$appID - Return: [bool]

## DeleteNode - Arguments: [string]\$node - Return: [bool]

## GetAllTierPerformanceSummary - Arguments: \$app,\$duration - Return: [PSCustomObject]

## GetAnalyticsEvents - Arguments: \$query,\$param - Return: [pscustomobject]

## GetAnalyticsSavedSearchs - Arguments: \$id - Return: [pscustomobject]

## GetAnalyticsSchema - Arguments: \$index - Return: [pscustomobject]

## GetFileToken - Arguments:  - Return: [bool]

## GetIndividualMetricsJSON - Arguments: \$appID,\$metricPath,\$duration - Return: []]

## GetMetrics - Arguments: \$appID,\$metricPath,\$duration - Return: [xml]

## GetMetricsHierarchy - Arguments: \$appID,\$metricPath - Return: []]

## GetMetricsJSON - Arguments: \$appID,\$metricPath,\$duration - Return: []]

## GetNodes - Arguments: \$appID,\$tierID - Return: []]

## GetTierPerformanceSummary - Arguments: \$app,\$duration - Return: [PSCustomObject]

## ImportActions - Arguments: [string]\$appID,[string]\$filePath - Return: [bool]

## ImportAppConfig - Arguments: [string]\$appID - Return: [bool]

## ImportExitPoints - Arguments: \$appID,[System.Object[]]\$eps - Return: [bool]

## ImportHealthRules - Arguments: [string]\$appID,[string]\$filePath - Return: [bool]

## ImportPolicies - Arguments: [string]\$appID,[string]\$filePath - Return: [bool]

## IntegrateOneAPPToELK - Arguments: [string]\$app,\$Config - Return: [bool]

## IntegrateOneAPPToELKWithCustomTerm - Arguments: [string]\$app,\$Config,\$CustomTerm,\$CustomValue - Return: [bool]

## IntegrateToELK - Arguments: \$apps,\$Config - Return: [bool]

## IntegrateToELKWithCustomTerm - Arguments: \$apps,\$Config,\$CustomTerm,\$CustomValue - Return: [bool]

## PublishAnalyticsEvents - Arguments: \$index,\$data - Return: [bool]

## ReplicateDashboard - Arguments: \$dashName,\$template,\$regex - Return: [bool]

## ServiceManifestAppend - Arguments: [string]\$appName,[string]\$tierName, [string]\$xmlFile, \$agentType - Return: [bool]

## ServiceManifestGetAppVersion - Arguments: [string]\$xmlFile - Return: [string]

## ServiceManifestGetTierName - Arguments: [string]\$xmlFile - Return: [string]

## ServiceManifestSetAppName - Arguments: [string]\$xmlFile,\$appName,\$environment - Return: [string]

## SetAnalytics - Arguments: \$APPDApiKey, \$accountName - Return: [bool]

## UploadAppConfig - Arguments: [string]\$filePath - Return: [bool]

## UploadDashboard - Arguments: [string]\$filePath - Return: [bool]

## UploadDashboardFile - Arguments: [String]\$fileEnc - Return: [bool]