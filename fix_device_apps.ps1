# Script to fix device_apps package namespace issue
# Run this script from the project root directory

$pubCache = $env:LOCALAPPDATA + "\Pub\Cache\hosted\pub.dev\device_apps-2.2.0\android\build.gradle"

if (Test-Path $pubCache) {
    $content = Get-Content $pubCache -Raw
    
    # Check if namespace is already added
    if ($content -notmatch "namespace\s*=") {
        # Find the android block and add namespace
        $namespace = "    namespace = `"com.ganeshrvel.device_apps`"`n"
        
        # Try to add after android { or android block
        if ($content -match "(android\s*\{)") {
            $content = $content -replace "(`$1)", "`$1`n$namespace"
        } else {
            # If no android block found, add it at the beginning
            $content = "android {`n$namespace`n}$content"
        }
        
        Set-Content -Path $pubCache -Value $content -NoNewline
        Write-Host "Fixed device_apps package namespace issue!" -ForegroundColor Green
    } else {
        Write-Host "Namespace already exists in device_apps package." -ForegroundColor Yellow
    }
} else {
    Write-Host "device_apps package not found. Please run 'flutter pub get' first." -ForegroundColor Red
}

