chcp 65001 | Out-Null
$env:PYTHONIOENCODING = "utf-8"

$repoRoot = (Get-Location).Path
$rawFiles = git -c core.quotepath=false ls-files

foreach ($gitPath in $rawFiles) {
    try {
        $gitPathClean = $gitPath.Replace("/", "\")
        $fullGitPath  = Join-Path $repoRoot $gitPathClean
        $directory    = Split-Path $fullGitPath -Parent
        $gitName      = Split-Path $fullGitPath -Leaf

        $actualItem = Get-ChildItem -LiteralPath $directory -ErrorAction SilentlyContinue |
                      Where-Object { $_.Name -ieq $gitName } |
                      Select-Object -First 1

        if ($actualItem -and $actualItem.Name -cne $gitName) {
            Write-Host "Correction : $gitName --> $($actualItem.Name)" -ForegroundColor Yellow
            $tempPath = Join-Path $directory ("__TEMP__" + $actualItem.Name)
            git mv $fullGitPath $tempPath 2>&1 | Out-Null
            git mv $tempPath (Join-Path $directory $actualItem.Name) 2>&1 | Out-Null
        }
    } catch {
        Write-Host "Ignoré : $gitPath" -ForegroundColor DarkGray
    }
}

Write-Host "`nTerminé ! Ouvre GitHub Desktop pour voir les changements." -ForegroundColor Green