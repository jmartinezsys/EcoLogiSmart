{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    const loader = document.getElementById('app-loading');
    if (loader) {
      loader.classList.add('app-loading-hidden');
      window.setTimeout(() => loader.remove(), 220);
    }
  },
});
