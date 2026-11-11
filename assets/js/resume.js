// Loaded in <head> without defer so the theme is applied before first paint.
// The game page loads it too, for the theme only; it has no toggle or print dialog.
(function () {
  "use strict";

  var THEME_KEY = "resume-theme";
  var root = document.documentElement;

  function storedTheme() {
    try {
      return window.localStorage.getItem(THEME_KEY);
    } catch (_error) {
      return null;
    }
  }

  function storeTheme(theme) {
    try {
      window.localStorage.setItem(THEME_KEY, theme);
    } catch (_error) {
      // Private windows can block storage; the toggle still works for this visit.
    }
  }

  function systemTheme() {
    var prefersDark = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
    return prefersDark ? "dark" : "light";
  }

  function applyTheme(theme) {
    root.setAttribute("data-theme", theme);

    var toggle = document.getElementById("theme-toggle");
    if (toggle) {
      toggle.setAttribute("aria-pressed", String(theme === "dark"));
      toggle.textContent = theme === "dark" ? "Light mode" : "Dark mode";
    }
  }

  // Phone and email exist only in what the visitor types here. They are written
  // into print-only header slots and cleared again once printing finishes.
  function setContactSlot(id, value) {
    var slot = document.getElementById(id);
    var text = value.trim();
    slot.textContent = text;
    slot.hidden = text === "";
  }

  function clearContactSlots() {
    setContactSlot("contact-phone", "");
    setContactSlot("contact-email", "");
  }

  function setUpThemeToggle() {
    var toggle = document.getElementById("theme-toggle");
    if (!toggle) return;

    applyTheme(root.getAttribute("data-theme"));

    toggle.addEventListener("click", function () {
      var next = root.getAttribute("data-theme") === "dark" ? "light" : "dark";
      storeTheme(next);
      applyTheme(next);
    });
  }

  function setUpPrinting() {
    var dialog = document.getElementById("print-dialog");
    var form = document.getElementById("print-form");
    if (!dialog) return;

    document.getElementById("print-button").addEventListener("click", function () {
      if (typeof dialog.showModal === "function") {
        dialog.showModal();
      } else {
        window.print();
      }
    });

    document.getElementById("print-cancel").addEventListener("click", function () {
      dialog.close();
    });

    form.addEventListener("submit", function (event) {
      event.preventDefault();
      setContactSlot("contact-phone", form.elements.phone.value);
      setContactSlot("contact-email", form.elements.email.value);
      dialog.close();
      window.print();
    });

    window.addEventListener("afterprint", clearContactSlots);
  }

  applyTheme(storedTheme() || systemTheme());

  document.addEventListener("DOMContentLoaded", function () {
    setUpThemeToggle();
    setUpPrinting();
  });
})();
