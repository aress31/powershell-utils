#    Copyright 2018 Alexandre Teyar

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
#    limitations under the License.

#Requires -RunAsAdministrator

Param(
    [Parameter(Mandatory=$True)]
    [ValidateSet("add", "remove")]
    [System.String] $action,
    [Parameter(Mandatory=$True)]
    [System.String] $nextHop,
    [Parameter(Mandatory=$True)]
    [System.Object] $interface,
    [Parameter(Mandatory=$True)]
    [System.String] $target
)

# $addressFamily = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetNeighbor.AddressFamily]::"IPv4"
[System.UInt32] $routeMetric = 1
# $persistentStore = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetRoute.Store]::"PersistentStore"

Write-Output "[*] Action            : $action"
Write-Output "[*] Interface         : $interface"
Write-Output "[*] Next hop          : $nextHop"
Write-Output "[*] Target file       : $target"

foreach ($entry in [System.IO.File]::ReadLines($target)) {
    # ensure CIDR compliance
    if (-not (([System.String]::IsNullOrEmpty($entry)) -or ($entry -match "^#"))) {
        if (-not ($entry -match "/")) {
            $entryCIDR = $entry + "/32"
            Write-Output "[*] Rewritting $entry to $entryCIDR"
        }

        switch ($action) { 
            "add" {
                Write-Output "[+] Adding new route to $entryCIDR"
                netsh int ipv4 add route prefix=$entryCIDR interface=$interface nexthop=$nextHop metric=$routeMetric store=persistent
                # New-NetRoute -DestinationPrefix $entryCIDR -interface $interface -NextHop $nextHop -RouteMetric $routeMetric -PolicyStore $persistentStore
            }
            "remove" {
                Write-Output "[-] Removing route to $entryCIDR"
                netsh int ipv4 delete route prefix=$entryCIDR interface=$interface nexthop=$nextHop store=persistent
                # Remove-NetRoute -DestinationPrefix $entryCIDR -interface $interface -NextHop $nextHop -RouteMetric $routeMetric -PolicyStore $persistentStore
            }
        }

    }
}

netsh int ipv4 show route store=persistent 
