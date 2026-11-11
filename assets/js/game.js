// Boots the Elixir runtime (Popcorn) for the easter egg page.
//
// The runtime needs cross-origin isolation. On first visit coi-serviceworker.js
// registers itself and reloads the page once to switch it on, so "not isolated"
// is only reported as a failure if it is still true after a short wait.

const status = document.querySelector("#status");
const details = document.querySelector("#details");
const ISOLATION_GRACE_MS = 4000;

function report(message, detail) {
  status.textContent = message;
  details.textContent = detail || "";
}

async function boot() {
  const started = performance.now();
  const { Popcorn } = await import("../../game/out/index.mjs");

  // The app's supervision tree starts during init; Elixir then writes #status.
  await Popcorn.init();

  const elapsed = Math.round(performance.now() - started);
  details.textContent = "Runtime downloaded and booted in " + elapsed + " ms.";
}

if (window.crossOriginIsolated) {
  boot().catch(function (error) {
    report("The Elixir runtime failed to start.", String(error));
  });
} else {
  report("Preparing the page (it reloads once on first visit)…");

  window.setTimeout(function () {
    report(
      "This page could not be cross-origin isolated, so the Elixir runtime cannot start.",
      "Service workers may be blocked here, for example in a private window or when opened as a local file."
    );
  }, ISOLATION_GRACE_MS);
}
