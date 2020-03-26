Using module './Appdynamics.psm1' 

$auth = Get-AuthorizationHeader -pair "user@account:password"

$appdy = [Appdynamics]::new("https://customer.saas.appdynamics.com",$auth)

$appID = "20231"

$appdy.GetLogin()
$appdy.GetFileToken()



$appdy.fileToken

$appdy.ImportHealthRules($appID,"health.json")
$appdy.ImportActions($appID,"actions.json")
$appdy.ImportPolicies($appID,"policies.json")
$appdy.UploadAppConfig("App_Template_Config.xml")
$appdy.ImportAppConfig($appID)