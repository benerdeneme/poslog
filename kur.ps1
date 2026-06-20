# Tek komut kurulum bootstrap.
# Kullanım (cmd veya PowerShell):
#   powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/benerdeneme/poslog/master/kur.ps1 | iex"
# GitHub'dan indirir → Belgeler\poslog'a kurar → kurulum.ps1'i çalıştırır (yönetici ister).

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$dest = Join-Path $env:USERPROFILE "Documents\poslog"
$zip  = Join-Path $env:TEMP "poslog.zip"
$tmp  = Join-Path $env:TEMP "poslog_extract"

Write-Host "POS Panel kurulumu indiriliyor..." -ForegroundColor Cyan
try {
    Invoke-WebRequest "https://github.com/benerdeneme/poslog/archive/refs/heads/master.zip" -OutFile $zip -UseBasicParsing
} catch {
    Write-Host "HATA: indirilemedi. Internet baglantisini kontrol et." -ForegroundColor Red
    exit 1
}

if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
Expand-Archive $zip $tmp -Force
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Copy-Item (Join-Path $tmp "poslog-master\*") $dest -Recurse -Force
Remove-Item $zip, $tmp -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Kuruldu: $dest" -ForegroundColor Green
Write-Host "Kurulum baslatiliyor (yonetici izni istenecek)..." -ForegroundColor Cyan

# Asil kurulumu calistir (kendini yonetici yapar, gorevleri kurar, chrome://extensions acar)
& (Join-Path $dest "kurulum.ps1")
