chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$repoRoot = (Get-Location).Path
Write-Host "Dossier racine : $repoRoot" -ForegroundColor Cyan

# Recupere tous les fichiers Git dans une hashtable nom_lowercase -> nom_git
$rawFiles = git -c core.quotepath=false ls-files
Write-Host "Fichiers trackes par Git : $($rawFiles.Count)" -ForegroundColor Cyan

# Construit un dictionnaire : chemin_lowercase => chemin_git_original
$gitIndex = @{}
foreach ($f in $rawFiles) {
    $normalized = $f.Replace("/", "\")
    $gitIndex[$normalized.ToLower()] = $normalized
}

# Parcourt tous les fichiers reels sur le disque
$allDiskFiles = Get-ChildItem -LiteralPath $repoRoot -Recurse -File |
    Where-Object { $_.FullName -notmatch '\\.git\\' -and $_.Name -notmatch '^__TEMP__' }

$corrections = 0
$notInGit = 0

foreach ($diskFile in $allDiskFiles) {
    $relativePath = $diskFile.FullName.Substring($repoRoot.Length).TrimStart("\")
    $relLower = $relativePath.ToLower()

    if ($gitIndex.ContainsKey($relLower)) {
        $gitPath = $gitIndex[$relLower]

        if ($gitPath -cne $relativePath) {
            Write-Host "Correction : $gitPath  -->  $relativePath" -ForegroundColor Yellow
            $fullGitPath = Join-Path $repoRoot $gitPath
            $fullDiskPath = $diskFile.FullName
            $tempPath = Join-Path $diskFile.Directory.FullName ("__TEMP__" + $diskFile.Name)

            git mv $fullGitPath $tempPath 2>&1 | Out-Null
            git mv $tempPath $fullDiskPath 2>&1 | Out-Null
            $corrections++
        }
    }
}

Write-Host ""
Write-Host "$corrections correction(s) effectuee(s)." -ForegroundColor Green
Write-Host "Termine ! Ouvre GitHub Desktop pour voir les changements." -ForegroundColor Green
