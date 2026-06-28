# Audit artifacts for script references
$artifacts = Get-ChildItem 'D:\code\slaytheword\slayword\external\data\artifacts\*.json'
foreach ($f in $artifacts) {
    $raw = Get-Content $f.FullName -Raw
    $json = $raw | ConvertFrom-Json
    $issues = [System.Collections.ArrayList]::new()
    
    # Find all res:// paths in the raw JSON text
    $matches = [regex]::Matches($raw, '"(res://[^"]+)"')
    foreach ($m in $matches) {
        $scriptPath = $m.Groups[1].Value
        $diskPath = $scriptPath -replace '^res://', 'D:\code\slaytheword\slayword\'
        if (-not (Test-Path $diskPath)) {
            [void]$issues.Add("SCRIPT_MISSING: $scriptPath")
        }
    }
    
    if ($issues.Count -gt 0) {
        $out = $f.Name + " | " + ($issues -join '; ')
        Write-Output $out
    }
}

# Audit consumables for script references
$consumables = Get-ChildItem 'D:\code\slaytheword\slayword\external\data\consumables\*.json'
foreach ($f in $consumables) {
    $raw = Get-Content $f.FullName -Raw
    $json = $raw | ConvertFrom-Json
    $issues = [System.Collections.ArrayList]::new()
    
    $matches = [regex]::Matches($raw, '"(res://[^"]+)"')
    foreach ($m in $matches) {
        $scriptPath = $m.Groups[1].Value
        $diskPath = $scriptPath -replace '^res://', 'D:\code\slaytheword\slayword\'
        if (-not (Test-Path $diskPath)) {
            [void]$issues.Add("SCRIPT_MISSING: $scriptPath")
        }
    }
    
    if ($issues.Count -gt 0) {
        $out = $f.Name + " | " + ($issues -join '; ')
        Write-Output $out
    }
}
