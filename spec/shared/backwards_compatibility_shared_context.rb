# frozen_string_literal: true

shared_context "with backwards compatibility" do
  let(:projects_rule) { true }
  let(:projects_rule_maximum_projects) { 1 }
  let(:projects_rule_total_projects) { 0 }

  let(:order_available_allocation) { projects_rule_maximum_projects }
  let(:order_total) { 0 }

  before do
    # For backwards compatibility, these methods need to be defined.
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Decidim::Budgets::Order).to receive(:available_allocation).and_return(order_available_allocation)
    allow_any_instance_of(Decidim::Budgets::Order).to receive(:total).and_return(order_total)

    if projects_rule
      allow_any_instance_of(Decidim::Budgets::Order).to receive(:projects_rule?).and_return(projects_rule)
      allow_any_instance_of(Decidim::Budgets::Order).to receive(:maximum_projects).and_return(projects_rule_maximum_projects)
      allow_any_instance_of(Decidim::Budgets::Order).to receive(:total_projects).and_return(projects_rule_total_projects)
    end
    # rubocop:enable RSpec/AnyInstance
  end
end
