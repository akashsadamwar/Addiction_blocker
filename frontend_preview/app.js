var userName = localStorage.getItem('gj4_userName') || '';
var limits = JSON.parse(localStorage.getItem('gj4_limits') || '[]');

function showScreen(id) {
  document.querySelectorAll('.screen').forEach(function(el) { el.classList.remove('active'); });
  var screen = document.getElementById(id);
  if (screen) screen.classList.add('active');
  if (id === 'screen-home') {
    var h3 = document.getElementById('home-greeting');
    if (h3) h3.textContent = 'Hi, ' + (userName || 'there');
  }
  if (id === 'screen-limits') renderLimits();
}

function saveName(name) {
  userName = (name || '').trim() || userName;
  localStorage.setItem('gj4_userName', userName);
}

function onLogin() {
  var nameInput = document.getElementById('login-name');
  saveName(nameInput ? nameInput.value : '');
  showScreen('screen-home');
}

function onSignup() {
  var nameInput = document.getElementById('signup-name');
  saveName(nameInput ? nameInput.value : '');
  showScreen('screen-home');
}

function openAddLimitModal() {
  document.getElementById('modal-add-limit').classList.remove('hidden');
  document.getElementById('limit-app').value = 'Instagram';
  document.getElementById('limit-package').value = 'com.instagram.android';
  document.getElementById('limit-minutes').value = '30';
  document.getElementById('limit-window').value = '180';
  document.getElementById('limit-message').value = 'has exceeded their time limit.';
}

function closeAddLimitModal() {
  document.getElementById('modal-add-limit').classList.add('hidden');
}

function addLimit() {
  var app = (document.getElementById('limit-app').value || 'App').trim();
  var pkg = (document.getElementById('limit-package').value || app).trim();
  var min = parseInt(document.getElementById('limit-minutes').value, 10) || 30;
  var win = parseInt(document.getElementById('limit-window').value, 10) || 180;
  var msg = (document.getElementById('limit-message').value || 'has exceeded their time limit.').trim();
  limits.push({ app: app, package: pkg, minutes: min, window: win, message: msg });
  localStorage.setItem('gj4_limits', JSON.stringify(limits));
  closeAddLimitModal();
  renderLimits();
  showScreen('screen-limits');
}

function removeLimit(i) {
  limits.splice(i, 1);
  localStorage.setItem('gj4_limits', JSON.stringify(limits));
  renderLimits();
}

function renderLimits() {
  var container = document.getElementById('limits-list');
  var empty = document.getElementById('limits-empty');
  if (!container || !empty) return;
  if (limits.length === 0) {
    container.classList.add('hidden');
    empty.classList.remove('hidden');
    return;
  }
  empty.classList.add('hidden');
  container.classList.remove('hidden');
  container.innerHTML = limits.map(function(r, i) {
    return '<div class="limit-card">' +
      '<div class="name">' + (r.app || 'App') + '</div>' +
      '<div class="detail">' + r.minutes + ' min in ' + (r.window / 60) + ' hr · "' + (r.message || '') + '"</div>' +
      '<button class="btn text" style="margin-top:8px;width:auto" onclick="removeLimit(' + i + ')">Remove</button>' +
      '</div>';
  }).join('');
}

var loginNameEl = document.getElementById('login-name');
var signupNameEl = document.getElementById('signup-name');
if (loginNameEl) loginNameEl.value = userName;
if (signupNameEl) signupNameEl.value = userName;

setTimeout(function() {
  showScreen('screen-login');
}, 1500);
