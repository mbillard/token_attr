require 'spec_helper'

describe TokenAttr do

  class Model < ActiveRecord::Base
    extend TokenAttr
    token_attr :token
  end

  class ModelWithLength < ActiveRecord::Base
    self.table_name = 'models'
    extend TokenAttr
    token_attr :token, length: 13
  end

  class ModelWithAlphabet < ActiveRecord::Base
    self.table_name = 'models'
    extend TokenAttr
    token_attr :token, alphabet: 'abc123'
  end

  describe ".token_attr" do
    let(:model) { Model.new }

    context "when token is blank" do
      before { model.token = '' }

      it "generates a token on validation" do
        model.valid?
        model.token.should_not be_blank
      end

      it "generates a token of the default length" do
        stub_const('TokenAttr::DEFAULT_TOKEN_LENGTH', 4)
        model.valid?
        model.token.length.should == 4
      end

      context "when length is specified" do
        let(:model) { ModelWithLength.new }

        it "generates a token of the specified length" do
          model.valid?
          model.token.length.should == 13
        end
      end

      context "when an alphabet is specified" do
        let(:model) { ModelWithAlphabet.new }

        it "generates a token with characters from that alphabet" do
          model.valid?
          model.token.split('').all? do |c|
            'abc123'.include?(c)
          end.should be_true
        end
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
