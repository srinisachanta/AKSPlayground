#V1 version
az login
az extension list
# if not present 
az extension add -n aks-preview
or 
az extension update -n aks-preview


az feature register --name AAD-V2 --namespace Microsoft.ContainerService

# contains doesn't in git bash/powershell. Works in python!
az feature list --query "[?contains(name,'Microsoft.ContainerService/AAD-V2')].{Name:name,State:properties.state}" 

az feature list --query "[?name=='Microsoft.ContainerService/AAD-V2'].{Name:name,State:properties.state}"

az provider register --namespace Microsoft.ContainerService

az ad group create --display-name AKSAdmins --mail-nickname AKSAdmins

az ad group member add --group 00000000-0000-0000-0000-000000000000 --member-id 00000000-0000-0000-0000-000000000000 

az ad group member check --group 00000000-0000-0000-0000-000000000000 --member-id 00000000-0000-0000-0000-000000000000 


# AKS Variables

$clusterCentralUSName = "AKSTheRightWay-CentralUS"
$clusterCentralUSResourceGroupName = "AKSTheRightWay-CentralUS-RG"
$location="centralus"
$nodeCentralUSResourceGroupName="AKSTheRightWayNodePool-CentralUS-RG"
$nodeCentralUSDevNodePoolName="aksdevpool" #alphanumeirc small
$clusterCentralUSSubNet="AKSTheRightWay-CentralUS-SubNet"
$adminCentralUSWorkSpace="Azure-CentralUS-WS"
$adminCentralUSRG="Admin-CentralUS-RG"
$adminCentralUSVNet="Azure-CentralUS-VNet"
$clusterCentralUSSubNet="AKSTheRightWay-CentralUS-SubNet"
$clusterAdminGroupId=$(az ad group list --display-name AKSAdmins --query "[].objectId")


#az network vnet list `
#    --resource-group $adminCentralUSRG `
#    --query "[0].id" --output tsv

#az network vnet subnet list `
#    --resource-group $adminCentralUSRG `
#    --vnet-name  $adminCentralUSVNet `
#    --query "[?contains(name, 'AKSTheRightWayCentralUSSubNet')].id" --output tsv


# http://www.subnet-calculator.com/cidr.php
az network vnet create -g $adminCentralUSRG -n $adminCentralUSVNet --address-prefix 10.0.0.0/17 `
    --subnet-name $clusterCentralUSSubNet --subnet-prefix 10.0.0.0/23 --location $location

$clusterCentralUSSubNetID=$(az network vnet subnet list `
    --resource-group $adminCentralUSRG `
    --vnet-name  $adminCentralUSVNet `
    --query "[?contains(name, '$clusterCentralUSSubNet')].id" --output tsv)


#az network vnet delete --name $adminCentralUSVNet --resource-group  $adminCentralUSRG 


# create log analytics workspace in centralus
az  deployment group create --resource-group $adminCentralUSRG --name $adminCentralUSWorkSpace  --template-file deploylaworkspacetemplate.json


az group create --name $clusterCentralUSResourceGroupName --location $location
$adminCentralUSWorkSpaceId=$(az monitor log-analytics workspace list --query "[?contains(name, '$adminCentralUSWorkSpace')].id" --output tsv)


#az aks list
# couldnt include userdefinedroute without configuring route table
az aks create   --name $clusterCentralUSName `
                --resource-group $clusterCentralUSResourceGroupName `
                --network-plugin azure `
                --vnet-subnet-id $clusterCentralUSSubNetID `
                --docker-bridge-address 172.17.0.1/16 `
                --dns-service-ip 10.2.0.10 `
                --service-cidr 10.2.0.0/24 `
                --max-pods 50 `
                --vm-set-type VirtualMachineScaleSets `
                --load-balancer-sku standard `
                --node-resource-group $nodeCentralUSResourceGroupName `
                --nodepool-name $nodeCentralUSDevNodePoolName `
                --node-count 3 `
                --node-vm-size Standard_DS2_v2 `
                --zones 1 2 3 `
                --enable-cluster-autoscaler `
                --min-count 3 `
                --max-count 5 `
                --network-policy azure `
                --enable-addons monitoring `
                --enable-managed-identity `
                --aad-admin-group-object-ids $clusterAdminGroupId `
                --workspace-resource-id $adminCentralUSWorkSpaceId `
                --generate-ssh-keys 

