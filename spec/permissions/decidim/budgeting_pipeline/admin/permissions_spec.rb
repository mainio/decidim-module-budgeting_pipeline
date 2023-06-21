# frozen_string_literal: true

require "spec_helper"

describe Decidim::BudgetingPipeline::Admin::Permissions do
  subject { described_class.new(user, permission_action, context).permissions.allowed? }

  let(:user) { build(:user, :confirmed, :admin) }
  let(:permission_action) { Decidim::PermissionAction.new(**action) }
  let(:context) { {} }
  let(:action) { { scope: :admin, action: action_name, subject: action_subject } }

  context "with help_section" do
    let(:action_subject) { :help_section }

    context "when create" do
      let(:action_name) { :create }

      it { is_expected.to be true }
    end

    context "when read" do
      let(:action_name) { :read }

      it { is_expected.to be true }
    end

    context "when update" do
      let(:action_name) { :update }

      it { is_expected.to be false }

      context "with a help section" do
        let(:context) { { help_section: double } }

        it { is_expected.to be true }
      end
    end

    context "when delete" do
      let(:action_name) { :delete }

      it { is_expected.to be false }

      context "with a help section" do
        let(:context) { { help_section: double } }

        it { is_expected.to be true }
      end
    end

    context "when any other action" do
      let(:action_name) { :foo }

      it_behaves_like "permission is not set"
    end
  end

  context "with budgets" do
    let(:action_subject) { :budgets }

    context "when read" do
      let(:action_name) { :export_results }

      it { is_expected.to be true }
    end

    context "when any other action" do
      let(:action_name) { :foo }

      it_behaves_like "permission is not set"
    end
  end

  context "with any other subject or action" do
    let(:action_subject) { :foo }
    let(:action_name) { :bar }

    it_behaves_like "permission is not set"
  end
end
