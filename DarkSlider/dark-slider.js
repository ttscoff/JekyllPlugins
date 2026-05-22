/**
 * Dark/light image comparison slider (vanilla JS, no dependencies).
 * Expects markup from the dark_slider Jekyll tag (figure.dark-slider).
 */
(function (global) {
  "use strict";

  var initialized = false;

  function clamp(n, min, max) {
    return Math.min(max, Math.max(min, n));
  }

  function syncLightMediaWidth(fig) {
    var w = fig.offsetWidth;
    if (!w) {
      return;
    }
    var media = fig.querySelector(".dark-slider__light picture, .dark-slider__light img");
    if (media) {
      media.style.width = w + "px";
    }
  }

  function setPosition(fig, pct) {
    var p = clamp(pct, 0, 100);
    fig.style.setProperty("--pos", p + "%");
    var range = fig.querySelector(".dark-slider__range");
    if (range) {
      range.value = String(p);
      range.setAttribute("aria-valuenow", String(Math.round(p)));
    }
  }

  function positionFromEvent(fig, ev) {
    var rect = fig.getBoundingClientRect();
    if (!rect.width) {
      return 50;
    }
    var x = (ev.clientX !== undefined ? ev.clientX : ev.touches[0].clientX) - rect.left;
    return (x / rect.width) * 100;
  }

  function bindFigure(fig) {
    if (fig.getAttribute("data-dark-slider-bound") === "1") {
      return;
    }
    fig.setAttribute("data-dark-slider-bound", "1");

    var range = fig.querySelector(".dark-slider__range");
    if (!range) {
      return;
    }

    range.addEventListener("input", function () {
      setPosition(fig, parseFloat(range.value, 10));
    });

    range.addEventListener("change", function () {
      setPosition(fig, parseFloat(range.value, 10));
    });

    var dragging = false;

    function onPointerDown(ev) {
      if (ev.target === range) {
        return;
      }
      dragging = true;
      fig.classList.add("dark-slider--dragging");
      setPosition(fig, positionFromEvent(fig, ev));
      if (ev.preventDefault) {
        ev.preventDefault();
      }
    }

    function onPointerMove(ev) {
      if (!dragging) {
        return;
      }
      setPosition(fig, positionFromEvent(fig, ev));
    }

    function onPointerUp() {
      dragging = false;
      fig.classList.remove("dark-slider--dragging");
    }

    fig.addEventListener("mousedown", onPointerDown);
    fig.addEventListener("touchstart", onPointerDown, { passive: false });
    global.addEventListener("mousemove", onPointerMove);
    global.addEventListener("touchmove", onPointerMove, { passive: false });
    global.addEventListener("mouseup", onPointerUp);
    global.addEventListener("touchend", onPointerUp);
    global.addEventListener("touchcancel", onPointerUp);

    var initial = parseFloat(range.getAttribute("value") || range.value || "50", 10);
    setPosition(fig, isNaN(initial) ? 50 : initial);
    syncLightMediaWidth(fig);

    if (global.ResizeObserver) {
      var ro = new global.ResizeObserver(function () {
        syncLightMediaWidth(fig);
      });
      ro.observe(fig);
    } else {
      global.addEventListener("resize", function () {
        syncLightMediaWidth(fig);
      });
    }
  }

  function init(root) {
    root = root || global.document;
    var figures = root.querySelectorAll
      ? root.querySelectorAll("figure.dark-slider")
      : [];
    for (var i = 0; i < figures.length; i++) {
      bindFigure(figures[i]);
    }
    initialized = true;
  }

  global.DarkSlider = {
    init: init
  };

  function onReady() {
    init(global.document);
  }

  if (global.document) {
    if (global.document.readyState === "loading") {
      global.document.addEventListener("DOMContentLoaded", onReady);
    } else {
      onReady();
    }
  }
})(typeof window !== "undefined" ? window : this);
