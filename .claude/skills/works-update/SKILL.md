---
name: works-update
description: 施工実績（工事写真・実績データ）の追加・削除・修正を行い、確認後にサイトへ公開する。「施工実績を追加/削除/直したい」「工事写真を載せたい」「実績を更新して」と言われたら必ずこのスキルを使う。works.json と index.html / work-detail.html の worksData ブロックを同期更新する。
---

# 施工実績の更新（追加・削除・修正）

長栄建設HPの施工実績は **3箇所に同じデータ** があり、必ず同期させること：

1. `works.json` — マスタデータ（JSON配列）
2. `index.html` 内の `  var worksData = [...];` ブロック
3. `work-detail.html` 内の同ブロック

## データ仕様（厳守）

- フィールド: `image`（works/ファイル名）, `category`, `title`, `year`, `town`, `client`
- カテゴリの選択肢: `Bridge`（橋梁）/ `Road`（道路・舗装）/ `River`（河川）/ `Civil`（土木一般）/ `Erosion Control`（砂防・治山）/ `Road / Bridge`（道路・橋梁）/ その他自由入力（英語）
- **配列の順序が `work-detail.html?id=N` のNを決める。** 新規エントリは配列の先頭に追加（サイトの一覧で先頭に表示される）
- HTMLブロックの整形（1文字も崩さない）:
  - 1行目: `  var worksData = [`（行頭スペース2つ）
  - エントリ行: `    { image: "…", category: "…", title: "…", year: "…", town: "…", client: "…" },`（行頭スペース4つ、最終エントリのみ末尾カンマ無し）
  - 最終行: `  ];`
- `index.html` / `work-detail.html` は **UTF-8 BOM付き・CRLF** を維持する（下の正規化スニペットを編集後に必ず実行）

## 追加の手順

1. `works/` フォルダ内で works.json 未登録の画像を探して候補を提示する。ユーザーが別の場所の写真パスをくれたら `works/` にコピーする（ファイル名は変えない）
2. 画像が幅1600px超または1MB超なら、scratchpadにバックアップした上で幅1600px・JPEG品質80に**同名上書き**で縮小する（PowerShell + System.Drawing）
3. 以下をユーザーから収集する（AskUserQuestion可）: 工事名／竣工年度（例: 令和8年竣工）／カテゴリ／市町村名（例: 秩父郡長瀞町）／発注者（例: 埼玉県秩父県土整備事務所）
4. `works.json` の配列**先頭**にエントリを追加（UTF-8で保存）
5. 2つのHTMLの worksData ブロックを works.json と同内容で再生成して差し替える
6. **正規化スニペット**と**検証スニペット**を実行し、全項目OKを確認する
7. 公開前の最終確認をユーザーに提示する:
   - 追加内容のサマリ（工事名・年度・カテゴリ・市町村・発注者・写真ファイル名）
   - 写真の写り込み確認（人物の顔・ナンバープレート・個人宅の表札等が写っていないか）
   - 「この操作はホームページに公開されます」と明示
8. ユーザーの明示的なOK後に: `git pull --ff-only origin main` → `git add -A` → `git commit -m "施工実績を追加: <工事名> (<竣工年度>)"` → `git push origin main`
9. 数分以内に https://choei-construction.co.jp に反映される旨を伝える

## 削除の手順

1. works.json の一覧を番号付き（工事名・年度）で提示し、対象を確認する
2. 3箇所から該当エントリを削除。写真ファイル（works/内）も削除するか確認する
3. 正規化・検証 → 公開前確認 → コミットメッセージ `施工実績を削除: <工事名>` でcommit・push（手順8と同様、ユーザーOK後）

## 修正の手順

工事名・年度などの修正も、必ず3箇所を同時に修正する。以降は追加と同じ（検証→確認→commit・push）。コミットメッセージは `施工実績を修正: <工事名>`。

## 正規化スニペット（HTML編集後に必ず実行）

```powershell
$repo = "C:\Users\yasut\Documents\GitHub\chouei-HP"
$enc = New-Object System.Text.UTF8Encoding($true)
foreach ($f in @("index.html", "work-detail.html")) {
    $p = Join-Path $repo $f
    $t = [System.IO.File]::ReadAllText($p)
    [System.IO.File]::WriteAllText($p, ($t -replace "`r?`n", "`r`n"), $enc)
}
"正規化完了"
```

## 検証スニペット（コミット前に必ず実行・全項目OKであること）

```powershell
$repo = "C:\Users\yasut\Documents\GitHub\chouei-HP"
$pattern = '(?s)  var worksData = \[.*?\];'
$jsonCount = (@((Get-Content "$repo\works.json" -Raw -Encoding UTF8) | ConvertFrom-Json | ForEach-Object { $_ })).Count
"works.json: $jsonCount 件"
foreach ($f in @("index.html", "work-detail.html")) {
    $html = [System.IO.File]::ReadAllText("$repo\$f", [System.Text.Encoding]::UTF8)
    $m = [regex]::Matches($html, $pattern)
    $entries = if ($m.Count -ge 1) { ([regex]::Matches($m[0].Value, 'image:')).Count } else { -1 }
    $bom = ([System.IO.File]::ReadAllBytes("$repo\$f"))[0] -eq 0xEF
    "$f : ブロック $($m.Count) 箇所（期待値1）／ $entries 件（期待値$jsonCount）／ BOM: $bom"
}
```

判定基準: 各HTMLでブロックがちょうど1箇所・件数がworks.jsonと一致・BOMがTrue。1つでも外れたら公開せず原因を直す。

## 注意

- 表示確認をしたい場合はローカルサーバー（`.claude/launch.json` の static-site、または `python -m http.server`）で index.html の施工実績グリッドと `work-detail.html?id=0` を確認する
- push（公開）は必ずユーザーの明示的な確認後に行う
- works/ に写真を入れる際の推奨サイズ等は `施工実績の更新方法.txt` にも記載がある
