# frozen_string_literal: true

require "spec_helper"

describe "Voting", type: :system do
  include_context "with budgeting setup"

  describe "show" do
    context "when the user is not logged in" do
      it "displays the sign in page" do
        visit_voting

        page.scroll_to find("h2", text: "Strong identification")

        contents = all(".wrapper .static__content")
        within contents[0] do
          expect(page).to have_content(strip_tags(translated(component.settings.vote_identify_page_content)))
        end
        within contents[1] do
          expect(page).to have_content(strip_tags(translated(component.settings.vote_identify_page_more_information)))
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

          expect(page).to have_content("Strong identification")
          page.scroll_to find("h2", text: "Strong identification")

          within ".voting-identity" do
            expect(page).to have_link("Example authorization")
          end
        end
      end

      context "when authorized" do
        it "redirects to the budgets selection and allows selecting a budget" do
          visit_voting

          expect(page).to have_content("Select voting area")
        end
      end
    end
  end

  describe "budgets" do
    before { login_as user, scope: :user }

    it "lists all available budgets" do
      visit_voting

      page.scroll_to find("h2", text: "Select voting area")

      within "form#new_budget_select_" do
        budgets.each do |budget|
          expect(find("label", text: translated(budget.title))).not_to be_nil
        end
      end
    end
  end

  describe "start" do
    before { login_as user, scope: :user }

    it "allows selecting a budget" do
      visit_voting

      page.scroll_to find("h2", text: "Select voting area")

      find("label", text: translated(budget1.title)).click
      click_button "Select proposals"

      expect(find("h2", text: "Select proposals")).not_to be_nil
    end
  end

  describe "projects" do
    let(:budget) { budget1 }

    before do
      login_as user, scope: :user

      visit_voting
      find("label", text: translated(budget.title)).click
      click_button "Select proposals"

      page.scroll_to find("h2", text: "Select proposals")
    end

    it "lists the projects for the selected budget" do
      expect(page).to have_content("FOUND 10 PROPOSALS")
    end

    it "allows selecting projects" do
      page.scroll_to find("#projects-count")

      within all(".card form.button_to")[0] do
        click_button "Add to voting cart"
      end

      # May be different element when the cart is updated
      expect(page).to have_button("Remove from voting cart")
    end

    context "when project is selected" do
      it "does not allow exceeding the budget" do
        page.scroll_to find("#projects-count")

        all(".card form.button_to")[0..4].each do |button|
          within button do
            click_button "Add to voting cart"
          end
        end

        within all(".card")[5] do
          expect(page).to have_css("button[disabled]")
        end
      end

      it "shows progress correctly" do
        within all(".card form.button_to")[0] do
          click_button "Add to voting cart"
        end

        page.scroll_to find("#orders")

        within "#orders" do
          expect(page).to have_content("Proposals in the cart 1 pcs")
          expect(page).to have_content("Maximum amount of proposals to be selected 5")
          expect(page).to have_content("Number of selected proposals 1")
          expect(page).to have_content("Remaining proposals to select 4")
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

      page.scroll_to find("h2", text: "Preview and vote")
    end

    it "shows the vote preview page" do
      expect(page).to have_content("Maximum amount of proposals to be selected in the area: 5")
      expect(page).to have_content(translated(budget1_projects.first.title))
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

      page.scroll_to find("h2", text: "Preview and vote")
    end

    it "can cast the vote" do
      click_button "Vote"

      within "#vote-finished-modal" do
        expect(page).to have_content("Thank you for your vote!")
      end
    end
  end
end
