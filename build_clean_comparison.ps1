# Clean Build Performance Test Script for Meson vs CMake
# Tests setup and compile performance starting from clean state

param(
    [string]$OutputFile = "",
    [int]$Runs = 5
)

Write-Host "=== OpenVPN Clean Build Performance Test (Meson vs CMake) ===" -ForegroundColor Green
Write-Host "Testing clean setup and compile performance"
Write-Host "Running $Runs iterations of the test"

# Set VCPKG_ROOT environment variable for CMake builds
$env:VCPKG_ROOT = "C:\OpenVPN\vcpkg"
Write-Host "Set VCPKG_ROOT to: $env:VCPKG_ROOT" -ForegroundColor Yellow

# Generate CSV filename with runs and timestamp if not provided
if ([string]::IsNullOrEmpty($OutputFile)) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputFile = "clean_build_times_${Runs}runs_${timestamp}.csv"
}

# Initialize CSV file
$csvPath = Join-Path (Get-Location) $OutputFile
"Run,BuildSystem,Phase,Time(seconds),Status,Timestamp" | Out-File -FilePath $csvPath -Encoding utf8

$totalResults = @()

try {
    # Run multiple iterations
    for ($run = 1; $run -le $Runs; $run++) {
        Write-Host "`n=================== RUN $run of $Runs ===================" -ForegroundColor Magenta
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # Test Meson Setup and Compile
        Write-Host "`n--- Testing Meson Clean Setup + Compile ---" -ForegroundColor Cyan
        
        # Meson Setup (--wipe)
        Write-Host "Running meson setup builddir --wipe..." -ForegroundColor White
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        $setupOutput = meson setup builddir --wipe 2>&1
        $setupExitCode = $LASTEXITCODE
        
        $stopwatch.Stop()
        $setupTime = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
        
        $setupStatus = if ($setupExitCode -eq 0) { "SUCCESS" } else { "FAILED" }
        Write-Host "Meson setup: $setupTime seconds - $setupStatus" -ForegroundColor $(if ($setupStatus -eq "SUCCESS") { "Green" } else { "Red" })
        
        # Log setup result
        "$run,MESON,SETUP,$setupTime,$setupStatus,$timestamp" | Out-File -FilePath $csvPath -Append -Encoding utf8
        $totalResults += @{Run=$run; BuildSystem="MESON"; Phase="SETUP"; Time=$setupTime; Status=$setupStatus}
        
        # Meson Compile (only if setup succeeded)
        if ($setupStatus -eq "SUCCESS") {
            Write-Host "Running meson compile in builddir..." -ForegroundColor White
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            $compileOutput = meson compile -C builddir 2>&1
            $compileExitCode = $LASTEXITCODE
            
            $stopwatch.Stop()
            $compileTime = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
            
            $compileStatus = if ($compileExitCode -eq 0) { "SUCCESS" } else { "FAILED" }
            Write-Host "Meson compile: $compileTime seconds - $compileStatus" -ForegroundColor $(if ($compileStatus -eq "SUCCESS") { "Green" } else { "Red" })
            
            # Log compile result
            "$run,MESON,COMPILE,$compileTime,$compileStatus,$timestamp" | Out-File -FilePath $csvPath -Append -Encoding utf8
            $totalResults += @{Run=$run; BuildSystem="MESON"; Phase="COMPILE"; Time=$compileTime; Status=$compileStatus}
        } else {
            Write-Host "Skipping meson compile due to setup failure" -ForegroundColor Red
            "$run,MESON,COMPILE,0,SKIPPED,$timestamp" | Out-File -FilePath $csvPath -Append -Encoding utf8
            $totalResults += @{Run=$run; BuildSystem="MESON"; Phase="COMPILE"; Time=0; Status="SKIPPED"}
        }
        
        # Test CMake Setup and Compile
        Write-Host "`n--- Testing CMake Clean Setup + Compile ---" -ForegroundColor Cyan
        
        # Clean out directory for CMake
        if (Test-Path "out") {
            Write-Host "Removing existing out directory..." -ForegroundColor Yellow
            Remove-Item -Recurse -Force "out" -ErrorAction SilentlyContinue
        }
        
        # CMake Setup (preset)
        Write-Host "Running cmake --preset win-amd64-release..." -ForegroundColor White
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        $cmakeSetupOutput = cmake --preset win-amd64-release 2>&1
        $cmakeSetupExitCode = $LASTEXITCODE
        
        $stopwatch.Stop()
        $cmakeSetupTime = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
        
        $cmakeSetupStatus = if ($cmakeSetupExitCode -eq 0) { "SUCCESS" } else { "FAILED" }
        Write-Host "CMake setup: $cmakeSetupTime seconds - $cmakeSetupStatus" -ForegroundColor $(if ($cmakeSetupStatus -eq "SUCCESS") { "Green" } else { "Red" })
        
        # Log cmake setup result
        "$run,CMAKE,SETUP,$cmakeSetupTime,$cmakeSetupStatus,$timestamp" | Out-File -FilePath $csvPath -Append -Encoding utf8
        $totalResults += @{Run=$run; BuildSystem="CMAKE"; Phase="SETUP"; Time=$cmakeSetupTime; Status=$cmakeSetupStatus}
        
        # CMake Build (only if setup succeeded)
        if ($cmakeSetupStatus -eq "SUCCESS") {
            Write-Host "Running cmake --build --preset win-amd64-release..." -ForegroundColor White
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            $cmakeBuildOutput = cmake --build --preset win-amd64-release 2>&1
            $cmakeBuildExitCode = $LASTEXITCODE
            
            $stopwatch.Stop()
            $cmakeBuildTime = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
            
            $cmakeBuildStatus = if ($cmakeBuildExitCode -eq 0) { "SUCCESS" } else { "FAILED" }
            Write-Host "CMake build: $cmakeBuildTime seconds - $cmakeBuildStatus" -ForegroundColor $(if ($cmakeBuildStatus -eq "SUCCESS") { "Green" } else { "Red" })
            
            # Log cmake build result
            "$run,CMAKE,COMPILE,$cmakeBuildTime,$cmakeBuildStatus,$timestamp" | Out-File -FilePath $csvPath -Append -Encoding utf8
            $totalResults += @{Run=$run; BuildSystem="CMAKE"; Phase="COMPILE"; Time=$cmakeBuildTime; Status=$cmakeBuildStatus}
        } else {
            Write-Host "Skipping cmake build due to setup failure" -ForegroundColor Red
            "$run,CMAKE,COMPILE,0,SKIPPED,$timestamp" | Out-File -FilePath $csvPath -Append -Encoding utf8
            $totalResults += @{Run=$run; BuildSystem="CMAKE"; Phase="COMPILE"; Time=0; Status="SKIPPED"}
        }
        
        # Show progress
        $percentComplete = [Math]::Round(($run / $Runs) * 100, 1)
        Write-Progress -Activity "Clean Build Testing" -Status "Run $run/$Runs - $percentComplete% complete" -PercentComplete $percentComplete
    }
} finally {
    Write-Progress -Activity "Clean Build Testing" -Completed
}

Write-Host "`n=== Final Summary ===" -ForegroundColor Green
Write-Host "Total runs completed: $Runs"
Write-Host "Build systems tested: Meson + CMake"
Write-Host "Phases tested: Setup + Compile"

# Calculate statistics
$mesonSetupSuccesses = $totalResults | Where-Object { $_.BuildSystem -eq "MESON" -and $_.Phase -eq "SETUP" -and $_.Status -eq "SUCCESS" }
$mesonCompileSuccesses = $totalResults | Where-Object { $_.BuildSystem -eq "MESON" -and $_.Phase -eq "COMPILE" -and $_.Status -eq "SUCCESS" }
$cmakeSetupSuccesses = $totalResults | Where-Object { $_.BuildSystem -eq "CMAKE" -and $_.Phase -eq "SETUP" -and $_.Status -eq "SUCCESS" }
$cmakeCompileSuccesses = $totalResults | Where-Object { $_.BuildSystem -eq "CMAKE" -and $_.Phase -eq "COMPILE" -and $_.Status -eq "SUCCESS" }

Write-Host "`nSuccess Summary:" -ForegroundColor Yellow
Write-Host "Meson Setup: $($mesonSetupSuccesses.Count)/$Runs successful" -ForegroundColor $(if ($mesonSetupSuccesses.Count -eq $Runs) { "Green" } else { "Red" })
Write-Host "Meson Compile: $($mesonCompileSuccesses.Count)/$Runs successful" -ForegroundColor $(if ($mesonCompileSuccesses.Count -eq $Runs) { "Green" } else { "Red" })
Write-Host "CMake Setup: $($cmakeSetupSuccesses.Count)/$Runs successful" -ForegroundColor $(if ($cmakeSetupSuccesses.Count -eq $Runs) { "Green" } else { "Red" })
Write-Host "CMake Build: $($cmakeCompileSuccesses.Count)/$Runs successful" -ForegroundColor $(if ($cmakeCompileSuccesses.Count -eq $Runs) { "Green" } else { "Red" })

Write-Host "`nAverage Times (successful runs only):" -ForegroundColor Yellow

if ($mesonSetupSuccesses.Count -gt 0) {
    $avgMesonSetup = [Math]::Round(($mesonSetupSuccesses | Measure-Object -Property Time -Average).Average, 2)
    Write-Host "Meson Setup: $avgMesonSetup seconds" -ForegroundColor Cyan
}

if ($mesonCompileSuccesses.Count -gt 0) {
    $avgMesonCompile = [Math]::Round(($mesonCompileSuccesses | Measure-Object -Property Time -Average).Average, 2)
    Write-Host "Meson Compile: $avgMesonCompile seconds" -ForegroundColor Cyan
}

if ($cmakeSetupSuccesses.Count -gt 0) {
    $avgCmakeSetup = [Math]::Round(($cmakeSetupSuccesses | Measure-Object -Property Time -Average).Average, 2)
    Write-Host "CMake Setup: $avgCmakeSetup seconds" -ForegroundColor Cyan
}

if ($cmakeCompileSuccesses.Count -gt 0) {
    $avgCmakeBuild = [Math]::Round(($cmakeCompileSuccesses | Measure-Object -Property Time -Average).Average, 2)
    Write-Host "CMake Build: $avgCmakeBuild seconds" -ForegroundColor Cyan
}

# Show total times comparison
if ($mesonSetupSuccesses.Count -gt 0 -and $mesonCompileSuccesses.Count -gt 0) {
    $avgMesonTotal = $avgMesonSetup + $avgMesonCompile
    Write-Host "Average Meson Total (Setup + Compile): $avgMesonTotal seconds" -ForegroundColor Green
}

if ($cmakeSetupSuccesses.Count -gt 0 -and $cmakeCompileSuccesses.Count -gt 0) {
    $avgCmakeTotal = $avgCmakeSetup + $avgCmakeBuild
    Write-Host "Average CMake Total (Setup + Build): $avgCmakeTotal seconds" -ForegroundColor Green
}

Write-Host "`nResults saved to: $csvPath" -ForegroundColor Yellow

# Display results preview
if (Test-Path $csvPath) {
    Write-Host "`nPreview of results:"
    Get-Content $csvPath | Select-Object -First 8 | ForEach-Object { Write-Host $_ }
    Write-Host "... (see full results in $OutputFile)"
} 