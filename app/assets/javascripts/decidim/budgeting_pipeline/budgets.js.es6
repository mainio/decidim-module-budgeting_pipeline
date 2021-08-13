((exports) => {
  const $ = exports.$; // eslint-disable-line id-length

  $(() => {
    $(".detail-selector").each((_i, el) => {
      const $selector = $(el);
      const $inputs = $('input[type="radio"], input[type="checkbox"]', $selector);

      $inputs.on("change", () => {
        $inputs.each((_j, inputEl) => {
          const $input = $(inputEl);
          const $item = $input.parents(".detail-selector-item");
          if ($input.is(":checked")) {
            $item.addClass("selected");
          } else {
            $item.removeClass("selected");
          }
        });
      });
    });
  });
})(window);
