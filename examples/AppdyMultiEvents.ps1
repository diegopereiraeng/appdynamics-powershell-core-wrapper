Function GetAppEvents {
    param ($app,$params)
    
    $url = $params.url+"/controller/rest/applications/"
    $finalUrl = "/events"+"?output=JSON&time-range-type=BEFORE_NOW&duration-in-mins="+$params.duration+"&event-types=APPLICATION_DEPLOYMENT&severities=INFO"

    try
    {
        $urlFinal = $url + $app + $finalUrl 
        #$urlFinal = $url + "21829" + $finalUrl 
        #Write-Host $urlFinal
        $responseData = Invoke-WebRequest -Uri $urlFinal -Headers $params.headers -Method Get -ContentType 'text/xml' -UseBasicParsing
        $content = $responseData.content
        <# Write-Host $content.GetType()
        Write-Host $content
        Write-Host $content.count #>
        if ($content -ne "[]") {
            return $content
            
        }
        else {
            return ""
        }
    }
    catch
    {
        $StatusCode = $_.Exception.Response.StatusCode.value__
        Write-Host $_.Exception.Response
        Write-Host $_.Exception.Message
        Write-Host "Error sending event : $StatusCode"
        Write-Host $url
        Write-Host $this.headers["Authorization"]
    }

}

$result = GetAppEvents -app $($args[0]) -params $($args[1])

# APP NAME
#Write-Output $($args[0])
# PARAMS
#Write-Output $($args[1])

#Write-Host $result
Write-Output $result
