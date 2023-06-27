import { unregisterCallback } from "src/decidim/history";
import "src/decidim/budgeting_pipeline/exit_handler";

((exports) => {
  const $ = exports.$; // eslint-disable-line id-length
  const Rails = exports.Rails;

  $(() => {
    const $form = $("form.new_filter");

    $form.on("reset.budgets", () => {
      // Give the browser a bit of time to clear the fields
      setTimeout(() => {
        Rails.fire($form[0], "submit");
      }, 100);
    });

    // Unregister the history callbacks for the filter forms because they cause
    // the form to be sent when anchor links are clicked. This would cause the
    // results to flash and also causes the screen reader to announce the number
    // of results. They would also never trigger because the change events are
    // disabled for all filter inputs.
    $form.each((_i, el) => {
      const $currentForm = $(el);
      unregisterCallback(`filters-${$currentForm.attr("id")}`);
    });
  });
})(window);
