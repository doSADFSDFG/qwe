# Requires -Version 5.1
param(
    [switch]$VerboseLog
)

Write-Host "Building Calut POS Windows release..." -ForegroundColor Cyan

$windowsRunner = Join-Path -Path (Resolve-Path '.') -ChildPath 'windows'
if (-Not (Test-Path $windowsRunner)) {
    Write-Host "Windows runner not found. Generating with flutter create..." -ForegroundColor Yellow
    $createArgs = @('create', '.', '--platforms=windows')
    $createProcess = Start-Process flutter -ArgumentList $createArgs -NoNewWindow -PassThru -Wait
    if ($createProcess.ExitCode -ne 0) {
        throw "flutter create for windows failed with exit code $($createProcess.ExitCode)"
    }
}

$flutterArgs = @('build', 'windows', '--release')
if ($VerboseLog) {
    $flutterArgs += '--verbose'
}

$process = Start-Process flutter -ArgumentList $flutterArgs -NoNewWindow -PassThru -Wait
if ($process.ExitCode -ne 0) {
    throw "flutter build windows failed with exit code $($process.ExitCode)"
}

$outputPath = Join-Path -Path (Resolve-Path '.') -ChildPath 'build/windows/x64/runner/Release'
Write-Host "Build completed. Executable path:" -ForegroundColor Green
Write-Host "    $outputPath/calut_pos.exe"

if (-Not (Test-Path $outputPath)) {
    throw "Expected output folder was not created: $outputPath"
}

Write-Host "You can create a desktop shortcut pointing to calut_pos.exe for quick access." -ForegroundColor Yellow
