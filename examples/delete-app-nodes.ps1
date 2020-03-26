Using module './Appdynamics.psm1' 

$auth = Get-AuthorizationHeader -pair "user@account:password"

$appdy = [Appdynamics]::new("https://customer.saas.appdynamics.com",$auth)

$appdy.GetLogin()

$nodes = $appdy.GetNodes(16)

foreach ($node in $nodes.nodes.node) {
    $appdy.DeleteNode($node.id)
    $node.id
    
}

$appdy.DeleteNode("1110")