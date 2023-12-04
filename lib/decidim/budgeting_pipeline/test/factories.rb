# frozen_string_literal: true

require "decidim/budgets/test/factories"

FactoryBot.define do
  factory :budgeting_pipeline_component, parent: :budgets_component do
    transient do
      vote_rule_settings do
        {
          vote_rule_threshold_percent_enabled: false,
          vote_threshold_percent: 70,
          vote_rule_minimum_budget_projects_enabled: false,
          vote_minimum_budget_projects_number: 0,
          vote_rule_selected_projects_enabled: true,
          vote_selected_projects_minimum: 0,
          vote_selected_projects_maximum: 5
        }
      end

      vote_projects_per_page { 6 }
      more_information_modal_label { generate_localized_title }
      geocoding_enabled { true }
      default_map_center_coordinates { "60.1674881,24.9427473" }
      vote_identify_page_content { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_title } }
      vote_identify_page_more_information { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_title } }
      vote_identify_invalid_authorization_title { generate_localized_title }
      vote_identify_invalid_authorization_content { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_title } }
      vote_budgets_page_content { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_title } }
      vote_projects_page_content { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_title } }
      vote_preview_page_content { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_title } }
      vote_success_content { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_title } }
      results_page_content { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_title } }
    end

    settings do
      vote_rule_settings.merge(
        # Pipeline settings
        vote_projects_per_page: vote_projects_per_page,
        more_information_modal_label: more_information_modal_label,
        geocoding_enabled: geocoding_enabled,
        default_map_center_coordinates: default_map_center_coordinates,
        vote_identify_page_content: vote_identify_page_content,
        vote_identify_page_more_information: vote_identify_page_more_information,
        vote_identify_invalid_authorization_title: vote_identify_invalid_authorization_title,
        vote_identify_invalid_authorization_content: vote_identify_invalid_authorization_content,
        vote_budgets_page_content: vote_budgets_page_content,
        vote_projects_page_content: vote_projects_page_content,
        vote_preview_page_content: vote_preview_page_content,
        vote_success_content: vote_success_content,
        results_page_content: results_page_content
      )
    end
  end

  factory :budgeting_pipeline_budget, parent: :budget do
    component { create(:budgeting_pipeline_component) }
    center_latitude { Faker::Address.latitude }
    center_longitude { Faker::Address.longitude }
  end

  factory :budgeting_pipeline_project, parent: :project do
    summary { generate_localized_title }
    address { "#{Faker::Address.street_address} #{Faker::Address.zip} #{Faker::Address.city}" }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
    budget_amount_min { Faker::Boolean.boolean ? Faker::Number.number(digits: 5) : nil }
    paper_orders_count { rand(0..10) }
  end

  factory :budgeting_pipeline_help_section, class: "Decidim::Budgets::HelpSection" do
    component { create(:budgeting_pipeline_component) }
    key { [:index, :pipeline].sample }
    weight { 0 }
    title { generate_localized_title }
    description { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_title } }
    link { "https://decidim.org" }
    link_text { generate_localized_title }
  end

  factory :budgeting_pipeline_vote, class: "Decidim::Budgets::Vote" do
    transient do
      order_count { 0 }
      order_checked_out { true }
    end

    component { create(:budgeting_pipeline_component) }
    user { create(:user, organization: component.organization) }

    after(:create) do |vote, evaluator|
      budgets = Decidim::Budgets::Budget.where(component: vote.component).order(Arel.sql("RANDOM()"))

      (evaluator.order_count || rand(1..budgets.count)).times do |idx|
        budget = budgets[idx]
        budget ||= create(:budget, component: vote.component)

        order = create(:order, budget: budget, user: vote.user)
        order.update!(checked_out_at: Time.current) if evaluator.order_checked_out
        vote.orders << order
      end
      vote.save!
    end
  end

  factory :budgeting_pipeline_order, parent: :order do
    vote { create(:budgeting_pipeline_vote, user: user, component: budget.component, order_checked_out: false) }
  end
end
