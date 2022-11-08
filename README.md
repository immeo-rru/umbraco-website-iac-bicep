# Bicep-files for deploying an Umbraco/commerce resources in Azure 
This repo contains bicep files for deploying a complete infrastructure for a site, infrastructure as code (IaC). 

It is complete example for deploying a website containing many resources and this is the _how to guide_. 

You can deploy the files here - they work :-)

## Prerequisites
You will need to have two things ready before start deploying:
1. an **existing resource group** in Azure where resourcer are created
2. the **ID of an Azure AD group** which is used by the SQL Server


## 'Changethis'
Some of the bicep files have the string "changethis" multiple places. You will need to take action and _change this_ or somehow change the file before it can be used in production.

## Running the example
Open a terminal such as powershell. We will need this for logging in to Azure to use the Azure-CLI to deploy the bicep-files.

In powershell log in using the following command:
```powershell
az login --tenant [xxx].onmicrosoft.com
```
where <code>xxx</code> is the tenant you will log in to.

After logging in start the deployment

```PowerShell 
az deployment group create \
  --resource-group [your resource group] \
  --template-file ./main.bicep \
  --parameters \
    applicationName=[name of your solution] \ 
    deploymentEnvironment=test \
    adGroupsChangeThisId=[ID of an existing AD group]
```

An example:
```PowerShell 
az deployment group create \
  --resource-group rg-rrutest-test-weu \
  --template-file ./main.bicep \
  --parameters applicationName=myapp deploymentEnvironment=test adGroupsChangeThisId=8e56e122-...
```

## Demo

https://user-images.githubusercontent.com/58074583/196007873-da7100e1-a13c-4642-9be7-681121c7ba8f.mp4

## Demo result

![image](https://user-images.githubusercontent.com/58074583/200167295-a8bd7058-ee54-449c-9a05-6a52ba376b10.png)


