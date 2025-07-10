# PowerShell script to deploy Web Scraping Detection app to Splunk
# Run this script from the project root directory

param(
    [Parameter(Mandatory=$false)]
    [string]$SplunkHome = "C:\Program Files\Splunk",
    
    [Parameter(Mandatory=$false)]
    [string]$AppName = "web_scraping_detection"
)

Write-Host "=== Splunk Web Scraping Detection Deployment Script ===" -ForegroundColor Green
Write-Host "Splunk Home: $SplunkHome" -ForegroundColor Yellow
Write-Host "App Name: $AppName" -ForegroundColor Yellow

# Check if Splunk directory exists
if (-not (Test-Path $SplunkHome)) {
    Write-Host "ERROR: Splunk directory not found at $SplunkHome" -ForegroundColor Red
    Write-Host "Please specify correct path with -SplunkHome parameter" -ForegroundColor Red
    exit 1
}

# Define paths
$AppPath = "$SplunkHome\etc\apps\$AppName"
$LocalPath = "$AppPath\local"
$LookupsPath = "$AppPath\lookups"
$MetadataPath = "$AppPath\metadata"

Write-Host "`n1. Creating app directory structure..." -ForegroundColor Cyan

# Create app directories
$Directories = @($AppPath, $LocalPath, $LookupsPath, $MetadataPath)
foreach ($Dir in $Directories) {
    if (-not (Test-Path $Dir)) {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
        Write-Host "   Created: $Dir" -ForegroundColor Green
    } else {
        Write-Host "   Exists: $Dir" -ForegroundColor Yellow
    }
}

Write-Host "`n2. Copying configuration files..." -ForegroundColor Cyan

# Copy configuration files
try {
    Copy-Item "splunk_config\props.conf" "$LocalPath\" -Force
    Write-Host "   Copied: props.conf" -ForegroundColor Green
    
    Copy-Item "splunk_config\transforms.conf" "$LocalPath\" -Force
    Write-Host "   Copied: transforms.conf" -ForegroundColor Green
    
    Copy-Item "splunk_config\app.conf" "$AppPath\" -Force
    Write-Host "   Copied: app.conf" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: Failed to copy config files - $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n3. Copying lookup tables..." -ForegroundColor Cyan

# Copy lookup files
try {
    Get-ChildItem "lookups\*.csv" | ForEach-Object {
        Copy-Item $_.FullName "$LookupsPath\" -Force
        Write-Host "   Copied: $($_.Name)" -ForegroundColor Green
    }
} catch {
    Write-Host "   ERROR: Failed to copy lookup files - $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n4. Creating app metadata..." -ForegroundColor Cyan

# Copy metadata files
try {
    if (Test-Path "splunk_config\metadata\default.meta") {
        Copy-Item "splunk_config\metadata\default.meta" "$MetadataPath\" -Force
        Write-Host "   Copied: default.meta" -ForegroundColor Green
    } else {
        # Create default.meta file if it doesn't exist
        $MetaContent = @"
[views]
export = system

[lookups]
export = system

[savedsearches]
export = system
"@
        $MetaContent | Out-File "$MetadataPath\default.meta" -Encoding UTF8 -Force
        Write-Host "   Created: default.meta" -ForegroundColor Green
    }
} catch {
    Write-Host "   ERROR: Failed to create metadata - $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n5. Finalizing app configuration..." -ForegroundColor Cyan

# App configuration is already copied, just verify it exists
if (Test-Path "$AppPath\app.conf") {
    Write-Host "   Verified: app.conf exists" -ForegroundColor Green
} else {
    Write-Host "   WARNING: app.conf not found" -ForegroundColor Yellow
}

Write-Host "`n=== Deployment Complete! ===" -ForegroundColor Green
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Restart Splunk to load the new app:" -ForegroundColor White
Write-Host "   `"$SplunkHome\bin\splunk.exe`" restart" -ForegroundColor Gray
Write-Host "`n2. Create index via Splunk Web or CLI:" -ForegroundColor White
Write-Host "   Settings > Indexes > New Index" -ForegroundColor Gray
Write-Host "   Index Name: infrastructure_analysis" -ForegroundColor Gray
Write-Host "`n3. Upload client_hostname.csv:" -ForegroundColor White
Write-Host "   Settings > Add Data > Upload" -ForegroundColor Gray
Write-Host "   Source Type: client_hostname_data" -ForegroundColor Gray
Write-Host "   Index: infrastructure_analysis" -ForegroundColor Gray
Write-Host "`n4. Import dashboard from dashboards/web_scraping_dashboard.xml" -ForegroundColor White

Write-Host "`nApp deployed to: $AppPath" -ForegroundColor Green
