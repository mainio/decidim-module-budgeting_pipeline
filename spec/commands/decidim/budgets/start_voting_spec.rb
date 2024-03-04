# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::StartVoting do
  let(:command) { described_class.new(form, user, workflow) }

  let(:form) { Decidim::Budgets::BudgetSelectForm.from_params(budget_ids: [budget.id]) }
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, organization: organization) }

  let(:participatory_space) { create(:participatory_process, organization: organization) }
  let(:component) { create(:budgets_component, :with_budget_projects_range, participatory_space: participatory_space) }
  let(:budget) { create(:budget, component: component) }
  let(:workflow) { Decidim::Budgets.workflows[:one].new(component, user) }

  describe "#call" do
    subject { command.call }

    it "broadcasts OK" do
      expect { subject }.to broadcast(:ok)
    end

    it "creates an order with the selected budget" do
      expect { subject }.to change(Decidim::Budgets::Order, :count).by(1)

      ord = Decidim::Budgets::Order.last
      expect(ord.budget).to eq(budget)
      expect(ord.user).to eq(user)
    end

    context "with concurrency" do
      # Disable transactional tests to allow multiple threads to work on the
      # same datasets at the same time without problems.
      self.use_transactional_tests = false

      after do
        # Because the transactional tests are disabled, we need to manually clear
        # the tables after the test.
        connection = ActiveRecord::Base.connection
        connection.disable_referential_integrity do
          connection.tables.each do |table_name|
            next if connection.select_value("SELECT COUNT(*) FROM #{table_name}").zero?

            connection.execute("TRUNCATE #{table_name} CASCADE")
          end
        end
      end

      it "only creates a single order" do
        expect do
          threads = 20.times.map do
            Thread.new do
              sleep(rand(0.05..0.5))

              usr = Decidim::User.find(user.id)
              described_class.new(form, usr, workflow)
            end
          end
          # Wait for each thread to finish
          threads.each(&:join)
        end.not_to raise_error

        expect(Decidim::Budgets::Order.count).to eq(1)
      end
    end
  end
end
