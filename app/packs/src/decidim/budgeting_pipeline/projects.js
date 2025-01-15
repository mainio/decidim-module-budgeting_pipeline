((exports) => {
  const Rails = exports.Rails;

  const stickySummary = () => {
    const ordersSummary = document.getElementById("orders-summary");
    if (!ordersSummary) {
      return;
    }

    const stickPosition = document.createElement("div");
    const placeHolder = document.createElement("div");
    stickPosition.style.position = "relative";
    placeHolder.style.visibility = "hidden";
    ordersSummary.parentElement.insertBefore(stickPosition, ordersSummary);
    stickPosition.appendChild(placeHolder);

    // placeHolder.style.height = `${ordersSummary.offsetHeight}px`;
    // console.log(ordersSummary.offsetHeight);

    document.addEventListener("scroll", () => {
      if (window.scrollY > stickPosition.offsetTop) {
        if (!ordersSummary.classList.contains("is-stuck")) {
          placeHolder.style.height = `${ordersSummary.offsetHeight}px`;
          ordersSummary.classList.add("is-stuck");
        }
      } else {
        if (ordersSummary.classList.contains("is-stuck")) {
          ordersSummary.classList.remove("is-stuck");
          placeHolder.style.height = 0;
        } else {
          return;
        }
      }
    });
  };

  const voteActionHandler = () => {
    document.body.classList.add("loading");
  };

  window.updateBudget = () => {
    const continueButton = document.getElementById("projects_continue_button")?.querySelector(".button");
    if (continueButton) {
      continueButton.addEventListener("click", voteActionHandler);
    }

    const continueButtonMobile = document.getElementById("projects_continue_button_mobile")?.querySelector(".button");
    if (continueButtonMobile) {
      continueButtonMobile.addEventListener("click", voteActionHandler);
    }
  };

  const initializeFilters = () => {
    document.querySelectorAll("[id^='additional_search_toggle']").forEach((toggleButton) => {
      toggleButton.addEventListener("click", () => {
        const typeSuffix = toggleButton.id.replace("additional_search_toggle", "");
        const additionalSearch = document.getElementById(`additional_search${typeSuffix}`);
        const closedLabel = document.getElementById(`additional_search_closed${typeSuffix}`);
        const openLabel = document.getElementById(`additional_search_open${typeSuffix}`);

        additionalSearch.classList.toggle("hidden");

        closedLabel.classList.toggle("hidden");
        openLabel.classList.toggle("hidden");

        const isExpanded = toggleButton.getAttribute("aria-expanded") === "true";
        toggleButton.setAttribute("aria-expanded", !isExpanded);
      });
    });
  }

  window.initializeProjects = () => {
    const loadingProjects = [];
    document.querySelectorAll("[data-project-selector] input[type='checkbox']").forEach((el) => {

      el.addEventListener("change", () => {
        let requestType;

        if (el.checked) {
          requestType = "POST";
        } else {
          requestType = "DELETE";
        }

        loadingProjects.push(el.value);
        document.body.classList.add("loading");
        Rails.ajax({
          url: el.dataset.selectUrl,
          type: requestType,
          success: () => {
            loadingProjects.shift();
            if (loadingProjects.length < 1) {
              document.body.classList.remove("loading");
            }
          },
          error: () => {
            loadingProjects.shift();
            if (loadingProjects.length < 1) {
              document.body.classList.remove("loading");
            }
          }
        });
      });
    });

    document.querySelectorAll(".projects-table__row").forEach((el) => {
      const clickableArea = el.querySelector(".projects-table__row__data");
      const button = clickableArea.querySelector(".projects-table__row__button")
      const clickHandler = (ev) => {
        ev.preventDefault();

        if (el.dataset.showDetails) {
          el.removeAttribute("data-show-details");
          button.setAttribute("aria-expanded", false);
        } else {
          el.setAttribute("data-show-details", true);
          button.setAttribute("aria-expanded", true);
        }
      }

      clickableArea.addEventListener("click", clickHandler);

      // eslint-disable-next-line no-undef
      button.addEventListener("keydown", (ev) => {
        if (ev.code === "Enter" || ev.code === "Space") {
          buttonClickHandler(ev);
        }
      });
    });
  };

  initializeFilters();
  stickySummary();
  window.initializeProjects();
  window.updateBudget();
})(window);
