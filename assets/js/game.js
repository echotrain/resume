// The browser side of the easter egg. All game logic and rendering is Elixir
// (lib/resume/game); this file only boots the VM, puts the HTML it sends onto
// the page, and forwards keys, taps and swipes to the game server.
//
// The runtime needs cross-origin isolation. On first visit coi-serviceworker.js
// registers itself and reloads the page once to switch it on, so "not isolated"
// is only reported as a failure if it is still true after a short wait.

const SERVER = "Elixir.Resume.Game.Server";
const ISOLATION_GRACE_MS = 4000;
const FIRST_RENDER_GRACE_MS = 5000;
const SWIPE_MIN_PX = 24;

const TURN_KEYS = {
  ArrowUp: "up",
  ArrowDown: "down",
  ArrowLeft: "left",
  ArrowRight: "right",
  w: "up",
  s: "down",
  a: "left",
  d: "right",
};
const ACTION_KEYS = [" ", "Enter"];

const board = document.querySelector("#board");
const details = document.querySelector("#details");

// #status sits inside the board and disappears with the first render.
function report(message, detail) {
  const status = document.querySelector("#status");
  if (status) status.textContent = message;
  details.textContent = detail || "";
}

// Elixir sends {type: "render", regions: {elementId: html}} for whatever changed.
function applyRender(event) {
  if (!event || event.type !== "render") return;

  for (const [id, html] of Object.entries(event.regions)) {
    const region = document.getElementById(id);
    if (region) region.innerHTML = html;
  }
}

function connectInput(popcorn) {
  const cast = (request) => popcorn.cast(SERVER, request).catch(console.error);
  const turn = (direction) => cast(["turn", direction]);

  document.addEventListener("keydown", (event) => {
    if (event.metaKey || event.ctrlKey || event.altKey) return;

    const key = event.key.length === 1 ? event.key.toLowerCase() : event.key;

    if (TURN_KEYS[key]) {
      event.preventDefault();
      turn(TURN_KEYS[key]);
    } else if (ACTION_KEYS.includes(event.key) && !event.target.closest("button, a")) {
      // On a focused button or link the browser's own click does the work.
      event.preventDefault();
      cast("action");
    }
  });

  // pointerdown, not click, so the steering buttons respond without delay.
  document.addEventListener("pointerdown", (event) => {
    const button = event.target.closest("[data-turn]");
    if (button) turn(button.dataset.turn);
  });

  document.addEventListener("click", (event) => {
    const button = event.target.closest("[data-event]");
    if (button) cast(button.dataset.event);
  });

  // Swipes: each time the finger travels far enough, steer and start measuring
  // again, so one continuous drag can take several corners.
  let origin = null;

  board.addEventListener("touchstart", (event) => {
    const touch = event.touches[0];
    origin = { x: touch.clientX, y: touch.clientY };
  });

  board.addEventListener("touchmove", (event) => {
    if (!origin) return;

    const touch = event.touches[0];
    const dx = touch.clientX - origin.x;
    const dy = touch.clientY - origin.y;
    if (Math.max(Math.abs(dx), Math.abs(dy)) < SWIPE_MIN_PX) return;

    if (Math.abs(dx) > Math.abs(dy)) {
      turn(dx > 0 ? "right" : "left");
    } else {
      turn(dy > 0 ? "down" : "up");
    }
    origin = { x: touch.clientX, y: touch.clientY };
  });

  board.addEventListener("touchend", () => {
    origin = null;
  });
}

async function boot() {
  const started = performance.now();
  const { Popcorn } = await import("../../game/out/index.mjs");

  const popcorn = await Popcorn.init({
    onEvent: applyRender,
    onError: (event) => {
      console.error("Elixir VM error", event);
      details.textContent = "The Elixir VM reported an error. The browser console has the details.";
    },
  });

  console.info("Elixir runtime booted in " + Math.round(performance.now() - started) + " ms");

  connectInput(popcorn);
  await popcorn.cast(SERVER, "mount");

  window.setTimeout(() => {
    if (document.querySelector("#status")) {
      report("The game did not draw.", "The runtime started but sent nothing to show. The browser console may say why.");
    }
  }, FIRST_RENDER_GRACE_MS);
}

if (window.crossOriginIsolated) {
  boot().catch((error) => {
    report("The Elixir runtime failed to start.", String(error));
  });
} else {
  report("Preparing the page (it reloads once on first visit)…");

  window.setTimeout(() => {
    report(
      "This page could not be cross-origin isolated, so the Elixir runtime cannot start.",
      "Service workers may be blocked here, for example in a private window or when opened as a local file."
    );
  }, ISOLATION_GRACE_MS);
}
