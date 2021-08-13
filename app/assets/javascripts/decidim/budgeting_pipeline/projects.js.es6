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
  });
})(window);
