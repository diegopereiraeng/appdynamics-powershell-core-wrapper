Using module './Appdynamics.psm1' 

$auth = Get-AuthorizationHeader -pair "user@account:password"

$appdy = [Appdynamics]::new("https://customer.saas.appdynamics.com",$auth)

$appdy.GetLogin()

$regex = "Coc.*"

$filePath = "custom.json"

$reportName = "Overall Dashboard "

$appdy.ReplicateDashboard($reportName,$filePath,$regex)
