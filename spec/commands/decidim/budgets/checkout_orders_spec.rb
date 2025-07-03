# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::CheckoutOrders do
  let(:command) { described_class.new(orders, user) }

  let(:form) { Decidim::Budgets::BudgetSelectForm.from_params(budget_ids: [budget.id]) }
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, organization: organization) }

  let(:participatory_space) { create(:participatory_process, organization: organization) }
  let(:component) { create(:budgets_component, :with_budget_projects_range, participatory_space: participatory_space) }
  let(:budget1) { create(:budget, component: component) }
  let(:budget1_projects) { create_list(:project, 5, budget: budget1) }
  let(:budget2) { create(:budget, component: component) }
  let(:budget2_projects) { create_list(:project, 5, budget: budget2) }

  let(:amt_projects) { [3, 4] }

  let(:orders) { [order1, order2] }
  let(:order1) do
    create(:order, user: user, budget: budget1).tap do |ord|
      budget1_projects.sample(amt_projects[0]).each { |pr| ord.projects << pr }
      ord.save!
    end
  end
  let(:order2) do
    create(:order, user: user, budget: budget2).tap do |ord|
      budget2_projects.sample(amt_projects[1]).each { |pr| ord.projects << pr }
      ord.save!
    end
  end

  describe "#call" do
    subject { command.call }

    it "broadcasts OK" do
      expect { subject }.to broadcast(:ok)
    end

    it "changes the checked out time for all orders" do
      expect { subject }.to(
        change { orders.map(&:checked_out_at) }
      )
    end

    it "creates a vote" do
      expect { subject }.to change(Decidim::Budgets::Vote, :count).by(1)
    end

    context "with concurrency", :threaded do
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

      it "only creates a single vote" do
        expect do
          threads = 20.times.map do
            Thread.new do
              sleep(rand(0.05..0.5))
              # command.call
              usr = Decidim::User.find(user.id)
              ords = Decidim::Budgets::Order.where(id: orders)
              described_class.new(ords, usr).call
            end
          end
          # Wait for each thread to finish
          threads.each(&:join)
        end.not_to raise_error

        expect(Decidim::Budgets::Vote.count).to eq(1)
      end
    end

    context "when the orders is empty" do
      let(:orders) { [] }

      it "broadcasts invalid" do
        expect { subject }.to broadcast(:invalid)
      end
    end

    context "when one of the orders is invalid" do
      it "broadcasts invalid" do
        allow(order1).to receive(:invalid?).and_return(true)

        expect { subject }.to broadcast(:invalid)
      end

      context "with the actual saving" do
        let(:amt_projects) { [1, 4] }

        it "broadcasts invalid" do
          expect { subject }.to broadcast(:invalid)
        end

        it "does not create a vote" do
          expect { subject }.not_to change(Decidim::Budgets::Vote, :count)
        end
      end
    end
  end
end
