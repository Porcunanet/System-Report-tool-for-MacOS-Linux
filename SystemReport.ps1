# ================================
# SystemInfoExport.ps1
# Generates a system information report
# Works on Windows without any dependencies
# ================================

Write-Host "Collecting system information..."

# --- Collect System Information ---
$info = [ordered]@{}
$info["Computer Name"] = $env:COMPUTERNAME
$info["User Name"] = $env:USERNAME
$info["OS"] = (Get-CimInstance Win32_OperatingSystem).Caption
$info["OS Version"] = (Get-CimInstance Win32_OperatingSystem).Version
$info["System Type"] = (Get-CimInstance Win32_ComputerSystem).SystemType
$info["Manufacturer"] = (Get-CimInstance Win32_ComputerSystem).Manufacturer
$info["Model"] = (Get-CimInstance Win32_ComputerSystem).Model
$info["CPU"] = (Get-CimInstance Win32_Processor).Name
$info["Total RAM (GB)"] = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
$info["Disk Space (GB)"] = [math]::Round((Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").Size / 1GB, 2)
$info["Free Disk Space (GB)"] = [math]::Round((Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace / 1GB, 2)
$info["IP Address"] = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet","Wi-Fi" -ErrorAction SilentlyContinue | Where-Object {$_.IPAddress -notlike "169.*"} | Select-Object -First 1).IPAddress
$info["Boot Time"] = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime

# --- Ask for export format ---
Write-Host ""
$choice = Read-Host "Export format (HTML or PDF)"

# --- Create HTML ---
$htmlPath = "$env:USERPROFILE\Desktop\SystemInfo.html"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$html = @"
<html>
<head>
<title>System Information Report</title>
<style>
body { font-family: Arial; background-color: #f5f5f5; color: #333; padding: 20px; }
h1 { color: #004aad; }
table { width: 100%; border-collapse: collapse; background: #fff; }
th, td { border: 1px solid #ccc; padding: 10px; text-align: left; }
th { background-color: #eee; }
</style>
</head>
<body>
<h1>System Information Report</h1>
<p>Generated on: $timestamp</p>
<table>
<tr><th>Property</th><th>Value</th></tr>
"@

foreach ($k in $info.Keys) {
    $html += "<tr><td>$k</td><td>$($info[$k])</td></tr>`n"
}

$html += "</table></body></html>"

$html | Out-File -Encoding UTF8 $htmlPath
Write-Host "✅ HTML report saved to: $htmlPath"

# --- Convert to PDF if chosen ---
if ($choice -match "pdf") {
    $pdfPath = "$env:USERPROFILE\Desktop\SystemInfo.pdf"
    Write-Host "Generating PDF..."
    Start-Process -FilePath $htmlPath
    Start-Sleep -Seconds 2
    $word = New-Object -ComObject Word.Application
    $doc = $word.Documents.Open($htmlPath)
    $doc.SaveAs([ref]$pdfPath, [ref]17)  # 17 = wdFormatPDF
    $doc.Close()
    $word.Quit()
    Write-Host "✅ PDF report saved to: $pdfPath"
}
