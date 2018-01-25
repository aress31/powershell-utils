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
    [ValidateSet("external", "internal")]
    [string]$engagementType,
    [Parameter(Mandatory=$True)]
    [ValidateSet("add", "delete")]
    [string]$operation,
    [Parameter(Mandatory=$True)]
    [string]$targetFile
)

Write-Output "[*] Engagement type   : $($engagementType)"
Write-Output "[*] Operation         : $($operation)"
Write-Output "[*] Target file       : $($targetFile)"

switch ($engagementType) {
    # gateway IP for external engagement 
    "external" {
        $gateway = "<REDACTED>"
    }
    # gateway IP for external engagement 
    "internal" {
        $gateway = "<REDACTED>"
    }
}

Write-Output "[*] Gateway           : $($gateway)"

# getting the correct adapater index
foreach ($adapter in Get-NetAdapter | Where {$_.Status -eq "Up"}) {
    $adapterIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $adapter.ifIndex).IPAddress

    if ($adapterIP -Match $gateway.Substring(0, $gateway.lastIndexOf('.'))) {
        Write-Output "[*] Interface index   : $($adapter.ifIndex)"
        Write-Output "[*] Interface IP      : $($adapterIP)"
        Write-Output "[*] Interface name    : $($adapter.Name)"

        $adapterIndex = $adapter.ifIndex
        $adapterName = $adapter.Name
    }
}

foreach ($entry in Get-Content $targetFile) {
    # ensure that the IP address is CIDR compliant
    if (-not (([string]::IsNullOrEmpty($entry)) -or ($entry -match "^#"))) {
        if (-not ($entry -match "/"))    {
            Write-Output "[*] Rewritting the IP address to CIDR notation"
            $entry = $entry + "/32"
        }

        switch ($operation) { 
            "add" {
                Write-Output "[+] Adding route to $($entry) via interface $($adapterName)"
                netsh int ipv4 add route $entry interface=$adapterIndex metric=1 nexthop=$gateway store=persistent
            }
            "delete" {
                Write-Output "[-] Deleting route to $($entry) via interface $($adapterName)"
                netsh int ipv4 delete route $entry interface=$adapterIndex
            }
        }
    }
}

# check that everything went smoothly
netsh int ipv4 show route store=persistent
