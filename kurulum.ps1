# POS Panel — TEK ADIM kurulum (yönetici gerekir)
# 1) Auto-login eklentisini Chrome'a POLİTİKAYLA otomatik kurar (Tampermonkey'e gerek yok)
# 2) Windows açılışında Chrome otomatik açılır
# 3) Her gün 08:00'da Chrome kapalıysa açılır
# Her şube makinesinde BİR KEZ çalıştırılır.

# ── Yönetici değilse kendini yükselt ─────────────────────────────────────────
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if (-not $admin) {
    Write-Host "Yönetici izni isteniyor..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$EXT_ID = "cfaoianhnngckdfnomkaeikekkbkgeob"   # eklentinin sabit kimliği
$url = "https://pm01.robotpos.com/"

# ── Chrome'u bul ──────────────────────────────────────────────────────────────
$chrome = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chrome)) { $chrome = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe" }
if (-not (Test-Path $chrome)) { $chrome = "$env:LocalAppData\Google\Chrome\Application\chrome.exe" }
if (-not (Test-Path $chrome)) { Write-Host "HATA: chrome.exe bulunamadi." -ForegroundColor Red; pause; exit 1 }

$crx = Join-Path $PSScriptRoot "eklenti.crx"
if (-not (Test-Path $crx)) { Write-Host "HATA: eklenti.crx bulunamadi (ayni klasorde olmali)." -ForegroundColor Red; pause; exit 1 }

# ── 1) Önceki başarısız force-install politikasını TEMİZLE ───────────────────
# Chrome 150+ file:// force-install'i [BLOCKED] ediyor → eklenti MANUEL yüklenecek.
$forceKey = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"
if (Test-Path $forceKey) {
    (Get-Item $forceKey).Property | ForEach-Object {
        try {
            $v = (Get-ItemProperty -Path $forceKey -Name $_).$_
            if ($v -like "*$EXT_ID*") { Remove-ItemProperty -Path $forceKey -Name $_ -ErrorAction SilentlyContinue }
        } catch {}
    }
}
Write-Host "[1/3] Bozuk politika temizlendi (eklenti manuel yuklenecek)." -ForegroundColor Green

# ── 2) Başlangıç kısayolu (Windows açılışında Chrome aç) ─────────────────────
$startup = [Environment]::GetFolderPath('Startup')
$lnkPath = Join-Path $startup "POS Panel.lnk"
$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($lnkPath)
$sc.TargetPath = $chrome
$sc.Arguments  = "--start-maximized --new-window `"$url`""
$sc.Description = "POS Panel otomatik baslat"
$sc.Save()
Write-Host "[2/3] Windows acilis kisayolu kuruldu." -ForegroundColor Green

# ── 3) Her gün 08:00 görevi (Chrome kapalıysa aç) ────────────────────────────
$script = Join-Path $PSScriptRoot "08-kontrol.ps1"
if (Test-Path $script) {
    $taskName = "POS 08-00 Kontrol"
    $action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`""
    $trigger = New-ScheduledTaskTrigger -Daily -At "08:00"
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Her sabah 08:00 - Chrome kapaliysa Platform Manager'i acar" -Force | Out-Null
    Write-Host "[3/3] Her gun 08:00 gorevi kuruldu." -ForegroundColor Green
} else {
    Write-Host "[3/3] UYARI: 08-kontrol.ps1 yok, 08:00 gorevi atlandi." -ForegroundColor Yellow
}

# ── 4) Otomatik guncelleme gorevi (her gun 07:55 GitHub'dan ceker) ───────────
$upd = Join-Path $PSScriptRoot "guncelle.ps1"
if (Test-Path $upd) {
    $uAction  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$upd`""
    $uTrigger = New-ScheduledTaskTrigger -Daily -At "07:55"
    $uSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName "POS Guncelle" -Action $uAction -Trigger $uTrigger -Settings $uSettings -Description "Her sabah 07:55 - eklentiyi GitHub'dan gunceller" -Force | Out-Null
    Write-Host "[+] Otomatik guncelleme gorevi kuruldu (her gun 07:55)." -ForegroundColor Green
}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " SON ADIM - Eklentiyi elle yukle (3 tik, KESIN calisir):" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  1) Acilan chrome://extensions sayfasinda sag ustte"
Write-Host "     'Gelistirici modu' (Developer mode) -> AC"
Write-Host "  2) 'Paketlenmemis oge yukle' (Load unpacked) -> tikla"
Write-Host "  3) Su KLASORU sec (crx degil, klasor):" -ForegroundColor Yellow
Write-Host "     $PSScriptRoot\eklenti" -ForegroundColor Yellow
Write-Host ""
Write-Host "Sonra Platform Manager'da cikis yapip F5 -> otomatik giris yapmali."
Write-Host "=================================================================="
# chrome://extensions sayfasini ac (kullanici hemen yuklesin)
Start-Process $chrome -ArgumentList "chrome://extensions"
Write-Host ""
pause
