Using module './Appdynamics.psm1' 

#$mode = "Delete"

$mode = "List Nodes"

$auth = "Basic "

$auth = Get-AuthorizationHeader -pair "user@account:password

$appdy = [Appdynamics]::new("https://customer.saas.appdynamics.com",$auth)

$result = $appdy.GetLogin()

Write-Host "Login="$result

$apps = $appdy.GetApplications()

$metricTime = "129600" # 90 dias

$metric = "Overall Application Performance|Calls per Minute"

foreach ($app in $apps.applications.application)
{
    $metrics = $appdy.GetMetrics($app.id, $metric, $metricTime)
    
    if (-not ($null -eq $metrics.'metric-datas'.'metric-data'.metricValues.'metric-value')) {
        $sum = $metrics.'metric-datas'.'metric-data'.metricValues.'metric-Value'.sum
        Write-Host $app.name",Calls per minute,"$sum        
    }
    else {
        Write-Host $app.name",No Calls,0"

        if ($mode -eq "List Nodes") {
            $nodes = $appdy.GetNodesJSON($app.id)
            foreach ($node in $nodes) {
                $app.name+","+$node.name | Out-File -Append -FilePath "Nodes.log"
            }
        }
        elseif ($mode -eq "Delete") {

            ## DELETA APP
            $result = $appdy.DeleteApplication($app.id)
            Write-Host "Delete "$app.name" com sucesso"
        }

    }

}