$SDK='C:\Users\sanja\AppData\Local\Android\sdk'
Write-Output "Using SDK path: $SDK"
if (-not (Test-Path $SDK)) { Write-Output "ERROR: SDK path not found: $SDK"; exit 2 }
$found = Get-ChildItem -Path $SDK -Recurse -Filter 'sdkmanager.bat' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
if ($found) {
  Write-Output "Found existing sdkmanager at: $found"
} else {
  Write-Output 'sdkmanager not found - downloading Android commandline tools...'
  $zip = Join-Path $env:TEMP 'commandlinetools.zip'
  Invoke-WebRequest -Uri 'https://dl.google.com/android/repository/commandlinetools-win-latest.zip' -OutFile $zip -UseBasicParsing
  $tmp = Join-Path $env:TEMP 'cmdline_tmp'
  if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue }
  Expand-Archive -Path $zip -DestinationPath $tmp -Force
  $src = Join-Path $tmp 'cmdline-tools'
  $dest = Join-Path $SDK 'cmdline-tools\latest'
  New-Item -ItemType Directory -Path $dest -Force | Out-Null
  Get-ChildItem -Path $src | ForEach-Object { Move-Item -Path $_.FullName -Destination $dest -Force }
  Remove-Item -Recurse -Force $tmp,$zip -ErrorAction SilentlyContinue
  $found = Join-Path $dest 'bin\sdkmanager.bat'
  Write-Output "Installed cmdline-tools to: $dest"
}
Write-Output 'Setting ANDROID_SDK_ROOT and updating user PATH...'
setx ANDROID_SDK_ROOT $SDK | Out-Null
$current = [Environment]::GetEnvironmentVariable('Path','User')
$add = @("$SDK\platform-tools","$SDK\cmdline-tools\latest\bin","D:\flutter\flutter\bin")
foreach ($p in $add) { if ($current -notlike "*$p*") { $current = $current + ';' + $p } }
setx Path $current | Out-Null
$env:ANDROID_SDK_ROOT = $SDK
$env:Path = $env:Path + ';' + ($add -join ';')
Write-Output 'Environment variables updated for this session.'
if (-not (Test-Path $found)) { Write-Output "ERROR: sdkmanager not found after install: $found"; exit 3 }
Write-Output 'Attempting to accept Android SDK licenses (may require JDK)...'
$cmdline = $found
$arg = '/c (for /l %i in (1,1,40) do @echo y) | "' + $cmdline + '" --sdk_root="' + $SDK + '" --licenses'
Write-Output "Running cmd.exe with args: $arg"
Start-Process -FilePath 'cmd.exe' -ArgumentList $arg -NoNewWindow -Wait
Write-Output 'Done.'
