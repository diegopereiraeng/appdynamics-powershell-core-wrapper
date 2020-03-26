Using module './Appdynamics.psm1' 

$auth = Get-AuthorizationHeader -pair "user@account:password"

$appdy = [Appdynamics]::new("https://customer.saas.appdynamics.com",$auth)

$result = $appdy.GetLogin()

$apps = $appdy.GetApplications()

foreach ($app in $apps.applications.application) {
    $nodes = $appdy.GetNodesJSON($app.id)
    Write-Host $app.name
    #Write-Host $app.id

    foreach ($node in $nodes) {
        $nodeInfo = $appdy.GetNodeInfo($node.id)
        $nodeStatus = $appdy.GetNodeStatus($node.id)
        $app.name + "," + $app.id + "," + $node.id + "," + $nodeInfo.name + "," + $nodeInfo.machineName + "," + $nodeInfo.applicationComponentName + "," + $nodeInfo.appAgent.installTime + "," + $nodeInfo.appAgent.lastStartTime + "," + $nodeInfo.numberOfLicenseUnits + "," + $nodeInfo.lastKnownTierAppConfig + "," + $nodeStatus.percentage | Out-File -Append -Path "agents.log"
        <# Write-Host $nodeInfo.name
        Write-Host $nodeInfo.machineName
        Write-Host $nodeInfo.applicationComponentName
        Write-Host $nodeInfo.appAgent.installTime
        Write-Host $nodeInfo.appAgent.lastStartTime #>
    }
}
