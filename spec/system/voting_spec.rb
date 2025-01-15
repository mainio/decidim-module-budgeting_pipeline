# frozen_string_literal: true

require "spec_helper"

describe "Voting" do
  include_context "with budgeting setup"

  describe "show" do
    context "when the user is not logged in" do
      it "displays the sign in page" do
        visit_voting

        page.scroll_to find("h2", text: "Log in to the service to vote")
        content = find(".layout-container #content")
        within content do
          expect(page).to have_content(strip_tags(translated(component.settings.vote_identify_page_content)))
        end

        within ".voting-identity" do
          expect(page).to have_link("Sign in with Facebook")
          expect(page).to have_link("Sign in with Twitter")
          expect(page).to have_link("Sign in with Google")
        end
      end
    end

    context "when the user is logged in" do
      before { login_as user, scope: :user }

      context "when not authorized" do
        let!(:authorization) { nil }

        it "displays the authorization options" do
          visit_voting

          expect(page).to have_content("Log in to the service to vote")
          page.scroll_to find("h2", text: "Log in to the service to vote")

          within ".voting-identity" do
            expect(page).to have_link("Example authorization")
          end
        end
      end

      context "when authorized" do
        it "redirects to the budgets selection and allows selecting a budget" do
          visit_voting

          expect(page).to have_content("Select the area where you want to vote")
        end
      end
    end
  end

  describe "budgets" do
    before { login_as user, scope: :user }

    it "lists all available budgets" do
      visit_voting

      page.scroll_to find("h2", text: "Select the area where you want to vote")

      budgets.each do |budget|
        expect(find("h2", text: translated(budget.title))).not_to be_nil
      end
    end
  end

  describe "start" do
    before { login_as user, scope: :user }

    let(:project1) { budget_one.projects.first }

    it "allows selecting a budget" do
      visit_voting

      page.scroll_to find("h2", text: "Select the area where you want to vote")

      find("h2", text: translated(budget_one.title)).click
      find("input[name='filter[selected]']").click
      find("label[for=project_selector_#{project1.id}]").click

      expect(find("div#project-#{project1.id}-order-summary")).to have_content(translated(project1.title))
    end
  end

  describe "projects" do
    let(:budget) { budget_one }

    before do
      login_as user, scope: :user

      visit_voting
      find("h2", text: translated(budget.title)).click
    end

    it "lists the projects for the selected budget" do
      expect(page).to have_content("Found 10 proposals")
    end

    it "allows selecting projects" do
      page.scroll_to find(".orders-summary-item")

      first("#projects_table .projects-table__row") do |container|
        within container do
          find("input").click
        end
      end

      # May be different element when the cart is updated
      expect(page).to have_button("Remove from vote")
    end

    context "when project is selected" do
      it "does not allow exceeding the budget" do
        page.scroll_to find(".orders-summary-item")

        all("#projects_table .projects-table__row").each do |container|
          within container do
            find("input").click
          end
        end

        expect(page).to have_css("#order-update-error-modal")
        expect(page).to have_content("You have already added the maximum amount of proposals")
      end

      it "shows progress correctly" do
        first("#projects_table .projects-table__row") do |container|
          within container do
            find("input").click
          end
        end

        page.scroll_to find_by_id("orders-summary")

        within "#orders-summary" do
          expect(page).to have_content("4 votes remaining")

          within ".voting-progress__indicator" do
            uses = all("use")
            expect(uses.size).to eq(5)

            hrefs = uses.map { |use| use[:href] }

            circle_line_count = hrefs.count { |href| href.include?("ri-checkbox-circle-line") }
            blank_circle_line_count = hrefs.count { |href| href.include?("ri-checkbox-blank-circle-line") }

            expect(circle_line_count).to eq(1)
            expect(blank_circle_line_count).to eq(4)
          end
        end
      end
    end
  end

  describe "preview" do
    let(:budget) { budget_one }
    let!(:order) { create(:order, budget: budget_one, user:) }

    before do
      order.projects << budget_one_projects.first
      order.save!

      login_as user, scope: :user

      visit_voting_preview

      page.scroll_to find("h2", text: "Preview and vote")
    end

    it "shows the vote preview page" do
      expect(page).to have_content("Maximum amount of proposals to be selected in the area: 5")
      expect(page).to have_content(translated(budget_one_projects.first.title))
    end
  end

  describe "create" do
    let(:budget) { budget_one }
    let!(:order) { create(:order, budget: budget_one, user:) }

    before do
      order.projects << budget_one_projects.first
      order.save!

      login_as user, scope: :user

      visit_voting_preview

      page.scroll_to find("h2", text: "Preview and vote")
    end

    it "can cast the vote" do
      click_on "Vote"

      within "#vote-finished-modal" do
        expect(page).to have_content("Thank you for your vote!")
      end
    end
  end
end
