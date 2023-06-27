$(() => {
  const { attachGeocoding } = window.Decidim;

  const $form = $("form.new_project, form.edit_project");
  if ($form.length < 1) {
    return;
  }

  const $address = $("#project_address", $form);
  if ($address.length !== 0) {
    attachGeocoding($address);
  }
});
