{{flutter_js}}
{{flutter_build_config}}

(() => {
  const loader = document.getElementById('app-loading');
  const message = document.getElementById('app-loading-message');
  let firstFrameRendered = false;

  function hideLoader() {
    firstFrameRendered = true;
    if (!loader) return;
    loader.classList.add('app-loading-hidden');
    window.setTimeout(() => loader.remove(), 220);
  }

  function showStartupError() {
    if (!loader || firstFrameRendered) return;
    loader.classList.add('app-loading-error');
    if (message) {
      message.textContent =
        'No se pudo iniciar la aplicación. Comprueba tu conexión e inténtalo de nuevo.';
    }
  }

  // Flutter emits this event after painting its first frame. Using it avoids
  // leaving the HTML loader over a running app if runApp's future stays pending.
  window.addEventListener('flutter-first-frame', hideLoader, { once: true });
  window.setTimeout(showStartupError, 45000);

  _flutter.loader.load({
    onEntrypointLoaded: async function (engineInitializer) {
      try {
        const appRunner = await engineInitializer.initializeEngine();
        Promise.resolve(appRunner.runApp()).catch(showStartupError);
      } catch (error) {
        console.error('EcoLogiSmart failed to start:', error);
        showStartupError();
      }
    },
  }).catch((error) => {
    console.error('EcoLogiSmart failed to load Flutter:', error);
    showStartupError();
  });
})();
