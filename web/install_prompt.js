
let deferredPrompt;
window.addEventListener('beforeinstallprompt', (e) => {
deferredPrompt = e;
});

function promptInstall() {
deferredPrompt.prompt();
}

window.addEventListener('appinstalled', () => {
deferredPrompt = null;
console.log('App installed!');
});
