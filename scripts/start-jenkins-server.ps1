$ErrorActionPreference = "Stop"

$workspace = $env:WORKSPACE
if ([string]::IsNullOrWhiteSpace($workspace)) {
    throw "Jenkins WORKSPACE is not set."
}

$buildDirectory = Join-Path $workspace "build"
$serverScript = Join-Path $workspace "node_modules\serve\build\main.js"
$pidFile = Join-Path $workspace ".youtube-clone-server.pid"
$stdoutLog = Join-Path $workspace "youtube-clone-server.log"
$stderrLog = Join-Path $workspace "youtube-clone-server-error.log"
$firewallRuleName = "YoutubeClone-Jenkins-3000"

if (-not (Test-Path (Join-Path $buildDirectory "index.html"))) {
    throw "Production build not found at '$buildDirectory'."
}
if (-not (Test-Path $serverScript)) {
    throw "Static server executable not found at '$serverScript'."
}

$node = (Get-Command node.exe -ErrorAction Stop).Source
$firewallRule = Get-NetFirewallRule -Name $firewallRuleName -ErrorAction SilentlyContinue
if ($firewallRule) {
    Set-NetFirewallRule -Name $firewallRuleName -Profile Private -Enabled True -Direction Inbound -Action Allow
}
else {
    New-NetFirewallRule -Name $firewallRuleName -DisplayName "YouTube Clone Jenkins app (TCP 3000)" `
        -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3000 -Profile Private | Out-Null
}

foreach ($profile in (Get-NetConnectionProfile -ErrorAction SilentlyContinue)) {
    if ($profile.NetworkCategory -eq "Public") {
        Write-Warning "Network '$($profile.Name)' is Public. The firewall rule only allows Private networks; change this connection to Private only if you trust it."
    }
}

function Test-PortInUse {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $client.Connect("127.0.0.1", 3000)
        return $true
    }
    catch {
        return $false
    }
    finally {
        $client.Dispose()
    }
}

if (Test-Path $pidFile) {
    $previousPid = 0
    if (-not [int]::TryParse((Get-Content $pidFile -Raw), [ref]$previousPid)) {
        throw "Invalid server PID file '$pidFile'. Remove it and rerun the pipeline."
    }

    $previousProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $previousPid" -ErrorAction SilentlyContinue
    if ($previousProcess) {
        if ([string]::IsNullOrEmpty($previousProcess.CommandLine) -or
            -not $previousProcess.CommandLine.Contains($serverScript)) {
            throw "PID $previousPid is not the app server; refusing to stop it."
        }
        Stop-Process -Id $previousPid -Force
    }
    Remove-Item $pidFile
}

for ($attempt = 0; $attempt -lt 30; $attempt++) {
    if (-not (Test-PortInUse)) {
        break
    }
    Start-Sleep -Seconds 1
}
if (Test-PortInUse) {
    throw "Port 3000 is already in use by another process."
}

Remove-Item $stdoutLog, $stderrLog -Force -ErrorAction SilentlyContinue
$arguments = "`"$serverScript`" --single --no-port-switching --listen tcp://0.0.0.0:3000 `"$buildDirectory`""
$server = Start-Process -FilePath $node -ArgumentList $arguments -WorkingDirectory $workspace `
    -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog
Set-Content -Path $pidFile -Value $server.Id -Encoding ASCII

$ready = $false
for ($attempt = 0; $attempt -lt 30; $attempt++) {
    if ($server.HasExited) {
        break
    }
    try {
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:3000" -UseBasicParsing -TimeoutSec 2
        if ($response.StatusCode -eq 200) {
            $ready = $true
            break
        }
    }
    catch {
        Start-Sleep -Seconds 1
    }
}

if (-not $ready) {
    if (-not $server.HasExited) {
        Stop-Process -Id $server.Id -Force
    }
    $details = Get-Content $stderrLog, $stdoutLog -ErrorAction SilentlyContinue | Out-String
    throw "App server did not become ready at http://localhost:3000. $details"
}

Write-Output "App is running on port 3000 (PID $($server.Id))."
$upInterfaceIndexes = @(Get-NetAdapter -ErrorAction SilentlyContinue |
    Where-Object { $_.Status -eq "Up" } |
    Select-Object -ExpandProperty ifIndex)
foreach ($address in (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $upInterfaceIndexes -contains $_.InterfaceIndex -and $_.IPAddress -ne "127.0.0.1" -and $_.IPAddress -notlike "169.254.*" } |
        Select-Object -ExpandProperty IPAddress -Unique)) {
    Write-Output "App URL: http://${address}:3000"
}
