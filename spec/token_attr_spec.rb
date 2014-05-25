require 'spec_helper'

describe TokenAttr do

  describe ".token_attr" do
    let(:model) { Model.new }

    context "when token is blank" do
      before { model.token = '' }

      it "generates a token on validation" do
        model.valid?
        model.token.should_not be_blank
      end
    end

    context "when token is not blank" do
      before { model.token = 'not blank' }

      it "does not generate a token on validation" do
        model.valid?
        model.token.should == 'not blank'
      end
    end
  end
end
