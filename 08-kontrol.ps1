# Görev Zamanlayıcı bunu her gün 08:00'da çalıştırır.
# Chrome KAPALIYSA Platform Manager'ı açar. Zaten açıksa hiçbir şey yapmaz
# (açık Chrome'da sayfa-içi otomatik yenileme + giriş zaten devrede).

$url = "https://pm01.robotpos.com/"

$chrome = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chrome)) { $chrome = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe" }
if (-not (Test-Path $chrome)) { $chrome = "$env:LocalAppData\Google\Chrome\Application\chrome.exe" }
if (-not (Test-Path $chrome)) { exit 1 }

$running = Get-Process chrome -ErrorAction SilentlyContinue
if (-not $running) {
    # Chrome kapalı → Platform Manager'ı aç
    Start-Process $chrome -ArgumentList "--start-maximized", "--new-window", $url
}
# Chrome açıksa: dokunma — açık sayfadaki Tampermonkey scripti 08:00 yenilemesini yapar.
