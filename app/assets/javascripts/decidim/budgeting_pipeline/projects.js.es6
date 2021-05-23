((exports) => {
  const $ = exports.$; // eslint-disable-line id-length

  $(() => {
    const $form = $("form.new_filter");

    $form.on("reset.ideas", () => {
      $('input[type="search"]').trigger("change");
    });
  });
})(window);
