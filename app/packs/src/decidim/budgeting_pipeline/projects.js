((exports) => {
  const Rails = exports.Rails;

  const stickySummary = () => {
    const ordersSummary = document.getElementById("orders-summary");
    const stickPosition = document.createElement("div");
    const placeHolder = document.createElement("div");
    stickPosition.style.position = "relative";
    placeHolder.style.visibility = "hidden";
    ordersSummary.parentElement.insertBefore(stickPosition, ordersSummary);
    stickPosition.appendChild(placeHolder);

    // placeHolder.style.height = `${ordersSummary.offsetHeight}px`;
    // console.log(ordersSummary.offsetHeight);

    document.addEventListener("scroll", (event) => {
      if (window.scrollY > stickPosition.offsetTop) {
        if (!ordersSummary.classList.contains("is-stuck")) {
          placeHolder.style.height = `${ordersSummary.offsetHeight}px`;
          ordersSummary.classList.add("is-stuck");
        }
      } else {
        if (ordersSummary.classList.contains("is-stuck")) {
          ordersSummary.classList.remove("is-stuck");
          placeHolder.style.height = 0;
        }
      }
    });
  };

  window.initializeProjects = () => {
    const loadingProjects = [];
    document.querySelectorAll("[data-project-selector] input[type='checkbox']").forEach((el) => {
      el.addEventListener("change", () => {
        loadingProjects.push(el.value);
        document.body.classList.add("loading");
        Rails.ajax({
          url: el.dataset.selectUrl,
          type: el.checked ? "POST" : "DELETE",
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
      el.querySelector(".projects-table__row__data").addEventListener("click", (ev) => {
        ev.preventDefault();

        if (el.dataset.open) {
          el.removeAttribute("data-open");
        } else {
          el.setAttribute("data-open", true);
        }
      });
    });
  };

  stickySummary();
  window.initializeProjects();
})(window);
