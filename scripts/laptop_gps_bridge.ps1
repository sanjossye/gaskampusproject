Add-Type -AssemblyName System.Device

$culture = [System.Globalization.CultureInfo]::InvariantCulture
$adbPath = "C:\Users\Lenovo\AppData\Local\Android\sdk\platform-tools\adb.exe"

$watcher = New-Object System.Device.Location.GeoCoordinateWatcher([System.Device.Location.GeoPositionAccuracy]::High)
$watcher.Start()

$waitCount = 0
while ($watcher.Status -ne 'Ready' -and $waitCount -lt 25) {
    Start-Sleep -Milliseconds 200
    $waitCount++
}

$script:lastLat = 3.555454
$script:lastLon = 98.657995
$script:hasRealSensor = $false
$script:lastAdbPush = [DateTime]::MinValue

function Update-LaptopGps {
    try {
        $loc = $watcher.Position.Location
        if ($null -ne $loc -and -not [double]::IsNaN($loc.Latitude) -and -not [double]::IsNaN($loc.Longitude)) {
            $script:lastLat = $loc.Latitude
            $script:lastLon = $loc.Longitude
            $script:hasRealSensor = $true
        }
    } catch {}

    $now = Get-Date
    if (($now - $script:lastAdbPush).TotalSeconds -ge 5 -and (Test-Path $adbPath)) {
        $script:lastAdbPush = $now
        try {
            $lonStr = $script:lastLon.ToString("F6", $culture)
            $latStr = $script:lastLat.ToString("F6", $culture)
            & $adbPath emu geo fix $lonStr $latStr 2>$null | Out-Null
        } catch {}
    }
}

Update-LaptopGps

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:18923/")
$listener.Start()
Write-Output ("Laptop GPS Bridge active on http://127.0.0.1:18923/ -> Lat=" + $script:lastLat.ToString("F6", $culture) + ", Lon=" + $script:lastLon.ToString("F6", $culture))

while ($listener.IsListening) {
    try {
        $ctxTask = $listener.GetContextAsync()
        while (-not $ctxTask.Wait(2500)) {
            Update-LaptopGps
        }
        $context = $ctxTask.Result
        Update-LaptopGps

        $latStr = $script:lastLat.ToString("F6", $culture)
        $lonStr = $script:lastLon.ToString("F6", $culture)
        $sensorStr = if ($script:hasRealSensor) { "true" } else { "false" }
        $json = "{`"latitude`":$latStr,`"longitude`":$lonStr,`"isLaptopGps`":$sensorStr,`"source`":`"windows_sensor`"}"

        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $context.Response.StatusCode = 200
        $context.Response.ContentType = "application/json; charset=utf-8"
        $context.Response.AddHeader("Access-Control-Allow-Origin", "*")
        $context.Response.ContentLength64 = $bytes.Length
        $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        $context.Response.OutputStream.Close()
    } catch {
        Start-Sleep -Milliseconds 500
    }
}
