require "rails_helper"

describe Dorsale::ES::Model do
  before :each do
    Dorsale::ES::Services.delete_index!
    Dorsale::ES::Services.create_index!
    def self.wait_es_refresh
      sleep 2
    end
  end

  it "should set default index_name" do
    expect(DummyModel.__elasticsearch__.index_name).to eq "dummy_test"
  end

  it "should set default document_type" do
    expect(DummyModel.__elasticsearch__.document_type).to eq "dummy_models"
  end

  let(:benoit) { DummyModel.create!(name: "Benoit") }
  let(:sophie) { DummyModel.create!(name: "Sophie") }
  let(:arthur) { DummyModel.create!(name: "Arthur") }

  describe "default order" do
    it "dummy model should have a default order scope" do
      sql = DummyModel.all.to_sql
      expect(sql).to include "ORDER BY"
    end

    it "search should ignore default order scope" do
      sql = DummyModel.es(keywords: "Benoit").to_sql
      expect(sql).to_not include "ORDER BY"
    end
  end # describe "default order"

  describe "sorting" do
    it "should sort by string" do
      ("A".."Z").to_a.shuffle.each do |letter|
        DummyModel.create!(name: letter)
      end
      wait_es_refresh

      entries = DummyModel.es(sort: "name:asc").entries
      expect(entries.first.name).to eq "A"
    end

    it "should sort by number" do
      (1..20).to_a.shuffle.each do |number|
        DummyModel.create!(integer_field: number)
      end
      wait_es_refresh

      entries = DummyModel.es(sort: "integer_field:asc").entries
      expect(entries.first.integer_field).to eq 1
    end

    it "should sort by date" do
      DummyModel.create!(date_field: "2012-05-23")
      DummyModel.create!(date_field: "2012-09-23")
      DummyModel.create!(date_field: "2012-01-23")
      wait_es_refresh

      entries      = DummyModel.es(sort: "date_field:asc").entries
      sorted_dates = entries.map { |e| e.date_field.to_s }

      expect(sorted_dates).to eq ["2012-01-23", "2012-05-23", "2012-09-23"]
    end
  end # describe "sorting"

  describe "keywords" do
    it "should search by one keyword" do
      benoit ; sophie
      wait_es_refresh

      entries = DummyModel.es(keywords: "benoit").entries
      expect(entries).to eq [benoit]
    end

    it "should search by multiple keywords ordered by keyword" do
      benoit ; sophie ; arthur
      wait_es_refresh

      entries = DummyModel.es(keywords: "benoit sophie").entries
      expect(entries).to eq [benoit, sophie]

      entries = DummyModel.es(keywords: "sophie benoit").entries
      expect(entries).to eq [sophie, benoit]
    end

    it "should search by incomplete keyword" do
      benoit
      wait_es_refresh

      entries = DummyModel.es(keywords: "ben").entries
      expect(entries).to eq [benoit]
    end

    it "should ignore not found keywords" do
      benoit
      wait_es_refresh

      entries = DummyModel.es(keywords: "benoit isabelle").entries
      expect(entries).to eq [benoit]
    end

    it "should work with accented keywords" do
      zoe = DummyModel.create!(name: "Zoé")
      wait_es_refresh

      entries = DummyModel.es(keywords: "zoe").entries
      expect(entries).to eq [zoe]
    end

    it "should work with accented keywords alt" do
      zoe = DummyModel.create!(name: "Zoe")
      wait_es_refresh

      entries = DummyModel.es(keywords: "zoé").entries
      expect(entries).to eq [zoe]
    end

    it "should return all results" do
      benoit ; sophie ; arthur
      wait_es_refresh

      entries = DummyModel.es.entries
      expect(entries.count).to eq 3
    end
  end # describe "keywords"

  describe "filters" do
    describe "integers" do
      let!(:a) { DummyModel.create!(integer_field: 5)  }
      let!(:b) { DummyModel.create!(integer_field: 10) }

      before do
        wait_es_refresh
      end

      it "should filter by integer field eq" do
        entries = DummyModel.es(filters: {"integer_field:" => 5}).entries
        expect(entries).to eq [a]
      end

      it "should filter by integer field lt" do
        entries = DummyModel.es(filters: {"integer_field:<" => 10}).entries
        expect(entries).to eq [a]
      end

      it "should filter by integer field lte" do
        entries = DummyModel.es(filters: {"integer_field:<=" => 5}).entries
        expect(entries).to eq [a]
      end

      it "should filter by integer field gt" do
        entries = DummyModel.es(filters: {"integer_field:>" => 5}).entries
        expect(entries).to eq [b]
      end

      it "should filter by integer field gte" do
        entries = DummyModel.es(filters: {"integer_field:>=" => 10}).entries
        expect(entries).to eq [b]
      end

      xit "should accept decimal" do
        entries = DummyModel.es(filters: {"integer_field:>=" => "5.5"}).entries
        expect(entries).to eq [b]
      end
    end # describe "integers"

    describe "decimals" do
      let!(:a) { DummyModel.create!(decimal_field: 5.5)  }
      let!(:b) { DummyModel.create!(decimal_field: 10.5) }

      before do
        wait_es_refresh
      end

      it "should filter by decimal field eq" do
        entries = DummyModel.es(filters: {"decimal_field:" => 5.5}).entries
        expect(entries).to eq [a]
      end

      it "should filter by decimal field lt" do
        entries = DummyModel.es(filters: {"decimal_field:<" => 10}).entries
        expect(entries).to eq [a]
      end

      it "should filter by decimal field lte" do
        entries = DummyModel.es(filters: {"decimal_field:<=" => 5.5}).entries
        expect(entries).to eq [a]
      end

      it "should filter by decimal field gt" do
        entries = DummyModel.es(filters: {"decimal_field:>" => 5.5}).entries
        expect(entries).to eq [b]
      end

      it "should filter by decimal field gte" do
        entries = DummyModel.es(filters: {"decimal_field:>=" => 10}).entries
        expect(entries).to eq [b]
      end
    end # describe "decimals"

    describe "strings" do
      let!(:pending)  { DummyModel.create!(name: "pending")  }
      let!(:accepted) { DummyModel.create!(name: "accepted") }
      let!(:refused)  { DummyModel.create!(name: "refused")  }

      before do
        wait_es_refresh
      end

      it "should filter single word" do
        entries = DummyModel.es(filters: {"name:" => "pending"}).entries
        expect(entries).to eq [pending]
      end

      it "should filter not single word" do
        entries = DummyModel.es(filters: {"name:" => "(-pending)"}).entries
        expect(entries).to eq [accepted, refused]
      end

      it "should filter multiple word" do
        entries = DummyModel.es(filters: {"name:" => "(accepted refused)"}).entries
        expect(entries).to eq [accepted, refused]
      end

      it "should filter not multiple word" do
        entries = DummyModel.es(filters: {"name:" => "(-accepted -refused)"}).entries
        expect(entries).to eq [pending]
      end
    end # describe "strings"

    describe "booleans" do
      let!(:t) { DummyModel.create!(boolean_field: true)  }
      let!(:f) { DummyModel.create!(boolean_field: false) }

      before do
        wait_es_refresh
      end

      it "should return true results" do
        entries = DummyModel.es(filters: {"boolean_field:" => true}).entries
        expect(entries).to eq [t]
      end

      it "should return false results" do
        entries = DummyModel.es(filters: {"boolean_field:" => false}).entries
        expect(entries).to eq [f]
      end
    end # describe "booleans"

    describe "(not) null / (not) blank" do
      let!(:string) { DummyModel.create!(name: "Benoit") }
      let!(:blank)  { DummyModel.create!(name: "")       }
      let!(:null)   { DummyModel.create!(name: nil)      }

      before do
        wait_es_refresh
      end

      it "should return null results" do
        entries = DummyModel.es(filters: {"name:" => "_null_"}).entries
        expect(entries).to include null
        expect(entries).to_not include blank
        expect(entries).to_not include string
      end

      it "should return not null results" do
        entries = DummyModel.es(filters: {"name:" => "_not_null_"}).entries
        expect(entries).to include string
        expect(entries).to include blank
        expect(entries).to_not include null
      end

      it "should return null results" do
        entries = DummyModel.es(filters: {"name:" => "_missing_"}).entries
        expect(entries).to include null
        expect(entries).to_not include blank
        expect(entries).to_not include string
      end

      it "should return not null results" do
        entries = DummyModel.es(filters: {"name:" => "_exists_"}).entries
        expect(entries).to include string
        expect(entries).to include blank
        expect(entries).to_not include null
      end

      it "should return blank results" do
        entries = DummyModel.es(filters: {"name:" => "_blank_"}).entries
        expect(entries).to include null
        expect(entries).to include blank
        expect(entries).to_not include string
      end

      it "should return not blank results" do
        entries = DummyModel.es(filters: {"name:" => "_not_blank_"}).entries
        expect(entries).to include string
        expect(entries).to_not include blank
        expect(entries).to_not include null
      end
    end # describe "null"

    describe "dates" do
      let!(:d1) { DummyModel.create!(date_field: "2015-06-10") }
      let!(:d2) { DummyModel.create!(date_field: "2015-06-20") }

      before do
        wait_es_refresh
      end

      it "should filter by date eq" do
        entries = DummyModel.es(filters: {"date_field:" => "2015-06-10"}).entries
        expect(entries).to eq [d1]
      end

      it "should filter by date range" do
        Timecop.travel "2015-06-10" do
          entries = DummyModel.es(filters: {"date_field:" => "_this_week_"}).entries
          expect(entries).to eq [d1]
        end
      end
    end # describe "dates"

    describe "datetimes" do
      let!(:d1) { DummyModel.create!(date_field: "2015-06-10 22:45:00") }
      let!(:d2) { DummyModel.create!(date_field: "2015-06-20 22:45:00") }

      before do
        wait_es_refresh
      end

      it "should filter by date eq" do
        entries = DummyModel.es(filters: {"date_field:" => "2015-06-10"}).entries
        expect(entries).to eq [d1]
      end
    end # describe "dates"
  end # describe "filters"

  describe "pagination" do
    it "should paginate" do
      ("A".."Z").to_a.each do |letter|
        DummyModel.create!(name: letter)
      end
      wait_es_refresh

      entries = DummyModel.es(sort: "name:asc", page: 2, per_page: 20).entries
      expect(entries.first.name).to eq "U"
    end
  end # describe "pagination"

end
