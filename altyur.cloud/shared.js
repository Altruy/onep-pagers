function toggleMenu() {
  const c = document.querySelector('.nav-center');
  const open = c.style.display === 'flex';
  c.style.cssText = open ? '' : 'display:flex;flex-direction:column;position:fixed;top:60px;left:0;right:0;background:var(--white);padding:20px;gap:20px;border-bottom:1px solid var(--border);z-index:199;box-shadow:0 8px 24px rgba(0,0,0,.08)';
}

function sendMsg() {
  const n = document.getElementById('fn').value;
  const e = document.getElementById('fe').value;
  const c = document.getElementById('fc').value;
  const m = document.getElementById('fm').value;
  if (!n || !e || !m) { alert('Please fill in your name, email, and message.'); return; }
  const s = encodeURIComponent('Enquiry from altyur.cloud' + (c ? ' - ' + c : ''));
  const b = encodeURIComponent('Name: ' + n + '\nEmail: ' + e + '\nCompany: ' + (c || '—') + '\n\n' + m);
  window.location.href = `mailto:turyal@hytgenx.ai?subject=${s}&body=${b}`;
}
