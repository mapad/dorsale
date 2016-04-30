require "rails_helper"

describe Dorsale::ES::ViewHelper do
  describe DummyController, type: :controller do
    render_views

    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "should render default link" do
      get :test_es_sortable_column
      expect(response).to be_ok
      expect(response.body).to eq %(<a class="sort " href="/dummy/test_es_sortable_column?sort=name%3Aasc">Name</a>)
    end

    it "should render asc link" do
      get :test_es_sortable_column, sort: "name:asc"
      expect(response).to be_ok
      expect(response.body).to eq %(<a class="sort asc" href="/dummy/test_es_sortable_column?sort=name%3Adesc">Name ↓</a>)
    end

    it "should render desc link" do
      get :test_es_sortable_column, sort: "name:desc"
      expect(response).to be_ok
      expect(response.body).to eq %(<a class="sort desc" href="/dummy/test_es_sortable_column?sort=name%3Aasc">Name ↑</a>)
    end

    it "should merge with other params" do
      get :test_es_sortable_column, sort: "name:desc", page: 1
      expect(response).to be_ok
      expect(response.body).to eq %(<a class="sort desc" href="/dummy/test_es_sortable_column?page=1&amp;sort=name%3Aasc">Name ↑</a>)
    end
  end
end
