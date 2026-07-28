/* MacTape site behaviour. Shared by index.html and privacy.html. */
document.documentElement.classList.add("js");

(function () {
  "use strict";

  var reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* ---------------------------------------------------------
     Floating chrome: condense the bar once the page scrolls
     past the first screen, and drive the mobile menu.
     --------------------------------------------------------- */
  var chrome = document.getElementById("chrome");

  if (chrome) {
    var syncScrolled = function () {
      chrome.classList.toggle("stuck", window.scrollY > 64);
    };
    syncScrolled();
    window.addEventListener("scroll", syncScrolled, { passive: true });

    var closeMobile = function () {
      chrome.classList.remove("open");
      var trigger = chrome.querySelector(".menu-btn");
      if (trigger) trigger.setAttribute("aria-expanded", "false");
      chrome.querySelectorAll(".m-row").forEach(function (row) {
        row.setAttribute("data-open", "false");
        var rowTrigger = row.querySelector(".m-trigger");
        if (rowTrigger) rowTrigger.setAttribute("aria-expanded", "false");
      });
    };

    var menuBtn = chrome.querySelector(".menu-btn");
    if (menuBtn) {
      menuBtn.addEventListener("click", function () {
        var next = !chrome.classList.contains("open");
        chrome.classList.toggle("open", next);
        menuBtn.setAttribute("aria-expanded", String(next));
        menuBtn.setAttribute(
          "aria-label",
          next ? "Close navigation menu" : "Open navigation menu"
        );
        if (!next) closeMobile();
      });
    }

    /* One mobile row open at a time, matching the desktop dropdowns. */
    chrome.querySelectorAll(".m-row .m-trigger").forEach(function (trigger) {
      trigger.addEventListener("click", function () {
        var row = trigger.closest(".m-row");
        var wasOpen = row.getAttribute("data-open") === "true";
        chrome.querySelectorAll(".m-row").forEach(function (other) {
          other.setAttribute("data-open", "false");
          var otherTrigger = other.querySelector(".m-trigger");
          if (otherTrigger) otherTrigger.setAttribute("aria-expanded", "false");
        });
        row.setAttribute("data-open", wasOpen ? "false" : "true");
        trigger.setAttribute("aria-expanded", String(!wasOpen));
      });
    });

    chrome.querySelectorAll(".chrome-mobile a").forEach(function (link) {
      link.addEventListener("click", closeMobile);
    });

    var scrim = chrome.querySelector(".chrome-scrim");
    if (scrim) scrim.addEventListener("click", closeMobile);

    window.addEventListener("resize", function () {
      if (window.innerWidth > 940) closeMobile();
    });

    /* Desktop dropdown groups. Close on outside click, scroll, or Escape. */
    var groups = chrome.querySelectorAll(".dd");

    var closeGroups = function () {
      groups.forEach(function (group) {
        group.setAttribute("data-open", "false");
        var trigger = group.querySelector(".dd-trigger");
        if (trigger) trigger.setAttribute("aria-expanded", "false");
      });
    };

    groups.forEach(function (group) {
      var trigger = group.querySelector(".dd-trigger");
      trigger.addEventListener("click", function (event) {
        event.stopPropagation();
        var wasOpen = group.getAttribute("data-open") === "true";
        closeGroups();
        if (!wasOpen) {
          group.setAttribute("data-open", "true");
          trigger.setAttribute("aria-expanded", "true");
        }
      });
    });

    document.addEventListener("click", function (event) {
      if (!event.target.closest(".dd")) closeGroups();
    });
    window.addEventListener("scroll", closeGroups, { passive: true });
    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape") {
        closeGroups();
        closeMobile();
      }
    });
  }

  /* ---------------------------------------------------------
     Live GitHub star count for the chrome pill. Cached per tab
     so a reload does not spend another anonymous API call.
     --------------------------------------------------------- */
  (function stars() {
    var slots = document.querySelectorAll("[data-stars]");
    if (!slots.length) return;

    var CACHE_KEY = "mactape:stars";

    var format = function (count) {
      if (count < 1000) return String(count);
      var scaled = (count / 1000).toFixed(count >= 10000 ? 0 : 1);
      return scaled.replace(/\.0$/, "") + "k";
    };

    var paint = function (count) {
      var text = format(count);
      slots.forEach(function (slot) {
        slot.textContent = text;
      });
    };

    try {
      var cached = window.sessionStorage.getItem(CACHE_KEY);
      if (cached !== null) {
        paint(parseInt(cached, 10));
        return;
      }
    } catch (error) {
      /* Private browsing can block sessionStorage; fall through to the fetch. */
    }

    fetch("https://api.github.com/repos/svvayyy/MacTape", {
      headers: { Accept: "application/vnd.github+json" },
    })
      .then(function (response) {
        return response.ok ? response.json() : null;
      })
      .then(function (data) {
        if (!data || typeof data.stargazers_count !== "number") return;
        try {
          window.sessionStorage.setItem(
            CACHE_KEY,
            String(data.stargazers_count)
          );
        } catch (error) {
          /* Nothing to cache into; the count still renders for this view. */
        }
        paint(data.stargazers_count);
      })
      .catch(function () {
        /* Rate limited or offline: the pill stays a plain star link. */
      });
  })();

  /* ---------------------------------------------------------
     Scroll reveal
     --------------------------------------------------------- */
  var revealables = document.querySelectorAll(".rv");

  if (!("IntersectionObserver" in window) || reduce) {
    revealables.forEach(function (el) {
      el.classList.add("in");
    });
  } else {
    var revealObserver = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting) return;
          entry.target.classList.add("in");
          revealObserver.unobserve(entry.target);
        });
      },
      { rootMargin: "0px 0px -8% 0px", threshold: 0.08 }
    );
    revealables.forEach(function (el, index) {
      el.style.transitionDelay = Math.min(index % 6, 5) * 55 + "ms";
      revealObserver.observe(el);
    });
  }

  /* ---------------------------------------------------------
     Pointer glow on the feature cards
     --------------------------------------------------------- */
  document.querySelectorAll(".card").forEach(function (card) {
    card.addEventListener("pointermove", function (event) {
      var bounds = card.getBoundingClientRect();
      card.style.setProperty("--mx", event.clientX - bounds.left + "px");
      card.style.setProperty("--my", event.clientY - bounds.top + "px");
    });
  });

  /* ---------------------------------------------------------
     Pause timeline: collapse the gap once it scrolls into view
     --------------------------------------------------------- */
  var timeline = document.getElementById("tl");
  if (timeline) {
    if (reduce || !("IntersectionObserver" in window)) {
      timeline.classList.add("run");
    } else {
      var timelineObserver = new IntersectionObserver(
        function (entries) {
          entries.forEach(function (entry) {
            if (!entry.isIntersecting) return;
            window.setTimeout(function () {
              timeline.classList.add("run");
            }, 420);
            timelineObserver.unobserve(entry.target);
          });
        },
        { threshold: 0.45 }
      );
      timelineObserver.observe(timeline);
    }
  }

  /* ---------------------------------------------------------
     Cycle the recording-state chips while they are on screen
     --------------------------------------------------------- */
  var statesRow = document.getElementById("states");
  if (statesRow && !reduce) {
    var chips = statesRow.querySelectorAll(".state");
    var sequence = [0, 1, 2, 3, 2, 4, 0];
    var step = 0;
    var timer = null;

    var advance = function () {
      chips.forEach(function (chip) {
        chip.classList.remove("on");
      });
      chips[sequence[step % sequence.length]].classList.add("on");
      step++;
    };

    var statesObserver = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting && !timer) {
            advance();
            timer = window.setInterval(advance, 1400);
          } else if (!entry.isIntersecting && timer) {
            window.clearInterval(timer);
            timer = null;
          }
        });
      },
      { threshold: 0.3 }
    );
    statesObserver.observe(statesRow);
  }
})();
