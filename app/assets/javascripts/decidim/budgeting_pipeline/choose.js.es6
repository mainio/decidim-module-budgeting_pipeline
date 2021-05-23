((exports) => {
  const $ = exports.$; // eslint-disable-line id-length

  const checkVotingAllowed = () => {
    const $button = $("#proceed-button");

    if ($(".order-progress[data-valid='false']").length > 0) {
      $button.attr("disabled", true);
    } else {
      $button.attr("disabled", false);
    }
  };

  $(() => {
    checkVotingAllowed();

    $(".order-wrapper").each((_i, el) => {
      const $order = $(el);

      const $confirmAll = $(".form.confirm_all_line_items input[type='checkbox']", $order);
      const $confirms = $(".form.confirm_line_item input[type='checkbox']", $order);
      $confirmAll.on("change", () => {
        if ($confirmAll.is(":checked")) {
          $confirms.prop("checked", true);
        } else {
          $confirms.prop("checked", false);
        }
      });

      $confirms.on("change", () => {
        const states = $.map($confirms, (confirm) => {
          return $(confirm).prop("checked")
        });
        if (states.every((val) => val === true)) {
          $confirmAll.prop("checked", true);
        } else {
          $confirmAll.prop("checked", false);
        }
      });
    });
  });

  window.DecidimBudgetingPipeline = window.DecidimBudgetingPipeline || {};
  window.DecidimBudgetingPipeline.checkVotingAllowed = checkVotingAllowed;
})(window);
