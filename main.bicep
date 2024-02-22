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
param adminPassword string

@description('Admin username for the VM.')
param adminUsername string

var ipaddressSpace = [
  '10.0.0.0/24'
]
var subnetAddressPrefix = cidrSubnet(ipaddressSpace[0], 25, 0)
var vnetName = 'vnet-networkts'
var nsgName = 'nsg-networkts'
var udrName = 'udr-networkts'
var vmName = 'networkts-vm'

var nsgScenarioA = [
  {
    name: 'deny-inbound-ssh'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '22'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Deny'
      priority: 100
      direction: 'Inbound'
    }
  }
]

var nsgScenarioB = [
  {
    name: 'deny-outbound-rdp'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '3389'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: ipaddressSpace[0]
      access: 'Deny'
      priority: 100
      direction: 'Outbound'
    }
  }
]

module vnet 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: 'deploy-vnet'
  params: {
    name: vnetName
    location: location
    addressPrefixes: ipaddressSpace
    subnets: [
      {
        name: 'subnet1'
        networkSecurityGroupResourceId: nsg.outputs.resourceId
        addressPrefix: subnetAddressPrefix
        // routeTableResourceId: tsScenario == 'C' ? routeTable.outputs.resourceId : ''
      }
    ]
  }
}

module nsg 'br/public:avm/res/network/network-security-group:0.1.2' = {
  name: 'deploy-nsg'
  params: {
    name: nsgName
    location: location
    securityRules: tsScenario == 'A' ? nsgScenarioA : tsScenario == 'B' ? nsgScenarioB : []
  }
}

module routeTable 'br/public:avm/res/network/route-table:0.2.1' = if (tsScenario == 'C') {
  name: 'deploy-routeTable'
  params: {
    name: udrName
    location: location
    routes: [
      {
        name: 'fubar'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '1.2.3.4'
        }
      }
    ]
  }
}

module vm 'br/public:avm/res/compute/virtual-machine:0.2.1' = {
  name: 'deploy-vm'
  dependsOn: [
    vnet
    nsg
  ]
  params: {
    name: vmName
    location: location
    vmSize: 'Standard_DS1_v2'
    osType: 'Windows'
    encryptionAtHost: false
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: '128'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
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
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: vnet.outputs.subnetResourceIds[0]
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
  }
}
