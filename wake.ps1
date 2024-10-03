$macAddresses = @("A0-88-09-4F-EC-0A", "48-44-F7-41-8B-C2", "00-01-2E-BC-71-66", "48-44-F7-41-66-84", "7C-83-34-BF-3E-96")
foreach ($mac in $macAddresses) {
	[System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | Where-Object { $_.NetworkInterfaceType -ne [System.Net.NetworkInformation.NetworkInterfaceType]::Loopback -and $_.OperationalStatus -eq [System.Net.NetworkInformation.OperationalStatus]::Up } | ForEach-Object {
    		$networkInterface = $_
    		$localIpAddress = ($networkInterface.GetIPProperties().UnicastAddresses | Where-Object { $_.Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork })[0].Address
    		$targetPhysicalAddress = [System.Net.NetworkInformation.PhysicalAddress]::Parse(($mac.ToUpper() -replace '[^0-9A-F]',''))
    		$targetPhysicalAddressBytes = $targetPhysicalAddress.GetAddressBytes()
    		$packet = [byte[]](,0xFF * 102)
    		6..101 | Foreach-Object { $packet[$_] = $targetPhysicalAddressBytes[($_ % 6)] }
    		$localEndpoint = [System.Net.IPEndPoint]::new($localIpAddress, 0)
    		$targetEndpoint = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Broadcast, 9)
    		$client = [System.Net.Sockets.UdpClient]::new($localEndpoint)
    		try { $client.Send($packet, $packet.Length, $targetEndpoint) | Out-Null } finally { $client.Dispose() }
	}
}
Write-Host "Se enviaron paquetes Wake-on-LAN a los ordenadores."