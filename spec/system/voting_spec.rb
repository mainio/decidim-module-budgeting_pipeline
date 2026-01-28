# frozen_string_literal: true

require "spec_helper"

describe "Voting", type: :system do
  include_context "with budgeting setup"

  describe "show" do
    context "when the user is not logged in" do
      it "displays the sign in page" do
        visit_voting

        page.scroll_to find("h2", text: "Log in to the service to vote")

        contents = all(".wrapper .static__content")
        within contents[0] do
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

          expect(page).to have_content("Log in to the service to")
          page.scroll_to find("h2", text: "Log in to the service to")

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

      within ".voting-wrapper" do
        budgets.each do |budget|
          expect(find("h2", text: translated(budget.title))).not_to be_nil
        end
      end
    end
  end

  describe "start" do
    before { login_as user, scope: :user }

    it "allows selecting a budget" do
      visit_voting

      page.scroll_to find("h2", text: "Select the area where you want to vote")

      within ".voting-wrapper" do
        find("h2", text: translated(budget1.title)).find(:xpath, "ancestor::a").click
      end

      expect(page).to have_content("You have not selected any proposals from this area.")
    end
  end

  describe "projects" do
    let(:budget) { budget1 }

    before do
      login_as user, scope: :user

      visit_voting
      within ".voting-wrapper" do
        find("h2", text: translated(budget1.title)).find(:xpath, "ancestor::a").click
      end

      page.scroll_to find("#projects_table")
    end

    it "lists the projects for the selected budget" do
      expect(page).to have_content("Found 10 proposals")
    end

    it "allows selecting projects" do
      within all(".projects-table__row")[0] do
        find("input[type=checkbox]").click
      end

      expect(page).to have_content("4 votes remaining")
    end

    context "when project is selected" do
      it "does not allow exceeding the budget" do
        all(".projects-table__row")[0..4].each do |row|
          within row do
            find("input[type=checkbox]").click
          end
        end

        within all(".projects-table__row")[5] do
          expect(page).to have_css("input[type=checkbox][disabled]")
        end
      end

      it "shows progress correctly" do
        within all(".projects-table__row")[0] do
          find("input[type=checkbox]").click
        end

        page.scroll_to find("#orders-summary")

        within "#orders-summary" do
          expect(page).to have_content("4 votes remaining")
        end
      end
    end
  end

  describe "preview" do
    let(:budget) { budget1 }
    let!(:order) { create(:order, budget: budget1, user: user) }

    before do
      order.projects << budget1_projects.first
      order.save!

      login_as user, scope: :user

      visit_voting_preview
    end

    it "shows the vote preview page" do
      within ".reveal" do
        expect(page).to have_content("Proposals you selected")
        expect(page).to have_content(translated(budget1_projects.first.title))
      end
    end
  end

  describe "create" do
    let(:budget) { budget1 }
    let!(:order) { create(:order, budget: budget1, user: user) }

    before do
      order.projects << budget1_projects.first
      order.save!

      login_as user, scope: :user

      visit_voting_preview
    end

    it "can cast the vote" do
      within ".reveal" do
        click_button "Yes, confirm my vote"
      end

      expect(page).to have_css("h1", text: "Your vote is registered")
    end
  end
end
