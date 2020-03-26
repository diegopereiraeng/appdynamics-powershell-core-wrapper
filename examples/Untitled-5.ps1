function Get-Login([string]$user) {

    $url = "https://customer.saas.appdynamics.com/controller/auth?action=login"

    $responseData = Invoke-RestMethod -Uri $url -Headers @{Authorization = "Basic " } -Method GET -ContentType 'text/xml' 
    $responseData
    $content = $responseData.content

    [xml]$apps = $content
    foreach ($app in $apps.applications.application)
    {
        if ($app.name -eq $appName){
            return $app.id,$app.description}
    }
    $appID = 0
    $comment = ""
    return $appID,$comment
}

$appID,$cdescription = Get-ApplicationID -appName $appName