require "rails_helper"

describe Dorsale::ES::SearchBuilder do
  subject {
    Dorsale::ES::SearchBuilder
  }

  it "should raise on invalid options" do
    expect {
      subject.new(a: 1, b: 2)
    }.to raise_error(ArgumentError, "Unknown option(s): a, b.")
  end

  describe "keywords" do
    it "should assign a default search" do
      expect(subject.new.es_query_string).to eq "(*)"
    end

    it "should parse keywords" do
      search = subject.new(keywords: "benoit sophie")
      expect(search.es_query_string).to eq "(*benoit*^2 OR *sophie*^1)"
    end

    it "should remove accents" do
      search = subject.new(keywords: "benoît")
      expect(search.es_query_string).to eq "(*benoit*^1)"
    end

    it "should not parse complex queries" do
      search = subject.new(keywords: "benoit OR sophie")
      expect(search.es_query_string).to eq "(benoit OR sophie)"

      search = subject.new(keywords: "-benoit")
      expect(search.es_query_string).to eq "(-benoit)"
    end
  end # describe "keywords"

  describe "filters" do
    it "should merge with filters" do
      search = subject.new(filters: {"name" => "benoit"})
      expect(search.es_query_string).to eq "(name:benoit) AND (*)"
    end

    it "should accept operator" do
      search = subject.new(filters: {"name:" => "benoit"})
      expect(search.es_query_string).to eq "(name:benoit) AND (*)"
    end

    it "should accept operator alt" do
      search = subject.new(filters: {"name:<=" => "benoit"})
      expect(search.es_query_string).to eq "(name:<=benoit) AND (*)"
    end

    it "should not include blank filters keys" do
      search = subject.new(filters: {"" => "benoit"})
      expect(search.filters).to eq []
    end

    it "should not include blank filters values" do
      search = subject.new(filters: {"name" => ""})
      expect(search.filters).to eq []
    end

    it "should convert date object to queryable string" do
      Timecop.travel "2015-06-15" do
        search = subject.new(filters: {"date" => Date.today})
        expect(search.filters).to eq ["date:2015-06-15"]
      end
    end

    it "should convert date object to queryable string" do
      Timecop.travel "2015-06-15 16:30:00" do
        search = subject.new(filters: {"date" => Time.now})
        expect(search.filters).to eq ["date:2015-06-15"]
      end
    end

    it "should accept french formatted dates" do
      search = subject.new(filters: {"date" => "15/06/2015"})
      expect(search.filters).to eq ["date:2015-06-15"]
    end

    describe "magic values" do
      before do
        Timecop.freeze("2016-05-11 15:30:00")

        def self.get_generated_filter_for(value)
          search = subject.new(filters: {"date" => value})
          expect(search.filters.length).to eq 1
          search.filters.first
        end
      end

      after do
        Timecop.return
      end

      it "_today_" do
        expect(get_generated_filter_for("_today_")).to eq "date:2016-05-11"
      end

      it "_tomorrow_" do
        expect(get_generated_filter_for("_tomorrow_")).to eq "date:2016-05-12"
      end

      it "_yesterday_" do
        expect(get_generated_filter_for("_yesterday_")).to eq "date:2016-05-10"
      end

      it "_this_week_" do
        expect(get_generated_filter_for("_this_week_")).to eq "date:[2016-05-09 TO 2016-05-15]"
      end

      it "_last_week_" do
        expect(get_generated_filter_for("_last_week_")).to eq "date:[2016-05-02 TO 2016-05-08]"
      end

      it "_next_week_" do
        expect(get_generated_filter_for("_next_week_")).to eq "date:[2016-05-16 TO 2016-05-22]"
      end

      it "_this_month_" do
        expect(get_generated_filter_for("_this_month_")).to eq "date:[2016-05-01 TO 2016-05-31]"
      end

      it "_last_month_" do
        expect(get_generated_filter_for("_last_month_")).to eq "date:[2016-04-01 TO 2016-04-30]"
      end

      it "_next_month_" do
        expect(get_generated_filter_for("_next_month_")).to eq "date:[2016-06-01 TO 2016-06-30]"
      end

      it "_this_year_" do
        expect(get_generated_filter_for("_this_year_")).to eq "date:[2016-01-01 TO 2016-12-31]"
      end

      it "_last_year_" do
        expect(get_generated_filter_for("_last_year_")).to eq "date:[2015-01-01 TO 2015-12-31]"
      end

      it "_next_year_" do
        expect(get_generated_filter_for("_next_year_")).to eq "date:[2017-01-01 TO 2017-12-31]"
      end
    end
  end # describe "filters"

  describe "(not) null magic values" do
    it "_missing_" do
      search = subject.new(filters: {"name" => "_missing_"})
      expect(search.filters).to eq ["_missing_:name"]
    end

    it "_exists_" do
      search = subject.new(filters: {"name" => "_exists_"})
      expect(search.filters).to eq ["_exists_:name"]
    end

    # _missing_ alias
    it "_null_" do
      search = subject.new(filters: {"name" => "_null_"})
      expect(search.filters).to eq ["_missing_:name"]
    end

    # _exists_ alias
    it "_not_null_" do
      search = subject.new(filters: {"name" => "_not_null_"})
      expect(search.filters).to eq ["_exists_:name"]
    end
  end

end
