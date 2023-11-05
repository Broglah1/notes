# Create an empty list to collect VM information
$exportData = @()

# Get all VM host groups
$hostGroups = Get-SCVMHostGroup

foreach ($group in $hostGroups) {
    # Get all clusters within the host group
    $clusters = Get-SCVMHostCluster -VMHostGroup $group

    foreach ($cluster in $clusters) {
        # Get all hosts within the cluster
        $clusterHosts = Get-SCVMHost -VMHostCluster $cluster

        foreach ($host in $clusterHosts) {
            # Get all VMs on the host
            $vms = Get-SCVirtualMachine -VMHost $host

            foreach ($vm in $vms) {
                # Create and add VM details to the list
                $exportData += New-Object PSObject -Property @{
                    HostGroupName = $group.Name
                    ClusterName   = $cluster.Name
                    HostName      = $host.Name
                    VMName        = $vm.Name
                    CPUNumber     = $vm.CPUCount
                    RAMAmount     = $vm.MemoryMB
                    CPUUsageMHz   = $vm.CPUUsageMHz
                    DomainName    = $vm.DomainName
                    PowerStatus   = $vm.StatusString
                    IsStandalone  = $false
                }
            }
        }
    }

    # Get all hosts in the host group
    $allGroupHosts = Get-SCVMHost -VMHostGroup $group

    # Determine standalone hosts by comparing with cluster hosts
    $standaloneHosts = $allGroupHosts | Where-Object { $_.VMHostCluster -eq $null }

    foreach ($host in $standaloneHosts) {
        # Get all VMs on the host
        $vms = Get-SCVirtualMachine -VMHost $host

        foreach ($vm in $vms) {
            # Create and add VM details to the list for standalone hosts
            $exportData += New-Object PSObject -Property @{
                HostGroupName = $group.Name
                ClusterName   = $null
                HostName      = $host.Name
                VMName        = $vm.Name
                CPUNumber     = $vm.CPUCount
                RAMAmount     = $vm.MemoryMB
                CPUUsageMHz   = $vm.CPUUsageMHz
                DomainName    = $vm.DomainName
                PowerStatus   = $vm.StatusString
                IsStandalone  = $true
            }
        }
    }
}

# Export the collected data to a CSV file
$exportData | Export-Csv -Path "VMHostsClustersAndVMsDetailed.csv" -NoTypeInformation
