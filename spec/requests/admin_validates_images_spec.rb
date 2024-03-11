# frozen_string_literal: true

require "spec_helper"

describe "Admin validates record images" do # rubocop:disable RSpec/DescribeClass
  include Decidim::ComponentPathHelper

  let(:user) { create(:user, :confirmed, :admin) }

  let(:headers) { { "HOST" => user.organization.host } }

  before do
    login_as user, scope: :user
  end

  describe "POST create" do
    let(:request_path) { Decidim::Core::Engine.routes.url_helpers.upload_validations_path }

    let(:blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(Decidim::Dev.asset("city.jpeg")),
        filename: "city.jpeg",
        content_type: "image/jpeg"
      )
    end

    {
      "Decidim::Budgets::Budget" => {
        form: "Decidim::Budgets::Admin::BudgetForm",
        properties: %w(list_image)
      },
      "Decidim::Budgets::Project" => {
        form: "Decidim::Budgets::Admin::ProjectForm",
        properties: %w(main_image)
      },
      "Decidim::Budgets::HelpSection" => {
        form: "Decidim::Budgets::Admin::HelpSectionForm",
        properties: %w(image)
      }
    }.each do |record, details|
      context "when #{record}" do
        details[:properties].each do |property|
          context "with #{property}" do
            let(:params) do
              {
                resource_class: record,
                property: property,
                blob: blob.signed_id,
                form_class: details[:form]
              }
            end

            it "validates the image" do
              post(request_path, params: params, headers: headers)

              expect(response).to have_http_status(:ok)

              messages = JSON.parse(response.body)
              expect(messages).to be_empty
            end
          end
        end
      end
    end
  end
end
