# Import Appdy Wrapper
Using module './Appdynamics.psm1' 

#Import Config 
$Config = Get-Content ./appdy-elk-config.json |  ConvertFrom-Json

# create an object instance of wrapper class
$appdy = [Appdynamics]::new($Config.controller_address,$Config.authorization)

#Login into Appdynamics 
$appdy.GetLogin()

# Get All Applications
$apps = $appdy.GetApplications()

# Variables for examples below:

$CustomTerm = "Test Name"
$CustomValue = "Test 123 2020-02-07"
$appName = "FAC-PRD"

# Integrate With ELK all appdy Apps - arguments: [Apps - List], Config File

$appdy.IntegrateToELK($apps.applications.application,$Config)

# Integrate With ELK one appdy App - arguments: [Single App Name], Config File

$appdy.IntegrateOneAPPToELK($appName,$Config)

# Integrate With ELK all appdy Apps + Custom Term and Value - arguments: [Apps - List], Config File, Custom Column, Custom Value

$appdy.IntegrateToELKWithCustomTerm($apps.applications.application,$Config,$CustomTerm,$CustomValue)

# Integrate With ELK one appdy App + Custom Term and Value - arguments: [Single App Name], Config File, Custom Column, Custom Value

$appdy.IntegrateOneAPPToELKWithCustomTerm($appName,$Config,$CustomTerm,$CustomValue)
