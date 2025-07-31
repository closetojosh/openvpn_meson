# Performance testing script for meson and cmake compile across commits
# Tests compilation time for each commit between f6c95ac and 7a2b814

param(
    [string]$StartCommit = "f6c95ac",
    [string]$EndCommit = "7a2b814",
    [string]$OutputFile = "",
    [int]$Runs = 10
)

Write-Host "=== OpenVPN Build Performance Test (Meson + CMake) ===" -ForegroundColor Green
Write-Host "Testing commits from $StartCommit to $EndCommit"
Write-Host "Running $Runs iterations of the test"

# Set VCPKG_ROOT environment variable for CMake builds
$env:VCPKG_ROOT = "C:\OpenVPN\vcpkg"
Write-Host "Set VCPKG_ROOT to: $env:VCPKG_ROOT" -ForegroundColor Yellow

# Get list of commits between the range (including both endpoints)
Write-Host "Getting commit list..." -ForegroundColor Yellow
$commits = git rev-list --reverse "$StartCommit^..$EndCommit" 2>$null

if ($LASTEXITCODE -ne 0 -or $commits.Count -eq 0) {
    Write-Error "Failed to get commit list. Please check that the commit hashes are valid."
    exit 1
}

Write-Host "Found $($commits.Count) commits to process across $Runs runs" -ForegroundColor Green

# Store current branch/commit to restore later
$originalRef = git rev-parse HEAD

# Generate CSV filename with runs and timestamp if not provided
if ([string]::IsNullOrEmpty($OutputFile)) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputFile = "build_compile_times_${Runs}runs_${timestamp}.csv"
}

# Initialize CSV file
$csvPath = Join-Path (Get-Location) $OutputFile
"Run,Commit,ShortHash,BuildSystem,CompileTime(seconds),Status,Timestamp" | Out-File -FilePath $csvPath -Encoding utf8

# Check if build directories exist and are configured
if (-not (Test-Path "builddir")) {
    Write-Host "builddir not found. Setting up meson build directory..." -ForegroundColor Yellow
    meson setup builddir
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to setup meson build directory"
        exit 1
    }
} else {
    Write-Host "Using existing builddir" -ForegroundColor Green
}

# Check for CMake preset
$cmakeBuildDir = "out\build\win-amd64-release"
if (-not (Test-Path $cmakeBuildDir)) {
    Write-Host "CMake build directory '$cmakeBuildDir' not found. Configuring now..." -ForegroundColor Yellow
    cmake --preset win-amd64-release
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to configure CMake build directory"
        exit 1
    }
} else {
    Write-Host "Using existing CMake build directory '$cmakeBuildDir'" -ForegroundColor Green
}

$totalSuccessCount = 0
$totalFailCount = 0

try {
    # Run multiple iterations
    for ($run = 1; $run -le $Runs; $run++) {
        Write-Host "`n=================== RUN $run of $Runs ===================" -ForegroundColor Magenta
        
        $runSuccessCount = 0
        $runFailCount = 0
        $commitIndex = 0
        
        foreach ($commit in $commits) {
            $commitIndex++
            $shortHash = $commit.Substring(0, 8)
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            
            Write-Host "`nProcessing commit $commitIndex/$($commits.Count): $shortHash ($commit)" -ForegroundColor Cyan
            
            try {
                # Checkout to the commit
                git checkout $commit --quiet 2>$null
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "Failed to checkout commit $shortHash, skipping..."
                    "$run,$commit,$shortHash,MESON,0,CHECKOUT_FAILED,$timestamp" | Out-File -FilePath $csvPath -Append -Encoding utf8
                    "$run,$commit,$shortHash,CMAKE,0,CHECKOUT_FAILED,$timestamp" | Out-File -FilePath $csvPath -Append -Encoding utf8
                    $runFailCount += 2
                    continue
                }
                
                # Skip timing for the first commit (just compile to set up)
                if ($commitIndex -eq 1) {
                    Write-Host "First commit - compiling to set up build state (not timing)..." -ForegroundColor Yellow
                    
                    # Just compile without timing to establish build state
                    meson compile -C builddir 2>&1 | Out-Null
                    cmake --build --preset win-amd64-release 2>&1 | Out-Null
                    
                    Write-Host "Setup complete, will start timing from next commit" -ForegroundColor Green
                    continue
                }
                
                # Test both build systems for commits after the first
                $buildSystems = @(
                    @{Name = "MESON"; Command = "meson compile -C builddir"},
                    @{Name = "CMAKE"; Command = "cmake --build --preset win-amd64-release"}
                )
                
                foreach ($buildSystem in $buildSystems) {
                    Write-Host "Running $($buildSystem.Name) build..." -ForegroundColor White
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    
                    # Execute the build command
                    $buildOutput = Invoke-Expression "$($buildSystem.Command) 2>&1"
                    $buildExitCode = $LASTEXITCODE
                    
                    $stopwatch.Stop()
                    $buildTime = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
                    
                    $status = if ($buildExitCode -eq 0) { 
                        "SUCCESS" 
                        $runSuccessCount++
                    } else { 
                        "COMPILE_FAILED"
                        $runFailCount++
                        Write-Host "$($buildSystem.Name) build failed for commit $shortHash" -ForegroundColor Red
                    }
                    
                    # Log the result
                    Write-Host "$($buildSystem.Name): $buildTime seconds - $status" -ForegroundColor $(if ($status -eq "SUCCESS") { "Green" } else { "Red" })
                    
                    # Append to CSV file
                    "$run,$commit,$shortHash,$($buildSystem.Name),$buildTime,$status,$timestamp" | Out-File -FilePath $csvPath -Append -Encoding utf8
                }
                
            } catch {
                Write-Warning "Error processing commit $shortHash`: $($_.Exception.Message)"
                "$run,$commit,$shortHash,MESON,0,ERROR,$timestamp" | Out-File -FilePath $csvPath -Append -Encoding utf8
                "$run,$commit,$shortHash,CMAKE,0,ERROR,$timestamp" | Out-File -FilePath $csvPath -Append -Encoding utf8
                $runFailCount += 2
            }
            
            # Show progress
            $totalProcessed = ($run - 1) * ($commits.Count - 1) * 2 + ($commitIndex - 1) * 2
            $totalToProcess = $Runs * ($commits.Count - 1) * 2  # -1 because we skip first commit timing
            if ($totalToProcess -gt 0) {
                $percentComplete = [Math]::Round(($totalProcessed / $totalToProcess) * 100, 1)
                Write-Progress -Activity "Processing commits" -Status "Run $run/$Runs - Commit $commitIndex/$($commits.Count) - $percentComplete% complete" -PercentComplete $percentComplete
            }
        }
        
        $totalSuccessCount += $runSuccessCount
        $totalFailCount += $runFailCount
        
        Write-Host "`nRun $run complete: $runSuccessCount successes, $runFailCount failures" -ForegroundColor $(if ($runFailCount -eq 0) { "Green" } else { "Yellow" })
    }
} finally {
    # Restore original branch/commit
    Write-Host "`nRestoring original state..." -ForegroundColor Yellow
    git checkout $originalRef --quiet 2>$null
    Write-Progress -Activity "Processing commits" -Completed
}

Write-Host "`n=== Final Summary ===" -ForegroundColor Green
Write-Host "Total runs completed: $Runs"
Write-Host "Commits per run: $($commits.Count) (first commit in each run not timed)"
Write-Host "Build systems tested: Meson + CMake"
Write-Host "Total successful builds: $totalSuccessCount" -ForegroundColor Green
Write-Host "Total failed builds: $totalFailCount" -ForegroundColor Red
$totalBuilds = $totalSuccessCount + $totalFailCount
if ($totalBuilds -gt 0) {
    $successRate = [Math]::Round(($totalSuccessCount / $totalBuilds) * 100, 1)
    Write-Host "Success rate: $successRate%" -ForegroundColor $(if ($successRate -gt 90) { "Green" } elseif ($successRate -gt 70) { "Yellow" } else { "Red" })
}
Write-Host "Results saved to: $csvPath" -ForegroundColor Yellow

# Display first few results as preview
if (Test-Path $csvPath) {
    Write-Host "`nPreview of results:"
    Get-Content $csvPath | Select-Object -First 8 | ForEach-Object { Write-Host $_ }
    Write-Host "... (see full results in $OutputFile)"
    
    # Show some statistics
    $csvData = Import-Csv $csvPath
    if ($csvData.Count -gt 0) {
        Write-Host "`nQuick Statistics:"
        $mesonData = $csvData | Where-Object { $_.BuildSystem -eq "MESON" -and $_.Status -eq "SUCCESS" }
        $cmakeData = $csvData | Where-Object { $_.BuildSystem -eq "CMAKE" -and $_.Status -eq "SUCCESS" }
        
        if ($mesonData.Count -gt 0) {
            $avgMeson = [Math]::Round(($mesonData | Measure-Object -Property "CompileTime(seconds)" -Average).Average, 2)
            Write-Host "Average Meson build time: $avgMeson seconds" -ForegroundColor Cyan
        }
        
        if ($cmakeData.Count -gt 0) {
            $avgCmake = [Math]::Round(($cmakeData | Measure-Object -Property "CompileTime(seconds)" -Average).Average, 2)
            Write-Host "Average CMake build time: $avgCmake seconds" -ForegroundColor Cyan
        }
    }
} 