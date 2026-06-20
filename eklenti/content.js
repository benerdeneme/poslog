// POS Panel — Otomatik Giriş (Chrome eklentisi content script)
// Panel çıkış yapınca kayıtlı bilgiyle otomatik "Giriş Yap" + her sabah 08:00 yenileme.
(function () {
  'use strict';

  // ── AYARLAR ─────────────────────────────────────────────────────────────────
  // Kullanıcı adı/şifre tarayıcıda KAYITLI olduğundan boş — script kayıtlı bilgiyle girer.
  // (Autofill bir şubede çalışmazsa buraya o şubenin bilgisini yazabilirsin.)
  const USERNAME = '';
  const PASSWORD = '';

  const ENABLE_DAILY_RELOAD = true;
  const RELOAD_HOUR   = 8;   // her gün 08:00'da sayfayı yenile
  const RELOAD_MINUTE = 0;

  const MAX_ATTEMPTS = 3;
  const ATTEMPT_GAP_MS = 4000;
  // ────────────────────────────────────────────────────────────────────────────

  const TAG = '[POS-AutoLogin]';
  function log(...a) { console.log(TAG, ...a); }

  function setReactValue(el, value) {
    const setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;
    setter.call(el, value);
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
  }

  function onLoginPage() {
    return location.pathname.includes('/login') ||
           (document.getElementById('username') && document.getElementById('password'));
  }

  function attemptsThisLoad() { return parseInt(sessionStorage.getItem('rp_attempts') || '0', 10); }
  function bumpAttempts() { sessionStorage.setItem('rp_attempts', String(attemptsThisLoad() + 1)); }

  async function tryLogin() {
    if (attemptsThisLoad() >= MAX_ATTEMPTS) { log('Maksimum deneme aşıldı, duruyorum.'); return; }
    const user = document.getElementById('username');
    const pass = document.getElementById('password');
    const btn  = document.querySelector('button[type="submit"]');
    if (!user || !pass || !btn) return false;

    log('Giriş formu bulundu...');
    if (USERNAME) setReactValue(user, USERNAME);
    else if (user.value) { user.dispatchEvent(new Event('input', { bubbles: true })); }
    if (PASSWORD) setReactValue(pass, PASSWORD);
    else if (pass.value) { pass.dispatchEvent(new Event('input', { bubbles: true })); }
    bumpAttempts();

    await new Promise(r => setTimeout(r, 400));
    if (!btn.disabled) { log('Giriş Yap tıklanıyor (deneme ' + attemptsThisLoad() + ')'); btn.click(); }
    else { log('Buton disabled, tekrar denenecek'); }
    return true;
  }

  function watchForLogin() {
    let tries = 0;
    const iv = setInterval(async () => {
      tries++;
      if (onLoginPage() && document.getElementById('username')) {
        clearInterval(iv);
        await tryLogin();
        let retries = 0;
        const rv = setInterval(async () => {
          retries++;
          if (!onLoginPage() || retries > MAX_ATTEMPTS) { clearInterval(rv); return; }
          await tryLogin();
        }, ATTEMPT_GAP_MS);
      }
      if (tries > 60) clearInterval(iv);
    }, 500);
  }

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
    }, 30000);
  }

  log('Aktif — sayfa:', location.pathname);
  if (onLoginPage()) sessionStorage.setItem('rp_attempts', '0');
  watchForLogin();
  scheduleDailyReload();
})();
