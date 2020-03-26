
function GetMetricsJSON($baseurl,$headers,[string]$app,$metricPath,$duration) {
    
    $metricPath = [uri]::EscapeDataString($metricPath)
    $app2 = [uri]::EscapeDataString($app)    
    $url = $baseurl+"/controller/rest/applications/$app2/metric-data?metric-path=$metricPath&time-range-type=BEFORE_NOW&duration-in-mins=$duration"+"&output=JSON"
    #Write-Host $url
    try
    {
        $responseData = Invoke-WebRequest -Uri $url -Headers $headers -Method Get -ContentType 'text/xml' -UseBasicParsing
        $content = $responseData.content
        [pscustomobject]$metrics = ([pscustomobject]($content | ConvertFrom-Json) | Where-Object {$_.metricName -ne "METRIC DATA NOT FOUND"})
        $metrics | Add-Member -MemberType NoteProperty -Name 'AppName' -Value $app
        #Write-Host $metrics | ConvertTo-Json
        return $metrics
    }
    catch
    {
        $StatusCode = $_.Exception.Response.StatusCode.value__
        Write-Host $_.Exception.Response
        Write-Host $_.Exception.Message
        Write-Host "Error getting apps : $StatusCode"
        Write-Host $url
        Write-Host $this.headers["Authorization"]
        return [pscustomobject]::new()
    }
    
}

$result = GetMetricsJSON -baseurl $($args[1]).url -headers $($args[1]).headers -app $($args[0]) -metricPath $($args[1]).metricALL -duration $($args[1]).duration

# APP NAME
#Write-Output $($args[0])
# PARAMS
#Write-Output $($args[1])

#Write-Host $result
Write-Output ($result | ConvertTo-Json )
