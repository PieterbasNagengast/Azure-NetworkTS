@description('region to deploy the resources')
param location string = resourceGroup().location

@allowed([
  'A'
  'B'
  'C'
])
@description('The troubleshooting scenario to deploy. Start with Scenario A.')
param tsScenario string

@secure()
@description('The password for the VM.')
param adminPassword string = newGuid()

@description('Admin username for the VM.')
param adminUsername string = 'NetworkTSUser'

@description('The IP address space for the virtual network.')
param ipaddressSpace array = [
  '10.0.0.0/24'
]

@description('The name of the virtual network.')
param vnetName string = 'vnet'

// variables
// The names of the virtual machines
var vmNames = [
  'vm-FrontEnd'
  'vm-BackEnd'
]

// The network security group and route table configurations for each scenario
var scenarios = {
  A: {
    nsg: [
      {
        name: 'nsg-FrontEnd'
        rules: [
          {
            name: 'nsgrule'
            properties: {
              protocol: 'Tcp'
              sourcePortRange: '*'
              destinationPortRange: '3389'
              sourceAddressPrefix: '*'
              destinationAddressPrefix: '*'
              access: 'Deny'
              priority: 100
              direction: 'Outbound'
            }
          }
        ]
      }
      {
        name: 'nsg-BackEnd'
        rules: []
      }
    ]
    udr: {
      name: 'RouteTable'
      routes: []
    }
  }
  B: {
    nsg: [
      {
        name: 'nsg-FrontEnd'
        rules: []
      }
      {
        name: 'nsg-BackEnd'
        rules: []
      }
    ]
    udr: {
      name: 'RouteTable'
      routes: [
        {
          name: 'route1'
          properties: {
            addressPrefix: '0.0.0.0/0'
            nextHopType: 'VirtualAppliance'
            nextHopIpAddress: '1.2.3.4'
          }
        }
      ]
    }
  }
  C: {
    nsg: [
      {
        name: 'nsg-FrontEnd'
        rules: []
      }
      {
        name: 'nsg-BackEnd'
        rules: [
          {
            name: 'nsgrule1'
            properties: {
              protocol: 'Tcp'
              sourcePortRange: '*'
              destinationPortRange: '3389'
              sourceAddressPrefix: '*'
              destinationAddressPrefix: cidrSubnet(ipaddressSpace[0], 25, 0)
              access: 'Allow'
              priority: 200
              direction: 'Outbound'
            }
          }
          {
            name: 'nsgrule2'
            properties: {
              protocol: 'Tcp'
              sourcePortRange: '*'
              destinationPortRange: '3389'
              sourceAddressPrefix: '*'
              destinationAddressPrefix: '*'
              access: 'Deny'
              priority: 100
              direction: 'Outbound'
            }
          }
        ]
      }
    ]
    udr: {
      name: 'RouteTable'
      routes: [
        {
          name: 'route1'
          properties: {
            addressPrefix: cidrSubnet(ipaddressSpace[0], 25, 0)
            nextHopType: 'None'
          }
        }
      ]
    }
  }
}

// get the scenario configuration
var scenario = scenarios[tsScenario]

// deploy the resources in the region using AVM modules
// deploy the network security groups
module nsg 'br/public:avm/res/network/network-security-group:0.1.2' = [for nsg in scenario.nsg: {
  name: 'deploy-${nsg.name}'
  params: {
    name: nsg.name
    location: location
    securityRules: !empty(nsg.rules) ? nsg.rules : []
  }
}]

// deploy the route table
module routeTable 'br/public:avm/res/network/route-table:0.2.1' = {
  name: 'deploy-routeTable'
  params: {
    name: scenario.udr.name
    location: location
    routes: !empty(scenario.udr.routes) ? scenario.udr.routes : []
  }
}

// deploy the virtual network
module vnet 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: 'deploy-vnet'
  params: {
    name: vnetName
    location: location
    addressPrefixes: ipaddressSpace
    subnets: [
      {
        name: 'subnet1'
        networkSecurityGroupResourceId: nsg[0].outputs.resourceId
        addressPrefix: cidrSubnet(ipaddressSpace[0], 25, 0)
        routeTableResourceId: routeTable.outputs.resourceId
      }
      {
        name: 'subnet2'
        networkSecurityGroupResourceId: nsg[1].outputs.resourceId
        addressPrefix: cidrSubnet(ipaddressSpace[0], 25, 1)
        routeTableResourceId: routeTable.outputs.resourceId
      }
    ]
  }
}

// deploy the virtual machines
module vm 'br/public:avm/res/compute/virtual-machine:0.2.1' = [for (vmName, i) in vmNames: {
  name: 'deploy-${vmName}'
  params: {
    name: vmName
    location: location
    vmSize: 'Standard_B2s'
    osType: 'Windows'
    encryptionAtHost: false
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: '128'
      managedDisk: {
        storageAccountType: 'Standard_LRS'
      }
    }
    adminUsername: adminUsername
    adminPassword: adminPassword
    imageReference: {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2022-datacenter-azure-edition'
      version: 'latest'
    }
    nicConfigurations: [
      {
        enableAcceleratedNetworking: false
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: vnet.outputs.subnetResourceIds[i]
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
  }
}]
