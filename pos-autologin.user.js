// ==UserScript==
// @name         POS Panel — Otomatik Giriş
// @namespace    pos-autologin
// @version      1.1
// @description  Panel otomatik yeniden giriş + sabah sayfa yenileme. Çıkış yapınca kendi giriş yapar.
// @match        https://pm01.robotpos.com/*
// @run-at       document-idle
// @grant        none
// ==/UserScript==

(function () {
  'use strict';

  // ╔══════════════════════════════════════════════════════════════╗
  // ║  AYARLAR                                                       ║
  // ╚══════════════════════════════════════════════════════════════╝
  // Kullanıcı adı/şifre tarayıcıda KAYITLI olduğundan boş bırak — script
  // kayıtlı bilgiyle "Giriş Yap"a basar. (İstersen yine de buraya yazabilirsin.)
  const USERNAME = '';
  const PASSWORD = '';

  // Her sabah sayfayı otomatik yenile (çıkışı yüzeye çıkarıp otomatik giriş yapsın)
  const ENABLE_DAILY_RELOAD = true;
  const RELOAD_HOUR   = 8;             // 08:00'da yenile
  const RELOAD_MINUTE = 0;

  // Güvenlik: yanlış şifrede sonsuz döngü olmasın — sayfa başına en fazla deneme
  const MAX_ATTEMPTS = 3;
  const ATTEMPT_GAP_MS = 4000;

  // ════════════════════════════════════════════════════════════════
  const TAG = '[POS-AutoLogin]';
  function log(...a) { console.log(TAG, ...a); }

  // React kontrollü input'a değer yaz (native setter + input event)
  function setReactValue(el, value) {
    const proto = window.HTMLInputElement.prototype;
    const setter = Object.getOwnPropertyDescriptor(proto, 'value').set;
    setter.call(el, value);
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
  }

  function onLoginPage() {
    return location.pathname.includes('/login') ||
           (document.getElementById('username') && document.getElementById('password'));
  }

  function attemptsThisLoad() {
    return parseInt(sessionStorage.getItem('rp_attempts') || '0', 10);
  }
  function bumpAttempts() {
    sessionStorage.setItem('rp_attempts', String(attemptsThisLoad() + 1));
  }

  async function tryLogin() {
    if (attemptsThisLoad() >= MAX_ATTEMPTS) {
      log('Maksimum deneme aşıldı, duruyorum. Şifreyi kontrol et.');
      return;
    }
    const user = document.getElementById('username');
    const pass = document.getElementById('password');
    const btn  = document.querySelector('button[type="submit"]');
    if (!user || !pass || !btn) return false;

    log('Giriş formu bulundu...');
    // Elle bilgi tanımlandıysa onu yaz; tanımlanmadıysa tarayıcının KAYITLI (autofill) değerini kullan
    if (USERNAME) setReactValue(user, USERNAME);
    else if (user.value) { user.dispatchEvent(new Event('input', { bubbles: true })); }
    if (PASSWORD) setReactValue(pass, PASSWORD);
    else if (pass.value) { pass.dispatchEvent(new Event('input', { bubbles: true })); }
    bumpAttempts();

    // React state'in oturması için kısa bekleme, sonra tıkla
    await new Promise(r => setTimeout(r, 400));
    if (!btn.disabled) {
      log('Giriş Yap tıklanıyor (deneme ' + attemptsThisLoad() + ')');
      btn.click();
    } else {
      log('Buton hâlâ disabled, tekrar denenecek');
    }
    return true;
  }

  // Login ekranı belirene kadar bekle (SPA geç render edebilir), sonra giriş yap
  function watchForLogin() {
    let tries = 0;
    const iv = setInterval(async () => {
      tries++;
      if (onLoginPage() && document.getElementById('username')) {
        clearInterval(iv);
        // Forma kısa süre ver, sonra dene; başarısızsa aralıklı tekrar
        await tryLogin();
        // Buton disabled vs. gibi durumlar için birkaç tekrar
        let retries = 0;
        const rv = setInterval(async () => {
          retries++;
          if (!onLoginPage() || retries > MAX_ATTEMPTS) { clearInterval(rv); return; }
          await tryLogin();
        }, ATTEMPT_GAP_MS);
      }
      if (tries > 60) clearInterval(iv); // ~30 sn sonra vazgeç (login ekranı değil)
    }, 500);
  }

  // Her sabah belirlenen saatte bir kez sayfayı yenile
  function scheduleDailyReload() {
    if (!ENABLE_DAILY_RELOAD) return;
    setInterval(() => {
      const now = new Date();
      const stamp = now.getFullYear() + '-' + now.getMonth() + '-' + now.getDate();
      const last = localStorage.getItem('rp_last_reload');
      if (now.getHours() === RELOAD_HOUR && now.getMinutes() === RELOAD_MINUTE && last !== stamp) {
        localStorage.setItem('rp_last_reload', stamp);
        log('Günlük yenileme saati — sayfa yenileniyor');
        location.reload();
      }
    }, 30000); // 30 sn'de bir saat kontrolü
  }

  log('Aktif — sayfa:', location.pathname);
  if (onLoginPage()) {
    sessionStorage.setItem('rp_attempts', '0');
    watchForLogin();
  } else {
    // Ana sayfadaysak: çıkış olursa SPA login'e yönlenince yakalamak için izle
    watchForLogin();
  }
  scheduleDailyReload();
})();
