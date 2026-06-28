$cards = Get-ChildItem 'D:\code\slaytheword\slayword\external\data\cards\card_astrology_*.json'
foreach ($f in $cards) {
    $json = Get-Content $f.FullName -Raw | ConvertFrom-Json
    $packs = $json.properties.card_appears_in_card_packs
    $desc = $json.properties.card_description
    $values = $json.properties.card_values
    $actions = $json.properties.card_play_actions
    $issues = [System.Collections.ArrayList]::new()

    if ($packs -eq $true) {
        if ($values -ne $null) {
            foreach ($p in $values.PSObject.Properties) {
                if ($p.Name -eq 'bonus_damage' -or $p.Name -eq 'bonus_block') {
                    [void]$issues.Add("HAS_BONUS_KEY: $($p.Name)")
                }
            }
        }
        if ($desc -match '\[bonus_damage\]') { [void]$issues.Add('DESC_HAS_[bonus_damage]') }
        if ($desc -match '\[bonus_block\]') { [void]$issues.Add('DESC_HAS_[bonus_block]') }
    }

    if ($actions -ne $null) {
        foreach ($action in $actions) {
            foreach ($prop in $action.PSObject.Properties) {
                $scriptPath = $prop.Name
                if ($scriptPath -match '^res://') {
                    $diskPath = $scriptPath -replace '^res://', 'D:\code\slaytheword\slayword\'
                    if (-not (Test-Path $diskPath)) {
                        [void]$issues.Add("SCRIPT_MISSING: $scriptPath")
                    }
                }
            }
        }
    }

    if ($issues.Count -gt 0) {
        $out = $f.Name + " | " + ($issues -join '; ')
        Write-Output $out
    }
}
