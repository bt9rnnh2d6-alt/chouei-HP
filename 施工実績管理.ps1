# 文字コード設定
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$jsonPath  = Join-Path $scriptDir "works.json"
$worksDir  = Join-Path $scriptDir "works"

# worksフォルダがなければ作成
if (-not (Test-Path $worksDir)) {
    New-Item -ItemType Directory -Path $worksDir | Out-Null
}

# works.json を読み込む
$works = Get-Content $jsonPath -Encoding UTF8 | ConvertFrom-Json
if (-not $works) { $works = @() }

# ========== メインメニュー ==========
Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  施工実績 管理ツール" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. 施工実績を追加する"
Write-Host "  2. 施工実績を削除する"
Write-Host ""
do { $mode = Read-Host "番号を入力してください" } while ($mode -notin @("1","2"))


# ========== 追加モード：情報を収集するだけ（ファイルはまだ変更しない） ==========
if ($mode -eq "1") {

    Write-Host ""
    Write-Host "【追加モード】" -ForegroundColor Green
    Write-Host ""

    $imageExtensions = @("*.jpg","*.jpeg","*.JPG","*.JPEG","*.png","*.PNG")
    $allImages = @()
    foreach ($ext in $imageExtensions) {
        $allImages += Get-ChildItem -Path $worksDir -Filter $ext | Select-Object -ExpandProperty Name
    }

    $allImages = @($allImages | Sort-Object -Unique)
    $existingImages = @($works | ForEach-Object { Split-Path $_.image -Leaf })
    $newImages = @($allImages | Where-Object { $_ -notin $existingImages })

    if ($newImages.Count -eq 0) {
        Write-Host "新しい画像ファイルが見つかりませんでした。" -ForegroundColor Yellow
        Write-Host "worksフォルダに写真を追加してから再度実行してください。" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "worksフォルダ: $worksDir" -ForegroundColor Gray
        Write-Host ""
        Read-Host "Enterキーで終了"
        exit
    }

    Write-Host "【追加できる写真一覧】" -ForegroundColor Green
    for ($i = 0; $i -lt $newImages.Count; $i++) {
        Write-Host "  $($i+1). $($newImages[$i])"
    }
    Write-Host ""
    do {
        $sel = Read-Host "追加する写真の番号を入力してください"
        $selNum = [int]$sel - 1
    } while ($selNum -lt 0 -or $selNum -ge $newImages.Count)
    $selectedImage = $newImages[$selNum]

    Write-Host ""
    $title = Read-Host "工事名を入力してください（例：橋りょう修繕工事（○○橋））"
    Write-Host ""
    $year  = Read-Host "竣工年度を入力してください（例：令和6年竣工）"
    Write-Host ""

    Write-Host "【カテゴリを選択してください】" -ForegroundColor Green
    Write-Host "  1. Bridge（橋梁）"
    Write-Host "  2. Road（道路・舗装）"
    Write-Host "  3. River（河川）"
    Write-Host "  4. Civil（土木一般）"
    Write-Host "  5. Erosion Control（砂防・治山）"
    Write-Host "  6. Road / Bridge（道路・橋梁）"
    Write-Host "  7. その他（直接入力）"
    Write-Host ""
    $categoryMap = @{ "1"="Bridge"; "2"="Road"; "3"="River"; "4"="Civil"; "5"="Erosion Control"; "6"="Road / Bridge" }
    do { $catSel = Read-Host "番号を入力" } while ($catSel -notin @("1","2","3","4","5","6","7"))
    if ($catSel -eq "7") { $category = Read-Host "カテゴリ名を入力してください（英語）" }
    else                 { $category = $categoryMap[$catSel] }

    $commitMsg = "施工実績を追加: $title ($year)"
}


# ========== 削除モード：情報を収集するだけ（ファイルはまだ変更しない） ==========
if ($mode -eq "2") {

    Write-Host ""
    Write-Host "【削除モード】" -ForegroundColor Yellow
    Write-Host ""

    if ($works.Count -eq 0) {
        Write-Host "施工実績データがありません。" -ForegroundColor Yellow
        Read-Host "Enterキーで終了"
        exit
    }

    Write-Host "【現在の施工実績一覧】" -ForegroundColor Yellow
    for ($i = 0; $i -lt $works.Count; $i++) {
        Write-Host "  $($i+1). $($works[$i].title)  [$($works[$i].year)]"
    }
    Write-Host ""
    do {
        $sel = Read-Host "削除する番号を入力してください"
        $selNum = [int]$sel - 1
    } while ($selNum -lt 0 -or $selNum -ge $works.Count)
    $target = $works[$selNum]

    Write-Host ""
    $delFile = Read-Host "写真ファイル（$($target.image)）も削除しますか？（y/n）"

    $commitMsg = "施工実績を削除: $($target.title)"
}


# ========== 最終確認（1回だけ） ==========
Write-Host ""
Write-Host "======================================" -ForegroundColor Red
Write-Host "  確認" -ForegroundColor Red
Write-Host "======================================" -ForegroundColor Red

if ($mode -eq "1") {
    Write-Host "  操作    : 追加" -ForegroundColor White
    Write-Host "  画像    : works/$selectedImage"
    Write-Host "  工事名  : $title"
    Write-Host "  竣工年度: $year"
    Write-Host "  カテゴリ: $category"
} else {
    Write-Host "  操作    : 削除" -ForegroundColor White
    Write-Host "  工事名  : $($target.title)"
    Write-Host "  竣工年度: $($target.year)"
    Write-Host "  画像    : $($target.image)"
    if ($delFile -eq "y" -or $delFile -eq "Y") {
        Write-Host "  写真    : 削除する" -ForegroundColor Red
    } else {
        Write-Host "  写真    : 残す"
    }
}

Write-Host ""
Write-Host "  ⚠ この操作はホームページに即座に公開されます" -ForegroundColor Red
Write-Host "======================================" -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "実行してよろしいですか？（y/n）"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host ""
    Write-Host "キャンセルしました。何も変更されていません。" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Enterキーで終了"
    exit
}


# ========== ここから実際の処理 ==========

if ($mode -eq "1") {
    $newEntry = [PSCustomObject]@{
        image    = "works/$selectedImage"
        category = $category
        title    = $title
        year     = $year
    }
    $works += $newEntry
    $json = $works | ConvertTo-Json -AsArray -Depth 5
    [System.IO.File]::WriteAllText($jsonPath, $json, [System.Text.Encoding]::UTF8)
    Write-Host ""
    Write-Host "✓ works.json を更新しました。" -ForegroundColor Green
}

if ($mode -eq "2") {
    $works = $works | Where-Object { $_ -ne $target }
    if (-not $works) { $works = @() }
    $json = @($works) | ConvertTo-Json -AsArray -Depth 5
    [System.IO.File]::WriteAllText($jsonPath, $json, [System.Text.Encoding]::UTF8)

    if ($delFile -eq "y" -or $delFile -eq "Y") {
        $imagePath = Join-Path $scriptDir $target.image
        if (Test-Path $imagePath) { Remove-Item $imagePath -Force }
    }
    Write-Host ""
    Write-Host "✓ works.json を更新しました。" -ForegroundColor Green
}


# ========== Git commit & push ==========
Write-Host ""
Write-Host "GitHubにアップロード中..." -ForegroundColor Cyan

$gitCmd = $null
$gitCandidates = @(
    "git",
    "$env:LOCALAPPDATA\GitHubDesktop\app-*\resources\app\git\cmd\git.exe",
    "$env:ProgramFiles\Git\cmd\git.exe",
    "$env:ProgramFiles(x86)\Git\cmd\git.exe"
)
foreach ($candidate in $gitCandidates) {
    if ($candidate -eq "git") {
        try { $null = & git --version 2>&1; if ($LASTEXITCODE -eq 0) { $gitCmd = "git"; break } } catch {}
    } else {
        $resolved = Resolve-Path $candidate -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($resolved) { $gitCmd = $resolved.Path; break }
    }
}

if (-not $gitCmd) {
    Write-Host "gitが見つかりませんでした。GitHub Desktopから手動でPushしてください。" -ForegroundColor Red
    Read-Host "Enterキーで終了"
    exit
}

Set-Location $scriptDir
& $gitCmd add -A
& $gitCmd commit -m $commitMsg
& $gitCmd push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ GitHubへのアップロード完了！" -ForegroundColor Green
    Write-Host "  数分以内にウェブサイトに反映されます。" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "アップロードに失敗しました。GitHub Desktopから手動でPushしてください。" -ForegroundColor Red
}

Write-Host ""
Read-Host "Enterキーで終了"
