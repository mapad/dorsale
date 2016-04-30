require "rails_helper"

describe Dorsale::SortableAttributes do
  it "should return a parameterized value" do
    user = User.new(email: "I-am an email_value")
    expect(user.sortable_email).to eq "i_am_an_email_value"
  end

  it "should raise a NoMethodError" do
    user = User.new
    expect {
      user.sortable_zzz
    }.to raise_error(NoMethodError)
  end
end
