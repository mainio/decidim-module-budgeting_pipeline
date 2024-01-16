import { unregisterCallback } from "src/decidim/history";
import "src/decidim/budgeting_pipeline/exit_handler";

((exports) => {
  const $ = exports.$; // eslint-disable-line id-length
  const Rails = exports.Rails;

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

  window.initializeProjects();
})(window);
