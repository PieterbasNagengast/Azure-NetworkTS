# Azure-NetworkTS
Azure Networking Troubleshooting

This repository contains a Azure deployment template for two Virtual machines in separate Subnmets but in a single VNET.
Deployiong this template allows you to use Azure Network troubleshooting tools like Network Watcher, NSG Flow Logs, and Diagnostics logs to troubleshoot network issues.
There are three pre-defined scenarios avaialble in the template to simulate network issues. Those scenarios are described below as if it was a description of a customer issue / support ticket.

The key here is to not only understand the issue but also to understand the tools and resources available in Azure to troubleshoot the issue without signing in to the VM's.

## Deployment steps

1. Clone the repository
2. Open the Azure Cloud Shell
3. Change the directory to the cloned repository
4. Run the following command to deploy the template

```bash
az deployment group create --resource-group <resource-group-name> --template-file azuredeploy.json --parameters azuredeploy.parameters.json
```

5. Once the deployment is complete, you can access the resources in the Azure Portal.
6. To simulate the network issues, you can use the pre-defined scenarios and then use the Azure Network troubleshooting tools to troubleshoot the issues.
7. If you have successfully troubleshooted the issue you can re-deploy the template (go to step 4) to reset the resources and select the next scenario to troubleshoot.
7. Once you are done with the troubleshooting, you can delete the resource group to clean up the resources.
8. To delete the resource group, run the following command in the Azure Cloud Shell

```bash
az group delete --name <resource-group-name> --yes --no-wait
```

## Tools to use for troubleshooting

- Azure Network Watcher
- IP Flow Verify
- NSG Diagnostics
- Next Hop
- Effective Routes
- Effective Security Rules
- Connection Troubleshoot

## Diagram of the deployment

![Dagram of deployment including all resources](media/Azure-NetworkTS.svg)

## Scenario A: FrontEnd VM cannot connect via RDP to BackeEnd VM

The FrontEnd VM cannot connect to BackEnd VM on RDP (TCP port 3389). Both VM's are in separate Subnets but in same VNET. Both VM's don't have Public IP Addresses assigned as our security policy doens't allow Public IP's to be assigned to VM's. Also a UDR's (Route Table) has been assigned to both subnets. Both Subnets have separate Network Security Groups (NSG's) associated with them. VNET is using Azure provided DNS server.

## Scenario B: VM's cannot connect to Internet

The VM's seem to have some issues connecting to Internet. Both VM's are in separate Subnets but in same VNET. Both VM's don't have Public IP Addresses assigned as our security policy doens't allow Public IP's to be assigned to VM's. Both Subnets have separate Network Security Groups (NSG's) associated with them. Also a UDR's (Route Table) has been assigned to both subnets. VNET is using Azure provided DNS server.

## Scenario C: Backend VM cannot connect to FrontEnd VM

We want to be able to connect from BackEndVM to FrontEnd VM on port 3389 (RDP). Both VM's are in separate Subnets but in same VNET. It seems like the subnet where BackEndVM is located is completely isolated. None of our tests where succesful. Both VM's don't have Public IP Addresses assigned as our security policy doens't allow Public IP's to be assigned to VM's. Both Subnets have separate Network Security Groups (NSG's) associated with them. Also a UDR's (Route Table) has been assigned to both subnets. VNET is using Azure provided DNS server.

