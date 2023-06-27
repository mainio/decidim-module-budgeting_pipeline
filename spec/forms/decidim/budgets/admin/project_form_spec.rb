# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::Admin::ProjectForm do
  subject(:form) { described_class.from_params(attributes).with_context(context) }

  let(:organization) { create(:organization, tos_version: Time.current, available_locales: [:en]) }
  let(:context) do
    {
      current_organization: organization,
      current_component: current_component,
      current_participatory_space: participatory_process
    }
  end
  let(:participatory_process) { create(:participatory_process, organization: organization) }
  let(:current_component) { create(:budgets_component, participatory_space: participatory_process) }
  let(:budget) { create(:budget, component: current_component) }
  let(:title) do
    Decidim::Faker::Localized.sentence
  end
  let(:description) do
    Decidim::Faker::Localized.sentence
  end
  let(:budget_amount) { Faker::Number.number }
  let(:parent_scope) { create(:scope, organization: organization) }
  let(:scope) { create(:subscope, parent: parent_scope) }
  let(:scope_id) { scope.id }
  let(:category) { create(:category, participatory_space: participatory_process) }
  let(:category_id) { category.id }
  let(:selected) { nil }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }
  let(:address) { nil }
  let(:attributes) do
    {
      decidim_scope_id: scope_id,
      decidim_category_id: category_id,
      title_en: title[:en],
      description_en: description[:en],
      budget_amount: budget_amount,
      selected: selected,
      address: address
    }
  end

  context "when budget amount is zero" do
    let(:budget_amount) { 0 }

    it { is_expected.to be_valid }
  end

  context "when budget amount is negative" do
    let(:budget_amount) { -1 }

    it { is_expected.not_to be_valid }
  end
end
