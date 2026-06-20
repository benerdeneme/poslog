# POS eklenti otomatik güncelleyici.
# GitHub'daki content.js'i indirir; değiştiyse yereli günceller ve Chrome'u yeniden
# başlatır (unpacked eklenti yeni dosyayı diskten okur). Görev zamanlayıcı çalıştırır.

$owner  = "benerdeneme"
$repo   = "poslog"
$branch = "master"
$path   = "eklenti/content.js"
$url    = "https://pm01.robotpos.com/"

$localFile = Join-Path $PSScriptRoot "eklenti\content.js"
$tokenFile = Join-Path $PSScriptRoot "token.txt"

# İçeriği indir: token.txt varsa private API ile, yoksa public raw ile
try {
    if (Test-Path $tokenFile) {
        $tok = (Get-Content $tokenFile -Raw).Trim()
        $headers = @{ Authorization = "Bearer $tok"; Accept = "application/vnd.github.raw"; "User-Agent" = "rp-updater" }
        $dl = "https://api.github.com/repos/$owner/$repo/contents/$path`?ref=$branch"
    } else {
        $headers = @{ "User-Agent" = "rp-updater" }
        $dl = "https://raw.githubusercontent.com/$owner/$repo/$branch/$path"
    }
    $new = (Invoke-WebRequest -Uri $dl -Headers $headers -UseBasicParsing -TimeoutSec 30).Content
} catch {
    exit 1   # internet yok / token hatası — sessizce çık, mevcut sürüm kalır
}

if (-not $new) { exit 1 }

# Satır sonlarını normalize ederek karşılaştır (gereksiz restart olmasın)
$old = if (Test-Path $localFile) { Get-Content $localFile -Raw } else { "" }
$normNew = ($new -replace "`r`n","`n")
$normOld = ($old -replace "`r`n","`n")

if ($normNew -eq $normOld) { exit 0 }   # değişiklik yok

# Güncelle
Set-Content -Path $localFile -Value $new -Encoding UTF8 -NoNewline

# Chrome'u yeniden başlat ki unpacked eklenti yeni içeriği yüklesin
Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
$chrome = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chrome)) { $chrome = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe" }
if (-not (Test-Path $chrome)) { $chrome = "$env:LocalAppData\Google\Chrome\Application\chrome.exe" }
if (Test-Path $chrome) { Start-Process $chrome -ArgumentList "--start-maximized", "--new-window", $url }
exit 0
