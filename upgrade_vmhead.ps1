param (
    [Parameter(Mandatory=$true)][string]$vsphere, # i.e. sc-vcsa-01.otsql.opentable.com
    [Parameter(Mandatory=$true)][string]$vmhead, # i.e. sc-vmhead-38.otsql.opentable.com
    [Parameter(Mandatory=$true)][string]$desiredBaseline # i.e. "Upgrade 6.5 U1 - Lenovo"
    )

# Connect to vsphere
Write-Host "Connecting to vsphere server..."
Connect-VIServer -Server $vsphere -Protocol https

#the baseline we want to upgrade to
Write-Host "Looking up baseline..."
$baselineObject = get-baseline | where {$_.Name -eq $desiredBaseline}

#put the head in maintenance mode
Write-Host "Putting $vmhead into maintenance mode..."
Get-VMHost -Name $vmhead | set-vmhost -State Maintenance

# assign the baseline to the head and scan so that the system knows that it needs and upgrade, then remediate
Write-Host "Attaching baseline to $vmhead... "
Attach-Baseline -Baseline $baselineObject -Entity $vmhead
Write-Host "Scanning $vmhead... "
Scan-Inventory -Entity $vmhead
Write-Host "Remediating!"
$remediatetask = remediate-inventory -entity $vmhead -Baseline $BaselineObject -RunAsync -confirm:$false
wait-task -Task $remediatetask

# take it out of maintenance mode
Write-Host "Taking $vmhead out of maintenance mode..."
Get-VMHost -Name $vmhead | set-vmhost -State Connected
