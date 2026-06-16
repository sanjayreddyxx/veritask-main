$SDK='C:\Users\sanja\AppData\Local\Android\sdk'
Write-Output "Using SDK path: $SDK"
if (-not (Test-Path $SDK)) {
  Write-Error "SDK path not found: $SDK"
  exit 2
}
Write-Output "SDK top-level contents:"
Get-ChildItem -Path $SDK -Force | Select-Object Name,Mode | ForEach-Object { Write-Output " - $($_.Name)" }

$found = Get-ChildItem -Path $SDK -Recurse -Filter 'sdkmanager.bat' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
if ($found) {
  Write-Output "Found existing sdkmanager at: $found"
} else {
  Write-Output 'sdkmanager not found — attempting downloads...'
  $urls = @(
    'https://dl.google.com/android/repository/commandlinetools-win-latest.zip',
    'https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip',
    'https://dl.google.com/android/repository/commandlinetools-win-9123335_latest.zip'
  )
  $zip = Join-Path $env:TEMP 'commandlinetools_retry.zip'
  $success = $false
  foreach ($u in $urls) {
    Write-Output "Trying $u"
    try {
      Invoke-WebRequest -Uri $u -OutFile $zip -UseBasicParsing -ErrorAction Stop
      Write-Output "Downloaded: $u"
      $success = $true
      break
    } catch {
      Write-Warning "Download failed for $u: $($_.Exception.Message)"
      if (Test-Path $zip) { Remove-Item $zip -ErrorAction SilentlyContinue }
    }
  }
  if (-not $success) {
    Write-Error 'All downloads failed. Please install Android Studio or download commandlinetools manually and place into the SDK path.'
    exit 3
  }
  $tmp = Join-Path $env:TEMP 'cmdline_tmp'
  if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue }
  Expand-Archive -Path $zip -DestinationPath $tmp -Force
  $src = Join-Path $tmp 'cmdline-tools'
  if (-not (Test-Path $src)) {
    # Some zips may have nested folders
    $maybe = Get-ChildItem -Path $tmp -Directory | Select-Object -First 1
    if ($maybe) { $src = $maybe.FullName }
  }
  $dest = Join-Path $SDK 'cmdline-tools\latest'
  New-Item -ItemType Directory -Path $dest -Force | Out-Null
  Get-ChildItem -Path $src | ForEach-Object { Move-Item -Path $_.FullName -Destination $dest -Force }
  Remove-Item -Recurse -Force $tmp, $zip -ErrorAction SilentlyContinue
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

if (-not (Test-Path $found)) { Write-Error "sdkmanager not found after install: $found"; exit 4 }

Write-Output 'Attempting to accept Android SDK licenses (interactive may appear)...'
# Use cmd.exe to run sdkmanager --licenses and pipe many 'y' responses
$arg = '/c (for /l %i in (1,1,40) do @echo y) | "' + $found + '" --sdk_root="' + $SDK + '" --licenses'
Write-Output "Running: cmd.exe $arg"
Start-Process -FilePath 'cmd.exe' -ArgumentList $arg -NoNewWindow -Wait
Write-Output 'License step finished. Run `flutter doctor -v` to verify.'
Write-Output 'Done.'
